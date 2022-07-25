This process can be used to install a NixOS machine with an existing working
configuration in this repo.

```console
# Once the installer is running become root.
sudo -i

# Partition the disk.
parted /dev/vda -- mklabel gpt
parted /dev/vda -- mkpart primary 256MiB 100%
parted /dev/vda -- mkpart ESP fat32 1MiB 256MiB
parted /dev/vda -- set 2 esp on

# Format the disk.
export NIX_DISK=sda
mkfs.ext4 -L nixos /dev/${NIX_DISK}1
mkfs.fat -F 32 -n boot /dev/${NIX_DISK}2

# Mount the disk
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot

# Specify which host we're working on.
export NIX_HOST=mael

# Enable flake support, and install NixOS
# At the time of writing this really needs to be nixUnstable, not nixFlakes to
# workaround https://github.com/nix-community/home-manager/issues/2074
nix-env -iA nixos.nixUnstable
nixos-install --flake github:negz/nix#${NIX_HOST} --no-root-password

# Authenticate to Tailscale
nixos-enter -c 'tailscaled 2>/dev/null & tailscale up'

# Shutdown - use ./run.sh to boot into the VM.
shutdown -h now
```