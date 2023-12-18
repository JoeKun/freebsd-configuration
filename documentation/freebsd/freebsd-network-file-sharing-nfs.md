# Network file sharing with NFS on FreeBSD

## Enable required services

Enable a few services on your file server running FreeBSD.[^1]

[^1]: System configuration options are placed in discrete system configuration files according to the principles outlined in [Modular system configuration on FreeBSD](freebsd-modular-system-configuration.md).

### `nfsd`

```console
# cat << EOF > /etc/rc.conf.d/nfsd
# /etc/rc.conf.d/nfsd: system configuration for nfsd

nfs_server_enable="YES"
EOF
```

### `statd`

```console
# cat << EOF > /etc/rc.conf.d/statd
# /etc/rc.conf.d/statd: system configuration for statd

rpc_statd_enable="YES"
EOF
```

### `lockd`

```console
# cat << EOF > /etc/rc.conf.d/lockd
# /etc/rc.conf.d/lockd: system configuration for lockd

rpc_lockd_enable="YES"
EOF
```

### `rpcbind`

```console
# cat << EOF > /etc/rc.conf.d/rpcbind
# /etc/rc.conf.d/rpcbind: system configuration for rpcbind

rpcbind_enable="YES"
EOF
```

### `mountd`

```console
# cat << EOF > /etc/rc.conf.d/mountd
# /etc/rc.conf.d/mountd: system configuration for mountd

mountd_enable="YES"
mountd_flags="-n"
EOF
```


## Start required services

First, create an empty `/etc/exports` file to avoid a warning upon starting those services.

```console
# touch /etc/exports
```

Then start the `nfsd`, `statd` and `lockd` services.

```console
# service nfsd start
# service statd start
# service lockd start
```

And reload the `mountd` service.

```console
# service mountd reload
```


## Example configuration

Let’s create a network file share named `stuff` restricted to one specific machine on your network.

We’ll assume that specific machine has a stable IP address, and is reachable using the host name `my_client`. You can make that work by simply adding a new entry mapping that IP address to the name `my_client` in `/etc/hosts`.

### Server side

Assuming you have a ZFS pool named `storage`, mounted at `/storage`, create a dedicated  dataset named `stuff`.

```console
# zfs create storage/stuff
```

Set the `sharenfs` property on this new dataset to make it available to the machine `my_client`.

```console
# zfs set sharenfs='-alldirs,my_client' storage/stuff
```

### Client side

Assuming your machine `my_client` is actually running FreeBSD too, you could add an entry mapping the IP address of your server to the name `my_server`  in the client’s `/etc/hosts` file.

Mount the new share as read-write on your client machine.

```console
# mkdir -p /data/stuff
# mount -t nfs -o rw my_server:/storage/stuff /data/stuff
```

To make sure this share is automatically mounted upon startup, add a new line to your `/etc/fstab`.

```console
# cat << EOF >> /etc/fstab
my_server:/storage/stuff			/data/stuff		nfs		rw		0		0
EOF
```