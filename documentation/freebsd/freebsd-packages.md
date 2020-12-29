# Common packages and configuration for FreeBSD

## Setup ssh keys for `root`

```
# ssh-keygen -t rsa -b 4096 -C foo@foo.com
```

Upload contents of `~/.ssh/id_rsa.pub` to GitHub.


## Prepare `pkg`

```
# pkg update
```


## Fetch configuration files

First, make sure to have `git` installed.

```
# pkg install git
```

Then clone the repository to `/`:

```
# cd /
# git clone https://github.com/JoeKun/freebsd-configuration.git
```


## Configure `git`

Link to git configuration file:

```
# cd
# ln -s ../freebsd-configuration/home/foo/.gitconfig
# mkdir -p .config
# cd .config
# ln -s ../../freebsd-configuration/home/foo/.config/git
```

You should then edit the name and email fields in the user section of this `.gitconfig` file.


## `zsh`

```
# pkg install zsh figlet fortune-mod-freebsd-classic
```

Link to global `zsh` configuration files:

```
# cd /usr/local/etc
# for file_name in zlogin zlogout zprofile zshenv zshrc; do ln -s ../../../freebsd-configuration/usr/local/etc/${file_name}; done
```

Link to user `zsh` configuration files for `root`:

```
# cd
# for file_name in .zshenv .zshrc; do ln -s ../freebsd-configuration/root/${file_name}; done
# chsh -s /usr/local/bin/zsh
```


## `vim`

```
# pkg install vim
# cd /usr/local/etc/vim
# rm -f vimrc
# for file_name in vimrc plugin indent syntax filetype.vim; do ln -s ../../../../freebsd-configuration/usr/local/etc/vim/${file_name}; done
```


## Edit login configuration to use Unicode (UTF-8)

As seen in [b1c1l1's blog post](https://www.b1c1l1.com/blog/2011/05/09/using-utf-8-unicode-on-freebsd/).

```
# cd /etc
# patch --posix -p1 -i /freebsd-configuration/patches/unicode-locale/login-use-unicode-locale.diff
# cap_mkdb /etc/login.conf
```

Log out and log back in.


## Configure `sshd`

As seen in the following [FreeBSD commit](https://svnweb.freebsd.org/base?view=revision&revision=294909), FreeBSD developers have made a conscious decision to deviate from the new default value of `UseDNS` since OpenSSH 6.8p1.

Unfortunately, leaving `UseDNS` enabled can result in significant delays when logging in, especially from a client machine in a network where the public IP address doesn't have a proper reverse DNS entry. Furthermore, `UseDNS` seems [pretty pointless for most people](http://unix.stackexchange.com/questions/56941/what-is-the-point-of-sshd-usedns-option#answer-56947).

So we can disable it by doing:

```
# cd /etc/ssh
# patch --posix -p1 -i /freebsd-configuration/patches/sshd/sshd-disable-usedns-configuration-option.diff
# service sshd reload
```


## Add unprivileged `admin` user

Prepare a skeleton for all regular unprivileged users:

```
# cd /usr/local/etc
# ln -s ../../../freebsd-configuration/usr/local/etc/skel
# pw group add users -g 500
```

Apply configuration for `adduser`:

```
# adduser -s zsh -k /usr/local/etc/skel -u 1000 -g users -C
Uid [1000]: 
Login group [users]: 
Enter additional groups []: 
Login class [default]: 
Shell (sh csh tcsh git-shell zsh rzsh bash rbash nologin) [zsh]: 
Home directory [/home/]: 
Home directory permissions (Leave empty for default): 
Use password-based authentication? [yes]: 
Use an empty password? (yes/no) [no]: 
Use a random password? (yes/no) [no]: 
Lock out the account after creation? [no]: 
Pass Type  : yes
Class      : 
Groups     : users 
Home       : /home/
Home Mode  : 
Shell      : /usr/local/bin/zsh
Locked     : no
OK? (yes/no): yes
Re-edit the default configuration? (yes/no): no
Goodbye!
```

Add unprivileged `admin` user:

```
# pw group add admin -g 1000
# adduser
Username: admin
Full name: Administrator
Uid [1000]: 
Login group [users]: admin
Login group is admin. Invite admin into other groups? []: wheel
Login class [default]: 
Shell (sh csh tcsh git-shell zsh rzsh bash rbash nologin) [zsh]: 
Home directory [/home/admin]: 
Home directory permissions (Leave empty for default): 
Use password-based authentication? [yes]: 
Use an empty password? (yes/no) [no]: 
Use a random password? (yes/no) [no]: 
Enter password: 
Enter password again: 
Lock out the account after creation? [no]: 
Username   : admin
Password   : *****
Full Name  : Administrator
Uid        : 1000
Class      : 
Groups     : admin wheel
Home       : /home/admin
Home Mode  : 
Shell      : /usr/local/bin/zsh
Locked     : no
OK? (yes/no): yes
adduser: INFO: Successfully added (admin) to the user database.
Add another user? (yes/no): no
Goodbye!
```

Copy `root` ssh key for `admin`:

```
# cp -av ~/.ssh ~admin
# chown -R admin:admin ~admin/.ssh
```

Apply basic configuration for `admin`:

```
# su admin
$ cd
$ git clone https://github.com/JoeKun/freebsd-configuration.git

$ rm -f .zshenv .zshrc
$ for file_name in .zshenv .zshrc; do ln -s freebsd-configuration/home/foo/${file_name}; done

$ ln -s freebsd-configuration/home/foo/.gitconfig
$ mkdir -p .config
$ cd .config
$ ln -s ../freebsd-configuration/home/foo/.config/git
```


## Clean up system configuration files

`loader.conf` cannot be a symbolic link.

```
# cd /boot
# rm -f loader.conf
# cp -a /freebsd-configuration/boot/loader.conf .
```

Other system configuration files don't have that restriction.

```
# cd etc
# rm -f fstab ; ln -s ../freebsd-configuration/etc/fstab
# mkdir -p /compat/linux/proc
# mount -a

# rm -f rc.conf ; ln -s ../freebsd-configuration/etc/rc.conf
# cd rc.conf.d
# for file_name in cleartmp hostname network ntpd routing sshd zfs; do rm -f ${file_name}; ln -s ../../freebsd-configuration/etc/rc.conf.d/${file_name} ; done
```

Manually edit `hostname` in `/etc/rc.conf.d/hostname`.


## Minor improvements to password prompts

```
# cd /freebsd-configuration/patches/password-prompts
# ./adjust_password_prompts
```


## Other utilities

```
# pkg install colordiff
# pkg install diff-so-fancy
# pkg install mmv
# pkg install htop
# pkg install screen
# pkg install wget
# pkg install bash
# pkg install most
# pkg install par_format
# pkg install gmake
# pkg install pwgen
# pkg install py37-mdv
# pkg install pstree
```


## `vimpager`

```
# pkg install vimpager
# cd /usr/local/etc
# rm -f vimpagerrc
# ln -s ../../../freebsd-configuration/usr/local/etc/vimpagerrc
```

Unfortunately, `vimpager` 2.06 has a serious bug when used with the latest version of `vim`. So we can compile it from source after applying a small patch, and then install it in an alternate directory so the binary that gets picked up is the patched one.

```
# cd /freebsd-configuration/patches/vimpager
# ./install_patched_vimpager_2_06
```


## `pf`

```
# cd /etc
# ln -s ../freebsd-configuration/etc/pf.conf
# cd /etc/rc.conf.d
# ln -s ../../freebsd-configuration/etc/rc.conf.d/pf
# ln -s ../../freebsd-configuration/etc/rc.conf.d/pflog
# service pf start
# service pflog start
```


## `smartd`

```
# pkg install smartmontools

# cd /usr/local/etc
# ln -s ../../../freebsd-configuration/usr/local/etc/smartd.conf
```

Edit `/usr/local/etc/smartd.conf` as necessary, namely regarding the list of drives to monitor, at the bottom of this configuration file.

Enable `smartd`:

```
# cd /etc/rc.conf.d
# ln -s ../../freebsd-configuration/etc/rc.conf.d/smartd
# service smartd start
```

To include drive health information in your daily status reports, add a line like the following to `/etc/periodic.conf`:

```
daily_status_smart_devices="/dev/ada0 /dev/ada1 /dev/ada2"
```


## `bind`

### Basic configuration

```
# pkg install bind916

# mkdir /var/named
# cd /var/named
# git clone https://github.com/JoeKun/freebsd-configuration.git

# mkdir -p usr/local/etc var/db/namedb var/db/namedb/managed-keys
# chgrp bind var/db/namedb
# chmod 775 var/db/namedb
# chown bind:bind var/db/namedb/managed-keys

# cd /usr/local/etc
# mv namedb /var/named/usr/local/etc
# ln -s ../../../var/named/usr/local/etc/namedb
# cd /var/db
# ln -s ../../var/named/var/db/namedb

# cd /var/named/usr/local/etc/namedb
# patch --posix -p1 -i ../../../../freebsd-configuration/patches/bind/modularize-named.conf.diff
# for file_name in named.conf.local named.conf.logging named.conf.options; do ln -s ../../../../freebsd-configuration/var/named/usr/local/etc/namedb/${file_name}; done
```

Manually edit `/var/named/usr/local/etc/namedb/named.conf.local` with your own zones and access lists.

Enable `bind`:

```
# cd /etc/rc.conf.d
# for file_name in named syslogd; do ln -s ../../freebsd-configuration/etc/rc.conf.d/${file_name}; done
# service named start
```

### Considerations for dynamic updates

Here are a few additional considerations in case you need to use RFC 2136 dynamic updates (which you will need if you want to generate Let's Encrypt certificates with the [DNS challenge](#dns-challenge) verification method).

If you tend to prefer handcrafting your DNS zone files, you may want to keep two directories in `/var/named/var/db/namedb`:

 * one named `master` where you keep your handcrafted zone files;
 * another one named `master-dynamic` where you keep the zone files that can be dynamically modified by `bind`.

Assuming you only use dynamic updates for transient challenge related records (such as those for generating Let's Encrypt certificates), the idea is that the source of truth for what the zone file should look like, in terms of both content and formatting, remains in `master`, which will only ever be handcrafted, whereas you can point `bind` to a copy of the zone file in `master-dynamic`, which `bind` is entitled to modify when it handles a dynamic update.

When setting this up initially, just copy all `.zone` files from `master` into `master-dynamic`, and make sure both `master-dynamic` and all `.zone` files in that directory are owned by `bind:bind`.

Then, make sure your `zone` configuration blocks in `/var/named/usr/local/etc/namedb/named.conf.local` refer to the zone file in the `master-dynamic` directory.

From this point on, in order to edit the dynamic zone, you need to freeze it first with `rndc freeze`, and then thaw it with `rndc thaw` once you're done editing it.

Since that is quite error prone, an easier approach is to leverage the script `named-reset-dynamic-zone-files`, which you can install as follows:

```
# cd /opt/local/bin
# ln -s ../../../freebsd-configuration/opt/local/bin/named-reset-dynamic-zone-files
```

The right way to perform manual edits to your zone files in a way that can be applied by `named-reset-dynamic-zone-files` is to never manually edit `.zone` files in the `master-dynamic` directory; instead, you should edit them in the `master` directory, and then call:

```
# named-reset-dynamic-zone-files
```

This will do the right dance with `rndc freeze` and `rndc thaw` on your behalf for any `.zone` file present in the `master` directory, and update the serial number in the SOA record as appropriate.


## SSL

### Create SSL user and group

```
# pw group add ssl -g 551
# pw user add ssl -u 551 -g 551 -c "SSL Unprivileged User" -d /var/empty -s /usr/sbin/nologin
# mkdir -p /etc/ssl/certs /etc/ssl/private
# chown root:ssl /etc/ssl/private
# chmod 710 /etc/ssl/private
```

### Let's Encrypt

A great option to get a valid SSL certificate is [Let's Encrypt](https://www.letsencrypt.org/). To use it, you'll need to install the following:

```
# pkg install py37-certbot
```

Let's discuss at a high level two different ways to generate Let's Encrypt signed certificates with `certbot`.

#### Standalone

One of the easiest ways to use `certbot` to create a new SSL certificate signed by Let's Encrypt is to use the `standalone` option, which essentially spawns up a builtin web server to handle a cryptographic challenge meant to prove that we do control our domain name. However, the downside of this `standalone` option is that you have to temporarily shut down any web server you might have running on your server. So, for example, assuming you have `nginx` running as a web server, you'll need to invoke `certbot` like this:

```
# service nginx stop
# certbot certonly --standalone
# service nginx start
```

The `certbot` command will prompt you with various questions, such as which domain names to include in your certificate.

With such a certificate, when the time to renew the certificate comes, you'll need to use `certbot` like so:

```
# service nginx stop
# certbot renew --standalone
# service nginx start
```

#### DNS challenge

As an alternative, `certbot` supports the DNS-01 challenge method, which requires a DNS server configured to allow `TXT` records to be updated in the zone file using RFC 2136 dynamic updates.

If you're using `bind` as a DNS server, make sure to check out the following resources on how to set this up:

 * [Patrick Terlisten's amazing howto guide](https://www.vcloudnine.de/using-lets-encrypt-dns-01-challenge-validation-with-local-bind-instance/);
 * [Alexis Wilke's amazing howto guide](https://linux.m2osw.com/setting-bind-get-letsencrypt-wildcards-work-your-system-using-rfc-2136).

However, a couple of things need to be done a bit differently on FreeBSD.

Create the TSIG key for `bind`:

```
# cd /var/named/usr/local/etc/namedb
# tsig-keygen -a hmac-sha512 letsencrypt > letsencrypt.key
# chown bind letsencrypt.key
# chmod 600 letsencrypt.key
```

Manually edit `/var/named/usr/local/etc/namedb/named.conf.local` to uncomment portions that relate to `letsencrypt`.

Restart `bind`:

```
# service named restart
```

Install the RFC 2136 plugin for `certbot`:

```
# pkg install py37-certbot-dns-rfc2136
```

Create a configuration file for this plugin:

```
# cd /etc/ssl
# mkdir credentials
# chmod 700 credentials
# cd credentials
# ln -s ../../../freebsd-configuration/etc/ssl/credentials/letsencrypt-dns-rfc2136-credentials.ini
# chmod -H 600 letsencrypt-dns-rfc2136-credentials.ini
```

Manually edit `/etc/ssl/credentials/letsencrypt-dns-rfc2136-credentials.ini` to replace the value associated with the `dns_rfc2136_secret` key with the `secret` present in `/var/named/usr/local/etc/namedb/letsencrypt.key`.

Invoke `certbot` with the RFC 2136 plugin:

```
# certbot certonly --dns-rfc2136 --dns-rfc2136-credentials /etc/ssl/credentials/letsencrypt-dns-rfc2136-credentials.ini --dns-rfc2136-propagation-seconds 180 -d foo.com -d '*.foo.com' -d bar.org -d '*.bar.org'
```

#### Create links to certificate in `/etc/ssl`

After you create a new Let's Encrypt signed certificate, you may want to create symbolic links to the commonly used components of this certificate, in `/etc/ssl`. For example, assuming you just created a wildcard certificate for foo.com as described above, run the following commands:

```
# cd /etc/ssl/certs
# ln -s ../../../usr/local/etc/letsencrypt/live/foo.com/fullchain.pem foo.com_wildcard.pem
# cd /etc/ssl/private
# ln -s ../../../usr/local/etc/letsencrypt/live/foo.com/privkey.pem foo.com_wildcard.key
```

#### Adjust permissions

Every time you create or renew a Let's Encrypt signed certificate with `certbot`, make sure to adjust permissions so the private key can be read by any user that belongs to the newly created `ssl` group:

```
# cd /usr/local/etc/letsencrypt
# chown -R -h root:ssl live archive
# chmod g+x live archive
# chmod g+r archive/*/privkey*.pem
```

And of course, don't forget to restart any services you have that use this SSL certificate.

#### Automate certificate renewal

In order to automate the renewal of your Let's Encrypt certificate, make sure you include the following in `/etc/periodic.conf`:

```
weekly_certbot_enable="YES"
```

Then you'll need to automate adjusting the permissions of new SSL certificates, as well as restarting any services that use SSL certificates. You can do so by adding executable scripts to the `post` `renewal-hooks` directory for Let's Encrypt:

```
# cd /usr/local/etc/letsencrypt/renewal-hooks/post
# ln -s ../../../../../../freebsd-configuration/usr/local/etc/letsencrypt/renewal-hooks/post/fix-ssl-certificate-permissions
# ln -s ../../../../../../freebsd-configuration/usr/local/etc/letsencrypt/renewal-hooks/post/restart-services-requiring-ssl-certificate
```

Manually edit `/usr/local/etc/letsencrypt/renewal-hooks/post/restart-services-requiring-ssl-certificate` to include instructions for restarting any services you run on your server that use your SSL certificate.

And finally, if you normally use `named-reset-dynamic-zone-files` to help you [reconcile handcrafting your zone files with DNS dynamic updates](#considerations-for-dynamic-updates), you can also add that script as an additional hook:

```
# cd /usr/local/etc/letsencrypt/renewal-hooks/post
# ln -s ../../../../../../freebsd-configuration/usr/local/etc/letsencrypt/renewal-hooks/post/named-reset-dynamic-zone-files
```


## OpenLDAP

```
# pkg install openldap-server
# cd /etc/rc.conf.d
# ln -s ../../freebsd-configuration/etc/rc.conf.d/slapd
# cd /usr/local/etc/openldap
# rm -f slapd.ldif
# ln -s ../../../../freebsd-configuration/usr/local/etc/openldap/slapd.ldif
# cd schema
# for file_name in virtual_mail.schema virtual_mail.ldif mailing_list.schema mailing_list.ldif application_participant.schema application_participant.ldif fully_qualified_group.schema fully_qualified_group.ldif; do ln -s ../../../../../../freebsd-configuration/usr/local/etc/openldap/schema/${file_name}; done
# cd /freebsd-configuration/usr/local/etc/openldap
# chmod 444 schema/*.{schema,ldif}
# chmod 600 slapd.ldif
# pw group mod ssl -m ldap
```

Manually edit the following keys in `/usr/local/etc/openldap/slapd.ldif`:

 * `olcTLSCACertificateFile`;
 * `olcTLSCertificateFile`;
 * `olcTLSCertificateKeyFile`;
 * `olcRootPW`.

Specifically, this last key, `olcRootPW`, is for the password of the root DN. Here's how you can generate a suitable blowfish password hash to avoid keeping it in clear text in the configuration file:

```
# slappasswd -h "{CRYPT}" -c '$2a$12$%.22s'
```

Import definitions from `slapd.ldif` as a `cn=config` OpenLDAP configuration, and start the `slapd` service:

```
# /usr/local/sbin/slapadd -n0 -F /usr/local/etc/openldap/slapd.d/ -l /usr/local/etc/openldap/slapd.ldif
# service slapd start
```

To populate the LDAP directory, you may use some scripts provided as part of this repository, which take advantage of the custom schemas used above, namely `virtual_mail`, `mailing_list`, `fullyQualifiedGroup` and `applicationParticipant`.

```
# mkdir -p /opt/local/lib
# cd /opt/local/lib
# for file_name in ../../../freebsd-configuration/opt/local/lib/ldap_*; do ln -s "${file_name}"; done
# mkdir -p /opt/local/bin
# cd /opt/local/bin
# for file_name in ../../../freebsd-configuration/opt/local/bin/ldap_*; do ln -s "${file_name}"; done
```

Some examples of how you can use these scripts to populate the LDAP directory can be found at `/freebsd-configuration/documentation/ldap/ldap_setup_multi_domain_directory_with_sample_entries`.


## `nginx`, `nginx-ldap-auth-daemon` and `php`

```
# pkg install nginx
# pkg install php73
```

Add `www` user to `ssl` group:

```
# pw group mod ssl -m www
```

Install `nginx-ldap-auth-daemon`:

```
# pkg install py37-ldap py37-yaml
# cd /usr/local
# ln -s ../../freebsd-configuration/usr/local/nginx-ldap-auth
# chown root:www /usr/local/nginx-ldap-auth/nginx-ldap-auth-daemon.conf
# chmod 640 /usr/local/nginx-ldap-auth/nginx-ldap-auth-daemon.conf
```

Manually edit `/usr/local/nginx-ldap-auth/nginx-ldap-auth-daemon.conf` with the right settings for connecting to your LDAP server.

Enable `nginx-ldap-auth-daemon`:

```
# cd /usr/local/etc/rc.d
# ln -s ../../../../freebsd-configuration/usr/local/etc/rc.d/nginx-ldap-auth-daemon
# chmod -H 555 nginx-ldap-auth-daemon

# cd /etc/rc.conf.d
# ln -s ../../freebsd-configuration/etc/rc.conf.d/nginx_ldap_auth_daemon
# service nginx-ldap-auth-daemon start
```

Configure `php`:

```
# cd /freebsd-configuration/patches/php
# ./configure_php
```

Manually edit `/usr/local/etc/php.ini` to set the timezone. For example:

```
[Date]
; Defines the default timezone used by the date functions
; http://php.net/date.timezone
date.timezone = America/Los_Angeles
```

Enable `php`:

```
# cd /etc/rc.conf.d
# ln -s ../../freebsd-configuration/etc/rc.conf.d/php_fpm
# service php-fpm start
```

Configure `nginx`:

```
# cd /usr/local/www
# ln -s ../../../freebsd-configuration/usr/local/www/admin

# cd /usr/local/etc
# mkdir -p newsyslog.conf.d
# cd newsyslog.conf.d
# ln -s ../../../../freebsd-configuration/usr/local/etc/newsyslog.conf.d/nginx.conf

# cd /usr/local/etc/nginx
# rm -f nginx.conf
# for file_name in nginx.conf error_pages php php_ssl php_ssl_auth_proxy redirect_to_ssl ssl_wildcard_certificate; do ln -s ../../../../freebsd-configuration/usr/local/etc/nginx/${file_name}; done
```

Manually edit `ssl_certificate` and `ssl_certificate_key` in `/usr/local/etc/nginx/ssl_wildcard_certificate` to point to your own SSL certificate.

```
# mkdir sites-enabled
# cd sites-enabled
# ln -s ../../../../../freebsd-configuration/usr/local/etc/nginx/sites-enabled/default.conf
# ln -s ../../../../../freebsd-configuration/usr/local/etc/nginx/sites-enabled/admin.foo.com.conf
# mkdir admin.foo.com.conf.d
# mkdir -p /var/cache/nginx/admin.foo.com/auth_cache
# chown -R www:www /var/cache/nginx
```

Manually edit the following in `/usr/local/etc/nginx/sites-enabled/admin.foo.com.conf`:

 * `server_name`;
 * `proxy_cache_path`, to match the `auth_cache` directory created just earlier;
 * `proxy_cache`;
 * `proxy_set_header X-LDAP-UserBaseDN`;
 * `proxy_set_header X-LDAP-GroupBaseDN`.

```
# cd /etc/rc.conf.d
# ln -s ../../freebsd-configuration/etc/rc.conf.d/nginx
# service nginx start
```


## MySQL

```
# pkg install mysql57-server
# cd /etc/rc.conf.d
# ln -s ../../freebsd-configuration/etc/rc.conf.d/mysql
# service mysql-server start
```

After the service is started, we need to secure the installation. This can be accomplished through a script called mysql_secure_installation. Run this as `root` to lock down some insecure defaults:

```
# mysql_secure_installation
```

The script will start by asking you for the current password for the MySQL root account.

```
[...]
Enter current password for root (enter for none):
```

Since we have not set a password for this user yet, we can press Enter to bypass this prompt.

Next, it will ask you if you would like to set the MySQL root account's password.

```
Set root password? [Y/n]
```

Press Enter to accept this suggestion. Choose and confirm an administrative password.

The script will then proceed with additional suggestions that will help reverse some insecure conditions in the default MySQL installation. Simply press Enter through all of these prompts to complete all of the suggested actions.

We should restart the MySQL service to ensure that our instance immediately implements the security changes:

```
# service mysql-server restart
```


# `phpMyAdmin`

```
# pkg install phpMyAdmin-php73
```

Create the `phpMyAdmin` storage database, as well as the `phpmyadmin` MySQL user with the right privileges:

```
# mysql -u root -p < /usr/local/www/phpMyAdmin/sql/create_tables.sql
# mysql -u root -p < /freebsd-configuration/documentation/phpmyadmin/phpmyadmin_user_and_privileges.sql
```

Alter password of `phpmyadmin` user:

```
# mysql -u root -p

[...]

root@localhost [(none)]> ALTER USER 'phpmyadmin'@'localhost' IDENTIFIED BY 'SomeThing@1234';
```

Prepare configuration for `phpMyAdmin`:

```
# cd /usr/local/etc
# ln -s ../../../freebsd-configuration/usr/local/etc/phpmyadmin
# cd /usr/local/etc/phpmyadmin
# chown root:www blowfish_secret.inc.php config-db.php
# chmod 640 blowfish_secret.inc.php config-db.php
# cd /usr/local/www/phpMyAdmin
# ln -s ../../../../freebsd-configuration/usr/local/www/phpMyAdmin/config.inc.php
```

Open `/usr/local/etc/phpmyadmin/config-db.php` and edit the `$phpmyadmin_user_password` variable in to match the password used above for the `phpmyadmin` MySQL user.

Open `/usr/local/etc/phpmyadmin/blowfish_secret.inc.php` and assign a 32 character password to the `$cfg['blowfish_secret']` variable.

Finally, remove any trace of these passwords:

```
# rm -f ~/.mysql_secret ~/.mysql_history
```

Enable `phpMyAdmin` configuration for `nginx`.

```
# cd /usr/local/etc/nginx/sites-enabled/admin.foo.com.conf.d
# ln -s ../../../../../../freebsd-configuration/usr/local/etc/nginx/sites-enabled/admin.foo.com.conf.d/phpmyadmin.conf
# service nginx restart
```


## PostgreSQL

```
# pkg install postgresql11-client postgresql11-server postgresql11-contrib
# cd /etc/rc.conf.d
# ln -s ../../freebsd-configuration/etc/rc.conf.d/postgresql
# service postgresql initdb
# cd /freebsd-configuration/patches/postgresql
# ./configure_postgresql
# service postgresql start
```

Change the Unix password of `postgres` user:

```
# passwd postgres
```

Configure shell for `postgres` user:

```
# chown -R postgres:postgres /freebsd-configuration/var/db/postgres
# su postgres
$ cd /var/db/postgres
$ ln -s ../../../freebsd-configuration/var/db/postgres/.zshenv
$ ln -s ../../../freebsd-configuration/var/db/postgres/.zshrc
$ exit
```

And alter password of `postgres` user in the database:

```
# su postgres
$ psql

[...]

postgres=# ALTER USER postgres WITH PASSWORD 'SomeThing@1234';
postgres=# \q
$ rm -f ~/.psql_history
```


## `phpPgAdmin`

```
# pkg install phppgadmin-php73
# cd /freebsd-configuration/patches/phppgadmin
# ./configure_phppgadmin
```

Enable `phpPgAdmin` configuration for `nginx`.

```
# cd /usr/local/etc/nginx/sites-enabled/admin.foo.com.conf.d
# ln -s ../../../../../../freebsd-configuration/usr/local/etc/nginx/sites-enabled/admin.foo.com.conf.d/phppgadmin.conf
# service nginx restart
```


## `phpLDAPAdmin`

```
# pkg install phpldapadmin-php73
```

Enable `phpLDAPAdmin` configuration for `nginx`.

```
# cd /usr/local/etc/nginx/sites-enabled/admin.foo.com.conf.d
# ln -s ../../../../../../freebsd-configuration/usr/local/etc/nginx/sites-enabled/admin.foo.com.conf.d/phpldapadmin.conf
# service nginx restart
```


## `ports` tree

```
# portsnap fetch extract
# portsnap fetch update
```


## `redis`

In this section, we will install `redis` with a special startup configuration file that makes it easy to use separate `redis` instances for each service that needs one.

This is inspired by [Rspamd's guide on using a multi-instance redis backend for its various components](https://rspamd.com/doc/tutorials/redis_replication.html).

```
# pkg install redis

# cd /usr/local/etc
# patch --posix -p1 -i /freebsd-configuration/patches/redis/redis.conf-bind-to-localhost-only-and-disable-listening-on-tcp-socket.diff

# cd /etc/rc.conf.d
# ln -s ../../freebsd-configuration/etc/rc.conf.d/redis
# mkdir redis.d
```

Files in the `redis.d` directory are expected to contain a single statement, like this:

```
redis_profiles="${redis_profiles} foo"
```

where `foo` corresponds to the name of a configuration file named `redis-foo.conf` next to the global `redis.conf` file.

Please refer to `/usr/local/etc/rc.d/redis` for further guidance on using multiple redis profiles.


## Email

The following is heavily inspired by:

 * [Kliment Andreev's amazing howto guide](https://blog.iandreev.com/?p=1604);
 * [Cullum Smith's amazing howto guide](https://www.c0ffee.net/blog/mail-server-guide/).

Please note that this section contains information on how to install and configure two different webmail applications:

 * Roundcube, which is fully open source, and at the same time with a basic design and powerful (especially when it comes to the extent to which it supports advanced aspects of server-side mail rules);
 * AfterLogic WebMail Pro, which is a commercial and paid product, but has a slightly more appealing look and feel, and a broader range as a more complete groupware suite, although its support for server-side mail rules is a bit more barebones; as a side note though, AfterLogic also offers a more stripped down version of this product, named AfterLogic WebMail Lite, which is free of charge.

Typically, one should pick only one of these two.

### Disable `sendmail`

```
# cd /etc/rc.conf.d
# ln -s ../../freebsd-configuration/etc/rc.conf.d/sendmail
# ln -s ../../freebsd-configuration/etc/rc.conf.d/var
# service sendmail stop
```


### `dovecot`

```
# cd /usr/ports/mail/dovecot
# make config
```

Keep all options enabled by default, and additionally enable the following:

 * `LZ4` in first section;
 * `LDAP` in *Database support* section;
 * `ICU` in *Full text search plugins* section.

See if any dependency is missing:

```
# make missing
```

If any, install the dependency using `pkg`. For example:

```
# pkg install devel/pkgconf
```

Then proceed to installing `dovecot`:

```
# make all install clean
# pkg lock dovecot
```

Prepare storage for virtual mailboxes:

```
# pw group add virtual_mail -g 145
# pw user add virtual_mail -u 145 -g 145 -c "Virtual Mail Administrator" -d /var/mail/virtual -s /usr/sbin/nologin
# rm -f /var/mail/virtual_mail
# mkdir /var/mail/virtual /var/mail/attachments
# chown virtual_mail:virtual_mail /var/mail/virtual /var/mail/attachments
# chmod 770 /var/mail/virtual /var/mail/attachments
```

Apply basic `dovecot` configuration:

```
# cd /freebsd-configuration/patches/dovecot
# ./bootstrap_dovecot_configuration
```

Manually edit server dependent configuration:

 * `ssl_cert` and `ssl_key` in `/usr/local/etc/dovecot/conf.d/10-ssl.conf` to point to your own SSL certificate;
 * `dnpass` in `/usr/local/etc/dovecot/dovecot-ldap.conf.ext`.

Enable `dovecot`:

```
# cd /etc/rc.conf.d
# ln -s ../../freebsd-configuration/etc/rc.conf.d/dovecot
# service dovecot start
```


### Server-side mail rules

This section is inspired by the [Dovecot section of Cullum Smith's guide](https://www.c0ffee.net/blog/mail-server-guide/#dovecot), especially those parts of that guide that directly mention `sieve`.

```
# cd /usr/ports/mail/dovecot-pigeonhole
# make config
```

Keep all options enabled by default, double-checking that the following are enabled:

 * `DOCS` in first section;
 * `MANAGESIEVE` in first section.

Additionally enable the following:

 * `LDAP` in first section.

See if any dependency is missing:

```
# make missing
```

If any, install the dependency using `pkg`.

Then proceed to installing `dovecot-pigeonhole`:

```
# make all install clean
# pkg lock dovecot-pigeonhole
```

Update `dovecot` configuration for `sieve` support:

```
# cd /freebsd-configuration/patches/dovecot
# ./bootstrap_dovecot_sieve_configuration
```

Restart dovecot:

```
# service dovecot restart
```


### Content filters (anti-spam and anti-virus)

Install ClamAV:

```
# pkg install clamav
```

Initialize and enable ClamAV:

```
# freshclam
# cd /etc/rc.conf.d
# ln -s ../../freebsd-configuration/etc/rc.conf.d/clamav_clamd
# ln -s ../../freebsd-configuration/etc/rc.conf.d/clamav_freshclam
# service clamav-clamd start
# service clamav-freshclam start
```

Install this helper script that makes it easy to augment ClamAV's database of known virus signatures:

```
# pkg install clamav-unofficial-sigs

# cd /var/log
# mkdir clamav-unofficial-sigs
# chown clamav:clamav clamav-unofficial-sigs

# cd /usr/local/etc/newsyslog.conf.d
# ln -s ../../../../freebsd-configuration/usr/local/etc/newsyslog.conf.d/clamav-unofficial-sigs.conf

# cd /usr/local/etc/clamav-unofficial-sigs
# patch --posix -p1 /freebsd-configuration/patches/clamav-unofficial-sigs/clamav-unofficial-sigs-user.conf-enable-logging-to-file.diff
```

Then follow instructions in [this guide](https://minamikhail.com/clamav-unofficial-sigs-installation-configuration/) on how to get and configure authorization keys for SecuriteInfo and MalwarePatrol.

Enable this script to run hourly:

```
# cd /etc/cron.d
# ln -s ../../freebsd-configuration/etc/cron.d/periodic-hourly

# cd /usr/local/etc/periodic
# mkdir hourly
# cd hourly
# ln -s ../../../../../freebsd-configuration/usr/local/etc/periodic/hourly/210.clamav-unofficial-sigs-update
```

Install the DCC daemon to check mail for bulkiness:

```
# cd /usr/ports/mail/dcc-dccd
# make all install clean
# pkg lock dcc-dccd

# cd /var/db/dcc
# patch --posix -p1 /freebsd-configuration/patches/dcc/dcc_conf-configure-for-spam-detection.diff

# cd /usr/local/etc/periodic/daily
# ln -s ../../../libexec/cron-dccd 340.dcc-maintenance-tasks

# cd /etc/rc.conf.d
# ln -s ../../freebsd-configuration/etc/rc.conf.d/dccifd
# service dccifd start
```

Configure and enable two new `redis` instances dedicated to `rspamd`, including one specifically for the Bayes classifier:

```
# cd /var/db/redis
# mkdir rspamd
# chown redis:redis rspamd

# cd /usr/local/etc
# ln -s ../../../freebsd-configuration/usr/local/etc/redis-rspamd.conf
# ln -s ../../../freebsd-configuration/usr/local/etc/redis-rspamd-bayes.conf

# cd /usr/local/etc/newsyslog.conf.d
# ln -s ../../../../freebsd-configuration/usr/local/etc/newsyslog.conf.d/redis-rspamd.conf
# ln -s ../../../../freebsd-configuration/usr/local/etc/newsyslog.conf.d/redis-rspamd-bayes.conf

# cd /etc/rc.conf.d/redis.d
# ln -s ../../../freebsd-configuration/etc/rc.conf.d/redis.d/rspamd
# ln -s ../../../freebsd-configuration/etc/rc.conf.d/redis.d/rspamd-bayes
# service redis start rspamd
# service redis start rspamd-bayes
```

Prepare to install `rspamd`:

```
# cd /usr/ports/mail/rspamd
# make config
```

Keep all options enabled by default, and additionally enable the following:

 * `HYPERSCAN`.

See if any dependency is missing:

```
# make missing
```

If any, install the dependencies using `pkg`. For example:

```
# pkg install devel/ragel devel/ninja security/libsodium devel/hyperscan lang/luajit
```

Then proceed to installing `rspamd`:

```
# make all install clean
# pkg lock rspamd
```

Configure `rspamd`:

```
# pw group mod clamav -m rspamd

# cd /usr/local/etc/rspamd
# mkdir local.d
# cd local.d
# for file_name in antivirus.conf classifier-bayes.conf dcc.conf dkim_signing.conf mx_check.conf phishing.conf redis.conf replies.conf worker-controller.inc worker-normal.inc worker-proxy.inc; do ln -s ../../../../../freebsd-configuration/usr/local/etc/rspamd/local.d/${file_name}; done
```

Manually edit the following key in `/usr/local/etc/rspamd/local.d/worker-controller.inc`:

 * `password`.

This key, `password`, is for the password of the administrator interface of `rspamd`. Here's how you can generate a suitable password hash:

```
# rspamadm pw
```

Enable `rspamd`:

```
# cd /etc/rc.conf.d
# ln -s ../../freebsd-configuration/etc/rc.conf.d/rspamd
# service rspamd start
```

Enable `rspamd` configuration for `nginx`:

```
# cd /usr/local/etc/nginx/sites-enabled/admin.foo.com.conf.d
# ln -s ../../../../../../freebsd-configuration/usr/local/etc/nginx/sites-enabled/admin.foo.com.conf.d/rspamd.conf
# service nginx restart
```

Update `dovecot` configuration to use IMAP Sieve plugin to run appropriate `sieve` scripts that allow for automatic training of `rspamd`:

```
# cd /freebsd-configuration/patches/dovecot
# ./bootstrap_dovecot_sieve_configuration
```

For reference, this part is heavily inspired from [dovecot's guide on integrating with an antispam using IMAP Sieve](https://wiki.dovecot.org/HowTo/AntispamWithSieve).

Restart `dovecot`:

```
# service dovecot restart
```

Once this is setup, you should consider following the steps outlined by Cullum Smith in the section titled [DKIM: Validation for Your Outgoing Mail](https://www.c0ffee.net/blog/mail-server-guide/#dkim) of his howto guide.


### `postfix`

```
# cd /usr/ports/mail/postfix
# make config
```

Keep all options enabled by default, and additionally enable the following:

 * `LDAP`.

See if any dependency is missing:

```
# make missing
```

If any, install the dependency using `pkg`.

Then proceed to installing `postfix`:

```
# make all install clean
# pkg lock postfix
```

Configure `postfix`:

```
# cd /freebsd-configuration/patches/postfix
# ./bootstrap_postfix_configuration

# cd /usr/local/etc/postfix
# rm -f main.cf
# ln -s ../../../../freebsd-configuration/usr/local/etc/postfix/main.cf
# ln -s ../../../../freebsd-configuration/usr/local/etc/postfix/transport
# ln -s ../../../../freebsd-configuration/usr/local/etc/postfix/ldap
# cd /usr/local/etc/postfix/ldap
# chown -R root:postfix .
# find . -type d -exec chmod 710 {} \;
# find . -type f -exec chmod 640 {} \;

# cd /usr/local/etc/mail
# ln -s ../../../../freebsd-configuration/usr/local/etc/mail/aliases
```

Manually edit the following keys in `/usr/local/etc/postfix/main.cf`:

 * `myhostname`;
 * `mydestination`;
 * `smtpd_tls_cert_file`;
 * `smtpd_tls_key_file`;
 * `smtpd_tls_CAfile`.

Manually edit the entry for `root` in `/usr/local/etc/mail/aliases`.

Manually edit the `bind_pw` entry in each of the files in `/usr/local/etc/postfix/ldap`.

Add `postfix` to `rspamd` group:

```
# pw group mod rspamd -m postfix
```

Add listeners for `postfix` in `dovecot` configuration files:

```
# cd /usr/local/etc/dovecot
# patch --posix -p1 -i /freebsd-configuration/patches/dovecot/dovecot-listeners-for-postfix.diff
# service dovecot restart
```

Update all map files:

```
# postmap /usr/local/etc/postfix/transport
# postalias /usr/local/etc/mail/aliases
# newaliases
```

Prepare container directory for users' local mailboxes at `/var/mail/local`:

```
# mkdir -p /var/mail/local
# chown root:mail /var/mail/local
# chmod 775 /var/mail/local
```

Enable `postfix`:

```
# cd /etc/rc.conf.d
# ln -s ../../freebsd-configuration/etc/rc.conf.d/postfix
# service postfix start
```

Adjust login configuration with the more specific location of users' local mailboxes in `/var/mail/local` as defined in `postfix`'s `main.cf` configuration file:

```
# cd /etc
# patch --posix -p1 -i /freebsd-configuration/patches/user-mailbox-location/login-adjusted-user-mailbox-location-in-var-mail-local.diff
# cap_mkdb /etc/login.conf
```

Log out and log back in.


### Roundcube

Roundcube is an open source webmail application.

The following is heavily inspired by [Kliment Andreev's howto guide on `roundcube`](https://blog.iandreev.com/?p=1339).

```
# cd /usr/ports/mail/roundcube
# make config
```

Keep all options enabled by default, and additionally enable the following:

 * `PGSQL` in *DB* section.

See if any dependency is missing:

```
# make missing
```

If any, install the dependency using `pkg`. For example:

```
# pkg install textproc/php73-dom devel/php73-intl sysutils/php73-fileinfo graphics/php73-exif databases/php73-pdo_pgsql databases/php73-pdo
# service php-fpm restart
```

Then proceed to installing `roundcube`:

```
# make all install clean
# pkg lock roundcube-php73
```

Create `roundcube` PostgreSQL database:

```
# su postgres
$ createuser --no-createdb --no-createrole --no-superuser --encrypted --pwprompt roundcube
$ createdb --owner=roundcube roundcube "Roundcube"
$ psql
postgres=# GRANT ALL PRIVILEGES ON DATABASE roundcube TO roundcube;
postgres=# \q
$ psql --host=localhost --username=roundcube --dbname=roundcube < /usr/local/www/roundcube/SQL/postgres.initial.sql
$ rm -f ~/.psql_history
```

Configure `roundcube`

```
# cd /usr/local/www/roundcube/config
# wget http://svn.apache.org/repos/asf/httpd/httpd/trunk/docs/conf/mime.types
# ln -s ../../../../../freebsd-configuration/usr/local/www/roundcube/config/config.inc.php
# cd /freebsd-configuration/patches/roundcube
# ./configure_roundcube_password_plugin
```

Manually edit the following in `/usr/local/www/roundcube/config.inc.php`:

 * password in `pgsql` address set for key `db_dsnw`;
 * administrator address set for key `support_url`.

Fix permissions:

```
# chown -H root:www /usr/local/www/roundcube/config/config.inc.php
# chmod -H 640 /usr/local/www/roundcube/config/config.inc.php

# chown -H root:www /usr/local/www/roundcube/plugins/password/config.inc.php
# chmod -H 640 /usr/local/www/roundcube/plugins/password/config.inc.php
```

Enable `nginx` configuration for `roundcube`:

```
# cd /usr/local/etc/nginx/sites-enabled
# ln -s ../../../../../freebsd-configuration/usr/local/etc/nginx/sites-enabled/roundcube.foo.com.conf
```

Manually edit `server_name` directives in `/usr/local/etc/nginx/sites-enabled/roundcube.foo.com.conf`.

Restart `nginx`:

```
# service nginx restart
```


### AfterLogic WebMail Pro

If Roundcube doesn't quite satisfy your needs, you might want to consider AfterLogic WebMail Pro, which is a commercial webmail application with wide-ranging groupware functionality.

#### AfterLogic WebMail Pro software itself

Make sure to refer to the official instructions to install AfterLogic WebMail Pro in the [administrator manual](https://afterlogic.com/docs/webmail-pro-8/installation/installation-instructions).

Install the web application:

```
# cd /usr/local/www
# wget https://afterlogic.com/download/webmail-pro-php.zip
# mkdir webmail
# cd webmail
# unzip ../webmail-pro-php.zip
# rm -f ../webmail-pro-php.zip
# /freebsd-configuration/patches/afterlogic-webmail-pro/afterlogic-webmail-pro-fix-permissions
# chown -R www:www data
```

Enable `nginx` configuration for AfterLogic WebMail Pro:

```
# cd /usr/local/etc/nginx/sites-enabled
# ln -s ../../../../../freebsd-configuration/usr/local/etc/nginx/sites-enabled/mail.foo.com.conf
# ln -s ../../../../../freebsd-configuration/usr/local/etc/nginx/sites-enabled/sync.foo.com.conf
```

Manually edit `server_name` directives in `/usr/local/etc/nginx/sites-enabled/mail.foo.com.conf` and in `/usr/local/etc/nginx/sites-enabled/sync.foo.com.conf`.

Restart `nginx`:

```
# service nginx restart
```

Follow [these instructions](https://afterlogic.com/docs/webmail-pro-8/installation/compatibility-test) by going to `https://mail.foo.com/?install` with your web browser, in order to figure out if your server meets the minimum requirements to run AfterLogic WebMail Pro. You might need to install additional PHP modules; for example, you might need to do the following:

```
# pkg install php73-pdo_mysql php73-tokenizer
# service php-fpm restart
```

Create `webmail` MySQL database as well as associated `webmail` user:

```
# mysql -u root -p

[...]

root@localhost [(none)]> CREATE DATABASE IF NOT EXISTS `webmail` DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
root@localhost [(none)]> CREATE USER 'webmail'@'localhost' IDENTIFIED BY 'SomeThing@1234';
root@localhost [(none)]> GRANT ALL PRIVILEGES ON webmail.* TO 'webmail'@'localhost';
```

Remove any trace of these passwords:

```
# rm -f ~/.mysql_secret ~/.mysql_history
```

Then log into the administrator interface, going to `https://mail.foo.com/` with your web browser, and follow [these instructions](https://afterlogic.com/docs/webmail-pro-8/configuring-webmail). In the database settings, you should indicate:

 * SQL login: `webmail`;
 * SQL password: same password as what you used in `CREATE USER` MySQL command above;
 * Database name: `webmail`;
 * Host: `localhost`.

In the Mobile Sync settings, make the following changes:

 * DAV server: `https://sync.foo.com/`, after replacing the domain with what you used as the `server_name` in `/usr/local/etc/nginx/sites-enabled/sync.foo.com.conf` up above.


#### Configuration adjustments

For security reasons, you may want to disallow embedding AfterLogic WebMail Pro into an `iframe`:

```
# cd /usr/local/www/webmail
# patch --posix -p1 -i /freebsd-configuration/patches/afterlogic-webmail-pro/afterlogic-webmail-pro-prevent-clickjacking-attacks.diff
```

You can also remove the *Powered by AfterLogic WebMail Pro* footer:

```
# cd /usr/local/www/webmail
# patch --posix -p1 -i /freebsd-configuration/patches/afterlogic-webmail-pro/afterlogic-webmail-pro-remove-powered-by-footer.diff
```

If you'd like to replace the email address as the name of the mail tab for something simpler and more consistent with the rest of the tab bar, you can do that with another patch:

```
# cd /usr/local/www/webmail
# patch --posix -p1 -i /freebsd-configuration/patches/afterlogic-webmail-pro/afterlogic-webmail-pro-disable-showing-email-as-tab-name.diff
```

The files functionality of AfterLogic WebMail Pro is pretty unsatisfactory, so we might as well disable it:

```
# cd /usr/local/www/webmail
# patch --posix -p1 -i /freebsd-configuration/patches/afterlogic-webmail-pro/afterlogic-webmail-pro-disable-files-functionality.diff
```


#### Allow saving messages as PDF

AfterLogic WebMail Pro has the ability to expose a button to save messages as PDF.

However, this functionality relies on a tool named `wkhtmltopdf`, which has a lot of dependencies. If you're willing to install so many package dependencies, you can enable this functionality like this:

```
# pkg install wkhtmltopdf
# cd /usr/local/www/webmail/data
# mkdir -p system/wkhtmltopdf/linux
# cd system/wkhtmltopdf/linux
# ln -s ../../../../../../bin/wkhtmltopdf
# chown -R -h www:www /usr/local/www/webmail/data/system
```


## Other client applications

### `mutt`

```
# pkg install mutt
```


### `irssi`

```
# pkg install irssi irssi-scripts
```

To launch `irssi` in a `screen` upon rebooting, add the following entry to the user's `crontab` using `crontab -e`:

```
@reboot screen -d -m -S irc env TERM=xterm-256color irssi
```


## `apache` behind `nginx` for WebDAV

Install `apache`:

```
# pkg install apache24
```

Apply basic configuration for `apache`:

```
# cd /usr/local/etc/newsyslog.conf.d
# ln -s ../../../../freebsd-configuration/usr/local/etc/newsyslog.conf.d/apache.conf

# mkdir -p /var/db/httpd-dav-lock
# cd /usr/local/etc/apache24
# mkdir -p sites-enabled
# patch --posix -p1 -i /freebsd-configuration/patches/apache/apache-base-configuration.diff
# cd sites-enabled
# ln -s ../../../../../freebsd-configuration/usr/local/etc/apache24/sites-enabled/files.foo.com.conf
```

Enable `apache`:

```
# cd /etc/rc.conf.d
# ln -s ../../freebsd-configuration/etc/rc.conf.d/apache24
# service apache24 start
```

Configure `nginx` to proxy to `apache`:

```
# cd /usr/local/etc/nginx
# ln -s ../../../../freebsd-configuration/usr/local/etc/nginx/redirect_to_apache_ssl
# cd sites-enabled
# ln -s ../../../../../freebsd-configuration/usr/local/etc/nginx/sites-enabled/files.foo.com.conf
# service nginx restart
```


## Gate One

Install some important dependencies of Gate One:

```
# pkg install sudo
# pkg install dtach
# pkg install py37-futures
# pkg install py37-tornado4
```

Make sure to load the `pty` kernel module for pseudo-terminal support:

```
# kldload pty
```

And make sure to include the following directive in `/boot/loader.conf`:

```
pty_load="YES"
```

Add unprivileged user for Gate One:

```
# pw group add gateone -g 647
# pw user add gateone -u 647 -g 647 -c "Gate One" -d /usr/local/gateone -s /usr/local/bin/zsh -m -k /usr/local/etc/skel
```

Give `gateone` unprivileged user the ability to call `login` using `sudo` without requiring password authentication.

```
# cp /freebsd-configuration/usr/local/etc/sudoers.d/gateone /usr/local/etc/sudoers.d
# chown root:wheel /usr/local/etc/sudoers.d/gateone
# chmod 440 /usr/local/etc/sudoers.d/gateone
# su gateone
```

Proceed with installation:

```
$ export PYTHONPATH="$HOME/lib/python3.7/site-packages"
$ mkdir -p "$PYTHONPATH"
$ git clone https://github.com/liftoff/GateOne.git gateone
$ cd gateone
$ git am /freebsd-configuration/patches/gateone/gateone-python-3-7-compatibility-stop-using-reserved-keywords-async-and-await.patch
$ git am /freebsd-configuration/patches/gateone/gateone-python-3-7-compatibility-workaround-regression-with-process-pool-executor-shutdown.patch
$ python3.7 setup.py install --prefix=/usr/local/gateone
```

Launch Gate One manually once so it will lay down its own configuration file:

```
$ ~/bin/gateone --settings_dir="$HOME/etc/gateone" --disable_ssl="true" --port=2222 --origins="localhost;127.0.0.1"
```

Interrupt with Control+C.

Replace `50terminal.conf`:

```
$ cd ~/etc/gateone
$ rm -f 50terminal.conf
$ ln -s ../../../../../freebsd-configuration/usr/local/gateone/etc/gateone/50terminal.conf
```

Install bootstrap script:

```
# cd /usr/local/etc/rc.d
# ln -s ../../../../freebsd-configuration/usr/local/etc/rc.d/gateone
# chmod -H 555 gateone
# chown -R gateone:gateone /freebsd-configuration/usr/local/gateone
```

Enable Gate One:

```
# cd /etc/rc.conf.d
# ln -s ../../freebsd-configuration/etc/rc.conf.d/gateone
# service gateone start
```

Enable Gate One virtual host for `nginx`:

```
# cd /usr/local/etc/nginx/sites-enabled
# ln -s ../../../../../freebsd-configuration/usr/local/etc/nginx/sites-enabled/gateone.foo.com.conf
# service nginx restart
```


## GitLab

Configure and enable a new `redis` instance dedicated to GitLab:

```
# cd /var/db/redis
# mkdir gitlab
# chown redis:redis gitlab

# cd /usr/local/etc
# ln -s ../../../freebsd-configuration/usr/local/etc/redis-gitlab.conf

# cd /usr/local/etc/newsyslog.conf.d
# ln -s ../../../../freebsd-configuration/usr/local/etc/newsyslog.conf.d/redis-gitlab.conf

# cd /etc/rc.conf.d/redis.d
# ln -s ../../../freebsd-configuration/etc/rc.conf.d/redis.d/gitlab
# service redis start gitlab
```

Install other required dependencies:

```
# pkg install sudo bash icu cmake pkgconf node npm phantomjs krb5 gmake go libtool bison re2 yarn libgit2 ruby rubygem-bundler
```

Install `chruby` to be able to select a specific version of ruby for GitLab:

```
# pkg install chruby
```

Install specific version of ruby for GitLab:

```
# wget "https://cache.ruby-lang.org/pub/ruby/2.7/ruby-2.7.2.tar.gz"
# tar xvzf ruby-2.7.2.tar.gz
# cd ruby-2.7.2
# ./configure --prefix=/opt/rubies/ruby-2.7.2
# make
# make install
# cd ..
# rm -R -f ruby-2.7.2 ruby-2.7.2.tar.gz
```

Install `bundler` for that specific version of ruby:

```
# source /usr/local/share/chruby/chruby.sh
# chruby ruby-2.7.2
# gem install bundler -v "2.1.4"
```

Add unprivileged user for GitLab:

```
# pw group add git -g 617
# pw user add git -u 617 -g 617 -c "GitLab" -d /usr/local/git -s /usr/local/bin/zsh -m -k /usr/local/etc/skel
# pw group mod redis -m git
```

Lay down configuration and local scripts for this unprivileged user:

```
# su git
$ rm -f .zshrc .zshenv
$ for file_name in .zshenv .zshrc .gitconfig bin; do ln -s ../../../freebsd-configuration/usr/local/git/${file_name}; done
$ exit
```

Prepare database:

```
# su postgres
$ createuser --no-createdb --no-createrole --no-superuser --encrypted --pwprompt gitlab
$ createdb --owner=gitlab gitlab "GitLab"
$ psql
postgres=# GRANT ALL PRIVILEGES ON DATABASE gitlab TO gitlab;
postgres=# CREATE EXTENSION IF NOT EXISTS pg_trgm;
postgres=# \q
$ psql gitlab
gitlab=# CREATE EXTENSION IF NOT EXISTS pg_trgm;
gitlab=# \q
$ rm -f ~/.psql_history
```

Complete installation drawing some inspiration from the instructions in [this guide](https://github.com/gitlabhq/gitlab-recipes/blob/master/install/freebsd/freebsd-10.md#6-install-and-set-up-gitlab); go straight to part 6 of this guide, named *Install and set up GitLab*.

Some important differences:

 * don't apply the change described as "Change the Redis socket path to `/usr/local/var/run/redis/redis.sock`"; instead, change it to `/var/run/redis/gitlab.sock`, as shown in `/freebsd-configuration/usr/local/git/gitlab/config/resque.yml`; also disregard other instructions about `redis` configuration, since this was covered above with a new `redis` instance dedicated to GitLab;
 * change `/home/*` to `/usr/local/*`;
 * before installing the bundle for either `gitaly` or `gitlab`, you will probably need to make the following adjustments:

```
$ bundle config build.rugged --use-system-libraries
$ bundle config build.gpgme --use-system-libraries
$ bundle config build.charlock_holmes --with-opt-include=/usr/local/include --with-opt-lib=/usr/local/lib
```

 * use the following instructions for the init script instead of the ones from the guide:

```
# cd /usr/local/etc/rc.d
# ln -s ../../../../freebsd-configuration/usr/local/etc/rc.d/gitlab
# chmod -H 555 gitlab

# cd /etc/rc.conf.d
# ln -s ../../freebsd-configuration/etc/rc.conf.d/gitlab
# service gitlab start
```


## Nextcloud

Make sure to refer to the official instructions to install Nextcloud in the [administrator manual](https://docs.nextcloud.com/server/15/admin_manual/installation/index.html).

You should also consider your options for [memory caching](https://docs.nextcloud.com/server/15/admin_manual/configuration_server/caching_configuration.html). In our case, we'll follow the recommendation for *Small organization, single-server setup* from an [older version of the Nextcloud administrator manual](https://docs.nextcloud.com/server/14/admin_manual/configuration_server/caching_configuration.html#small-organization-single-server-setup), which is to say that we'll use APCu for local caching, and Redis for file locking.

### Redis backend

Configure and enable a new `redis` instance dedicated to Nextcloud:

```
# cd /var/db/redis
# mkdir nextcloud
# chown redis:redis nextcloud

# cd /usr/local/etc
# ln -s ../../../freebsd-configuration/usr/local/etc/redis-nextcloud.conf

# cd /usr/local/etc/newsyslog.conf.d
# ln -s ../../../../freebsd-configuration/usr/local/etc/newsyslog.conf.d/redis-nextcloud.conf

# cd /etc/rc.conf.d/redis.d
# ln -s ../../../freebsd-configuration/etc/rc.conf.d/redis.d/nextcloud
# service redis start nextcloud
```


### Basic installation

Here are down below some of the steps where we deviate slightly from that manual installation guide.

```
# cd /usr/ports/www/nextcloud
# make config
```

Keep all options enabled by default, except for `MYSQL` in the *Database backend(s)* section, which you should disable; and additionally enable the following:

 * `IMAGICK` in first section;
 * `PCNTL` in first section;
 * `REDIS` in *Caching* section;
 * `PGSQL` in *Database backend(s)* section.

See if any dependency is missing:

```
# make missing
```

If any, install the dependencies using `pkg`. For example:

```
# pkg install php73-pecl-imagick php73-pecl-redis php73-pecl-APCu
# pkg install math/php73-bcmath ftp/php73-curl math/php73-gmp sysutils/php73-posix textproc/php73-simplexml textproc/php73-xmlreader textproc/php73-xmlwriter textproc/php73-xsl www/php73-opcache devel/php73-pcntl
```

Then proceed to installing `nextcloud`:

```
# make all install clean
# pkg lock nextcloud-php73
```

Prepare database:

```
# su postgres
$ createuser --no-createdb --no-createrole --no-superuser --encrypted --pwprompt nextcloud
$ createdb --owner=nextcloud nextcloud "Nextcloud"
$ psql
postgres=# GRANT ALL PRIVILEGES ON DATABASE nextcloud TO nextcloud;
postgres=# \q
$ rm -f ~/.psql_history
```

Grant the web server unprivileged user access to Redis:

```
# pw group mod redis -m www
```

Adjust `php` configuration with some optimizations for Nextcloud.

```
# cd /freebsd-configuration/patches/nextcloud
# ./configure_php_for_nextcloud
# service php-fpm restart
```

Enable `nginx` configuration for Nextcloud:

```
# cd /usr/local/etc/nginx/sites-enabled
# ln -s ../../../../../freebsd-configuration/usr/local/etc/nginx/sites-enabled/cloud.foo.com.conf
```

Manually edit `server_name` directives in `/usr/local/etc/nginx/sites-enabled/cloud.foo.com.conf`.

Restart `nginx`:

```
# service nginx restart
```

Follow the [installation wizard](https://docs.nextcloud.com/server/15/admin_manual/installation/installation_wizard.html) to bootstrap the configuration of your Nextcloud installation.

You may want to enable [pretty URLs](https://docs.nextcloud.com/server/15/admin_manual/installation/source_installation.html#pretty-urls), but make sure to temporarily change the ownership of `config/.htaccess` before running the required maintenance task:

```
# cd /usr/local/www/nextcloud
# chown www config/.htaccess .htaccess
# sudo -u www php /usr/local/www/nextcloud/occ maintenance:update:htaccess
# chown root config/.htaccess .htaccess
```

and make sure to add the following directives to `/usr/local/www/nextcloud/config/config.php`:

```
'overwrite.cli.url' => 'https://cloud.foo.com',
'htaccess.RewriteBase' => '/',
```

Additionally, adjust your configuration options in that same file, `/usr/local/www/nextcloud/config/config.php`, for memory caching and file locking:

```
  'filelocking.enabled' => true,
  'memcache.local' => '\\OC\\Memcache\\APCu',
  'memcache.locking' => '\\OC\\Memcache\\Redis',
  'redis' =>
  array (
    'host' => '/var/run/redis/nextcloud.sock',
    'port' => 0,
    'timeout' => 0.0,
  ),
```

Finally, setup a cron job for Nextcloud maintenance tasks:

```
# mkdir -p /usr/local/etc/cron.d
# cd /usr/local/etc/cron.d
# ln -s ../../../../freebsd-configuration/usr/local/etc/cron.d/nextcloud-cron
```

### Ensure proper basic configuration

 * Go to `https://cloud.foo.com/` with your web browser and login with your administrator account.
 * Click the avatar icon on the top right, and then *Settings* in the popup menu.
 * In the side menu on the left, click *Overview* right below the *Administration* section heading.
 * In the section titled *Security & setup warnings*, wait for results of these checks to appear, and take appropriate action for each action item.

In our case, at this point, there was a warning about incorrect types for big integers in the database, which is easily addressed by running the following command:

```
# sudo -u www php /usr/local/www/nextcloud/occ db:convert-filecache-bigint
```

 * In the side menu on the left, click *Basic settings* below the *Administration* section heading.
 * In the section titled *Background jobs*, select *Cron* as the preferred method for running maintenance tasks.
 * In the section titled *Email server*, adjust configuration as needed to make sure Nextcloud can send emails to its users.

### LDAP configuration for Nextcloud

You will need to make a few adjustments to your LDAP directory in preparation of linking Nextcloud to it.

To make those adjustments, you may want to take advantage of the LDAP scripts to populate the directory mentioned above and installed in `/opt/local`.

Create an LDAP account for Nextcloud:

```
# ldap_create_user --system --cn "nextcloud"
```

Also augment LDAP entries for any user or group you want to have access to Nextcloud with the `applicationParticipant` schema, and this property:

```
supportedApplication: nextcloud
```

Groups will also require being augmented with the `fullyQualifiedGroup` schema, and the following property:

```
fullyQualifiedGroupName: <some_unique_group_name>
```

The point is simply that, with the kind of multi-domain LDAP setup we have on our server, you may have multiple groups with the same common name in different branches of the LDAP tree, for different domains. A simple pattern for coming up with the value of that fully qualified group name is to concatenate the group's common name with the domain name, separated by a delimiter such as `%`: `<group_cn>%<domain_name>`, which is the default behavior of the `ldap_create_group` script when you pass the option `--fully-qualified`.

Once all those changes are applied, we can configure Nextcloud to point to our LDAP server.

 * Go to `https://cloud.foo.com/` with your web browser and login with your administrator account.
 * Click the avatar icon on the top right, and then *Settings* in the popup menu.
 * In the side menu on the left, further down below the *Administration* section heading, click *LDAP / AD Integration*.
 * In the *Server* tab:
    - enter your LDAP server address as `localhost`, and click the *Detect Port* button; it should find the port number 389;
    - in the field for the *DN of the client user with which the bind shall be done*, enter `cn=nextcloud,ou=users,ou=system,ou=directory`;
    - right below, enter the associated password below;
    - in the field for the *Base DN*, enter `ou=directory`.
 * In the *Users* tab, enter the following in the text box below *Edit LDAP Query*:

```
(&(objectClass=inetOrgPerson)(ou:dn:=users)(supportedApplication=nextcloud)(uid=*)(mail=*))
```

 * In the *Login Attributes* tab, enter the following in the text box below *Edit LDAP Query*:

```
(&(objectClass=inetOrgPerson)(ou:dn:=users)(supportedApplication=nextcloud)(mail=%uid))
```

 * In the *Groups* tab, enter the following in the text box below *Edit LDAP Query*:

```
(&(objectClass=fullyQualifiedGroup)(ou:dn:=groups)(supportedApplication=nextcloud)(fullyQualifiedGroupName=*))
```

 * In the *Advanced* tab, disclose the *Directory Settings* section, and make the following changes:
    - in the pop-up menu for *Group-Member association*, select *member (AD)*;
    - in the text field for *Group Display Name Field*, enter `fullyQualifiedGroupName`.

### Full Text Search for Nextcloud

The following is heavily inspired by [Neil Feltham's amazing howto guide](https://lothiancaleysweb.co.uk/how-to-install-fulltextsearch-in-nextcloud-with-elasticsearch-and-tesseract-ocr).

For full text search support, we'll be using Elasticsearch, which depends on Java.

#### Prepare for installing Java

The `openjdk8` package in FreeBSD requires a few special file systems to be mounted:

 * `fdescfs` needs to be mounted on `/dev/fd`;
 * `procfs` needs to be mounted on `/proc`.

This is already in place in this repository's `/etc/fstab`, but if you don't have the corresponding entries in your `/etc/fstab`, add them, and then run the following commands, as needed:

```
# mount -t fdescfs fdesc /dev/fd
# mount -t procfs proc /proc
```

#### Install Elasticsearch

```
# pkg install elasticsearch6
# cd /etc/rc.conf.d
# ln -s ../../freebsd-configuration/etc/rc.conf.d/elasticsearch
# cd /freebsd-configuration/patches/elasticsearch
# ./configure_elasticsearch
# service elasticsearch start
```

To check that the Elasticsearch server is running, enter the following:

```
# curl -XGET '127.0.0.1:9200/?pretty'
```

You should see output like this:

```
{
  "name" : "gq3rrjS",
  "cluster_name" : "elasticsearch",
  "cluster_uuid" : "aRlhEpf4QmGIHmWFA0_BWg",
  "version" : {
    "number" : "6.5.4",
    "build_flavor" : "default",
    "build_type" : "tar",
    "build_hash" : "d2ef93d",
    "build_date" : "2018-12-17T21:17:40.758843Z",
    "build_snapshot" : false,
    "lucene_version" : "7.5.0",
    "minimum_wire_compatibility_version" : "5.6.0",
    "minimum_index_compatibility_version" : "5.0.0"
  },
  "tagline" : "You Know, for Search"
}
```

Install the `ingest-attachment` plugin for Elasticsearch, which is required to facilitate searches within certain types of files.

```
# /usr/local/lib/elasticsearch/bin/elasticsearch-plugin install ingest-attachment
# service elasticsearch restart
```

#### Install Tesseract Optical Character Recognition

```
# pkg install tesseract tesseract-data
```

#### Configure Nextcloud

Install the `readline` PHP package:

```
# pkg install php73-readline
# service php-fpm restart
# service nginx restart
```

Go to `https://cloud.foo.com/` with your web browser, login with your administrator account, and install the following plugins:

 * Full text search
 * Full text search - Elasticsearch Platform
 * Full text search - Files
 * Full text search - Files - Tesseract OCR
 * Full text search - Bookmarks

Then follow the instructions as outlined in the last part of [Neil Feltham's howto guide](https://lothiancaleysweb.co.uk/how-to-install-fulltextsearch-in-nextcloud-with-elasticsearch-and-tesseract-ocr/2#6), with the following adjustments for FreeBSD:

 * replace `/var/www/html/nextcloud` with `/usr/local/www/nextcloud`;
 * replace `www-data` with `www`.

So for example, for the step titled *Create the index*, after configuring full text search in Nextcloud's web interface, you'll end up running this command:

```
# sudo -u www php /usr/local/www/nextcloud/occ fulltextsearch:index
```

#### Live Index Service for Nextcloud Full Text Search

To have your files continuously indexed, you need to install a new service.

```
# cd /usr/local/etc/rc.d
# ln -s ../../../../freebsd-configuration/usr/local/etc/rc.d/nextcloud-full-text-search
# chmod -H 555 nextcloud-full-text-search

# cd /etc/rc.conf.d
# ln -s ../../freebsd-configuration/etc/rc.conf.d/nextcloud_full_text_search
# service nextcloud-full-text-search start
```

For some reason, and despite my best efforts to address that, your shell may start behaving weirdly after starting this new service, as if it's eating a bunch of your keystrokes. The best solution I found to this was to simply disconnect from the current SSH session, close the Terminal tab or window, and create a new one.


### Integrate AfterLogic WebMail Pro with Nextcloud

To make this work, you'll need to expose AfterLogic WebMail Pro with the same origin as the Nextcloud installation:

```
# cd /usr/local/etc/nginx/sites-enabled
# mkdir -p cloud.foo.com.conf.d
# cd cloud.foo.com.conf.d
# ln -s ../../../../../../freebsd-configuration/usr/local/etc/nginx/sites-enabled/cloud.foo.com.conf.d/mail.conf
```

Then follow instructions about [Nextcloud integration](https://afterlogic.com/docs/webmail-pro-8/configuring-webmail/nextcloud-integration) from AfterLogic WebMail Pro's documentation.


## Time Machine Server

You should consider tuning a few kernel settings to allow more files to be opened at once. In particular, consider the following settings:

```
kern.maxfiles=25600
kern.maxfilesperproc=16384
net.inet.tcp.sendspace=65536
net.inet.tcp.recvspace=65536
```

To do this, you may simply use our `sysctl.conf` file:

```
# cd /etc
# rm -f sysctl.conf ; ln -s ../freebsd-configuration/etc/sysctl.conf
# sysctl --system
```

Install `netatalk3` for AFP file transfer protocol, and `nss_mdns` for multicast DNS support.

```
# pkg install netatalk3
# pkg install nss_mdns
```

Enable `mdns` for Avahi, which will allow advertising services via Bonjour:

```
# cd /etc
# rm -f nsswitch.conf ; ln -s ../freebsd-configuration/etc/nsswitch.conf
```

Alternatively, just make sure that the following line is present in `/etc/nsswitch.conf`:

```
hosts: files mdns_minimal [NOTFOUND=return] dns mdns
```

Prepare Time Machine folder:

```
# chmod o+x /var/backups
# mkdir /var/backups/time-machine
```

Configure `netatalk3`:

```
# cd /usr/local/etc
# rm -f afp.conf ; ln -s ../../../freebsd-configuration/usr/local/etc/afp.conf
```

Enable relevant daemons:

```
# cd /etc/rc.conf.d

# ln -s ../../freebsd-configuration/etc/rc.conf.d/dbus
# ln -s ../../freebsd-configuration/etc/rc.conf.d/avahi_daemon
# ln -s ../../freebsd-configuration/etc/rc.conf.d/netatalk

# service dbus start
# service avahi-daemon start
# service netatalk start
```

For better performance and possibly better reliability with Time Machine backups, make sure to follow [this tutorial](http://endlessgeek.com/2014/03/improve-time-machine-performance-big-bands/).


## Plex Media Server

Install `plexmediaserver-plexpass` package:

```
# pkg install plexmediaserver-plexpass
```

Enable `plexmediaserver-plexpass` daemon:

```
# cd /etc/rc.conf.d
# ln -s ../../freebsd-configuration/etc/rc.conf.d/plexmediaserver_plexpass
# service plexmediaserver_plexpass start
```

