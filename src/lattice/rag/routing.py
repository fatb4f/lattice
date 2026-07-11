"""Bounded routing decisions over validated adapter inputs."""

from __future__ import annotations

from typing import Literal

Route = Literal["inspect", "retrieve", "diagnostics"]


def route_for_intent(intent: str) -> Route:
    routes: dict[str, Route] = {"inspect": "inspect", "retrieve": "retrieve", "diagnostics": "diagnostics"}
    try:
        return routes[intent]
    except KeyError as exc:
        raise ValueError(f"unsupported runtime intent: {intent}") from exc
