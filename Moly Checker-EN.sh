#!/system/bin/sh

# ============================================
# Environment Detection Script v1.0
# Checks: Modules, TEE, Bootloader, Xposed,
#         Zygisk, SU Mount, SELinux
# ============================================

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color
BLUE='\033[0;34m'

# Result counters
PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

# Print separator line
print_separator() {
    echo -e "${BLUE}========================================${NC}"
}

# Print title header
print_title() {
    echo -e "${BLUE}=== Environment Detection Report ===${NC}"
    echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Device: $(getprop ro.product.model 2>/dev/null || echo 'Unknown')"
    print_separator
}

# Output result with color coding
print_result() {
    local item=$1
    local status=$2
    local detail=$3
    
    case $status in
        "PASS")
            echo -e "[${GREEN}✓${NC}] $item: ${GREEN}PASS${NC}"
            if [ -n "$detail" ]; then
                echo -e "    ${GREEN}→ $detail${NC}"
            fi
            PASS_COUNT=$((PASS_COUNT + 1))
            ;;
        "WARN")
            echo -e "[${YELLOW}!${NC}] $item: ${YELLOW}WARNING${NC}"
            if [ -n "$detail" ]; then
                echo -e "    ${YELLOW}→ $detail${NC}"
            fi
            WARN_COUNT=$((WARN_COUNT + 1))
            ;;
        "FAIL")
            echo -e "[${RED}✗${NC}] $item: ${RED}FAIL${NC}"
            if [ -n "$detail" ]; then
                echo -e "    ${RED}→ $detail${NC}"
            fi
            FAIL_COUNT=$((FAIL_COUNT + 1))
            ;;
    esac
}

# ============================================
# 1. Module Check - Tricky Store
# ============================================
check_tricky_store() {
    echo -e "\n${BLUE}[1] Module Check - Tricky Store${NC}"
    
    if [ -d "/data/adb/tricky_store" ]; then
        print_result "Tricky Store Module" "WARN" "Tricky Store module detected"
        if [ -f "/data/adb/tricky_store/keybox.xml" ]; then
            echo -e "    ${YELLOW}→ keybox.xml file found${NC}"
        fi
        if [ -f "/data/adb/tricky_store/spoof_build_vars" ]; then
            echo -e "    ${YELLOW}→ spoof_build_vars file found${NC}"
        fi
    else
        print_result "Tricky Store Module" "PASS" "No Tricky Store module detected"
    fi
}

# ============================================
# 2. TEE Status Check
# ============================================
check_tee() {
    echo -e "\n${BLUE}[2] TEE Status Check${NC}"
    
    TEE_SUPPORT=$(getprop ro.boot.tee 2>/dev/null)
    TEE_TYPE=$(getprop ro.tee.type 2>/dev/null)
    TEE_VERSION=$(getprop ro.tee.version 2>/dev/null)
    
    if [ -n "$TEE_SUPPORT" ] && [ "$TEE_SUPPORT" = "enabled" ]; then
        print_result "TEE Support" "PASS" "TEE is enabled"
    elif [ -n "$TEE_SUPPORT" ]; then
        print_result "TEE Support" "WARN" "TEE status: $TEE_SUPPORT"
    else
        print_result "TEE Support" "WARN" "Unable to determine TEE status"
    fi
    
    if [ -f "/dev/tee" ] || [ -f "/dev/teepriv" ]; then
        print_result "TEE Device" "PASS" "TEE device files exist"
    else
        print_result "TEE Device" "WARN" "TEE device files not found"
    fi
    
    TEE_SERVICE=$(ps -A 2>/dev/null | grep -E "tee|tz_|qseecom" | head -1)
    if [ -n "$TEE_SERVICE" ]; then
        echo -e "    ${GREEN}→ TEE service is running${NC}"
    fi
}

# ============================================
# 3. Bootloader Status Check
# ============================================
check_bootloader() {
    echo -e "\n${BLUE}[3] Bootloader Status Check${NC}"
    
    BOOTLOADER=$(getprop ro.bootloader 2>/dev/null)
    BUILD_DATE=$(getprop ro.build.date 2>/dev/null)
    BUILD_TYPE=$(getprop ro.build.type 2>/dev/null)
    BUILD_TAGS=$(getprop ro.build.tags 2>/dev/null)
    FLASH_LOCKED=$(getprop ro.boot.flash.locked 2>/dev/null)
    VERIFIED_BOOTSTATE=$(getprop ro.boot.verifiedbootstate 2>/dev/null)
    
    if [ -n "$FLASH_LOCKED" ] && [ "$FLASH_LOCKED" = "0" ]; then
        print_result "Bootloader Lock" "FAIL" "Bootloader is UNLOCKED (FLASH_LOCKED=0)"
    elif [ -n "$FLASH_LOCKED" ] && [ "$FLASH_LOCKED" = "1" ]; then
        print_result "Bootloader Lock" "PASS" "Bootloader is locked"
    else
        if [ -n "$VERIFIED_BOOTSTATE" ] && [ "$VERIFIED_BOOTSTATE" != "green" ]; then
            print_result "Bootloader Lock" "WARN" "Verified boot state: $VERIFIED_BOOTSTATE"
        else
            print_result "Bootloader Lock" "WARN" "Unable to determine bootloader status"
        fi
    fi
    
    if [ -n "$BUILD_TYPE" ] && [ "$BUILD_TYPE" = "user" ]; then
        echo -e "    ${GREEN}→ Build type: $BUILD_TYPE${NC}"
    elif [ -n "$BUILD_TYPE" ]; then
        echo -e "    ${YELLOW}→ Build type: $BUILD_TYPE (non-user build)${NC}"
    fi
    
    if [ -n "$BOOTLOADER" ]; then
        echo -e "    → Bootloader version: $BOOTLOADER"
    fi
}

# ============================================
# 4. Xposed Framework Check
# ============================================
check_xposed() {
    echo -e "\n${BLUE}[4] Xposed Framework Check${NC}"
    
    XP_FOUND=0
    
    XP_PATHS="/data/data/de.robv.android.xposed.installer \
              /data/data/io.github.xposed.installer \
              /data/data/com.topjohnwu.magisk/modules/xposed \
              /data/adb/modules/xposed \
              /data/adb/modules/zygisk_lsposed \
              /data/adb/modules/riru_edxposed"
    
    for path in $XP_PATHS; do
        if [ -d "$path" ]; then
            print_result "Xposed Framework" "FAIL" "Xposed/LSPosed installation detected: $(basename $path)"
            XP_FOUND=1
            break
        fi
    done
    
    XP_PROCESS=$(ps -A 2>/dev/null | grep -E "xposed|lsposed|edxposed" | head -1)
    if [ -n "$XP_PROCESS" ] && [ $XP_FOUND -eq 0 ]; then
        print_result "Xposed Framework" "FAIL" "Xposed-related processes detected"
        XP_FOUND=1
    fi
    
    XP_PROPS=$(getprop | grep -i xposed 2>/dev/null)
    if [ -n "$XP_PROPS" ] && [ $XP_FOUND -eq 0 ]; then
        print_result "Xposed Framework" "FAIL" "Xposed system properties detected"
        XP_FOUND=1
    fi
    
    if [ $XP_FOUND -eq 0 ]; then
        XP_LIBS=$(find /system /vendor /product 2>/dev/null | grep -E "libxposed|xposed_bridge" | head -2)
        if [ -n "$XP_LIBS" ]; then
            print_result "Xposed Framework" "FAIL" "Xposed library files detected"
            XP_FOUND=1
        fi
    fi
    
    if [ $XP_FOUND -eq 0 ]; then
        print_result "Xposed Framework" "PASS" "No Xposed framework detected"
    fi
}

# ============================================
# 5. Zygisk Detection
# ============================================
check_zygisk() {
    echo -e "\n${BLUE}[5] Zygisk Detection${NC}"
    
    ZYGISK_FOUND=0
    
    MAGISK_ZYGISK=$(getprop persist.zygisk.enabled 2>/dev/null)
    if [ -n "$MAGISK_ZYGISK" ] && [ "$MAGISK_ZYGISK" = "1" ]; then
        print_result "Zygisk" "WARN" "Magisk Zygisk is enabled"
        ZYGISK_FOUND=1
    fi
    
    ZYGISK_MODULES="/data/adb/modules/zygisk_* \
                    /data/adb/zygisk \
                    /data/adb/modules/*/zygisk"
    
    for pattern in $ZYGISK_MODULES; do
        if [ -d "$pattern" ] 2>/dev/null; then
            print_result "Zygisk" "WARN" "Zygisk module detected: $(basename $pattern)"
            ZYGISK_FOUND=1
            break
        fi
    done
    
    ZYGISK_PROC=$(ps -A 2>/dev/null | grep -E "zygisk|magiskd" | head -1)
    if [ -n "$ZYGISK_PROC" ] && [ $ZYGISK_FOUND -eq 0 ]; then
        print_result "Zygisk" "WARN" "Zygisk-related processes detected"
        ZYGISK_FOUND=1
    fi
    
    if [ $ZYGISK_FOUND -eq 0 ]; then
        ZYGISK_LIBS=$(find /system /vendor /product /apex 2>/dev/null | grep -E "libzygisk|zygisk" | head -2)
        if [ -n "$ZYGISK_LIBS" ]; then
            print_result "Zygisk" "WARN" "Zygisk library files detected"
            ZYGISK_FOUND=1
        fi
    fi
    
    if [ $ZYGISK_FOUND -eq 0 ]; then
        MEMFD_CHECK=$(ls -la /proc/*/fd 2>/dev/null | grep -E "memfd:zygisk|memfd:magisk" | head -1)
        if [ -n "$MEMFD_CHECK" ]; then
            print_result "Zygisk" "WARN" "Zygisk memory file descriptors detected"
            ZYGISK_FOUND=1
        fi
    fi
    
    if [ $ZYGISK_FOUND -eq 0 ]; then
        print_result "Zygisk" "PASS" "No Zygisk characteristics detected"
    fi
}

# ============================================
# 6. SU File Detection
# ============================================
check_su_mount() {
    echo -e "\n${BLUE}[6] SU File Detection${NC}"
    
    SU_FOUND=0
    
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
            print_result "SU Files" "FAIL" "SU file found: $su_path"
            SU_FOUND=1
        fi
    done
    
    MOUNT_CHECK=$(mount 2>/dev/null | grep -E "su|magisk" | head -3)
    if [ -n "$MOUNT_CHECK" ] && [ $SU_FOUND -eq 0 ]; then
        print_result "SU Files" "WARN" "SU-related mount points detected"
        echo -e "    ${YELLOW}→ $MOUNT_CHECK${NC}"
        SU_FOUND=1
    fi
    
    OVERLAY_CHECK=$(mount 2>/dev/null | grep overlay | grep -E "system|vendor" | head -1)
    if [ -n "$OVERLAY_CHECK" ] && [ $SU_FOUND -eq 0 ]; then
        print_result "SU Files" "WARN" "System partition overlay mount detected"
        SU_FOUND=1
    fi
    
    if [ $SU_FOUND -eq 0 ]; then
        print_result "SU Files" "PASS" "No SU files detected"
    fi
}

# ============================================
# 7. SELinux Status Check
# ============================================
check_selinux() {
    echo -e "\n${BLUE}[7] SELinux Status Check${NC}"
    
    SELINUX_STATUS=$(getenforce 2>/dev/null)
    SELINUX_POLICY=$(getprop ro.boot.selinux 2>/dev/null)
    
    case "$SELINUX_STATUS" in
        "Enforcing")
            print_result "SELinux" "PASS" "SELinux is in Enforcing mode"
            ;;
        "Permissive")
            print_result "SELinux" "FAIL" "SELinux is in Permissive mode (MODIFIED)"
            ;;
        "Disabled")
            print_result "SELinux" "FAIL" "SELinux is DISABLED (CRITICAL)"
            ;;
        *)
            print_result "SELinux" "WARN" "Unable to determine SELinux status"
            ;;
    esac
    
    if [ -f "/sys/fs/selinux/policyvers" ]; then
        POLICY_VER=$(cat /sys/fs/selinux/policyvers 2>/dev/null)
        echo -e "    → Policy version: $POLICY_VER"
    fi
}

# ============================================
# Summary Report
# ============================================
show_summary() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}Detection Complete - Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    echo -e "${GREEN}PASS: $PASS_COUNT${NC}"
    echo -e "${YELLOW}WARNING: $WARN_COUNT${NC}"
    echo -e "${RED}FAIL: $FAIL_COUNT${NC}"
    
    TOTAL=$((PASS_COUNT + WARN_COUNT + FAIL_COUNT))
    echo -e "Total checks: $TOTAL"
    
    if [ $FAIL_COUNT -gt 0 ]; then
        echo -e "\n${RED}⚠ $FAIL_COUNT checks FAILED${NC}"
    elif [ $WARN_COUNT -gt 0 ]; then
        echo -e "\n${YELLOW}⚠ $WARN_COUNT warnings detected${NC}"
    else
        echo -e "\n${GREEN}✓ All checks PASSED${NC}"
    fi
    
    print_separator
}

# ============================================
# Main Execution
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

# Permission check
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${YELLOW}Warning: Root privileges recommended for complete detection${NC}"
    echo -e "${YELLOW}Try: su -c 'sh $0'${NC}\n"
fi

# Execute main
main