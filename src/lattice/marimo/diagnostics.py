"""Generated, non-authoritative diagnostics workbook projection."""

from __future__ import annotations

import html
from collections.abc import Mapping
from typing import Any


def render_workbook(summary: Mapping[str, Any], checks: list[Mapping[str, Any]]) -> str:
    rows = "".join(
        "<tr><td>{}</td><td>{}</td><td>{}</td><td>{}</td></tr>".format(
            html.escape(str(item["checkId"])),
            html.escape(str(item["subsystem"])),
            html.escape(str(item["status"])),
            html.escape(str(item.get("remediation", ""))),
        )
        for item in checks
    )
    return (
        "<!doctype html><html><head><meta charset='utf-8'><title>Lattice diagnostics</title>"
        "<style>body{font:14px system-ui;margin:2rem}table{border-collapse:collapse;width:100%}"
        "td,th{border:1px solid #ccc;padding:.5rem;text-align:left}</style></head><body>"
        f"<h1>Lattice diagnostics</h1><p>Status: {html.escape(str(summary['status']))}</p>"
        "<table><thead><tr><th>Check</th><th>Subsystem</th><th>Status</th><th>Remediation</th></tr></thead>"
        f"<tbody>{rows}</tbody></table></body></html>"
    )
