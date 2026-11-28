---
name: config-vscode-clash-proxy
description: >-
  解决 macOS 上 VS Code 装插件很慢的问题：诊断 Clash Verge 规则是否把
  marketplace.visualstudio.com 和 *.gallerycdn.vsassets.io 放回了直连，
  在增强规则里把相关域名 prepend 到代理分组，并给 VS Code 设置
  http.proxy。还包括 code CLI 装插件时的代理环境变量、配置重载和回滚。
  Use when VS Code 扩展安装或更新很慢、插件下载卡住、marketplace 走不了
  代理，或者需要让 VS Code / code CLI 的流量走 Clash Verge。
metadata:
  short-description: VS Code 插件下载慢的 Clash 代理规则与 http.proxy 配置
---

# VS Code 插件下载走代理（Clash Verge）

目标：VS Code 装插件慢的时候，先确认是代理没通，还是流量到了 Clash 又被
规则扔回直连。大多数情况是后者：系统代理明明开着，但 `microsoft.com` 的
`DIRECT` 规则和 `GEOIP,CN,DIRECT` 把 marketplace 与插件 CDN 都放行了。

已在 macOS + Clash Verge Rev + VS Code 1.10x 上验证。其他 Clash 客户端
（ClashX、Mihomo 内核的图形前端）思路一样，只是配置文件位置不同。

## 诊断

先确认代理链路本身是通的：

```bash
# 系统代理是否指向 Clash
networksetup -getwebproxy Wi-Fi
networksetup -getsecurewebproxy Wi-Fi

# VS Code 是否显式设了代理
grep -n 'http.proxy' "$HOME/Library/Application Support/Code/User/settings.json"
```

然后在 Clash 的运行时配置里看这几个域名的命中情况：

```bash
CFG="$HOME/Library/Application Support/io.github.clash-verge-rev.clash-verge-rev/clash-verge.yaml"
grep -nE 'microsoft\.com|vsassets|vscode-unpkg|GEOIP,CN|MATCH' "$CFG" | head -30
```

典型的问题规则：

```yaml
- DOMAIN-SUFFIX,microsoft.com,DIRECT
- GEOIP,CN,DIRECT
```

`marketplace.visualstudio.com` 会被 `microsoft.com` 那条吃掉；插件包实际
下载地址 `*.gallerycdn.vsassets.io` 没有专门规则，国内解析到 CN 边缘节点
就命中 `GEOIP,CN,DIRECT`。所以即使 VS Code 走系统代理，实际下载还是直连。

## 修复

### 1. Clash 增强规则

在 Clash Verge 的订阅页打开当前订阅的「编辑规则」或直接改增强规则文件
`profiles/<profile-id>.yaml`，把域名加进 `prepend`，让它们排在
`microsoft.com` 之前：

```yaml
prepend:
  - DOMAIN-SUFFIX,vsassets.io,<PROXY_GROUP>
  - DOMAIN,marketplace.visualstudio.com,<PROXY_GROUP>
  - DOMAIN-SUFFIX,vscode-unpkg.net,<PROXY_GROUP>
  - DOMAIN,update.code.visualstudio.com,<PROXY_GROUP>
  - DOMAIN-SUFFIX,prss.microsoft.com,<PROXY_GROUP>
  - DOMAIN-SUFFIX,vo.msecnd.net,<PROXY_GROUP>
```

`<PROXY_GROUP>` 换成当前配置 `proxy-groups:` 里的一个分组名，通常就是
你平时选节点的那个订阅分组。不要照抄别人的名字。

改完在 Clash Verge 里重新应用一次订阅或配置，它才会把 `prepend` 合并进
运行时的 `clash-verge.yaml`。

### 2. VS Code 设置

`~/Library/Application Support/Code/User/settings.json`：

```json
"http.proxy": "http://127.0.0.1:7897",
"http.proxySupport": "override"
```

端口按 Clash 实际混合端口改（Verge 默认常见 7897）。`proxySupport` 设
`override` 是为了让 VS Code 不依赖 Electron 对系统代理的推断。改完完全
退出 VS Code（Cmd+Q）再打开。

### 3. 命令行装插件

`code --install-extension` 不读 VS Code 设置，需要环境变量：

```bash
export https_proxy=http://127.0.0.1:7897
export http_proxy=http://127.0.0.1:7897
code --install-extension <extension-id>
```

## 验证

```bash
CFG="$HOME/Library/Application Support/io.github.clash-verge-rev.clash-verge-rev/clash-verge.yaml"
grep -nE 'vsassets|vscode-unpkg' "$CFG"
```

应该能在 `rules:` 靠前的位置看到刚加的几条。再打开 Clash Verge 的
「连接」页，装一个插件，看 `gallerycdn.vsassets.io` 那几行命中的是不是
`<PROXY_GROUP>`。

如果规则已经生效但仍然慢，先测一下两种方式的速度，别把 CDN 本身的问题
误判成代理问题。必要时用 TUN 模式兜底，或者看 VS Code「输出 → 扩展主机」
里的报错。

## 回滚

删掉增强规则里的 `prepend` 条目，去掉 settings.json 里的 `http.proxy`
和 `http.proxySupport` 两行，重新应用订阅即可。
