#!/usr/bin/with-contenv bash

SIDECAR_CRON=${SIDECAR_CRON:-0}
SIDECAR_POSTFIX=${SIDECAR_POSTFIX:-0}

if [ "$SIDECAR_CRON" = "1" ] || [ "$SIDECAR_POSTFIX" = "1" ]; then
  exit 0
fi

echo "DB migration"
anonaddy migrate --no-interaction --force

echo "Clear cache"
anonaddy cache:clear --no-interaction
anonaddy config:cache --no-interaction

# Install passport
if [ ! -f "/data/storage/oauth-private.key" ] && [ ! -f "/data/storage/oauth-public.key" ]; then
  echo "Install passport"
  anonaddy passport:install --no-interaction
fi

mkdir -p /etc/services.d/nginx
cat > /etc/services.d/nginx/run <<EOL
#!/usr/bin/execlineb -P
s6-setuidgid ${PUID}:${PGID}
nginx -g "daemon off;"
EOL
chmod +x /etc/services.d/nginx/run

mkdir -p /etc/services.d/php-fpm
cat > /etc/services.d/php-fpm/run <<EOL
#!/usr/bin/execlineb -P
s6-setuidgid ${PUID}:${PGID}
php-fpm7 -F
EOL
chmod +x /etc/services.d/php-fpm/run
