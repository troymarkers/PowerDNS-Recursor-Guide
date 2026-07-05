#!/bin/sh
#=============================================================================
# HaGeZi DNS Blocklists — RPZ 自动更新脚本 (仅下载，不配置 rpzs)
# 部署路径: /etc/powerdns/rpz/update-hagezi-rpz.sh
#=============================================================================
# 使用前请确保已在 06-recursor.yml 中配置好对应的 rpzs: 条目！
# 本脚本仅负责下载 RPZ 文件，不会自动修改 Recursor 配置。
#
# 用法:
#   update-hagezi-rpz.sh [1|2|3]        以指定等级运行（默认 1=Pro）
#   update-hagezi-rpz.sh --list          列出可选等级
#   update-hagezi-rpz.sh --dry-run [N]   模拟运行，不覆盖文件（dry-run）
#   update-hagezi-rpz.sh --help          显示帮助
#
# Multi 三选一:
#   1 = Pro       广告/跟踪/恶意软件/弹窗 (~230K 条目, ~55MB)
#   2 = Pro++     增强恶意软件/钓鱼 (~249K 条目, ~60MB)
#   3 = Ultimate  激进全面防护 (~268K 条目, ~65MB)
#
# 以下列表始终下载（不随等级变化）:
#   TIF (威胁情报) / Fake (虚假网店) / Pop-Up Ads (弹窗广告)
#   SafeSearch (强制安全搜索) / Abused TLDs (高风险顶级域)
#   Badware Hoster (恶意托管商) / DoH Bypass (DNS 绕过防护)
#   Dynamic DNS / URL Shortener / Anti Piracy
#   Gambling / Social Networks / NSFW
#=============================================================================
set -eu

# ═══════════════════════════════════════════════════════════════════════════
echo "  -------------------------------------------------"
echo "  使用前请确认已在 06-recursor.yml 配置好 rpzs 条目"
echo "  本脚本仅下载文件，下载后执行:"
echo "  sudo systemctl restart pdns-recursor"
echo "  -------------------------------------------------"
HAGEZI_TIER=${HAGEZI_TIER:-1}
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
RPZ_DIR=${HAGEZI_RPZ_DIR:-$SCRIPT_DIR}
CDN=${HAGEZI_CDN:-https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/rpz}
DRY_RUN=false

# ── 帮助 / 列表 ───────────────────────────────────────────────────────────
show_help() { sed -n '4,27p' "$0" | sed 's/^# //'; exit 0; }
show_list() {
    echo "等级  Multi       条目数  内存    补充列表（始终下载）"
    echo "────  ──────────  ──────  ──────  ──────────────────────────────────────────"
    echo "  1   Pro   ★     ~230K  ~55MB   TIF / Fake / Pop-Up / SafeSearch / TLDs"
    echo "  2   Pro++       ~249K  ~60MB   Hoster / DoH / Dyndns / URLShortener"
    echo "  3   Ultimate    ~268K  ~65MB   AntiPiracy / Gambling / Social / NSFW"
    echo ""
    echo "  共计 14 个文件（1 个 Multi + 13 个补充列表）"
    echo "配套 06-recursor.yml rpzs: 配置参考 hagezi-dns-blocklists-guide.md"
    exit 0
}

# ── 参数解析 ──────────────────────────────────────────────────────────────
for arg in "$@"; do
    case "$arg" in
        --help|-h) show_help ;;
        --list|-l) show_list ;;
        --dry-run|--dty-run|-n) DRY_RUN=true ;;
        ''|*[!0-9]*) echo "用法: $0 [1|2|3] [--list|--dry-run]"; exit 1 ;;
        *) HAGEZI_TIER=$arg ;;
    esac
done

# ── Multi 三选一 ──────────────────────────────────────────────────────────
case "$HAGEZI_TIER" in
    1) MULT=pro.txt ;;
    2) MULT=pro.plus.txt ;;
    3) MULT=ultimate.txt ;;
    *) echo "三选一: 1=Pro  2=Pro++  3=Ultimate"; exit 1 ;;
esac

# ── 补充列表（始终下载，不随等级变化）───────────────────────────────────
EXTRA='tif.txt
fake.txt
popupads.txt
nosafesearch.txt
spam-tlds-rpz.txt
hoster.txt
doh.txt
dyndns.txt
urlshortener.txt
anti.piracy.txt
gambling.txt
social.txt
nsfw.txt'

# 文件名映射（CDN URL → 本地文件名）
local_name() {
    case "$1" in
        spam-tlds-rpz.txt) echo 'hagezi-tlds.txt' ;;
        anti.piracy.txt) echo 'hagezi-anti.txt' ;;
        *) echo "hagezi-${1%.txt}.txt" ;;
    esac
}

# ── 工具函数 ──────────────────────────────────────────────────────────────
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
ok() { log "[OK] $*"; }
warn() { log "[WARN] $*"; }
fail() { log "[FAIL] $*"; }
cleanup() { rm -rf "${TEMP_DIR:-}"; }
trap cleanup EXIT

# ── 主流程 ────────────────────────────────────────────────────────────────
TOTAL_FILES=14
TIER_NAME=''
case "$HAGEZI_TIER" in
    1) TIER_NAME='Pro' ;;
    2) TIER_NAME='Pro++' ;;
    3) TIER_NAME='Ultimate' ;;
esac

log "HaGeZi RPZ — Tier ${HAGEZI_TIER} (${TIER_NAME}) — ${TOTAL_FILES} 个文件"
[ "$DRY_RUN" = true ] && log "(模拟模式 — 不会覆盖文件)"

TEMP_DIR=$(mktemp -d -t hagezi-rpz.XXXXXX)
mkdir -p "$RPZ_DIR"
SUCCESS=0
FAILED=0

# 生成列表文件，避免在 POSIX sh 中使用数组
LIST_FILE="$TEMP_DIR/files.list"
{
    printf '%s\n' "$MULT"
    printf '%s\n' "$EXTRA"
} | sed '/^$/d' > "$LIST_FILE"

while IFS= read -r url_file; do
    [ -n "$url_file" ] || continue
    local_file=$(local_name "$url_file")
    temp="$TEMP_DIR/$local_file"
    target="$RPZ_DIR/$local_file"

    printf '  %-40s → %-30s ' "$url_file" "$local_file"

    RETRY=0
    while [ "$RETRY" -lt 3 ]; do
        if curl -sSfL --connect-timeout 30 --max-time 120 -o "$temp" "$CDN/$url_file" 2>/dev/null; then
            break
        fi
        RETRY=$((RETRY + 1))
        [ "$RETRY" -lt 3 ] && sleep $((5 * RETRY))
done

    if [ "$RETRY" -ge 3 ]; then
        fail "下载失败"
        FAILED=$((FAILED + 1))
        continue
    fi
    if ! grep -q 'SOA' "$temp" 2>/dev/null; then
        fail "无效"
        FAILED=$((FAILED + 1))
        continue
    fi

    if [ -f "$target" ] && diff -q "$temp" "$target" >/dev/null 2>&1; then
        ok "无变化"
        SUCCESS=$((SUCCESS + 1))
    elif [ "$DRY_RUN" = true ]; then
        ok "将更新 $(wc -l < "$temp") 行 [DRY-RUN]"
        SUCCESS=$((SUCCESS + 1))
    else
        mv "$temp" "$target"
        ok "已更新 $(wc -l < "$target") 行"
        SUCCESS=$((SUCCESS + 1))
    fi
done < "$LIST_FILE"

log "结果: ${SUCCESS}/$(wc -l < "$LIST_FILE" | tr -d ' ') 成功, ${FAILED} 失败"

# ── 白名单 ────────────────────────────────────────────────────────────────
WHITELIST="$RPZ_DIR/whitelist.txt"
if [ ! -s "$WHITELIST" ]; then
    log "创建 whitelist.txt"
    cat > "$WHITELIST" << 'EOF'
$TTL 3600
@ SOA localhost. root.localhost. 1 14400 3600 86400 3600
  NS  localhost.

; 白名单规则 — 匹配到的域名跳过所有 RPZ 拦截
; 格式: 域名 CNAME rpz-passthru.
;
; 示例（取消注释以启用）:
; example.com           CNAME rpz-passthru.
; *.example.com         CNAME rpz-passthru.
; analytics.google.com  CNAME rpz-passthru.
EOF
    ok "whitelist.txt 已创建"
fi

# ── 提示 ───────────────────────────────────────────────────────────────────
echo ""
echo "  -------------------------------------------------"
echo "  下载完成！确认 rpzs 配置后执行:"
echo "  sudo systemctl restart pdns-recursor"
echo "  -------------------------------------------------"
echo ""
