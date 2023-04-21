#!/usr/bin/with-contenv bash
# shellcheck shell=bash
set -e

. $(dirname $0)/00-env

if [ "$RSPAMD_ENABLE" != "true" ]; then
  echo "INFO: Rspamd service disabled."
  exit 0
fi
if [ ! -f "$DKIM_PRIVATE_KEY" ]; then
  echo "WRN: $DKIM_PRIVATE_KEY not found. Rspamd service disabled."
  exit 0
fi

# Init
mkdir -p -m o-rwx /var/run/rspamd
chown rspamd. /var/run/rspamd

# Fix perms
chown -R rspamd. /etc/rspamd /var/lib/rspamd

# Create service
mkdir -p /etc/services.d/rspamd
cat >/etc/services.d/rspamd/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
/usr/sbin/rspamd -i -f -u rspamd -g rspamd
EOL
chmod +x /etc/services.d/rspamd/run

# Empty the local_addrs array to avoid having Rspamd skip DMARC and SPF checks if the mailserver is running in a container as well (therefore being in a local network).
# Required since AnonAddy checks the headers injected by Rspamd. See https://github.com/anonaddy/docker/issues/192#issuecomment-1518111988
sed -i 's/local_addrs.*$/local_addrs=[]/' /etc/rspamd/options.inc
