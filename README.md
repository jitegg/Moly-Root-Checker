# Moly-Root-Checker
Shell script for detecting root environment on Android.

## Download the script
If you want to try this script, you can go there:
#### 脚本下载：
[下载 Download](Moly.zip)

## How does it work?
### 1.Module Detection
Check if your module list path (data/adb/modules) contains Tricky Store or keybox.xml.

### 2.TEE status
Check your system properties to determine your device's TEE status.

### 3.Bootloader status
Determine if the device's bootloader is unlocked by reading multiple build.prop entries.

### 4.Xposed Framework
Our detection methods:

#### 1. Module Path Detection

Check the following paths for Xposed framework characteristics:

1. /data/data
2. /data/adb/modules

#### 2. Process Inspection

Read the process list via command to filter and check for Xposed framework-related processes.

#### 3. System Properties

Read system prop properties to search for characteristic traces (usually not present).

#### 4. Library File Check

Scan directories such as /system, /vendor, /product, etc., for the runtime libraries required by Xposed.

### 5.Zygisk Injection
The script establishes five detection methods:

#### 1.Magisk Zygisk Status
Read Magisk's Zygisk setting status to determine whether Zygisk is enabled.

#### 2.Module Directory
Read the module list under the /data/adb/modules directory to check if it contains Zygisk module names.

#### 3.Process Characteristics
Read the process table to check for Zygisk and its injection-related processes.

#### 4.lib Injection Characteristics
Obtain lib libraries from directories such as system, vendor, product, apex, etc., to check for lib libraries required for Zygisk operation.

#### 5.memfd Characteristics
Under certain circumstances, Zygisk creates memfd files in the /proc directory. This script checks for such characteristic files to determine the presence of Zygisk injection.

### 6.su Mount Detection
/system/bin/su \
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
/system/xbin/supolicy

Scan the above directories for the presence of su command files.

Additionally, scan for mount bind and overlay mount points.

### 7.SeLinux Status Detection
Retrieve the SELinux status via prop and display the SELinux policy version.

## Usage
Execute the file with root privileges via Termux or other terminal emulators (root privileges do not affect the detection results).

## Solutions and Suggestions
Please read the help documentation in your corresponding language:
#### 帮助文档：
[中文](helps-CN.md) [English](helps-EN.md)

## Author's Note
Thank you for using this script. This script is completely open-source. The author is a first-year junior high school student and does not have much energy for maintenance. I will regularly fix and update the script. Thank you for your support!

If this project helps you, please give it a ⭐ Star on GitHub!
