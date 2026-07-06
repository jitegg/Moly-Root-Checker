#!/system/bin/sh

# ============================================
# 环境检测脚本 v1.0
# 检测项目：模块、TEE、Bootloader、Xposed、
#          Zygisk、SU挂载、SELinux
# ============================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color
BLUE='\033[0;34m'

# 结果统计
PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

# 打印分隔线
print_separator() {
    echo -e "${BLUE}========================================${NC}"
}

# 打印标题
print_title() {
    echo -e "${BLUE}=== 环境检测报告 ===${NC}"
    echo "检测时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "设备信息: $(getprop ro.product.model 2>/dev/null || echo 'Unknown')"
    print_separator
}

# 检测项结果输出
print_result() {
    local item=$1
    local status=$2
    local detail=$3
    
    case $status in
        "PASS")
            echo -e "[${GREEN}✓${NC}] $item: ${GREEN}正常${NC}"
            if [ -n "$detail" ]; then
                echo -e "    ${GREEN}→ $detail${NC}"
            fi
            PASS_COUNT=$((PASS_COUNT + 1))
            ;;
        "WARN")
            echo -e "[${YELLOW}!${NC}] $item: ${YELLOW}有痕迹${NC}"
            if [ -n "$detail" ]; then
                echo -e "    ${YELLOW}→ $detail${NC}"
            fi
            WARN_COUNT=$((WARN_COUNT + 1))
            ;;
        "FAIL")
            echo -e "[${RED}✗${NC}] $item: ${RED}确定修改${NC}"
            if [ -n "$detail" ]; then
                echo -e "    ${RED}→ $detail${NC}"
            fi
            FAIL_COUNT=$((FAIL_COUNT + 1))
            ;;
    esac
}

# ============================================
# 1. 模块检测 - Tricky Store
# ============================================
check_tricky_store() {
    echo -e "\n${BLUE}[1] 模块检测 - Tricky Store${NC}"
    
    if [ -d "/data/adb/tricky_store" ]; then
        print_result "Tricky Store模块" "WARN" "检测到Tricky Store模块存在"
        # 检查关键文件
        if [ -f "/data/adb/tricky_store/keybox.xml" ]; then
            echo -e "    ${YELLOW}→ 发现 keybox.xml 文件${NC}"
        fi
        if [ -f "/data/adb/tricky_store/spoof_build_vars" ]; then
            echo -e "    ${YELLOW}→ 发现 spoof_build_vars 文件${NC}"
        fi
    else
        print_result "Tricky Store模块" "PASS" "未检测到Tricky Store模块"
    fi
}

# ============================================
# 2. TEE检测
# ============================================
check_tee() {
    echo -e "\n${BLUE}[2] TEE状态检测${NC}"
    
    # 检查TEE相关属性
    TEE_SUPPORT=$(getprop ro.boot.tee 2>/dev/null)
    TEE_TYPE=$(getprop ro.tee.type 2>/dev/null)
    TEE_VERSION=$(getprop ro.tee.version 2>/dev/null)
    
    if [ -n "$TEE_SUPPORT" ] && [ "$TEE_SUPPORT" = "enabled" ]; then
        print_result "TEE支持" "PASS" "TEE已启用"
    elif [ -n "$TEE_SUPPORT" ]; then
        print_result "TEE支持" "WARN" "TEE状态: $TEE_SUPPORT"
    else
        print_result "TEE支持" "WARN" "无法获取TEE状态"
    fi
    
    # 检查TEE相关文件
    if [ -f "/dev/tee" ] || [ -f "/dev/teepriv" ]; then
        print_result "TEE设备" "PASS" "TEE设备文件存在"
    else
        print_result "TEE设备" "WARN" "未找到TEE设备文件"
    fi
    
    # 检查TEE服务
    TEE_SERVICE=$(ps -A 2>/dev/null | grep -E "tee|tz_|qseecom" | head -1)
    if [ -n "$TEE_SERVICE" ]; then
        echo -e "    ${GREEN}→ TEE服务运行中${NC}"
    fi
}

# ============================================
# 3. Bootloader检测
# ============================================
check_bootloader() {
    echo -e "\n${BLUE}[3] Bootloader状态检测${NC}"
    
    # 读取build.prop关键属性
    BOOTLOADER=$(getprop ro.bootloader 2>/dev/null)
    BUILD_DATE=$(getprop ro.build.date 2>/dev/null)
    BUILD_TYPE=$(getprop ro.build.type 2>/dev/null)
    BUILD_TAGS=$(getprop ro.build.tags 2>/dev/null)
    FLASH_LOCKED=$(getprop ro.boot.flash.locked 2>/dev/null)
    VERIFIED_BOOTSTATE=$(getprop ro.boot.verifiedbootstate 2>/dev/null)
    
    # 检测Bootloader是否解锁
    if [ -n "$FLASH_LOCKED" ] && [ "$FLASH_LOCKED" = "0" ]; then
        print_result "Bootloader锁定" "FAIL" "Bootloader已解锁 (FLASH_LOCKED=0)"
    elif [ -n "$FLASH_LOCKED" ] && [ "$FLASH_LOCKED" = "1" ]; then
        print_result "Bootloader锁定" "PASS" "Bootloader已锁定"
    else
        # 检查verifiedbootstate
        if [ -n "$VERIFIED_BOOTSTATE" ] && [ "$VERIFIED_BOOTSTATE" != "green" ]; then
            print_result "Bootloader锁定" "WARN" "验证启动状态: $VERIFIED_BOOTSTATE"
        else
            print_result "Bootloader锁定" "WARN" "无法确定Bootloader状态"
        fi
    fi
    
    # 检查Build类型
    if [ -n "$BUILD_TYPE" ] && [ "$BUILD_TYPE" = "user" ]; then
        echo -e "    ${GREEN}→ Build类型: $BUILD_TYPE${NC}"
    elif [ -n "$BUILD_TYPE" ]; then
        echo -e "    ${YELLOW}→ Build类型: $BUILD_TYPE (非用户版本)${NC}"
    fi
    
    # 显示Bootloader版本
    if [ -n "$BOOTLOADER" ]; then
        echo -e "    → Bootloader版本: $BOOTLOADER"
    fi
}

# ============================================
# 4. Xposed检测
# ============================================
check_xposed() {
    echo -e "\n${BLUE}[4] Xposed框架检测${NC}"
    
    XP_FOUND=0
    
    # 检测1: 检查Xposed相关文件
    XP_PATHS="/data/data/de.robv.android.xposed.installer \
              /data/data/io.github.xposed.installer \
              /data/data/com.topjohnwu.magisk/modules/xposed \
              /data/adb/modules/xposed \
              /data/adb/modules/zygisk_lsposed \
              /data/adb/modules/riru_edxposed"
    
    for path in $XP_PATHS; do
        if [ -d "$path" ]; then
            print_result "Xposed框架" "FAIL" "检测到Xposed/LSPosed安装路径: $(basename $path)"
            XP_FOUND=1
            break
        fi
    done
    
    # 检测2: 检查进程
    XP_PROCESS=$(ps -A 2>/dev/null | grep -E "xposed|lsposed|edxposed" | head -1)
    if [ -n "$XP_PROCESS" ] && [ $XP_FOUND -eq 0 ]; then
        print_result "Xposed框架" "FAIL" "检测到Xposed相关进程"
        XP_FOUND=1
    fi
    
    # 检测3: 检查属性
    XP_PROPS=$(getprop | grep -i xposed 2>/dev/null)
    if [ -n "$XP_PROPS" ] && [ $XP_FOUND -eq 0 ]; then
        print_result "Xposed框架" "FAIL" "检测到Xposed系统属性"
        XP_FOUND=1
    fi
    
    # 检测4: 检查库文件
    if [ $XP_FOUND -eq 0 ]; then
        XP_LIBS=$(find /system /vendor /product 2>/dev/null | grep -E "libxposed|xposed_bridge" | head -2)
        if [ -n "$XP_LIBS" ]; then
            print_result "Xposed框架" "FAIL" "检测到Xposed库文件"
            XP_FOUND=1
        fi
    fi
    
    # 未检测到
    if [ $XP_FOUND -eq 0 ]; then
        print_result "Xposed框架" "PASS" "未检测到Xposed框架"
    fi
}

# ============================================
# 5. Zygisk检测
# ============================================
check_zygisk() {
    echo -e "\n${BLUE}[5] Zygisk检测${NC}"
    
    ZYGISK_FOUND=0
    
    # 检测1: Magisk Zygisk状态
    MAGISK_ZYGISK=$(getprop persist.zygisk.enabled 2>/dev/null)
    if [ -n "$MAGISK_ZYGISK" ] && [ "$MAGISK_ZYGISK" = "1" ]; then
        print_result "Zygisk" "WARN" "Magisk Zygisk已启用"
        ZYGISK_FOUND=1
    fi
    
    # 检测2: Zygisk模块目录
    ZYGISK_MODULES="/data/adb/modules/zygisk_* \
                    /data/adb/zygisk \
                    /data/adb/modules/*/zygisk"
    
    for pattern in $ZYGISK_MODULES; do
        if [ -d "$pattern" ] 2>/dev/null; then
            print_result "Zygisk" "WARN" "检测到Zygisk模块: $(basename $pattern)"
            ZYGISK_FOUND=1
            break
        fi
    done
    
    # 检测3: Zygisk进程特征
    ZYGISK_PROC=$(ps -A 2>/dev/null | grep -E "zygisk|magiskd" | head -1)
    if [ -n "$ZYGISK_PROC" ] && [ $ZYGISK_FOUND -eq 0 ]; then
        print_result "Zygisk" "WARN" "检测到Zygisk相关进程"
        ZYGISK_FOUND=1
    fi
    
    # 检测4: 检查lib注入特征
    if [ $ZYGISK_FOUND -eq 0 ]; then
        ZYGISK_LIBS=$(find /system /vendor /product /apex 2>/dev/null | grep -E "libzygisk|zygisk" | head -2)
        if [ -n "$ZYGISK_LIBS" ]; then
            print_result "Zygisk" "WARN" "检测到Zygisk库文件"
            ZYGISK_FOUND=1
        fi
    fi
    
    # 检测5: 检查memfd特征 (Zygisk通常会创建memfd)
    if [ $ZYGISK_FOUND -eq 0 ]; then
        MEMFD_CHECK=$(ls -la /proc/*/fd 2>/dev/null | grep -E "memfd:zygisk|memfd:magisk" | head -1)
        if [ -n "$MEMFD_CHECK" ]; then
            print_result "Zygisk" "WARN" "检测到Zygisk内存文件描述符"
            ZYGISK_FOUND=1
        fi
    fi
    
    # 未检测到Zygisk
    if [ $ZYGISK_FOUND -eq 0 ]; then
        print_result "Zygisk" "PASS" "未检测到Zygisk特征"
    fi
}

# ============================================
# 6. SU挂载检测
# ============================================
check_su_mount() {
    echo -e "\n${BLUE}[6] SU文件检测${NC}"
    
    SU_FOUND=0
    
    # SU文件路径列表
    SU_PATHS="/system/bin/su \
              /system/xbin/su \
              /system/sbin/su \
              /system/bin/.su \
              /system/xbin/.su \
              /system/sbin/.su \
              /system/bin/sugote \
              /system/bin/sugote-mksh \
              /system/bin/daemonsu \
              /system/xbin/daemonsu \
              /system/bin/magisk \
              /system/xbin/magisk \
              /system/bin/magiskpolicy \
              /system/xbin/magiskpolicy \
              /system/bin/supolicy \
              /system/xbin/supolicy"
    
    for su_path in $SU_PATHS; do
        if [ -f "$su_path" ]; then
            print_result "SU文件" "FAIL" "发现SU文件: $su_path"
            SU_FOUND=1
        fi
    done
    
    # 检测mount bind挂载
    MOUNT_CHECK=$(mount 2>/dev/null | grep -E "su|magisk" | head -3)
    if [ -n "$MOUNT_CHECK" ] && [ $SU_FOUND -eq 0 ]; then
        print_result "SU文件" "WARN" "检测到SU相关挂载点"
        echo -e "    ${YELLOW}→ $MOUNT_CHECK${NC}"
        SU_FOUND=1
    fi
    
    # 检查overlay挂载 (Magisk常用)
    OVERLAY_CHECK=$(mount 2>/dev/null | grep overlay | grep -E "system|vendor" | head -1)
    if [ -n "$OVERLAY_CHECK" ] && [ $SU_FOUND -eq 0 ]; then
        print_result "SU文件" "WARN" "检测到系统分区overlay挂载"
        SU_FOUND=1
    fi
    
    # 未检测到SU
    if [ $SU_FOUND -eq 0 ]; then
        print_result "SU文件" "PASS" "未检测到SU文件"
    fi
}

# ============================================
# 7. SELinux状态检测
# ============================================
check_selinux() {
    echo -e "\n${BLUE}[7] SELinux状态检测${NC}"
    
    # 获取SELinux状态
    SELINUX_STATUS=$(getenforce 2>/dev/null)
    SELINUX_POLICY=$(getprop ro.boot.selinux 2>/dev/null)
    
    case "$SELINUX_STATUS" in
        "Enforcing")
            print_result "SELinux" "PASS" "SELinux处于强制模式"
            ;;
        "Permissive")
            print_result "SELinux" "FAIL" "SELinux处于宽容模式 (已修改)"
            ;;
        "Disabled")
            print_result "SELinux" "FAIL" "SELinux已禁用 (严重修改)"
            ;;
        *)
            print_result "SELinux" "WARN" "无法获取SELinux状态"
            ;;
    esac
    
    # 显示SELinux策略版本
    if [ -f "/sys/fs/selinux/policyvers" ]; then
        POLICY_VER=$(cat /sys/fs/selinux/policyvers 2>/dev/null)
        echo -e "    → 策略版本: $POLICY_VER"
    fi
}

# ============================================
# 显示汇总报告
# ============================================
show_summary() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}检测完成 - 结果汇总${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    echo -e "${GREEN}正常: $PASS_COUNT${NC}"
    echo -e "${YELLOW}有痕迹: $WARN_COUNT${NC}"
    echo -e "${RED}确定修改: $FAIL_COUNT${NC}"
    
    TOTAL=$((PASS_COUNT + WARN_COUNT + FAIL_COUNT))
    echo -e "总计检测项: $TOTAL"
    
    if [ $FAIL_COUNT -gt 0 ]; then
        echo -e "\n${RED}⚠ 检测到 $FAIL_COUNT 项确定修改${NC}"
    elif [ $WARN_COUNT -gt 0 ]; then
        echo -e "\n${YELLOW}⚠ 检测到 $WARN_COUNT 项痕迹${NC}"
    else
        echo -e "\n${GREEN}✓ 所有检测项正常${NC}"
    fi
    
    print_separator
}

# ============================================
# 主执行流程
# ============================================
main() {
    print_title
    check_tricky_store
    check_tee
    check_bootloader
    check_xposed
    check_zygisk
    check_su_mount
    check_selinux
    show_summary
}

# 检查权限
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${YELLOW}警告: 建议以root权限运行以获得完整检测结果${NC}"
    echo -e "${YELLOW}尝试使用: su -c 'sh $0'${NC}\n"
fi

# 执行主函数
main