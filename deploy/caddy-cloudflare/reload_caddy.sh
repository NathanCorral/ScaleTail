#/bin/bash
docker exec -it "$1" caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile
