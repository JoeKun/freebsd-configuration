# Synchronizing time with NTP on FreeBSD

FreeBSD includes the [Network Time Protocol daemon](https://docs.freebsd.org/en/books/handbook/network-servers/#network-ntp) (`ntpd`) as part of the base operating system. Here are instructions on how to set it up.

## Enable `ntpd` service

In case you haven’t selected `ntpd` as one of the enabled services in the FreeBSD installer, you can enable by setting `ntpd_enable="YES"` in your system configuration.[^1]

It's also desirable to include the `ntpd_sync_on_start="YES"` directive to make sure time can be adjusted automatically at startup time.

[^1]: System configuration options are placed in discrete system configuration files according to the principles outlined in [Modular system configuration on FreeBSD](freebsd-modular-system-configuration.md).

```console
# cat << EOF > /etc/rc.conf.d/ntpd
# /etc/rc.conf.d/ntpd: system configuration for ntpd

ntpd_enable="YES"
ntpd_sync_on_start="YES"
EOF
```

Then start the `ntpd` service.

```console
# service ntpd start
```
