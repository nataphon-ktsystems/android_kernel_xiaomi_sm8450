# Xiaomi 12 Pro (zeus): Droidspaces kernel

This branch adds Droidspaces container support and official KernelSU v3.3.1 to
the PixelOS kernel at `8b33f8e9a44a6351e65138c4fe0be0fd5ffdcbd1`.

## Tested environment

- Xiaomi 12 Pro (zeus), model 2201122G.
- PixelOS `PixelOS_zeus-16.2-20260619-1345`, Android 16, security patch 2026-06-01.
- Kernel 5.10.252, KernelSU v3.3.1 (32680), Droidspaces v7.2.0.
- Debian 13 ARM64: systemd as PID 1, `systemctl is-system-running` reports
  `running`, zero failed units, graceful stop/start, NAT and DNS tested.
- Android boots with SELinux enforcing. Vendor module import CRCs were checked
  for all 394 installed vendor modules: no mismatches or unresolved imports.
- KernelSU root was tested with the unmodified PixelOS ramdisk and no Magisk
  daemon. Existing module mounting needs separate migration and validation.

## Scope and limits

This is an exact-ROM build, not a generic kernel for other Xiaomi devices or
firmware versions. Retain a known-good boot image and working fastboot recovery.

The SYSVIPC and POSIX message-queue patches move added fields into Android's ABI
padding. CFS_BANDWIDTH and CGROUP_PIDS remain disabled because they break the ABI
used by prebuilt vendor modules. Per-container CPU bandwidth and PID count limits
are unavailable. Memory and swap limits pass the runtime requirements probe.

Docker, GPU acceleration, OTA survival and long-term stability are untested.
Full disk and app data backups are outside this kernel release.

The charging property-ID source correction does not override current, voltage
or thermal protection. The vendor charging module is separate from the kernel
image, so a kernel-only installation does not replace that module.

## Build

Use Linux with make, flex, bison, Python 3, OpenSSL/libelf headers, and the Android
NDK r29 LLVM toolchain. The tested compiler is clang 21, Android build 13989888,
LLVM commit `5e96669f06077099aa41290cdb4c5e6fa0f59349`.

Clone this branch with its pinned KernelSU submodule:

```sh
git clone --recurse-submodules --branch droidspaces-zeus-pixelos-16.2 \
  https://github.com/nataphon-ktsystems/android_kernel_xiaomi_sm8450.git
cd android_kernel_xiaomi_sm8450
export ZDS_LLVM_BIN=/path/to/android-ndk-r29/toolchains/llvm/prebuilt/linux-x86_64/bin
ZDS_JOBS=4 scripts/build-zeus-droidspaces.sh
```

The image is `out-zeus-droidspaces/arch/arm64/boot/Image`. Keep MODVERSIONS and
CFI enabled. Compare vendor module imports against the completed Module.symvers
before booting a build with further configuration changes. Do not force-load
modules to bypass checksum mismatches.

The released boot image uses the exact original PixelOS boot image as its base
(SHA256 `683b5cbe77a37a80e0085ccede2c348e4effd24fe184a9efa207032a4f5ccad9`),
replacing only its kernel using magiskboot unpack/repack. magiskboot is a host
image-manipulation tool; the resulting ramdisk is not Magisk-patched.

## Droidspaces and module migration

Install the official KernelSU manager and Droidspaces APKs. Grant Droidspaces
root through KernelSU, install its backend and boot module, and follow the
official Droidspaces kernel and Android installation guides.

Do not assume copying Magisk module files preserves their SELinux labels. A
hosts overlay copied to an ext4 image without contexts produced `unlabeled`
overlay directories and prevented Android services from starting. Assign the
contexts from the real destination files, then verify them after remounting.
Android Toybox chcon on this ROM does not support `--reference`.

The meta-overlayfs v1.3.1 staging image also required 4 KiB loop block size and
direct I/O for a successful read-write mount on this device. It was tested with
fresh attach, mount, write/readback and remount cycles. Directory-based Debian
containers do not depend on that module image.

References:

- https://www.droidspaces.org/docs/kernel-configuration.html
- https://www.droidspaces.org/docs/installation-android.html
- https://kernelsu.org/guide/installation.html

## Patch attribution

SYSVIPC ABI padding: nullptr-t-oss. POSIX message-queue ABI padding:
lateautumn233. Both patches are supplied by Droidspaces and their original
authorship is retained in this branch's commit history.
