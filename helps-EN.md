# Hiding / Fixing Suggestions

This script is used to detect Root environment features. Below are common hiding or fixing approaches for the corresponding detection items.  
**Note: For study and research purposes only. Do not use for illegal activities.**

---

## 1. Suspicious Modules (Tricky Store / keybox.xml)

- Remove the module: Uninstall or disable it directly in Magisk / KernelSU / APatch
- Rename to hide: Modify the module folder name (module configuration must also be updated)
- Try using the TEE Simulator module to resolve (only works on certain devices)
- Wait for module updates (almost impossible)

---

## 2. TEE Status

- TEE status is determined by the device hardware and cannot be modified via software
- Unlocking the Bootloader may permanently fuse TEE on some devices (e.g., OPPO / OnePlus)
- If TEE is invalid, the usual solution is to restore factory settings or relock the Bootloader (requires official support)

---

## 3. Bootloader Status

- Relock Bootloader: Use fastboot oem lock or official tools
- **Note: Relocking will erase all data, and some devices still show unlocked after relocking (e.g., Xiaomi)**
- An unlocked status does not affect daily use; it is only used to determine device state
- Try installing the Play Integrity Fork module to resolve (works on certain devices)

---

## 4. Xposed Framework

- Uninstall Xposed / LSPosed / EdXposed frameworks
- If needed, use HMA (HiddenMyApp) to hide from target apps
- It is not recommended to enable Xposed in sensitive apps (e.g., banking, games)

---

## 5. Zygisk Injection

- Disable Zygisk in Magisk settings (requires reboot)
- Switch to KernelSU + ZygiskNext combination to reduce traces in some cases
- Try switching to ReZygisk to resolve (works on certain devices)
- Wait for module updates (almost impossible)

---

## 6. su Mount

- Use Magic Mount or Overlay to mount su and avoid direct exposure
- Some kernels support rename mount to hide su paths
- KernelSU users can set legacy su command support to Always Disabled
- If Root privileges are not needed, temporarily disable Root or use temporary unroot

---

## 7. SELinux Status

- Keep SELinux in enforcing mode (setenforce 1)
- If permissive, force enable via Magisk module or kernel parameters
- Try restarting the device to resolve (some devices revert to enforcing after reboot)

---

## Other General Suggestions

- Use **Shamiko** (Magisk module) to hide Root from specific apps
- Use **HMA (HiddenMyApp)** to hide Xposed / LSPosed from detection apps
- Use **AppListDetector** and similar tools to self-check and verify hiding effectiveness

---

## Disclaimer

This guide provides technical ideas only and does not guarantee 100% bypass of detection.  
Please comply with the terms of use of relevant applications. Users are solely responsible for any consequences arising from misuse.
