##
# NAME             : nlhomme/nlhomme-webmedia
# TO_BUILD         : docker build --rm -t nlhomme/nlhomme-webmedia:latest . -f webmedia/Dockerfile
# TO_RUN           : docker run --rm -d -e WEBMEDIA_URL='https://visuweb.exemple.org?action=webmedia' nlhomme/nlhomme-webmedia:latest
# Variables        : voir Documentation/12-webmedia.md
##

# --- Étape 1 : téléchargement de MiniPavi (https://github.com/ludosevilla/minipavi)
FROM alpine:3 AS src

# Version (tag) de MiniPavi à installer ; "latest" ou vide = dernière release publiée
ARG MINIPAVI_VERSION=latest

# Docker revérifie cette réponse à chaque build : le cache n'est invalidé que si une nouvelle release est sortie
ADD https://api.github.com/repos/ludosevilla/minipavi/releases/latest /latest.json

RUN set -eo pipefail; \
    V="$MINIPAVI_VERSION"; \
    if [ -z "$V" ] || [ "$V" = latest ]; then V=$(sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' /latest.json); fi; \
    [ -n "$V" ] || { echo "Version de MiniPavi introuvable" >&2; exit 1; }; \
    wget -qO- "https://github.com/ludosevilla/minipavi/archive/$V.tar.gz" | tar xz; \
    mv minipavi-* /src; \
    echo "$V" > /src/VERSION

# --- Étape 2 : la page WebMedia
# https://hub.docker.com/r/trafex/php-nginx
FROM trafex/php-nginx:latest

# Ajout au site de la dernière version du robots.txt anti-AI
# https://github.com/ai-robots-txt/ai.robots.txt
RUN wget https://raw.githubusercontent.com/ai-robots-txt/ai.robots.txt/refs/heads/main/robots.txt -O /var/www/html/robots.txt

# Copie de la page WebMedia (modifiable par "nobody" : l'adresse de la passerelle y est écrite au démarrage)
COPY --from=src --chown=nobody /src/webmedia/. /var/www/html/
COPY --from=src /src/VERSION /MINIPAVI_VERSION
COPY commun/start-web.sh commun/render-conf.php /

ENTRYPOINT ["/start-web.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
