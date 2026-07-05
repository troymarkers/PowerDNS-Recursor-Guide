# PowerDNS Recursor 手册页参考

> 来源: https://doc.powerdns.com/recursor/manpages/index.html
> 生成日期: 2026-07-03

---

## 目录

- [pdns_recursor(1)](#pdns_recursor1) — 递归 DNS 服务器
- [rec_control(1)](#rec_control1) — 递归服务器控制工具

---

# pdns_recursor(1)

## 概述

**pdns_recursor** — 高性能、简单且安全的递归 DNS 服务器。

```
pdns_recursor [OPTION]…
```

## 描述

`pdns_recursor` 是一个高性能的递归域名服务器，为全球数亿互联网连接提供服务。

Recursor 通过配置文件进行配置，但配置文件中的每个配置项都可以在命令行上覆盖。

本手册列出了运行 PowerDNS Recursor 所需的核心功能选项。完整的最新详细信息请访问 [https://doc.powerdns.com/](https://doc.powerdns.com/)。

## 示例

### 基本监听配置

监听 `192.0.2.53`，允许 `192.0.2.0/24` 子网进行递归查询，并以守护进程方式运行：

```bash
# pdns_recursor --local-address=192.0.2.53 --allow-from=192.0.2.0/24 --daemon
```

### 停止 Recursor

```bash
# rec_control quit-nicely
```

> **推荐**: 使用 `systemctl(1)` 或 init.d 脚本启动和停止 recursor。

## 选项

> 完整的权威选项列表请查阅在线文档：<https://doc.powerdns.com/>

| 选项 | 说明 |
|------|------|
| `--allow-from=<networks>` | 仅允许指定网络（逗号分隔，带掩码）进行递归查询。示例: `192.0.2.0/24,203.0.113.128/25` |
| `--auth-zones=<authzones>` | 权威 Zone 配置，格式: `<zonename>=<filename>`。示例: `ds9a.nl=/var/zones/ds9a.nl,powerdns.com=/var/zones/powerdns.com` |
| `--chroot=<directory>` | 将进程 chroot 到指定目录 |
| `--client-tcp-timeout=<num>` | TCP 客户端超时时间（秒） |
| `--config` | 显示当前配置。自 4.8.0 起支持可选值：`--config=default`（显示默认配置）、`--config=diff`（显示已修改项）、`--config=check`（检查配置错误） |
| `--config-dir=<directory>` | 配置文件目录（recursor.conf）。默认取决于构建时的 SYSCONFDIR，通常为 `/etc/powerdns`。可通过 `pdns_recursor --config \| grep 'config-dir='` 查看默认值 |
| `--daemon` | 以守护进程方式运行 |
| `--export-etc-hosts` | 导出 `/etc/hosts` 中的主机名和 IP 地址 |
| `--forward-zones=<forwardzones>` | 转发 Zone 配置，格式: `<zonename>=<address>`。address 必须为 IP 地址（非主机名）。示例: `ds9a.nl=213.244.168.210,powerdns.com=127.0.0.1` |
| `--forward-zones-file=<filename>` | 同 `--forward-zones`，但从文件读取。每行一个 Zone，格式: `ds9a.nl=213.244.168.210` |
| `--help` | 显示选项摘要 |
| `--hint-file=<filename>` | 从指定文件加载根提示 |
| `--local-address=<address>` | 监听的 IP 地址，以空格或逗号分隔。可包含端口号；不含端口号的地址将使用 `--local-port` |
| `--local-port=<port>` | 监听端口 |
| `--log-common-errors` | 是否记录常见错误 |
| `--max-cache-entries=<num>` | 主缓存的最大条目数 |
| `--max-negative-ttl=<num>` | 负面缓存条目的最大保留秒数 |
| `--max-tcp-clients=<num>` | 最大并发 TCP 客户端数 |
| `--max-tcp-per-client=<num>` | 每个客户端（IP 地址）的最大 TCP 会话数 |
| `--query-local-address=<address[,address…]>` | 发送查询时使用的源 IP 地址 |
| `--quiet` | 禁止记录查询和应答日志 |
| `--server-id=<text>` | 查询 `id.server` TXT 记录时返回的文本，默认为主机名 |
| `--serve-rfc1918` | （默认启用）使服务器权威感知 `10.in-addr.arpa`、`168.192.in-addr.arpa` 和 `16-31.172.in-addr.arpa` 等 RFC 1918 反向区域，减轻 AS112 服务器负载。这些区域的部分数据仍可被加载或转发 |
| `--setgid=<gid>` | 切换组 ID 以增强安全性 |
| `--setuid=<uid>` | 切换用户 ID 以增强安全性 |
| `--single-socket` | 仅使用单个 socket 进行外发查询 |
| `--socket-dir=<directory>` | 控制 socket 所在目录 |
| `--spoof-nearmiss-max=<num>` | 非零时，在接近命中次数达到此值后假定为欺骗攻击 |
| `--trace` | 输出大量日志 |
| `--version-string=<text>` | 查询 `version.pdns` 或 `version.bind` 时返回的文本 |

## 参见

- `rec_control(1)`
- `systemctl(1)`
- [https://docs.powerdns.com/recursor](https://docs.powerdns.com/recursor)

---

# rec_control(1)

## 概述

**rec_control** — 查询和控制运行中的 PowerDNS Recursor 实例。

```
rec_control [OPTION]… COMMAND [COMMAND-OPTION]…
```

## 描述

`rec_control` 允许管理员查询和控制正在运行的 PowerDNS Recursor 实例。

`rec_control` 通过 "controlsocket" 与 Recursor 通信，该 socket 通常位于 `/var/run`。使用 `--socket-dir` 或 `--config-dir` 和 `--config-name` 开关控制 `rec_control` 连接到哪个进程。

## 示例

### 检查 Recursor 是否存活

```bash
# rec_control ping
```

### 停止 Recursor

```bash
# rec_control quit
```

### 将缓存转储到磁盘

```bash
# rec_control dump-cache /tmp/the-cache
```

> **注意**: 4.5.0 之前，对于每个写入文件的命令，pdns_recursor 会自行打开文件。从 4.5.0 开始，文件由 rec_control 命令本身使用运行 rec_control 的用户的凭证和当前工作目录打开。单个减号 `-` 可用作文件名，将数据写入标准输出流。

## 选项

| 选项 | 说明 |
|------|------|
| `--help` | 显示帮助信息 |
| `--config-dir=<path>` | recursor.conf 所在目录 |
| `--config-name=<name>` | 虚拟配置名称 |
| `--socket-dir=<path>` | 控制 socket 所在位置，建议使用 `--config-dir` |
| `--socket-pid=<pid>` | SMP 模式下，要控制的 pdns_recursor 进程 PID |
| `--timeout=<num>` | 等待远程 PowerDNS Recursor 响应的秒数 |
| `--version` | 显示本程序的版本号。注意：`version` 命令显示的是正在运行的 recursor 的版本 |

## 命令

### 诊断与监控

| 命令 | 说明 |
|------|------|
| `ping` | 检查服务器是否存活 |
| `version` | 报告运行中 Recursor 的版本 |
| `current-queries` | 显示当前活跃的查询 |
| `get STATISTIC [STATISTIC]…` | 获取指定统计项。可查询项参见 [Metrics 文档](https://docs.powerdns.com/recursor/metrics.html) |
| `get-all` | 获取所有已知统计信息 |
| `get-qtypelist` | 获取 QType 统计信息。注意：来自缓存的查询暂不计数 |
| `get-remotelogger-stats` | 获取远程日志统计信息，按类型和地址分组 |
| `top-queries` | 显示 Top-20 查询（基于最近 `stats-ringbuffer-entries` 次查询） |
| `top-pub-queries` | 按公共后缀列表分组的 Top-20 查询 |
| `top-largeanswer-remotes` | 造成大响应的 Top-20 远程主机 |
| `top-remotes` | Top-20 最活跃远程主机 |
| `top-servfail-queries` | 导致 SERVFAIL 响应的 Top-20 查询 |
| `top-bogus-queries` | 导致 Bogus 响应的 Top-20 查询 |
| `top-pub-servfail-queries` | 按公共后缀列表分组的 SERVFAIL Top-20 查询 |
| `top-pub-bogus-queries` | 按公共后缀列表分组的 Bogus Top-20 查询 |
| `top-servfail-remotes` | 导致 SERVFAIL 响应的 Top-20 远程主机 |
| `top-bogus-remotes` | 导致 Bogus 响应的 Top-20 远程主机 |
| `top-timeouts` | Top-20 超时下游目标 |
| `get-proxymapping-stats` | 获取代理映射子网及相关计数器 |

### 缓存管理

| 命令 | 说明 |
|------|------|
| `wipe-cache DOMAIN [DOMAIN] […]` | 清除指定域名（精确名称匹配）的缓存条目。适用于服务器 IP 变更但 TTL 尚未过期的情况。DOMAIN 可后缀 `$` 来删除整棵缓存树。**注意**: 此命令也会清除负面缓存。**警告**: 不要只清除 `www.somedomain.com`，其 NS 记录或 CNAME 目标可能仍不需要，应同时清除 `somedomain.com` |
| `wipe-cache-typed qtype DOMAIN [DOMAIN] […]` | 同 wipe-cache，但仅清除指定 `qtype` 类型的记录 |
| `dump-cache FILENAME [TYPE…]` | 将缓存转储到 FILENAME。文件不应事先存在。转储期间 Recursor 可能不响应查询。TYPE 可选: `r`（记录缓存）、`n`（负面缓存）、`p`（数据包缓存）、`a`（NSEC 激进缓存）。不指定则全部转储 |
| `dump-cookies FILENAME` | 转储 Cookie 存储 |
| `dump-dot-probe-map FILENAME` | 转储 DoT 探测映射内容 |
| `dump-edns FILENAME` | 转储 EDNS 状态 |
| `dump-failedservers FILENAME` | 转储失败服务器映射内容 |
| `dump-non-resolving FILENAME` | 转储无法解析到地址的域名服务器名称映射 |
| `dump-nsspeeds FILENAME` | 转储域名服务器速度统计。统计按线程保存，转储到同一文件 |
| `dump-rpz ZONE_NAME FILENAME` | 转储 RPZ Zone 内容（ZONE_NAME 命名规则参见 [RPZ 文档](https://docs.powerdns.com/recursor/lua-config/rpz.html#policyname)） |
| `dump-saved-parent-ns-sets FILENAME` | 转储已成功用于解析的父级 NS 集合映射条目 |
| `dump-throttlemap FILENAME` | 转储节流映射内容 |

### 运行时配置调整

| 命令 | 说明 |
|------|------|
| `set-carbon-server CARBON_SERVER [CARBON_OURNAME]` | 设置 carbon-server 和可选的 carbon-ourname |
| `set-dnssec-log-bogus SETTING` | 设置 DNSSEC 验证失败日志开关。`on`/`yes` 开启，`no`/`off` 关闭 |
| `set-ecs-minimum-ttl NUM` | 设置 ecs-minimum-ttl-override |
| `set-max-aggr-nsec-cache-size NUM` | 修改 NSEC 激进缓存的最大条目数（若配置中设为 0 禁用，则无法通过此命令设置） |
| `set-max-cache-entries NUM` | 修改 DNS 缓存最大条目数。减少后缓存将在正常清理过程中逐渐缩减 |
| `set-max-packetcache-entries NUM` | 修改数据包缓存最大条目数。减少后将在正常清理过程中逐渐缩减 |
| `set-minimum-ttl NUM` | 设置 minimum-ttl-override |
| `set-event-trace-enabled NUM` | 设置事件跟踪日志：`0`=禁用, `1`=protobuf, `2`=日志文件, `3`=protobuf+日志文件 |

### 配置查询

| 命令 | 说明 |
|------|------|
| `get-parameter [KEY]…` | 获取配置参数。自 5.4.0 起使用 YAML 配置时，KEY 格式为 `section[.name]`，不提供 KEY 则完整转储 |
| `get-default-parameter [KEY]…` | 获取配置参数的默认值。YAML 配置下 KEY 格式同上 |
| `show-yaml [FILE]` | 显示旧式配置的 YAML 表示形式 |

### DNSSEC / 信任锚

| 命令 | 说明 |
|------|------|
| `add-nta DOMAIN [REASON]` | 为 DOMAIN 添加 Negative Trust Anchor，可选附带 REASON |
| `clear-nta DOMAIN…` | 移除一个或多个 DOMAIN 的 Negative Trust Anchor。设为 `*` 可清除所有 NTA |
| `get-ntas` | 获取当前配置的 Negative Trust Anchor 列表 |
| `add-ta DOMAIN DSRECORD` | 为 DOMAIN 添加 Trust Anchor 及 DS 记录数据。新 TA 添加到现有 TA 集合中 |
| `clear-ta [DOMAIN]…` | 移除一个或多个 DOMAIN 的 Trust Anchor。注意：无法移除根 Trust Anchor |
| `get-tas` | 获取当前配置的 Trust Anchor 列表 |
| `list-dnssec-algos` | 列出支持（及可能已禁用）的 DNSSEC 算法 |

### Cookie / 限速

| 命令 | 说明 |
|------|------|
| `add-cookies-unsupported IP [IP…]` | 将不支持 Cookie 的服务器 IP 添加到 Cookie 表（可指定 `IP:port`，默认端口 53）。标记为 `Unsupported`，不会被修剪 |
| `clear-cookies [IP…]` | 从 Cookie 表移除条目。IP 为 `*` 时移除全部 |
| `add-dont-throttle-names NAME [NAME…]` | 添加不禁用限速的名称服务器域名 |
| `clear-dont-throttle-names NAME [NAME…]` | 移除不限速名称。NAME 为 `*` 时移除全部 |
| `get-dont-throttle-names` | 获取不限速名称列表 |
| `add-dont-throttle-netmasks NETMASK [NETMASK…]` | 添加不禁用限速的名称服务器网段 |
| `clear-dont-throttle-netmasks NETMASK [NETMASK…]` | 移除不限速网段。NETMASK 为 `*` 时移除全部 |
| `get-dont-throttle-netmasks` | 获取不限速网段列表 |

### 脚本与 Zone 重载

| 命令 | 说明 |
|------|------|
| `reload-acls` | 重新加载 ACL |
| `reload-lua-script [FILENAME]` | （重新）加载 Lua 脚本。FILENAME 为空则尝试重新加载当前脚本，替换当前加载的脚本 |
| `reload-lua-config [FILENAME]` | （重新）加载 Lua 配置。FILENAME 为空则尝试重新加载当前文件。注意：文件将被完全执行，运行时修改的未在此文件中修改的设置仍然有效。重载效果并非立即生效。使用 YAML 设置时此命令重新加载 YAML 设置的运行时可变部分 |
| `reload-yaml` | 重新加载 YAML 设置的运行时可变部分 |
| `reload-zones` | 重新加载权威和转发 Zone。出错时保留当前配置 |
| `unload-lua-script` | 卸载已加载的 Lua 脚本 |

### 调试

| 命令 | 说明 |
|------|------|
| `trace-regex REGEX FILE` | 为匹配的查询发出解析跟踪。无参数时禁用跟踪。4.9.0 之前无 FILE 参数，跟踪始终写入日志。4.9.0 起跟踪写入指定文件，`-` 表示 stdout。正则表达式匹配带末尾点的域名查询。例如 `'powerdns.com$'` 不会匹配 `'www.powerdns.com'`，因为实际匹配的是 `'www.powerdns.com.'`。多匹配可使用 `\|` 运算符 |

### 其他

| 命令 | 说明 |
|------|------|
| `help` | 显示运行中的 pdns_recursor 支持的命令列表 |
| `hash-password [WORK-FACTOR]` | 提示输入密码后返回哈希加盐版本，用于 webserver 密码或 API key。此命令不联系 recursor，在 rec_control 内部完成哈希。可选 scrypt 工作因子（2 的幂），默认 1024 |
| `quit` | 请求关闭 recursor，退出进程让操作系统清理资源 |
| `quit-nicely` | 请求优雅关闭 recursor。允许所有线程完成当前工作并释放资源后再退出。**推荐的停止方式** |

## 参见

- `pdns_recursor(1)`
- [https://docs.powerdns.com/recursor](https://docs.powerdns.com/recursor)
