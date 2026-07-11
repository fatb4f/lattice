"""Deprecated compatibility import for :mod:`lattice`."""

from __future__ import annotations

import warnings

from lattice import CompositionArtifact, RegistrySnapshot, SnapshotValidationError, compose, load_snapshot

warnings.warn("registry_adapter is deprecated; import lattice instead", DeprecationWarning, stacklevel=2)

CompositionResult = CompositionArtifact

__all__ = ["CompositionResult", "RegistrySnapshot", "SnapshotValidationError", "compose", "load_snapshot"]
