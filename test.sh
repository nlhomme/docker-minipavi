#!/bin/sh
# Vérification : construit les images, les démarre avec des valeurs de test et contrôle
# que chacune fait son travail. Affiche OK à la fin.
# Usage : ./test.sh [version de MiniPavi] [asterisk]
#   ./test.sh                  les quatre images légères, dernière release de MiniPavi
#   ./test.sh 1.6.1            idem, avec une version précise
#   ./test.sh latest asterisk  en plus, l'image Asterisk (longue à construire)
set -eu
V="${1:-latest}"
WITH_ASTERISK="${2:-}"

# docker-compose.yml et la documentation doivent suivre les Dockerfiles (voir CLAUDE.md) :
# chaque Dockerfile a son service, chaque variable des images y figure et est documentée dans Documentation/
echo "docker-compose.yml et docs"
missing() { echo "$1 : $2 absent" >&2; exit 1; }
for dockerfile in */Dockerfile; do
    grep -q "dockerfile: $dockerfile\$" docker-compose.yml || missing docker-compose.yml "$dockerfile"
done
variables=$({
    grep -oh '\${[A-Z_]*' minipavi/minipavi.conf.template accueil-extcall/*/*.template | tr -d '${'
    sed -n "s/^VARS='\(.*\)'/\1/p" asterisk/start-asterisk.sh | tr ' ' '\n'
    sed -n 's/^ARG \([A-Z_]*\).*/\1/p' */Dockerfile
    echo GATEWAY_URL
    echo WEBMEDIA_URL
} | sort -u)
for variable in $variables; do
    grep -q "^ *$variable:" docker-compose.yml || missing docker-compose.yml "$variable"
    grep -rq "\`$variable\`" Documentation/ || missing Documentation/ "$variable"
done
MINIPAVI_HTTP_PASSWORD=x docker compose --profile webmedia --profile accueil-extcall --profile asterisk config --quiet

for part in minipavi emulminitel webmedia accueil-extcall; do
    docker build -q --build-arg MINIPAVI_VERSION="$V" -t "test-$part" . -f "$part/Dockerfile"
done

# Réussit seulement si la commande échoue ("! commande" ne suffit pas : set -e l'ignore)
fails() {
    if "$@" >/dev/null 2>&1; then echo "aurait dû échouer : $*" >&2; exit 1; fi
}

cleanup() {
    docker stop test-mp test-em test-wm test-sv test-ast >/dev/null 2>&1 || true
    docker network rm test-minipavi-net >/dev/null 2>&1 || true
}
trap cleanup EXIT
cleanup
docker network create test-minipavi-net >/dev/null

# ponytail: clés et mots de passe de test en clair, ils ne servent qu'ici
docker run --rm -d --name test-mp --network test-minipavi-net \
    -e MINIPAVI_HTTP_PASSWORD='p&ss<w$rd' -e MINIPAVI_VIEWER_URL=https://emul.test/ \
    -e MINIPAVI_AST_PORT=8183 -e MINIPAVI_AMI_PASSWORD=amitest -e MINIPAVI_AMI_HOST=test-ast \
    -e MINIPAVI_SIP_CHANNEL='PJSIP/trunk/sip:%NUM%@sip.test' test-minipavi >/dev/null
docker run --rm -d --name test-em -e GATEWAY_URL=wss://gw.test:443/ test-emulminitel >/dev/null
docker run --rm -d --name test-wm -e WEBMEDIA_URL='https://vw.test?action=webmedia' test-webmedia >/dev/null
docker run --rm -d --name test-sv -e MINIPAVI_CONNECT_KEY=Secret9 test-accueil-extcall >/dev/null
sleep 6

echo "passerelle"
docker logs test-mp 2>&1 | grep 'MiniPavi version'
docker logs test-mp 2>&1 | grep -q 'Port TCP Websockets: 8181'
docker logs test-mp 2>&1 | grep -q 'Port TCP Asterisk: 8183'
docker logs test-mp 2>&1 | grep -q 'IP AMI: test-ast'
docker exec test-mp grep -q '<httppwd>p&amp;ss&lt;w$rd</httppwd>' minipavi.conf
[ -n "$(docker ps -q -f name=test-mp)" ] || { echo "la passerelle s'est arrêtée"; exit 1; }
# Sans MINIPAVI_AMI_PASSWORD, la section <asterisk> doit disparaître de la configuration
docker run --rm -e MINIPAVI_HTTP_PASSWORD=x -e MINIPAVI_VIEWER_URL=https://emul.test/ test-minipavi \
    php -r 'require "render-conf.php"; exit(str_contains(render_conf("minipavi.conf.template"), "<asterisk>") ? 1 : 0);'

echo "émulateur"
for page in index.php indexminitel.php; do
    docker exec test-em wget -qO- "http://localhost:8080/$page" | grep -q 'data-socket="wss://gw.test:443/"'
done
docker exec test-em grep -q 'data-url="https://gw.test:443?action=webmedia"' import/minitel-minipavi-webmedia.html

echo "webmedia"
docker exec test-wm wget -qO- http://localhost:8080/ | grep -q 'WebMedia'
docker exec test-wm grep -q "const url = 'https://vw.test?action=webmedia'" webmedia.js

echo "accueil-extcall"
REQUEST='{"PAVI":{"version":"1.2","uniqueId":"1700000000001","remoteAddr":"127.0.0.1","typesocket":"websocket","versionminitel":"Cv;","content":[],"context":"","fctn":"CNX"},"URLPARAMS":{"cid":"hacker"}}'
for service in MiniPaviAcc/ 'EXTcall/?cid=hacker'; do
    docker exec test-sv wget -qO- -U MiniPAVI --header 'Content-Type: application/json' \
        --post-data "$REQUEST" "http://localhost:8080/$service" | grep -q '"content":"'
done
docker exec test-sv grep -q 'extcall key="Secret9"' EXTcall/extcall.conf
# Les fichiers de configuration ne doivent pas être lisibles depuis le web
for file in EXTcall/extcall.conf EXTcall/extcall.conf.template MiniPaviAcc/paviacc.conf; do
    fails docker exec test-sv wget -qO /dev/null "http://localhost:8080/$file"
done

echo "variables obligatoires"
fails docker run --rm test-emulminitel true
fails docker run --rm test-webmedia true
fails docker run --rm test-minipavi

if [ "$WITH_ASTERISK" = asterisk ]; then
    echo "asterisk"
    docker build -q --build-arg MINIPAVI_VERSION="$V" -t test-asterisk . -f asterisk/Dockerfile
    fails docker run --rm test-asterisk
    docker run --rm -d --name test-ast --network test-minipavi-net \
        -e SIP_SERVER=sip.test -e SIP_USERNAME=0033100000000 -e SIP_PASSWORD='s;p' \
        -e ASTERISK_EXTERNAL_ADDRESS=203.0.113.1 -e MINIPAVI_HOST=test-mp -e AMI_PASSWORD=amitest test-asterisk >/dev/null
    sleep 15
    docker exec test-ast asterisk -rx 'module show like minipavi' | grep -q 'app_softmodemminipavi.so.*Running'
    docker exec test-ast asterisk -rx 'dialplan show minipavi' | grep -q 'SoftmodemMinipavi("test-mp", 8183'
    docker exec test-ast asterisk -rx 'pjsip show endpoints' | grep -q 'trunk'
    docker exec test-ast grep -q 'password=s\\;p' /etc/asterisk/pjsip.conf
    # Un appel simulé doit faire se connecter le softmodem à la passerelle
    docker exec test-ast asterisk -rx 'channel originate Local/s@minipavi application Wait 8' >/dev/null
    sleep 6
    docker logs test-ast 2>&1 | grep -q "CONNECTED to remote host: 'test-mp port 8183'"
    # La passerelle doit pouvoir s'identifier sur l'AMI d'Asterisk
    docker exec test-mp php -r '$s = fsockopen("test-ast", 5038); fgets($s); fwrite($s, "Action: Login\r\nUsername: minipavi\r\nSecret: amitest\r\n\r\n"); exit(str_contains(fgets($s), "Success") ? 0 : 1);'
fi

echo "OK"
