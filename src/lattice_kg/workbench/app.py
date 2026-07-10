"""Optional interactive inspector over the installed package APIs."""

from __future__ import annotations

import json

import marimo as mo

from lattice_kg import compose, load_snapshot
from lattice_kg.profiles import load_manifest

DEFAULT_REQUEST = (
    '{"schema":"lattice.compose-request.v1","intent":"inspect","focus":{"paths":["meta/kernel.cue"]},'
    '"budget":{"maxDepth":2,"maxNodes":16,"maxEdges":24,"maxScannedEdges":256,"maxDiagnostics":32,"maxBytes":8192}}'
)

app = mo.App()


@app.cell
def _():
    snapshot_path = mo.ui.text(label="Snapshot directory", placeholder="/path/to/snapshot")
    request = mo.ui.text_area(label="Compose request", value=DEFAULT_REQUEST)
    return request, snapshot_path


@app.cell
def _(request, snapshot_path):
    controls = mo.vstack([snapshot_path, request])
    return (controls,)


@app.cell
def _(request, snapshot_path):
    if not snapshot_path.value.strip():
        result = mo.md("Enter a snapshot directory to inspect it.")
    else:
        try:
            artifact = compose(json.loads(request.value), load_snapshot(snapshot_path.value.strip()))
            result = mo.vstack(
                [
                    mo.md("### Context packet"),
                    mo.ui.code_editor(value=artifact.packet_bytes.decode("utf-8"), language="json"),
                    mo.md("### Composition trace"),
                    mo.ui.code_editor(value=artifact.trace_bytes.decode("utf-8"), language="json"),
                    mo.md("### Bundled profiles"),
                    mo.ui.table(load_manifest()["profiles"]),
                ]
            )
        except (OSError, ValueError) as exc:
            result = mo.callout(f"Unable to compose: {exc}", kind="danger")
    return (result,)


def create_app():
    """Return the packaged application without starting a server."""
    return app


def smoke_test() -> None:
    """Verify the optional dependency and all workbench cells can be registered."""
    if not getattr(app, "_cell_manager", None):
        raise RuntimeError("Marimo application did not register its cells")


def main() -> int:
    app.run()
    return 0
