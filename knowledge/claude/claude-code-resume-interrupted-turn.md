# Claude Code 被打断后怎么继续生成

适用版本：Claude Code 2.1.332（macOS，2026-11 验证）。

## 结论

Claude Code 有一个隐藏参数 `--reply-on-resume`。resume 时带上它，如果会话末尾是一个被 Esc 打断的 turn，它会自己再发一次请求接着跑，不需要你输入"继续"。

```bash
claude --resume <session-id> --reply-on-resume

# 最近一个会话
claude -c --reply-on-resume
```

session id 可以从 `claude --resume` 的列表里拿，或者在会话里用 `/resume` 看。

## 它具体做了什么

按 Esc 中断时，Claude Code 会在 transcript 末尾写一条 `[Request interrupted by user]`；如果打断的是工具调用，则是 `[Request interrupted by user for tool use]`。

resume 带上 `--reply-on-resume` 后，它读到最后停在这个 marker，就自动发起下一轮查询：

- 如果打断前已经有部分文字输出，它会把那段输出用 `<interrupted-output>...</interrupted-output>` 包起来，作为一条 `isMeta: true` 的提示注入，告诉模型"这是你自己被截断的输出，从断点接着写，不要重复"。
- 如果打断时还没产出文字（还停在 thinking），它会把被打断的 turn 重新跑一遍。

两种情况下都不用你打字；注入的提示是 harness 生成的，不以用户口吻出现。

## 实测过程

拿一个临时会话做的验证：

1. 用 `-p` 跑一个长回答，中途 SIGINT，transcript 末尾出现 `[Request interrupted by user]`。
2. 交互式执行 `claude --resume <id> --reply-on-resume`（用 pty 驱动），没有输入任何 prompt，界面直接开始继续生成。
3. 对照：`-p` 模式下加同样的参数会报 `No deferred tool marker found in the resumed session...`，因为 print 模式对空白输入有一条额外的校验，要求存在挂起的 deferred tool。交互式 resume 没有这个限制。

## 相关环境变量

`CLAUDE_CODE_RESUME_INTERRUPTED_TURN=1` 看起来是同一套机制，旁边还有 `CLAUDE_CODE_RESUME_INTERRUPTED_TURN_MAX_AGE_MS` 控制"多久以内的中断才自动续跑"（设置了环境变量但没给值时默认按 1 小时处理）。这两个没有在交互式会话里单独验证，用时先小范围试。

## 和 /rewind 的区别

- `Esc Esc` 或 `/rewind`：回到某个检查点，把代码和/或对话退回去，然后重新来。适合"这条分支跑偏了"。
- `--reply-on-resume`：不后退，接着被打断的地方往下跑。适合"跑到一半被打断了，想继续"。

## 什么时候还是得自己说一句

- `--reply-on-resume` 是隐藏参数，`--help` 里没有，官方文档也没写，随版本可能变。当前 2.1.332 可用。
- 它原本是为 `/background` 中途 fork、后台 worker 重启这类场景做的，所以 `-p`（print）模式下不适用。
- 如果会话末尾不是 user-role 的打断 marker（例如进程被直接 kill、没来得及写 marker），它可能不触发，这时还是得给一句话。
- 多一条 user message 的"污染"其实很小。Claude Code 自己在电脑睡眠、用量额度重置、worker 重启时，也是注入类似 `Please continue from where you left off.` 的消息，只是标成自动续跑，不以用户口吻出现。

## 顺带

- 网络抖动不用每次手动停：可重试的 API 错误会自动退避重试，流断了已生成的部分会保留。
- 长任务怕终端断，用 `claude --bg` 扔后台，回头 `claude attach`。
- 主模型忙时可以用 `--fallback-model` 自动换一个。
