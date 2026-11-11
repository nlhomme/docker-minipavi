##
# NAME             : nlhomme/nlhomme-asterisk-minipavi
# TO_BUILD         : docker build --rm -t nlhomme/nlhomme-asterisk-minipavi:latest . -f asterisk/Dockerfile
# TO_RUN           : voir Documentation/14-asterisk.md (ports UDP à publier, variables obligatoires)
# Variables        : voir Documentation/14-asterisk.md
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

# --- Étape 2 : compilation de spandsp et d'Asterisk avec le module softmodem de MiniPavi
# (étapes de la documentation de MiniPavi, chapitre 9)
FROM debian:bookworm-slim AS build

# Branche d'Asterisk à compiler (MiniPavi est testé avec les versions 20 et 22)
ARG ASTERISK_VERSION=22

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential autoconf automake libtool pkg-config \
        wget ca-certificates unzip bzip2 patch xmlstarlet \
        libtiff-dev libjpeg-dev libedit-dev uuid-dev libjansson-dev libxml2-dev \
        libsqlite3-dev libssl-dev libsrtp2-dev \
    && rm -rf /var/lib/apt/lists/*

COPY --from=src /src/asterisk /minipavi

# Librairie spandsp 3 (la copie fournie avec MiniPavi)
RUN cd /tmp && unzip -q /minipavi/spandsp-3.0.0/master.zip && cd spandsp-master \
    && ./bootstrap.sh && ./configure --prefix=/usr \
    && make -j"$(nproc)" && make install && make install DESTDIR=/out

# Asterisk, avec le module app_softmodemminipavi
RUN cd /tmp && wget -qO- "https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-${ASTERISK_VERSION}-current.tar.gz" | tar xz \
    && cd asterisk-* \
    && cp /minipavi/app_softmodemminipavi.c apps/ \
    && ./configure --with-pjproject-bundled \
    && make menuselect.makeopts \
    && menuselect/menuselect --enable app_softmodemminipavi --disable BUILD_NATIVE \
        --disable-category MENUSELECT_CORE_SOUNDS --disable-category MENUSELECT_MOH --disable-category MENUSELECT_EXTRA_SOUNDS \
        menuselect.makeopts \
    && make -j"$(nproc)" \
    && make install DESTDIR=/out && make samples DESTDIR=/out \
    && test -f /out/usr/lib/asterisk/modules/app_softmodemminipavi.so

# Sous Debian, /var/run est un lien vers /run : on y déplace ce qu'Asterisk a installé dans /var/run
RUN mv /out/var/run /out/run

# --- Étape 3 : le serveur Asterisk
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        libtiff6 libjpeg62-turbo libedit2 libuuid1 libjansson4 libxml2 libsqlite3-0 libssl3 libsrtp2-1 \
        gettext-base ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /out/ /

# Le build échoue s'il manque une librairie à Asterisk ou au module softmodem
RUN ldconfig \
    && ! ldd /usr/sbin/asterisk /usr/lib/asterisk/modules/app_softmodemminipavi.so /usr/lib/asterisk/modules/res_pjsip.so | grep "not found"

# Configuration : écrite au démarrage à partir des variables d'environnement
COPY asterisk/*.template /etc/asterisk-templates/
COPY --from=src /src/VERSION /MINIPAVI_VERSION
COPY asterisk/start-asterisk.sh /

# SIP (5060) et RTP (10000-10100) en UDP : à publier. AMI (5038) : réservé à la passerelle, à ne pas publier.
EXPOSE 5060/udp 10000-10100/udp

CMD ["/start-asterisk.sh"]
