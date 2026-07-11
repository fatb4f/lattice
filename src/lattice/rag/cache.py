"""Revision- and input-addressed runtime artifact caching."""

from __future__ import annotations

import asyncio
import json
import multiprocessing
import os
import tempfile
from collections.abc import Callable
from pathlib import Path
from typing import Any, TypeVar

from .provenance import canonical_json, sha256_digest

T = TypeVar("T")


def _process_operation(
    connection: Any, operation: Callable[..., Any], args: tuple[Any, ...], kwargs: dict[str, Any]
) -> None:
    try:
        connection.send((True, operation(*args, **kwargs)))
    except BaseException as exc:  # pragma: no cover - exercised through the parent boundary
        connection.send((False, exc))
    finally:
        connection.close()


def cache_key(kind: str, revision: str, inputs: Any, tools: Any) -> str:
    return sha256_digest({"kind": kind, "revision": revision, "inputs": inputs, "tools": tools}).removeprefix("sha256:")


class ArtifactCache:
    """Small content-addressed cache that never treats cached data as authority."""

    def __init__(self, root: str | Path) -> None:
        self.root = Path(root)

    def _path(self, kind: str, key: str) -> Path:
        if not kind.replace("-", "").isalnum() or len(key) != 64 or any(char not in "0123456789abcdef" for char in key):
            raise ValueError("invalid cache address")
        return self.root / kind / f"{key}.json"

    def get(self, kind: str, key: str) -> Any | None:
        path = self._path(kind, key)
        try:
            value = json.loads(path.read_text(encoding="utf-8"))
        except (FileNotFoundError, json.JSONDecodeError, UnicodeDecodeError, OSError):
            return None
        if (
            not isinstance(value, dict)
            or value.get("schema") != "lattice.runtime-cache-entry.v1"
            or value.get("kind") != kind
            or value.get("key") != key
        ):
            return None
        artifact = value.get("artifact")
        artifact_digest = sha256_digest(artifact)
        if value.get("artifactDigest") != artifact_digest:
            return None
        if value.get("bindingDigest") != sha256_digest({"kind": kind, "key": key, "artifactDigest": artifact_digest}):
            return None
        return artifact

    def put(self, kind: str, key: str, artifact: Any) -> Path:
        path = self._path(kind, key)
        path.parent.mkdir(parents=True, exist_ok=True)
        artifact_digest = sha256_digest(artifact)
        payload = canonical_json(
            {
                "schema": "lattice.runtime-cache-entry.v1",
                "kind": kind,
                "key": key,
                "artifactDigest": artifact_digest,
                "bindingDigest": sha256_digest({"kind": kind, "key": key, "artifactDigest": artifact_digest}),
                "artifact": artifact,
            }
        )
        descriptor, temporary = tempfile.mkstemp(prefix=f".{key}.", dir=path.parent)
        try:
            with os.fdopen(descriptor, "wb") as output:
                output.write(payload)
                output.flush()
                os.fsync(output.fileno())
            os.replace(temporary, path)
        finally:
            if os.path.exists(temporary):
                os.unlink(temporary)
        return path

    def get_or_compute(self, kind: str, key: str, producer: Callable[[], T]) -> tuple[T, bool]:
        cached = self.get(kind, key)
        if cached is not None:
            return cached, True
        artifact = producer()
        self.put(kind, key, artifact)
        return artifact, False


class BoundedExecutor:
    def __init__(self, concurrency: int = 4, timeout: float = 20.0) -> None:
        if concurrency < 1 or timeout <= 0:
            raise ValueError("execution bounds must be positive")
        self._semaphore = asyncio.Semaphore(concurrency)
        self.timeout = timeout

    async def run(self, operation: Callable[..., T], *args: Any, **kwargs: Any) -> T:
        async with self._semaphore:
            return await self._run_process(operation, args, kwargs)

    async def _run_process(self, operation: Callable[..., T], args: tuple[Any, ...], kwargs: dict[str, Any]) -> T:
        context = multiprocessing.get_context("spawn")
        parent, child = context.Pipe(duplex=False)
        process = context.Process(target=_process_operation, args=(child, operation, args, kwargs), daemon=True)
        process.start()
        child.close()
        loop = asyncio.get_running_loop()
        deadline = loop.time() + self.timeout
        try:
            while not parent.poll():
                remaining = deadline - loop.time()
                if remaining <= 0:
                    raise TimeoutError("operation exceeded its execution deadline")
                await asyncio.sleep(min(0.01, remaining))
            ok, value = parent.recv()
            process.join(timeout=1)
            if ok:
                return value
            raise value
        finally:
            parent.close()
            if process.is_alive():
                process.terminate()
                process.join(timeout=1)
                if process.is_alive():
                    process.kill()
                    process.join()
