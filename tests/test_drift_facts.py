from __future__ import annotations

import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).parents[1]
DRIFT_FACTS = ROOT / ".kg" / "codex" / "tools" / "drift-facts"
CONTEXT_WRAPPER = (
    "sh -c 'd=$PWD; while [ \"$d\" != / ]; do p=$d/.kg/hooks/codex/user-prompt-submit; "
    "[ -f \"$p\" ] && exec sh \"$p\"; d=${d%/*}; done; exit 0'"
)
DRIFT_WRAPPER = (
    "sh -c 'd=$PWD; while [ \"$d\" != / ]; do p=$d/.kg/codex/tools/drift-hook; "
    "[ -f \"$p\" ] && exec sh \"$p\"; d=${d%/*}; done; exit 0'"
)


def _init_repo(root: Path) -> None:
    subprocess.run(["git", "init", "--quiet"], cwd=root, check=True)


def _facts(root: Path, environment: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [str(DRIFT_FACTS)], cwd=root, env=environment, capture_output=True, text=True, check=False
    )


def test_drift_facts_preserves_small_fixture_semantics() -> None:
    with tempfile.TemporaryDirectory() as temp:
        root = Path(temp)
        _init_repo(root)
        (root / "included.txt").write_text("included", encoding="utf-8")
        (root / "node_modules").mkdir()
        (root / "node_modules" / "ignored.txt").write_text("ignored", encoding="utf-8")

        result = _facts(root)

        assert result.returncode == 0, result.stderr
        facts = json.loads(result.stdout)
        assert facts["schema"] == "codex-drift-facts.v1"
        assert facts["repo"] == {"filesByPath": {"included.txt": True}}
        assert facts["patch"] == {
            "changes": [
                {"action": "added", "path": "included.txt"},
                {"action": "added", "path": "node_modules/ignored.txt"},
            ]
        }


def test_drift_facts_streams_payload_larger_than_arg_max() -> None:
    arg_max = int(subprocess.run(["getconf", "ARG_MAX"], capture_output=True, check=True, text=True).stdout)
    with tempfile.TemporaryDirectory() as temp:
        root = Path(temp)
        _init_repo(root)
        payload_size = 0
        index = 0
        while payload_size <= arg_max + 262_144:
            name = f"payload-{index:06d}-{'x' * 220}"
            (root / name).touch()
            payload_size += len(name) + 8
            index += 1

        result = _facts(root)

        assert result.returncode == 0, result.stderr
        facts = json.loads(result.stdout)
        assert len(json.dumps(facts["repo"], separators=(",", ":"))) > arg_max


def test_drift_facts_rejects_malformed_streamed_json() -> None:
    with tempfile.TemporaryDirectory() as temp:
        root = Path(temp)
        _init_repo(root)
        fake_bin = root / "bin"
        fake_bin.mkdir()
        jq = shutil.which("jq")
        assert jq is not None
        fake_jq = fake_bin / "jq"
        fake_jq.write_text(
            "#!/bin/sh\n"
            'case " $* " in *" -Rn "*) printf \'%s\\n\' \'{malformed\' ;; *) exec "$REAL_JQ" "$@" ;; esac\n',
            encoding="utf-8",
        )
        fake_jq.chmod(0o755)
        environment = {**os.environ, "PATH": f"{fake_bin}:{os.environ['PATH']}", "REAL_JQ": jq}

        result = _facts(root, environment)

        assert result.returncode != 0


def test_user_prompt_submit_wrappers_both_succeed() -> None:
    event = '{"hook_event_name":"UserPromptSubmit","prompt":"drift hook regression"}\n'
    with tempfile.TemporaryDirectory() as temp:
        fake_bin = Path(temp)
        fake_kg = fake_bin / "kg"
        fake_kg.write_text(
            "#!/bin/sh\n"
            'case "$1" in vet) exit 0 ;; query) printf \'{}\' ;; index) printf \'{"summary":{}}\' ;; esac\n',
            encoding="utf-8",
        )
        fake_kg.chmod(0o755)
        environment = {**os.environ, "PATH": f"{fake_bin}:{os.environ['PATH']}"}
        for wrapper in (CONTEXT_WRAPPER, DRIFT_WRAPPER):
            result = subprocess.run(
                wrapper,
                cwd=ROOT,
                shell=True,
                env=environment,
                input=event,
                capture_output=True,
                text=True,
                check=False,
            )
            assert result.returncode == 0, result.stderr
