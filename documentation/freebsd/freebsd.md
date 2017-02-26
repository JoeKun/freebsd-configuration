# FreeBSD on Mac Mini with External Thunderbolt Enclosure

## Hardware configuration

 * Mac Mini Late 2014
    - 3.0 GHz Dual-Core Intel Core i7
    - 16 GB 1600MHz LPDDR3 SDRAM
    - 256 GB PCIe-based Flash Storage

 * OWC ThunderBay 4
    - Two Western Digital Red 6 TB NAS Hard Drive 3.5-inch SATA 6 Gbps
 
 * Two USB drives (only used at install time)

## Prepare main drive

The main drive that ships with the Mac Mini uses Core Storage. We'd like to use some of that disk space for partitions dedicated to FreeBSD, so we need to disable Core Storage.

To do that, we will re-install OS X El Capitan from scratch.

### Prepare a USB drive with a bootable image of the OS X El Capitan installer

 * Boot the Mac Mini to OS X El Capitan, and go to the App Store.
 * Search for "OS X El Capitan", and download it. You may get some warning about OS X El Capitan already being installed; just ignore the warning and confirm the download.
 * Once the download has complete, the OS X El Capitan setup assistant will launch. Just quit it.
 * Plug a USB drive.
 * Using the "Disk Utility" application, re-partition the USB drive with a GUID Partition Table, and a single partition with an HFS+ volume named "USB".
 * Open Terminal, and enter the following command:
 
   `$ sudo /Applications/Install\ OS\ X\ El\ Capitan.app/Contents/Resources/createinstallmedia --volume /Volumes/Untitled --applicationpath /Applications/Install\ OS\ X\ El\ Capitan.app --nointeraction`

### Re-install OS X El Capitan

 * Boot into the USB drive.
 * Launch Terminal.
 * Run the following command.
 
    `$ diskutil cs list`
 
 * In the output, find and copy the "Logical Volume Group" identifier.
 * Delete the logical volume group using:

    `$ sudo diskutil cs delete <Logical Volume Group Identifier>`

 * Exit Terminal.
 * Launch Disk Utility.
 * Repartition drive with a GUID Partition Table, and a single partition with an HFS+ volume named "Macintosh HD". This can be done very easily using the Erase button in the toolbar.
 * Exit Disk Utility.
 * Proceed installing OS X El Capitan onto this new "Macintosh HD" volume.

### Disable System Integrity Protection

After completing the install and going through the first launch setup assistant,  we need to disable System Integrity Protection, which will prevent us from changing the boot volume later on.

 * Restart the computer, while booting hold down Command-R to boot into recovery mode.
 * Once booted, navigate to the “Utilities > Terminal” in the top menu bar.
 * Enter `csrutil disable` in the terminal window and hit the return key.
 * Restart the machine and System Integrity Protection will now be disabled.

### Make room for FreeBSD partitions in the main drive

Now we need to make some room for FreeBSD partitions.

In Terminal, execute the following commands:

```
$ diskutil resizeVolume disk0s2 120G
$ diskutil resizeVolume disk0s2 100G
```

## Prepare installation media

 * Download latest FreeBSD 11 image for AMD64 architecture, in `memstick` format.

   `$ wget ftp://ftp.freebsd.org/pub/FreeBSD/releases/amd64/amd64/ISO-IMAGES/11.0/FreeBSD-11.0-BETA4-amd64-memstick.img`

 * Find device identifier for USB drive to be used for installing FreeBSD by looking at the output of the following command.

   `$ diskutil list`

    Let's assume going forward that the USB drive corresponds to `/dev/disk2`.

 * Make sure to unmount all volumes from the USB drive using the Disk Utility application.

 * Expand image to USB drive using the following command.

   `$ sudo dd if=FreeBSD-11.0-BETA4-amd64-memstick.img of=/dev/disk2 bs=4m`
   
 * For the installation process, you will also need a second USB drive with a FAT partition, to help transfer one critical file from FreeBSD's boot volume an HFS+ partition.

## Install FreeBSD

 * Boot into the USB drive drive with the FreeBSD image, while keeping the second USB drive plugged in.
 * Go through the initial setup.
 * When the partitioning dialogue comes up, choose the "Shell" option.
 * Find the device identifiers or the main drive and the two drives in the Thunderbolt enclosure by looking at the output of the following command.
 
   `# camcontrol devlist`

   Going forward, let's assume that `ada2` is the device identifier of the main drive, and that `ada0` and `ada1` are the device identifiers of the two drives in the Thunderbolt enclosure. Let's also assume that `da1` is the device identifier of the second USB drive with the FAT partition.
 
 * Check the initial state of the main drive by looking at the output of the following command.
 
   `# gpart show ada2`
 
   Going forward, let's assume it had 3 partitions set up:
   
    * An EFI System Partition of about 200 MB.
    * The "Macintosh HD" HFS+ partition of 93 GB (OS X counts GB differently from other OSes).
    * The Recovery partition of type "apple-boot", of about 620 MB.

 * In the main drive, we need to add a small HFS+ partition which will be visible by the Mac Boot Manager as well as OS X's System Preferences to boot into FreeBSD. We will also need a swap partition.
 
   ```
   # gpart add -s 200m -a 4k -t apple-hfs -l FreeBSD ada2
   # gpart add -s 8g -a 4k -t freebsd-swap -l swap ada2
   # gpart add -a 4k -t freebsd-zfs -l ssd ada2
   ```

 * Verify the end result by looking at the output of the following command.
 
   `# gpart show ada2`
 
 * Destroy previous partition table on the disks, if any.

   ```
   # gpart destroy -F ada0
   # gpart destroy -F ada1
   ```

 * If those disks have previously been used as vdevs of a previous ZFS pool, you may want to zero out a few sectors at the beginning and at the end of the disks to prevent an annoying warning later on with the `zpool create` command.
 
   ```
   # dd if=/dev/zero of=/dev/ada0 bs=1m count=1
   # dd if=/dev/zero of=/dev/ada0 bs=1m oseek=`diskinfo ada0 | awk '{print int($3 / (1024*1024)) - 4;}'`
   
   # dd if=/dev/zero of=/dev/ada1 bs=1m count=1
   # dd if=/dev/zero of=/dev/ada1 bs=1m oseek=`diskinfo ada1 | awk '{print int($3 / (1024*1024)) - 4;}'`
   ```

 * Create new GPT partitioned disks.

   ```
   # gpart create -s gpt ada0
   # gpart create -s gpt ada1
   ```
 
 * Create partitions for ZFS.
 
   ```
   # gpart add -a 4k -t freebsd-zfs -l owc0.0 ada0
   # gpart add -a 4k -t freebsd-zfs -l owc0.1 ada1
   ```
 
 * For FreeBSD 10.1, we used to need to set a VFS tunable to make sure ZFS will setup the pool optimized for 4k (i.e. Advanced Format) drives, like so:
 
   `# sysctl vfs.zfs.min_auto_ashift=12`

However, it seems like that VFS tunable doesn't exist in FreeBSD 11 anymore, as running this command produces an error. Nevertheless, the ZFS pool we're about to create with the following commands will have the correct `ashift` value, as you can verify later on by checking the output of `zdb`.
 
 * Create the ZFS pool.
 
   ```
   # zpool create -o altroot=/mnt -m none storage mirror /dev/gpt/owc0.0 /dev/gpt/owc0.1
   # zfs set mountpoint=/ storage
   # zfs set checksum=fletcher4 storage
   # zfs set atime=off storage
   # zpool set bootfs=storage storage
   
   # zfs create -o compression=lz4 -o setuid=off storage/tmp
   # chmod 1777 /mnt/tmp
   
   # zfs create -o compression=gzip -o setuid=off storage/home
   
   # zfs create -o compression=lz4 storage/usr
   # zfs create storage/usr/local
   # zfs create -o setuid=off storage/usr/ports
   # zfs create -o compression=off -o exec=off -o setuid=off storage/usr/ports/distfiles
   # zfs create -o compression=off -o exec=off -o setuid=off storage/usr/ports/packages
   # zfs create -o exec=off -o setuid=off storage/usr/src
   # zfs create storage/usr/obj
   
   # zfs create -o compression=lz4 storage/var
   # zfs create -o compression=gzip -o exec=off -o setuid=off storage/var/backups
   # zfs create -o exec=off -o setuid=off storage/var/crash
   # zfs create -o exec=off -o setuid=off storage/var/db
   # zfs create -o exec=on -o setuid=off storage/var/db/pkg
   # zfs create -o exec=off -o setuid=off storage/var/empty
   # zfs create -o compression=gzip -o exec=off -o setuid=off storage/var/log
   # zfs create -o compression=gzip -o exec=off -o setuid=off storage/var/mail
   # zfs create -o exec=off -o setuid=off storage/var/run
   # zfs create -o exec=on -o setuid=off storage/var/tmp
   # chmod 1777 /mnt/var/tmp
   ```
 
 * Prepare `fstab` file.
 
   ```
   # cat << EOF > /tmp/bsdinstall_etc/fstab
 # Device                       Mountpoint              FStype  Options         Dump    Pass#
 /dev/gpt/swap                  none                    swap    sw              0       0
 EOF
   ```
 
 * Type `exit` in the shell and proceed with the installation as normal.
 * Once the installation is complete choose "Exit" from the main menu.
 * The next dialogue will will offer the option to "open a shell in the new system", choose this option.
 * Configure ZFS to load and mount the file systems automatically at boot.
 
   ```
   # mount -t devfs devfs /dev
   # echo 'zfs_enable="YES"' >> /etc/rc.conf
   # echo 'vfs.root.mountfrom="zfs:storage"' >> /boot/loader.conf
   ```
 
 * Workaround an issue with the AHCI driver.
 
   ```
   echo 'hint.ahci.0.msi="0"' >> /boot/loader.conf
   ```
 
 * Set read only on `/var/empty`, it is supposed to be empty at all times.
   
   ```
   # zfs set readonly=on storage/var/empty
   ```
   
 * Copy `/boot/boot1.efi` to the FAT partition in the second USB drive.
 
   ```
   # mkdir /tmp/fat
   # mount -t msdosfs /dev/da1s1 /tmp/fat
   # cp /boot/boot1.efi /tmp/fat
   # umount /tmp/fat
   # rmdir /tmp/fat
   ```

## Make the FreeBSD install bootable

 * Reboot, and hold the option key when the Mac starts up again.
 * Select the Macintosh HD partition in the Mac Boot Manager.
 * Prepare the second HFS+ volume with 200 MB of space to allow booting FreeBSD,  with what we need to have it show up in System Preferences or in the Mac Boot Manager.
 
   ```
   $ diskutil eraseVolume JHFS+ FreeBSD /dev/disk0s4
   $ mkdir -p /Volumes/FreeBSD/System/Library/CoreServices
   $ cp /Volumes/FAT/boot1.efi /Volumes/FreeBSD/System/Library/CoreServices/boot.efi
   $ cp /path/to/freebsd-configuration/documentation/freebsd/SystemVersion.plist /Volumes/FreeBSD/System/Library/CoreServices
   $ cp /path/to/freebsd-configuration/documentation/freebsd/FreeBSD.icns /Volumes/FreeBSD/.VolumeIcon.icns
   $ touch /Volumes/FreeBSD/mach_kernel
   $ SetFile -a V /Volumes/FreeBSD/mach_kernel
   $ sudo chown -R root:wheel /Volumes/FreeBSD/{mach_kernel,System}
   $ sudo chmod 644 /Volumes/FreeBSD/System/Library/CoreServices/boot.efi
   $ sudo bless --folder /Volumes/FreeBSD --label "FreeBSD"
   $ sudo bless --mount /Volumes/FreeBSD --setBoot
   ```

 * Reboot.

## Upgrade base system

```
# freebsd-update fetch
# freebsd-update install
# reboot
```

## Prepare `pkg`

```
# pkg update
```

## Install base packages

```
# pkg install git
```
