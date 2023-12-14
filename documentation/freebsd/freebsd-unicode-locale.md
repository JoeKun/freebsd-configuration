# Using a Unicode locale on FreeBSD

Your experience with FreeBSD console applications will be better if you tweak a few login configuration options.

As seen in [b1c1l1’s related blog post](https://www.b1c1l1.com/blog/2011/05/09/using-utf-8-unicode-on-freebsd/), you may want to set a couple of things in `/etc/login.conf`.
 * `lang` should be set to your preferred UTF-8 locale, such as `en_US.UTF-8`;
 * `LC_COLLATE` should be set to `C`.

Assuming you [fetched these FreeBSD configuration files](freebsd-command-line-tools.md#fetch-configuration-files) in `/freebsd-configuration`, you may apply those changes with just a few commands.

```console
# cd /etc
# patch --posix -p1 -i /freebsd-configuration/patches/unicode-locale/login-use-unicode-locale.diff
# cap_mkdb /etc/login.conf
```

To apply those changes, simply log out and log back in.
