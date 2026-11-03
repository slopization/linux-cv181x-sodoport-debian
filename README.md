# Recipe-only Debian packaging for Linux 7.1

This repository contains only Debian packaging for the `cv181x-sodoport`
flavour (Milk-V Duo 256M / SG2002 family, including NanoKVM PCIe).
Sources live in [slopization/linux-cv181x-sodoport](https://github.com/slopization/linux-cv181x-sodoport),
a fork of torvalds/linux based on `v7.3`. The camera, pinctrl, Ethernet,
CV1800B watchdog-node and Wave420L changes are commits on source `cv181x`;
dependent commits are grouped in stacked topic branches. Do not apply those
source commits a second time as quilt patches. The NanoKVM PCIe board device
tree and its watchdog enablement are the exception: board enablement stays out
of the source branch and is carried by `debian/patches` instead.

## Branches and builds

- Recipe `main`: packaging only. The previous remote recipe branch was `master`.
- Source `cv181x`: Linux v7.1 plus all eight hardware commits; source history is not imported here.
- `patch/01-sg2002-duo256m`: Duo256M DTS (one commit).
- `patch/02-licheerv-nano-ethernet`: adds Ethernet support on top of the first topic.
- `patch/03-nanokvm-platform`: adds the six dependent NanoKVM camera/GPIO/reset/
  pinctrl, board DTS/fixups/OLED, Wave420L driver and enablement commits; same tip
  as `cv181x`. Topic branches are stacked, not advertised as independently buildable.
- Only pushes to source `cv181x` are watched for kernel CI; topic branches, upstream
  `master`, and kernel tags do not automatically build.
- Historical generated `latest`, `upstream/latest`, and `pristine-tar` branches
  are not inputs to the new build. No workflow generates or pushes Git refs.

The manual [build caller](.github/workflows/build.yml) accepts
`source-repository`, full lowercase 40-character `source-sha`, and optional raw
`source-tag`. Only `slopization/linux-cv181x-sodoport` is allowed. The dispatch
bridge may invoke this same API; build execution does not publish packages.
The caller pins an existing, preceding packaging commit with `recipe-sha` and
uses shared `slopization/debian-ci` CI at the fixed `v2.0.1` release.
After packaging changes, commit those first and update the literal pin in a
separate caller-only commit. Never use a future or self-referential pin.

Shared CI assembles the source snapshot with the pinned recipe, retaining
`3.0 (quilt)` for the NanoKVM PCIe board and watchdog patches. It builds in a
native amd64 Debian 13 (`trixie`) unshare chroot using `sbuild --build amd64
--host riscv64 --arch-all`. Explicit arch-all builds the source bundle as well
as the four riscv64 packages. No target emulation or generated-source Git
branch is required. Artifacts include source archives, binaries, logs,
changes, buildinfo, and source/recipe provenance, including on build failure.

Publishing is separate and manual through the [publish caller](.github/workflows/publish.yml):
supply a successful build run ID and artifact name. Publishing credentials
(`DEB_CREDENTIALS`) belong only to publishing, never to build dispatch.

## Verified pipeline

[Kernel build and artifacts](https://github.com/slopization/linux-cv181x-sodoport-debian/actions/runs/39569419468)
passed through the live App/Worker. Image, headers and meta packages are riscv64;
source is Architecture:all (plus a RISC-V headers debug-symbol package). Artifact
hashes, source/recipe provenance, dependency metadata, target header tools and
source archive integrity were checked without installing packages on the host.
Headers declare computed Perl/library dependencies for the shipped RISC-V tools.
Board boot and target-side DKMS smoke tests remain separate; no APT publication
was triggered by this verification.

## Board configuration and provenance

The initial board configuration and DTS seed came from the local
`/root/uboot/sg2002` Alpine package draft. The Debian recipe retained only the
kernel-facing pieces. The checked-in [board config](debian/config/cv181x-sodoport.config)
is a generated seed derived from Alpine `cv180x.riscv64.config`, with the
localversion replaced by the `cv181x-sodoport` flavour suffix.
The [base and fragment inputs](debian/config/README) remain unchanged.
The intended long-term Debian common fragment should be derived from the
intersection of Debian kernel configurations. Regenerate against an already
available source tree with the retained [configuration helper](debian/scripts/update-config.sh):

```sh
debian/scripts/update-config.sh /path/to/linux
```

The effective config keeps in-tree LT6911UXE disabled (the separate DKMS
package owns that driver), Wave420L as a module, and DWC2 dual-role enabled.
Kernel configuration and compiler selection remain unchanged. Packaging uses
fail-fast Bash recipes, including pipeline failures, so failed module install or
header-helper rebuilding cannot be hidden by a later successful command.

## Outputs

- `linux-image-7.1.0-cv181x-sodoport`: versioned image, System.map and config
  under `/boot`, board DTBs under `/usr/lib/linux-image-7.1.0-cv181x-sodoport/`,
  and modules under `/lib/modules/7.1.0-cv181x-sodoport/`.
- `linux-image-cv181x-sodoport`: current-image meta-package.
- `linux-headers-7.1.0-cv181x-sodoport`: prepared headers under `/usr/src`,
  with conventional module build/source symlinks.
- `linux-headers-cv181x-sodoport`: current-headers meta-package.
- `linux-source-cv181x-sodoport`: compressed source tree under `/usr/src`.

The kernel package does not choose a board DTB. With `u-boot-menu` installed,
Debian kernel hooks regenerate `/boot/extlinux/extlinux.conf`; the board
support package owns `fdtfile`, DTB syncing, and overlay policy.
