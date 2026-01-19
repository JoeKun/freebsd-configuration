# FreeBSD guest virtual machine in FreeBSD host with `bhyve`

This is partly inspired from [`vermaden`’s great article on `bhyve`](https://vermaden.wordpress.com/2023/08/18/freebsd-bhyve-virtualization/).

## Initial `bhyve` configuration for FreeBSD host

Install `vm-bhyve` with its associated firmware package for booting virtual machines with UEFI.

```console
# pkg install vm-bhyve bhyve-firmware
```

Load required kernel modules.

```console
# kldload if_bridge
# kldload if_tap
# kldload nmdm
# kldload vmm
```

Also add directives in `/boot/loader.conf` to load those same kernel modules at boot time.

```console
# cat << EOF >> /boot/loader.conf

# Virtual machine support
if_bridge_load="YES"
if_tap_load="YES"
nmdm_load="YES"
vmm_load="YES"
EOF
```

Create new dataset for virtual machines.

```console
# zfs create -o exec=off -o setuid=off system/var/virtual-machines
```

Enable the `vm` service.[^1]

[^1]: System configuration options are placed in discrete system configuration files according to the principles outlined in [Modular system configuration on FreeBSD](freebsd-modular-system-configuration.md).

```console
# cat << EOF > /etc/rc.conf.d/vm
# /etc/rc.conf.d/vm: system configuration for vm

vm_enable="YES"
vm_dir="zfs:system/var/virtual-machines"
EOF
```

Also enable the `vm_network` service.[^2]

[^2]: As shown in [Modular system configuration on FreeBSD](freebsd-modular-system-configuration.md).

```console
# cat << EOF > /etc/rc.conf.d/vm_network
# /etc/rc.conf.d/vm_network: system configuration for vm_network

vm_enable="YES"
EOF
```

Prepare scaffolding for virtual machines.

```console
# vm init
# cp -f /usr/local/share/examples/vm-bhyve/* /var/virtual-machines/.templates/
```

Also install `tmux`, which is much easier to work with than the default console for `vm-bhyve`.

```console
# pkg install tmux
```

And enable `tmux` as the default console.

```console
# echo "console=tmux" >> /var/virtual-machines/.config/system.conf
```


## Host-side networking configuration for `bhyve` virtual machines

Setup NAT network for virtual machines following [this guide](https://github.com/churchers/vm-bhyve/wiki/NAT-Configuration).

```console
# vm switch create -a 172.16.0.1/24 public
```

Enable `gateway` functionality.[^3]

[^3]: As shown in [Modular system configuration on FreeBSD](freebsd-modular-system-configuration.md).

```console
# cat << EOF > /etc/rc.conf.d/routing
# /etc/rc.conf.d/routing: system configuration for routing

gateway_enable="YES"
EOF
```

Create `pf` configuration file to setup NAT for this new internal virtual machines network.

```console
# cat << 'EOF' > /etc/pf.conf
# /etc/pf.conf: Configuration for Packet Filter

#-----------------------------------------------------------
# Variables
#-----------------------------------------------------------

ext_if = "ix0"

vm_if = "vm-public"
vm_subnet = "{172.16.0.1/24}"


#-----------------------------------------------------------
# Tables
#-----------------------------------------------------------

# NAT for bhyve virtual machines.
nat on $ext_if inet from $vm_subnet to any -> ($ext_if)
EOF
```

Enable `pf` service.[^4]

[^4]: As shown in [Modular system configuration on FreeBSD](freebsd-modular-system-configuration.md).

```console
# cat << EOF > /etc/rc.conf.d/pf
# /etc/rc.conf.d/pf: system configuration for pf

pf_enable="YES"
EOF
```

Start `pf` and enable gateway functionality without rebooting.

```console
# sysctl net.inet.ip.forwarding=1
# service pf start
```


## Boot into FreeBSD installer in a new `bhyve` virtual machine

Create new virtual machine template for FreeBSD using the `uefi` boot loader, as well as the `nvme` driver for the storage block device.

```console
# cd /var/virtual-machines/.templates
# cp -av freebsd-zvol.conf freebsd-uefi-nvme-zvol.conf
# sed -i '' 's/loader="bhyveload"/loader="uefi"/' freebsd-uefi-nvme-zvol.conf
# sed -i '' 's/_type="virtio-blk"/_type="nvme"/' freebsd-uefi-nvme-zvol.conf
```

Download an ISO image for FreeBSD 14.0-RELEASE.

```console
# vm iso "https://download.freebsd.org/releases/ISO-IMAGES/14.0/FreeBSD-14.0-RELEASE-amd64-disc1.iso"
```

Create a new virtual machine using the template `freebsd-uefi-nvme-zvol` and with an appropriate amount of system resources.

```console
# vm create -t freebsd-uefi-nvme-zvol -s 512G -m 32G -c 16 my_vm
```

Start installing the previously downloaded ISO image onto this new `my_vm` virtual machine:

```console
# vm install my_vm FreeBSD-14.0-RELEASE-amd64-disc1.iso
```

Attach the console to the newly started virtual machine.

```console
# vm console my_vm
```

Once the FreeBSD installer has started, you will be asked to choose the console type you want to use:

```
Welcome to FreeBSD!

Please choose the appropriate terminal type for your system.
Common console types are:
   ansi     Standard ANSI terminal
   vt100    VT100 or compatible terminal
   xterm    xterm terminal emulator (or compatible)

Console type [vt100]:
```

Type `xterm` and hit the return key.


## Install FreeBSD as a guest in a the `bhyve` virtual machine

Go through the initial setup, until the partitioning dialog comes up.

### Manual partitioning

In the *Partitioning* dialog, choose the *Shell* option.

```console
# gpart create -s gpt nda0

# gpart add -a 4k -t efi -l boot -s 200m nda0
# gpart add -a 4k -t freebsd-swap -l swap -s 10g nda0
# gpart add -a 4k -t freebsd-zfs -l system nda0
```

Create the ZFS pool.

```console
# zpool create -o ashift=12 -o altroot=/mnt -m none system /dev/gpt/system
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

Prepare EFI mount point.

```console
# mkdir /mnt/boot
# cd /mnt/boot
# mkdir efi
# newfs_msdos /dev/gpt/boot
# mount_msdosfs /dev/gpt/boot /mnt/boot/efi
```

Prepare `fstab` file.

```console
# cat << EOF > /tmp/bsdinstall_etc/fstab
# Device            Mountpoint      FStype      Options         Dump    Pass#
/dev/gpt/boot       /boot/efi       msdosfs     rw              2       2

/dev/gpt/swap       none            swap        sw              0       0
EOF
```

Type `exit` in the shell and proceed with the installation as normal.

### Network configuration

When the *Network Configuration* dialog comes up, configure IPv4 for the virtual network adapter, but without using DHCP. Instead, use the following static configuration.

 * *IP Address*: `172.16.0.10`
 * *Subnet Mask*: `255.255.255.0`
 * *Default Router*: `172.16.0.1`

Decline configuring IPv6 for the virtual network adapter.

Then the *Resolver Configuration* dialog comes up, use the following DNS settings.

 * *Search*: none (leave empty)
 * IPv4 DNS #1: `10.0.0.1`
 * IPv4 DNS #2: none (leave empty)

### Complete installation

Continue going through the remaining installation dialogs.

When the *System Hardening* dialog comes up, select the following options.

 * `0 hide_uids`: Hide processes running as other users
 * `1 hide_gids`: Hide processes running as other groups
 * `2 hide_jail`: Hide processes running in jails
 * `3 read_msgbuf`: Disable reading kernel message buffer for unprivileged users
 * `5 random_pid`: Randomize the PID of newly created processes
 * `6 clear_tmp`: Clean the /tmp filesystem on system startup
 * `7 disable_syslogd`: Disable opening Syslogd network socket (disables remote logging)
 * `8 secure_console`: Enable console password prompt
 * `9 disable_ddtrace`: Disallow DTrace destructive-mode

When the *Final Configuration* dialog comes up, select *Exit* from the main menu.

The next dialog will will offer the option to *open a shell in the new system*; choose this option.

Configure ZFS to load and mount the file systems automatically at boot.

```console
# echo 'zfs_enable="YES"' >> /etc/rc.conf
```

Power the virtual machine off.

```console
# poweroff
```


## Upgrade base system

On the host server, start the virtual machine back up.

```console
# vm start my_vm
```

Back in the virtual machine, upgrade the base system.

```console
# freebsd-update fetch
# freebsd-update install
# reboot
```
