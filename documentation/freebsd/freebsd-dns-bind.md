# Authoritative DNS server on FreeBSD with BIND

If you have a domain name, you might choose to self-host your own DNS server.

A popular option for this is a suite of software components for interacting with the Domain Name System called [BIND](https://www.isc.org/bind/), which is an [acronym for *Berkeley Internet Name Domain*](https://www2.eecs.berkeley.edu/Pubs/TechRpts/1984/5957.html).

Its most prominent component, `named` (short for *name daemon*), performs both of the main DNS server roles, acting as an authoritative name server for DNS zones and as a recursive resolver in the network.

This guide will walk you through the process of setting up an authoritative DNS server on FreeBSD with BIND’s `named`, so you can declare your own DNS zones.

**Important note**: This guide does not cover how to configure BIND’s `named` to act as a DNS server for domain name resolution in your local network. The goal is not for the DNS server to resolve any DNS queries, except for the domains that it is authoritative for.


## Install BIND

If you’re using `poudriere` following [this guide](freebsd-poudriere.md), then add a few entries to the list of packages built by `poudriere`.

```console
# cat << EOF >> /usr/local/etc/poudriere.d/pkglist

# DNS related services
dns/bind920
EOF
```

And build your packages again.

```console
# poudriere bulk \
    -j my_poudriere-amd64-14-3 \
    -p 2025Q4 \
    -f /usr/local/etc/poudriere.d/pkglist
```

Finally, on the target server machine, install `bind920`.

```console
# pkg install bind920
```


## Prepare `chroot` environment for `named`

First, create the top-level directory for your `named` deployment, in `/var/named`.

```console
# mkdir /var/named
# cd /var/named
```

Then, create various essential directories, with correct permissions.

```console
# mkdir -p usr/local/etc var/db/namedb var/db/namedb/managed-keys
# chgrp bind var/db/namedb
# chmod 775 var/db/namedb
# chown bind:bind var/db/namedb/managed-keys
```

Create relevant directories for zones your server will be the authoritative name server.

```console
# mkdir -p var/db/namedb/primary var/db/namedb/primary-dynamic
# chown root:bind var/db/namedb/primary
# chown bind:bind var/db/namedb/primary-dynamic
```

If you would like your name server to serve as a secondary authoritative name server for some zones, then make sure to create a directory for those.

```console
# mkdir -p var/db/namedb/secondary
# chown bind:bind var/db/namedb/secondary
```

Move `named`’s configuration directory to the `chroot` environment, while leaving a symbolic link in the default configuration path.

```console
# cd /usr/local/etc
# mv namedb /var/named/usr/local/etc
# ln -s ../../../var/named/usr/local/etc/namedb
```

Create a symbolic link to `named`’s database folder.

```console
# cd /var/db
# ln -s ../../var/named/var/db/namedb
```


## Modularize configuration file for `named`

As you prepare to add your own configuration for `named`, you may want to adjust its main configuration file at `/var/named/usr/local/etc/namedb/named.conf` to allow setting various options in a separate file, and adding configuration for your zones in another dedicated file.

This requires making several changes.

In the `options` section:
 - comment out the `directory` directive;
 - below the `statistics-file`, add an `include` directive for a separate `named.conf.options`.

```
options {
	// All file and path names are relative to the chroot directory,
	// if any, and should be fully qualified.
	//directory     "/usr/local/etc/namedb/working";
	pid-file		"/var/run/named/pid";
	dump-file       "/var/dump/named_dump.db";
	statistics-file "/var/stats/named.stats";

	include "/usr/local/etc/namedb/named.conf.options";
```

A good baseline for the `named.conf.options` configuration file can be found [here in this repository](../../var/named/usr/local/etc/namedb/named.conf.options).

After the `options` section, add a `logging` section with an `include` directive for a dedicated configuration file.

```
logging {
	include "/usr/local/etc/namedb/named.conf.logging";
};
```

A good baseline for the `named.conf.logging` configuration file can be found [here in this repository](../../var/named/usr/local/etc/namedb/named.conf.logging).

Lastly, at the very bottom of the file, add an `include` directive for your local configuration, including your DNS zones.

```
include "/usr/local/etc/namedb/named.conf.local";
```

As an alternative to making those changes manually in your `named.conf` configuration file, you may apply those changes with just a few commands, assuming you [fetched these FreeBSD configuration files](freebsd-command-line-tools.md#fetch-configuration-files) in `/freebsd-configuration`.

```console
# cd /var/named/usr/local/etc/namedb
# patch --posix -p1 -i /freebsd-configuration/patches/bind/modularize-named.conf.diff
```


## Local configuration for `named`

A good baseline for the `named.conf.local` configuration file can be found [here in this repository](../../var/named/usr/local/etc/namedb/named.conf.local).

Here are some of the important parts of this file.

### Access lists

At the top are defined some important access lists, such as `myself` for the local server.

```
// self: local link, localhost
acl myself {
	127.0.0.0/8;
	::1/128;
};
```

Redundancy for your authoritative name server is important, so you should find one or more servers that can serve as reliable secondary name servers for your zones.

For your secondary name servers, you may want to consider [BuddyNS](https://www.buddyns.com/).

Once you figure out which transfer servers will be used by your choice of secondary name server, add a dedicated access list for those.

```
// BuddyNS domain name service transfer servers:
//
//  - b.ns.buddyns.com;
// [...]
//
// Based on information from https://www.buddyns.com/support/setup/zone-transfer/
acl buddyns-transfer {
	108.61.224.67;
	2001:19f0:6400:8642::3;
	
	[...]
};
```

If you would like your name server to serve as a secondary authoritative name server for some zones, you should define their primary name servers in this section, like so.

```
// my_friend_name_server.tld
primaries my_friend_name_server {
	123.45.67.89;
};
```

### DNS zones configuration as primary

Add zone configuration blocks for any domain name you want this server to be the primary authoritative name server.

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
	notify yes;
};
```

### DNS zones configuration as secondary

Add zone configuration blocks for any domain name you want this server to be a secondary authoritative name server, using the `primaries` declaration previously mentioned.

```
zone "my_friend_domain.tld" {
	type secondary;
	file "secondary/my_friend_domain.tld.zone";
	primaries {
		my_friend_name_server;
	};
	allow-query {
		any;
	};
};
```


## Anatomy of a `named` zone file

For any domain name you want this server to be the primary authoritative name server, such as the domain `my_domain.tld` mentioned above, you will need to define a dedicated zone file, which is a simple plain text file.

### Time to live directive

It should start with a default TTL directive.

```
; my_domain.tld.zone: DNS Zone file for domain my_domain.tld

; Default TTL (Time To Live) value
$TTL 86400
```

### Start of Authority record

Then you should add a Start of Authority record, also known as `SOA` record.

```
@		IN		SOA		ns0		admin (
			2025101201		; Serial
			7200			; Refresh		(2 hours)
			900				; Retry			(15 minutes)
			2419200			; Expire		(4 weeks)
			7200			; Minimum		(2 hours)
)
```

#### Primary authoritative name server

The primary authoritative name server is indicated in the `SOA` record above as `ns0`. Since it’s not a fully qualified domain name, it actually corresponds to `ns0.my_domain.tld`.

This kind of configuration requires that you setup carefully the corresponding DNS glue records with your domain name registrar.

#### Administrator’s email address

The administrator’s email address is indicated in the `SOA` record above as `admin`, which corresponds to `admin@my_domain.tld`.

#### Serial number

The serial number is used by other DNS servers to determine if they should update their copy of the DNS zone with the most recent one. Therefore, it’s essential that you only define values for the serial number that increase monotonically.

A common pattern to ensure this is handled correctly is to use a 10 digit number, formatted as `yyyyMMddNN` where `yyyy` refers to the year, `MM` the month, `dd` the day of the month, and `NN` the number of revisions made to this DNS zone file on that day.

### Name server records

After the Start of Authority record, the most essential thing you need to define is the list of authoritative name servers for your zone, using `NS` records.

```
; NS Records
@		IN		NS			ns0

; Primary: My Location
ns0		IN		A			89.67.45.123
ns0		IN		AAAA		1234:5678:9abc:edcb::a
```

Since the primary authoritative name server is `ns0.my_domain.tld`, which is part of this zone we’re defining here, this `NS` record needs to be accompanied with relevant address records to specify the IP addresses of `ns0.my_domain.tld`. These addresses needs to match the ones you provided your domain name registrar for the glue records for `ns0.my_domain.tld`.

You may declare your secondary name servers in the same way, or you can include a separate file that only includes DNS records that relate to your secondary name servers.

```
; Secondaries
$INCLUDE primary/include/buddyns-secondary-nameservers.zone-include;
```

If you are also using BuddyNS for your secondary name servers, feel free to refer to the [`buddyns-secondary-nameservers.zone-include`](../../var/named/var/db/namedb/primary/include/buddyns-secondary-nameservers.zone-include) file in this repository.

### Mail exchange records

Mail servers that should be used for incoming email for any address ending with `@my_domain.tld` need to be declared with an `MX` record, accompanied with relevant address records to specify the IP addresses of that mail server.

```
; MX Records
@		IN		MX		10		mx0

; Main Mail Server: My Location
mx0		IN		A			89.67.45.123
mx0		IN		AAAA		1234:5678:9abc:edcb::a
```

You should also consider adding specific `TXT` records to enhance mail deliverability, such as:
 - SPF: Sender Policy Framework;
 - DMARC: Domain-based Message Authentication, Reporting, and Conformance;
 - DKIM: Domain Keys Identified Mail.

However, that is beyond the scope of this specific guide.

### Address and canonical name records

Aside from name servers and mail exchange servers, most other DNS needs can be satisfied with simple address records, such as `A` for IPv4 or `AAAA` for IPv6.

```
my_server		IN		A			89.67.45.123
my_server		IN		AAAA		1234:5678:9abc:edcb::a
```

You may also define aliases using `CNAME` records, which stands for canonical name.

```
www				IN		CNAME		my_server
```


## Enable `named`

Once your configuration for `named` is ready, along with all the DNS zone files for all the domains for which this server will act as primary authoritative name server, you can enable the `named` service.

### System configuration for `named`

Enable the `named` service.[^1]

[^1]: As shown in [Modular system configuration on FreeBSD](freebsd-modular-system-configuration.md).

```console
# cat << EOF > /etc/rc.conf.d/named
# /etc/rc.conf.d/named: system configuration for named

. /etc/rc.conf.d/syslogd

named_enable="YES"
named_chrootdir="/var/named"
EOF
```

### Adjustments to the system configuration file for `syslogd`

The system configuration file for `named` above assumes you have already defined relevant `syslogd_flags` in `/etc/rc.conf.d/syslogd`.[^2]

[^2]: This is also covered in [Modular system configuration on FreeBSD](freebsd-modular-system-configuration.md).

Beyond that, in order to log `named` activity to both a dedicated log file and `syslog`, as specified in the `named.conf.logging` file mentioned above, you need to tell `syslog` to install a log socket in the `chroot` environment for `named`.

This can be achieved by including `named` in `altlog_proglist` in `/etc/rc.conf.d/syslogd`. Here’s an example of how this file might look like.

```
# /etc/rc.conf.d/syslogd: system configuration for syslogd

# Disable opening Syslogd network socket (disables remote logging).
syslogd_flags="-ss"
altlog_proglist="named"
```

### Initial start of the `named` service

Start `named`.

```console
# service named start
```

For the first time you start this service, you should see the following output, showing that the startup script created various files and directories, as well as adjusted some permissions.

```console
./dev missing (created)
./etc missing (created)
./tmp missing (created)
./var/dump missing (created)
./var/log missing (created)
./var/run missing (created)
./var/run/named missing (created)
./var/stats missing (created)
etc/namedb/dynamic: 
	gid (0, 53, modified)
etc/namedb/working: 
	gid (0, 53, modified)
etc/namedb/secondary: 
	gid (0, 53, modified)
wrote key file "/var/named/usr/local/etc/namedb/rndc.key"
Starting named.
```

### Open port for the `domain` service in your firewall

In order for your new DNS server to be reachable from the internet, you’ll need to open the port for the `domain` service, which corresponds to port 53.

If you configured `pf` as a firewall as shown in [Configuring firewall for FreeBSD with `pf`](freebsd-firewall.md), all you need to do is to ensure `domain` is included in the `tcp_services` and `udp_services` variables, and reload `pf` rules.

```console
# service pf reload
```

If your server is behind a NAT, you will also need to adjust your router configuration to redirect traffic for your server’s public IP address on port 53 to your server’s local IP address.


## Considerations for dynamic updates

Here are a few additional considerations in case you would like to use RFC 2136 dynamic updates (which you will need if you want to generate Let’s Encrypt certificates with the DNS challenge verification method).

If you tend to prefer handcrafting your DNS zone files, you may want to keep two directories in `/var/named/var/db/namedb`:

 - one named `primary` where you keep your handcrafted zone files;
 - another one named `primary-dynamic` where you keep the zone files that can be dynamically modified by `named`.

Assuming you only use dynamic updates for transient challenge related records (such as those for generating Let’s Encrypt certificates), the idea is that the source of truth for what the zone file should look like, in terms of both content and formatting, remains in `primary`, which will only ever be handcrafted, whereas you can point `named` to a copy of the zone file in `primary-dynamic`, which `named` is entitled to modify when it handles a dynamic update.

When setting this up initially, just copy all `.zone` files from `primary` into `primary-dynamic`, and make sure both `primary-dynamic` and all `.zone` files in that directory are owned by `bind:bind`.

Then, make sure your `zone` configuration blocks in `/var/named/usr/local/etc/namedb/named.conf.local` refer to the zone file in the `primary-dynamic` directory.

From this point on, in order to edit the dynamic zone, you need to freeze it first with `rndc freeze`, and then thaw it with `rndc thaw` once you’re done editing it.

Since that is quite error prone, an easier approach is to leverage the script [`named-reset-dynamic-zone-files`](../../opt/local/bin/named-reset-dynamic-zone-files). Assuming you [fetched these FreeBSD configuration files](freebsd-command-line-tools.md#fetch-configuration-files) in `/freebsd-configuration`, you can install this script as follows:

```console
# mkdir -p /opt/local/bin
# cd /opt/local/bin
# ln -s ../../../freebsd-configuration/opt/local/bin/named-reset-dynamic-zone-files
```

The right way to perform manual edits to your zone files in a way that can be applied by `named-reset-dynamic-zone-files` is to never manually edit `.zone` files in the `primary-dynamic` directory; instead, you should edit them in the `primary` directory, and then call:

```console
# named-reset-dynamic-zone-files
```

This will do the right dance with `rndc freeze` and `rndc thaw` on your behalf for any `.zone` file present in the `primary` directory, and update the serial number in the `SOA` record as appropriate.