# 隐藏/修复建议

本脚本用于检测 Root 环境特征，以下为对应检测项的常见隐藏或修复思路。  
**注意：仅供学习研究，请勿用于非法用途。**

---

## 1. 可疑模块（Tricky Store / keybox.xml）

- 移除模块：在 Magisk / KernelSU / APatch 中直接卸载或禁用
- 改名隐藏：修改模块文件夹名称（需同时修改模块配置）
- 尝试使用 TEE Simulator 模块解决（仅部分设备可用）
- 等待模块开发者更新（几乎不可能实现）

---

## 2. TEE 状态

- TEE 状态由设备出厂决定，无法通过软件修改
- 部分设备解锁 Bootloader 后 TEE 会永久熔断（如 OPPO / 一加）
- 若 TEE 为 invalid，通常只能恢复出厂或回锁 Bootloader（需官方支持）

---

## 3. Bootloader 状态

- 回锁 Bootloader：使用 fastboot oem lock 或官方工具
- **注意：回锁会清除所有数据，且部分设备回锁后仍然显示 unlocked（如小米）**
- 检测到 unlocked 不影响日常使用，仅用于判断设备状态
- 可尝试安装 Play Integrity Fork 模块解决（部分设备可用）

---

## 4. Xposed 框架

- 卸载 Xposed / LSPosed / EdXposed 框架
- 若需使用，可搭配 HMA（HiddenMyApp）对目标应用隐藏
- 不建议在检测敏感的应用（如银行、游戏）中开启 Xposed

---

## 5. Zygisk 注入

- 在 Magisk 设置中关闭 Zygisk（需重启）
- 切换至 KernelSU + ZygiskNext 组合，部分场景可降低特征
- 尝试更换为 ReZygisk 解决（部分设备可用）
- 等待模块更新（几乎不可能实现）

---

## 6. su 挂载

- 使用 Magic Mount 或 Overlay 方式挂载 su，避免直接暴露
- 部分内核支持 rename 挂载，可隐藏 su 路径
- KernelSU 用户可将传统 su 命令支持改为始终禁用
- 若无需 Root 权限，可临时关闭 Root 或使用临时 unroot 功能

---

## 7. SELinux 状态

- 保持 SELinux 为 enforcing 状态（setenforce 1）
- 若为 permissive，可通过 Magisk 模块或内核参数强制开启
- 尝试重启设备解决（部分设备重启后恢复 enforcing）

---

## 其他通用建议

- 使用 **Shamiko**（Magisk 模块）对特定应用隐藏 Root
- 使用 **HMA（HiddenMyApp）** 对检测应用隐藏 Xposed / LSPosed
- 使用 **AppListDetector** 等工具自查，确认隐藏效果

---

## 免责声明

本指南仅提供技术思路，不保证 100% 绕过检测。  
请遵守相关应用的使用协议，因滥用导致的后果由使用者自行承担。
