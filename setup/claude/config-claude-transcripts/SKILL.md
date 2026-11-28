---
name: config-claude-transcripts
description: >-
  查看、保留、导出和提取 Claude Code 的本地会话记录：jsonl 文件位置与
  目录编码规则、cleanupPeriodDays 保留天数、--resume/-c 续聊、/export
  导出，以及从 jsonl 里批量提取用户提问和回答做归档。Use when 想找回
  以前的对话、保存聊天记录、调整会话保留时间、导出 transcript，或者需要
  批量提取历史会话内容。
metadata:
  short-description: Claude Code 会话记录的位置、保留、导出与提取
---

# Claude Code 会话记录

目标：知道对话存在哪、能留多久，以及需要归档时怎么把有用的部分拿出来。
原始 jsonl 适合机器读不适合人看，真正值得长期留的是结论，不是流水账。

## 文件位置

每次会话对应一个 jsonl：

```text
~/.claude/projects/<编码后的工作目录>/<session-id>.jsonl
```

目录名是工作目录绝对路径的编码：所有 `/` 换成 `-`，开头的 `/` 也会变成
`-`。例如 `/Users/alice/code/demo` 对应 `-Users-alice-code-demo`。

每行是一个 JSON 事件，常见 `type` 有 `user`、`assistant`，还有
`queue-operation`、`api-request`、`file-history-snapshot` 等非对话事件。
用户消息的 `message.content` 可能是字符串，也可能是 block 数组；工具结果
会以 `user` 角色回传，块类型是 `tool_result`，提取时要跳过。部分系统注入
的消息带 `isMeta: true`。

## 保留与清理

保留天数由 `~/.claude/settings.json` 里的 `cleanupPeriodDays` 控制，默认
30 天。想留久一点就调大：

```json
{
  "cleanupPeriodDays": 365
}
```

改完新开一个会话生效。`~/.claude/projects` 是纯本地目录，需要长期归档时
用 rsync 或私有 git 仓库备份，不建议让 iCloud 同步整个 `~/.claude`，容易
和正在跑的会话抢文件。

## 续聊与导出

```bash
claude --resume     # 列出会话挑一个继续
claude -c           # 直接续上当前目录最近一次会话
```

会话里可以用 `/export` 导出一份纯文本，默认文件名带时间和第一句话。缺点
是工具调用细节基本不保留，适合给别人看，不适合归档。

## 从 jsonl 提取

下面这段脚本把用户提问和带正文的回复抽出来，按会话顺序输出。适合把一段
时间的历史整理成可读清单，再人工挑值得沉淀的结论：

```python
#!/usr/bin/env python3
import json, glob, os, sys

DROP = ("<system-reminder>", "<command-name>", "Caveat:")

def text_of(content):
    if isinstance(content, str):
        return content
    if not isinstance(content, list):
        return ""
    return "\n".join(b.get("text", "") for b in content
                     if isinstance(b, dict) and b.get("type") == "text")

base = os.path.expanduser(sys.argv[1] if len(sys.argv) > 1
                          else "~/.claude/projects")
for path in sorted(glob.glob(base + "/*/*.jsonl")):
    print(f"\n## {os.path.basename(path)}")
    for line in open(path, encoding="utf-8", errors="replace"):
        try:
            o = json.loads(line)
        except Exception:
            continue
        if o.get("type") not in ("user", "assistant"):
            continue
        if o.get("isMeta"):
            continue
        text = text_of((o.get("message") or {}).get("content")).strip()
        if not text or text.startswith(DROP):
            continue
        who = "用户" if o["type"] == "user" else "助手"
        print(f"[{who}] {text}\n")
```

用法：

```bash
python3 extract.py ~/.claude/projects/-Users-alice-code-demo
```

输出可能很大，重定向到文件再翻，或者只挑某几个 session 的文件。

## 归档策略

原始记录解决的是「找回某次对话」，不是「下次不用再问一遍」。所以分两层：

- 会反复用到的结论、偏好、项目约定，写进 memory、`CLAUDE.md` 或 skill，
  下次自动带上。这部分见全局指令里的「Skill 仓库」一节。
- 确实要完整保留的过程，再把 jsonl 转成可读文本归档。

## 隐私

jsonl 里有完整的用户输入、文件内容和命令输出。备份、分享或提交之前先
确认里面没有 token、内网地址、私人数据，不要直接推进公开仓库。
