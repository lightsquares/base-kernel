#!/bin/sh
set -eu

config=${1:?usage: verify_guest_config.sh CONFIG}

require_value() {
    grep -qx "CONFIG_$1=$2" "$config" || {
        echo "required kernel setting missing: CONFIG_$1=$2" >&2
        exit 1
    }
}

require_disabled() {
    ! grep -Eq "^CONFIG_$1=[ym]$" "$config" || {
        echo "kernel attack surface still enabled: CONFIG_$1" >&2
        exit 1
    }
}

for symbol in SEV_GUEST AMD_MEM_ENCRYPT DEVTMPFS BLK_DEV_INITRD RD_GZIP \
    FUTEX POSIX_TIMERS HIGH_RES_TIMERS SHMEM TMPFS PROC_SYSCTL TTY UNIX98_PTYS \
    SERIAL_8250_CONSOLE SCSI_VIRTIO VIRTIO_PCI VIRTIO_NET HW_RANDOM_VIRTIO \
    BLK_DEV_DM DM_CRYPT DM_VERITY EXT4_FS OVERLAY_FS \
    VIRTIO_VSOCKETS VETH BRIDGE NF_TABLES SYN_COOKIES NET_NS USER_NS CGROUPS \
    SECCOMP SECCOMP_FILTER SECURITY_YAMA RANDOMIZE_BASE VMAP_STACK \
    STRICT_KERNEL_RWX FORTIFY_SOURCE HARDENED_USERCOPY \
    SLAB_FREELIST_RANDOM SLAB_FREELIST_HARDENED INIT_ON_ALLOC_DEFAULT_ON \
    INIT_ON_FREE_DEFAULT_ON; do
    require_value "$symbol" y
done

for symbol in MODULES KEXEC KEXEC_FILE HIBERNATION SUSPEND IA32_EMULATION \
    X86_X32_ABI USERFAULTFD HW_PERF_EVENTS KPROBES UPROBES FTRACE DEBUG_FS \
    DEBUG_INFO DEVMEM PROC_KCORE BPF_SYSCALL IO_URING IO_URING_ZCRX COREDUMP \
    MAGIC_SYSRQ DM_VERITY_VERIFY_ROOTHASH_SIG SECURITY_LANDLOCK; do
    require_disabled "$symbol"
done

require_value LSM '"lockdown,yama"'

echo "Base kernel config satisfies the functional and hardening contracts."
