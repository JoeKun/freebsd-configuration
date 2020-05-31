# /usr/local/etc/rspamd/local.d/worker-normal.inc: Normal scanner worker configuration for rspamd.

# We're not running rspamd in a distributed setup, so this can be disabled.
# The proxy worker will handle all the spam filtering.
enabled = false;

