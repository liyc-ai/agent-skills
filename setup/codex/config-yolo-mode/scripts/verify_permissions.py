#!/usr/bin/env python3
"""Report the permission settings Codex would actually send to the model.

Behavior follows the real config chain (user config, project config, profile,
CLI overrides) without calling the model: it renders the prompt input and
extracts the `<permissions instructions>` block.
"""

import argparse
import os
import re
import subprocess
import sys


def run(cmd, cwd, env):
    return subprocess.run(
        cmd, cwd=cwd, env=env, capture_output=True, text=True, timeout=180
    )


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--codex-home", help="override CODEX_HOME (default: current env)")
    ap.add_argument("--cwd", default=os.getcwd(), help="directory to evaluate")
    ap.add_argument("--profile", "-p", help="config profile from $CODEX_HOME/<name>.config.toml")
    ap.add_argument(
        "-c",
        "--config",
        action="append",
        default=[],
        metavar="KEY=VALUE",
        help="config override, repeatable",
    )
    args = ap.parse_args()

    env = dict(os.environ)
    if args.codex_home:
        env["CODEX_HOME"] = os.path.expanduser(args.codex_home)

    cmd = ["codex"]
    if args.profile:
        cmd += ["-p", args.profile]
    for override in args.config:
        cmd += ["-c", override]
    cmd += ["debug", "prompt-input", "hi"]

    try:
        proc = run(cmd, args.cwd, env)
    except FileNotFoundError:
        print("error: `codex` not found on PATH", file=sys.stderr)
        return 2
    except subprocess.TimeoutExpired:
        print("error: `codex debug prompt-input` timed out", file=sys.stderr)
        return 2

    if proc.returncode != 0:
        print(f"error: codex exited {proc.returncode}", file=sys.stderr)
        print(proc.stderr.strip()[-2000:], file=sys.stderr)
        return 2

    match = re.search(
        r"<permissions instructions>(.*?)</permissions instructions>", proc.stdout, re.S
    )
    if not match:
        print("error: no <permissions instructions> block found", file=sys.stderr)
        return 2

    block = match.group(1).replace("\\n", "\n").strip()

    def grab(pattern, default="unknown"):
        found = re.search(pattern, block, re.I)
        return found.group(1) if found else default

    mode = grab(r"`sandbox_mode` is `([^`]+)`")
    network = "enabled" if re.search(r"Network access is enabled", block, re.I) else "restricted"

    # `never` has its own sentence; other policies are described through the
    # escalation section instead of a fixed phrase.
    if re.search(r"Approval policy is currently never", block, re.I):
        approval = "never"
    elif re.search(r"# Escalation Requests|approved by the user", block, re.I):
        approval = "on-request (escalation available)"
    else:
        approval = grab(r"Approval policy is (?:currently )?`?([A-Za-z_-]+)`?")

    print(f"sandbox_mode      = {mode}")
    print(f"approval policy   = {approval}")
    print(f"network           = {network}")
    print(f"cwd               = {args.cwd}")
    if args.profile:
        print(f"profile           = {args.profile}")

    warnings = [line for line in proc.stderr.splitlines() if line.strip()]
    if warnings:
        print("\nstderr (project config / policy warnings):")
        for line in warnings[-6:]:
            print(f"  {line.strip()}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
