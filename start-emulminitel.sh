#!/bin/sh
# Démarrage de l'émulateur : écrit l'adresse de la passerelle dans les fichiers de MiniPavi
# (à la place de l'adresse d'exemple "mapasserelleminipavi.com"), puis lance le serveur web.
set -eu

echo "MiniPavi version $(cat /MINIPAVI_VERSION)"

: "${GATEWAY_URL:?Variable GATEWAY_URL manquante, ex. wss://passerelle.exemple.org:443/ (voir README.md)}"

# Adresse WebMedia : par défaut, celle de la passerelle en http(s)
if [ -z "${WEBMEDIA_URL:-}" ]; then
    WEBMEDIA_URL="$(echo "${GATEWAY_URL%/}" | sed 's/^ws/http/')?action=webmedia"
fi

# Les adresses sont écrites dans du PHP et du HTML : on refuse tout caractère inattendu
echo "$GATEWAY_URL" | grep -Eq '^wss?://[A-Za-z0-9.:/_-]+$' \
    || { echo "GATEWAY_URL invalide : $GATEWAY_URL" >&2; exit 1; }
echo "$WEBMEDIA_URL" | grep -Eq '^https?://[A-Za-z0-9.:/_?=&-]+$' \
    || { echo "WEBMEDIA_URL invalide : $WEBMEDIA_URL" >&2; exit 1; }

cd /var/www/html
export GATEWAY_URL WEBMEDIA_URL
php -r '
foreach (["index.php", "indexminitel.php", "import/minitel-minipavi-webmedia.html"] as $f) {
    if (!is_file($f)) continue;
    file_put_contents($f, str_replace(
        ["wss://mapasserelleminipavi.com:YYYY/", "https://mapasserelleminipavi.com:XXXX?action=webmedia"],
        [getenv("GATEWAY_URL"), getenv("WEBMEDIA_URL")],
        file_get_contents($f)));
}'

# Une adresse d'exemple restante = une nouvelle version de MiniPavi a changé ses fichiers
left=$(find . \( -name '*.php' -o -name '*.html' -o -name '*.js' \) -exec grep -l mapasserelleminipavi {} +) || true
if [ -n "$left" ]; then
    echo "Adresse d'exemple encore présente dans : $left" >&2
    echo "start-emulminitel.sh est à adapter à cette version de MiniPavi" >&2
    exit 1
fi

exec "$@"
