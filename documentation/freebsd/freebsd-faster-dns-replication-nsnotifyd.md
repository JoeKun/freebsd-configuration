# Faster DNS zone replication on FreeBSD with `nsnotifyd`

Even with a [robust primary/secondary DNS server setup for your custom domain](freebsd-dns-bind.md), you may encounter issues with DNS zone replication to your secondary DNS servers being too slow.

This can be particularly important if you intend to use the DNS challenge verification method for generating Let’s Encrypt certificates.

Enter [`nsnotifyd`](https://dotat.at/prog/nsnotifyd/), a very handy lightweight daemon which can be used to listen to DNS NOTIFY messages from a regular DNS server, and invoke a custom script.

This guide is inspired by [Jan-Piet Mens’ great article on how to setup `nsnotifyd` and its possible uses](https://jpmens.net/2015/06/16/alert-on-dns-notify/).

More specifically, we will use `nsnotifyd` to invoke a script to request immediate synchronization of the corresponding DNS zone by the BuddyNS secondary DNS servers, using their [SyncNOW API](https://www.buddyns.com/support/api/v2/#example-sync-zone).

## Install script to request immediate syncing of zone by BuddyNS

Assuming you [fetched these FreeBSD configuration files](freebsd-command-line-tools.md#fetch-configuration-files) in `/freebsd-configuration` , it’s easy to install the [`buddyns-sync-zone` script](../../opt/local/bin/buddyns-sync-zone).

```
# mkdir -p /opt/local/bin
# cd /opt/local/bin
# ln -s ../../../freebsd-configuration/opt/local/bin/buddyns-sync-zone

# mkdir -p /opt/local/etc
# cd /opt/local/etc
# ln -s ../../../freebsd-configuration/opt/local/etc/buddyns-sync-zone.conf
# chown root:nobody /opt/local/etc/buddyns-sync-zone.conf
# chmod 640 /opt/local/etc/buddyns-sync-zone.conf
```

Edit `/opt/local/etc/buddyns-sync-zone.conf` with your [BuddyNS API Key](https://www.buddyns.com/support/api/v2/#security-authentication).


## Install `nsnotifyd`

If you’re using `poudriere` following [this guide](freebsd-poudriere.md), then add a few entries to the list of packages built by `poudriere`.

```console
# echo "dns/nsnotifyd" >> /usr/local/etc/poudriere.d/pkglist
```

And build your packages again.

```console
# poudriere bulk \
    -j my_poudriere-amd64-14-3 \
    -p 2025Q4 \
    -f /usr/local/etc/poudriere.d/pkglist
```

Finally, on the target server machine, install `nsnotifyd`.

```console
# pkg install nsnotifyd
```


## Configure and enable `nsnotifyd`

Configuring `nsnotifyd` can be done directly in its system configuration file, in `/etc/rc.conf.d/nsnotifyd`. [^1]

[^1]: As shown in [Modular system configuration on FreeBSD](freebsd-modular-system-configuration.md).

```console
# cat << EOF > /etc/rc.conf.d/nsnotifyd
# /etc/rc.conf.d/nsnotifyd: system configuration for nsnotifyd

nsnotifyd_enable="YES"
nsnotifyd_pidfile="/var/run/nsnotifyd/nsnotifyd.pid"
nsnotifyd_user="nobody"
nsnotifyd_port="5309"
nsnotifyd_command="/opt/local/bin/buddyns-sync-zone"
nsnotifyd_flags="-P \${nsnotifyd_pidfile} -u \${nsnotifyd_user} -p \${nsnotifyd_port} -w \${nsnotifyd_command}"
EOF
```

Make sure to create the `/var/run/nsnotifyd` directory with the right permissions.

```console
# mkdir -p /var/run/nsnotifyd
# chown -R nobody:nobody /var/run/nsnotifyd
```

Then start the `nsnotifyd` service.

```console
# service nsnotifyd start
```


## Update `named` configuration

Assuming you adopted the [modular approach for configuring `named`](freebsd-dns-bind.md#modularize-configuration-file-for-named), you should make a few small updates to your [`named.conf.local` file](../../var/named/usr/local/etc/namedb/named.conf.local).

First, make sure to define `buddyns-notify-bridge` in a `primaries` block, pointing to the local host with the same port as the one used above for `nsnotifyd`, i.e. 5309.

```
// BuddyNS notify bridge
primaries buddyns-notify-bridge {
	127.0.0.1 port 5309;
};
```

Then, edit each of your DNS zones configuration as primary to also notify this `buddyns-notify-bridge`.

```
	also-notify {
		buddyns-notify-bridge;
	};
```

For a bit more context, your DNS zones configuration as primary should look something like this now.

```
zone "my_domain.tld" {
	type primary;
	file "primary-dynamic/my_domain.tld.zone";
	allow-query {
		any;
	};
	allow-transfer {
		buddyns-transfer;
	};
	also-notify {
		buddyns-notify-bridge;
	};
	notify yes;
};
```

Once you’ve updated all the relevant DNS zones configuration as primary, you need to reload the configuration for `named`.

```console
# service named reload
```

And now you should see the `buddyns-sync-zone` script invoked for a zone whenever a DNS NOTIFY message is sent by `named`, which in turn will make a call to BuddyNS’s SyncNOW API.


## Confirm correct behavior

You can confirm everything is working by monitoring the daemon logs on your server for the word `buddyns`.

```
# tail -f /var/log/daemon.log | grep -i buddyns
```

You should see logs like this (date, time and server name omitted).

```
nsnotifyd[12345]: my_domain.tld IN SOA 2025101201 wildcard; running /opt/local/bin/buddyns-sync-zone
buddyns-sync-zone[87654]: Received NOTIFY from @127.0.0.1 about zone my_domain.tld being updated to serial number 2025101201.
buddyns-sync-zone[98765]: Triggered sync for zone my_domain.tld with BuddyNS.
```

You can also confirm the actual zone transfer is taking place in a timely fashion by monitoring the `named` log file for the term `AXFR`.

```
# tail -f /var/named/var/log/named.log | grep -i axfr
```

You should see logs like this (date and time omitted).

```
xfer-out: client @0x342b7fc6ec00 5.223.55.119#40972 (my_domain.tld): transfer of 'my_domain.tld/IN': AXFR started (serial 2025101201)
xfer-out: client @0x342b7fc6ec00 5.223.55.119#40972 (my_domain.tld): transfer of 'my_domain.tld/IN': AXFR ended: 1 messages, 39 records, 1327 bytes, 0.001 secs (1327000 bytes/sec) (serial 2025101201)
```