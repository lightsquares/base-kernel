# Base kernel

[![Light Squares Attestable Builds](https://app.lightsquares.dev/api/badge/lightsquares/base-ovmf.svg)](https://app.lightsquares.dev/builds/dashboard?show=lightsquares/base-ovmf)

Builds the pinned Linux guest kernel used by the confidential VM base image.
The source commit, Debian snapshot/compiler image, Kbuild metadata and config
inputs are pinned for reproducibility.

Kernel source comes from Linus Torvalds' official upstream repository on
kernel.org. The pinned commit is the Linux 6.16 release; no AMD fork or
out-of-tree guest patches are required.

Configuration starts from `allnoconfig` and applies two small contracts:

- `kernel-functional.config` contains only the SNP/QEMU, dm-verity,
  dm-crypt, gVisor/Podman and networking functionality used by epsilon.
- `kernel-hardening.config` enables production hardening and explicitly
  removes modules, unused privilege mechanisms, legacy ABIs, debug and device
  families.

`verify-kernel-config.sh` fails the build if required functionality disappears
or a denied attack surface returns. `kernel.config` is the generated resolved
configuration retained for review, not an independent input.

```sh
podman build -t base-kernel-builder .
podman run --rm -v "$PWD:/workspace" -w /workspace \
  base-kernel-builder ./build.sh
```

The kernel is written to `dist/bzImage`. The build also enforces a 12 MiB
maximum and refreshes the resolved `kernel.config`.
