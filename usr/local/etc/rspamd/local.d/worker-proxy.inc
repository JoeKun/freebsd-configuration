# /usr/local/etc/rspamd/local.d/worker-proxy.inc: Proxy worker configuration for rspamd.

# Use this worker as a postfix milter.
milter = yes;
bind_socket = "/var/run/rspamd/milter.sock mode=0660";

# Self-scan mode; appropriate when rspamd is on the same machine as postfix.
timeout = 120s;
upstream "local" {
  default = yes;
  self_scan = yes;
}

