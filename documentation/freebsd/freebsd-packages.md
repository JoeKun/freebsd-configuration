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
