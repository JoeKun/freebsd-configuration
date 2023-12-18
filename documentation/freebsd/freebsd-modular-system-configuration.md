# Modular system configuration on FreeBSD

## A different approach for system configuration

The most common way to add system configuration options on FreeBSD is to simply add new lines in the `/etc/rc.conf` file.

However, FreeBSD also offers an alternative which can lead to a more modular system configuration, allowing administrators to create smaller and more focused system configuration files in the `/etc/rc.conf.d` directory.


## Naming rules for discrete system configuration files

This technique requires careful naming of the discrete system configuration file. It often matches the name of the corresponding service startup script in `/etc/rc.d` or `/usr/local/etc/rc.d`, but not always.

Here are a few notable examples where the name of the discrete system configuration file is slightly different from the name of the corresponding service startup script.

 * For the `mysql-server` service, you should name your discrete system configuration file `mysql`.
 * For the `php-fpm` service, you should name your discrete system configuration file `php_fpm`.
 * For the `avahi-daemon` service, you should name your discrete system configuration file `avahi_daemon`.

The reliable way to figure out how to name the discrete system configuration file for a given service is to look for the value of the `name` variable in the corresponding service startup script.

```console
# grep "^name=" /usr/local/etc/rc.d/mysql-server
name="mysql"
```


## Modularize basic system configuration

On a freshly installed FreeBSD system, the installer typically adds a few things to `/etc/rc.conf`. Most of them can move to discrete system configuration files easily.

 * `clear_tmp_enable` can move to `/etc/rc.conf.d/cleartmp`.
 * `hostname` can move to `/etc/rc.conf.d/hostname`.
 * `moused_nondefault_enable` can move to `/etc/rc.conf.d/moused`.
 * `sshd_enable` can move to `/etc/rc.conf.d/sshd`.
 * `syslogd_flags` can move to `/etc/rc.conf.d/syslogd`.

Some of the less obvious options are described in [Quiddle’s article _Using `rc.conf.d` in FreeBSD_](https://quiddle.net/post/77406007305/using-rcconfd-in-freebsd).

 * `ifconfig_<interface>` can move to `/etc/rc.conf.d/network`.
 * `defaultrouter` and `gateway_enable` can move to `/etc/rc.conf.d/routing`.

There are however a couple of system configuration options which are used in meaningful ways in multiple service startup scripts, which can lead to unexpected behavior when those options are moved out of the central `/etc/rc.conf`. Specifically, you may want to keep the following in `/etc/rc.conf`.

 * `dumpdev` which is used in the `dumpon` and `savecore` startup scripts.
 * `zfs_enable` which is used in several ZFS-related startup scripts, as well as the `mountd` startup script.


## Additional resources

Klara Systems has a great article which goes into a lot more depth about FreeBSD’s `rc` and how `rc.conf.d` can be especially helpful for automation.

[Your Comprehensive Guide to `rc(8)`: FreeBSD Services and Automation](https://klarasystems.com/articles/rc8-freebsd-services-and-automation/)
