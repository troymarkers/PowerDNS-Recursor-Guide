# PowerDNS Recursor — DNSSEC 验证

> 来源: https://doc.powerdns.com/recursor/dnssec.html


自 4.0.0 起，PowerDNS Recursor 支持 DNSSEC 处理和验证。
对递归解析器而言，DNSSEC 保护客户端到解析器之间的"最后一公里"。


## 一、验证模式详解

Recursor 提供 **5 个级别**的 DNSSEC 处理，由 `dnssec.validation` 控制：

### 模式对比表

| 行为 | off | process-no-validate | process | log-fail | validate |
|------|:---:|:-------------------:|:-------:|:--------:|:--------:|
| 执行验证 | 否 | 否 | 仅客户端+AD/+DO | 总是 | 总是 |
| Bogus 返回 SERVFAIL | 否 | 否 | 仅 +AD/+DO | 仅 +AD/+DO | CD=0 时 |
| 验证通过设 AD 标志 | 否 | 否 | 仅 +AD/+DO | 仅 +AD/+DO | 仅 +AD/+DO |
| +DO 查询返回 RRSIG/NSEC | 否 | 是 | 是 | 是 | 是 |

> `dig` 默认设置 AD 标志。测试时使用 `dig +noad` 获得更直观的结果。

### `off` — 完全关闭

- 不设出站 DO 位、忽略查询中的 DO/AD 位
- 行为类似 4.0 之前的 Recursor
- 适合仅做转发、不需要 DNSSEC 的场景

### `process-no-validate` — 安全感知，不验证

- 4.5.0 之前的默认模式
- 给请求 DNSSEC 的客户端返回 RRSIG/NSEC 等记录
- 不执行任何验证，`auth-zones` 中的 zone 也不返回 DNSSEC 记录

### `process` — 按需验证（4.5+ 默认）

- 类似 `process-no-validate`，额外：
  - 客户端设置 DO 或 AD 位时尝试验证
  - 验证成功设 AD 标志，Bogus 返回 SERVFAIL
- 企业内网推荐的起步模式

### `log-fail` — 总是验证并记录

- 无论客户端是否请求都验证
- Bogus 记录到日志但不拒绝（行为同 `process`）
- 用于上线前评估：了解验证负载和 Bogus 比例

### `validate` — 完整强制验证（企业推荐）

- 总是验证所有数据
- Bogus 一律返回 SERVFAIL（除非客户端设 CD 位）
- 公网递归和企业安全环境的**推荐模式**

---

## 二、CD 位 (Checking Disabled)

`process`、`log-fail` 和 `validate` 模式下都支持 CD 位：

- 客户端设置 CD 位时，即使验证失败也返回结果（不设 AD）
- `log-fail` 模式下仍会记录失败日志

---

## 三、信任锚点 (Trust Anchors)

信任锚点是 DNSSEC 验证链的根。Recursor 内置 ICANN 根区 KSK。

> Recursor 不支持 RFC 5011 自动密钥轮转，也不会持久化根信任锚点变更。

### 配置文件配置

```yaml
dnssec:
  trustanchors:
    # 根区信任锚点（已内置，此示例覆盖内置值）
    - name: '.'
      dsrecords:
        - '20326 8 2 e06d44b80b8f1d39a95c0b0d7c65d08458e880409bbc683457104237c7f8ec8d'
        - '38696 8 2 683d2d0acb8c9b712a1948b27f741219298d0a450d612c483af444a4c0fb2b16'
    # 内部签名域（未在公网委托）
    - name: 'internal.example.com'
      dsrecords:
        - '44030 8 2 D4C3D5552B8679FAEEBC317E5F048B614B2E5F607DC57F1553182D49AB2179F7'
```

### 从 BIND 区域文件加载

```yaml
dnssec:
  trustanchorfile: '/usr/share/dns/root.key'       # Debian dns-root-data 包
  trustanchorfile_interval: 24                      # 重新加载间隔（小时），0 禁用
```

仅读取文件中的 DS 和 DNSKEY 记录。此文件中的根信任锚点会**覆盖**内置值。

> **注意**: 运行时通过 `rec_control add-ta` 添加的信任锚点在文件重新加载时会被覆盖。设 `trustanchorfile_interval: 0` 可禁用自动加载。

### 运行时管理 (`rec_control`)

```bash
# 添加信任锚点
rec_control add-ta domain.example 63149 13 1 a59da3f5c1b97fcd5fa2b3b2b0ac91d38a60d33a

# 查看所有信任锚点
rec_control get-tas
# 输出:
# Configured Trust Anchors:
# .       20326 8 2 e06d44b80b8f...
# net.    2574 13 1 a5c5acb8...

# 删除信任锚点（根区不可删除）
rec_control clear-ta domain.example

# 也可通过 DNS 查询（需 allow_trust_anchor_query=true）
dig @127.0.0.1 CH TXT trustanchor.server
```

运行时修改是**易失的**（重启丢失），永久配置需写入 `recursor.yml`。

---

## 四、否定信任锚点 (Negative Trust Anchors, NTA)

NTA (RFC 7646) 用于**临时禁用**某域名的 DNSSEC 验证。典型场景：

- TLD 或高流量域名的 DNSSEC 配置错误导致大面积 Bogus
- 验证确实是配置问题而非攻击行为后使用

### 配置文件配置

```yaml
dnssec:
  negative_trustanchors:
    - name: 'example.com'
      reason: 'botched key rollover at registry'
    - name: 'example.org'
      reason: 'DS in parent, no DNSKEY in child zone'
```

### 运行时管理 (`rec_control`)

```bash
# 添加 NTA（可带原因）
rec_control add-nta domain.example "botched keyroll"

# 查看所有 NTA
rec_control get-ntas
# 输出:
# Configured Negative Trust Anchors:
# subdomain.example.      Operator failed key-roll
# otherdomain.example.    DS in parent, no DNSKEY in zone

# 删除 NTA
rec_control clear-nta subdomain.example

# 删除所有 NTA（注意 shell 引号）
rec_control clear-nta '*'

# 通过 DNS 查询 NTA 列表（需 allow_trust_anchor_query=true）
dig @127.0.0.1 CH TXT negativetrustanchor.server
```

---

## 五、DNSSEC 验证流程

```
客户端 DNS 查询
  │
  ▼
Recursor 接收查询
  │
  ├─ validation=off ──────────────────────> 跳过 DNSSEC，正常递归
  ├─ validation=process-no-validate ──────> 传递 DNSSEC 记录，不验证
  └─ validation=process/log-fail/validate ─> 设出站 DO 位，请求 DNSSEC 记录
       │
       ▼
     递归解析
       │
       ├─ 无信任锚点 ──> Insecure（无验证链）
       └─ 有信任锚点 ──> 沿 DNS 树逐级验证 DS -> DNSKEY -> RRSIG
            │
            ├─ Secure ───> 设 AD 标志，返回结果
            ├─ Insecure ──> 返回结果（无 AD 标志）
            └─ Bogus ────> 客户端 CD=1: 返回结果无 AD
                          └─ 客户端 CD=0 (validate): 返回 SERVFAIL
```

---

## 六、企业 DNSSEC 最佳实践

### 渐进式部署流程

1. 设为 `log-fail`，观察 1~2 周
2. 分析日志，统计 Bogus 比例
3. 添加 NTA 修复已知问题域
4. 设为 `validate`，正式启用
5. 持续监控 `dnssec-*` 指标

### 关键监控指标

- **`dnssec-validations`**: 验证总数，监控趋势。
- **`dnssec-result-secure`**: Secure 验证通过数。
- **`dnssec-result-insecure`**: Insecure 数（无验证链）。
- **`dnssec-result-bogus`**: Bogus 验证失败数。大于 0 应告警。
- **`dnssec-result-indeterminate`**: 无法确定数，关注趋势。
- **`x-dnssec-result-bogus-*`**: 按域名独立统计的 Bogus 数。

### 常见问题

- **内部域转发 Bogus**：内部域有 DNSSEC 父域但本地无签名。添加 NTA 或手动配置 DS 记录作为 Trust Anchor。
- **时钟不同步**：`signature_inception_skew` 相关错误。调大 `dnssec.signature_inception_skew` 并同步 NTP。
- **RSASHA1 算法验证失败**：RHEL9 等强加密策略系统自动禁用。手动调整 `disabled_algorithms` 或放宽 crypto-policies。
- **NSEC3 迭代过多**：CPU 飙升。降低 `dnssec.nsec3_max_iterations`。
- **根密钥轮转**：需要更新信任锚点。更新 `trustanchorfile` 或 `trustanchors` 配置。

### 企业生产推荐配置

```yaml
dnssec:
  validation: validate                      # 强制验证

  trustanchorfile: '/usr/share/dns/root.key'
  trustanchorfile_interval: 24

  negative_trustanchors:
    - name: 'internal.example.com'
      reason: 'Internally managed, no DNSSEC'

  nsec3_max_iterations: 50
  signature_inception_skew: 60
  aggressive_nsec_cache_size: 100000
  log_bogus: true
```

---

## 七、为私有域配置 DNSSEC（完整操作指南）

当企业内部有私有 DNS 权威服务器管理内部域名，且希望启用 DNSSEC 验证时，需要在权威端签名后在 Recursor 端手动配置 Trust Anchor。

核心原因：私有域无法在公网 TLD 注册局提交 DS 记录，必须由 Recursor 管理员手动配置 Trust Anchor，绕过正常的 DNSSEC 父域验证链。

### 7.1 架构概览

```
公网根 (.)
  │ DS(com) ← 由根 DNSKEY 签名验证
  ▼
.com TLD
  │ zjygsj.com 的 DS 记录未在公网注册 → 验证链断裂
  ▼
zjygsj.com 权威服务器 (10.20.1.8:53)
  │ DNSKEY (已签名)
  ▼
www.zjygsj.com A 记录 + RRSIG

── 解决方案 ──
Recursor 配置 trustanchors:
  - name: 'zjygsj.com'
    dsrecords:
      - '<从私有权威导出的 DS 记录>'

效果: Recursor 跳过 .com 的 DS 检查，直接信任此 DS 记录
      验证链: trustanchor(手动) → DNSKEY → RRSIG
```

### 7.2 前提条件

- 私有权威 DNS 服务器支持 DNSSEC 签名（PowerDNS Authoritative / BIND / Knot DNS 等）
- PowerDNS Recursor 已配置 `forward_zones` 将私有域转发到私有权威
- 两台服务器时间偏差在 60 秒以内（DNSSEC 签名有时效性）

### 7.3 第一步：在私有权威服务器上对 Zone 进行 DNSSEC 签名

**PowerDNS Authoritative**

```bash
# 1. 对 zone 进行 DNSSEC 签名（自动生成 KSK + ZSK）
pdnsutil secure-zone zjygsj.com

# 2. 整理 zone（计算 NSEC/NSEC3 链）
pdnsutil rectify-zone zjygsj.com

# 3. 查看 zone 状态
pdnsutil show-zone zjygsj.com

# 4. 导出 DS 记录
pdnsutil export-zone-ds zjygsj.com
# 输出: zjygsj.com. IN DS 12345 13 2 a1b2c3...
```

**BIND**

```bash
# 1. 生成 KSK
dnssec-keygen -f KSK -a ECDSAP256SHA256 -n ZONE zjygsj.com

# 2. 生成 ZSK
dnssec-keygen -a ECDSAP256SHA256 -n ZONE zjygsj.com

# 3. 将公钥 include 进 zone 文件
#   $INCLUDE Kzjygsj.com.+013+12345.key   ; KSK
#   $INCLUDE Kzjygsj.com.+013+54321.key   ; ZSK

# 4. 签名
rndc sign zjygsj.com

# 5. 导出 DS 记录
dnssec-dsfromkey -2 Kzjygsj.com.+013+12345.key
```

**Knot DNS**

```bash
keymgr zjygsj.com generate algorithm=ECDSAP256SHA256 size=256 ksk=yes
keymgr zjygsj.com generate algorithm=ECDSAP256SHA256 size=256
# 在 knot.conf 中 zone 段添加: dnssec-signing: on
keymgr zjygsj.com ds
```

### 7.4 第二步：解读 DS 记录格式

```
zjygsj.com. IN DS 12345 13 2 a1b2c3...
                  │     │  │  └── Digest（哈希值）
                  │     │  └── DigestType: 1=SHA-1, 2=SHA-256, 4=SHA-384
                  │     └── Algorithm: 8=RSASHA256, 13=ECDSAP256, 15=Ed25519
                  └── KeyTag（密钥标识号）
```

在 `dsrecords` 中只需四个字段用空格分隔：

```yaml
dsrecords:
  - '12345 13 2 a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2'
```

### 7.5 第三步：在 Recursor 配置中添加 Trust Anchor

```yaml
dnssec:
  validation: validate
  trustanchors:
    - name: 'zjygsj.com'
      dsrecords:
        - '12345 13 2 a1b2c3...'
  trustanchorfile: '/usr/share/dns/root.key'
```

> 重要：添加 Trust Anchor 后，Recursor 不再检查父域的 DS 记录，直接信任你配置的 DS。需自行确保 DS 记录的正确性。

### 7.6 第四步：重载并验证

```bash
rec_control reload-yaml

# 测试 DNSSEC 验证
dig +dnssec A www.zjygsj.com @127.0.0.1
# 期望 flags 中有 ad 标志

# 深度诊断
delv +vtrace www.zjygsj.com @127.0.0.1

# 验证 DS 一致性
dig DS zjygsj.com @10.20.1.8

# 监控日志
journalctl -u pdns-recursor | grep -i "dnssec\|bogus\|zjygsj.com"
```

### 7.7 特殊情况处理

**私有权威未签名（需要 NTA）**

```yaml
dnssec:
  negative_trustanchors:
    - name: 'zjygsj.com'
      reason: '私有权威服务器未配置 DNSSEC 签名'
```

```bash
# 或运行时动态添加
rec_control add-nta zjygsj.com '私有权威未签名'
rec_control clear-nta zjygsj.com     # 签名配置完成后移除
```

> 安全警告：NTA 关闭了 DNSSEC 验证，添加后该域名不再受 DNSSEC 保护。应仅在确认根因后临时使用。

**forward_zones + DNSSEC 行为**

当 `forward_zones` 配置了私有域时，Recursor 以 RD=0 模式查询私有权威，`validation: validate` 仍然生效。私有权威返回的记录必须有有效 RRSIG 签名。若未签名，解决方案：

1. 权威端签名 + 递归端添加 Trust Anchor（推荐）
2. 添加 NTA 跳过验证
3. 降级 `dnssec.validation` 为 `process`（不推荐）

**多子域混合场景**

```yaml
dnssec:
  trustanchors:
    - name: 'zjygsj.com'              # 父域已签名
      dsrecords:
        - '12345 13 2 a1b2c3...'
  negative_trustanchors:
    - name: 'legacy.zjygsj.com'       # 子域未签名
      reason: '遗留系统未配置 DNSSEC'

recursor:
  forward_zones:
    - zone: 'zjygsj.com'
      forwarders:
        - '10.20.1.8:53'
```

### 7.8 KSK 轮换

当私有域 KSK 需要轮换时，必须遵循双签名流程：

```
T0: 添加新KSK（zone中同时有两个 DNSKEY 257，TA中仅有旧DS）
T1: 新DS加入TA（TA中同时有新旧DS）
T2: 等待TTL过期（至少1个最大TTL，通常1~7天）
T3: 移除旧KSK+DS（TA中仅保留新DS）
```

操作步骤：

```bash
# 权威端：添加新 KSK
pdnsutil add-zone-key zjygsj.com ksk active ecdsa256

# 查看新旧 DS 记录
pdnsutil export-zone-ds zjygsj.com

# Recursor 端：同时配置新旧 DS
# trustanchors:
#   - name: 'zjygsj.com'
#     dsrecords:
#       - '12345 13 2 a1b2c3...'   # 旧 DS（保留一段时间）
#       - '67890 13 2 f9e8d7...'   # 新 DS（刚添加）
rec_control reload-yaml

# 等待缓存过期后移除旧 KSK 和旧 DS
pdnsutil deactivate-zone-key zjygsj.com 12345
pdnsutil remove-zone-key zjygsj.com 12345
```

> 轮换期间切勿过早移除旧 DS：部分缓存可能仍引用旧签名，会导致 Bogus 并返回 SERVFAIL。

### 7.9 故障排查

**`dig +dnssec` 无 `ad` 标志**：Trust Anchor 未配置或 DS 不匹配。执行 `rec_control get-tas`。

**查询返回 SERVFAIL**：DNSSEC 验证失败。执行 `grep -i bogus /var/log/syslog`。

**DS 记录不一致**：权威端签名后未更新 Recursor。执行 `dig DS zjygsj.com @10.20.1.8`。

**签名过期**：执行 `pdnsutil check-zone zjygsj.com`。

**时间不同步**：执行 `timedatectl status`。

**算法不兼容**：执行 `update-crypto-policies --show`（RHEL 9+）。

调试命令速查：

```bash
rec_control get-tas                        # 查看 Trust Anchors
rec_control get-ntas                       # 查看 NTA
delv +vtrace www.zjygsj.com @127.0.0.1    # 追踪验证链
dig DS zjygsj.com @10.20.1.8 +short       # 查询权威 DS
dig DNSKEY zjygsj.com @10.20.1.8          # 查询权威 DNSKEY
journalctl -u pdns-recursor --since '5m' | grep -i 'dnssec\|bogus'
```

## 七、为私有域配置 DNSSEC（完整操作指南）
