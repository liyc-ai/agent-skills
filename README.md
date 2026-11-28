# agent-skills

我维护的个人 skills 集合，Codex CLI 和 Claude Code 共用。每个 skill 都是一个
独立的 `SKILL.md` 目录，按用途分层放置。

## 目录结构

```text
AGENTS.GLOBAL.md                # 全局指令，Codex/Claude 共用一份
AGENTS.md                       # 仓库级指令，修改本仓库时的提交与 README 同步约定
code/
└── full-repo-review/           # 跨工具的工程流程 skill
setup/
├── claude/
│   └── config-auto-mode/
├── codex/
│   ├── config-yolo-mode/
│   └── config-codex-tui-scrollback/
└── tmux/
    └── config-tmux-interaction/   # 场景目录，两个客户端通用
```

`code/<skill-name>/SKILL.md` 放跨工具的工程流程 skill；
`setup/<tool>/<skill-name>/SKILL.md` 放工具专用的 skill；
`setup/<scenario>/<skill-name>/SKILL.md` 放跨工具的场景化配置 skill。它们都用
通用的 `SKILL.md` 格式，所以同一份文件可以被 Codex 和 Claude Code 加载。

## 全局指令

`AGENTS.GLOBAL.md` 是全局指令的唯一副本，目前包括任务执行规范（验收标准、
任务拆分、卡住时停下来提问）、中文表达、学术写作、Git/GitHub 环境约定，以及
skill 仓库位置和新增 skill 的放置约定。
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
| `config-tmux-interaction` | [setup/tmux/config-tmux-interaction](setup/tmux/config-tmux-interaction/SKILL.md) | Codex / Claude Code | 安装/升级 oh-my-tmux，补齐新窗口命名、鼠标滚动、剪贴板复制、状态栏当前目录与 TUI 误触防护；排查 Claude Code fullscreen 渲染器导致 tmux 翻不到历史（`/tui default`、`Ctrl+O` + `[`）。 |
| `full-repo-review` | [code/full-repo-review](code/full-repo-review/SKILL.md) | Codex / Claude Code | 全仓库审查：建立基线，按契约和分层清单找真实 bug，用测试复现后小批量修复，并核对文档、示例和依赖是否完备。 |

格式对两个工具都通用；`setup` 下的 skill 各自面向具体工具或配置场景，
`code/full-repo-review` 则是跨工具的代码审查流程。

## 安装

先把仓库 clone 到一个你自己选的位置，再把位置写进
`~/.config/agent-skills/repo`。之后的安装命令和 agent 都从这个文件读路径，
换机器或想把仓库挪到别处时，改这一行就行，不用动仓库里的任何文件：

```bash
REPO="$HOME/Documents/Code/agent-skills"   # 改成你想放的位置
git clone git@github.com:liyc-ai/agent-skills.git "$REPO"

mkdir -p ~/.config/agent-skills
printf '%s\n' "$REPO" > ~/.config/agent-skills/repo
```

已经 clone 过的机器不用再 clone，只补最后两行。如果临时要用别的副本，可以设
`AGENT_SKILLS_REPO`，它的优先级高于配置文件；平时不用设。

下面的代码块都从配置文件读一次 `REPO`，复制粘贴时彼此独立，不依赖上一个
shell 里还留着变量。

如果目标位置已经有同名文件或软链，先备份再建链接：

```bash
# 只对已存在的项执行
mv ~/.codex/AGENTS.md ~/.codex/AGENTS.md.bak
mv ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.bak
mv ~/.codex/skills/agent-skills ~/.codex/skills/agent-skills.bak
mv ~/.claude/skills/config-yolo-mode ~/.claude/skills/config-yolo-mode.bak
mv ~/.claude/skills/config-codex-tui-scrollback ~/.claude/skills/config-codex-tui-scrollback.bak
mv ~/.claude/skills/config-auto-mode ~/.claude/skills/config-auto-mode.bak
mv ~/.claude/skills/config-tmux-interaction ~/.claude/skills/config-tmux-interaction.bak
mv ~/.claude/skills/full-repo-review ~/.claude/skills/full-repo-review.bak
```

### Codex CLI

Codex 会递归扫描 `~/.codex/skills` 下的 `SKILL.md`（已在 codex-cli 0.169.0
验证），所以链接一次仓库根目录就够了：

```bash
REPO="$(cat ~/.config/agent-skills/repo)"
CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
mkdir -p "$CODEX_DIR/skills"
ln -s "$REPO" "$CODEX_DIR/skills/agent-skills"
ln -s "$REPO/AGENTS.GLOBAL.md" "$CODEX_DIR/AGENTS.md"
```

如果想让 Codex 侧也保持和 Claude 一样的扁平结构，可以改成逐个软链：

```bash
REPO="$(cat ~/.config/agent-skills/repo)"
CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
for f in "$REPO"/setup/*/*/SKILL.md "$REPO"/code/*/SKILL.md; do
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
REPO="$(cat ~/.config/agent-skills/repo)"
CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR/skills"
for f in "$REPO"/setup/*/*/SKILL.md "$REPO"/code/*/SKILL.md; do
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
$REPO = "$env:USERPROFILE\Documents\Code\agent-skills"   # 改成你想放的位置

New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.config\agent-skills" | Out-Null
Set-Content -Path "$env:USERPROFILE\.config\agent-skills\repo" -Value $REPO

New-Item -ItemType Junction `
  -Path "$env:USERPROFILE\.codex\skills\agent-skills" `
  -Target $REPO
```

Claude 侧不能 junction 整个仓库，需要给每个 skill 单独建 junction，例如：

```powershell
$REPO = Get-Content "$env:USERPROFILE\.config\agent-skills\repo"

New-Item -ItemType Junction `
  -Path "$env:USERPROFILE\.claude\skills\config-tmux-interaction" `
  -Target "$REPO\setup\tmux\config-tmux-interaction"

New-Item -ItemType Junction `
  -Path "$env:USERPROFILE\.claude\skills\full-repo-review" `
  -Target "$REPO\code\full-repo-review"
```

## 验证安装

先确认配置文件指向一个真实的仓库：

```bash
REPO="$(cat ~/.config/agent-skills/repo)"
test -d "$REPO/.git" && echo "ok: $REPO" || echo "路径不对，改 ~/.config/agent-skills/repo"
```

### Codex

```bash
codex debug prompt-input 'hi' \
  | grep -oE 'file: [^)]*(config-yolo-mode|config-codex-tui-scrollback|config-auto-mode|config-tmux-interaction|full-repo-review)/SKILL.md' \
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
REPO="$(cat ~/.config/agent-skills/repo)"
git -C "$REPO" pull --ff-only
```

软链指向仓库工作区，不需要重新复制文件。skill 文本会被 Claude Code 监听，
也可以用 `/reload-skills` 强制重扫；`AGENTS.md` / `CLAUDE.md` 的改动新开一个
会话最稳。

## 新增 skill 约定

1. 跨工具的工程流程 skill 放 `code/<skill-name>/`；工具专用 skill 放
   `setup/<tool>/<skill-name>/`，跨工具的场景化配置 skill 放
   `setup/<scenario>/<skill-name>/`。
2. `SKILL.md` 的 frontmatter `name` 与目录名保持一致，并确保全局唯一；
   `description` 写清楚触发场景。
3. 只在确实需要时添加 `scripts/`、`references/`、`assets/`。
4. 用 skill-creator 的校验脚本检查（如果本机装了）：

```bash
python3 "${CODEX_HOME:-$HOME/.codex}/skills/.system/skill-creator/scripts/quick_validate.py" \
  "code/<skill-name>"
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
- `~/.config/agent-skills/repo` 是仓库位置的唯一记录。没有这个文件时，agent
  会先问仓库放在哪，不会猜 `~/Documents/Code/agent-skills`。
- 删除软链不会删除仓库：

  ```bash
  unlink "${CODEX_HOME:-$HOME/.codex}/skills/agent-skills"
  unlink ~/.claude/skills/config-tmux-interaction
  ```

## License

[Apache-2.0](LICENSE)
