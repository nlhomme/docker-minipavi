# docker-minipavi

Images Docker de [MiniPavi](https://github.com/ludosevilla/minipavi), la passerelle qui fait revivre les services Minitel : la passerelle elle-même, l'émulateur Minitel, la page WebMedia, les services d'accueil et le serveur téléphonique Asterisk.

Ce dépôt ne contient pas le code de MiniPavi : il est téléchargé depuis le dépôt de son auteur, Jean-Arthur Silve, au moment de construire les images. Il n'y a donc rien à fusionner pour rester à jour.

## Les cinq images

MiniPavi est fait de cinq parties ; chacune a son Dockerfile. Seule la passerelle est indispensable.

| Image | Dockerfile | Rôle | Nécessaire ? |
|---|---|---|---|
| [Passerelle](documentation/10-passerelle.md) | `minipavi/Dockerfile` | Le point d'accès : reçoit les connexions des Minitel et appelle les services | oui |
| [Émulateur](documentation/11-emulateur.md) | `emulminitel/Dockerfile` | Page web affichant un Minitel dans le navigateur | pour un accès par le web |
| [WebMedia](documentation/12-webmedia.md) | `webmedia/Dockerfile` | Page web affichant les vidéos, sons et images envoyés par un service | si des services utilisent WebMedia |
| [Accueil et EXTcall](documentation/13-accueil-extcall.md) | `accueil-extcall/Dockerfile` | Les deux services fournis avec MiniPavi : page d'accueil avec annuaire, et connexion à des serveurs Minitel externes | facultatif |
| [Asterisk](documentation/14-asterisk.md) | `asterisk/Dockerfile` | Serveur téléphonique avec modem logiciel V23 : accès par téléphone avec un vrai Minitel | pour un accès par téléphone |

## Démarrage rapide

Le minimum pour voir un Minitel dans son navigateur : la passerelle et l'émulateur, sur sa propre machine.

```bash
# Créer son fichier de réglages, et y renseigner MINIPAVI_HTTP_PASSWORD
cp .env.example .env

# Construire et lancer la passerelle et l'émulateur
docker compose up -d --build
```

Ouvrir ensuite `http://localhost:8081/` : le Minitel s'affiche et se connecte à la passerelle. VisuWeb est à `http://localhost:8080/` (utilisateur `minipavi`, et le mot de passe choisi).

Pour arrêter : `docker compose down`.

Les trois autres images s'ajoutent par des profils : voir [documentation/30-docker-compose.md](documentation/30-docker-compose.md). Chaque image peut aussi être lancée seule avec `docker run`, comme décrit dans son article.

## Organisation du dépôt

Un dossier par image, portant le nom technique de l'image (celui de MiniPavi, utilisé aussi dans `docker-compose.yml`) :

| Dossier ou fichier | Contenu |
|---|---|
| `minipavi/` | La passerelle : son Dockerfile, son fichier de configuration, son script de démarrage, son contrôle de santé |
| `emulminitel/` | L'émulateur : son Dockerfile |
| `webmedia/` | La page WebMedia : son Dockerfile |
| `accueil-extcall/` | Les services d'accueil et EXTcall : leur Dockerfile et leurs fichiers de configuration |
| `asterisk/` | Le serveur téléphonique : son Dockerfile, ses fichiers de configuration, son script de démarrage, son contrôle de santé |
| `commun/` | Les scripts de démarrage partagés par plusieurs images |
| `docker-compose.yml`, `.env.example` | Les cinq images lancées ensemble, et le modèle de leurs réglages |
| `test.sh` | La vérification des images |
| `documentation/` | La documentation |

## ⚠️ La version de MiniPavi n'est pas figée

Par défaut, chaque construction d'image installe **la dernière release de MiniPavi**. Une reconstruction peut donc changer de version sans que personne ne l'ait décidé, et installer une release que personne n'a essayée ici.

Pour imposer une version : `--build-arg MINIPAVI_VERSION=1.6.1`. Les conséquences et la marche à suivre en cas de problème sont dans [documentation/01-version-minipavi.md](documentation/01-version-minipavi.md).

## Documentation

Tout le reste est dans le dossier [documentation/](documentation/README.md) : la version, les liaisons entre images, un article par image, la vérification, le dépannage, le lancement avec Docker Compose et l'hébergement dans Coolify.

## Licence

MiniPavi est distribué sous licence GPL v3 (fichier `LICENSE`), comme ce dépôt qui en reprend les fichiers de configuration.
