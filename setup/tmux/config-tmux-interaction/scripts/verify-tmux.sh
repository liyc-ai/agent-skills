#!/usr/bin/env bash
# Print the tmux interaction settings and bindings relevant to this skill.
set -u

if ! command -v tmux >/dev/null 2>&1; then
	echo "error: tmux not found" >&2
	exit 2
fi

echo "== tmux =="
tmux -V
printf 'TERM=%s TERM_PROGRAM=%s\n' "${TERM:-}" "${TERM_PROGRAM:-}"

echo
echo "== options =="
for opt in mouse mode-keys set-clipboard history-limit; do
	value=$(tmux show-options -g "$opt" 2>/dev/null | sed "s/^$opt //")
	printf '%-14s %s\n' "$opt" "${value:-<unset>}"
done

echo
echo "== bindings =="
tmux list-keys -T prefix c 2>/dev/null || true
tmux list-keys -T copy-mode-vi Enter 2>/dev/null || true
tmux list-keys -T copy-mode-vi MouseDragEnd1Pane 2>/dev/null || true
tmux list-keys -T copy-mode Enter 2>/dev/null || true

echo
echo "== panes =="
tmux list-panes -a -F \
	'pane=#{pane_id} win=#{window_index}:#{window_name} cmd=#{pane_current_command} alt=#{alternate_on} hist=#{history_size}/#{history_limit}' \
	2>/dev/null || true

echo
if command -v pbcopy >/dev/null 2>&1; then
	echo "pbcopy: $(command -v pbcopy)"
else
	echo "pbcopy: not found (Linux: use xclip/wl-copy in the copy-pipe binding)"
fi

cat <<'EOF'

Manual checks:
  1) prefix + c -> prompt "窗口名称:"; Enter accepts, C-u clears.
  2) wheel / two-finger scroll -> copy-mode; q exits.
  3) select multiple lines, release inside the pane, then run: pbpaste
  4) if released over the status bar/outside, press Enter while still in copy-mode.
EOF
