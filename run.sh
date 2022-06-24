#/usr/bin/env zsh

FIRMWARE=$PWD/vm/nixos.fd
NIX_ROOT=$PWD/vm/nixos.qcow2
qemu-system-aarch64 \
    -name mael \
    -machine virt,accel=hvf \
    -cpu host \
    -smp 6,sockets=1,cores=6,threads=1 \
    -m 16348 \
    -boot menu=on \
    -drive if=pflash,format=raw,readonly=on,file=${FIRMWARE} \
    -drive if=none,media=disk,id=drive0,cache=writethrough,file=${NIX_ROOT} \
    -fsdev local,path=/Users/negz,id=fs0,security_model=mapped-xattr \
    -netdev user,id=net0,net=192.168.100.0/24 \
    -device virtio-rng-pci \
    -device ramfb \
    -device virtio-net-pci,netdev=net0,mac=52:55:55:80:ae:7d \
    -device qemu-xhci,id=usb-bus \
    -device usb-kbd,bus=usb-bus.0 \
    -device usb-mouse,bus=usb-bus.0 \
    -device virtio-blk-pci,drive=drive0,bootindex=0 \
    -device virtio-9p-pci,fsdev=fs0,mount_tag=/Users/negz \
    -parallel none \
    -display none \
    -vga none \
    -serial mon:stdio
