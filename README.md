# nix

My Nix configuration. Mostly used to run Docker images without relying on
Docker Desktop on my M1 Mac. You should probably just use Docker Desktop.

To create a VM from an M1 Mac:

```bash
# Install the Nix package manager.
sh <(curl -L https://nixos.org/nix/install)

# Install qemu from master to get https://github.com/NixOS/nixpkgs/pull/164908
nix-env -f https://github.com/NixOS/nixpkgs/archive/master.tar.gz -iA qemu

# Create a disk for the VM.
NIX_ROOT=$PWD/vm/nixos.qcow2
qemu-img create -f qcow2 $NIX_ROOT 80G

# Grab an install ISO from Hydra
# https://hydra.nixos.org/job/nixos/release-21.11/nixos.iso_minimal.aarch64-linux/all
NIX_INSTALL=$PWD/vm/install.iso
curl -o $NIX_INSTALL https://hydra.nixos.org/build/170436603/download/1/nixos-minimal-21.11.336635.31aa631dbc4-aarch64-linux.iso

# Start the VM. Note that unlike the command below this one boots the installer.
# Ctrl-A-X to stop the VM (or ctrl-A-Ctrl-A-X if you bind Ctrl-A to tmux).
qemu-system-aarch64 \
    -name mael \
    -machine virt,accel=hvf,highmem=off \
    -cpu host \
    -smp 4,sockets=1,cores=4,threads=1 \
    -m 4096 \
    -boot menu=on \
    -drive if=pflash,format=raw,readonly=on,file=$HOME/.nix-profile/share/qemu/edk2-aarch64-code.fd \
    -drive if=none,media=disk,id=drive0,cache=writethrough,file=$NIX_ROOT \
    -drive if=none,media=cdrom,id=drive1,readonly=on,file=$NIX_INSTALL \
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
```

Once the VM is running:

```shell
# Become root.
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
nix-env -iA nixos.nixUnstable
nixos-install --flake github:negz/nix#mael --no-root-password

# TODO(negz): nixos-enter to setup tailscale?

# Shutdown - you'll want to restart qemu to boot from the disk
shutdown -h now
```

Now you can run and use your new VM. I typically run this inside `tmux` so I can
keep it running when I'm detached and watch the console. Note that with my setup
neither `root` nor my user (`negz`) has a password, so no-one can login on the
console. Instead I rely on Tailscale working so I can connect using my SSH key.

```
# Ctrl-A-X to stop the VM (or Ctrl-A-Ctrl-A-X if you bind Ctrl-A to tmux).
NIX_ROOT=$PWD/vm/nixos.qcow2
qemu-system-aarch64 \
    -name mael \
    -machine virt,accel=hvf,highmem=off \
    -cpu host \
    -smp 4,sockets=1,cores=4,threads=1 \
    -m 4096 \
    -boot menu=on \
    -drive if=pflash,format=raw,readonly=on,file=$HOME/.nix-profile/share/qemu/edk2-aarch64-code.fd \
    -drive if=none,media=disk,id=drive0,cache=writethrough,file=$NIX_ROOT \
    -device virtio-rng-pci \
    -device ramfb \
    -device virtio-net-pci,netdev=net0,mac=52:55:55:80:ae:7d \
    -device qemu-xhci,id=usb-bus \
    -device usb-kbd,bus=usb-bus.0 \
    -device usb-mouse,bus=usb-bus.0 \
    -device virtio-blk-pci,drive=drive0,bootindex=0 \
    -netdev user,id=net0,net=192.168.100.0/24 \
    -parallel none \
    -display none \
    -vga none \
    -serial mon:stdio
```
