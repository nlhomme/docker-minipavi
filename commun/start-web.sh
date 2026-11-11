#!/bin/sh
# Démarrage des images web (émulateur, WebMedia, accueil-extcall) :
# - écrit les adresses de la passerelle dans les fichiers de MiniPavi,
#   à la place des adresses d'exemple "mapasserelleminipavi.com" ;
# - écrit les fichiers de configuration à partir des modèles *.template ;
# puis lance le serveur web.
set -eu

echo "MiniPavi version $(cat /MINIPAVI_VERSION)"

cd /var/www/html

WS_EXAMPLE='wss://mapasserelleminipavi.com:YYYY/'
WM_EXAMPLE='https://mapasserelleminipavi.com:XXXX?action=webmedia'

# Fichiers contenant un texte donné
files_with() {
    find . \( -name '*.php' -o -name '*.html' -o -name '*.js' \) -exec grep -lF "$1" {} + || true
}

# Remplace un texte par un autre dans les fichiers qui le contiennent
replace() {
    FROM="$1" TO="$2" php -r '
        foreach (array_slice($argv, 1) as $f) {
            file_put_contents($f, str_replace(getenv("FROM"), getenv("TO"), file_get_contents($f)));
        }' $(files_with "$1")
}

# Adresse websocket de la passerelle
if [ -n "$(files_with "$WS_EXAMPLE")" ]; then
    : "${GATEWAY_URL:?Variable GATEWAY_URL manquante, ex. wss://passerelle.exemple.org:443/ (voir documentation/)}"
    # L'adresse est écrite dans du PHP : on refuse tout caractère inattendu
    echo "$GATEWAY_URL" | grep -Eq '^wss?://[A-Za-z0-9.:/_-]+$' \
        || { echo "GATEWAY_URL invalide : $GATEWAY_URL" >&2; exit 1; }
    replace "$WS_EXAMPLE" "$GATEWAY_URL"
fi

# Adresse WebMedia de la passerelle : par défaut, celle de la passerelle en http(s)
if [ -n "$(files_with "$WM_EXAMPLE")" ]; then
    if [ -z "${WEBMEDIA_URL:-}" ]; then
        : "${GATEWAY_URL:?Variable WEBMEDIA_URL manquante, ex. https://visuweb.exemple.org?action=webmedia (voir documentation/)}"
        WEBMEDIA_URL="$(echo "${GATEWAY_URL%/}" | sed 's/^ws/http/')?action=webmedia"
    fi
    echo "$WEBMEDIA_URL" | grep -Eq '^https?://[A-Za-z0-9.:/_?=&-]+$' \
        || { echo "WEBMEDIA_URL invalide : $WEBMEDIA_URL" >&2; exit 1; }
    replace "$WM_EXAMPLE" "$WEBMEDIA_URL"
fi

# Une adresse d'exemple restante = une nouvelle version de MiniPavi a changé ses fichiers
left=$(files_with mapasserelleminipavi)
if [ -n "$left" ]; then
    echo "Adresse d'exemple encore présente dans : $left" >&2
    echo "commun/start-web.sh est à adapter à cette version de MiniPavi" >&2
    exit 1
fi

# Fichiers de configuration : xxx.conf.template devient xxx.conf
for template in $(find . -name '*.template'); do
    php /render-conf.php "$template" "${template%.template}"
done

exec "$@"
