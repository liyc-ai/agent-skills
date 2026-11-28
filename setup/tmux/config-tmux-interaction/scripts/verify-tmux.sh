#!/usr/bin/env bash
# Print oh-my-tmux install status and the tmux interaction settings
# relevant to this skill.
set -u

if ! command -v tmux >/dev/null 2>&1; then
	echo "error: tmux not found" >&2
	exit 2
fi

conf=""
for candidate in "$HOME/.tmux.conf" "${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf"; do
	if [ -f "$candidate" ]; then
		conf="$candidate"
		break
	fi
done
if [ -n "$conf" ]; then
	local_conf="${conf}.local"
else
	local_conf="$HOME/.tmux.conf.local"
fi

echo "== tmux =="
tmux -V
printf 'TERM=%s TERM_PROGRAM=%s\n' "${TERM:-}" "${TERM_PROGRAM:-}"

echo
echo "== oh-my-tmux =="
if [ -n "$conf" ]; then
	ls -l "$conf"
else
	echo "config not found in ~/.tmux.conf or \$XDG_CONFIG_HOME/tmux/tmux.conf"
fi
if [ -d "$HOME/.tmux/.git" ]; then
	printf 'repo: %s\n' "$HOME/.tmux"
	git -C "$HOME/.tmux" log -1 --format='commit: %h %cs %s' 2>/dev/null || true
else
	echo "repo: ~/.tmux is missing or not a git clone (custom install path?)"
fi
if [ -f "$local_conf" ]; then
	printf 'local: %s\n' "$local_conf"
	grep -nE '^[[:space:]]*tmux_conf_(copy_to_os_clipboard|new_window_retain_current_path|preserve_stock_bindings|theme_status_right)=' \
		"$local_conf" 2>/dev/null || true
else
	echo "local: $local_conf not found"
fi

server_running=0
if tmux list-sessions >/dev/null 2>&1; then
	server_running=1
fi

echo
echo "== options =="
if [ "$server_running" -eq 1 ]; then
	for opt in mouse mode-keys status-keys set-clipboard history-limit \
		default-terminal prefix2; do
		value=$(tmux show-options -gv "$opt" 2>/dev/null || true)
		printf '%-16s %s\n' "$opt" "${value:-<unset>}"
	done
else
	echo "tmux server not running; start tmux to inspect live options"
fi

if [ "$server_running" -eq 1 ]; then
	status_right=$(tmux show-options -gv status-right 2>/dev/null || true)
	case "$status_right" in
		*pane_current_path*) echo "status-right: shows the current pane path" ;;
		*) echo "status-right: current pane path not configured" ;;
	esac
fi

echo
echo "== bindings =="
tmux list-keys -T prefix c 2>/dev/null || true
tmux list-keys -T copy-mode-vi Enter 2>/dev/null || true
tmux list-keys -T copy-mode-vi y 2>/dev/null || true
tmux list-keys -T copy-mode-vi MouseDragEnd1Pane 2>/dev/null || true
tmux list-keys -T root MouseDrag1Pane 2>/dev/null || true
tmux list-keys -T root DoubleClick1Pane 2>/dev/null || true
tmux list-keys -T root TripleClick1Pane 2>/dev/null || true

echo
if [ "$server_running" -eq 1 ]; then
	if tmux list-keys -T copy-mode-vi y 2>/dev/null | grep -q pbcopy; then
		echo "clipboard: copy-mode y writes to pbcopy"
	else
		echo "clipboard: copy-mode y does NOT invoke pbcopy"
		echo "           check tmux_conf_copy_to_os_clipboard=true in $local_conf"
	fi
else
	echo "clipboard: skipped (server not running)"
fi

echo
echo "== panes =="
tmux list-panes -a -F \
	'pane=#{pane_id} win=#{window_index}:#{window_name} cmd=#{pane_current_command} alt=#{alternate_on} mouse_any=#{mouse_any_flag} hist=#{history_size}/#{history_limit}' \
	2>/dev/null || true

if [ "$server_running" -eq 1 ]; then
	alt_claude=$(tmux list-panes -a -F '#{pane_current_command} #{alternate_on}' 2>/dev/null |
		awk '$1 ~ /claude/ && $2 == 1 { n++ } END { print n + 0 }')
	if [ "${alt_claude:-0}" -gt 0 ]; then
		echo "note: $alt_claude claude pane(s) are on the alternate screen (fullscreen renderer);"
		echo "      their output is not in tmux scrollback. Run /tui default there,"
		echo "      or use Ctrl+O then [ to write the transcript into the scrollback."
	fi
fi

echo
if command -v pbcopy >/dev/null 2>&1; then
	echo "pbcopy: $(command -v pbcopy)"
else
	echo "pbcopy: not found (Linux: use xclip/wl-copy in the copy-pipe binding)"
fi

cat <<'EOF'

Manual checks:
  1) prefix + e opens ~/.tmux.conf.local; prefix + r reloads.
  2) prefix + c -> prompt "窗口名称:"; Enter accepts, C-u clears;
     the new window opens in the current pane's directory.
  3) wheel / two-finger scroll -> copy-mode; q exits; prefix + m toggles mouse.
  4) select multiple lines, release inside the pane, then run: pbpaste
     (Enter or y also copy while in copy-mode).
  5) in a codex pane (mouse_any=0), drag/double-click in the transcript must
     select normally; only the bottom 5 rows are ignored. Wheel up first if
     the selection has to start in the bottom rows.
  6) in a claude pane, run /tui to print the renderer. fullscreen (alt=1) keeps
     the conversation out of tmux scrollback; /tui default switches it back.
     in fullscreen, Ctrl+O then [ writes the whole transcript into the terminal
     scrollback, where prefix + [ and Cmd+F can find it.
  7) prefix + maximizes the current pane to its own window; prefix + ? lists keys.
  8) status bar bottom-right shows the current pane's directory. cd into
     another directory and wait one status-interval (10s) for it to update.
EOF
