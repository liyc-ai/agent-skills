# 仓库级 Agent 指令

这是 agent-skills 仓库的项目级指令。Codex 读 `AGENTS.md`，Claude Code 2.1.277+
也读 `AGENTS.md`，所以两个工具改这个仓库时都会自动加载。它和
`AGENTS.GLOBAL.md` 里的全局约定叠加使用，本文件只补充修改这个仓库时的规则。

## 提交

- 不要新建分支，直接在 `main` 上 commit。这个仓库是个人 skills 集合，没有 PR
  流程，也不需要靠分支隔离改动。
- commit message 写清楚改了什么，比如 `Add config-xxx skill`、`Update README
  for the new global instructions section`。
- 只提交和本次改动相关的文件，不要顺手把无关的本地修改或临时文件带进去。

## README 同步

改完内容后，对照 `README.md` 检查一遍要同步的地方：

- 新增、删除、重命名 skill：更新目录结构树、Skills 表格，以及安装部分的软链、
  备份、卸载命令和验证部分里的 skill 数量和名字。
- 改了安装或验证步骤：更新对应小节。
- 新增顶层文件或目录：更新目录结构树，必要时补一段说明。
- 改了某个 skill 的用途或适用工具：更新 Skills 表格里对应的那一行。
- 只改 skill 内部实现、行为和用法都没变时，README 一般不用动；拿不准就打开对应
  小节看一眼。

README 是别人照着装、照着用的，缺一条命令或者数量对不上，比 skill 本身写错更
容易让人卡住。

## 同步 Codex / Claude 的 skill 列表

这个仓库是 skill 的唯一来源。新增、修改、重命名或删除 skill 后，先 pull 到最新，
再按下面的方式同步客户端，避免出现“仓库里有、客户端看不到”或“仓库里删了、旧软链
还在”的情况。

```bash
REPO="$HOME/Documents/Code/agent-skills"
CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
CLAUDE_DIR="$HOME/.claude"
git -C "$REPO" pull --ff-only
```

### Codex

Codex 会递归扫描 `~/.codex/skills`，推荐只保留一个指向仓库根目录的软链：

```bash
mkdir -p "$CODEX_DIR/skills"
ln -sfn "$REPO" "$CODEX_DIR/skills/agent-skills"
```

新增、更新、删除 skill 都不用逐个改链，`pull` 后新启动的 Codex 会直接看到最新
内容。验证：

```bash
codex debug prompt-input 'hi' 2>/dev/null \
  | grep -oE 'agent-skills/(code|setup)/[^)]*/SKILL.md' \
  | sort -u
```

如果之前建过 `~/.codex/skills/<skill-name>` 形式的逐个软链，先把指向本仓库的旧链
删掉，只保留整仓库软链，否则已删除的 skill 可能仍会被旧链发现。

### Claude Code

Claude Code 只扫描 `~/.claude/skills/<skill-name>/SKILL.md` 这一层，需要逐个
软链。新增和更新用同一段命令，重复执行是安全的：

```bash
mkdir -p "$CLAUDE_DIR/skills"
for f in "$REPO"/setup/*/*/SKILL.md "$REPO"/code/*/SKILL.md; do
  [ -f "$f" ] || continue
  src=$(dirname "$f")
  ln -sfn "$src" "$CLAUDE_DIR/skills/$(basename "$src")"
done
```

删除 skill 后，只清理“指向本仓库但已经失效”的软链。不要整目录删除，也不要碰
`nature-*` 等其它来源的 skill：

```bash
for link in "$CLAUDE_DIR"/skills/*; do
  [ -L "$link" ] || continue
  target=$(readlink "$link")
  case "$target" in
    "$REPO"/*) [ -f "$link/SKILL.md" ] || unlink "$link" ;;
  esac
done
```

验证当前有哪些来自本仓库的 skill：

```bash
for link in "$CLAUDE_DIR"/skills/*; do
  [ -L "$link" ] || continue
  target=$(readlink "$link")
  case "$target" in
    "$REPO"/*) printf '%s -> %s\n' "$(basename "$link")" "$target" ;;
  esac
done
```

结果应该只包含仓库当前的 skill，数量和 `find "$REPO" -name SKILL.md` 对得上。
Claude Code 里可以执行 `/reload-skills`，或新开一个会话，让列表重新扫描。

同步完成后，记得按上面的“README 同步”检查目录树、Skills 表格、安装命令和验证
数量；如果新增或删除了 skill，这些地方通常都要一起改。
