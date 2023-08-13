{ modulesPath, ... }: {
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  boot.loader.grub.device = "/dev/vda";
  boot.initrd.availableKernelModules =
    [ "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi" ];
  boot.initrd.kernelModules = [ "nvme" ];
  fileSystems."/" = {
    device = "/dev/vdb";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/vda1";
    fsType = "ext4";
  };
  boot.kernelParams = [ "console=ttyS0,115200" ];
}
