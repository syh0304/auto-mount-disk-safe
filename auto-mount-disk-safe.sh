#!/bin/bash
# ===================================================================
# 🛠️  自动挂载磁盘脚本 - 安全完全体之最终版 auto-mount-disk-safe.sh v5.0
# 📅  2025-09-02
# 💡  支持 dry-run、force、依赖检查、重复挂载清理、fstab 备份
# 🚀  一行命令，永久解决挂载混乱问题
# ===================================================================

# 日志函数
log_info()  { echo -e "\e[36m[INFO]\e[0m $*"; }
log_warn()  { echo -e "\e[33m[WARN]\e[0m $*"; }
log_error() { echo -e "\e[31m[ERROR]\e[0m $*"; }
log_success() { echo -e "\e[32m[SUCCESS]\e[0m $*"; }

VERSION_INFO="自动挂载磁盘脚本 - 安全完全体之最终版 v5.0"
log_info "📦 $VERSION_INFO"

VERSION="v5.0 - 安全完全体之最终版"
SCRIPT_NAME=$(basename "$0")

usage() {
    cat << EOF
📦 ${SCRIPT_NAME} - 自动挂载磁盘脚本 $VERSION

📌 用法:
    $SCRIPT_NAME [选项]

🔧 选项:
    dry-run         模拟执行，不修改系统
    --force         强制继续，即使已正确挂载
    --help          显示此帮助信息

✅ 示例:
    $SCRIPT_NAME                    # 正常执行
    $SCRIPT_NAME dry-run            # 模拟执行
    $SCRIPT_NAME dry-run --force    # 模拟并强制继续

EOF
}

# 参数解析
DRY_RUN=false
FORCE_CONTINUE=false

for arg in "$@"; do
    case $arg in
        "dry-run"|"--dry-run") DRY_RUN=true ;;
        "--force"|"--continue") FORCE_CONTINUE=true ;;
        "--help"|"-h") usage; exit 0 ;;
        *) log_warn "未知参数: $arg"; usage; exit 1 ;;
    esac
done

# 检查必要命令
log_info "🔍 正在检查依赖..."
check_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        log_error "❌ 缺少必要命令: $1"
        log_info "📌 请先安装 $2 包（例如：apt install $2）"
        exit 1
    fi
}

check_command "findmnt" "util-linux"
check_command "blkid" "util-linux"
check_command "sed" "sed"
check_command "tee" "coreutils"
log_info "✅ 所有依赖检查通过"

if [ "$DRY_RUN" = true ]; then
    log_warn "[DRY-RUN 模式] 不会执行任何修改操作，仅模拟输出"
    [ "$FORCE_CONTINUE" = true ] && log_info "📌 强制继续模式：即使已正确挂载，也会模拟后续流程"
fi

# ================ 函数定义 ================
# 根据模式选择执行命令或模拟
if [ "$DRY_RUN" = true ]; then
    run_cmd() {
        echo "[DRY-RUN] $*"
    }
    safe_exit() {
        if [ "$1" -eq 0 ] && [ "$FORCE_CONTINUE" != true ]; then
            log_success "$DEVICE 已正确挂载到 $NEW_MOUNT"
            log_info "💡 dry-run 模式：检测到已正确挂载，模拟退出（使用 --force 可继续模拟）"
            exit 0
        else
            log_info "[DRY-RUN] 本应退出，继续模拟..."
            # 继续执行后续流程
        fi
    }
else
    run_cmd() {
        "$@"
    }
    safe_exit() {
        exit "$1"
    }
fi

# ================ 配置参数 ================
DEVICE="/dev/sda"
NEW_MOUNT="/mnt/workspace"
FS_TYPE="ext4"
MOUNT_OPTIONS="rw,noatime,discard,defaults"

# ================== 主逻辑开始 ==================
log_info "🔧 开始处理磁盘挂载: $DEVICE → $NEW_MOUNT"
[ "$DRY_RUN" = true ] && log_warn "运行模式: dry-run"

# 检查是否已挂载到目标路径（最可靠方式）
if findmnt -n "$NEW_MOUNT" >/dev/null 2>&1 && \
   [ "$(findmnt -n -o SOURCE "$NEW_MOUNT" 2>/dev/null)" = "$DEVICE" ]; then
    log_success "$DEVICE 已正确挂载到 $NEW_MOUNT"
    df -h "$NEW_MOUNT"
    safe_exit 0
fi

# 获取所有挂载点
ALL_MOUNTS=($(findmnt -n -o TARGET "$DEVICE" 2>/dev/null))

# 如果被多次挂载，清理非目标挂载点
if [ ${#ALL_MOUNTS[@]} -gt 1 ]; then
    log_warn "检测到 $DEVICE 被挂载了 ${#ALL_MOUNTS[@]} 次，正在清理非目标挂载点"
    for mount_point in "${ALL_MOUNTS[@]}"; do
        if [ "$mount_point" = "$NEW_MOUNT" ]; then
            log_info "保留目标挂载点: $mount_point"
        else
            log_info "模拟卸载非目标挂载点: $mount_point"
            run_cmd umount "$mount_point" && log_success "已卸载 $mount_point"
        fi
    done
fi

# 此时再次判断是否已挂载到目标（清理后）
if findmnt -n "$NEW_MOUNT" >/dev/null 2>&1 && \
   [ "$(findmnt -n -o SOURCE "$NEW_MOUNT" 2>/dev/null)" = "$DEVICE" ]; then
    log_success "$DEVICE 已正确挂载到 $NEW_MOUNT"
    df -h "$NEW_MOUNT"
    safe_exit 0
fi

# 否则继续迁移流程
CURRENT_MOUNT=$(findmnt -n -o TARGET "$DEVICE" 2>/dev/null | head -n1 || echo "")
if [ -n "$CURRENT_MOUNT" ]; then
    log_warn "检测到 $DEVICE 当前挂载在 $CURRENT_MOUNT，将迁移到 $NEW_MOUNT"
else
    log_info "$DEVICE 当前未挂载"
fi


# 卸载旧挂载点（如果需要）
if [ -n "$CURRENT_MOUNT" ] && [ "$CURRENT_MOUNT" != "$NEW_MOUNT" ]; then
    log_info "正在卸载 $CURRENT_MOUNT..."
    if run_cmd umount "$CURRENT_MOUNT"; then
        log_success "已卸载 $CURRENT_MOUNT"
    else
        log_warn "普通卸载失败，尝试强制懒卸载..."
        run_cmd umount -l "$CURRENT_MOUNT" || {
            log_error "强制卸载失败，请检查进程占用"
            safe_exit 1
        }
        log_success "已强制卸载 $CURRENT_MOUNT"
    fi
fi

# 等待设备完全释放
log_info "等待 $DEVICE 挂载点完全释放..."
MAX_WAIT=10
for i in $(seq 1 $MAX_WAIT); do
    if ! findmnt -n "$DEVICE" >/dev/null 2>&1; then
        log_info "✅ $DEVICE 已完全卸载，耗时 $i 秒"
        break
    fi
    sleep 1
    if [ $i -eq $MAX_WAIT ]; then
        log_error "❌ 超时：$DEVICE 仍未完全卸载，请检查进程占用（lsof $DEVICE）"
        safe_exit 1
    fi
done

# 创建挂载目录
log_info "正在创建挂载目录：$NEW_MOUNT"
run_cmd mkdir -p "$NEW_MOUNT"
log_success "已创建挂载目录：$NEW_MOUNT"

# 获取设备 UUID
UUID=$(blkid -s UUID -o value "$DEVICE")
if [ -z "$UUID" ]; then
    log_error "无法获取 $DEVICE 的 UUID，请检查设备是否存在"
    safe_exit 1
fi
log_info "设备 UUID: $UUID"

# 备份 fstab
log_info "正在备份 /etc/fstab"
run_cmd cp /etc/fstab "/etc/fstab.$(date +%Y%m%d-%H%M%S).bak"
log_success "已备份 /etc/fstab 到 /etc/fstab.$(date +%Y%m%d-%H%M%S).bak"

# 清理 fstab 中旧条目
log_info "正在清理 /etc/fstab 中旧条目"
run_cmd sed -i "\|$DEVICE|d" /etc/fstab
run_cmd sed -i "\|$NEW_MOUNT|d" /etc/fstab
log_info "已清理 /etc/fstab 中旧条目"

# 添加新挂载条目
FSTAB_ENTRY="UUID=$UUID $NEW_MOUNT $FS_TYPE $MOUNT_OPTIONS 0 0"
log_info "正在添加新挂载条目到 /etc/fstab"
echo "$FSTAB_ENTRY" | run_cmd tee -a /etc/fstab > /dev/null
log_success "已添加新挂载条目到 /etc/fstab：$FSTAB_ENTRY"

# 挂载
log_info "正在挂载 $NEW_MOUNT"
if run_cmd mount "$NEW_MOUNT"; then
    log_success "挂载成功！"
else
    log_error "挂载失败，请检查 fstab 或设备状态"
    safe_exit 1
fi

# 验证挂载
if findmnt -n "$NEW_MOUNT" >/dev/null; then
    log_success "挂载验证通过 ✅"
else
    log_error "挂载验证失败"
    safe_exit 1
fi

# 读写测试
log_info "正在进行读写测试"
if run_cmd touch "$NEW_MOUNT/.test_write"; then
    run_cmd rm -f "$NEW_MOUNT/.test_write"
    log_success "读写测试通过 ✅"
else
    log_error "读写测试失败，请检查权限或磁盘状态"
    safe_exit 1
fi

# 最终成功
log_success "🎉 磁盘挂载迁移完成！"
log_info "📌 数据盘已永久挂载在: $NEW_MOUNT"
log_info "📥 示例：aria2c -d '$NEW_MOUNT' '链接'"

# 正常退出
safe_exit 0