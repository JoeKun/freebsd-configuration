# Upgrade firmware for Broadcom 9500-16i Host Bus Adapter

These instructions are inspired from [this post](https://forums.servethehome.com/index.php?threads/info-on-lsi-sas3408-got-myself-a-530-8i-on-ebay.21588/page-2#post-220335) on the ServeTheHomes forums.

## Download firmware files from Broadcom website

The relevant firmware files can be found [here](https://www.broadcom.com/products/storage/host-bus-adapters/sas-nvme-9500-16i).

Download the following archives:
 * Phase 28 SAS3.5 Package Firmware, BIOS and UEFI: [9500_16i_Pkg_P28_MIXED_FW_BIOS_UEFI](https://docs.broadcom.com/docs/9500_16i_Pkg_P28_MIXED_FW_BIOS_UEFI.zip)
 * Latest HBA PSoC Catalog 1.25: [1.25_PSoC_Catalog_Firmware_HBA](https://docs.broadcom.com/docs/1.25_PSoC_Catalog_Firmware_HBA.zip)
 * STORCLI utility for LSI SAS3.5 Controllers: [STORCLI_SAS3.5_P28](https://docs.broadcom.com/docs/STORCLI_SAS3.5_P28.zip)

## Prepare USB flash drive with firmware files

Prepare a USB flash drive with a single partition with the FAT filesystem and MBR partition table.

Put the following files in a directory named `EFI` in the USB flash drive:
 * `HBA_9500-16i_Mixed_Profile.bin`
 * `IT_HBA_X64_BIOS_PKG_E6.rom`
 * `pblp_catalog.signed.rom`
 * `storcli.efi`

## Boot server to UEFI shell with USB flash drive inserted

Insert the USB flash drive in a suitable USB port, and start the server.

When the Supermicro screen shows with suggestions of keys to press for different actions, press the F11 key to invoke the Boot Menu.

When the Boot Menu appears, select the `UEFI: Built-in EFI Shell`.

When in the UEFI Shell, look for the USB flash drive in the `Mapping table`.
Assuming it corresponds to `FS0:`, select it in the shell, and move to the `EFI` directory:

```
Shell> FS0:
FS0:\> cd EFI
```

## Backup data about host bus adapter before firmware upgrade

Dump list of all devices using `storcli.efi`:

```
FS0:\EFI\> storcli.efi show all > backup_global_show_all
```

Inspect output to find the index of the Broadcom 9500-16i HBA.

```
FS0:\EFI\> cat backup_global_show_all
```

Let's assume it's listed in that output with index 0.

Create backup files for various memory regions or properties of the HBA.

```
FS0:\EFI\> storcli.efi /c0 show all > backup_show_all
FS0:\EFI\> storcli.efi /c0 get bios file=backup_bios
FS0:\EFI\> storcli.efi /c0 get firmware file=backup_firmware
FS0:\EFI\> storcli.efi /c0 get mpb file=backup_mpb
FS0:\EFI\> storcli.efi /c0 get fwbackup file=backup_fwbackup
FS0:\EFI\> storcli.efi /c0 get nvdata file=backup_nvdata
FS0:\EFI\> storcli.efi /c0 get flash file=backup_flash
FS0:\EFI\> storcli.efi /c0 show sasadd > backup_sasadd
```

## Flash firmware

Flash relevant memory regions of the HBA.

```
FS0:\EFI\> storcli.efi /c0 download file=HBA_9500-16i_Mixed_Profile.bin
FS0:\EFI\> storcli.efi /c0 download bios file=IT_HBA_X64_BIOS_PKG_E6.rom
FS0:\EFI\> storcli.efi /c0 download psoc file=pblp_catalog.signed.rom
```

Power reset the server, and get back into the UEFI Shell the same way you did before.

## Backup data about host bus adapter after firmware upgrade

Create a copy of the current state of the `EFI` directory.

```
Shell> FS0:
FS0:\> mkdir before
FS0:\> cp -r EFI before
FS0:\> cd EFI
```

Move previous backup files:

```
FS0:\EFI\> mkdir orig
FS0:\EFI\> mv backup_* orig
```

Create new backup files for various memory regions of properties of the HBA.

```
FS0:\EFI\> storcli.efi show all > backup_global_show_all
FS0:\EFI\> storcli.efi /c0 show all > backup_show_all
FS0:\EFI\> storcli.efi /c0 get bios file=backup_bios
FS0:\EFI\> storcli.efi /c0 get firmware file=backup_firmware
FS0:\EFI\> storcli.efi /c0 get mpb file=backup_mpb
FS0:\EFI\> storcli.efi /c0 get fwbackup file=backup_fwbackup
FS0:\EFI\> storcli.efi /c0 get nvdata file=backup_nvdata
FS0:\EFI\> storcli.efi /c0 get flash file=backup_flash
FS0:\EFI\> storcli.efi /c0 show sasadd > backup_sasadd
```