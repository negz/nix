This process can be used to install a NixOS machine with an existing working
configuration in this repo.

It assumes a Parallels VM booted from a minimal NixOS installer ISO from
https://nixos.org/download/.

```console
# Once the installer is running become root.
sudo -i

# Partition the disk.
export NIX_DISK=sda
parted /dev/${NIX_DISK} -- mklabel gpt
parted /dev/${NIX_DISK} -- mkpart primary 256MiB 100%
parted /dev/${NIX_DISK} -- mkpart ESP fat32 1MiB 256MiB
parted /dev/${NIX_DISK} -- set 2 esp on

# Format the disk.
mkfs.ext4 -L nixos /dev/${NIX_DISK}1
mkfs.fat -F 32 -n boot /dev/${NIX_DISK}2

# Mount the disk
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot

# Specify which host we're working on.
export NIX_HOST=mael
nixos-install --flake github:negz/nix#${NIX_HOST} --no-root-password

# Shutdown - use ./run.sh to boot into the VM.
shutdown -h now
```