---
name: config-tmux-interaction
description: >-
  配置 tmux 的新窗口命名、鼠标/触摸板滚动和选中内容复制到系统剪贴板，
  并排查多行复制失败、历史不足等问题。Use when setting up tmux mouse/copy
  behavior, 新建窗口自动提示重命名, 选中即复制, or debugging tmux
  scrollback and copy-mode. Codex TUI 自身的 transcript/alternate-screen
  问题见 setup/codex/config-codex-tui-scrollback。
metadata:
  short-description: tmux 窗口命名、滚动与复制
---

# tmux 交互配置

目标：新建窗口时提示命名；鼠标或触摸板可以查看历史；选中内容后按 Enter
或松开鼠标即复制到系统剪贴板。

已在 tmux 3.5a + macOS 的 `pbcopy` 上验证。Linux 把 `pbcopy` 换成
`xclip -selection clipboard` 或 `wl-copy`。

## 先诊断

```bash
tmux -V
tmux show-options -g mouse
tmux show-options -g history-limit
tmux list-panes -a -F \
  'pane=#{pane_id} cmd=#{pane_current_command} alt=#{alternate_on} hist=#{history_size}/#{history_limit}'
```

`alt=1` 表示当前 pane 运行在 alternate screen（例如 Codex TUI）。这种应用的
内容不会进入 tmux scrollback，调大 `history-limit` 也看不到；先看
[Codex TUI 回滚配置](../../codex/config-codex-tui-scrollback/SKILL.md)。

## 核心配置

写入 `~/.tmux.conf`：

```tmux
# 新窗口：保留当前目录，然后提示命名
bind c new-window -c "#{pane_current_path}" \; \
	command-prompt -p "窗口名称:" -I "#{b:pane_current_path}" \
	"rename-window -- '%%'"

# 鼠标/触摸板滚动；history-limit 只对新建 pane 生效
set -g mouse on
set -g history-limit 100000

# copy-mode 使用 vi 键位
set -g mode-keys vi
set -g set-clipboard on

# 选中内容 + Enter 复制到 macOS 剪贴板
bind -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "pbcopy"
bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"

# 鼠标拖选后松开也直接复制
bind -T copy-mode-vi MouseDragEnd1Pane \
	send-keys -X copy-pipe-and-cancel "pbcopy"

# 双击选词、三击选行
bind -T copy-mode-vi DoubleClick1Pane select-pane \; \
	send-keys -X select-word \; run-shell -d 0.3 \; \
	send-keys -X copy-pipe-and-cancel "pbcopy"
bind -T copy-mode-vi TripleClick1Pane select-pane \; \
	send-keys -X select-line \; run-shell -d 0.3 \; \
	send-keys -X copy-pipe-and-cancel "pbcopy"
```

完整示例见 [references/tmux.conf.example](references/tmux.conf.example)。

## 使用方式

- `prefix + c`：在当前目录新建窗口，底部出现 `窗口名称:`。
  - 默认值是当前目录名，直接 Enter 即可使用。
  - 默认值只是插入光标前，不是全选；想输入全新名称时先按 `C-u` 清空。
  - `rename-window` 会关闭该窗口的 `automatic-rename`，名称不会被运行的
    命令覆盖。
- 滚轮或触摸板双指滑动：自动进入 copy-mode，浏览 `history-limit` 行；
  `q` 退出。
- 左键拖选：选择文本；拖拽 pane 边框：调整 pane 大小。
- `Enter` 或 `y`：复制当前选择并退出 copy-mode。
- 鼠标拖选后松开：直接在 `MouseDragEnd1Pane` 中复制并退出。
- 双击选词、三击选行：复制并退出。

## 多行复制排查

多行复制本身是支持的；失败通常不是 tmux 的 `copy-pipe` 问题。

1. **松开鼠标时落在状态栏或窗口外**：tmux 收不到
   `MouseDragEnd1Pane`，自动复制不会触发，但通常仍停留在 copy-mode。
   直接按 `Enter`（或 `y`）复制当前多行选择。
2. **按住 Shift 拖拽**：这会绕过 tmux，使用终端自带的选择，不会触发
   tmux 的自动复制。多行请用普通左键拖拽。
3. **终端没有发送拖拽移动事件**：极快拖动或某些终端手势可能只发送按下/
   松开，选区无法扩展。放慢拖动，或改用键盘：`prefix + [` → vi 移动 →
   `Space` 开始选择 → `Enter`。
4. **`pbpaste` 正常但粘贴结果不对**：说明复制已成功，问题在目标程序的
   粘贴行为（例如单行输入框吞掉换行）。

快速确认剪贴板内容：

```bash
pbpaste | cat -vet
```

## 验证

```bash
tmux show-options -g mouse set-clipboard history-limit mode-keys
tmux list-keys -T prefix c
tmux list-keys -T copy-mode-vi Enter
tmux list-keys -T copy-mode-vi MouseDragEnd1Pane

# 手动测试：选中两行以上，松开在 pane 内，然后运行
pbpaste
```

也可运行 [scripts/verify-tmux.sh](scripts/verify-tmux.sh)，它会打印当前
选项、绑定和 pane 的 `alt/history` 状态。

## 约束

- `history-limit`、`default-terminal` 等设置在新建 pane 时生效；已经存在的
  pane 不会因为 `source-file` 而扩容。需要更大历史时新建窗口/pane，或重启
  tmux server。
- `set -g mouse on` 后，终端自带的选择通常要按住 `Shift` 才能使用；这也是
  tmux 选择与终端选择的分界。
- `set -g set-clipboard on` 是补充；macOS 上最确定的系统剪贴板路径是
  `copy-pipe-and-cancel "pbcopy"`。
