from __future__ import annotations

import hashlib
import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from importlib.resources import files
from pathlib import Path

from lattice_kg import compose, load_snapshot
from lattice_kg.contracts.models import ContextBudget, ContractError
from lattice_kg.contracts.serialization import sha256_digest
from lattice_kg.profiles import load_manifest
from lattice_kg.registry.loader import SnapshotValidationError

ROOT = Path(__file__).parents[1]
FIXTURE = ROOT / "registry" / "fixtures" / "canonical"


class LatticeKgTests(unittest.TestCase):
    def setUp(self) -> None:
        self.snapshot = load_snapshot(FIXTURE)
        self.request = {
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

    def test_canonical_artifact_is_immutable_and_self_verifying(self) -> None:
        artifact = compose(self.request, self.snapshot)
        packet = json.loads(artifact.packet_bytes)
        trace = json.loads(artifact.trace_bytes)
        self.assertEqual(
            packet["packetDigest"],
            "sha256:"
            + hashlib.sha256(
                json.dumps(
                    {key: value for key, value in packet.items() if key != "packetDigest"},
                    sort_keys=True,
                    separators=(",", ":"),
                    ensure_ascii=True,
                ).encode()
            ).hexdigest(),
        )
        self.assertEqual(
            trace["traceDigest"],
            "sha256:"
            + hashlib.sha256(
                json.dumps(
                    {key: value for key, value in trace.items() if key != "traceDigest"},
                    sort_keys=True,
                    separators=(",", ":"),
                    ensure_ascii=True,
                ).encode()
            ).hexdigest(),
        )
        with self.assertRaises(TypeError):
            artifact.packet["intent"] = "other"  # type: ignore[index]
        self.assertLessEqual(len(artifact.packet_bytes), self.request["budget"]["maxBytes"])

    def test_seed_expansion_and_byte_limits_reject_without_broken_closure(self) -> None:
        overflowing = {
            **self.request,
            "focus": {"paths": ["meta/kernel.cue"], "symbols": ["meta.#MakeClosedObligationState"]},
            "budget": {
                "maxDepth": 0,
                "maxNodes": 1,
                "maxEdges": 0,
                "maxScannedEdges": 100,
                "maxDiagnostics": 32,
                "maxBytes": 8000,
            },
        }
        with self.assertRaisesRegex(ContractError, "maxNodes"):
            compose(overflowing, self.snapshot)
        too_small = {
            **self.request,
            "budget": {
                "maxDepth": 2,
                "maxNodes": 10,
                "maxEdges": 10,
                "maxScannedEdges": 100,
                "maxDiagnostics": 32,
                "maxBytes": 512,
            },
        }
        with self.assertRaisesRegex(ContractError, "maxBytes"):
            compose(too_small, self.snapshot)

    def test_contract_and_profile_resources_are_installed_package_resources(self) -> None:
        packaged = files("lattice_kg.contracts.resources").joinpath("registry/schema.cue").read_bytes()
        self.assertEqual(packaged, (ROOT / "projections" / "registry" / "schema.cue").read_bytes())
        self.assertIn("#CompositionTrace", packaged.decode())
        manifest = load_manifest()
        self.assertEqual(manifest["profiles"][0]["id"], "control")
        with self.assertRaises(TypeError):
            manifest["profiles"][0]["id"] = "changed"  # type: ignore[index]

    def test_python_contract_negatives_match_cue_types(self) -> None:
        with self.assertRaisesRegex(ContractError, "budget must be an object"):
            ContextBudget.from_mapping([])  # type: ignore[arg-type]
        with self.assertRaisesRegex(ContractError, "missing required fields"):
            ContextBudget.from_mapping({"maxDepth": 2})
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp) / "fixture"
            import shutil

            shutil.copytree(FIXTURE, target)
            graph = json.loads((target / "graph.jsonld").read_text())
            graph["evidence"][0]["startLine"] = 1.0
            manifest = json.loads((target / "manifest.json").read_text())
            manifest["identity"]["graphDigest"] = sha256_digest(graph)
            (target / "manifest.json").write_text(json.dumps(manifest))
            (target / "graph.jsonld").write_text(json.dumps(graph))
            with self.assertRaisesRegex(SnapshotValidationError, "integers"):
                load_snapshot(target)
            graph["evidence"][0]["startLine"] = 1
            graph["evidence"][0]["endLine"] = 2.0
            manifest["identity"]["graphDigest"] = sha256_digest(graph)
            (target / "manifest.json").write_text(json.dumps(manifest))
            (target / "graph.jsonld").write_text(json.dumps(graph))
            with self.assertRaisesRegex(SnapshotValidationError, "integers"):
                load_snapshot(target)

    def test_lattice_urn_cannot_be_classified_as_external(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp) / "fixture"
            import shutil

            shutil.copytree(FIXTURE, target)
            graph = json.loads((target / "graph.jsonld").read_text())
            manifest = json.loads((target / "manifest.json").read_text())
            for object_id in (
                "urn:lattice:entity:file:patterns-closedness",
                "urn:lattice:entity:misspelled-internal-id",
            ):
                graph["relations"][0]["object"] = object_id
                graph["relations"][0]["external"] = True
                manifest["identity"]["graphDigest"] = sha256_digest(graph)
                (target / "manifest.json").write_text(json.dumps(manifest))
                (target / "graph.jsonld").write_text(json.dumps(graph))
                with self.assertRaisesRegex(SnapshotValidationError, "internal relation cannot be external"):
                    load_snapshot(target)

    def test_edge_budget_stops_high_degree_scan_with_one_diagnostic(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp) / "fixture"
            import shutil

            shutil.copytree(FIXTURE, target)
            graph = json.loads((target / "graph.jsonld").read_text())
            source = "urn:lattice:entity:file:meta-kernel"
            for index in range(100):
                graph["relations"].append(
                    {
                        "id": f"urn:lattice:relation:fanout-{index}",
                        "predicate": "uses",
                        "subject": source,
                        "object": "urn:lattice:entity:file:patterns-closedness",
                        "evidence": ["ev-meta-kernel"],
                    }
                )
            manifest = json.loads((target / "manifest.json").read_text())
            manifest["identity"]["graphDigest"] = sha256_digest(graph)
            (target / "manifest.json").write_text(json.dumps(manifest))
            (target / "graph.jsonld").write_text(json.dumps(graph))
            request = {
                **self.request,
                "focus": {"ids": [source]},
                "budget": {
                    "maxDepth": 1,
                    "maxNodes": 10,
                    "maxEdges": 0,
                    "maxScannedEdges": 100,
                    "maxDiagnostics": 32,
                    "maxBytes": 8000,
                },
            }
            artifact = compose(request, load_snapshot(target))
            self.assertEqual(
                artifact.packet["diagnostics"], ({"code": "edge_budget_exhausted", "message": "maxEdges reached"},)
            )

    def test_traversal_scan_and_diagnostics_are_bounded(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp) / "fixture"
            import shutil

            shutil.copytree(FIXTURE, target)
            graph = json.loads((target / "graph.jsonld").read_text())
            source = "urn:lattice:entity:file:meta-kernel"
            target_id = "urn:lattice:entity:file:patterns-closedness"
            graph["relations"] = [
                {
                    "id": f"urn:lattice:relation:unsupported-{index}",
                    "predicate": "unsupported",
                    "subject": source,
                    "object": target_id,
                    "evidence": ["ev-meta-kernel"],
                }
                for index in range(100)
            ] + [
                {
                    "id": "urn:lattice:relation:zz-accepted-after-limit",
                    "predicate": "uses",
                    "subject": source,
                    "object": target_id,
                    "evidence": ["ev-meta-kernel"],
                }
            ]
            manifest = json.loads((target / "manifest.json").read_text())
            manifest["identity"]["graphDigest"] = sha256_digest(graph)
            (target / "manifest.json").write_text(json.dumps(manifest))
            (target / "graph.jsonld").write_text(json.dumps(graph))
            request = {
                **self.request,
                "focus": {"ids": [source]},
                "budget": {
                    "maxDepth": 1,
                    "maxNodes": 10,
                    "maxEdges": 10,
                    "maxScannedEdges": 5,
                    "maxDiagnostics": 8,
                    "maxBytes": 8000,
                },
            }
            artifact = compose(request, load_snapshot(target))
            self.assertEqual(artifact.packet["relations"], ())
            self.assertEqual(len(artifact.packet["diagnostics"]), 6)
            self.assertEqual(
                artifact.packet["diagnostics"][-1],
                {"code": "scanned_edge_budget_exhausted", "message": "maxScannedEdges reached"},
            )
            request["budget"]["maxDiagnostics"] = 2
            self.assertLessEqual(len(compose(request, load_snapshot(target)).packet["diagnostics"]), 2)

    def test_cue_contracts_admit_canonical_inputs_and_emitted_outputs(self) -> None:
        golden = json.loads((ROOT / "registry" / "fixtures" / "golden" / "inspect_meta_kernel.json").read_text())
        commands = [
            ("#RegistryManifest", FIXTURE / "manifest.json"),
        ]
        with tempfile.TemporaryDirectory() as temp:
            temp_path = Path(temp)
            graph = temp_path / "graph.json"
            request = temp_path / "request.json"
            packet = temp_path / "packet.json"
            trace = temp_path / "trace.json"
            graph.write_text((FIXTURE / "graph.jsonld").read_text())
            cue_request = {**self.request, "focus": {"ids": [], "paths": ["meta/kernel.cue"], "symbols": []}}
            request.write_text(json.dumps(cue_request))
            packet.write_text(json.dumps(golden["packet"]))
            trace.write_text(json.dumps(golden["trace"]))
            commands.extend(
                [
                    ("#RegistryGraph", graph),
                    ("#ComposeRequest", request),
                    ("#ContextPacket", packet),
                    ("#CompositionTrace", trace),
                ]
            )
            for definition, value in commands:
                subprocess.run(
                    ["cue", "vet", str(ROOT / "projections" / "registry" / "schema.cue"), str(value), "-d", definition],
                    check=True,
                    capture_output=True,
                    text=True,
                )
            subprocess.run(
                [
                    "cue",
                    "vet",
                    str(ROOT / "src" / "lattice_kg" / "contracts" / "resources" / "profiles" / "schema.cue"),
                    str(ROOT / "src" / "lattice_kg" / "profiles" / "manifest.json"),
                    "-d",
                    "#ProfileManifest",
                ],
                check=True,
                capture_output=True,
                text=True,
            )

    def test_cli_writes_engine_bytes_without_workbench_import(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            temp_path = Path(temp)
            request = temp_path / "request.json"
            packet = temp_path / "packet.json"
            trace = temp_path / "trace.json"
            request.write_text(json.dumps(self.request), encoding="utf-8")
            completed = subprocess.run(
                [
                    sys.executable,
                    "-m",
                    "lattice_kg.cli",
                    "compose",
                    "--snapshot",
                    str(FIXTURE),
                    "--request",
                    str(request),
                    "--packet-out",
                    str(packet),
                    "--trace-out",
                    str(trace),
                ],
                check=True,
                capture_output=True,
                text=True,
            )
            self.assertEqual(completed.stderr, "")
            artifact = compose(self.request, self.snapshot)
            self.assertEqual(packet.read_bytes(), artifact.packet_bytes)
            self.assertEqual(trace.read_bytes(), artifact.trace_bytes)
            subprocess.run([sys.executable, "-m", "lattice_kg.cli", "profile", "validate"], check=True)

    def test_wheel_exposes_deprecated_registry_adapter(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            temp_path = Path(temp)
            dist = temp_path / "dist"
            subprocess.run(
                ["uv", "build", "--no-sources", "--wheel", "--out-dir", str(dist)],
                cwd=ROOT,
                check=True,
                capture_output=True,
                text=True,
            )
            wheel = next(dist.glob("lattice_kg-*.whl"))
            environment = temp_path / "environment"
            subprocess.run([sys.executable, "-m", "venv", str(environment)], check=True)
            python = environment / ("Scripts/python.exe" if sys.platform == "win32" else "bin/python")
            subprocess.run([str(python), "-m", "pip", "install", "--no-deps", str(wheel)], check=True)
            completed = subprocess.run(
                [
                    str(python),
                    "-I",
                    "-c",
                    "import warnings\n"
                    "import lattice_kg\n"
                    "with warnings.catch_warnings(record=True) as captured:\n"
                    "    warnings.simplefilter('always')\n"
                    "    import registry_adapter\n"
                    "assert registry_adapter.compose is lattice_kg.compose\n"
                    "assert any(issubclass(item.category, DeprecationWarning) for item in captured)\n",
                ],
                cwd=temp_path,
                check=True,
                capture_output=True,
                text=True,
            )
            self.assertEqual(completed.stderr, "")

    @unittest.skipUnless(importlib.util.find_spec("marimo"), "workbench extra is not installed")
    def test_workbench_extra_constructs_registered_application(self) -> None:
        subprocess.run([sys.executable, "-m", "lattice_kg.cli", "workbench", "--headless-smoke-test"], check=True)


if __name__ == "__main__":
    unittest.main()
