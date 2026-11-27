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
