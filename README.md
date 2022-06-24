# nix

The Nix configuration for my M1 Mac. 

![My NixOS Setup!](nix.png "A screenshot of my NixOS terminals")

The goal here is to:

* Have a _somewhat_ lightweight Linux VM in which to run the Docker daemon.
* Leverage said Linux VM for not-containers things from time to time.
* Manage both the MacOS host and the Linux VM using the same, declarative tool.

I use [nix-darwin] to configure the Mac's command-line environment. I also run a
headless [NixOS] VM in QEMU. My user on both is configured using [home-manager].

To bootstrap a new M1 Mac, first install [iTerm] and load `iterm2.json`, then:

```shell
# Install the Nix package manager.
sh <(curl -L https://nixos.org/nix/install)

# Install nix-darwin
nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
./result/bin/darwin-installer

# Rebuild the Mac
darwin-rebuild switch --flake github:negz/nix#bugg
```

Once the Mac is boostrapped, create a VM:

```shell
# Create a disk for the VM.
FIRMWARE=$PWD/vm/nixos.fd
NIX_ROOT=$PWD/vm/nixos.qcow2
cp $(nix eval --raw 'nixpkgs#qemu')/share/qemu/edk2-aarch64-code.fd $FIRMWARE
qemu-img create -f qcow2 $NIX_ROOT 80G

# Grab an install ISO from Hydra
# https://hydra.nixos.org/job/nixos/release-22.05/nixos.iso_minimal.aarch64-linux/all
NIX_INSTALL=$PWD/vm/install.iso
curl -o $NIX_INSTALL https://hydra.nixos.org/build/181427254/download/1/nixos-minimal-22.05.1191.ccf8bdf7262-aarch64-linux.iso

# Start the VM. Ctrl-A-X to kill the VM.
qemu-system-aarch64 \
    -name mael \
    -machine virt,accel=hvf \
    -cpu host \
    -smp 6,sockets=1,cores=6,threads=1 \
    -m 16384 \
    -boot menu=on \
    -drive if=pflash,format=raw,readonly=on,file=${FIRMWARE} \
    -drive if=none,media=disk,id=drive0,cache=writethrough,file=${NIX_ROOT} \
    -drive if=none,media=cdrom,id=drive1,readonly=on,file=${NIX_INSTALL} \
    -device virtio-rng-pci \
    -device ramfb \
    -device ahci,id=achi0 \
    -device virtio-net-pci,netdev=net0 \
    -device qemu-xhci,id=usb-bus \
    -device usb-kbd,bus=usb-bus.0 \
    -device usb-mouse,bus=usb-bus.0 \
    -device virtio-blk-pci,drive=drive0,bootindex=1 \
    -device usb-storage,drive=drive1,removable=true,bus=usb-bus.0,bootindex=0 \
    -netdev user,id=net0,net=192.168.100.0/24 \
    -parallel none \
    -display none \
    -vga none \
    -serial mon:stdio

# Once the VM is running become root.
sudo -i

# Partition the disk.
parted /dev/vda -- mklabel gpt
parted /dev/vda -- mkpart primary 256MiB 100%
parted /dev/vda -- mkpart ESP fat32 1MiB 256MiB
parted /dev/vda -- set 2 esp on

# Format the disk
mkfs.ext4 -L nixos /dev/vda1
mkfs.fat -F 32 -n boot /dev/vda2

# Mount the disk
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot

# Enable flake support, and install NixOS
# At the time of writing this really needs to be nixUnstable, not nixFlakes to
# workaround https://github.com/nix-community/home-manager/issues/2074
nix-env -iA nixos.nixUnstable
nixos-install --flake github:negz/nix#mael --no-root-password

# Authenticate to Tailscale
nixos-enter -c 'tailscaled 2>/dev/null & tailscale up'

# Shutdown - use ./run.sh to boot into the VM.
shutdown -h now
```

To make `docker` use the VM (from MacOS):

```shell
docker context create --docker host=ssh://negz@mael --description "Virtual Machine via Tailscale"
docker context use mael
```

[nix-darwin]: https://github.com/LnL7/nix-darwin
[NixOS]: https://nixos.org
[home-manager]: https://github.com/nix-community/home-manager
[iTerm]: https://iterm2.com
