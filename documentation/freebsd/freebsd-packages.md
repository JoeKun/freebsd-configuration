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

# mkdir sites-enabled
# cd sites-enabled
# ln -s ../../../../../freebsd-configuration/usr/local/etc/nginx/sites-enabled/admin.foo.com.conf
# mkdir admin.foo.com.conf.d

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
