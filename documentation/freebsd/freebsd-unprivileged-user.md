# Creating an unprivileged user on FreeBSD

## Skeleton for home directory of unprivileged users

Prepare a skeleton for all regular unprivileged users.

Assuming you [fetched these FreeBSD configuration files](freebsd-command-line-tools.md#fetch-configuration-files) in `/freebsd-configuration`, you may apply create this skeleton with just a few commands.

```console
# cd /usr/local/etc
# ln -s ../../../freebsd-configuration/usr/local/etc/skel
```


## Apply default configuration for `adduser`

Create new unprivileged group for regular users.

```console
# pw group add users -g 1000
```

Apply configuration for `adduser`.

```console
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
OK? (yes/no) [yes]: yes
Re-edit the default configuration? (yes/no) [no]: no
Goodbye!
```


## Add unprivileged user

Let’s assume we want to create an unprivileged user named `john`.

```console
# adduser
Username: john
Full name: John Smith
Uid [1000]: 
Login group [users]: 
Login group is users. Invite john into other groups? []: 
Login class [default]: 
Shell (sh csh tcsh git-shell zsh rzsh bash rbash nologin) [zsh]: 
Home directory [/home/john]: 
Home directory permissions (Leave empty for default): 
Use password-based authentication? [yes]: 
Use an empty password? (yes/no) [no]: 
Use a random password? (yes/no) [no]: 
Enter password: 
Enter password again: 
Lock out the account after creation? [no]: 
Username   : john
Password   : *****
Full Name  : John Smith
Uid        : 1000
Class      : 
Groups     : users 
Home       : /home/john
Home Mode  : 
Shell      : /usr/local/bin/zsh
Locked     : no
OK? (yes/no) [yes]: yes
adduser: INFO: Successfully added (john) to the user database.
Add another user? (yes/no) [no]: no
Goodbye!
```

If you would like your unprivileged user to be able to use `su` to login as `root`, then you must add this user to the `wheel` group.

```console
# pw group mod wheel -m john
```


## Configure basic command-line tools

### Remote access with SSH

This may be a good time to setup SSH keys however you see fit.

For inspiration on how you might do that, you may want to reapply for your new unprivileged user the principles outlined [here](freebsd-remote-access-ssh.md#register-public-ssh-key-as-authorized-for-root-on-the-freebsd-server).

### Configure `git`

For a comprehensive configuration file for `git`, you may want to have another copy of the [`freebsd-configuration`](https://github.com/JoeKun/freebsd-configuration) repository, dedicated for your new unprivileged user, and with the right ownership.

```console
% mkdir ~/code
% cd ~/code
% git clone https://github.com/JoeKun/freebsd-configuration.git
```

Link to `git` configuration files for your new unprivileged user.

```console
% cd
% ln -s code/freebsd-configuration/home/my_username/.gitconfig
% mkdir -p .config
% cd .config
% ln -s ../code/freebsd-configuration/home/my_username/.config/git
```

You should then edit the name and email fields in the user section of this `.gitconfig` file using the `git config` command.

```console
% git config --global user.name "John Smith"
% git config --global user.email "john@smith.com"
```

### Configure `zsh`

Link to user `zsh` configuration files for your new unprivileged user.

```console
% cd
% rm -f .zshenv .zshrc
% for file_name in .zshenv .zshrc; \
  do \
    ln -s code/freebsd-configuration/home/my_username/${file_name}; \
  done
```

You should also customize the `LOGIN_GREETING_NAME` in `~/.zshenv`.
