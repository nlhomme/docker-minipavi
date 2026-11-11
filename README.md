# docker-minipavi

Images Docker de la passerelle [MiniPavi](https://github.com/ludosevilla/minipavi) et de son émulateur Minitel.

Ce dépôt ne contient pas le code de MiniPavi : il est téléchargé depuis le dépôt de son auteur, Jean-Arthur Silve, au moment de construire les images. Il n'y a donc rien à fusionner pour rester à jour.

## Fichiers

- `Dockerfile-minipavi` : image de la passerelle
- `Dockerfile-emulminitel` : image de l'émulateur Minitel (page web)
- `minipavi.conf.template` : configuration de la passerelle, complétée au démarrage par les variables d'environnement
- `start-minipavi.php` et `start-emulminitel.sh` : scripts de démarrage des deux conteneurs
- `test.sh` : vérification des deux images

## Version de MiniPavi

La version est choisie à la construction par la variable `MINIPAVI_VERSION` :

- absente, vide ou `latest` : la dernière release publiée par l'auteur
- un numéro de release, par exemple `1.6.1` : cette version précise

```bash
# Dernière release
docker build --rm -t nlhomme/nlhomme-minipavi:latest . -f Dockerfile-minipavi
docker build --rm -t nlhomme/nlhomme-emulminitel:latest . -f Dockerfile-emulminitel

# Version imposée
docker build --rm --build-arg MINIPAVI_VERSION=1.6.1 -t nlhomme/nlhomme-minipavi:latest . -f Dockerfile-minipavi
```

Chaque conteneur affiche sa version au démarrage, en première ligne de ses logs : `MiniPavi version 1.6.1`.

## ⚠️ Avertissement : la version n'est pas figée

Par défaut, les images suivent la dernière release de MiniPavi. C'est pratique, mais il faut en connaître les conséquences :

- **Une reconstruction peut changer la version de MiniPavi sans que personne ne l'ait décidé.** Un redéploiement fait pour une autre raison (changement de variable, reconstruction de l'image) installe la release du jour.
- **La passerelle et l'émulateur peuvent se retrouver sur deux versions différentes**, s'ils ne sont pas reconstruits au même moment. Il en va de même entre un environnement de test et la production.
- **Une nouvelle release peut avoir besoin de quelque chose que l'image n'a pas** (une extension PHP, un programme), ou changer les fichiers que les scripts de démarrage modifient. Dans ce dernier cas, l'émulateur refuse de démarrer et le dit dans ses logs.
- **Une nouvelle release n'a été essayée par personne ici** avant d'arriver en production.

En cas de problème après une reconstruction :

1. Lire la version dans les logs d'un conteneur qui fonctionnait (`MiniPavi version …`), ou choisir la release précédente dans la [liste des releases](https://github.com/ludosevilla/minipavi/releases).
2. Imposer cette version avec `MINIPAVI_VERSION` (voir ci-dessous pour Coolify) et reconstruire **les deux** images.
3. Revenir à `latest` quand le problème est réglé.

## Variables d'environnement

Ces variables sont lues **au démarrage** des conteneurs : les changer demande un redémarrage, pas une reconstruction.

### Passerelle

| Variable | Obligatoire | Valeur par défaut | Rôle |
|---|---|---|---|
| `MINIPAVI_HTTP_PASSWORD` | oui | | Mot de passe de VisuWeb (interface web de la passerelle) |
| `MINIPAVI_VIEWER_URL` | oui | | Adresse de l'émulateur, ex. `https://minitel.exemple.org:443/` |
| `MINIPAVI_HTTP_USER` | non | `minipavi` | Nom d'utilisateur de VisuWeb |
| `MINIPAVI_DEFAULT_URL` | non | `http://www.minipavi.fr/minipavitest/` | Service affiché à la connexion |
| `MINIPAVI_WS_PORT` | non | `8181` | Port websocket de la passerelle |
| `MINIPAVI_HOST` | non | `127.0.0.1` | Adresse de la passerelle, sans le port |
| `MINIPAVI_VERBOSE` | non | `0` | `1` pour des logs détaillés |
| `MINIPAVI_CONNECT_KEY` | non | `Key1234` | Clé d'autorisation des connexions vers l'extérieur |
| `MINIPAVI_VISU_KEY` | non | `123abc` | Clé de visualisation des utilisateurs |

Les deux dernières valeurs par défaut sont celles de l'exemple fourni avec MiniPavi, donc publiques : à remplacer si ces fonctions sont utilisées.

Le reste de la configuration se modifie dans `minipavi.conf.template`. La signification de chaque réglage est décrite dans la documentation de MiniPavi (`MiniPavi-doc.pdf`, dans le dépôt de l'auteur).

### Émulateur

| Variable | Obligatoire | Valeur par défaut | Rôle |
|---|---|---|---|
| `GATEWAY_URL` | oui | | Adresse websocket de la passerelle, ex. `wss://passerelle.exemple.org:443/` |
| `WEBMEDIA_URL` | non | déduite de `GATEWAY_URL` (`ws` devient `http`, `wss` devient `https`, suivie de `?action=webmedia`) | Adresse WebMedia de la passerelle |

Si une variable obligatoire manque, le conteneur s'arrête aussitôt et le dit dans ses logs.

## Déployer dans Coolify

Deux ressources, toutes deux branchées sur ce dépôt :

| Ressource | Dockerfile Location | Ports Exposés |
|---|---|---|
| Passerelle | `/Dockerfile-minipavi` | `8181` (websocket, ou la valeur de `MINIPAVI_WS_PORT`) et `8080` (VisuWeb) |
| Émulateur | `/Dockerfile-emulminitel` | `8080` |

Coolify ne trouve pas ces Dockerfiles tout seul (il cherche un fichier nommé `Dockerfile`) : choisir le build pack **Dockerfile** à la main, puis renseigner « Dockerfile Location ».

**« Ports Exposés » est à renseigner à la main.** Pour un dépôt Git, Coolify ne lit pas le port dans le Dockerfile : il propose `3000` par défaut. Avec un mauvais port, le conteneur tourne mais le site répond par une erreur 502.

Dans les variables d'environnement de chaque ressource :

- les variables des tableaux ci-dessus sont des variables ordinaires (disponibles à l'exécution) ; le mot de passe est à marquer comme secret ;
- `MINIPAVI_VERSION` est une variable **de build** (case « Build Variable » ou « Available at Buildtime » selon la version de Coolify).

### `MINIPAVI_VERSION` en variable partagée

Pour que la passerelle et l'émulateur soient toujours sur la même version, ne pas écrire le numéro dans chaque ressource mais dans une **variable partagée** :

1. Créer une fois la variable partagée `MINIPAVI_VERSION` au niveau du projet (Shared Variables), avec la valeur `latest`.
2. Dans chacune des deux ressources, ajouter la variable de build `MINIPAVI_VERSION` avec pour valeur la référence `{{project.MINIPAVI_VERSION}}`.
3. Pour imposer une version : mettre par exemple `1.6.1` dans la variable partagée, puis redéployer **les deux** ressources. Modifier la variable ne reconstruit rien tout seul.
4. Pour revenir à la dernière release : remettre `latest` dans la variable partagée (plutôt que de la supprimer), puis redéployer les deux ressources.

Coolify ne reconstruit une image que lors d'un push sur ce dépôt ou d'un clic sur Redeploy : la sortie d'une nouvelle release de MiniPavi ne déclenche rien. La nouvelle version arrive au redéploiement suivant.

## Vérifier

```bash
./test.sh          # avec la dernière release
./test.sh 1.6.1    # avec une version précise
```

Le script construit les deux images, les démarre avec des valeurs de test, puis contrôle que la passerelle tourne, que sa configuration est bien écrite et que l'émulateur sert la bonne adresse. Il affiche `OK` à la fin.

## Licence

MiniPavi est distribué sous licence GPL v3 (fichier `LICENSE`), comme ce dépôt qui en reprend le fichier de configuration.
