# agent-skills

我维护的 Codex skills 集合，按工具和场景分层放置。

## 目录结构

```text
AGENTS.md                 # 全局偏好，软链到 ~/.codex/AGENTS.md
setup/
├── codex/
│   ├── config-yolo-mode/
│   └── config-codex-tui-scrollback/
└── tmux/
    └── config-tmux-interaction/
```

`setup/<tool>/<skill-name>/SKILL.md` 是一个完整 skill。Codex 会递归扫描
`~/.codex/skills` 下的 `SKILL.md`（已在 codex-cli 0.169.0 验证），所以不需要
把层级拍平。

## 全局偏好（AGENTS.md）

仓库根目录的 `AGENTS.md` 是全局偏好的唯一副本，`~/.codex/AGENTS.md` 是指向它
的软链。改偏好直接改仓库里的文件，Git 会记录每次变更：

```bash
# 首次建立软链
cp ~/.codex/AGENTS.md ~/.codex/AGENTS.md.bak
rm ~/.codex/AGENTS.md
ln -s "$HOME/Documents/Code/agent-skills/AGENTS.md" ~/.codex/AGENTS.md
```

注意：仓库内运行 Codex 时，这份文件也会作为项目级指令被读一次。内容相同，
不会冲突，只是重复。

## Skills

| Skill | 路径 | 用途 |
| --- | --- | --- |
| `config-yolo-mode` | [setup/codex/config-yolo-mode](setup/codex/config-yolo-mode/SKILL.md) | 把 Codex 默认权限设为全权限（YOLO mode），或恢复/缩小权限并校验实际生效值。 |
| `config-codex-tui-scrollback` | [setup/codex/config-codex-tui-scrollback](setup/codex/config-codex-tui-scrollback/SKILL.md) | 解决 Codex TUI 在 tmux 中无法回看长会话的问题：`Ctrl+T` transcript pager 或 `alternate_screen = "never"`。 |
| `config-tmux-interaction` | [setup/tmux/config-tmux-interaction](setup/tmux/config-tmux-interaction/SKILL.md) | 配置 tmux 新窗口命名、鼠标/触摸板滚动、选中内容 + Enter 复制到系统剪贴板，并排查多行复制问题。 |

## 安装到另一台电脑

推荐把仓库 clone 到普通代码目录，再把**仓库根目录**软链到 Codex 的
skills 目录：

```bash
# 1. clone
git clone https://github.com/liyc-ai/agent-skills.git \
  "$HOME/Documents/Code/agent-skills"

# 也可以用 SSH
# git clone git@github.com:liyc-ai/agent-skills.git \
#   "$HOME/Documents/Code/agent-skills"

# 2. 软链整个仓库
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"
ln -s "$HOME/Documents/Code/agent-skills" \
  "${CODEX_HOME:-$HOME/.codex}/skills/agent-skills"

# 3. 软链全局偏好
ln -s "$HOME/Documents/Code/agent-skills/AGENTS.md" \
  "${CODEX_HOME:-$HOME/.codex}/AGENTS.md"
```

如果目标位置已经存在，先备份再建立软链：

```bash
mv "${CODEX_HOME:-$HOME/.codex}/skills/agent-skills" \
   "${CODEX_HOME:-$HOME/.codex}/skills/agent-skills.bak"

mv "${CODEX_HOME:-$HOME/.codex}/AGENTS.md" \
   "${CODEX_HOME:-$HOME/.codex}/AGENTS.md.bak"
```

也可以直接 clone 进 skills 目录，效果相同：

```bash
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"
git clone https://github.com/liyc-ai/agent-skills.git \
  "${CODEX_HOME:-$HOME/.codex}/skills/agent-skills"
```

Windows 可以使用目录 junction：

```powershell
New-Item -ItemType Junction `
  -Path "$env:USERPROFILE\.codex\skills\agent-skills" `
  -Target "$env:USERPROFILE\Documents\Code\agent-skills"
```

## 验证安装

```bash
ls -l "${CODEX_HOME:-$HOME/.codex}/skills/agent-skills"

codex debug prompt-input 'hi' \
  | grep -oE 'file: r0/agent-skills/[^)]*SKILL.md' \
  | sed 's/^file: //' \
  | sort -u
```

预期能看到三个 skill 的 `SKILL.md` 路径，例如：

```text
r0/agent-skills/setup/codex/config-codex-tui-scrollback/SKILL.md
r0/agent-skills/setup/codex/config-yolo-mode/SKILL.md
r0/agent-skills/setup/tmux/config-tmux-interaction/SKILL.md
```

`codex debug prompt-input` 只渲染 prompt，不调用模型。skill 在会话启动时加载；
安装或更新后请新开 Codex 会话。

## 更新

```bash
git -C "$HOME/Documents/Code/agent-skills" pull --ff-only
```

然后新开 Codex 会话即可。软链指向仓库工作区，不需要重新复制文件。

如果采用直接 clone 到 skills 目录的方式，把上面的路径换成
`${CODEX_HOME:-$HOME/.codex}/skills/agent-skills`。

## 新增 skill 约定

1. 按 `setup/<tool>/<skill-name>/` 建目录。
2. `SKILL.md` 的 frontmatter `name` 与目录名保持一致，并确保全局唯一。
3. 只在确实需要时添加 `scripts/`、`references/`、`assets/`。
4. 用 skill-creator 的校验脚本检查：

```bash
python3 "${CODEX_HOME:-$HOME/.codex}/skills/.system/skill-creator/scripts/quick_validate.py" \
  "setup/<tool>/<skill-name>"
```

## 注意

- 不要把个人 skill 放进 `~/.codex/skills/.system/`；`.system` 是系统 skill 的位置。
- Codex 使用 `SKILL.md` 的 `name` 作为 skill 标识；同级路径不会改变名称。
- 删除软链不会删除仓库：

  ```bash
  unlink "${CODEX_HOME:-$HOME/.codex}/skills/agent-skills"
  ```

## License

[Apache-2.0](LICENSE)
