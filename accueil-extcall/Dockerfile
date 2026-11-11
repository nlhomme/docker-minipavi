##
# NAME             : nlhomme/nlhomme-accueil-extcall
# TO_BUILD         : docker build --rm -t nlhomme/nlhomme-accueil-extcall:latest . -f accueil-extcall/Dockerfile
# TO_RUN           : docker run --rm -d nlhomme/nlhomme-accueil-extcall:latest
# Variables        : voir Documentation/13-accueil-extcall.md
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

# --- Étape 2 : les services EXTcall et MiniPaviAcc
# https://hub.docker.com/r/trafex/php-nginx
FROM trafex/php-nginx:latest

# Ajout au site de la dernière version du robots.txt anti-AI
# https://github.com/ai-robots-txt/ai.robots.txt
RUN wget https://raw.githubusercontent.com/ai-robots-txt/ai.robots.txt/refs/heads/main/robots.txt -O /var/www/html/robots.txt

# Les fichiers de configuration sont à côté des scripts : le serveur web ne doit pas les donner à lire
COPY accueil-extcall/nginx-deny-conf.conf /etc/nginx/deny-conf.conf
USER root
# Extension SimpleXML de PHP : lecture des fichiers de configuration des services
RUN apk add --no-cache "php$(php -r 'echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;')-simplexml"
RUN sed -i 's|^\( *\)root /var/www/html;|&\n\1include /etc/nginx/deny-conf.conf;|' /etc/nginx/conf.d/default.conf \
    && grep -q deny-conf /etc/nginx/conf.d/default.conf
USER nobody

# Copie des services, puis de nos modèles de configuration (dossier accueil-extcall/),
# qui remplacent les fichiers d'exemple de MiniPavi au démarrage
COPY --from=src --chown=nobody /src/services/. /var/www/html/
COPY --chown=nobody accueil-extcall/EXTcall/. /var/www/html/EXTcall/
COPY --chown=nobody accueil-extcall/MiniPaviAcc/. /var/www/html/MiniPaviAcc/
COPY --from=src /src/VERSION /MINIPAVI_VERSION
COPY commun/start-web.sh commun/render-conf.php /

ENTRYPOINT ["/start-web.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
