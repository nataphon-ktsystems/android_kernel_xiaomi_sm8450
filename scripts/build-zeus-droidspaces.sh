#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${ZDS_LLVM_BIN:?Set ZDS_LLVM_BIN to the Android NDK r29 LLVM bin directory}"
test -f KernelSU/kernel/Kconfig
task_out=${ZDS_OUT:-out-zeus-droidspaces}
case "$task_out" in /*) ;; *) task_out="$PWD/$task_out" ;; esac
mkdir -p "$task_out/host-bin"
ln -sf "$(command -v python3)" "$task_out/host-bin/python"
export PATH="$task_out/host-bin:$ZDS_LLVM_BIN:$PATH"
make ARCH=arm64 O="$task_out" LLVM=1 LLVM_IAS=1 zeus_droidspaces_defconfig
make -j"${ZDS_JOBS:-4}" ARCH=arm64 O="$task_out" LLVM=1 LLVM_IAS=1 \
 CROSS_COMPILE=aarch64-linux-gnu- \
 KERNELRELEASE=5.10.252-Requiem-Kernel-@8b33f8e9 Image modules
