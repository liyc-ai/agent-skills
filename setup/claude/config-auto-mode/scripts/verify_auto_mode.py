#!/usr/bin/env python3
"""Report the effective Claude Code permission mode and verify auto mode.

Usage:
  python3 verify_auto_mode.py [--cwd DIR] [--no-live]

The live check starts `claude -p ... --max-turns 0` and reads `permissionMode`
from the init event. It does not call a model.
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path


def load_json(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return None
    except Exception as exc:  # noqa: BLE001 - report and continue
        print(f"  ! cannot parse {path}: {exc}")
        return None


def describe_sources(cwd: Path):
    sources = [
        ("user", Path.home() / ".claude/settings.json"),
        ("user-local", Path.home() / ".claude/settings.local.json"),
        ("project", cwd / ".claude/settings.json"),
        ("project-local", cwd / ".claude/settings.local.json"),
    ]

    user_mode = None
    project_auto = []
    disabled = []

    print(f"cwd: {cwd}")
    print()
    print("settings files:")
    for label, path in sources:
        data = load_json(path)
        if data is None:
            print(f"  {label:<13} {path}  (missing)")
            continue

        permissions = data.get("permissions") or {}
        mode = permissions.get("defaultMode")
        print(f"  {label:<13} {path}  defaultMode={mode!r}")

        if label.startswith("user") and mode:
            user_mode = mode
        if label.startswith("project") and mode == "auto":
            project_auto.append(path)

        disable = permissions.get("disableAutoMode", data.get("disableAutoMode"))
        if disable:
            disabled.append((path, disable))

    print()
    if project_auto:
        for path in project_auto:
            print(
                f"  ! {path} sets defaultMode=auto; project-level settings "
                "cannot grant auto mode, this value is ignored (and can shadow "
                "your user-level mode). Remove it and set it in "
                "~/.claude/settings.json instead."
            )
    if disabled:
        for path, value in disabled:
            print(
                f"  ! {path} sets disableAutoMode={value!r}; auto mode is "
                "turned off while this applies."
            )
    if user_mode and user_mode != "auto":
        print(
            f"  ! user settings defaultMode={user_mode!r}, not 'auto'. "
            "Set it in ~/.claude/settings.json to make auto the default."
        )
    if not user_mode and not project_auto:
        print(
            "  note: no defaultMode configured in user settings; the session "
            "will fall back to the built-in default (possibly auto on newer "
            "versions, depending on rollout flags)."
        )

    return user_mode


def live_mode(cwd: Path):
    claude = shutil.which("claude")
    if not claude:
        print("live check: skipped (claude not found in PATH)")
        return None

    cmd = [
        claude,
        "-p",
        "ok",
        "--output-format",
        "stream-json",
        "--verbose",
        "--max-turns",
        "0",
    ]
    try:
        proc = subprocess.run(
            cmd,
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=90,
            env=os.environ.copy(),
        )
    except subprocess.TimeoutExpired:
        print("live check: timed out after 90s")
        return None
    except Exception as exc:  # noqa: BLE001
        print(f"live check: failed to start claude: {exc}")
        return None

    mode = None
    for line in proc.stdout.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if event.get("type") == "system" and event.get("subtype") == "init":
            mode = event.get("permissionMode")
            break

    if mode is None:
        stderr = (proc.stderr or "").strip().splitlines()
        detail = f": {stderr[-1]}" if stderr else ""
        print(f"live check: could not read an init event (exit {proc.returncode}){detail}")
        return None

    print(f"live permissionMode = {mode}")
    return mode


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cwd", default=os.getcwd(), help="directory to check (default: current)")
    parser.add_argument("--no-live", action="store_true", help="skip the live claude -p check")
    args = parser.parse_args()

    cwd = Path(args.cwd).expanduser().resolve()
    user_mode = describe_sources(cwd)
    print()

    if args.no_live:
        ok = user_mode == "auto"
        print("live check: skipped (--no-live); based on user settings, "
              f"auto mode is {'configured' if ok else 'NOT configured'}.")
        return 0 if ok else 1

    mode = live_mode(cwd)
    if mode is None:
        return 2
    return 0 if mode == "auto" else 1


if __name__ == "__main__":
    sys.exit(main())
