from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from typing import Any

from lattice.adapters.full_index import FullIndexError, load_full_index_envelope, normalize_full_index
from lattice.adapters.runtime_surface import runtime_surface_violations
from lattice.rag.routing import route_for_intent

ROOT = Path(__file__).parents[1]
FIXTURES = ROOT / "tests" / "fixtures" / "full_index"


class FullIndexBoundaryTests(unittest.TestCase):
    def run_javascript_normalizer(self, raw: str, provenance: dict[str, str]) -> dict[str, Any]:
        script = """
import { normalizeFullIndex } from './src/lattice/adapters/index_response.js';
const result = normalizeFullIndex({ok: true, output: process.argv[1]}, JSON.parse(process.argv[2]));
const normalized = result.ok
  ? {ok: true, value: result.value}
  : {ok: false, error: JSON.parse(result.output)};
console.log(JSON.stringify(normalized));
"""
        completed = subprocess.run(
            ["node", "--input-type=module", "-e", script, raw, json.dumps(provenance)],
            cwd=ROOT,
            check=True,
            capture_output=True,
            text=True,
        )
        return json.loads(completed.stdout)

    def test_fixture_normalizes_to_versioned_envelope(self) -> None:
        graph = (FIXTURES / "graph.json").read_text()
        provenance = json.loads((FIXTURES / "provenance.json").read_text())
        envelope = normalize_full_index(graph, provenance)
        self.assertEqual(envelope["schema"], "lattice.kg-full-index-envelope.v1")
        self.assertEqual(
            envelope["graph"]["relations"],
            [{"source": "one", "predicate": "related", "target": "two"}],
        )
        self.assertEqual(load_full_index_envelope(envelope), envelope)

    def test_dangling_relation_fails_closed(self) -> None:
        graph = json.loads((FIXTURES / "graph.json").read_text())
        graph["entities"]["one"]["value"]["related"] = {"missing": True}
        with self.assertRaisesRegex(FullIndexError, "dangling"):
            normalize_full_index(graph, json.loads((FIXTURES / "provenance.json").read_text()))

    def test_envelope_requires_complete_provenance(self) -> None:
        graph = (FIXTURES / "graph.json").read_text()
        envelope = normalize_full_index(graph, json.loads((FIXTURES / "provenance.json").read_text()))
        envelope["provenance"] = {}
        with self.assertRaisesRegex(FullIndexError, "provenance"):
            load_full_index_envelope(envelope)

    def test_declared_total_must_equal_entity_inventory(self) -> None:
        graph = json.loads((FIXTURES / "graph.json").read_text())
        graph["summary"]["total"] += 1
        with self.assertRaisesRegex(FullIndexError, "incomplete"):
            normalize_full_index(graph, json.loads((FIXTURES / "provenance.json").read_text()))

    def test_bun_bridge_matches_python_canonical_envelope(self) -> None:
        graph = (FIXTURES / "graph.json").read_text()
        provenance = json.loads((FIXTURES / "provenance.json").read_text())
        expected = normalize_full_index(graph, provenance)
        script = """
import { normalizeFullIndex } from './src/lattice/adapters/index_response.js';
const graph = JSON.parse(process.argv[1]);
const provenance = JSON.parse(process.argv[2]);
console.log(JSON.stringify(normalizeFullIndex({ok: true, output: JSON.stringify(graph)}, provenance).value));
"""
        actual = subprocess.run(
            ["node", "--input-type=module", "-e", script, graph, json.dumps(provenance)],
            cwd=ROOT,
            check=True,
            capture_output=True,
            text=True,
        )
        self.assertEqual(json.loads(actual.stdout), expected)

    def test_bun_bridge_matches_python_error_envelope(self) -> None:
        graph = (FIXTURES / "graph.json").read_text()
        expected: dict[str, Any] = {}
        try:
            normalize_full_index(graph, {})
        except FullIndexError as exc:
            expected = exc.as_dict()
        script = """
import { normalizeFullIndex } from './src/lattice/adapters/index_response.js';
const result = normalizeFullIndex({ok: true, output: process.argv[1]}, {});
console.log(result.output);
"""
        actual = subprocess.run(
            ["node", "--input-type=module", "-e", script, graph],
            cwd=ROOT,
            check=True,
            capture_output=True,
            text=True,
        )
        self.assertEqual(json.loads(actual.stdout), expected)

    def test_javascript_and_python_share_full_boundary_matrix(self) -> None:
        provenance = json.loads((FIXTURES / "provenance.json").read_text())
        base = json.loads((FIXTURES / "graph.json").read_text())
        ordering = {
            "entities": {
                "😀": {"collection": "insights", "value": {"related": {"z": True}}},
                "\ue000": {"collection": "insights", "value": {"related": {"z": True}}},
                "z": {"collection": "insights", "value": {}},
            },
            "summary": {"total": 3},
        }
        cases: dict[str, tuple[str, dict[str, str], str | None]] = {
            "valid": (json.dumps(base), provenance, None),
            "malformed-entity-value": (
                json.dumps({**base, "entities": {**base["entities"], "one": {"collection": "decisions", "value": []}}}),
                provenance,
                "kg_index_incomplete",
            ),
            "malformed-related": (
                json.dumps(
                    {
                        **base,
                        "entities": {**base["entities"], "one": {"collection": "decisions", "value": {"related": []}}},
                    }
                ),
                provenance,
                "kg_index_incomplete",
            ),
            "inventory-type": (
                json.dumps({"entities": [], "summary": {"total": 0}}),
                provenance,
                "kg_index_incomplete",
            ),
            "inventory-count": (json.dumps({**base, "summary": {"total": 1}}), provenance, "kg_index_incomplete"),
            "dangling": (
                json.dumps(
                    {
                        **base,
                        "entities": {
                            **base["entities"],
                            "one": {"collection": "decisions", "value": {"related": {"missing": True}}},
                        },
                    }
                ),
                provenance,
                "kg_index_dangling_relations",
            ),
            "invalid-json": ("{", provenance, "kg_index_invalid_json"),
            "missing-provenance": (json.dumps(base), {}, "kg_index_provenance_missing"),
            "ordinal-ordering": (json.dumps(ordering), provenance, None),
        }
        for name, (raw, case_provenance, error_code) in cases.items():
            with self.subTest(name=name):
                python_result: dict[str, Any]
                try:
                    python_result = {"ok": True, "value": normalize_full_index(raw, case_provenance)}
                except FullIndexError as exc:
                    python_result = {"ok": False, "error": exc.as_dict()}
                javascript_result = self.run_javascript_normalizer(raw, case_provenance)
                self.assertEqual(javascript_result["ok"], python_result["ok"])
                if error_code:
                    self.assertEqual(python_result["error"]["error"]["code"], error_code)
                    self.assertEqual(javascript_result["error"]["error"]["code"], error_code)
                else:
                    self.assertEqual(
                        javascript_result["value"]["graph"]["relations"],
                        python_result["value"]["graph"]["relations"],
                    )

    def test_routing_is_closed(self) -> None:
        self.assertEqual(route_for_intent("retrieve"), "retrieve")
        with self.assertRaisesRegex(ValueError, "unsupported"):
            route_for_intent("invent-policy")


class RuntimeSurfaceGateTests(unittest.TestCase):
    def test_repository_surface_is_admitted(self) -> None:
        self.assertEqual(runtime_surface_violations(ROOT), [])

    def test_unknown_kg_files_and_package_data_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            paths = {
                ".kg/retrieval/server.py": "pass\n",
                ".kg/tools/new-runtime": "#!/bin/sh\nexit 0\n",
                ".kg/tools/hidden-fragment": "run_runtime --quiet\n",
                ".kg/mcp-next/server.mjs": "export {};\n",
                ".kg/mcp-next/server.cjs": "module.exports = {};\n",
                ".kg/mcp-next/package.json": "{}\n",
                ".kg/mcp-next/bun.lock": "\n",
                "src/lattice/index.json": "{}\n",
                "src/lattice/corpus/entities.jsonl": "{}\n",
                "src/lattice/cache/index.bin": "bytes\n",
                "src/lattice/review-bundle.json": "{}\n",
                "src/lattice/snapshot.json": "{}\n",
                "src/lattice/entities.yaml": "entities: []\n",
                "src/lattice/registry.sqlite": "bytes\n",
                "src/lattice/projection.parquet": "bytes\n",
                "src/lattice/review/report.html": "<html></html>\n",
            }
            for relative, contents in paths.items():
                path = root / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(contents)
            self.assertEqual(len(runtime_surface_violations(root)), len(paths))

    def test_tracked_python_cache_artifact_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            artifact = root / "src" / "lattice" / "__pycache__" / "module.cpython-312.pyc"
            artifact.parent.mkdir(parents=True)
            artifact.write_bytes(b"tracked bytecode")
            subprocess.run(["git", "init", "--quiet"], cwd=root, check=True)
            subprocess.run(["git", "add", artifact.relative_to(root)], cwd=root, check=True)
            self.assertEqual(
                runtime_surface_violations(root),
                ["tracked Python cache artifact beneath src/lattice: src/lattice/__pycache__/module.cpython-312.pyc"],
            )

    def test_minified_substantive_wrapper_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            wrapper = root / ".kg" / "tools" / "kg"
            wrapper.parent.mkdir(parents=True)
            wrapper.write_text("#!/bin/sh; parse_event_and_run_runtime\n")
            self.assertEqual(runtime_surface_violations(root), ["unadmitted file beneath .kg: .kg/tools/kg"])


if __name__ == "__main__":
    unittest.main()
