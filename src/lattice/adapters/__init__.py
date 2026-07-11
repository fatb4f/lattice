"""Adapters at the serialized CUE, KG, and MCP boundary."""

from .full_index import FULL_INDEX_SCHEMA, normalize_full_index, validate_full_index

__all__ = ["FULL_INDEX_SCHEMA", "normalize_full_index", "validate_full_index"]
