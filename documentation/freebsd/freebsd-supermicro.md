# FreeBSD on Supermicro Server

## Hardware configuration

### Supermicro System

 * **Motherboard:** Supermicro X12SPi-TF
 * **Processor:** Intel Xeon Gold 5317 12 Core 3.0 GHz
 * **Memory:** 256 GB of Samsung DDR4 (PC4-25600), ECC Registered, Dual-rank
 * **Add-in card:** Gigabyte AORUS Gen-4 AIC 4 x M.2 PCIe Expansion Card Adapter
 * **System storage:** Three Samsung 990 PRO 2 TB - NVMe PCIe 4.0 M.2 2280 SSD

### Installation Media

You will need one USB flash drive, only used at install time.

You can avoid this requirement by using Virtual Media via IPMI.

However, with a Supermicro motherboard such as the X12SPi-TF, Virtual Media Support with the HTML5 iKVM requires a special software license from Supermicro: [SFT-DCMS-SINGLE](https://store.supermicro.com/supermicro-server-manager-dcms-license-key-sft-dcms-single.html?utm=smcsoftware).


## Prepare installation media

Download latest FreeBSD 14 image for AMD64 architecture, in `memstick` format.

```
$ wget https://download.freebsd.org/releases/ISO-IMAGES/14.0/FreeBSD-14.0-RELEASE-amd64-memstick.img
```

Find device identifier for USB flash drive to be used for installing FreeBSD by looking at the output of the following command.

```
$ diskutil list
```

Let's assume going forward that the USB flash drive corresponds to `/dev/disk27`.

Make sure to unmount all volumes from the USB flash drive using the Disk Utility application.

Expand the image to USB flash drive using the following command.

```
$ sudo dd if=FreeBSD-14.0-RELEASE-amd64-memstick.img of=/dev/disk27 bs=4m
```


## BIOS configuration

If you intend to use NVMe M.2 drives in a PCIe 4.0 Expansion Card Adapter as noted above, you will need to setup the relevant PCIe slot with PCIe bifurcation, following [these instructions](https://forums.servethehome.com/index.php?threads/supermicro-x11-s-d-px-bifurcation.22598/#post-210803).

Look for the motherboard's block diagram in the user manual.

In this specific scenario, assuming you insert the add-in card in slot 6 of the X12SPi-TF motherboard, then you need to configure PCIe output *IOU0 (IIO PCIe Port 1)* for PCIe bifurcation.

Hence, enter the BIOS, and navigate to:

 * *Advanced* tab
 * *Chipset Configuration* menu
 * *North Bridge* menu
 * *IIO Configuration* menu
 * *CPU1 Configuration* menu

Then select *IOU0 (IIO PCIe Port 1)*, and then select the option `4x4x4x4`.

Then navigate to the *Save & Exit* tab, and select *Save Changes and Reset*.


## Install FreeBSD

 * Boot into the USB flash drive with the FreeBSD image.
 * Go through the initial setup.
 * When the partitioning dialog comes up, choose the *Shell* option.
 * Find the device identifiers of the SSD drives to install the system on by looking at the output of the following command.

```
# camcontrol devlist
```

 * Going forward, let's assume that `nda0`, `nda1` and `nda2` are the device identifiers of the SSD drives to install the system on.
 * Find the serial number of each of the SSD drives by looking at the output of one of the following commands.

```
# dmesg | grep -i nda0 | grep -i serial
# nvmecontrol identify nvme0 | grep -i serial
```

 * Going forward, we will refer to these serial numbers as `sn0`, `sn1` and `sn2` respectively for `nda0`, `nda1` and `nda2`.
 * Destroy previous partition table on the drives, if any.

```
# gpart destroy -F nda0
# gpart destroy -F nda1
# gpart destroy -F nda2
```

 * If those drives have previously been used as vdevs of a previous ZFS pool, you may want to zero out a few sectors at the beginning and at the end of the drives to prevent an annoying warning later on with the `zpool create` command. In order to do that, create a new temporary script named `wipe_drive` with the following command:

```
# cat << 'EOF' > /tmp/wipe_drive
#! /bin/sh
#
# wipe_drive
#
# Utility script to completely wipe the contents of a storage block device.
#
# This is built for FreeBSD, and simply zeroes out a few sectors
# at the beginning and end of the block device.
#

drive_id=$1

if [ -z ${drive_id} ]
then
    /bin/echo "usage: $0 <drive_id>" >&2
    /bin/echo "" >&2
    /bin/echo "Completely wipes the contents of a storage block device." >&2
    /bin/echo "" >&2
    /bin/echo "You may find the valid <drive_id> by using commands such as:" >&2
    /bin/echo "# camcontrol devlist" >&2
    /bin/echo "# nvmecontrol devlist" >&2
    /bin/echo "# geom disk list" >&2
    exit 1
fi

/bin/echo "About to completely wipe the contents of /dev/${drive_id}..."
/bin/echo ""

/sbin/geom disk list ${drive_id}

/bin/echo -n "Are you sure you want to completely wipe the contents of /dev/${drive_id}? [yes/no] "
read confirmation_text

if [ $(/bin/echo ${confirmation_text} | /usr/bin/tr '[:upper:]' '[:lower:]') != yes ]
then
    /bin/echo "Aborting due to non-affirmative answer: ${confirmation_text}." >&2
    exit
fi

/usr/sbin/diskinfo ${drive_id} | \
while read disk sector_size size sectors other
do
    /bin/echo "Deleting MBR, GPT Primary, ZFS(L0L1)/other partition table..."
    /bin/dd if=/dev/zero of=/dev/${drive_id} bs=${sector_size} count=8192
    /bin/echo "Deleting GEOM metadata, GPT Secondary(L2L3)..."
    /bin/dd if=/dev/zero of=/dev/${drive_id} bs=${sector_size} oseek=$(expr ${sectors} - 8192) count=8192
done
EOF
```

 * Make the script executable, and wipe the relevant drives.

```
# chmod +x /tmp/wipe_drive

# /tmp/wipe_drive nda0
# /tmp/wipe_drive nda1
# /tmp/wipe_drive nda2
```

 * Create new GPT partition tables.

```
# gpart create -s gpt nda0
# gpart create -s gpt nda1
# gpart create -s gpt nda2
```

 * Going forward, for partitioning purposes, we'll be using GPT labels that include the serial number of the respective drive, as `-sn0`, `-sn1` and `-sn2`. While this is pretty verbose, the GPT labels will be used very rarely, and for the occasional disaster recovery scenario, it may be more convenient to have the serial number embedded in the GPT label, to make sure no mistake is made about which drive to take offline.
 * Create partitions for ZFS.

```
# gpart add -a 4k -t efi -l boot-sn0 -s 200m nda0
# gpart add -a 4k -t freebsd-swap -l swap-sn0 -s 100g nda0
# gpart add -a 4k -t freebsd-zfs -l system-sn0 nda0

# gpart add -a 4k -t efi -l boot-sn1 -s 200m nda1
# gpart add -a 4k -t freebsd-swap -l swap-sn1 -s 100g nda1
# gpart add -a 4k -t freebsd-zfs -l system-sn1 nda1

# gpart add -a 4k -t efi -l boot-sn2 -s 200m nda2
# gpart add -a 4k -t freebsd-swap -l swap-sn2 -s 100g nda2
# gpart add -a 4k -t freebsd-zfs -l system-sn2 nda2
```

 * Create the ZFS pool.

```
# zpool create -o ashift=12 -o altroot=/mnt -m none system mirror /dev/gpt/system-sn0 /dev/gpt/system-sn1 /dev/gpt/system-sn2
# zfs set mountpoint=/ system
# zfs set checksum=blake3 system
# zfs set compression=lz4 system
# zfs set atime=off system
# zpool set bootfs=system system

# zfs create -o exec=on -o setuid=off system/tmp
# chmod 1777 /mnt/tmp

# zfs create -o compression=gzip -o setuid=off system/home

# zfs create -o canmount=off system/usr
# zfs create system/usr/local
# zfs create -o setuid=off system/usr/ports
# zfs create -o compression=off -o exec=off -o setuid=off system/usr/ports/distfiles
# zfs create -o compression=off -o exec=off -o setuid=off system/usr/ports/packages
# zfs create -o exec=off -o setuid=off system/usr/src
# zfs create system/usr/obj

# zfs create -o canmount=off system/var
# zfs create -o compression=gzip -o exec=off -o setuid=off system/var/backups
# zfs create -o exec=off -o setuid=off system/var/audit
# zfs create -o exec=off -o setuid=off system/var/crash
# zfs create -o exec=off -o setuid=off system/var/db
# zfs create -o exec=on -o setuid=off system/var/db/pkg
# zfs create -o exec=off -o setuid=off -o readonly=on system/var/empty
# zfs create -o compression=gzip -o exec=off -o setuid=off system/var/log
# zfs create -o compression=gzip -o exec=off -o setuid=off -o atime=on system/var/mail
# zfs create -o exec=off -o setuid=off system/var/run
# zfs create -o exec=on -o setuid=off system/var/tmp
# chmod 1777 /mnt/var/tmp
```

 * Prepare EFI mount points.

```
# mkdir /mnt/boot
# cd /mnt/boot
# mkdir efi
# newfs_msdos /dev/gpt/boot-sn0
# mount_msdosfs /dev/gpt/boot-sn0 /mnt/boot/efi
# ln -s efi efi0

# mkdir efi1
# newfs_msdos /dev/gpt/boot-sn1
# mount_msdosfs /dev/gpt/boot-sn1 /mnt/boot/efi1

# mkdir efi2
# newfs_msdos /dev/gpt/boot-sn2
# mount_msdosfs /dev/gpt/boot-sn2 /mnt/boot/efi2
```

 * Prepare `fstab` file.

```
# cat << EOF > /tmp/bsdinstall_etc/fstab
# Device            Mountpoint      FStype      Options         Dump    Pass#
/dev/gpt/boot-sn0   /boot/efi       msdosfs     rw              2       2
/dev/gpt/boot-sn1   /boot/efi1      msdosfs     rw              2       2
/dev/gpt/boot-sn2   /boot/efi2      msdosfs     rw              2       2

/dev/gpt/swap-sn0   none            swap        sw              0       0
/dev/gpt/swap-sn1   none            swap        sw              0       0
/dev/gpt/swap-sn2   none            swap        sw              0       0
EOF
```

 * Type `exit` in the shell and proceed with the installation as normal.
 * Once the installation is complete choose *Exit* from the main menu.
 * The next dialog will will offer the option to *open a shell in the new system*; choose this option.
 * Configure ZFS to load and mount the file systems automatically at boot.

```
# echo 'zfs_enable="YES"' >> /etc/rc.conf
```

 * Replicate contents of EFI boot partition from the first drive to the second drive.

```
# cd /boot/efi1
# cp -av ../efi0/* .

# cd /boot/efi2
# cp -av ../efi0/* .
```


## Upgrade base system

```
# freebsd-update fetch
# freebsd-update install
# reboot
```
