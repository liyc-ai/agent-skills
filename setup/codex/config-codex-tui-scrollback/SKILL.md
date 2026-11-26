---
name: config-codex-tui-scrollback
description: >-
  解决 Codex CLI 在 tmux 中长会话无法回看、内容显示不全的问题：使用
  Ctrl+T 打开 transcript pager，或设置 [tui] alternate_screen = "never"
  / --no-alt-screen 保留终端 scrollback。Use when Codex TUI output is
  truncated, 无法向上滚动, tmux 看不到历史, or configuring Codex
  alternate screen.
metadata:
  short-description: Codex 长会话回滚与 tmux 历史
---

# Codex TUI 长会话回滚

## 症状

Codex 在 tmux 中运行，滚轮或触摸板只能看到当前屏；长对话向上滚不到之前的
内容。把 tmux 的 `history-limit` 调得很大也没有改善，装了 oh-my-tmux 也
一样。

## 根因

Codex 默认进入 **alternate screen**。tmux 不会把备用屏幕的内容写入自己的
scrollback，所以 copy-mode 只能看到当前可见屏幕。这是 tmux 和终端之间的
边界，换哪套 tmux 配置都绕不过去。

在 tmux 里检查：

```bash
tmux display-message -p '#{alternate_on} #{history_size}/#{history_limit}'
```

典型输出：

```text
1 26/2000
```

- `alternate_on=1`：Codex 正在使用备用屏幕。
- `history_size` 可能只有几十行，和 `history_limit` 无关。
- 同一个 tmux server 里其他普通 shell pane 不受影响。

## 立即查看：Ctrl+T

不需要重启 Codex，在 Codex 窗口按：

```text
Ctrl+T
```

会打开 Codex 的 `TRANSCRIPT` pager。默认键位：

- `↑/↓`：逐行滚动
- `PgUp/PgDn`：翻页
- `Home/End`：跳到开头/结尾
- `f3`：搜索
- `q`：关闭

Codex 主界面按 `?` 可以查看当前版本的全部快捷键。已在 codex-cli 0.169.0
验证。

## 永久保留终端 scrollback

在 `~/.codex/config.toml` 中写入：

```toml
[tui]
alternate_screen = "never"
```

等价于每次启动都带：

```bash
codex --no-alt-screen
```

Codex 会改用 inline mode，把输出写入终端 scrollback。之后 tmux 的滚轮、
触摸板和 copy-mode 就能看到完整历史；tmux 侧的鼠标/复制配置见
[config-tmux-interaction](../../tmux/config-tmux-interaction/SKILL.md)。

`alternate_screen` 的值是**字符串**，不是布尔值。写 `false` 会直接报配置
错误：

```text
invalid type: unit variant, expected string only
in `tui.alternate_screen`
```

支持的值至少包括 `"always"` 和 `"never"`。

## 和 oh-my-tmux 的关系

oh-my-tmux 管的是 tmux 这一侧：滚轮进 copy-mode、拖选复制、`history-limit`
默认 5000（可按
[config-tmux-interaction](../../tmux/config-tmux-interaction/SKILL.md) 调大）。
它管不到 Codex 的备用屏幕。所以两件事要分开做：

- `alternate_screen = "never"`（或 `--no-alt-screen`）：让 Codex 把输出写进
  终端 scrollback；
- oh-my-tmux 的鼠标/复制配置：让这些 scrollback 能滚、能选、能复制。

只装 oh-my-tmux 而 Codex 仍是 `"always"`，滚轮依然只能看到当前屏。

## 生效范围

- **只影响新启动的 Codex 进程**。已经运行的会话仍使用启动时的模式，需要
  退出重开；重开前可以先用 `Ctrl+T` 查看。
- **tmux 的 `history-limit` 只对新建 pane 生效**。如果当前 pane 的
  `hist` 仍是 `.../5000`（oh-my-tmux 默认值），即使已按 tmux skill 把
  local 配置改成 `100000`，这个 pane 也不会自动扩容。新建窗口/pane，或
  重启 tmux server 后才会使用新上限。
- 想保留当前会话又换到新 pane，可以新建窗口后运行：

  ```bash
  codex resume --last
  ```

## 验证

```bash
# 配置值（不依赖 Python 3.11+）
awk '
  /^[[:space:]]*\[/ { in_tui = ($0 ~ /^[[:space:]]*\[tui\][[:space:]]*$/) }
  in_tui && /^[[:space:]]*alternate_screen[[:space:]]*=/ { print }
' ~/.codex/config.toml

# 运行中的 pane
tmux list-panes -a -F \
  'pane=#{pane_id} cmd=#{pane_current_command} alt=#{alternate_on} hist=#{history_size}/#{history_limit}'
```

新开的 Codex 应显示 `alt=0`。若仍是 `alt=1`，确认 Codex 是否真的重新启动，
以及启动时是否带了 `--no-alt-screen` 或被 profile/项目配置覆盖。

也可运行
[scripts/verify-codex-scrollback.sh](scripts/verify-codex-scrollback.sh)。

## 取舍

- `alternate_screen = "never"`：保留完整 scrollback，适合 tmux 工作流；
  但 TUI 重绘可能留下历史行，界面不如备用屏幕干净。
- `alternate_screen = "always"` + `Ctrl+T`：TUI 更干净，长会话通过 Codex
  自己的 transcript pager 查看。若 inline mode 出现渲染异常，改回
  `"always"` 即可。

---

已在 codex-cli 0.169.0 (macOS) 上验证：`Ctrl+T` 能打开 transcript pager；
`[tui] alternate_screen = "never"` 能让新会话的 `alternate_on` 变为 `0`。
codex-cli 0.172.0 的 `--help` 仍包含 `--no-alt-screen`，配置键也仍然有效。
