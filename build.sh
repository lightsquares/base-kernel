#!/bin/sh
set -eu

# Official upstream Linux; this commit is the Linux 6.16 release.
LINUX_REPOSITORY=https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
LINUX_COMMIT=038d61fd642278bab63ee8ef722c50d10ab01e8f
SOURCE_DATE_EPOCH=1753651598
KBUILD_BUILD_TIMESTAMP='Sun Jul 27 21:26:38 UTC 2025'
REPOSITORY_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SOURCE_DIR=${KERNEL_SOURCE_DIR:-/tmp/base-kernel-source}
OUTPUT_DIR=${KERNEL_OUTPUT_DIR:-/tmp/base-kernel-output}

cleanup_source=0
if [ ! -d "$SOURCE_DIR/.git" ]; then
    test ! -e "$SOURCE_DIR"
    mkdir -p "$SOURCE_DIR"
    cleanup_source=1
    git -C "$SOURCE_DIR" init -q
    git -C "$SOURCE_DIR" remote add origin "$LINUX_REPOSITORY"
    git -C "$SOURCE_DIR" fetch -q --depth 1 origin "$LINUX_COMMIT"
    git -C "$SOURCE_DIR" checkout -q --detach FETCH_HEAD
fi
trap '[ "$cleanup_source" -eq 0 ] || rm -rf "$SOURCE_DIR"' EXIT HUP INT TERM

test "$(git -C "$SOURCE_DIR" rev-parse HEAD)" = "$LINUX_COMMIT"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR" "$REPOSITORY_DIR/dist"

# Start from allnoconfig and add back only the audited guest functionality and
# production hardening contracts. kernel.config is the generated, resolved
# result retained for review; it is not a second source of truth.
cat "$REPOSITORY_DIR/kernel-functional.config" \
    "$REPOSITORY_DIR/kernel-hardening.config" > "$OUTPUT_DIR/min.config"
make -C "$SOURCE_DIR" O="$OUTPUT_DIR" \
    KCONFIG_ALLCONFIG="$OUTPUT_DIR/min.config" allnoconfig
make -C "$SOURCE_DIR" O="$OUTPUT_DIR" olddefconfig
"$REPOSITORY_DIR/verify-kernel-config.sh" "$OUTPUT_DIR/.config"

export SOURCE_DATE_EPOCH KBUILD_BUILD_TIMESTAMP
export KBUILD_BUILD_USER=builder
export KBUILD_BUILD_HOST=builder
export KBUILD_BUILD_VERSION=1

make -C "$SOURCE_DIR" O="$OUTPUT_DIR" -j"${JOBS:-8}" bzImage
install -m 0644 "$OUTPUT_DIR/arch/x86/boot/bzImage" \
    "$REPOSITORY_DIR/dist/bzImage"
install -m 0644 "$OUTPUT_DIR/.config" "$REPOSITORY_DIR/kernel.config"

size=$(stat -c '%s' "$REPOSITORY_DIR/dist/bzImage")
max_size=$((12 * 1024 * 1024))
test "$size" -le "$max_size" || {
    echo "Base kernel exceeds 12 MiB size budget: $size bytes" >&2
    exit 1
}
echo "Built base kernel: $size bytes (budget: $max_size bytes)"
