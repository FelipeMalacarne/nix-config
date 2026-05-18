{
  flake.nixosModules.zarosHardware = {
    config,
    lib,
    modulesPath,
    ...
  }:
  {
    imports = [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

    boot.initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "ahci"
      "usb_storage"
      "usbhid"
      "sd_mod"
    ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-amd" ];
    boot.extraModulePackages = [ ];

    fileSystems."/" = {
      device = "/dev/disk/by-uuid/6b85d1a7-4aaf-428d-afa6-8365249f9c2b";
      fsType = "ext4";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/E936-7E6F";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };

    fileSystems."/mnt/games" = {
      device = "/dev/disk/by-uuid/8701a071-fed6-475b-a14c-40ef8e46e76a";
      fsType = "ext4";
      options = [
        "defaults"
        "nofail"
        "user"
        "exec"
      ];
    };

    swapDevices = [
      { device = "/dev/disk/by-uuid/736bdac5-bc95-48a4-977e-cf74946e1fb6"; }
    ];

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
