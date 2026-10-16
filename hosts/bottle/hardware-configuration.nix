{ ... }:

{
  # The kernel's default NVMe I/O timeout is short enough for persistent disk
  # I/O to time out. This is the rule from Google's own images. See
  # https://cloud.google.com/compute/docs/troubleshooting/troubleshooting-disk-nvme
  services.udev.extraRules = ''
    KERNEL=="nvme*n*", ENV{DEVTYPE}=="disk", ATTRS{model}=="nvme_card-pd", ATTR{queue/io_timeout}="4294967295"
  '';

  # Partitioned by nixos-anywhere at install time.
  disko.devices.disk.main = {
    type = "disk";
    # C4A only exposes NVMe disks, and bottle has one.
    device = "/dev/nvme0n1";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            # systemd-boot warns if its random seed file is world-readable.
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
