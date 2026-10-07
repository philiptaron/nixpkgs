# vmTools {#sec-vm-tools}

A set of VM related utilities, that help in building some packages in more advanced scenarios.
They are useful when a build needs things a normal Nix build cannot do, such as mounting filesystems, loading kernel modules, or running another Linux distribution's tools.
The VMs run with QEMU/KVM, so builds using them need the `kvm` system feature.

## `vmTools.createEmptyImage` {#vm-tools-createEmptyImage}

A bash script fragment that produces a disk image at `destination`.

### Attributes {#vm-tools-createEmptyImage-attributes}

* `size`. The disk size, in MiB.
* `fullName`. Name that will be written to `${destination}/nix-support/full-name`.
* `destination` (optional, default `$out`). Where to write the image files.

The image is written to `${destination}/disk-image.qcow2`, and the fragment sets `diskImage` to it, so a VM started afterwards gets it as `/dev/vda`.
See the [`runInLinuxVM` examples](#vm-tools-runInLinuxVM-examples) for how to use it.

## `vmTools.runInLinuxVM` {#vm-tools-runInLinuxVM}

Run a derivation in a Linux virtual machine (using Qemu/KVM).
By default, there is no disk image; the root filesystem is a `tmpfs`, and the Nix store is shared with the host (via [virtiofs](https://virtio-fs.gitlab.io/)).
Thus, any pure Nix derivation should run unmodified.
The build runs as root inside the VM, so it can mount filesystems and load kernel modules.

### Attributes {#vm-tools-runInLinuxVM-attributes}

* `preVM` (optional). Shell command to be evaluated *before* the VM is started (i.e., on the host).
* `postVM` (optional). Shell command to be evaluated *after* the VM has finished (i.e., on the host).
* `memSize` (optional, default `512`). The memory size of the VM in MiB (1024×1024 bytes).
* `QEMU_OPTS` (optional). Extra arguments for QEMU, for example additional `-drive` options.
* `enableParallelBuilding` (optional). When set, the VM gets as many CPUs as the build has cores.
* `diskImage` (optional). A file system image to be attached to `/dev/vda`.
  It is opened read-write, so it cannot be a path in the Nix store; set it in `preVM` instead, as in the examples below.
  Note that currently we expect the image to contain a filesystem, not a full disk image with a partition table etc.

### Examples {#vm-tools-runInLinuxVM-examples}

Build the derivation hello inside a VM:
```nix
{ pkgs }: with pkgs; with vmTools; runInLinuxVM hello
```

Build inside a VM with extra memory:
```nix
{ pkgs }:
with pkgs;
with vmTools;
runInLinuxVM (
  hello.overrideAttrs (_: {
    memSize = 1024;
  })
)
```

Build an ext4 filesystem image containing a file.
`createEmptyImage` in `preVM` creates the (empty) disk, which the build formats and fills from inside the VM:
```nix
{ pkgs }:
pkgs.vmTools.runInLinuxVM (
  pkgs.runCommand "data-image"
    {
      preVM = pkgs.vmTools.createEmptyImage {
        size = 64;
        fullName = "data";
      };
      nativeBuildInputs = [
        pkgs.e2fsprogs
        pkgs.util-linux
      ];
    }
    ''
      mkfs.ext4 -q /dev/vda
      mkdir /mnt
      mount /dev/vda /mnt
      echo hello > /mnt/hello.txt
      umount /mnt
    ''
)
```

Kernel modules that are not needed to boot the VM are loaded on demand, so the same works for other filesystems such as btrfs.

Use an existing image, such as the one built above, in another build.
Images in the Nix store are read-only, so put a copy-on-write overlay in front of it:
```nix
{ pkgs, dataImage }:
pkgs.vmTools.runInLinuxVM (
  pkgs.runCommand "read-data"
    {
      preVM = ''
        diskImage=$(pwd)/disk.qcow2
        ${pkgs.vmTools.qemu}/bin/qemu-img create -f qcow2 -F qcow2 \
          -b ${dataImage}/disk-image.qcow2 "$diskImage"
      '';
      nativeBuildInputs = [ pkgs.util-linux ];
    }
    ''
      mkdir /mnt
      mount -o ro /dev/vda /mnt
      cat /mnt/hello.txt > $out
    ''
)
```

### Debugging {#vm-tools-runInLinuxVM-debugging}

If the build fails and Nix is run with the `-K/--keep-failed` option, a script `run-vm` is left behind in the temporary build directory.
That directory belongs to the build user, so copy it somewhere writable first.
Then `./run-vm` runs the build again, and `./run-vm --shell` boots the VM into an interactive shell instead, in the build's environment.
Power the VM off with the `poweroff -f` command the shell prints, or with Ctrl-A X.

### Customizing the VM {#vm-tools-override}

`vmTools` takes a few arguments that can be changed with `vmTools.override`:

* `kernel`. The kernel to boot. Defaults to `pkgs.linux`.
* `kernelModules`. The module tree to load modules from. Defaults to `kernel`.
* `rootModules`. The modules loaded at boot, before the build starts.
* `customQemu`. A QEMU command to use instead of the default one.

Boot a newer kernel:
```nix
{ pkgs }:
let
  vmTools = pkgs.vmTools.override { kernel = pkgs.linuxPackages_latest.kernel; };
in
vmTools.runInLinuxVM (pkgs.runCommand "uname" { } "uname -r > $out")
```

Make an out-of-tree module available.
The module tree has to include the kernel's own modules, which live in its `modules` output:
```nix
{ pkgs }:
let
  inherit (pkgs.linuxPackages) kernel v4l2loopback;
  vmTools = pkgs.vmTools.override {
    kernelModules = pkgs.aggregateModules [
      kernel
      (pkgs.lib.getOutput "modules" kernel)
      v4l2loopback
    ];
  };
in
vmTools.runInLinuxVM (
  pkgs.runCommand "v4l2loopback" { nativeBuildInputs = [ pkgs.kmod ]; } ''
    modprobe v4l2loopback
    ls /dev/video0
    touch $out
  ''
)
```

## `vmTools.extractFs` {#vm-tools-extractFs}

Takes a file, such as an ISO, and extracts its contents into the store.

### Attributes {#vm-tools-extractFs-attributes}

* `file`. Path to the file to be extracted.
  Note that currently we expect the image to contain a filesystem, not a full disk image with a partition table etc.
  It must be a raw image, not a QEMU image such as the ones `createEmptyImage` makes.
* `fs` (optional). Filesystem of the contents of the file.

### Examples {#vm-tools-extractFs-examples}

Extract the contents of an ISO file:
```nix
{ pkgs }: with pkgs; with vmTools; extractFs { file = ./image.iso; }
```

Extract the contents of an ext4 image:
```nix
{ pkgs }:
pkgs.vmTools.extractFs {
  file = ./rootfs.ext4;
  fs = "ext4";
}
```

## `vmTools.extractMTDfs` {#vm-tools-extractMTDfs}

Like [](#vm-tools-extractFs), but it makes use of a [Memory Technology Device (MTD)](https://en.wikipedia.org/wiki/Memory_Technology_Device).
The emulated device has 128 KiB erase blocks, so make JFFS2 images with `mkfs.jffs2 -e 128KiB`.

### Examples {#vm-tools-extractMTDfs-examples}

Extract the contents of a JFFS2 image:
```nix
{ pkgs }:
pkgs.vmTools.extractMTDfs {
  file = ./rootfs.jffs2;
  fs = "jffs2";
}
```

## `vmTools.runInLinuxImage` {#vm-tools-runInLinuxImage}

Like [](#vm-tools-runInLinuxVM), but instead of using `stdenv` from the Nix store, run the build using the tools provided by `/bin`, `/usr/bin`, etc. from the specified filesystem image, which typically is a filesystem containing a [FHS](https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard)-based Linux distribution.
The image is not modified: the build runs on a copy-on-write overlay.

### Attributes {#vm-tools-runInLinuxImage-attributes}

* `diskImage`. The image to run in, such as one of [`vmTools.diskImages`](#vm-tools-diskImages).
* `diskImageFormat` (optional, default `"qcow2"`). The format of `diskImage`.

### Examples {#vm-tools-runInLinuxImage-examples}

Run a command in Debian 13:
```nix
{ pkgs }:
pkgs.vmTools.runInLinuxImage (
  pkgs.runCommand "debian-version" { diskImage = pkgs.vmTools.diskImages.debian13x86_64; } ''
    cat /etc/debian_version > $out
  ''
)
```

## `vmTools.makeImageTestScript` {#vm-tools-makeImageTestScript}

Generate a script that can be used to run an interactive session in the given image.
Run it with the path of a scratch file, which holds the session's changes to the image: `./result /tmp/scratch.qcow2`.
The Nix store is available inside the VM.

### Examples {#vm-tools-makeImageTestScript-examples}

Create a script for running a Fedora 43 VM:
```nix
{ pkgs }: pkgs.vmTools.makeImageTestScript pkgs.vmTools.diskImages.fedora43x86_64
```

Create a script for running an Ubuntu 24.04 VM:
```nix
{ pkgs }: pkgs.vmTools.makeImageTestScript pkgs.vmTools.diskImages.ubuntu2404x86_64
```

## `vmTools.diskImageFuns` {#vm-tools-diskImageFuns}

A set of functions that build a predefined set of minimal Linux distributions images.

### Images {#vm-tools-diskImageFuns-images}

* Fedora
  * `fedora43x86_64`
  * `fedora44x86_64`
* Rocky Linux
  * `rocky9x86_64`
  * `rocky10x86_64`
* AlmaLinux
  * `alma9x86_64`
  * `alma10x86_64`
* Oracle Linux
  * `oracle9x86_64`
  * `oracle10x86_64`
* Amazon Linux
  * `amazon2023x86_64`
* Ubuntu
  * `ubuntu2204i386`
  * `ubuntu2204x86_64`
  * `ubuntu2404x86_64`
  * `ubuntu2604x86_64`
* Debian
  * `debian12i386`
  * `debian12x86_64`
  * `debian13i386`
  * `debian13x86_64`

### Attributes {#vm-tools-diskImageFuns-attributes}

* `size` (optional, defaults to `4096`). The size of the image, in MiB.
* `extraPackages` (optional). A list of names of additional packages from the distribution that should be included in the image.
* `extraDebs` (optional, Debian and Ubuntu only). A list of `.deb` files to install in addition to the distribution's packages.
* `postInstall` (optional). Shell commands to run after the packages are installed.
  They run outside the image, which is mounted at `/mnt`.

In Debian and Ubuntu images, errors from the packages' installation scripts do not fail the build.
If a package does not seem to work, run `dpkg --audit` in the image to check.

### Examples {#vm-tools-diskImageFuns-examples}

8GiB image containing nginx in addition to the default packages:
```nix
{ pkgs }:
pkgs.vmTools.diskImageFuns.debian13x86_64 {
  extraPackages = [ "nginx" ];
  size = 8192;
}
```

Note that some Ubuntu packages, such as `firefox`, only install a stub that expects a snap, which does not work in these images.

Image containing a `.deb` built with [`releaseTools.debBuild`](#vm-tools-packages):
```nix
{ pkgs, myPackage }:
pkgs.vmTools.diskImageFuns.debian13x86_64 {
  extraDebs = [ "${myPackage}/debs/my-package_1.0-1_amd64.deb" ];
}
```

## `vmTools.diskImageExtraFuns` {#vm-tools-diskImageExtraFuns}

Shorthand for `vmTools.diskImageFuns.<attr> { extraPackages = ... }`.

## `vmTools.diskImages` {#vm-tools-diskImages}

Shorthand for `vmTools.diskImageFuns.<attr> { }`.

## Building `.deb` and `.rpm` packages {#vm-tools-packages}

`releaseTools.debBuild` and `releaseTools.rpmBuild` build a source tarball into a distribution package inside one of these images.
`debBuild` runs the usual configure and build phases and packages what `make install` installs, using checkinstall.
`rpmBuild` runs `rpmbuild -ta`, so the tarball has to contain a spec file.

Build GNU hello as a `.deb` for Debian 13:
```nix
{ pkgs }:
pkgs.releaseTools.debBuild {
  name = "hello";
  inherit (pkgs.hello) src;
  diskImage = pkgs.vmTools.diskImages.debian13x86_64;
  debName = "gnu-hello";
  meta.description = "GNU hello, as a .deb";
}
```

The packages end up in `$out/debs` and `$out/rpms` respectively.
Set `installCommand` if the project is not installed with `make install`.
