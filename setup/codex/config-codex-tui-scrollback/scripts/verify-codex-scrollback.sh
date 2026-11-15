#!/usr/bin/env bash
# Check Codex alternate-screen config and the state of running tmux panes.
set -u

if ! command -v codex >/dev/null 2>&1; then
	echo "error: codex not found" >&2
	exit 2
fi

echo "== codex =="
codex --version 2>/dev/null | head -1

echo
echo "== config =="
python3 - <<'PY'
import os
import pathlib
import sys

try:
    import tomllib
except ImportError:
    print("error: Python 3.11+ is required for tomllib", file=sys.stderr)
    raise SystemExit(2)

home = pathlib.Path(os.environ.get("CODEX_HOME", pathlib.Path.home() / ".codex"))
path = home / "config.toml"
print(f"config: {path}")

if not path.exists():
    print("missing config.toml")
    raise SystemExit(0)

try:
    config = tomllib.loads(path.read_text())
except Exception as exc:
    print(f"parse error: {exc}", file=sys.stderr)
    raise SystemExit(1)

value = config.get("tui", {}).get("alternate_screen", "<unset>")
print(f"tui.alternate_screen = {value!r}")

if value == "never":
    print("OK: new Codex sessions will use inline mode (terminal scrollback).")
elif value == "always":
    print("NOTE: alternate screen is forced; use Ctrl+T for long transcripts.")
else:
    print("NOTE: using Codex default; use Ctrl+T if tmux cannot scroll back.")
PY

if command -v tmux >/dev/null 2>&1; then
	echo
	echo "== running panes =="
	tmux list-panes -a -F \
		'pane=#{pane_id} cmd=#{pane_current_command} alt=#{alternate_on} hist=#{history_size}/#{history_limit}' \
		2>/dev/null || true
	echo
	echo "alt=1 means alternate screen; tmux cannot scroll that pane's history."
fi

cat <<'EOF'

Inside Codex:
  Ctrl+T   open transcript pager
  ↑/↓      scroll
  PgUp/PgDn, Home/End
  f3       find
  q        close
EOF
