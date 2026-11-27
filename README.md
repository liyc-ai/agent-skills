# agent-skills

我维护的个人 skills 集合，Codex CLI 和 Claude Code 共用。每个 skill 都是一个
独立的 `SKILL.md` 目录，按工具和场景分层放置。

## 目录结构

```text
AGENTS.GLOBAL.md                # 全局指令，Codex/Claude 共用一份
AGENTS.md                       # 仓库级指令，修改本仓库时的提交与 README 同步约定
setup/
├── claude/
│   ├── config-auto-mode/
│   └── claude-code-resume-interrupted-turn/
├── codex/
│   ├── config-yolo-mode/
│   └── config-codex-tui-scrollback/
└── tmux/
    └── config-tmux-interaction/   # 场景目录，两个客户端通用
knowledge/
└── claude/
    └── claude-code-resume-interrupted-turn.md   # 长文调查记录，供 skill 引用
```

`setup/<tool>/<skill-name>/SKILL.md` 放工具专用的 skill；
`setup/<scenario>/<skill-name>/SKILL.md` 放跨工具的场景化 skill。两者都用通用
的 `SKILL.md` 格式，所以同一份文件可以被 Codex 和 Claude Code 加载。

## 全局指令

`AGENTS.GLOBAL.md` 是全局指令的唯一副本，目前包括任务执行规范（验收标准、
任务拆分、卡住时停下来提问）、中文表达、学术写作和 Git/GitHub 环境约定。
Codex 通过 `~/.codex/AGENTS.md` 读取，Claude Code 通过 `~/.claude/CLAUDE.md`
读取；两条软链都指向这个文件，改一处两边都生效。

文件放在仓库根目录，但特意用了 `AGENTS.GLOBAL.md` 这个名字：Codex 只认
`AGENTS.md`，Claude Code 认 `AGENTS.md` / `CLAUDE.md`，所以它不会被当成
项目级指令自动加载；只有软链过去的两个名字会被读取。

Claude Code 2.1.277+ 也支持项目里的 `AGENTS.md`，但用户级全局指令仍然是
`~/.claude/CLAUDE.md`；`~/.codex/AGENTS.md` 不会被 Claude Code 读取。

## 仓库级指令

根目录的 `AGENTS.md` 是项目级指令，和上面的全局指令不同，它会被 Codex 和
Claude Code 自动加载，只在本仓库生效。目前约定两件事：

- 不要新建分支，直接在 `main` 上 commit。
- 改完内容后同步更新 `README.md`（目录树、Skills 表格、安装命令、验证数量等）。

具体条目见 [AGENTS.md](AGENTS.md)。

## Skills

| Skill | 路径 | 适用 | 用途 |
| --- | --- | --- | --- |
| `config-yolo-mode` | [setup/codex/config-yolo-mode](setup/codex/config-yolo-mode/SKILL.md) | Codex | 把 Codex 默认权限设为全权限（YOLO mode），或恢复/缩小权限并校验实际生效值。 |
| `config-codex-tui-scrollback` | [setup/codex/config-codex-tui-scrollback](setup/codex/config-codex-tui-scrollback/SKILL.md) | Codex | 解决 Codex TUI 在 tmux 中无法回看长会话的问题：`Ctrl+T` transcript pager 或 `alternate_screen = "never"`。 |
| `config-auto-mode` | [setup/claude/config-auto-mode](setup/claude/config-auto-mode/SKILL.md) | Claude Code | 把 Claude Code 默认权限模式改为 auto mode（分类器逐个判断），或恢复/校验默认模式。 |
| `claude-code-resume-interrupted-turn` | [setup/claude/claude-code-resume-interrupted-turn](setup/claude/claude-code-resume-interrupted-turn/SKILL.md) | Claude Code | 用隐藏参数 `--reply-on-resume` 在 resume 时自动续跑被 Esc 打断的 turn，不用再输入"继续"。 |
| `config-tmux-interaction` | [setup/tmux/config-tmux-interaction](setup/tmux/config-tmux-interaction/SKILL.md) | Codex / Claude Code | 安装/升级 oh-my-tmux，并在 `.tmux.conf.local` 中补齐新窗口命名、鼠标滚动、剪贴板复制与 TUI 误触防护。 |

格式对两个工具都通用；前两个 Codex skill、`config-auto-mode` 和
`claude-code-resume-interrupted-turn` 的内容本身是各自工具专用的。

## Knowledge

`knowledge/<tool>/<topic>.md` 放长文的调查记录、实测过程和边界情况，既给人读，
也供对应的 skill 引用。它不会被 Codex 或 Claude Code 自动加载，所以想让某个
问题被自动答上，仍然要在 `setup/` 下有一个 skill 作为入口；skill 里放短答案
和触发词，长文留在 `knowledge/`，避免把大段背景塞进每次会话的上下文。

## 安装

先 clone 仓库，后面的命令都用这个路径：

```bash
REPO="$HOME/Documents/Code/agent-skills"
git clone https://github.com/liyc-ai/agent-skills.git "$REPO"

# 也可以用 SSH
# git clone git@github.com:liyc-ai/agent-skills.git "$REPO"
```

后面的命令都假设 `REPO` 还在当前 shell 里。

如果目标位置已经有同名文件或软链，先备份再建链接：

```bash
# 只对已存在的项执行
mv ~/.codex/AGENTS.md ~/.codex/AGENTS.md.bak
mv ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.bak
mv ~/.codex/skills/agent-skills ~/.codex/skills/agent-skills.bak
mv ~/.claude/skills/config-yolo-mode ~/.claude/skills/config-yolo-mode.bak
mv ~/.claude/skills/config-codex-tui-scrollback ~/.claude/skills/config-codex-tui-scrollback.bak
mv ~/.claude/skills/config-auto-mode ~/.claude/skills/config-auto-mode.bak
mv ~/.claude/skills/claude-code-resume-interrupted-turn ~/.claude/skills/claude-code-resume-interrupted-turn.bak
mv ~/.claude/skills/config-tmux-interaction ~/.claude/skills/config-tmux-interaction.bak
```

### Codex CLI

Codex 会递归扫描 `~/.codex/skills` 下的 `SKILL.md`（已在 codex-cli 0.169.0
验证），所以链接一次仓库根目录就够了：

```bash
CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
mkdir -p "$CODEX_DIR/skills"
ln -s "$REPO" "$CODEX_DIR/skills/agent-skills"
ln -s "$REPO/AGENTS.GLOBAL.md" "$CODEX_DIR/AGENTS.md"
```

如果想让 Codex 侧也保持和 Claude 一样的扁平结构，可以改成逐个软链：

```bash
for f in "$REPO"/setup/*/*/SKILL.md; do
  src=$(dirname "$f")
  ln -sfn "$src" "$CODEX_DIR/skills/$(basename "$src")"
done
```

### Claude Code

Claude Code 只扫描 `~/.claude/skills/<skill-name>/SKILL.md` 这一层，**不会
递归**。把整个仓库软链成 `~/.claude/skills/agent-skills` 时，顶层没有
`SKILL.md`，里面的 skill 不会被发现；所以要逐个软链，不过软链的 skill 目录
本身会被正常跟随（Claude Code 2.1.332 验证）：

```bash
CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR/skills"
for f in "$REPO"/setup/*/*/SKILL.md; do
  src=$(dirname "$f")
  ln -sfn "$src" "$CLAUDE_DIR/skills/$(basename "$src")"
done
ln -s "$REPO/AGENTS.GLOBAL.md" "$CLAUDE_DIR/CLAUDE.md"
```

以后新增 skill 时，重跑上面的循环（或只补一条 `ln -sfn`）即可。

如果以后想把 agents、hooks、MCP 也一起打包，可以在仓库根加
`.claude-plugin/plugin.json`，改用 Claude Code 的插件方式安装；现在只装
skills 的话，逐个软链就够了。

### Windows

Windows 用目录 junction。Codex 侧可以 junction 整个仓库：

```powershell
New-Item -ItemType Junction `
  -Path "$env:USERPROFILE\.codex\skills\agent-skills" `
  -Target "$env:USERPROFILE\Documents\Code\agent-skills"
```

Claude 侧不能 junction 整个仓库，需要给每个 skill 单独建 junction，例如：

```powershell
New-Item -ItemType Junction `
  -Path "$env:USERPROFILE\.claude\skills\config-tmux-interaction" `
  -Target "$env:USERPROFILE\Documents\Code\agent-skills\setup\tmux\config-tmux-interaction"
```

## 验证安装

### Codex

```bash
codex debug prompt-input 'hi' \
  | grep -oE 'file: [^)]*(config-yolo-mode|config-codex-tui-scrollback|config-auto-mode|claude-code-resume-interrupted-turn|config-tmux-interaction)/SKILL.md' \
  | sed 's/^file: //' \
  | sort -u
```

预期能看到五个 `SKILL.md` 路径。

### Claude Code

新开一个 Claude Code 会话，然后：

```text
/skills      # 应看到五个 skill，名字与目录名一致
/memory      # 应看到 ~/.claude/CLAUDE.md
```

`/reload-skills` 可以强制重新扫描 `~/.claude/skills`，安装或改动 skill 后
不用重启会话。

## 更新

```bash
git -C "$REPO" pull --ff-only
```

软链指向仓库工作区，不需要重新复制文件。skill 文本会被 Claude Code 监听，
也可以用 `/reload-skills` 强制重扫；`AGENTS.md` / `CLAUDE.md` 的改动新开一个
会话最稳。

## 新增 skill 约定

1. 工具专用 skill 放 `setup/<tool>/<skill-name>/`，跨工具 skill 放
   `setup/<scenario>/<skill-name>/`。
2. `SKILL.md` 的 frontmatter `name` 与目录名保持一致，并确保全局唯一；
   `description` 写清楚触发场景。
3. 只在确实需要时添加 `scripts/`、`references/`、`assets/`。
4. 用 skill-creator 的校验脚本检查（如果本机装了）：

```bash
python3 "${CODEX_HOME:-$HOME/.codex}/skills/.system/skill-creator/scripts/quick_validate.py" \
  "setup/<tool>/<skill-name>"
```

Claude Code 侧没有独立的裸 skill 校验命令，装好后用 `/skills` 看是否被发现
即可。

## 注意

- 不要把个人 skill 放进 `~/.codex/skills/.system/`；`.system` 是 Codex 系统
  skill 的位置。
- Claude Code 的个人 skill 只扫描一层目录，仓库根软链不会生效；`~/.claude`
  下要放的是每个 skill 目录本身。
- `~/.codex/AGENTS.md` 只给 Codex 用；Claude Code 的用户级文件是
  `~/.claude/CLAUDE.md`，两者都指向 `AGENTS.GLOBAL.md`。
- Cowork 桌面会话会跳过本身是软链的 `~/.claude/CLAUDE.md`；普通终端会话不受
  影响。
- 删除软链不会删除仓库：

  ```bash
  unlink "${CODEX_HOME:-$HOME/.codex}/skills/agent-skills"
  unlink ~/.claude/skills/config-tmux-interaction
  ```

## License

[Apache-2.0](LICENSE)
