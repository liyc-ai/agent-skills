---
name: config-yolo-mode
description: 配置 Codex CLI 的默认权限为全权限（YOLO mode：不弹审批 + 无沙箱），或反向恢复/缩小权限、校验实际生效的权限。Use when asked to make Codex default to full access, 免审批, danger-full-access, yolo mode, or to revert such a setting.
metadata:
  short-description: Codex 默认全权限（YOLO）配置
---

# Codex YOLO 模式配置

把 Codex 的**默认**权限改成"不问、不拦"：不弹审批、无文件系统沙箱、网络放开。等价于每次启动都带 `--dangerously-bypass-approvals-and-sandbox`（本版本的隐藏别名是 `--yolo`）。

在改动任何全局配置前，先确认用户确实要"全局默认"而不是"只对这个仓库"。全局全权限意味着模型在任何项目里都能任意读写文件、执行命令、联网。

## 核心配置

写入 `~/.codex/config.toml` **顶层**（不能放进 `[projects.*]`、`[model_providers.*]` 等表里）：

```toml
approval_policy = "never"
sandbox_mode = "danger-full-access"
```

- `approval_policy = "never"`：不再请求人工审批。
- `sandbox_mode = "danger-full-access"`：无沙箱，读写与网络都不受限。

## 步骤

1. 备份：`cp ~/.codex/config.toml ~/.codex/config.toml.bak-$(date +%Y%m%d-%H%M%S)`
2. 在顶层追加上面两行（保留注释说明如何恢复）。
3. 校验 TOML 可解析：

   ```bash
   python3 -c "import tomllib;d=tomllib.load(open('$HOME/.codex/config.toml','rb'));print(d['approval_policy'],d['sandbox_mode'])"
   ```

4. 校验实际生效（不要只看配置文件，见下节）。

**不要**只凭键名猜测字段是否被本版本识别：用 `scripts/verify_permissions.py` 或 `codex debug prompt-input "hi"` 看模型真正收到的 `<permissions instructions>` 块。

## 验证生效

```bash
python3 scripts/verify_permissions.py                 # 当前 shell 环境下的默认配置
python3 scripts/verify_permissions.py --cwd <repo>    # 该仓库内的有效权限（含项目级配置）
python3 scripts/verify_permissions.py --profile yolo  # 指定 profile
```

脚本会打印 `sandbox_mode`、审批策略与网络状态，并把 stderr 中的"项目配置被忽略 / 被策略覆盖"提示一并输出。它只渲染 prompt，不调用模型。

预期输出包含：

```
sandbox_mode      = danger-full-access
approval policy   = never
network           = enabled
```

## 作用范围与优先级

- **新会话生效**；已经运行的会话沿用启动时的权限，需要重启 `codex` 或新开线程。
- **项目级**：在 `<repo>/.codex/config.toml` 写同样两行，只对该仓库生效。前提是该路径已列入全局配置的 `[projects."<abs path>"] trust_level = "trusted"`；未信任时整份项目配置（含 hooks、exec policy）会被静默忽略，不报错也看不到效果，所以务必用 `--cwd <repo>` 跑一次校验脚本确认。
- **Profile**：把两行写进 `~/.codex/<name>.config.toml`，用 `codex -p <name>` 启动，适合"平时安全、需要时放开"。
- Desktop app 自己的权限开关可能覆盖 config.toml，遇到仍然弹审批时检查 app 内设置。
- 若被 `requirements.toml` 或托管策略限制（如 `allowed_sandbox_modes`），配置会报错或被降级，此时不能靠改 config 绕过。

## 常见坑

- 本版本 `approval_policy` 只接受 `on-request` 和 `never`；旧的 `untrusted` 已废弃，写入会直接报错。
- 不要同时使用新的权限体系键（`default_permissions` / `[permissions.*]`）和 `sandbox_mode`，混用会报 `<sandbox_mode> and default_permissions overrides cannot both be set`。
- `--yolo` / `--dangerously-bypass-approvals-and-sandbox` 只作用于单次会话，不改变默认值。
- 键写错层级（例如放进 `[projects."..."]`）时 TOML 依然合法，但完全不生效，必须用上面的脚本验证。

## 恢复安全默认

删掉这两行，或改成：

```toml
approval_policy = "on-request"
sandbox_mode = "workspace-write"
```

只想"工作区内免审批、但仍然沙箱"时，用 `approval_policy = "never"` + `sandbox_mode = "workspace-write"`。

---

已在 codex-cli 0.169.0 (macOS) 上验证：顶层键、项目级覆盖、profile 覆盖三条路径都能通过 `codex debug prompt-input` 观察到生效。
