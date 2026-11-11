# Documentation

Les articles sont numérotés dans l'ordre où l'on en a besoin pour installer MiniPavi.

## Avant de commencer

- [01 - La version de MiniPavi](01-version-minipavi.md) : quelle version est installée, comment en imposer une, et l'avertissement à connaître
- [02 - Les liaisons entre images](02-liaisons.md) : comment les conteneurs se joignent, et les variables qui doivent correspondre de l'un à l'autre

## Les images

Dans l'ordre de mise en place. Seule la passerelle est indispensable.

- [10 - Passerelle](10-passerelle.md)
- [11 - Émulateur](11-emulateur.md)
- [12 - WebMedia](12-webmedia.md)
- [13 - Accueil et EXTcall](13-accueil-extcall.md)
- [14 - Asterisk](14-asterisk.md)

Chaque article suit le même plan : le rôle de l'image, comment la construire et la lancer, ses variables, ses ports, comment la vérifier.

## Une fois installé

- [20 - Vérifier](20-verifier.md) : le script `test.sh`
- [21 - Dépannage](21-depannage.md) : un conteneur qui ne démarre pas, les messages des logs

## Lancer et héberger

Les images fonctionnent avec n'importe quel hébergement Docker. Ces deux articles sont facultatifs : chacun décrit une façon de les lancer.

- [30 - Lancer avec Docker Compose](30-docker-compose.md) : les cinq images ensemble, en une commande
- [31 - Héberger dans Coolify](31-hebergement-coolify.md)

## Principe commun à toutes les images

- **Les commandes `docker build` se lancent depuis la racine du dépôt**, avec `-f <image>/Dockerfile` : les images partagent des scripts du dossier `commun/`.
- **La configuration passe par des variables d'environnement**, lues au démarrage du conteneur. En changer une demande un redémarrage, pas une reconstruction.
- **Une variable obligatoire manquante arrête le conteneur** aussitôt, avec un message dans ses logs.
- **Les fichiers `*.template` du dépôt sont des modèles** de fichiers de configuration : au démarrage, les `${VARIABLES}` y sont remplacées par les variables d'environnement. Le reste de leur contenu se modifie directement dans le dépôt.
- **Chaque conteneur affiche la version de MiniPavi** en première ligne de ses logs : `MiniPavi version 1.6.1`.
- **Chaque image déclare un contrôle de santé** : `docker ps` affiche `(healthy)` quand le conteneur fonctionne, `(unhealthy)` quand il ne répond plus. Les hébergeurs comme Coolify s'en servent pour savoir si un déploiement a réussi.
