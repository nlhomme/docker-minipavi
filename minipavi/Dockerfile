##
# NAME             : nlhomme/nlhomme-minipavi
# TO_BUILD         : docker build --rm -t nlhomme/nlhomme-minipavi:latest . -f minipavi/Dockerfile
# TO_RUN           : docker run --rm -d -e MINIPAVI_HTTP_PASSWORD=... -e MINIPAVI_VIEWER_URL=... nlhomme/nlhomme-minipavi:latest
# Variables        : voir documentation/10-passerelle.md
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

# --- Étape 2 : la passerelle
FROM php:8.4-alpine

# Activation de PCNTL pour php
RUN docker-php-ext-install pcntl

# Copie des données du service Minipavi
# et création des dossiers nécessaires
WORKDIR /usr/src/minipavi
COPY --from=src /src/minipavi.php /src/VERSION ./
COPY --from=src /src/css css
COPY --from=src /src/lib lib
RUN mkdir logs recordings sockets stats

# Configuration : écrite au démarrage à partir des variables d'environnement
COPY minipavi/minipavi.conf.template minipavi/start-minipavi.php minipavi/healthcheck.php commun/render-conf.php ./

# Contrôle de santé : la passerelle doit répondre sur son port VisuWeb/WebMedia (voir healthcheck.php)
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 CMD ["php", "/usr/src/minipavi/healthcheck.php"]

CMD [ "php", "./start-minipavi.php" ]
