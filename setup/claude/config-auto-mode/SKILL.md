---
name: config-auto-mode
description: >-
  把 Claude Code 的默认权限模式改成 auto mode（安全分类器逐个判断工具调用，
  安全的直接放行，危险的才询问或拦截），或恢复成逐次确认、排查 auto mode
  不生效的原因。Use when asked to make Claude Code default to auto mode,
  自动批准/免逐次确认, permissions.defaultMode=auto, auto-mode-setup, or to
  revert/verify the default permission mode.
metadata:
  short-description: Claude Code 默认 auto 权限模式
---

# Claude Code auto 模式配置

目标：新开的 Claude Code 会话默认就是 auto mode，不用每次手动切；它不是全放行，危险动作仍然会拦。

先把几种权限模式分清楚：

- `manual` / `default`：每个工具调用都停下来问。
- `acceptEdits`：只自动放行工作区内的文件编辑，Bash 等照样问。
- `auto`：每次工具调用交给安全分类器判断，安全的直接执行，可能危险或不可逆的才拦下来问人（或直接拒绝）。
- `bypassPermissions`：全部放行，不做任何检查，只适合一次性、无网络的沙箱。

auto 比 `acceptEdits` 覆盖得广（Bash、WebFetch、MCP 工具也走分类器），又比 `bypassPermissions` 安全，适合当日常默认。

## 核心配置

写进用户级 `~/.claude/settings.json`：

```json
{
  "permissions": {
    "defaultMode": "auto"
  }
}
```

几个要点：

- **必须放用户级**。项目里的 `.claude/settings.json` 或 `.claude/settings.local.json` 写 `"defaultMode": "auto"` 不会被采纳，Claude Code 会忽略这个值，而且它还会挡住用户级的模式设置。想让所有仓库都生效，只能改 `~/.claude/settings.json`。
- 文件里的其它键（`model`、`env`、`permissions.allow` 等）保持原样，只加 `defaultMode`，不要整份覆盖。
- `permissions.disableAutoMode: "disable"`（常见于 managed settings 或公司策略）会让 auto 直接不可用，有这个键时改了也不生效。
- 新版 Claude Code 在没有任何设置指定模式时，可能自己默认成 auto（灰度开关控制）。显式写死更可控，也避免以后开关变化。

## 步骤

1. 备份：

   ```bash
   cp ~/.claude/settings.json ~/.claude/settings.json.bak-$(date +%Y%m%d-%H%M%S)
   ```

2. 合并写入（保留已有键）：

   ```bash
   python3 - <<'PY'
   import json, pathlib
   p = pathlib.Path.home() / ".claude/settings.json"
   data = json.loads(p.read_text()) if p.exists() else {}
   data.setdefault("permissions", {})["defaultMode"] = "auto"
   p.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
   print(json.dumps(data.get("permissions"), indent=2))
   PY
   ```

3. 校验 JSON 没写坏：

   ```bash
   python3 -c "import json;json.load(open('$HOME/.claude/settings.json'));print('ok')"
   ```

4. **新开一个会话**才生效。当前已经在跑的会话沿用启动时的模式。

## 验证生效

```bash
python3 scripts/verify_auto_mode.py               # 当前目录（含项目级设置）
python3 scripts/verify_auto_mode.py --cwd <repo>  # 指定仓库
```

脚本会列出每个 settings 文件里的 `permissions.defaultMode`，检查有没有 `disableAutoMode`，再真的启动一个 `claude -p ... --max-turns 0` 子进程，从 init 事件里读实际生效的 `permissionMode`。这条路径不调用模型，只验证模式。

预期输出包含：

```
live permissionMode = auto
```

会话里也可以按 `/status` 或 `/permissions` 查看当前模式。

## auto 模式怎么判断

auto mode 会把工具调用（尤其是 Bash 命令、WebFetch、写文件等）交给一个安全分类器，由它判断是否安全。分类器放行读文件、搜索、常规构建测试这类操作；对删除、推送、改全局配置、访问未知域名等会给人的确认或直接拒绝。

分类器要调用模型，所以：

- 用官方 API 时开箱即用。
- 走自建代理或第三方模型（例如把 `ANTHROPIC_BASE_URL` 指到本地网关，模型是 deepseek、kimi 之类）时，分类器可能拿不到可用的判断，报 "auto mode's check had no usable answer" 或 "none of the models allowed for its auto mode check can be used here"。这时动作会退回询问，不会静默放行，但 auto 的免打扰效果会打折。用本地代理时先跑一次验证，观察实际行为。
- 会话里可以用 `/auto-mode-setup` 给分类器补充环境说明、调整规则。

## 恢复与临时切换

- 恢复成逐次询问：把 `defaultMode` 改成 `"default"`（或删掉这个键）。
- 只自动改文件、Bash 仍询问：`"acceptEdits"`。
- 单次会话覆盖：`claude --permission-mode auto` / `claude --permission-mode default`，不写配置文件。
- 会话内用 Shift+Tab 循环切换模式（下次启动仍看设置）。
- `--dangerously-skip-permissions` 是绕过所有检查的 bypass，和 auto 不是一回事。

## 常见坑

- 写进项目级 `.claude/settings.json` 不生效，还可能是"看起来配了、实际没切"的根源；把项目里的 `defaultMode: auto` 删掉，改到用户级。
- 改完不新开会话看不到变化。
- auto 不等于全放行：删除、外发、`git push`、改 `~/.claude` 之类仍可能被拦，这是预期行为；真正要什么都不问只能用 `bypassPermissions`，不建议常开。
- 非交互跑 `claude -p` 时没人能回答权限询问，被拦的动作会直接按拒绝处理，需要提前用 `permissions.allow` 或 `--allowedTools` 放行。
- 公司 managed settings 优先级最高，里面的 `disableAutoMode` 或 `defaultMode` 会覆盖个人设置。

---

已在 Claude Code 2.1.332 (macOS) 上验证：用户级 `permissions.defaultMode: "auto"` 会让新会话的 init 事件返回 `"permissionMode":"auto"`；项目级写入会被忽略。
