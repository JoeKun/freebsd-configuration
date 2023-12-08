# Custom package management for FreeBSD with `poudriere`

## General approach

For small scale FreeBSD environments, such as those involving a single FreeBSD server, using `poudriere` directly on that server can lead to longer downtime during upgrades to a new major version of FreeBSD.

Indeed, for such upgrades, the ABI usually changes, and requires all compiled software outside of the base operating system being re-compiled, and reinstalled.

Even though `poudriere` can build packages for different versions of FreeBSD, because it relies on `jail`, and a `jail` uses the same FreeBSD kernel as the host, it's not supported to run a `jail` for a new major version of FreeBSD before upgrading at least the base system.

In other words, with `poudriere`, we can easily build binary packages for *older* versions of FreeBSD, but we can't quite as easily build binary packages for *newer* versions of FreeBSD.

This conundrum was actually discussed in the `freebsd-ports` mailing list a few years ago, in this thread: [Correct order when upgrading to 11.0 Release with Poudriere](https://lists.freebsd.org/pipermail/freebsd-ports/2017-January/106807.html).

That's why it can be helpful to use a separate server dedicated to building binary packages with `poudriere`.

In this procedure, the approach followed will be to setup a dedicated virtual machine for `poudriere`, so it can be upgraded to a future major version of FreeBSD ahead of its host, and thus, enable upgrades of the host with shorter downtime.


## Specific goals

 * Install `poudriere` on a dedicated virtual machine with `bhyve`.
 * Configure the FreeBSD host server to use exclusively the binary packages produced by `poudriere` running on that virtual machine.
 * Setup storage for built packages in such a way that the virtual machine can remain powered off most of the time, only powering it on when actually using `poudriere` to build packages.
 * Expose `poudriere`'s web interface right from the FreeBSD host server.


## Pre-requisites

First, enable and start NFS-related services.  
See [Network file sharing with NFS on FreeBSD](freebsd-network-file-sharing-nfs.md).

Second, create a FreeBSD guest virtual machine for `poudriere`.  
See [FreeBSD guest virtual machine in FreeBSD host with `bhyve`](freebsd-bhyve-freebsd-guest.md).

Going forward, let's assume the virtual machine name is `my_poudriere`. Furthermore, the following commands are assumed to be executed on this virtual machine, unless otherwise noted.

Several things below use `my_poudriere` to identify a component that pertains to this setup, whether it be certificate file names, jail names, names of configuration files or repositories.

If you have a more creative name for your virtual machine, I suggest you change those things to `poudriere-<virtual_machine_name>`.


## Install `git`

First, install `git` using the default FreeBSD-maintained binary package repository.

```
# pkg install git
```

Add basic configuration for `git`.

```
# git config --global user.name "John Smith"
# git config --global user.email "john@smith.com"
```


## Generate SSL certificate for packages

Prepare directories for the certificate and private key.

```
# mkdir -p /usr/local/etc/ssl/certs
# mkdir -p /usr/local/etc/ssl/private
# chmod 700 /usr/local/etc/ssl/private
```

Generate a 4096-bit RSA key.

```
# openssl genrsa -out /usr/local/etc/ssl/private/my_poudriere.key 4096
# chmod 600 /usr/local/etc/ssl/private/my_poudriere.key
```

Generate public certificate gets generated from the private key.

```
# openssl rsa -in /usr/local/etc/ssl/private/my_poudriere.key -pubout -out /usr/local/etc/ssl/certs/my_poudriere.cert
```


## Install `poudriere`

Next, install `poudriere` using the default FreeBSD-maintained binary package repository.

```
# pkg install poudriere
```


## File system configuration for `poudriere`

### Share datasets from FreeBSD host for packages and logs

On the FreeBSD host `my_server`, create a dedicated dataset for `poudriere` data in the `system` pool, as well as children datasets for `packages` and `logs`.

```
# zfs create system/var/poudriere
# zfs create system/var/poudriere/packages
# zfs create system/var/poudriere/logs
```

Make sure you have an entry for the `my_poudriere` virtual machine in `/etc/hosts`, and set the `sharenfs` property on both of these datasets.

```
# zfs set sharenfs='-alldirs,-maproot=root,my_poudriere' system/var/poudriere/packages
# zfs set sharenfs='-alldirs,-maproot=root,my_poudriere' system/var/poudriere/logs
```

### Mount network shares in the `poudriere` virtual machine

Back on the `my_poudriere` virtual machine, create a dedicated dataset for `poudriere`, and corresponding directories for `packages` and `logs`.

```
# zfs create system/usr/local/poudriere
# mkdir -p /usr/local/poudriere/data/packages
# mkdir -p /usr/local/poudriere/data/logs
```

Make sure you have an entry for the `my_server` host in `/etc/hosts`, and mount the `packages` and `logs` network shares inside this new `poudriere` dataset.

```
# mount -t nfs -o rw my_server:/var/poudriere/packages /usr/local/poudriere/data/packages
# mount -t nfs -o rw my_server:/var/poudriere/logs /usr/local/poudriere/data/logs
```

To make sure these shares are automatically mounted upon startup, add a couple of new lines to your `/etc/fstab`.

```
# cat << EOF >> /etc/fstab

# Poudriere data
my_server:/var/poudriere/packages		/usr/local/poudriere/data/packages		nfs		rw		0		0
my_server:/var/poudriere/logs			/usr/local/poudriere/data/logs			nfs		rw		0		0
EOF
```


## Basic configuration for `poudriere`

Update `/usr/local/etc/poudriere.conf` to disable the usage of ZFS by `poudriere`.

```
NO_ZFS=yes
```

Set a specific host name for downloading the FreeBSD base system for jails.

```
FREEBSD_HOST=https://download.FreeBSD.org
```

Specify where the private key for signing packages can be found.

```
PKG_REPO_SIGNING_KEY=/usr/local/etc/ssl/private/my_poudriere.key
```

Change a few settings to correctly check for certain types of updates to ports.

```
CHECK_CHANGED_OPTIONS=verbose
[...]
CHECK_CHANGED_DEPS=yes
```

Enable building ports using multiple concurrent jobs.

```
ALLOW_MAKE_JOBS=yes
```

Finally, set a base URL for `poudriere`'s web interface.

```
URL_BASE=http://pkg.my_domain.tld
```


## Setup build environment for `poudriere`

Create dedicated jail for `poudriere` to build binary packages for the `amd64` architecture, for the `14.0-RELEASE` version of FreeBSD.

```
# poudriere jail -c -j my_poudriere-amd64-14-0 -v 14.0-RELEASE
```

Clone a new ports tree for the current quarterly branch from FreeBSD's official ports tree: `2023Q4`.

```
# poudriere ports -c -p 2023Q4 -B 2023Q4
```

In addition to that, let's clone a `default` ports tree so we'll be able to easily set default options that will apply to all ports trees.

```
# poudriere ports -c -B 2023Q4
```


## Create initial list of packages to build

For now, let's start with building our own version of the packages we installed above from the default FreeBSD-maintained binary package repository.

```
# cat << EOF > /usr/local/etc/poudriere.d/pkglist
# /usr/local/etc/poudriere.d/pkglist

ports-mgmt/pkg
ports-mgmt/poudriere
devel/git
sysutils/vm-bhyve
sysutils/bhyve-firmware
sysutils/tmux
EOF
```


## Build initial package set

Start an initial build using the `bulk` command.

```
# poudriere bulk -j my_poudriere-amd64-14-0 -p 2023Q4 -f /usr/local/etc/poudriere.d/pkglist
```

Once the build is complete, setup a symbolic link for the current set of quarterly packages.

```
# cd /usr/local/poudriere/data/packages
# ln -s my_poudriere-amd64-14-0-2023Q4 my_poudriere-amd64-14-0-quarterly
```


## Configure host to use private package repository

On the FreeBSD host `my_server`, disable using the default FreeBSD-maintained binary package repository.

```
# mkdir -p /usr/local/etc/pkg/repos
# cat << EOF > /usr/local/etc/pkg/repos/FreeBSD.conf
# /usr/local/etc/pkg/repos/FreeBSD.conf

FreeBSD: {
    enabled: no
}
EOF
```

Install a copy of the public certificate `my_poudriere.cert` generated above.

```
# mkdir -p /usr/local/etc/ssl/certs
# mv /path/to/my_poudriere.cert /usr/local/etc/ssl/certs
```

Then enable using our own private package repository.

```
# cat << EOF > /usr/local/etc/pkg/repos/my_poudriere.conf
# /usr/local/etc/pkg/repos/my_poudriere.conf

my_poudriere: {
    url: "file:///var/poudriere/packages/my_poudriere-amd64-14-0-quarterly",
    signature_type: "pubkey",
    pubkey: "/usr/local/etc/ssl/certs/my_poudriere.cert",
    enabled: yes
}
EOF
```

Finally force reinstalling all the current packages from our own private package repository.

```
# pkg upgrade -f
```


## Update packages

On the `my_poudriere` virtual machine, update both the jail and both of the ports trees.

```
# poudriere jail -j my_poudriere-amd64-14-0 -u
# poudriere ports -u
# poudriere ports -p 2023Q4 -u
```

Build packages for updated ports.

```
# poudriere bulk -j my_poudriere-amd64-14-0 -p 2023Q4 -f /usr/local/etc/poudriere.d/pkglist
```


## Add a new package

Add a new entry to the package list.

```
# echo "misc/figlet" >> /usr/local/etc/poudriere.d/pkglist
```

If the default set of options for this package don't suit you, you may customize them with the `options` command.

```
# poudriere options -c -n misc/figlet
```

And start building again.

```
# poudriere bulk -j my_poudriere-amd64-14-0 -p 2023Q4 -f /usr/local/etc/poudriere.d/pkglist
```


## Switch to a new quarterly ports branch

Clone a new ports tree for the new quarterly branch from FreeBSD's official ports tree: `2024Q1`.

```
# poudriere ports -c -p 2024Q1 -B 2024Q1
```

Recreate the default ports tree to target the same branch.

```
# poudriere ports -d -p default
# poudriere ports -c -B 2024Q1
```

It's sad to have to recreate the default ports tree entirely, but there is [no built-in support to switch branches for an existing ports tree in `poudriere` yet](https://github.com/freebsd/poudriere/issues/508).