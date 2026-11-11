#!/bin/sh
# Démarrage du serveur Asterisk : écrit pjsip.conf, extensions.conf, manager.conf et rtp.conf
# à partir des modèles et des variables d'environnement, puis lance Asterisk.
set -eu

echo "MiniPavi version $(cat /MINIPAVI_VERSION)"

# Variables obligatoires
: "${SIP_SERVER:?Variable SIP_SERVER manquante : serveur du fournisseur SIP, ex. sip.exemple.org (voir Documentation/14-asterisk.md)}"
: "${SIP_USERNAME:?Variable SIP_USERNAME manquante : identifiant de la ligne SIP (voir Documentation/14-asterisk.md)}"
: "${SIP_PASSWORD:?Variable SIP_PASSWORD manquante : mot de passe de la ligne SIP (voir Documentation/14-asterisk.md)}"
: "${ASTERISK_EXTERNAL_ADDRESS:?Variable ASTERISK_EXTERNAL_ADDRESS manquante : adresse publique du serveur (voir Documentation/14-asterisk.md)}"
: "${MINIPAVI_HOST:?Variable MINIPAVI_HOST manquante : adresse de la passerelle MiniPavi (voir Documentation/14-asterisk.md)}"
: "${AMI_PASSWORD:?Variable AMI_PASSWORD manquante : mot de passe de l AMI, le même que MINIPAVI_AMI_PASSWORD (voir Documentation/14-asterisk.md)}"

# Variables avec valeur par défaut
: "${MINIPAVI_AST_PORT:=8183}"
: "${ASTERISK_LOCAL_NET:=172.16.0.0/12}"
: "${AMI_USER:=minipavi}"
: "${AMI_PERMIT:=172.16.0.0/255.240.0.0}"
: "${RTP_START:=10000}"
: "${RTP_END:=10100}"

VARS='SIP_SERVER SIP_USERNAME SIP_PASSWORD ASTERISK_EXTERNAL_ADDRESS ASTERISK_LOCAL_NET MINIPAVI_HOST MINIPAVI_AST_PORT AMI_USER AMI_PASSWORD AMI_PERMIT RTP_START RTP_END'

# Dans les fichiers d'Asterisk, un ";" commence un commentaire et un retour à la ligne commence un réglage :
# le ";" est protégé, le retour à la ligne est refusé
list=''
for name in $VARS; do
    eval "value=\$$name"
    if [ "$(printf '%s' "$value" | wc -l)" -ne 0 ]; then
        echo "Variable $name invalide : elle contient un retour à la ligne" >&2
        exit 1
    fi
    value=$(printf '%s' "$value" | sed 's/;/\\;/g')
    export "$name=$value"
    list="$list \${$name}"
done

# Seules les variables listées sont remplacées : les ${...} d'Asterisk restent intacts
for template in /etc/asterisk-templates/*.template; do
    envsubst "$list" < "$template" > "/etc/asterisk/$(basename "${template%.template}")"
done

# -f : au premier plan, pour que le conteneur vive tant qu'Asterisk tourne
exec asterisk -f
