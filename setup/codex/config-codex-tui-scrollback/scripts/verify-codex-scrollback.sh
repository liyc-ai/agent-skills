#!/usr/bin/env bash
# Check Codex alternate-screen config and the state of running tmux panes.
set -u

if ! command -v codex >/dev/null 2>&1; then
	echo "error: codex not found" >&2
	exit 2
fi

echo "== codex =="
codex --version 2>/dev/null | head -1
if codex --help 2>/dev/null | grep -q -- '--no-alt-screen'; then
	echo "CLI: --no-alt-screen available"
else
	echo "CLI: --no-alt-screen NOT found (check codex version)"
fi

echo
echo "== config =="
home="${CODEX_HOME:-$HOME/.codex}"
path="$home/config.toml"
echo "config: $path"

if [ ! -f "$path" ]; then
	echo "missing config.toml"
else
	# Read only the [tui] table; avoids depending on Python 3.11+ / tomllib.
	value=$(awk '
		/^[[:space:]]*\[/ { in_tui = ($0 ~ /^[[:space:]]*\[tui\][[:space:]]*$/); next }
		in_tui && /^[[:space:]]*alternate_screen[[:space:]]*=/ {
			line = $0
			sub(/^[^=]*=[[:space:]]*/, "", line)
			sub(/[[:space:]]*#.*$/, "", line)
			gsub(/"/, "", line)
			print line
			exit
		}
	' "$path")
	value="${value:-<unset>}"
	printf 'tui.alternate_screen = %s\n' "$value"

	case "$value" in
		never)
			echo "OK: new Codex sessions will use inline mode (terminal scrollback)."
			;;
		always)
			echo "NOTE: alternate screen is forced; use Ctrl+T for long transcripts."
			;;
		"<unset>")
			echo "NOTE: using Codex default; use Ctrl+T if tmux cannot scroll back."
			;;
		*)
			echo "NOTE: unrecognized value; check Codex config docs."
			;;
	esac
fi

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

Note: oh-my-tmux can make inline-mode scrollback selectable/copyable, but it
cannot record alternate-screen content. alternate_screen = "never" (or
--no-alt-screen) is still required for tmux to see the full transcript.
EOF
