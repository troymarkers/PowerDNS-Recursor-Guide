# PowerDNS Recursor 配置参数参考

> 来源: https://doc.powerdns.com/recursor/yamlsettings.html
> 版本: 基于 PowerDNS Recursor 5.2+ (YAML 格式)
>
> **说明**: 自 Recursor 5.0 起推荐使用 YAML 格式。5.2 起默认识别 YAML。
> 旧式 key=value 格式将在未来版本移除。本文档以 YAML 章节组织参数。

---

## 一、incoming — 入站连接

控制 Recursor 如何接收客户端 DNS 查询。

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `incoming.listen` | SocketAddress[] | `[127.0.0.1, ::1]` | 监听地址列表，可指定端口 |
| `incoming.port` | Integer | 53 | 未指定端口时的默认端口 |
| `incoming.allow_from` | Subnet[] | RFC1918+回环 | 客户端 ACL，仅这些来源可使用递归 |
| `incoming.allow_from_file` | String | - | 从 YAML 文件加载 ACL（覆盖 allow_from） |
| `incoming.allow_no_rd` | Boolean | false | 是否允许 RD=0（非递归）查询返回缓存 |
| `incoming.allow_notify_for` | String[] | [] | 允许 NOTIFY 清除缓存的域名列表 |
| `incoming.allow_notify_from` | Subnet[] | [] | 允许发送 NOTIFY 的来源 IP |
| `incoming.max_tcp_clients` | Integer | 1024 | 最大并发 TCP 客户端连接（≥5.2） |
| `incoming.max_tcp_per_client` | Integer | 0 | 每客户端最大并发 TCP 连接，0=无限 |
| `incoming.max_tcp_queries_per_connection` | Integer | 0 | 单 TCP 连接最大查询数，0=无限 |
| `incoming.max_concurrent_requests_per_tcp_connection` | Integer | 10 | 单 TCP 连接并发请求数 |
| `incoming.max_udp_queries_per_round` | Integer | 10000 | 每轮 recvmsg 循环最大 UDP 处理数 |
| `incoming.udp_truncation_threshold` | Integer | 1232 | UDP 响应截断阈值 |
| `incoming.tcp_timeout` | Integer | 2 | TCP 客户端数据等待超时（秒） |
| `incoming.tcp_fast_open` | Integer | 0 | TCP Fast Open 队列大小，0=禁用 |
| `incoming.reuseport` | Boolean | true(≥4.9) | SO_REUSEPORT 多核优化 |
| `incoming.pdns_distributes_queries` | Boolean | false(≥4.9) | 独立分发线程模式 |
| `incoming.distributor_threads` | Integer | 1/0 | 分发线程数 |
| `incoming.distribution_load_factor` | Double | 0.0 | 分发负载均衡因子 |
| `incoming.distribution_pipe_buffer_size` | Integer | 0 | 分发管道缓冲大小 |
| `incoming.non_local_bind` | Boolean | false | 允许绑定非本地 IP |
| `incoming.edns_padding_from` | Subnet[] | [] | EDNS 填充来源 |
| `incoming.edns_padding_mode` | String | padded-queries-only | EDNS 填充模式: always/padded-queries-only |
| `incoming.edns_padding_tag` | Integer | 7830 | 填充响应的包缓存标签 |
| `incoming.gettag_needs_edns_options` | Boolean | false | 向 gettag() hook 传递 EDNS 选项 |
| `incoming.proxy_protocol_from` | Subnet[] | [] | Proxy Protocol 来源 IP（通过代理时） |
| `incoming.proxy_protocol_maximum_size` | Integer | 512 | Proxy Protocol 负载最大字节 |
| `incoming.proxy_protocol_exceptions` | SocketAddress[] | [] | Proxy Protocol 例外地址 |
| `incoming.proxymappings` | ProxyMapping[] | [] | 代理映射规则（≥5.1） |
| `incoming.use_incoming_edns_subnet` | Boolean | false | 传递客户端 ECS 到上游 |

---

## 二、outgoing — 出站连接

控制 Recursor 向权威 DNS 服务器发起查询的行为。

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `outgoing.source_address` | String[] | `[0.0.0.0]` | 出站查询源地址（多个增加防欺骗） |
| `outgoing.dont_query` | Subnet[] | 私有/保留地址 | 不查询的 IP 范围 |
| `outgoing.network_timeout` | Integer | 1500 | 网络超时（毫秒） |
| `outgoing.max_qperq` | Integer | 50(≥5.1) | 单次解析最大出站查询数 |
| `outgoing.max_ns_per_resolve` | Integer | 13 | 每次解析最大 NS 抽样数 |
| `outgoing.max_ns_address_qperq` | Integer | 10 | NS 地址解析最大查询数 |
| `outgoing.max_bytesperq` | Integer | 100000 | 单次解析最大接收字节数 |
| `outgoing.edns_bufsize` | Integer | 1232 | 出站 EDNS 缓冲区大小 |
| `outgoing.edns_padding` | Boolean | true | 出站 DoT 查询 EDNS 填充 |
| `outgoing.edns_subnet_allow_list` | String[] | [] | ECS 发送白名单（目的 IP/域名） |
| `outgoing.edns_subnet_harden` | Boolean | false | ECS 严格校验 |
| `outgoing.server_down_max_fails` | Integer | 64 | 标记 down 前最大失败次数 |
| `outgoing.server_down_throttle_time` | Integer | 60 | 标记 down 后限流时间（秒） |
| `outgoing.bypass_server_throttling_probability` | Integer | 25 | 绕过低速限流的概率 1/n |
| `outgoing.non_resolving_ns_max_fails` | Integer | 5 | NS 名解析失败限流阈值 |
| `outgoing.non_resolving_ns_throttle_time` | Integer | 60 | NS 名解析失败限流时间（秒） |
| `outgoing.dont_throttle_names` | String[] | [] | 不限流的服务器名（后缀匹配） |
| `outgoing.dont_throttle_netmasks` | Subnet[] | [] | 不限流的 IP 段 |
| `outgoing.cookies` | Boolean | false(≥5.4) | 发送 DNS Cookies |
| `outgoing.cookies_unsupported` | SocketAddress[] | [] | 不支持 Cookies 的服务器 |
| `outgoing.any_to_tcp` | Boolean | true(≥5.4) | 出站 ANY 查询走 TCP |
| `outgoing.single_socket` | Boolean | false | 使用单一出站 socket |
| `outgoing.lowercase` | Boolean | false | 出站查询转小写 |
| `outgoing.spoof_nearmiss_max` | Integer | 1 | DNS 欺骗检测阈值 |
| `outgoing.tcp_fast_open_connect` | Boolean | false | 出站 TCP Fast Open |
| `outgoing.tcp_max_idle_ms` | Integer | 10000 | 出站 TCP/DoT 空闲超时（毫秒） |
| `outgoing.tcp_max_idle_per_auth` | Integer | 10 | 每服务器最大空闲连接 |
| `outgoing.tcp_max_idle_per_thread` | Integer | 100 | 每线程最大空闲连接 |
| `outgoing.tcp_max_queries` | Integer | 0 | 每连接最大查询数，0=无限 |
| `outgoing.udp_source_port_min` | Integer | 1024 | UDP 源端口下限 |
| `outgoing.udp_source_port_max` | Integer | 65535 | UDP 源端口上限 |
| `outgoing.udp_source_port_avoid` | String[] | `[4791,11211]` | 避免的 UDP 端口 |
| `outgoing.dot_to_auth_names` | String[] | [] | 强制 DoT 的权威服务器名 |
| `outgoing.dot_to_port_853` | Boolean | true | 端口 853 转发目标使用 DoT |
| `outgoing.max_busy_dot_probes` | Integer | 0 | 最大并发 DoT 探测（实验性） |
| `outgoing.tls_configurations` | TLSConfig[] | [] | 出站 DoT TLS 配置（≥5.4） |

---

## 三、dnssec — DNSSEC 验证

递归解析器的 DNSSEC 验证比权威更重要——它保护客户端到解析器之间的"最后一公里"。

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `dnssec.validation` | String | process | 验证模式: off / process-no-validate / process / log-fail / validate |
| `dnssec.trustanchors` | TrustAnchor[] | 内置根 KSK | 信任锚点（DS 记录）序列 |
| `dnssec.negative_trustanchors` | NegTrustAnchor[] | [] | 否定信任锚点（临时禁用某 zone 验证） |
| `dnssec.trustanchorfile` | String | - | 从 zone 文件加载信任锚点 |
| `dnssec.trustanchorfile_interval` | Integer | 24 | 信任锚点文件重新加载间隔（小时） |
| `dnssec.nsec3_max_iterations` | Integer | 50(≥5.0) | NSEC3 最大允许迭代次数 |
| `dnssec.aggressive_nsec_cache_size` | Integer | 100000 | RFC 8198 激进 NSEC 缓存大小，0=禁用 |
| `dnssec.aggressive_cache_min_nsec3_hit_ratio` | Integer | 2000 | 激进 NSEC3 缓存命中率 1/n 下限 |
| `dnssec.aggressive_cache_max_nsec3_hash_cost` | Integer | 150 | 激进 NSEC3 缓存最大哈希开销 |
| `dnssec.signature_inception_skew` | Integer | 60 | 签名生效时间偏差容忍（秒） |
| `dnssec.max_signature_validations_per_query` | Integer | 30 | 每查询最大签名验证次数 |
| `dnssec.max_rrsigs_per_record` | Integer | 2 | 每条记录最大 RRSIG 检查数 |
| `dnssec.max_dnskeys` | Integer | 2 | 同算法同 tag 最大 DNSKEY 数 |
| `dnssec.max_ds_per_zone` | Integer | 8 | 每 zone 最大 DS 记录数 |
| `dnssec.max_nsec3_hash_computations_per_query` | Integer | 600 | 每查询最大 NSEC3 哈希计算 |
| `dnssec.max_nsec3s_per_record` | Integer | 10 | 每条记录最大 NSEC3 数 |
| `dnssec.disabled_algorithms` | String[] | [] | 禁用的 DNSSEC 算法编号 |
| `dnssec.log_bogus` | Boolean | false | 记录 Bogus 验证失败 |
| `dnssec.x_dnssec_names` | String[] | [] | 独立统计的 DNSSEC 域名列表 |

---

## 四、ecs — EDNS Client Subnet

允许递归解析器传递客户端子网信息以获取地理就近的解析结果。

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `ecs.ipv4_bits` | Integer | 24 | IPv4 ECS 子网位数 |
| `ecs.ipv6_bits` | Integer | 56 | IPv6 ECS 子网位数 |
| `ecs.ipv4_cache_bits` | Integer | 24 | 允许缓存的 IPv4 ECS Scope 上限 |
| `ecs.ipv6_cache_bits` | Integer | 56 | 允许缓存的 IPv6 ECS Scope 上限 |
| `ecs.cache_limit_ttl` | Integer | 0 | ECS 缓存最小 TTL 条件 |
| `ecs.ipv4_never_cache` | Boolean | false | 永不缓存 IPv4 ECS 答案 |
| `ecs.ipv6_never_cache` | Boolean | false | 永不缓存 IPv6 ECS 答案 |
| `ecs.add_for` | Subnet[] | 公网地址 | 哪些客户端使用真实 IP 作 ECS |
| `ecs.scope_zero_address` | String | - | ECS Scope=0 时的源地址 |
| `ecs.minimum_ttl_override` | Integer | 1 | ECS 应答最小 TTL 提升 |

---

## 五、packetcache — 包缓存

缓存完整的 DNS 响应包，命中时零延迟返回。

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `packetcache.disable` | Boolean | false | 禁用包缓存 |
| `packetcache.max_entries` | Integer | 500000 | 最大条目数（≥4.9 全院共享） |
| `packetcache.max_entry_size` | Integer | 8192 | 单包最大缓存字节，0=无限 |
| `packetcache.shards` | Integer | 1024 | 分片数（减少锁竞争） |
| `packetcache.ttl` | Integer | 86400(≥4.9) | 最大缓存 TTL（秒） |
| `packetcache.negative_ttl` | Integer | 60 | 否定应答缓存 TTL |
| `packetcache.servfail_ttl` | Integer | 60 | 解析失败缓存 TTL |

---

## 六、recordcache — 记录缓存

缓存独立的 DNS 记录集，可跨不同查询复用。

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `recordcache.max_entries` | Integer | 1000000 | 最大条目数（≥4.4 全院共享） |
| `recordcache.max_entry_size` | Integer | 8192 | 单条最大字节，0=无限 |
| `recordcache.max_ttl` | Integer | 86400 | 最大缓存 TTL |
| `recordcache.max_negative_ttl` | Integer | 3600 | 否定缓存最大 TTL |
| `recordcache.max_cache_bogus_ttl` | Integer | 3600 | Bogus 缓存最大 TTL |
| `recordcache.shards` | Integer | 1024 | 分片数 |
| `recordcache.max_rrset_size` | Integer | 256 | 最大 RRSet 大小 |
| `recordcache.limit_qtype_any` | Boolean | true | 限制 ANY 查询缓存 |
| `recordcache.locked_ttl_perc` | Integer | 0 | 缓存更新锁定（% TTL 内不替换） |
| `recordcache.refresh_on_ttl_perc` | Integer | 0 | 记录预刷新（% TTL 剩余时后台更新） |
| `recordcache.serve_stale_extensions` | Integer | 0 | 过期记录继续服务次数（+30s/次） |
| `recordcache.zonetocaches` | ZoneToCache[] | [] | Zone to Cache 预加载（≥5.1） |

---

## 七、recursor — 核心行为

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `recursor.threads` | Integer | 2 | 工作线程数 |
| `recursor.tcp_threads` | Integer | 1(≥5.0) | TCP 处理线程数 |
| `recursor.max_mthreads` | Integer | 2048 | 每 worker 最大并发 MTasker 线程 |
| `recursor.max_recursion_depth` | Integer | 16(≥4.9) | 最大递归深度，0=无限 |
| `recursor.max_cnames_followed` | Integer | 10(≥5.1) | 最大 CNAME 链长度 |
| `recursor.max_chain_length` | Integer | 0(≥5.1) | 最大请求链长度，0=无限制 |
| `recursor.max_total_msec` | Integer | 7000 | 单查询最大总耗时（毫秒） |
| `recursor.stack_size` | Integer | 200000 | mthread 栈大小（字节） |
| `recursor.stack_cache_size` | Integer | 100(≥4.9) | mthread 栈缓存数 |
| `recursor.minimum_ttl_override` | Integer | 1 | 最小 TTL 强制提升 |
| `recursor.qname_minimization` | Boolean | true | QName 最小化（RFC 9156） |
| `recursor.qname_max_minimize_count` | Integer | 10(≥5.0) | 最小化最大迭代次数 |
| `recursor.qname_minimize_one_label` | Integer | 4(≥5.0) | 单标签最小化迭代次数 |
| `recursor.nothing_below_nxdomain` | String | dnssec | RFC 8020 处理: no/dnssec/yes |
| `recursor.root_nx_trust` | Boolean | true | 信任根的 NXDOMAIN |
| `recursor.save_parent_ns_set` | Boolean | true | 保存父级 NS 集合 |
| `recursor.extended_resolution_errors` | Boolean | true(≥5.0) | 扩展错误（RFC 8914） |
| `recursor.any_to_tcp` | Boolean | true(≥5.4) | 入站 ANY 截断到 TCP |
| `recursor.serve_rfc1918` | Boolean | true | RFC 1918 反向区域权威应答 |
| `recursor.serve_rfc6303` | Boolean | true(≥5.1.3) | RFC 6303 区域权威应答 |
| `recursor.dns64_prefix` | String | - | DNS64 /96 前缀（RFC 6147） |
| `recursor.hint_file` | String | - | 根提示文件; 'no'=禁用; 'no-refresh'=禁用+不刷新 |
| `recursor.forward_zones` | ForwardZone[] | [] | 权威转发（RD=0） |
| `recursor.forward_zones_recurse` | ForwardZone[] | [] | 递归转发（RD=1） |
| `recursor.forward_zones_file` | String | - | 从 YAML 文件加载转发规则 |
| `recursor.forwarding_catalog_zones` | CatZone[] | [] | 转发 Catalog Zone（≥5.2） |
| `recursor.auth_zones` | AuthZone[] | [] | 本地权威 Zone（BIND 格式） |
| `recursor.rpzs` | RPZ[] | [] | 响应策略区域（DNS 防火墙） |
| `recursor.sortlists` | SortList[] | [] | 地址排序列表（≥5.1） |
| `recursor.allowed_additional_qtypes` | AddQType[] | [] | 允许附加解析的 QType |
| `recursor.server_id` | String | 主机名 | NSID/id.server 响应值，'disabled'=禁用 |
| `recursor.version_string` | String | 真实版本 | version.bind 响应值 |
| `recursor.security_poll_suffix` | String | secpoll.powerdns.com. | 安全更新查询域名 |
| `recursor.config_dir` | String | 编译决定 | 配置目录 |
| `recursor.config_name` | String | - | 虚拟实例名称 |
| `recursor.include_dir` | String | - | 额外 YAML 配置目录 |
| `recursor.ignore_unknown_settings` | String[] | [] | 忽略的未知设置名 |
| `recursor.cpu_map` | String | - | CPU 亲和性绑定 |
| `recursor.setuid` | String | - | 运行用户 |
| `recursor.setgid` | String | - | 运行组 |
| `recursor.daemon` | Boolean | false | 后台守护模式 |
| `recursor.write_pid` | Boolean | true | 写 PID 文件 |
| `recursor.socket_dir` | String | 编译决定 | 控制套接字/PID 目录 |
| `recursor.socket_owner` | String | - | 套接字所有者 |
| `recursor.socket_group` | String | - | 套接字组 |
| `recursor.socket_mode` | String | - | 套接字权限（八进制） |
| `recursor.chroot` | String | - | chroot 目录 |
| `recursor.lua_config_file` | String | - | Lua 配置文件（旧式，不推荐与 YAML 混用） |
| `recursor.lua_dns_script` | String | - | Lua DNS 脚本 |
| `recursor.lua_global_include_dir` | String | - | Lua 全局 include 目录 |
| `recursor.lua_maintenance_interval` | Integer | 1 | Lua maintenance() 调用间隔（秒） |
| `recursor.lua_start_stop_script` | String | - | 启动/停止 Lua 脚本（≥5.2） |
| `recursor.export_etc_hosts` | Boolean | false | 导出 /etc/hosts |
| `recursor.etc_hosts_file` | String | /etc/hosts | hosts 文件路径 |
| `recursor.export_etc_hosts_search_suffix` | String | - | hosts 条目搜索后缀 |
| `recursor.public_suffix_list_file` | String | - | 公共后缀列表文件 |
| `recursor.stats_ringbuffer_entries` | Integer | 10000 | top-remotes 环缓冲条目 |
| `recursor.latency_statistic_size` | Integer | 10000 | 延迟统计采样数 |
| `recursor.allow_trust_anchor_query` | Boolean | false | 允许查询信任锚点 |
| `recursor.event_trace_enabled` | Integer | 0 | 事件跟踪: 1=PB 2=日志 4=OTel |
| `recursor.system_resolver_ttl` | Integer | 0(≥5.1) | 系统解析器 TTL, >0 时转发目标可用主机名 |
| `recursor.system_resolver_interval` | Integer | 0(≥5.1) | 系统解析器检查间隔（秒） |
| `recursor.system_resolver_self_resolve_check` | Boolean | true(≥5.1) | 自解析检测警告 |
| `recursor.max_generate_steps` | Integer | 0 | $GENERATE 指令最大步数 |
| `recursor.max_include_depth` | Integer | 20 | $INCLUDE 嵌套深度 |
| `recursor.stats_api_disabled_list` | String[] | 部分大指标 | API 统计禁用列表 |
| `recursor.stats_carbon_disabled_list` | String[] | 部分大指标 | Carbon 统计禁用列表 |
| `recursor.stats_rec_control_disabled_list` | String[] | 部分大指标 | rec_control 统计禁用列表 |
| `recursor.stats_snmp_disabled_list` | String[] | 部分大指标 | SNMP 统计禁用列表 |

---

## 八、nod — 新域名检测 (NOD) 和独特响应 (UDR)

基于布隆过滤器的安全监控功能。

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `nod.tracking` | Boolean | false | 启用新域名（NOD）追踪 |
| `nod.db_size` | Integer | 67108864 | NOD 布隆过滤器大小（bit） |
| `nod.history_dir` | String | 编译决定 | NOD 持久化目录 |
| `nod.db_snapshot_interval` | Integer | 600(≥5.1) | 快照间隔（秒），0=禁用 |
| `nod.log` | Boolean | true | 记录新域名 |
| `nod.lookup` | String | - | 新域名报告 DNS 查询后缀 |
| `nod.pb_tag` | String | pdns-nod | Protobuf 中新域名标签 |
| `nod.ignore_list` | String[] | [] | NOD 忽略列表 |
| `nod.ignore_list_file` | String | - | NOD 忽略列表文件 |
| `nod.unique_response_tracking` | Boolean | false | 启用独特响应（UDR）追踪 |
| `nod.unique_response_db_size` | Integer | 67108864 | UDR 布隆过滤器大小 |
| `nod.unique_response_history_dir` | String | 编译决定 | UDR 持久化目录 |
| `nod.unique_response_log` | Boolean | true | 记录独特响应 |
| `nod.unique_response_pb_tag` | String | pdns-udr | Protobuf 中 UDR 标签 |
| `nod.unique_response_ignore_list` | String[] | [] | UDR 忽略列表 |
| `nod.unique_response_ignore_list_file` | String | - | UDR 忽略列表文件 |

---

## 九、logging — 日志

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `logging.loglevel` | Integer | 6 | 日志等级 0~7（syslog 标准） |
| `logging.quiet` | Boolean | true | 不记录查询日志 |
| `logging.disable_syslog` | Boolean | false | 禁用 syslog（systemd 管理时推荐） |
| `logging.facility` | String | - | syslog facility（数字） |
| `logging.timestamp` | Boolean | true | 日志带时间戳 |
| `logging.common_errors` | Boolean | false | 记录常见无关紧要的 DNS 错误 |
| `logging.trace` | String | no | 详细追踪: no/yes/fail |
| `logging.rpz_changes` | Boolean | false | 记录 RPZ 增删变更 |
| `logging.statistics_interval` | Integer | 1800 | 统计摘要间隔（秒），0=禁用 |
| `logging.structured_logging` | Boolean | true(≥5.1) | 结构化日志输出 |
| `logging.structured_logging_backend` | String | default | 结构化后端: default/systemd-journal/json |
| `logging.protobuf_servers` | ProtobufServer[] | [] | Protobuf 日志服务器（客户端查询） |
| `logging.outgoing_protobuf_servers` | ProtobufServer[] | [] | Protobuf 日志服务器（出站查询） |
| `logging.protobuf_mask_v4` | Integer | 32 | IPv4 匿名化掩码 |
| `logging.protobuf_mask_v6` | Integer | 128 | IPv6 匿名化掩码 |
| `logging.protobuf_use_kernel_timestamp` | Boolean | false | 使用内核时间戳计算延迟 |
| `logging.dnstap_framestream_servers` | DNSTap[] | [] | dnstap FrameStream 服务器 |
| `logging.dnstap_nod_framestream_servers` | DNSTapNOD[] | [] | NOD dnstap FrameStream 服务器 |
| `logging.opentelemetry_trace_conditions` | OTelCond[] | [] | OpenTelemetry 追踪条件（≥5.4） |

---

## 十、webservice — Web 服务/API

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `webservice.webserver` | Boolean | false | 启动 Web 服务器 |
| `webservice.address` | String | 127.0.0.1 | 监听地址（listen 未设时） |
| `webservice.port` | Integer | 8082 | 监听端口（listen 未设时） |
| `webservice.listen` | IncomingWSConfig[] | [] | 高级监听配置（TLS 支持，≥5.3） |
| `webservice.allow_from` | Subnet[] | `[127.0.0.1, ::1]` | Web 访问 ACL |
| `webservice.api_key` | String | - | API 预共享密钥（支持哈希） |
| `webservice.password` | String | - | Web Basic Auth 密码 |
| `webservice.api_dir` | String | - | API 配置/zone 存储目录 |
| `webservice.loglevel` | String | normal | Web 日志: none/normal/detailed |
| `webservice.hash_plaintext_credentials` | Boolean | false | 启动时哈希明文凭据 |
| `webservice.max_request_size` | Integer | 2(≥5.5) | 最大请求大小 (MB) |
| `webservice.cross_origin_request_header` | String | - | CORS 头值（≥5.5） |

---

## 十一、监控

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `carbon.server` | SocketAddress[] | [] | Carbon 服务器地址 |
| `carbon.interval` | Integer | 30 | Carbon 上报间隔（秒） |
| `carbon.ns` | String | pdns | Carbon 命名空间 |
| `carbon.ourname` | String | 主机名 | Carbon 主机名 |
| `carbon.instance` | String | recursor | Carbon 实例名 |
| `snmp.agent` | Boolean | false | 注册为 SNMP Agent |
| `snmp.daemon_socket` | String | - | SNMP 守护进程 socket 路径 |

---

## YAML 配置结构参考

```yaml
incoming:        # 入站连接
outgoing:        # 出站连接
dnssec:          # DNSSEC 验证
ecs:             # EDNS Client Subnet
packetcache:     # 包缓存
recordcache:     # 记录缓存
recursor:        # 核心递归行为（含转发、RPZ、auth_zones）
nod:             # 新域名/独特响应检测
logging:         # 日志
webservice:      # Web API
carbon:          # Graphite 监控上报
snmp:            # SNMP
```

---

## 统计

| 分类 | 参数数 |
|------|--------|
| incoming | ~32 |
| outgoing | ~33 |
| dnssec | ~19 |
| ecs | ~10 |
| packetcache | 7 |
| recordcache | 12 |
| recursor | ~55 |
| nod | ~16 |
| logging | ~18 |
| webservice | ~12 |
| carbon/snmp | 6 |
| **总计** | **~220** |
