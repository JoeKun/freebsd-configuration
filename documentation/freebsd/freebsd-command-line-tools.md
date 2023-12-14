# Useful command-line tools for FreeBSD

Your experience managing a FreeBSD server can be elevated using some essential command-line tools.

## Build required packages using `poudriere`

If you’re using `poudriere` following [this guide](freebsd-poudriere.md), then add a few entries to the list of packages built by `poudriere`.

```console
# cat << EOF >> /usr/local/etc/poudriere.d/pkglist

# Command-line utilities
devel/git
devel/gmake
editors/vim
ftp/wget
misc/figlet
misc/fortune-mod-freebsd-classic
misc/mmv
shells/bash
shells/zsh
sysutils/htop
sysutils/most
sysutils/pstree
sysutils/pwgen
sysutils/screen
sysutils/vimpager
textproc/colordiff
textproc/diff-so-fancy
textproc/par
EOF
```

And build your packages again.

```console
# poudriere bulk \
    -j my_poudriere-amd64-14-0 \
    -p 2023Q4 \
    -f /usr/local/etc/poudriere.d/pkglist
```


## Install packages for basic command-line tools

```console
# pkg install git
# pkg install zsh
# pkg install figlet
# pkg install fortune-mod-freebsd-classic
# pkg install vim
# pkg install vimpager
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
# pkg install pstree
```


## Fetch configuration files

This [`freebsd-configuration`](https://github.com/JoeKun/freebsd-configuration) repository contains a number of ready-to-use configuration files for FreeBSD. Some of those configuration files can be used as-is, whereas others may only require lightweight personal customizations.

Clone the `freebsd-configuration` repository to `/`.

```console
# cd /
# git clone https://github.com/JoeKun/freebsd-configuration.git
```

Going forward, we will leverage those configuration files directly.

Furthermore, in most cases, the approach followed to apply those configuration files will be to establish a symbolic link from the relevant file-system location to the corresponding configuration file from this repository. Indeed, this approach has the benefit of allowing some updates to apply simply by performing a simple `git pull`.


## Configure `git`

Link to `git` configuration files.

```console
# cd
# ln -s ../freebsd-configuration/home/my_username/.gitconfig
# mkdir -p .config
# cd .config
# ln -s ../../freebsd-configuration/home/my_username/.config/git
```

You should then edit the name and email fields in the user section of this `.gitconfig` file using the `git config` command.

```console
# git config --global user.name "John Smith"
# git config --global user.email "john@smith.com"
```


## Configure `zsh`

Link to global `zsh` configuration files.

```console
# cd /usr/local/etc
# for file_name in zlogin zlogout zprofile zshenv zshrc; \
  do \
      ln -s ../../../freebsd-configuration/usr/local/etc/${file_name}; \
  done
```

Link to user `zsh` configuration files for the `root` user.

```console
# cd
# for file_name in .zshenv .zshrc; \
  do \
    ln -s ../freebsd-configuration/root/${file_name}; \
  done
```

Change the default shell for the `root` user.

```console
# chsh -s /usr/local/bin/zsh
```

You may now `exit` from your current `ssh` session, and start a new one, where you should be welcomed with a nicer shell with more inviting colors!


## Configure `vim`

Create symbolic links to relevant configuration files for `vim`.

```console
# mkdir -p /usr/local/etc/vim
# cd /usr/local/etc/vim
# for file_name in vimrc colors plugin indent syntax filetype.vim; \
  do \
    ln -s ../../../../freebsd-configuration/usr/local/etc/vim/${file_name}; \
  done
```


## Configure `vimpager`

Replace default configuration file for `vimpager` with a symbolic links to relevant the one found in the repository.

```console
# cd /usr/local/etc
# rm -f vimpagerrc
# ln -s ../../../freebsd-configuration/usr/local/etc/vimpagerrc
```


## Apply minor adjustment to password prompts

FreeBSD’s default password prompts for `ssh` and `su` lack a space after the `Password:` prompt, which looks a bit inelegant.

You may adjust these password prompts by applying the `authtok_prompt` option in the `auth` rule for `pam_unix.so` in the Pluggable Authentication Module configuration files for `ssh` and `su`.

```console
# cd /freebsd-configuration/patches/password-prompts
# ./adjust_password_prompts
```


## Additional command-line tools for unprivileged users

Here are a few more command-line tools you might be interested in using with your [unpriviledged user on FreeBSD](freebsd-unprivileged-user.md).

### Terminal Markdown Viewer

Install the Terminal Markdown Viewer package. [^1]

[^1]: If you’re using `poudriere`, make sure to build the package `devel/py-mdv` following the pattern described [above](#build-required-packages-using-poudriere).

```console
# pkg install py39-mdv
```

### Mail client `mutt`

Install the `mutt` package. [^2]

[^2]: If you’re using `poudriere`, make sure to build the package `mail/mutt` following the pattern described [above](#build-required-packages-using-poudriere).

```console
# pkg install mutt
```

Feel free to check the sample configuration files for `mutt` in the [`home/my_username/.mutt`](https://github.com/JoeKun/freebsd-configuration/tree/main/home/my_username/.mutt) directory of this repository.

### IRC client `irssi`

Install the `irssi` and `irssi-scripts` packages. [^3]

[^3]: If you’re using `poudriere`, make sure to build the packages `irc/irssi` and `irc/irssi-scripts` following the pattern described [above](#build-required-packages-using-poudriere).

```console
# pkg install irssi irssi-scripts
```

To launch `irssi` in a `screen` upon rebooting, add the following entry to the user’s `crontab` using `crontab -e`.

```
@reboot screen -d -m -S irc env TERM=xterm-256color irssi
```