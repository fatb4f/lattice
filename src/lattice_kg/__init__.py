"""Compatibility import; runtime authority lives under :mod:`lattice`."""

from lattice import (
    CompositionArtifact,
    PythonRegistryEngine,
    RegistrySnapshot,
    SnapshotValidationError,
    compose,
    load_snapshot,
)

__all__ = [
    "CompositionArtifact",
    "PythonRegistryEngine",
    "RegistrySnapshot",
    "SnapshotValidationError",
    "compose",
    "load_snapshot",
]
