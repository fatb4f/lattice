from __future__ import annotations

import json
import shutil
import tempfile
import unittest
from pathlib import Path

from lattice import SnapshotValidationError, compose, load_snapshot
from lattice.rag.contracts.models import ContractError

ROOT = Path(__file__).parents[1]
FIXTURE = ROOT / "registry" / "fixtures" / "canonical"
GOLDEN = ROOT / "registry" / "fixtures" / "golden" / "inspect_meta_kernel.json"


class RegistryAdapterTests(unittest.TestCase):
    def setUp(self) -> None:
        self.snapshot = load_snapshot(FIXTURE)

    def test_loads_immutable_snapshot_and_exact_indexes(self) -> None:
        self.assertEqual(
            self.snapshot.ids_by_path["meta/kernel.cue"],
            ("urn:lattice:entity:file:meta-kernel", "urn:lattice:entity:symbol:make-closed-obligation-state"),
        )
        self.assertEqual(
            self.snapshot.ids_by_qualified_symbol["meta.#MakeClosedObligationState"],
            ("urn:lattice:entity:symbol:make-closed-obligation-state",),
        )
        with self.assertRaises(TypeError):
            self.snapshot.nodes_by_id["other"] = None  # type: ignore[index]

    def test_compose_is_byte_deterministic_for_path_seed(self) -> None:
        request = {
            "schema": "lattice.compose-request.v1",
            "intent": "inspect",
            "focus": {"paths": ["meta/kernel.cue"]},
            "budget": {
                "maxDepth": 2,
                "maxNodes": 10,
                "maxEdges": 10,
                "maxScannedEdges": 100,
                "maxDiagnostics": 32,
                "maxBytes": 8000,
            },
        }
        first = compose(request, self.snapshot)
        second = compose(request, self.snapshot)
        self.assertEqual(first.packet_bytes, second.packet_bytes)
        self.assertEqual(first.trace_bytes, second.trace_bytes)
        self.assertEqual(
            {"packet": json.loads(first.packet_bytes), "trace": json.loads(first.trace_bytes)},
            json.loads(GOLDEN.read_text()),
        )
        self.assertEqual(
            [item["id"] for item in first.packet["entities"]],
            [
                "urn:lattice:entity:file:meta-kernel",
                "urn:lattice:entity:file:patterns-closedness",
                "urn:lattice:entity:symbol:make-closed-obligation-state",
            ],
        )

    def test_exact_symbol_resolution_rejects_unknown_intents(self) -> None:
        request = {
            "schema": "lattice.compose-request.v1",
            "intent": "inspect",
            "focus": {"symbols": ["meta.#MakeClosedObligationState"]},
            "budget": {
                "maxDepth": 2,
                "maxNodes": 16,
                "maxEdges": 24,
                "maxScannedEdges": 256,
                "maxDiagnostics": 32,
                "maxBytes": 8192,
            },
        }
        result = compose(request, self.snapshot)
        self.assertEqual(result.trace["resolvedSeeds"], ("urn:lattice:entity:symbol:make-closed-obligation-state",))
        with self.assertRaises(ContractError):
            compose(
                {
                    "schema": "lattice.compose-request.v1",
                    "intent": "change_impact",
                    "focus": {"paths": ["meta/kernel.cue"]},
                    "budget": {
                        "maxDepth": 2,
                        "maxNodes": 16,
                        "maxEdges": 24,
                        "maxScannedEdges": 256,
                        "maxDiagnostics": 32,
                        "maxBytes": 8192,
                    },
                },
                self.snapshot,
            )

    def test_bad_digest_and_context_fail_before_indexing(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp) / "fixture"
            shutil.copytree(FIXTURE, target)
            manifest = json.loads((target / "manifest.json").read_text())
            manifest["identity"]["graphDigest"] = "sha256:" + "0" * 64
            (target / "manifest.json").write_text(json.dumps(manifest))
            with self.assertRaisesRegex(SnapshotValidationError, "digest"):
                load_snapshot(target)
            manifest["identity"]["graphDigest"] = self.snapshot.identity.graph_digest
            (target / "manifest.json").write_text(json.dumps(manifest))
            graph = json.loads((target / "graph.jsonld").read_text())
            graph["@context"] = "https://example.invalid/context"
            (target / "graph.jsonld").write_text(json.dumps(graph))
            with self.assertRaisesRegex(SnapshotValidationError, "context"):
                load_snapshot(target)

    def test_dangling_relation_requires_explicit_external_iri(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp) / "fixture"
            shutil.copytree(FIXTURE, target)
            graph = json.loads((target / "graph.jsonld").read_text())
            graph["relations"][0]["object"] = "urn:remote:entity"
            from lattice.rag.provenance import sha256_digest

            manifest = json.loads((target / "manifest.json").read_text())
            manifest["identity"]["graphDigest"] = sha256_digest(graph)
            (target / "manifest.json").write_text(json.dumps(manifest))
            (target / "graph.jsonld").write_text(json.dumps(graph))
            with self.assertRaisesRegex(SnapshotValidationError, "dangling"):
                load_snapshot(target)
            graph["relations"][0]["external"] = True
            manifest["identity"]["graphDigest"] = sha256_digest(graph)
            (target / "manifest.json").write_text(json.dumps(manifest))
            (target / "graph.jsonld").write_text(json.dumps(graph))
            self.assertTrue(any(relation.external for relation in load_snapshot(target).relations))

    def test_byte_budget_reports_or_rejects_small_envelopes(self) -> None:
        request = {
            "schema": "lattice.compose-request.v1",
            "intent": "inspect",
            "focus": {"paths": ["meta/kernel.cue"]},
            "budget": {
                "maxDepth": 2,
                "maxNodes": 10,
                "maxEdges": 10,
                "maxScannedEdges": 100,
                "maxDiagnostics": 32,
                "maxBytes": 1200,
            },
        }
        with self.assertRaisesRegex(ContractError, "maxBytes"):
            compose(request, self.snapshot)


if __name__ == "__main__":
    unittest.main()
