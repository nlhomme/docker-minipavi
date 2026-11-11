# 10 - Passerelle

## Rôle

La passerelle est le cœur de MiniPavi et la seule image indispensable. Elle reçoit les connexions des Minitel (par l'émulateur web, ou par téléphone avec Asterisk), appelle les services en HTTP et renvoie leurs écrans. Elle fournit aussi VisuWeb, une interface web pour suivre les connexions en cours.

## Construire et lancer

```bash
docker build -t minipavi . -f minipavi/Dockerfile

docker run -d --name minipavi -p 8181:8181 -p 8080:8080 \
  -e MINIPAVI_HTTP_PASSWORD=change-moi \
  -e MINIPAVI_VIEWER_URL=http://localhost:8081/ \
  minipavi
```

## Ports

| Port | Usage |
|---|---|
| `8181` | Websocket : les connexions de l'émulateur. Modifiable avec `MINIPAVI_WS_PORT` |
| `8080` | VisuWeb (protégé par mot de passe) et WebMedia |
| `8183` | Connexions venant d'Asterisk, si `MINIPAVI_AST_PORT` est renseignée. Port interne : à ne pas publier |

## Variables

| Variable | Obligatoire | Valeur par défaut | Rôle |
|---|---|---|---|
| `MINIPAVI_HTTP_PASSWORD` | oui | | Mot de passe de VisuWeb |
| `MINIPAVI_VIEWER_URL` | oui | | Adresse publique de l'émulateur, ex. `https://minitel.exemple.org:443/` |
| `MINIPAVI_HTTP_USER` | non | `minipavi` | Nom d'utilisateur de VisuWeb |
| `MINIPAVI_DEFAULT_URL` | non | `http://www.minipavi.fr/minipavitest/` | Service affiché à la connexion |
| `MINIPAVI_EXTCALL_URL` | non | `http://www.minipavi.fr/EXTcall/` | Adresse du service EXTcall |
| `MINIPAVI_WS_PORT` | non | `8181` | Port websocket |
| `MINIPAVI_HOST` | non | `127.0.0.1` | Adresse de la passerelle, sans le port |
| `MINIPAVI_VERBOSE` | non | `0` | `1` pour des logs détaillés |
| `MINIPAVI_CONNECT_KEY` | non | `Key1234` | Clé d'autorisation des connexions vers l'extérieur |
| `MINIPAVI_VISU_KEY` | non | `123abc` | Clé de visualisation des utilisateurs |

Les deux dernières valeurs par défaut sont celles de l'exemple fourni avec MiniPavi, donc publiques : à remplacer si ces fonctions sont utilisées.

### Avec Asterisk

| Variable | Obligatoire | Valeur par défaut | Rôle |
|---|---|---|---|
| `MINIPAVI_AST_PORT` | pour les appels entrants | `0` (désactivé) | Port sur lequel Asterisk se connecte à la passerelle, ex. `8183` |
| `MINIPAVI_AMI_PASSWORD` | pour les appels sortants | | Mot de passe de l'AMI d'Asterisk. Sans elle, les appels sortants sont désactivés et les trois variables suivantes sont ignorées |
| `MINIPAVI_AMI_HOST` | avec la précédente | | Adresse du conteneur Asterisk |
| `MINIPAVI_SIP_CHANNEL` | avec la précédente | | Canal SIP des appels sortants, ex. `PJSIP/trunk/sip:%NUM%@sip.exemple.org` |
| `MINIPAVI_AMI_USER` | non | `minipavi` | Utilisateur de l'AMI |
| `MINIPAVI_AMI_PORT` | non | `5038` | Port de l'AMI |

Les correspondances avec les variables de l'image Asterisk sont dans [02 - Les liaisons entre images](02-liaisons.md).

## Fichier à adapter

`minipavi/minipavi.conf.template` est le fichier de configuration de la passerelle, repris de l'exemple `minipavi-base.conf` de MiniPavi. Les réglages qui ne sont pas des variables (nombre maximum de connexions, délai d'inactivité, etc.) s'y modifient directement.

La signification de chaque réglage est décrite dans la documentation de MiniPavi (`MiniPavi-doc.pdf`, dans le dépôt de l'auteur). Un réglage ajouté par une nouvelle version de MiniPavi n'apparaît pas tout seul dans ce fichier : il faut l'y ajouter.

## Vérifier

```bash
docker logs minipavi | head -30
```

Les logs commencent par la version, puis par le résumé de la configuration : ports, service par défaut, Asterisk activé ou non. VisuWeb doit répondre sur le port 8080 avec l'utilisateur et le mot de passe choisis.
