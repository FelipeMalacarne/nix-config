{ inputs, ... }:
{
  flake.nixosModules.saradominDisk =
    { ... }:
    {
      imports = [ inputs.disko.nixosModules.disko ];

      disko.devices = {
        disk.main = {
          device = "/dev/nvme0n1";
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              esp = {
                size = "512M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot/efi";
                  mountOptions = [ "fmask=0077" "dmask=0077" ];
                };
              };
              swap = {
                size = "8G";
                content = {
                  type = "swap";
                  discardPolicy = "both";
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
      };
    };
}
