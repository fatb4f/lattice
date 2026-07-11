"""Validate profile resource IDs, protocol versions, and resource digests."""

from __future__ import annotations

import hashlib
import json
from collections.abc import Mapping
from importlib.resources import files
from types import MappingProxyType
from typing import Any


def _freeze(value: Any) -> Any:
    if isinstance(value, dict):
        return MappingProxyType({key: _freeze(item) for key, item in value.items()})
    if isinstance(value, list):
        return tuple(_freeze(item) for item in value)
    return value


def load_manifest() -> Mapping[str, Any]:
    root = files("lattice.profiles")
    data = json.loads(root.joinpath("manifest.json").read_text(encoding="utf-8"))
    if (
        not isinstance(data, dict)
        or data.get("schema") != "lattice.profile-manifest.v1"
        or data.get("protocolVersion") != "lattice.registry.v1"
    ):
        raise ValueError("unsupported profile manifest")
    profiles = data.get("profiles")
    if not isinstance(profiles, list) or not profiles:
        raise ValueError("profile manifest must declare profiles")
    ids: set[str] = set()
    for profile in profiles:
        if (
            not isinstance(profile, dict)
            or set(profile) != {"id", "version", "protocolVersion", "resource", "digest"}
            or not all(isinstance(profile[key], str) and profile[key] for key in profile)
        ):
            raise ValueError("invalid profile declaration")
        if profile["id"] in ids or profile["protocolVersion"] != data["protocolVersion"]:
            raise ValueError("duplicate or incompatible profile")
        ids.add(profile["id"])
        digest = "sha256:" + hashlib.sha256(root.joinpath(profile["resource"]).read_bytes()).hexdigest()
        if digest != profile["digest"]:
            raise ValueError(f"profile digest mismatch: {profile['id']}")
    return _freeze(data)
