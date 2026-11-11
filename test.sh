#!/bin/sh
# Vérification : construit les deux images, les démarre avec des valeurs de test
# et contrôle que la passerelle tourne et que l'émulateur sert la bonne adresse.
# Usage : ./test.sh [version de MiniPavi]   (par défaut : latest)
set -eu
V="${1:-latest}"

docker build -q --build-arg MINIPAVI_VERSION="$V" -t test-minipavi . -f Dockerfile-minipavi
docker build -q --build-arg MINIPAVI_VERSION="$V" -t test-emulminitel . -f Dockerfile-emulminitel

trap 'docker stop test-mp test-em >/dev/null 2>&1 || true' EXIT
docker run --rm -d --name test-mp -e MINIPAVI_HTTP_PASSWORD='p&ss<w$rd' \
    -e MINIPAVI_VIEWER_URL=https://emul.test/ test-minipavi >/dev/null
docker run --rm -d --name test-em -e GATEWAY_URL=wss://gw.test:443/ test-emulminitel >/dev/null
sleep 6

docker logs test-mp 2>&1 | grep 'MiniPavi version'
docker logs test-mp 2>&1 | grep -q 'Port TCP Websockets: 8181'
docker exec test-mp grep -q '<httppwd>p&amp;ss&lt;w$rd</httppwd>' minipavi.conf
[ -n "$(docker ps -q -f name=test-mp)" ] || { echo "la passerelle s'est arrêtée"; exit 1; }

for page in index.php indexminitel.php; do
    docker exec test-em wget -qO- "http://localhost:8080/$page" | grep -q 'data-socket="wss://gw.test:443/"'
done
docker exec test-em grep -q 'data-url="https://gw.test:443?action=webmedia"' import/minitel-minipavi-webmedia.html

# Une variable obligatoire manquante doit empêcher le démarrage
! docker run --rm test-emulminitel true 2>/dev/null
! docker run --rm test-minipavi 2>/dev/null

echo "OK"
