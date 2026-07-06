# PowerDNS Recursor — 配置模板与部署说明

> 适用版本: PowerDNS Recursor 5.2+
> 目标用途: 为生产环境提供一套可直接部署的 Recursor 配置模板

这个仓库提供了一套按模块拆分的 PowerDNS Recursor 配置模板，适合用于企业内网递归 DNS、纯转发模式、DNSSEC 校验和 RPZ 阻断规则集成。

当前仓库使用 [recursor.yml](recursor.yml) 作为主入口，并通过 [recursor.d/](recursor.d/) 目录拆分成多个主题配置文件；与旧的 recursor-enterprise 命名不同，本文档统一按当前仓库结构说明。

## 1. 仓库内容

```text
recursor.yml                  # 入口配置，仅负责 include_dir 分发
recursor.d/                   # 拆分后的 YAML 配置目录
  01-incoming.yml             # 入站监听与访问控制
  02-outgoing.yml             # 出站连接与超时策略
  03-dnssec.yml               # DNSSEC 验证与信任锚
  04-ecs.yml                  # ECS / CDN 就近调度
  05-cache.yml                # 缓存相关参数
  06-recursor.yml             # 递归行为、转发与 RPZ
  07-nod.yml                  # NOD / UDR 相关配置
  08-logging.yml              # 日志设置
  09-webservice.yml           # Web API / REST 接口
rpz/                          # RPZ 规则与更新脚本
  update-hagezi-rpz.sh        # 自动下载 HaGeZi RPZ 规则
  whitelist.txt               # 白名单模板
hagezi-dns-blocklists-guide.md             # 提供 HaGeZi RPZ 规则下载、部署与更新建议
powerdns-recursor-settings-reference.md    # YAML 配置参数索引，适合查找各项设置项与默认值
powerdns-recursor-dnssec.md                # 介绍 DNSSEC 验证模式、bogus 处理和推荐配置
powerdns-recursor-dns64.md                 # 说明 DNS64/NAT64 的工作原理与适用场景
powerdns-recursor-lua-scripting.md         # 介绍 Lua Hook 编程能力，用于自定义解析策略
powerdns-recursor-metrics.md               # 汇总内置指标、接口和监控方式
powerdns-recursor-nod-udr.md               # 介绍 NOD / UDR 的安全检测能力
powerdns-recursor-performance-guide.md     # 面向性能调优和资源规划的实战指南
powerdns-recursor-manpages.md              # 收录 pdns_recursor 和 rec_control 的手册页参考
```

## 2. 快速开始

### 2.1 先修改关键配置

部署前，至少确认以下项已按实际环境调整：

- incoming.listen：绑定正确的监听地址
- incoming.allow_from：限制允许查询的客户端网段
- webservice.api_key：设置 REST API 访问密钥
- recursor.threads：按 CPU 核心数调整
- forward_zones 或 forward_zones_recurse：配置内部域转发或上游转发

### 2.2 部署到系统目录

```bash
sudo mkdir -p /etc/powerdns/recursor.d
sudo cp recursor.yml /etc/powerdns/recursor.yml
sudo cp recursor.d/*.yml /etc/powerdns/recursor.d/
sudo chown pdns:pdns /etc/powerdns/recursor.yml
sudo chown -R pdns:pdns /etc/powerdns/recursor.d
sudo chmod 640 /etc/powerdns/recursor.yml
```

### 2.3 检查并启动服务

```bash
sudo pdns_recursor --config=check
sudo systemctl restart pdns-recursor
sudo systemctl status pdns-recursor
```

### 2.4 验证运行状态

```bash
sudo journalctl -u pdns-recursor --no-pager | tail -50
sudo rec_control get-all
```

## 3. 常见使用场景

### 场景 A：企业内网递归 DNS

适合内部客户端访问公司内网资源，内部域名转发给内部权威服务器。

```yaml
incoming:
  listen:
    - '10.0.0.53'
  allow_from:
    - '10.0.0.0/8'
    - '172.16.0.0/12'
    - '192.168.0.0/16'

outgoing:
  source_address:
    - '10.0.0.53'

dnssec:
  validation: validate
  log_bogus: true

recursor:
  threads: 4
  forward_zones:
    - zone: 'corp.local'
      forwarders:
        - '10.0.0.10'
        - '10.0.0.11'
```

### 场景 B：纯转发模式

适合所有请求直接交给上游递归服务，不在本机做递归逻辑。

```yaml
outgoing:
  source_address:
    - '10.0.0.53'

dnssec:
  validation: process

recursor:
  threads: 2
  hint_file: 'no'
  forward_zones_recurse:
    - zone: '.'
      forwarders:
        - '8.8.8.8'
        - '8.8.4.4'
```

## 4. RPZ / HaGeZi 阻断规则集成

如果你希望启用 DNS 层面的广告、跟踪、恶意域名拦截，可以参考 [hagezi-dns-blocklists-guide.md](hagezi-dns-blocklists-guide.md) 和 [rpz/update-hagezi-rpz.sh](rpz/update-hagezi-rpz.sh)
