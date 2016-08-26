# Common packages and configuration for FreeBSD

## Setup ssh keys for `root` and `admin` users

```
# ssh-keygen -t rsa -b 4096 -C foo@foo.com
# cp -av ~/.ssh ~admin
# chown -R admin:admin ~admin/.ssh
```

Upload contents of `~/.ssh/id_rsa.pub` to GitHub.


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

Repeat this for `admin`:

```
$ cd
$ git clone https://github.com/JoeKun/freebsd-configuration.git
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

Repeat this for `admin` in the user's home directory:

```
$ cd
$ ln -s freebsd-configuration/home/foo/.gitconfig
$ mkdir -p .config
$ cd .config
$ ln -s ../freebsd-configuration/home/foo/.config/git
```


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

Link to user `zsh` configuration files for `admin`:

```
$ cd
$ for file_name in .zshenv .zshrc; do ln -s freebsd-configuration/root/${file_name}; done
$ chsh -s /usr/local/bin/zsh
```


## `vim`

```
# pkg install vim
# cd /usr/local/etc/vim
# rm -f vimrc ; ln -s ../../../../freebsd-configuration/usr/local/etc/vim/vimrc
# cd /root
# ln -s ../freebsd-configuration/root/.vim
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
# cd /freebsd-configuration/patches/password_prompts
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


## `nginx` and `php`

```
# pkg install nginx
# pkg install php56
```

Configure `php`:

```
# cd /freebsd-configuration/patches/php
# ./configure_php
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
# pkg install php56-mysql phpMyAdmin
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
# pkg install postgresql93-client postgresql93-server
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
# rm -f .psql_history
```


## `phpPgAdmin`

```
# pkg install phpPgAdmin
# cd /freebsd-configuration/patches/phppgadmin
# ./configure_phppgadmin
```

Enable `phpPgAdmin` configuration for `nginx`.

```
# cd /usr/local/etc/nginx/sites-enabled/admin.foo.com.conf.d
# ln -s ../../../../../../freebsd-configuration/usr/local/etc/nginx/sites-enabled/admin.foo.com.conf.d/phppgadmin.conf
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


### Create `mail` SQL database and users

```
# su pgsql
$ createuser --no-createdb --no-createrole --no-superuser --encrypted --pwprompt mail
$ createuser --no-createdb --no-createrole --no-superuser --encrypted --pwprompt dovecot
$ createuser --no-createdb --no-createrole --no-superuser --encrypted --pwprompt postfix
$ createdb --owner=mail mail "Mail aliases and accounts information"
$ psql postgres
postgres=# GRANT ALL PRIVILEGES ON DATABASE mail TO mail;
postgres=# \q
$ psql --host=localhost --username=mail --dbname=mail < /freebsd-configuration/documentation/mail/mail-database-schema.sql
```


### `dovecot`

```
# cd /usr/ports/mail/dovecot2
# make config
```

Keep all options enabled by default, and additionally enable the following:

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

Then proceed to installing `dovecot2`:

```
# make all install clean
# pkg lock dovecot2
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
 * password in `connect` configuration in `/usr/local/etc/dovecot/dovecot-sql.conf.ext`.

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
# ln -s ../../../../freebsd-configuration/usr/local/etc/postfix/sql
# cd /usr/local/etc/postfix/sql
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

Manually edit the `password` entry in the following files:

 * `/usr/local/etc/postfix/sql/virtual_alias/domains.cf`;
 * `/usr/local/etc/postfix/sql/virtual_alias/maps.cf`;
 * `/usr/local/etc/postfix/sql/virtual_mailbox/domains.cf`.

Add listeners for `postfix` in `dovecot` configuration files:

```
# cd /usr/local/etc/dovecot
# patch --posix -p1 -i /freebsd-configuration/patches/dovecot/dovecot-listeners-for-postfix.diff
```

Update all map files:

```
# postalias /usr/local/etc/postfix/transport
# postalias /usr/local/etc/mail/aliases
# newaliases
```

Enable `postfix`:

```
# cd /etc/rc.conf.d
# ln -s ../../freebsd-configuration/etc/rc.conf.d/postfix
# service postfix start
```


### Additional notes

For the password field in the mailboxes table, you should use the following command:

```
# doveadm pw -s BLF-CRYPT
```
