{ config, lib, pkgs, ... }:

let
  # Note: ntfs-3g does not support remount, so it will fail.
  # From: https://github.com/ValveSoftware/Proton/wiki/Using-a-NTFS-disk-with-Linux-and-Windows
  ntfsOptions = [
    "gid=100" # users # Not sure if this can be read throught `config`
    "uid=1000" # nithi
    "umask=000"
    "dmask=027"
    "fmask=027"
    "rw"
    "exec"
    "x-gvfs-show"
  ];
in
{
  config = {
    # Unlock the secondary NVMe drive at early userspace and not during boot, using crypttab.
    environment.etc.crypttab.text = ''
      secondary_nvme_crypt UUID=7a2d1004-d7c7-40b7-aed4-4818b7f4961a ${config.age.secrets.secondary_nvme_key.path}
    '';

    swapDevices = [{
      device = "/var/lib/swapfile";
      size = 8 * 1024;
    }];

    fileSystems."/mnt/external_nvme" = {
      device = "/dev/disk/by-uuid/68c3c87d-7176-4e74-abc0-6c050e886a45";
      fsType = "ext4";
      options = [
        "defaults"
        "rw"
        "nofail" # This is an external drive
        "noexec"
        "relatime"
      ];
    };

    fileSystems."/mnt/secondary_nvme" = {
      # sudo cryptsetup luksAddKey /dev/nvme1n1p1 /run/agenix/secondary_nvme_key
      device = "/dev/mapper/secondary_nvme_crypt";
      fsType = "ext4";
      options = [
        "defaults"
        "relatime"
        "x-gvfs-show"
      ];
    };

    fileSystems."/mnt/cold_storage" = {
      device = "/dev/disk/by-uuid/6cfd26d4-00bf-46e9-a1be-5155aee520a0";
      fsType = "ext4";
      options = [
        "defaults"
        "relatime"
        "x-gvfs-show"
      ];
    };

    fileSystems."/mnt/bulk_shared" = {
      device = "/dev/disk/by-uuid/586518A25EA93E13";
      fsType = "ntfs-3g";
      options = ntfsOptions;
    };

    fileSystems."/mnt/fast_shared" = {
      device = "/dev/disk/by-uuid/1E8C79ED8C79C037";
      fsType = "ntfs-3g";
      options = ntfsOptions;
    };
  };
}
