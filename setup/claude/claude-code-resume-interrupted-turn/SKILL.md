---
name: claude-code-resume-interrupted-turn
description: >-
  回答 Claude Code 被打断后如何继续生成：用隐藏参数 --reply-on-resume 在
  resume 时自动续跑被 Esc 打断的 turn，不用再输入"继续"。Use when asked how to
  resume or continue an interrupted Claude Code response without typing
  "继续" / continue, how to pause an agent and resume it later without
  polluting context, 停止后如何接着生成, 中断续跑, Esc 之后 resume,
  --reply-on-resume, or CLAUDE_CODE_RESUME_INTERRUPTED_TURN.
metadata:
  short-description: Claude Code 中断的 turn 自动续跑
---

# Claude Code 中断后自动续跑

被 Esc 打断的会话，resume 时加一个隐藏参数就能自己接着跑，不用再发"继续"：

```bash
claude --resume <session-id> --reply-on-resume

# 最近一个会话
claude -c --reply-on-resume
```

## 行为

- 触发条件是会话末尾有 `[Request interrupted by user]` 这类 user-role 的打断标记。
- 打断前已有部分输出：把那段用 `<interrupted-output>` 包成一条 `isMeta` 提示注入，让模型从断点接着写、不要重复。
- 打断时还没输出：把被打断的 turn 重跑一遍。
- 注入的是 harness 生成的消息，不是用户输入，不会以你的口吻留在对话里。

## 坑

- 隐藏参数，`--help` 里没有，官方文档也没写；当前 2.1.332 可用，随版本可能变。
- 它原本为 `/background` 中途 fork、后台 worker 重启设计，`-p`（print）模式下用会报 `No deferred tool marker found`，要交互式 resume 才正常。
- 会话末尾不是 user-role 的打断标记（例如进程被直接 kill）时可能不触发，这时还是得给一句话。
- 相关环境变量 `CLAUDE_CODE_RESUME_INTERRUPTED_TURN=1` 看着是同一套机制，旁边还有 `..._MAX_AGE_MS`；交互式下没有单独验证。

## 不是这个场景

- 想撤销跑偏的分支：用 `Esc Esc` 或 `/rewind`，它回退到检查点，不是续跑。
- 网络抖动：可重试的 API 错误会自动退避重试；长任务可以用 `claude --bg` 扔后台，回头 `claude attach`。
- 多一条 user message 的影响其实很小；Claude Code 自己在睡眠、额度重置、worker 重启时也会注入 `Please continue from where you left off.`。

完整调查记录和实测过程见仓库里的 `knowledge/claude/claude-code-resume-interrupted-turn.md`。
