# HaGeZi DNS Blocklists —  PowerDNS Recursor 集成指南

> **项目地址**: https://github.com/hagezi/dns-blocklists

## 1. 项目概述

### 1.1 这是什么？

HaGeZi DNS Blocklists 是一个**综合性 DNS 阻止列表集合**，旨在通过 DNS 层面屏蔽广告、跟踪器、恶意软件、钓鱼、诈骗等不良内容，清洁互联网并保护用户隐私。

### 1.2 核心特点

| 特性                 | 说明                                                     |
| -------------------- | -------------------------------------------------------- |
| **多级别防护** | Light → Normal → Pro → Pro++ → Ultimate 五个防护等级 |
| **多格式支持** | AdBlock、Hosts、Domains、Wildcard、RPZ、DNSMasq 等       |
| **每日更新**   | 所有列表每 24 小时自动更新                               |
| **广泛测试**   | 基于 Cisco Umbrella Top 100 万网站进行误拦测试           |
| **多源整合**   | 聚合 100+ 第三方源并加入自有数据，非简单拼接             |
| **区域性适用** | 适用于全球所有地区                                       |
| **死域名清理** | 定期清理失效域名，保持列表精简                           |

### 1.3 文件内容

HaGeZi DNS Blocklists 的 RPZ 格式适用于 PowerDNS Recursor，文件内容如下:

每个 RPZ 文件都是一个完整的 BIND zone 文件，结构如下：

```
$TTL 3600
@ SOA localhost. root.localhost. 1781894340 14400 3600 86400 3600
  NS  localhost.
;
; Title: HaGeZi's ...
; Last modified: ...
; Syntax: RPZ
; Number of entries: XXXXX
;
bad-domain.com CNAME .
*.bad-domain.com CNAME .
```

RPZ 策略动作

| 动作                 | 说明                       | 客户端表现                         |
| -------------------- | -------------------------- | ---------------------------------- |
| **NXDOMAIN**  | 返回域名不存在             | 客户端立即停止尝试                 |
| **Drop**       | 丢弃查询无响应             | 客户端超时重试（消耗资源）         |
| **NODATA**     | 返回空响应                 | 域名存在但无该类型记录             |
| **Truncate**   | 返回 TC 标志               | 强制客户端走 TCP（消耗攻击者资源） |
| **NoAction**   | 不拦截（用于监控或白名单） | —                                 |
| **Custom**     | 自定义响应                 | 配合 defcontent 显示拦截页         |

## 2. 适配本仓库的部署方式

如果你使用的是当前仓库里的 PowerDNS Recursor 模板，建议按下面的方式组织：

- 将更新脚本仓库中的 [rpz/update-hagezi-rpz.sh](rpz/update-hagezi-rpz.sh) 部署到对应的目标路径 `/etc/powerdns/rpz/`
- 将 RPZ 规则配置块追加到 Recursor 主配置目录中的 `/etc/powerdns/recursor.d/06-recursor.yml`
- 先使用 `--dry-run` 验证下载结果，再执行正式更新
- 更新后执行 `systemctl restart pdns-recursor` 让新规则生效

> 说明：本仓库已经提供了更新脚本和白名单模板文件，文档中的示例可以直接作为“部署到生产环境时”的参考，但实际部署时优先以 `/etc/powerdns/...` 的路径为准。

## 3. 防护方案（以 Multi 等级为核心）

Multi 多合一（五个防护等级）系列是 HaGeZi 的核心产品线，每个等级包含广告、跟踪器、恶意软件的综合规则。

**等级越高 = 防护越强 = 条目越多 = 误拦风险略增。**

| Tier | Multi 等级 | 防护范围           | 推荐搭配                         | 总条目 | 内存    | 适用场景        |
| ---- | ---------- | ------------------ | -------------------------------- | ------ | ------- | --------------- |
| 1    | Pro        | +崩溃跟踪器+弹窗   | TIF Medium + TLDs + DoH          | ~730K  | ~180 MB | 中小企业/推荐   |
| 2    | Pro++      | +更多恶意软件+钓鱼 | TIF Medium + TLDs + Dyndns + DoH | ~750K  | ~185 MB | 大型企业        |
| 3    | Ultimate   | +激进规则+诈骗     | TIF + TLDs Aggr + Dyndns + DoH   | ~1.87M | ~470 MB | 高安全/最大防护 |

## 4. 常用规则

### 1、Multi Pro、Pro++、ultimate 三选一

```bash
# Multi Pro
curl -sSL -o /etc/powerdns/rpz/hagezi-pro.txt \
  'https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/rpz/pro.txt'

# Multi Pro++
curl -sSL -o /etc/powerdns/rpz/hagezi-proplus.txt \
    'https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/rpz/pro.plus.txt'
  

# Multi ultimate
curl -sSL -o /etc/powerdns/rpz/hagezi-ultimate.txt \
    'https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/rpz/ultimate.txt'
```

### 2、其余规则默认全选

```bash
# Threat Intelligence Feeds
curl -sSL -o /etc/powerdns/rpz/hagezi-tif.txt \
    'https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/rpz/tif.txt'

#  Fake
curl -sSL -o /etc/powerdns/rpz/hagezi-fake.txt \
  'https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/rpz/fake.txt'

# Pop-Up Ads
curl -sSL -o /etc/powerdns/rpz/hagezi-popupads.txt \
  'https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/rpz/popupads.txt'

# DoH/VPN/TOR/Proxy Bypass
curl -sSL -o /etc/powerdns/rpz/hagezi-doh.txt \
  'https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/rpz/doh-vpn-proxy-bypass.txt'

# Safesearch not supported
curl -sSL -o /etc/powerdns/rpz/hagezi-nosafesearch.txt \
  'https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/rpz/nosafesearch.txt'

# Dynamic DNS blocking
curl -sSL -o /etc/powerdns/rpz/hagezi-dyndns.txt \
  'https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/rpz/dyndns.txt'

# Badware Hoster blocking
curl -sSL -o /etc/powerdns/rpz/hagezi-hoster.txt \
  'https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/rpz/hoster.txt'

# URL Shortener
curl -sSL -o /etc/powerdns/rpz/hagezi-urlshortener.txt \
  'https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/rpz/urlshortener.txt'

# Most Abused TLDs
curl -sSL -o /etc/powerdns/rpz/hagezi-tlds.txt \
  'https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/rpz/spam-tlds-rpz.txt'

# DNS Rebind Protection
curl -sSL -o /etc/powerdns/rpz/hagezi-anti.txt \
  'https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/rpz/anti.piracy.txt'

# Gambling
curl -sSL -o /etc/powerdns/rpz/hagezi-gambling.txt \
  'https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/rpz/gambling.txt'

# Social Networks
curl -sSL -o /etc/powerdns/rpz/hagezi-social.txt \
  'https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/rpz/social.txt'

# NSFW
curl -sSL -o /etc/powerdns/rpz/hagezi-nsfw.txt \
  'https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/rpz/nsfw.txt'
```

## 5. 配置过程

### 5.1 在配置文件06-recursor.yml中添加rpz规则

规则默认使用 Multi ultimate，若需要其他版本的 Multi，自行修改配置文件，执行下载脚本时选对版本即可。

```bash
sudo nano /etc/powerdns/recursor.d/06-recursor.yml

# 添加以下内容
recursor:
  ....................

  rpzs:
    # ─── 白名单（优先级最高，匹配到的域名不拦截）───
    - name: '/etc/powerdns/rpz/whitelist.txt'
      defpol: NoAction
      policyName: 'whitelist'

    # ─── Multi ultimate — 广告/跟踪/恶意软件/弹窗───
    - name: '/etc/powerdns/rpz/hagezi-ultimate.txt'
      defpol: NXDOMAIN
      policyName: 'hagezi-ultimate'

    # ─── TIF — 威胁情报 (~1.6M 条目, ~400MB 内存) ───
    - name: '/etc/powerdns/rpz/hagezi-tif.txt'
      defpol: NXDOMAIN
      policyName: 'hagezi-tif'

    # ─── Fake — 虚假网店/诈骗检测 (~16K 条目) ───
    - name: '/etc/powerdns/rpz/hagezi-fake.txt'
      defpol: NXDOMAIN
      policyName: 'hagezi-fake'

    # ─── Pop-Up Ads — 弹窗广告拦截 (~56K 条目) ───
    - name: '/etc/powerdns/rpz/hagezi-popupads.txt'
      defpol: NXDOMAIN
      policyName: 'hagezi-popupads'

    # ─── Safesearch — 强制安全搜索 ───
    - name: '/etc/powerdns/rpz/hagezi-nosafesearch.txt'
      defpol: NXDOMAIN
      policyName: 'hagezi-nosafesearch'

    # ─── Abused TLDs — 高风险顶级域拦截 (~130 条) ───
    - name: '/etc/powerdns/rpz/hagezi-tlds.txt'
      defpol: NXDOMAIN
      policyName: 'hagezi-tlds'

    # ─── Badware Hoster — 恶意软件托管商 (~1.2K 条目) ───
    - name: '/etc/powerdns/rpz/hagezi-hoster.txt'
      defpol: NXDOMAIN
      policyName: 'hagezi-hoster'

    # ─── DoH/VPN/Proxy Bypass — 防止 DNS 绕过 (~3.4K 条目) ───
    - name: '/etc/powerdns/rpz/hagezi-doh.txt'
      defpol: NXDOMAIN
      policyName: 'hagezi-doh'

    # ─── Dynamic DNS — 动态 DNS 阻止/防 C2 (~1.5K 条目) ───
    - name: '/etc/powerdns/rpz/hagezi-dyndns.txt'
      defpol: NXDOMAIN
      policyName: 'hagezi-dyndns'

    # ─── URL Shortener — 短链接服务拦截 (~10K 条目) ───
    - name: '/etc/powerdns/rpz/hagezi-urlshortener.txt'
      defpol: NXDOMAIN
      policyName: 'hagezi-urlshortener'

    # ─── Anti Piracy — 反盗版 (~31K 条目) ───
    - name: '/etc/powerdns/rpz/hagezi-anti.txt'
      defpol: NXDOMAIN
      policyName: 'hagezi-anti'

    # ─── Gambling — 赌博网站拦截 (~280K 条目) ───
    - name: '/etc/powerdns/rpz/hagezi-gambling.txt'
      defpol: NXDOMAIN
      policyName: 'hagezi-gambling'

    # ─── Social Networks — 社交网络拦截 (~900 条目) ───
    - name: '/etc/powerdns/rpz/hagezi-social.txt'
      defpol: NXDOMAIN
      policyName: 'hagezi-social'

    # ─── NSFW — 成人内容拦截 ───
    - name: '/etc/powerdns/rpz/hagezi-nsfw.txt'
      defpol: NXDOMAIN
      policyName: 'hagezi-nsfw'
```

### 5.2 检查配置是否有误

```bash
sudo pdns_recursor --config=check

# 如下所示，则说明配置文件没有问题
Jul 05 16:58:54 PowerDNS Recursor 5.4.3 (C) PowerDNS.COM BV
Jul 05 16:58:54 Using 64-bits mode. Built using clang 19.1.7 (3+b1) on Jun  9 2026 07:15:10 by root@localhost.
Jul 05 16:58:54 PowerDNS comes with ABSOLUTELY NO WARRANTY. This is free software, and you are welcome to redistribute it according to the terms of the GPL version 2.
Jul 05 16:58:54 msg="Processing main YAML settings" subsystem="config" level="0" prio="Notice" tid="0" ts="1783241934.739" path="/etc/powerdns/recursor.yml"
Jul 05 16:58:54 msg="Processing YAML settings" subsystem="config" level="0" prio="Notice" tid="0" ts="1783241934.740" path="/etc/powerdns/recursor.d/01-incoming.yml"
Jul 05 16:58:54 msg="Processing YAML settings" subsystem="config" level="0" prio="Notice" tid="0" ts="1783241934.740" path="/etc/powerdns/recursor.d/02-outgoing.yml"
Jul 05 16:58:54 msg="Processing YAML settings" subsystem="config" level="0" prio="Notice" tid="0" ts="1783241934.741" path="/etc/powerdns/recursor.d/03-dnssec.yml"
Jul 05 16:58:54 msg="Processing YAML settings" subsystem="config" level="0" prio="Notice" tid="0" ts="1783241934.742" path="/etc/powerdns/recursor.d/04-ecs.yml"
Jul 05 16:58:54 msg="Processing YAML settings" subsystem="config" level="0" prio="Notice" tid="0" ts="1783241934.743" path="/etc/powerdns/recursor.d/05-cache.yml"
Jul 05 16:58:54 msg="Processing YAML settings" subsystem="config" level="0" prio="Notice" tid="0" ts="1783241934.743" path="/etc/powerdns/recursor.d/06-recursor.yml"
Jul 05 16:58:54 msg="Processing YAML settings" subsystem="config" level="0" prio="Notice" tid="0" ts="1783241934.745" path="/etc/powerdns/recursor.d/07-nod.yml"
Jul 05 16:58:54 msg="Processing YAML settings" subsystem="config" level="0" prio="Notice" tid="0" ts="1783241934.745" path="/etc/powerdns/recursor.d/08-logging.yml"
Jul 05 16:58:54 msg="Processing YAML settings" subsystem="config" level="0" prio="Notice" tid="0" ts="1783241934.745" path="/etc/powerdns/recursor.d/09-webservice.yml"
Jul 05 16:58:54 msg="YAML config found and processed" subsystem="config" level="0" prio="Notice" tid="0" ts="1783241934.746" configname="/etc/powerdns/recursor.yml"
```

### 5.3 部署规则文件下载脚本

脚本详见 update-hagezi-rpz.sh

#### 1、创建目录与部署脚本

```bash
sudo mkdir -p /etc/powerdns/rpz
sudo cp update-hagezi-rpz.sh /etc/powerdns/rpz/update-hagezi-rpz.sh
sudo chmod +x /etc/powerdns/rpz/update-hagezi-rpz.sh
```

#### 2、下载规则文件

```bash
cd /etc/powerdns/rpz

# 查看等级清单
sudo sh ./update-hagezi-rpz.sh --list

# 模拟 Tier 3 下载（dry-run）
sudo sh ./update-hagezi-rpz.sh --dry-run 3

# 正式执行 Tier 3
sudo sh ./update-hagezi-rpz.sh 3
```

#### 3、重启并检查服务

```bash
sudo systemctl restart pdns-recursor
sudo systemctl status pdns-recursor
```

#### 4、查看日志确定没有错误

```bash
sudo journalctl -u pdns-recursor --no-pager | tail -50

# 查看 RPZ 命中统计
sudo rec_control get-all | grep policy

# 测试某个域名是否被 RPZ 拦截，如果返回 NXDOMAIN 且日志有 RPZ 命中记录，说明生效
dig @127.0.0.1 doubleclick.net | grep status
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 61781
```

### 5.4 配置 systemd timer

HaGeZi 列表每日更新，需定期同步。推荐使用 systemd timer（现代 Linux 标准方式）

#### 1、创建 service 单元

```bash
sudo nano /etc/systemd/system/hagezi-rpz-update.service

# 写入以下内容
[Unit]
Description=HaGeZi RPZ Update
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=/etc/powerdns/rpz/update-hagezi-rpz.sh
WorkingDirectory=/etc/powerdns/rpz
StandardOutput=journal
StandardError=journal
# 安全加固
ProtectSystem=strict
ReadWritePaths=/etc/powerdns/rpz
PrivateTmp=yes
NoNewPrivileges=yes
EOF
```

#### 2、创建 timer 单元

```bash
sudo nano /etc/systemd/system/hagezi-rpz-update.timer

# 写入以下内容
[Unit]
Description=Daily HaGeZi RPZ update

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=600

[Install]
WantedBy=timers.target
```

| 参数                       | 含义                                            |
| -------------------------- | ----------------------------------------------- |
| `OnCalendar=daily`       | 每天 00:00 触发                                 |
| `Persistent=true`        | 若系统在触发时间处于关机状态，启动后立即补执行  |
| `RandomizedDelaySec=600` | 随机延迟 0~600 秒，避免所有用户同一时刻访问 CDN |

#### 3、启用并验证

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now hagezi-rpz-update.timer

# 查看 timer 状态和下次触发时间
systemctl status hagezi-rpz-update.timer
systemctl list-timers | grep hagezi

# 手动触发一次测试
sudo systemctl start hagezi-rpz-update.service
journalctl -u hagezi-rpz-update.service -f
```

## 6. 常见问题

**Q: TIF 完整版（例如 1.6M 条目）值得使用吗？**

A: 不一定。对于大多数部署而言，完整 TIF 版会显著增加内存占用和启动时间，通常不建议直接作为首选。更稳妥的方式是先从 Multi 系列入手，再根据实际风险和资源情况，逐步增加 TIF 或恶意 TLD 等专项规则进行测试。

**Q: RPZ 文件下载失败怎么办？**

A: 脚本会保留已有文件，避免把旧规则替换成空文件。若下载失败，先排查网络、URL 或权限问题；修复后重新执行脚本即可。对于已存在的 RPZ 文件，通常先尝试 `rec_control reload-zones` 让 Recursor 重新加载，而不是直接重启服务。

**Q: 可以和 Spamhaus RPZ 等其他源一起使用吗？**

A: 可以。RPZ 的匹配顺序是按配置顺序执行，先命中的策略会优先生效。建议顺序为：白名单 → 自定义黑名单/本地策略 → HaGeZi → 其他威胁情报源。

**Q: 是否需要同时加载 Multi Pro 和各个专项列表？**

A: 不一定。Multi 系列已经包含大量常见广告、跟踪和恶意软件规则，是否再叠加专项列表，应根据资源情况和误报容忍度来决定。建议先从一个 Multi 等级配合少量专项规则开始测试，避免一次性引入过多规则。

**Q: 更新后需要重启 Recursor 吗？**

A: 通常不需要。更新 RPZ 文件后，优先使用 `rec_control reload-zones`；如果只是修改 YAML 配置，则使用 `rec_control reload-yaml`。只有在新增/删除 `rpzs` 条目、修改配置结构，或服务无法正常加载新规则时，才考虑执行 `systemctl restart pdns-recursor`。

## 7. 企业最常用的规则组合建议

根据 HaGeZi 官方仓库的说明，企业环境里最常见、也最实用的组合通常集中在以下几类：

### 7.1 推荐入门组合：Multi Pro + TIF + TLDs + DoH

这是最常见的“平衡型”企业组合：

- `Multi Pro`：提供稳定的广告、跟踪、恶意软件、诈骗和钓鱼防护基础能力。
- `TIF`：增强威胁情报类拦截，适合提升安全防御能力。
- `Most Abused TLDs`：拦截高风险顶级域，能有效降低钓鱼和恶意域名风险。
- `DoH/VPN/TOR/Proxy Bypass`：阻止 DNS 绕过链路，避免用户通过加密 DNS 绕开内网策略。

这套组合适合大多数企业内部 DNS 递归服务，兼顾“可管理性、误报可控性和安全性”。

### 7.2 更激进的安全组合：Multi Pro++ + TIF + Fake + Dyndns + DoH

如果你希望在安全性上进一步加强，可以考虑：

- `Multi Pro++`：比 Pro 更激进，覆盖更多恶意和诈骗类域名。
- `Fake`：拦截虚假商店、诈骗和诱导式钓鱼页面。
- `Dynamic DNS`：阻止动态 DNS 服务滥用。
- `DoH/VPN/TOR/Proxy Bypass`：确保 DNS 绕过行为被拦截。

这类组合更适合高安全要求的企业、金融、政府、教育机构等场景，但需要留出白名单和误报处理流程。

### 7.3 高防护但更激进的组合：Ultimate + TIF + 额外专项规则

如果组织对安全要求非常高，并且愿意接受更高的误报和资源消耗，可以采用：

- `Ultimate`：提供更激进的全量保护。
- `TIF`：继续补充威胁情报。
- `Fake`、`Gambling`、`Social`、`NSFW` 等专项规则：根据公司策略决定是否启用。

这组组合适合敏感网络环境，但建议先在测试环境验证，再逐步上线。

### 7.4 企业部署时的实战建议

- 优先从 `Multi Pro` 开始，不要一开始就上 `Ultimate`。
- 如果资源较紧张，先使用 `Multi Pro` 或 `Multi Pro++`，再根据 CPU/内存情况加 `TIF`。
- 对于需要强管控的环境，建议同时启用 `Most Abused TLDs` 和 `DoH/VPN/TOR/Proxy Bypass`。
- 对于允许少量误报但更看重安全的环境，可考虑 `Fake`、`Dyndns`、`Gambling`、`Social`、`NSFW` 等专项规则。
- 所有上线前都建议先在测试网段验证，并预留白名单机制，避免影响业务系统。

### 7.5 简单结论

如果你要在企业环境中快速落地，最推荐的默认方案是：

- `Multi Pro` + `TIF` + `Most Abused TLDs` + `DoH/VPN/TOR/Proxy Bypass`

如果你希望更强的安全防护，则可以升级为：

- `Multi Pro++` + `TIF` + `Fake` + `Dyndns` + `DoH/VPN/TOR/Proxy Bypass`
