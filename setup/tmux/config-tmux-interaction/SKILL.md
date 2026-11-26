---
name: config-tmux-interaction
description: >-
  用 oh-my-tmux（gpakosz/.tmux）搭好 tmux 基础配置，并在 .tmux.conf.local
  中补齐新窗口命名、鼠标/触摸板滚动、选中内容复制到系统剪贴板、Codex TUI
  误触选中防护；排查多行复制失败、历史不足、TUI 误选等问题。Use when
  installing or customizing oh-my-tmux (gpakosz/.tmux), setting up tmux
  mouse/copy behavior, 新建窗口自动提示重命名, 选中即复制, 误点输入框被
  选中/剪贴板被覆盖, or debugging tmux scrollback and copy-mode. Codex TUI
  自身的 transcript/alternate-screen 问题见
  setup/codex/config-codex-tui-scrollback。
metadata:
  short-description: oh-my-tmux 安装与窗口/滚动/复制
---

# tmux 交互配置（oh-my-tmux 底座）

目标：用 [oh-my-tmux](https://github.com/gpakosz/.tmux) 作为基础配置，再在
`~/.tmux.conf.local` 中补齐交互层：新窗口命名、鼠标/触摸板滚动、复制到系统
剪贴板、Codex TUI 误触保护。

已在 tmux 3.8 + oh-my-tmux master（`58a3dcc`）+ macOS `pbcopy` 上验证。
Linux 把 `pbcopy` 换成 `xclip -selection clipboard` 或 `wl-copy`。

## 安装 oh-my-tmux

要求：tmux >= 2.6；`awk`、`perl`、`grep`、`sed`；tmux 外
`TERM=xterm-256color`。

自动安装：

```bash
curl -fsSL "https://github.com/gpakosz/.tmux/raw/refs/heads/master/install.sh#$(date +%s)" | bash
```

手动安装到 `~`：

```bash
cd ~
git clone --single-branch https://github.com/gpakosz/.tmux.git
ln -s -f .tmux/.tmux.conf
cp .tmux/.tmux.conf.local .
```

安装后的结构：

| 路径 | 作用 |
| --- | --- |
| `~/.tmux/` | 配置仓库，升级用 `git -C ~/.tmux pull` |
| `~/.tmux.conf` | 指向 `~/.tmux/.tmux.conf` 的软链 |
| `~/.tmux.conf.local` | 个人配置，唯一应该修改的文件 |

也支持装在 `$XDG_CONFIG_HOME/tmux` 或 `~/.config/tmux`（此时文件名是
`tmux.conf` / `tmux.conf.local`，没有前导点）。

**不要修改** `.tmux.conf`；所有定制写进 `.tmux.conf.local`，升级时才不会
冲突。改完在 tmux 里按 `<prefix> r` 重载，`<prefix> e` 直接打开 local 文件。

## 先诊断

```bash
tmux -V
ls -l ~/.tmux.conf
git -C ~/.tmux log -1 --format='%h %cs %s'
tmux show-options -gv mouse
tmux show-options -gv history-limit
tmux show-options -gv mode-keys
tmux list-panes -a -F \
  'pane=#{pane_id} cmd=#{pane_current_command} alt=#{alternate_on} hist=#{history_size}/#{history_limit}'
```

`alt=1` 表示当前 pane 运行在 alternate screen（例如 Codex TUI）。这种应用的
内容不会进入 tmux scrollback，调大 `history-limit` 也看不到；先看
[Codex TUI 回滚配置](../../codex/config-codex-tui-scrollback/SKILL.md)。

## 在 .tmux.conf.local 末尾追加

把 [references/tmux.conf.local.example](references/tmux.conf.local.example)
整段追加到 `~/.tmux.conf.local` 末尾即可（后出现的赋值覆盖官方示例里的默认
值）。核心内容：

```tmux
# 1. oh-my-tmux 变量
# 复制时写入系统剪贴板（macOS 自动用 pbcopy）
tmux_conf_copy_to_os_clipboard=true
# 新窗口/新 pane 沿用当前目录；prefix + c 的命名提示依赖它
tmux_conf_new_window_retain_current_path=true

# 2. 基础选项
set -g history-limit 100000
set -g mode-keys vi
set -g status-keys vi
set -g set-clipboard on

# 3. 复制：Enter / 拖选松开也写入系统剪贴板
bind -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "pbcopy"
bind -T copy-mode-vi MouseDragEnd1Pane \
	send-keys -X copy-pipe-and-cancel "pbcopy"

# 4. 新窗口：沿用当前目录并提示命名
bind c new-window \; \
	command-prompt -p "窗口名称:" -I "#{b:pane_current_path}" \
	"rename-window -- '%%'"

# 5. Codex 等 TUI 底部 5 行不响应拖拽/双击，见下一节
```

几个容易踩的点：

- **`tmux_conf_new_window_retain_current_path=true` 不能省。** oh-my-tmux
  加载时会规范化 new-window 绑定，把自定义的
  `-c "#{pane_current_path}"` 去掉；打开这个变量后它会把 `-c` 统一加回去
  （split-window 同理），`bind c` 才会落在当前目录。
- **`mode-keys vi` 不能省。** oh-my-tmux 的复制键位写在 `copy-mode-vi`
  表里，emacs 模式下完全不生效。也可以改成导出 `VISUAL` 或 `EDITOR=vim`。
- `tmux_conf_copy_to_os_clipboard=true` 会在加载时把 copy-selection 类绑定
  自动改写成 `copy-pipe ... pbcopy`；自定义绑定里显式写了 `pbcopy` 也不会
  重复添加。
- tmux 3.8 默认 `mouse on`；如果 `tmux show-options -gv mouse` 是 `off`
  （旧版本），加 `set -g mouse on`，或运行时 `<prefix> m` 切换。
- `default-terminal` 不用手写：oh-my-tmux 在 macOS 上会探测 terminfo，
  自动把 `screen-256color` 升级成 `tmux-256color`。

## 键位速查

`<prefix>` 默认是 `C-b`，oh-my-tmux 同时把 `C-a` 设为第二前缀。

- `<prefix> e` / `<prefix> r`：编辑 local 配置 / 重载配置
- `<prefix> c`：在当前目录新建窗口并提示名称
- `<prefix> -` / `<prefix> _`：竖直 / 水平分屏
- `<prefix> h/j/k/l`：切换 pane；`H/J/K/L`（可连按）调整大小
- `<prefix> +`：把 pane 最大化到新窗口（还能继续分屏，与 `resize-pane -Z` 不同）
- `<prefix> m`：开关鼠标模式
- `<prefix> C-h` / `C-l`：左右切窗口；`Tab` 上一个窗口；`BTab` 上一个会话
- `<prefix> C-c` / `C-f`：新建会话 / 按名称查找会话
- `<prefix> Enter`：进入 copy-mode；`q` 退出
- `<prefix> p` / `P` / `b`：粘贴 / 选择缓冲区 / 列出缓冲区
- `<prefix> y`：把当前 tmux 粘贴缓冲区写入系统剪贴板（根表绑定）
- `<prefix> ?`：列出全部键位

copy-mode（vi 键位）里：`v` 开始选择、`C-v` 块选择、`H/L` 行首/行尾、`y`
复制并退出；本配置还加了 `Enter` 和鼠标拖选松开即复制。

## 在 Codex 等 TUI 里误触选中

Codex 用 inline mode 时不接管鼠标，`tmux display-message -p '#{mouse_any_flag}'`
会返回 `0`。它画在屏幕上的输入框、状态栏，在 tmux 眼里就是普通文本。再
叠加 tmux 3.5+ 的默认行为：

- `MouseDrag1Pane`：不在 copy-mode 时，左键稍微一动就 `copy-mode -M` 并
  开始选区；
- `DoubleClick1Pane` / `TripleClick1Pane`：双击选词、三击选行，而且**立即**
  复制，不用先进 copy-mode。

所以点输入框时手抖一下、或者双击想定位光标，都会生成选区并把系统剪贴板
覆盖掉。根因在 tmux 这一侧，不是 Codex：`mouse_any_flag=0` 就说明鼠标事件
没有交给应用。

最直接的办法是让 codex pane 整个不响应拖拽，但这样正文也选不了，基本没
法用。更稳的做法是只屏蔽底部几行（输入框和状态栏），上面的正文照常选中：

```tmux
bind -n MouseDrag1Pane if -F '#{||:#{pane_in_mode},#{mouse_any_flag}}' \
	{ send-keys -M } \
	{ if -F '#{&&:#{==:#{pane_current_command},codex},#{>=:#{mouse_y},#{e|+|:#{pane_height},-5}}}' \
		{ select-pane -t = } \
		{ copy-mode -M } }

bind -n DoubleClick1Pane select-pane -t = \; \
	if -F '#{||:#{pane_in_mode},#{mouse_any_flag}}' { send-keys -M } \
	{ if -F '#{&&:#{==:#{pane_current_command},codex},#{>=:#{mouse_y},#{e|+|:#{pane_height},-5}}}' \
		{ select-pane -t = } \
		{ copy-mode -H ; send-keys -X select-word ; run-shell -d 0.3 ; send-keys -X copy-pipe-and-cancel } }

bind -n TripleClick1Pane select-pane -t = \; \
	if -F '#{||:#{pane_in_mode},#{mouse_any_flag}}' { send-keys -M } \
	{ if -F '#{&&:#{==:#{pane_current_command},codex},#{>=:#{mouse_y},#{e|+|:#{pane_height},-5}}}' \
		{ select-pane -t = } \
		{ copy-mode -H ; send-keys -X select-line ; run-shell -d 0.3 ; send-keys -X copy-pipe-and-cancel } }
```

这些是根表（`-n`）绑定，放在 `.tmux.conf.local` 末尾即可，已确认不会被
oh-my-tmux 的加载后处理覆盖。

`mouse_y` 是鼠标在 pane 内的行号，`pane_height - 5` 是底部 5 行的起点。
Codex 的输入框和状态栏一般就落在这几行，具体数字可以按实际布局调；输入
框经常写成多行时把它调大一点。判断的是拖拽起点，所以从正文开始拖到底部
仍然能选中底部内容，只有把起点直接放在输入框上才会被忽略。

条件里的 `pane_current_command` 用于限定只对 codex 生效。如果 Codex 是
通过包装脚本启动的，`cmd` 可能显示成 `node`、`python` 之类，把 `codex`
换成实际命令名即可；也可以去掉这个条件，让所有 pane 的底部几行都屏蔽。

改完之后：codex pane 的正文区域照常拖选、双击选词、三击选行并复制，只有
底部输入框那一小块不再响应鼠标。如果确实要从输入框那一行开始选，先滚轮
上翻一格（或 `prefix + [`）进入 copy-mode，之后拖选完全正常。

## 多行复制排查

多行复制本身是支持的；失败通常不是 tmux 的 `copy-pipe` 问题。

先确认绑定真的写到了系统剪贴板：

```bash
tmux list-keys -T copy-mode-vi y
tmux list-keys -T copy-mode-vi Enter
```

输出里应带 `copy-pipe-and-cancel pbcopy`；没有的话检查 local 里的
`tmux_conf_copy_to_os_clipboard=true` 是否生效，以及是否重载过配置。

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
tmux -V
ls -l ~/.tmux.conf
git -C ~/.tmux log -1 --format='%h %cs %s'

tmux show-options -gv mouse
tmux show-options -gv mode-keys
tmux show-options -gv history-limit
tmux show-options -gv prefix2

tmux list-keys -T prefix c
tmux list-keys -T copy-mode-vi Enter
tmux list-keys -T copy-mode-vi y
tmux list-keys -T copy-mode-vi MouseDragEnd1Pane
tmux list-keys -T root MouseDrag1Pane

# 手动测试：选中两行以上，松开在 pane 内，然后运行
pbpaste
```

也可运行 [scripts/verify-tmux.sh](scripts/verify-tmux.sh)，它会打印
oh-my-tmux 安装状态、相关选项、绑定和 pane 的 `alt/history` 状态。

## 约束与坑

- `.tmux.conf` 是仓库文件，升级会被覆盖；只改 `.tmux.conf.local`。升级：
  `git -C ~/.tmux pull`，然后 `<prefix> r`。
- `#!important` 只对**单行**的 `set` / `bind` / `unbind` 生效（后处理只匹
  配以这些词开头、以 `#!important` 结尾的行）。多行绑定写不了
  `#!important`；需要时合并成一行。
- `history-limit`、`default-terminal` 等设置只对新建 pane 生效；已存在的
  pane 不会因为重载而扩容，需新建窗口/pane 或重启 server。
- `mode-keys vi` 必须设置，否则 oh-my-tmux 的 `copy-mode-vi` 键位是死代码。
- `tmux_conf_copy_to_os_clipboard` 等变量在配置加载时求值；改完必须
  `<prefix> r`（或 `tmux source-file ~/.tmux.conf`）。
- oh-my-tmux 用大量 `run-shell`，Cygwin 下很慢，官方推荐 WSL + Windows
  Terminal；macOS/Linux 无此问题。
- 默认主题的分隔符是 ASCII `|`，不需要 Powerline 字体；想要 Powerline
  外观再改 `tmux_conf_theme_*_separator_*` 变量。
