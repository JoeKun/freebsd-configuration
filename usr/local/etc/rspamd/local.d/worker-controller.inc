# /usr/local/etc/rspamd/local.d/worker-controller.inc: Controller worker configuration for rspamd.

# Administrator password for rspamd.
password = "PasswordHashWithRspamadmPw";

# Socket for dovecot to communicate with rspamd.
bind_socket = "/var/run/rspamd/rspamd.sock mode=0660 owner=rspamd group=rspamd";

# Socket for web interface.
bind_socket = "localhost:11334";

