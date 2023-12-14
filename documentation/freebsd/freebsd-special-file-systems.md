# Mount special file systems on FreeBSD

Some software may expect to find some special file systems mounted on your server.

For example, `openjdk8` requires `fdescfs` mounted on `/dev/fd` and `procfs` mounted on `/proc`.[^1]

[^1]: See [`openjdk8`’s `pkg-message`](https://www.freshports.org/java/openjdk8#message) for more context.

Those requirements can be fulfilled on a permanent basis by adding a couple of lines to your `/etc/fstab` file.

```
fdesc       /dev/fd             fdescfs     rw          0       0
proc        /proc               procfs      rw          0       0
```

Other software may even require other Linux related file systems to be mounted, which is described in the [Linux Binary Compatibility](https://docs.freebsd.org/en/books/handbook/linuxemu/) section of the FreeBSD Handbook.

After adding these new lines in your `/etc/fstab` file, make sure to mount those special file systems immediately without needing to reboot.

```console
# mount -a
```
