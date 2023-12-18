# Remote access with SSH on FreeBSD

FreeBSD includes OpenSSH as part of the base operating system. Here are instructions on how to set it up.

## Enable `sshd` service

In case you haven’t selected `sshd` as one of the enabled services in the FreeBSD installer, you can enable by setting `sshd_enable="YES"` in your system configuration.[^1]

[^1]: System configuration options are placed in discrete system configuration files according to the principles outlined in [Modular system configuration on FreeBSD](freebsd-modular-system-configuration.md).

```console
# cat << EOF > /etc/rc.conf.d/sshd
# /etc/rc.conf.d/sshd: system configuration for sshd

sshd_enable="YES"
EOF
```

Then start the `sshd` service.

```console
# service sshd start
```

## Allow `root` login with SSH key

This section goes over how to login as `root` via SSH using an SSH key.

### Generate SSH key on your client machine

On your client machine, such as your primary laptop, if you don’t already have an SSH key, you may generate one.

```console
% ssh-keygen -t rsa -b 4096 -C my_username@my_domain.com
```

I suggest you simply replace `my_username@my_domain.com` with your regular email address.

### Register public SSH key as authorized for `root` on the FreeBSD server

First copy your public SSH key from your client machine. For example, if your client machine is a Mac, you can do so using the `pbcopy` in the Terminal.

```console
% cat ~/.ssh/id_rsa.pub | tr -d '\n' | pbcopy
```

Going forward, we’ll refer to this public key you just copied as:

```
ssh-rsa […] my_username@my_domain.com
```

Obviously, the real public key is considerably longer, as it will contain a lot of characters in place of `[…]`.

On the FreeBSD server, add this public key to the `~/.ssh/authorized_keys` file.

```console
# mkdir -p ~/.ssh
# chmod 700 ~/.ssh
# touch ~/.ssh/authorized_keys
# echo "ssh-rsa […] my_username@my_domain.com" >> ~/.ssh/authorized_keys
```

### Update `sshd` configuration to allow `root` login with an SSH key

Allowing `root` login with an SSH key can be achieved by setting the configuration option `PermitRootLogin prohibit-password` in `/etc/ssh/sshd_config`.[^2]

```console
# cd /etc/ssh
# sed -i '' 's/^#PermitRootLogin no$/PermitRootLogin prohibit-password/' sshd_config
```

[^2]: An equivalent patch for `sshd_config` can also be found in this `freebsd-configuration` repository at the following location: `patches/sshd/sshd-allow-root-login-using-ssh-key.diff`.

Then reload the `sshd` service.

```console
# service sshd reload
```


## Disable `UseDNS` configuration option

As seen in the following [FreeBSD commit](https://svnweb.freebsd.org/base?view=revision&revision=294909), FreeBSD developers have made a conscious decision to deviate from the new default value of `UseDNS` since OpenSSH 6.8p1.

Unfortunately, leaving `UseDNS` enabled can result in significant delays when logging in, especially from a client machine in a network where the public IP address doesn’t have a proper reverse DNS entry. Furthermore, `UseDNS` seems [pretty pointless for most people](http://unix.stackexchange.com/questions/56941/what-is-the-point-of-sshd-usedns-option#answer-56947).

For those reasons, disabling `UseDNS` can be a good idea.[^3]

[^3]: An equivalent patch for `sshd_config` can also be found in this `freebsd-configuration` repository at the following location: `patches/sshd/sshd-disable-usedns-configuration-option.diff`.

```console
# cd /etc/ssh
# sed -i '' 's/^#UseDNS yes$/UseDNS no/' sshd_config
```

Then reload the `sshd` service.

```console
# service sshd reload
```