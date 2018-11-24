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
# pkg install zsh figlet
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
# pkg install mmv
# pkg install htop
# pkg install screen
# pkg install wget
# pkg install bash
# pkg install most
# pkg install par_format
# pkg install gmake
# pkg install pwgen
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


## SSL

```
# pw group add ssl -g 551
# pw user add ssl -u 551 -g 551 -c "SSL Unprivileged User" -d /var/empty -s /usr/sbin/nologin
# pw group mod ssl -m www
# mkdir -p /etc/ssl/certs /etc/ssl/private
# chown root:ssl /etc/ssl/private
# chmod 710 /etc/ssl/private
```

Assuming you have an SSL certificate named `foo.com_wildcard`, install it like this:

```
# cp foo.com_wildcard.pem /etc/ssl/certs
# cp foo.com_wildcard.key /etc/ssl/private
# chown root:ssl /etc/ssl/private/foo.com_wildcard.key
# chmod 640 /etc/ssl/private/foo.com_wildcard.key
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
# for file_name in virtual_mail.schema virtual_mail.ldif mailing_list.schema mailing_list.ldif; do ln -s ../../../../../../freebsd-configuration/usr/local/etc/openldap/schema/${file_name}; done
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

To populate the LDAP directory, you may use some scripts provided as part of this repository, which take advantage of the custom schemas used above, namely `virtual_mail` and `mailing_list`.

```
# mkdir -p /opt/local/lib
# cd /opt/local/lib
# for file_name in ../../../freebsd-configuration/opt/local/lib/ldap_*; do ln -s "${file_name}"; done
# mkdir -p /opt/local/bin
# cd /opt/local/bin
# for file_name in ../../../freebsd-configuration/opt/local/bin/ldap_*; do ln -s "${file_name}"; done
```

Some examples of how you can use these scripts to populate the LDAP directory can be found at `/freebsd-configuration/documentation/ldap/ldap_setup_multi_domain_directory_with_sample_entries`.


## `nginx` and `php`

```
# pkg install nginx
# pkg install php71
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

# cd /usr/local/etc/nginx
# rm -f nginx.conf
# for file_name in nginx.conf error_pages php php_ssl redirect_to_ssl ssl_wildcard_certificate; do ln -s ../../../../freebsd-configuration/usr/local/etc/nginx/${file_name}; done
```

Manually edit `ssl_certificate` and `ssl_certificate_key` in `/usr/local/etc/nginx/ssl_wildcard_certificate` to point to your own SSL certificate.

```
# mkdir sites-enabled
# cd sites-enabled
# ln -s ../../../../../freebsd-configuration/usr/local/etc/nginx/sites-enabled/default.conf
# ln -s ../../../../../freebsd-configuration/usr/local/etc/nginx/sites-enabled/admin.foo.com.conf
# mkdir admin.foo.com.conf.d
```

Manually edit `server_name` directives in `/usr/local/etc/nginx/sites-enabled/admin.foo.com.conf`.

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
# pkg install phpMyAdmin-php71
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
# pkg install postgresql95-client postgresql95-server postgresql95-contrib
# cd /etc/rc.conf.d
# ln -s ../../freebsd-configuration/etc/rc.conf.d/postgresql
# service postgresql initdb
# cd /freebsd-configuration/patches/postgresql
# ./configure_postgresql
# service postgresql start
# chown -R pgsql:pgsql /freebsd-configuration/usr/local/pgsql
# cd /usr/local/pgsql
# ln -s ../../../freebsd-configuration/usr/local/pgsql/.zshenv
# ln -s ../../../freebsd-configuration/usr/local/pgsql/.zshrc
```

Change the Unix password of `pgsql` user:

```
# passwd pgsql
```

And alter password of `pgsql` user in the database:

```
# su pgsql
$ psql postgres

[...]

postgres=# ALTER USER pgsql WITH PASSWORD 'SomeThing@1234';
postgres=# \q
$ rm -f ~/.psql_history
```


## `phpPgAdmin`

```
# pkg install phppgadmin-php71
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
# pkg install phpldapadmin
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


## Email

The following is heavily inspired from [Kliment Andreev's amazing howto guide](https://blog.iandreev.com/?p=1604).

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
 * `PGSQL` in *Database support* section;
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
# mkdir /var/mail/virtual
# chown virtual_mail:virtual_mail /var/mail/virtual
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


### Content filters (anti-spam and anti-virus)

Install content filter tools:

```
# pkg install amavisd-new clamav spamassassin
```

Initialize and enable `spamassassin`:

```
# sa-update -D
# cd /usr/local/etc/periodic/daily
# ln -s ../../../../../freebsd-configuration/usr/local/etc/periodic/daily/340.spamassassin-update
# cd /etc/rc.conf.d
# ln -s ../../freebsd-configuration/etc/rc.conf.d/spamd
# service sa-spamd start
```

Initialize and enable ClamAV:

```
# pw group mod vscan -m clamav
# freshclam
# cd /etc/rc.conf.d
# ln -s ../../freebsd-configuration/etc/rc.conf.d/clamav_clamd
# ln -s ../../freebsd-configuration/etc/rc.conf.d/clamav_freshclam
# service clamav-clamd start
# service clamav-freshclam start
```

Apply base patch for `amavisd` configuration file:

```
# cd /usr/local/etc
# chmod u+w amavisd.conf
# patch --posix -p1 -i /freebsd-configuration/patches/amavis/amavisd.conf.diff
```

Manually edit `$mydomain` and `$myhostname` in `/usr/local/etc/amavisd.conf`.

Enable `amavisd`:

```
# chmod u-w amavisd.conf
# cd /etc/rc.conf.d
# ln -s ../../freebsd-configuration/etc/rc.conf.d/amavisd
# service amavisd start
```

TODO: Look into `pyzor`, `razor`, `SPF`, `DKIM`.


### `postfix`

```
# cd /usr/ports/mail/postfix
# make config
```

Keep all options enabled by default, and additionally enable the following:

 * `LDAP`;
 * `PGSQL`.

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
# cd /usr/local/etc/postfix
# patch --posix -p1 -i /freebsd-configuration/patches/postfix/postfix-master.cf.diff
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

The following is heavily inspired from [Kliment Andreev's howto guide on `roundcube`](https://blog.iandreev.com/?p=1339).

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
# pkg install textproc/php71-dom devel/php71-intl sysutils/php71-fileinfo graphics/php71-exif databases/php71-pdo_pgsql databases/php71-pdo
# service php-fpm restart
```

Then proceed to installing `roundcube`:

```
# make all install clean
# pkg lock roundcube
```

Create `roundcube` PostgreSQL database:

```
# su pgsql
$ createuser --no-createdb --no-createrole --no-superuser --encrypted --pwprompt roundcube
$ createdb --owner=roundcube roundcube "Roundcube"
$ psql postgres
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

Manually edit the following in `/usr/local/www/roundcube/plugins/password/config.inc.php`:

 * password in `pgsql` address set for key `password_db_dsn`.

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
# ln -s ../../../../../freebsd-configuration/usr/local/etc/nginx/sites-enabled/mail.foo.com.conf
```

Manually edit `server_name` directives in `/usr/local/etc/nginx/sites-enabled/mail.foo.com.conf`.

Restart `nginx`:

```
# service nginx restart
```


### `mailman`

##### `mailman` software itself

```
# cd /usr/ports/mail/mailman
# make config
```

Keep all options enabled by default, and additionally enable the following:

 * `POSTFIX` in *Integrate with which MTA?* section.

See if any dependency is missing:

```
# make missing
```

If any, install the dependency using `pkg`. For example:

```
# pkg install dns/py-dnspython devel/automake devel/automake-wrapper security/fakeroot
```

Then proceed to installing `mailman`:

```
# make all install clean
# pkg lock mailman
```

Configure `mailman`:

```
# cd /usr/local/mailman/Mailman
# ln -s ../../../../freebsd-configuration/usr/local/mailman/Mailman/mm_cfg.py
# chown -H root:mailman /usr/local/mailman/Mailman/mm_cfg.py
```

Manually edit the following options with your own domain name in `/usr/local/mailman/Mailman/mm_cfg.py`:

 * `DEFAULT_EMAIL_HOST`;
 * `DEFAULT_URL_HOST`;
 * `POSTFIX_STYLE_VIRTUAL_DOMAINS`;
 * `FREEBSD_LISTMASTER`.

Enable `mailman`:

```
# cd /etc/rc.conf.d
# ln -s ../../freebsd-configuration/etc/rc.conf.d/mailman
# service mailman start
```


##### Integration with `postfix`

This part was inspired from [FreeBSD Diary's amazing howto guide](http://www.freebsddiary.org/mailman.php).

Make sure that the following configuration option in `/usr/local/etc/postfix/main.cf` is uncommented:

```
mailman_destination_recipient_limit = 1
```

Make sure your lists subdomain is enabled in `/usr/local/etc/postfix/transport`:

```
lists.foo.com           mailman:
```

Rebuild `transport.db`:

```
# cd /usr/local/etc/postfix
# postmap transport
```

Install `postfix-to-mailman.py` script:

```
# cd /usr/local/mailman/bin
# ln -s ../../../../freebsd-configuration/usr/local/mailman/bin/postfix-to-mailman.py
# chown -H root:mailman /usr/local/mailman/bin/postfix-to-mailman.py
# chmod -H +x /usr/local/mailman/bin/postfix-to-mailman.py
```

Apply patch for `master.cf` to defer Mailman traffic to `postfix-to-mailman.py`:

```
# cd /usr/local/etc/postfix
# patch --posix -p1 -i /freebsd-configuration/patches/postfix/postfix-integration-with-mailman-master.cf.diff
```

Restart `postfix`:

```
# service postfix restart
```


##### Integration with `nginx`

This part was inspired from [My Wushu Blog's amazing howto guide](https://www.mywushublog.com/2012/05/mailman-with-nginx-on-freebsd/).

Install `fcgiwrap`:

```
# pkg install fcgiwrap
```

Enable `fcgiwrap`:

```
# cd /etc/rc.conf.d
# ln -s ../../freebsd-configuration/etc/rc.conf.d/fcgiwrap
# service fcgiwrap start
```

Enable mailing lists virtual host for `nginx`:

```
# cd /usr/local/etc/nginx/sites-enabled
# ln -s ../../../../../freebsd-configuration/usr/local/etc/nginx/sites-enabled/lists.foo.com.conf
```

Restart `nginx`:

```
# service nginx restart
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


## `bind`

```
# pkg install bind911

# mkdir /var/named
# cd /var/named
# git clone https://github.com/JoeKun/freebsd-configuration.git

# mkdir -p usr/local/etc var/db/namedb var/db/namedb/managed-keys
# chgrp bind var/db/namedb var/db/namedb/managed-keys
# chmod 775 var/db/namedb var/db/namedb/managed-keys
# chown bind:bind .
# chmod 700 .

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


## `apache` behind `nginx` for WebDAV

Install `apache`:

```
# pkg install apache24
```

Apply basic configuration for `apache`:

```
# mkdir -p /var/db/httpd-dav-lock
# cd /usr/local/etc/apache24
# mkdir -p sites-enabled
# patch --posix -p1 -i /freebsd-configuration/patches/apache/apache-base-configuration.diff
# cd sites-enabled
# ln -s ../../../../../freebsd-configuration/usr/local/etc/apache24/sites-enabled/personal-files.foo.com.conf
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
# ln -s ../../../../../freebsd-configuration/usr/local/etc/nginx/sites-enabled/personal-files.foo.com.conf
# service nginx restart
```


## GateOne

Install some important dependencies of GateOne:

```
# pkg install sudo
# pkg install dtach
# pkg install py27-tornado4
```

Make sure to load the `pty` kernel module for pseudo-terminal support:

```
# kldload pty
```

And make sure to include the following directive in `/boot/loader.conf`:

```
pty_load="YES"
```

Add unprivileged user for GateOne:

```
# pw group add gateone -g 647
# pw user add gateone -u 647 -g 647 -c "GateOne" -d /usr/local/gateone -s /usr/local/bin/zsh -m -k /usr/local/etc/skel
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
$ mkdir -p "$HOME/lib/python$(python -V 2>&1 | grep -o '[0-9].[0-9]')/site-packages"
$ export PYTHONPATH="$HOME/lib/python$(python -V 2>&1 | grep -o '[0-9].[0-9]')/site-packages"
$ git clone https://github.com/liftoff/GateOne.git gateone
$ cd gateone
$ python setup.py install --prefix=/usr/local/gateone
```

Launch GateOne manually once so it will lay down its own configuration file:

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

Enable GateOne:

```
# cd /etc/rc.conf.d
# ln -s ../../freebsd-configuration/etc/rc.conf.d/gateone
# service gateone start
```

Enable GateOne virtual host for `nginx`:

```
# cd /usr/local/etc/nginx/sites-enabled
# ln -s ../../../../../freebsd-configuration/usr/local/etc/nginx/sites-enabled/gateone.foo.com.conf
# service nginx restart
```


## GitLab

Install and enable `redis`:

```
# pkg install redis

# cd /etc/rc.conf.d
# ln -s ../../freebsd-configuration/etc/rc.conf.d/redis
# service redis start
```

Install other required dependencies:

```
# pkg install sudo bash icu cmake pkgconf node npm phantomjs krb5 gmake go libtool bison re2 yarn libgit2 ruby rubygem-bundler
```

Add unprivileged user for GitLab:

```
# pw group add git -g 617
# pw user add git -u 617 -g 617 -c "GitLab" -d /usr/local/git -s /usr/local/bin/zsh -m -k /usr/local/etc/skel
# pw group mod redis -m git
```

Prepare database:

```
# su pgsql
$ createuser --no-createdb --no-createrole --no-superuser --encrypted --pwprompt gitlab
$ createdb --owner=gitlab gitlab "GitLab"
$ psql postgres
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

 * don't apply the change described as "Change the Redis socket path to `/usr/local/var/run/redis/redis.sock`";
 * change `/home/*` to `/usr/local/*`;
 * use the following instructions for the init script instead of the ones from the guide.

```
# cd /usr/local/etc/rc.d
# ln -s ../../../../freebsd-configuration/usr/local/etc/rc.d/gitlab
# chmod -H 555 gitlab

# cd /etc/rc.conf.d
# ln -s ../../freebsd-configuration/etc/rc.conf.d/gitlab
# service gitlab start
```


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

If you're interested in cutting commercials, you should also follow these instructions.

```
# pkg install ffmpeg
# pkg install autoconf
# pkg install automake
# pkg install libtool
# pkg install argtable
# pkg install gcc6
# export CC=gcc6

# git clone --depth 1 https://github.com/erikkaashoek/Comskip comskip
# cd comskip
# ./autogen.sh
# ./configure --prefix=/opt/local
# make
# make install
# cd ..
# rm -R -f comskip

# git clone --depth 1 https://github.com/BrettSheleski/comchap
# cp -av comchap/comchap comchap/comcut /opt/local/bin
# rm -R -f comchap

# mkdir -p /opt/local/etc
# cd /opt/local/etc
# ln -s ../../../freebsd-configuration/opt/local/etc/comskip.ini

# cd /opt/local/bin
# ln -s ../../../freebsd-configuration/opt/local/bin/plex_post_process_tv_content
```

Then, go to Plex's Server Settings, in the Live TV & DVR section. Click the DVR settings link, and set `/opt/local/bin/plex_post_process_tv_content` as the postprocessing script for recorded programs.

