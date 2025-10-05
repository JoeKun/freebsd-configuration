# Configuring firewall for FreeBSD with `pf`

FreeBSD’s built-in firewall `pf` can be used to protect your server against unintended network activity.

A good place to learn more about this is in the [Firewalls](https://docs.freebsd.org/en/books/handbook/firewalls/) section of the FreeBSD Handbook.


## Sample `pf.conf` configuration file

Here is a quick walk through of a simple `/etc/pf.conf` configuration file.

### Variables

Keeping certain variables at the top of your `/etc/pf.conf` configuration file can make it easier to reason about the basic parameters of your firewall rules.

For example, you can define:
 - `ext_if` to designate your external network interface;
 - `tcp_services` as a list of TCP services should be reachable from the internet;
 - `udp_services` as a list of UDP services should be reachable from the internet;
 - `lan_subnet` to specify the IP address range for your local area network;
 - `cloud_servers` as a list of IP addresses for trusted cloud servers.

```
# /etc/pf.conf: Configuration for Packet Filter

#-----------------------------------------------------------
# Variables
#-----------------------------------------------------------

ext_if = "ix0"
tcp_services = "{ ssh, domain, http, https, smtp, smtps, submission }"
udp_services = "{ domain }"
icmp_types = "{ echoreq, unreach }"

lan_subnet = "{10.0.0.0/24}"

cloud_servers = "{123.231.123.231, 231.123.231.123}"
```

### Tables

In the next section of your `/etc/pf.conf` configuration file, you may define persistent tables, such as one we’ll use later to keep track of abusive hosts.

```
#-----------------------------------------------------------
# Tables
#-----------------------------------------------------------

# Define persistent table of abusive hosts.
table <abusive_hosts> persist
```

### Options

Here are a few common options you should consider adding to your `/etc/pf.conf` configuration file.

```
#-----------------------------------------------------------
# Options
#-----------------------------------------------------------

# Ignore loopback interface.
set skip on lo0

# Protect against activity from spoofed or forged IP addresses.
antispoof quick for $ext_if
```

### Rules

Using the variables defined above, you can now specify the list of rules for network traffic.

```
#-----------------------------------------------------------
# Rules
#-----------------------------------------------------------

# Allow all outgoing traffic.
pass out quick

# Allow all incoming traffic from local area network for allowed TCP services.
pass in quick on $ext_if proto tcp from $lan_subnet to any port $tcp_services

# Allow all incoming traffic from personal cloud servers for allowed TCP
# services.
pass in quick on $ext_if proto tcp from $cloud_servers to any port $tcp_services

# Block all incoming traffic from abusive hosts table.
block in quick from <abusive_hosts>

# Block all incoming traffic…
block in

# …except for allowed TCP services with rate limiting against abusive hosts…
pass in quick on $ext_if proto tcp to any port $tcp_services    \
    flags S/SA keep state                                       \
    (max-src-conn 100, max-src-conn-rate 15/5,                  \
    overload <abusive_hosts> flush)

# …and UDP services, as well as ICMP.
pass in quick on $ext_if proto udp to any port $udp_services
pass in quick on $ext_if inet proto icmp all icmp-type $icmp_types
```


## Enable and start `pf`

Enable the `pf` service.[^1]

[^1]: As shown in [Modular system configuration on FreeBSD](freebsd-modular-system-configuration.md).

```console
# cat << EOF > /etc/rc.conf.d/pf
# /etc/rc.conf.d/pf: system configuration for pf

pf_enable="YES"
EOF
```

To enable logging for `pf`, you must also enable the `pflog` service separately.[^2]

[^2]: As shown in [Modular system configuration on FreeBSD](freebsd-modular-system-configuration.md).

```console
# cat << EOF > /etc/rc.conf.d/pflog
# /etc/rc.conf.d/pflog: system configuration for pflog

pflog_enable="YES"
EOF
```

Start `pf` and `pflog`.

```console
# service pf start
# service pflog start
```


## Inspect persistent table for abusive hosts

You can inspect the `abusive_hosts` persistent table setup above in `/etc/pf.conf` using the `pfctl` command line tool.

```console
# pfctl -t abusive_hosts -T show
```


## SSH connection monitoring with `sshguard`

You may also optionally install and setup `sshguard` to protect your server from brute-force attacks against SSH and other services.

This section is inspired from the [official documentation for `sshguard`](https://www.sshguard.net/docs/sshguard-setup.html).

### Install `sshguard`

If you’re using `poudriere` following [this guide](freebsd-poudriere.md), then add a few entries to the list of packages built by `poudriere`.

```console
# cat << EOF >> /usr/local/etc/poudriere.d/pkglist

# Firewall related services
security/sshguard
EOF
```

And build your packages again.

```console
# poudriere bulk \
    -j my_poudriere-amd64-14-3 \
    -p 2025Q3 \
    -f /usr/local/etc/poudriere.d/pkglist
```

Finally, on the target server machine, install `sshguard`.

```console
# pkg install sshguard
```

### Configure `sshguard`

Some configuration is needed to instruct `sshguard` to use `pf` as its `BACKEND`.

This can be achieved by editing `/usr/local/etc/sshguard.conf` and enabling the option `BACKEND="/usr/local/libexec/sshg-fw-pf"`.[^3]

```console
# cd /usr/local/etc
# sed -i '' 's,^#BACKEND="/usr/local/libexec/sshg-fw-pf"$,BACKEND="/usr/local/libexec/sshg-fw-pf",' sshguard.conf
```

[^3]: An equivalent patch for `sshguard.conf` can also be found in this `freebsd-configuration` repository at the following location: `patches/sshguard/sshguard-use-pf-backend.diff`.

### Enable `sshguard`

Enable the `sshguard` service.[^4]

[^4]: As shown in [Modular system configuration on FreeBSD](freebsd-modular-system-configuration.md).

```console
# cat << EOF > /etc/rc.conf.d/sshguard
# /etc/rc.conf.d/sshguard: system configuration for sshguard

sshguard_enable="YES"
EOF
```

Start `sshguard`.

```console
# service sshguard start
```

### Integrate `sshguard` with `pf`

Integrating `sshguard` with `pf` requires making a few more adjustments to  the `/etc/pf.conf` configuration file.

First, add a new persistent table below the `<abusive_hosts>` one.

```
# Define persistent table for hosts banned by sshguard.
table <sshguard> persist
```

Then, add a new rule below the one that blocks incoming traffic from abusive hosts table.

```
# Block all incoming traffic from sshguard table.
block in quick from <sshguard>
```

Finally, reload `pf` rules.

```console
# service pf reload
```

As before, you can also inspect the `sshguard` persistent table using the `pfctl` command line tool.

```console
# pfctl -t sshguard -T show
```

You may also observe `sshguard`’s activity by checking logs in `/var/log/auth.log`.

```console
# tail -f /var/log/auth.log | grep sshguard
```