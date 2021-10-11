#!/usr/bin/env bash

set -eu

/radarr/Radarr -nobrowser -data=/config &

export DEBIAN_FRONTEND=noninteractive
apt-get -q update
apt-get install -qqy curl

MAX=10
i=0

until [ $i -ge $MAX ]
do
  HTTP_CODE=$(curl -sL -w "%{http_code}\\n" "http://127.0.0.1:7878/" -o /dev/null)
  [ $? -eq 0 ] && break
  i=$((i+1))
  sleep 5
done

[ "$HTTP_CODE" != "200" ] && >&2 echo "Radarr HTTP Code: $HTTP_CODE" && exit 1

exit 0