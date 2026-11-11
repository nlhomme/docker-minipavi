#!/bin/sh
# Contrôle de santé d'Asterisk : le serveur doit répondre à sa propre ligne de commande.
# Code de sortie : 0 si Asterisk répond, autre chose sinon.
exec asterisk -rx 'core show uptime' > /dev/null 2>&1
