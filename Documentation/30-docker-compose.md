# 30 - Lancer avec Docker Compose

Le fichier `docker-compose.yml` décrit les cinq images ensemble : leurs variables, leurs ports et le réseau qui les relie. Il remplace les commandes `docker build` et `docker run` des articles 10 à 14 par une seule commande, et donne exactement le même résultat.

Cet article est facultatif : chaque image peut aussi être lancée seule, comme décrit dans son article.

## Démarrer

```bash
# 1. Créer son fichier de réglages et y renseigner au moins MINIPAVI_HTTP_PASSWORD
cp .env.example .env

# 2. Construire et lancer la passerelle et l'émulateur
docker compose up -d --build
```

L'émulateur est alors à `http://localhost:8081/` et VisuWeb à `http://localhost:8080/`.

```bash
docker compose logs -f minipavi    # suivre les logs d'un service
docker compose down                # tout arrêter
```

## Le fichier `.env`

Toutes les valeurs se règlent dans le fichier `.env`, créé à partir de `.env.example`. Il contient des mots de passe : il n'est pas enregistré dans git.

- Une variable absente, commentée ou vide prend la valeur par défaut de l'image.
- Les variables sont les mêmes que dans les articles 10 à 14.
- Une valeur qui contient un `$` s'écrit entre apostrophes : `MINIPAVI_HTTP_PASSWORD='pa$se'`.
- Après une modification, relancer `docker compose up -d`.

Les valeurs par défaut des adresses publiques (`GATEWAY_URL`, `MINIPAVI_VIEWER_URL`, `WEBMEDIA_URL`) désignent `localhost` : elles conviennent pour un essai sur sa propre machine et sont à remplacer par les adresses publiques sur un serveur. Voir [02 - Les liaisons entre images](02-liaisons.md).

## Les images facultatives : les profils

Sans option, seuls la passerelle et l'émulateur démarrent. Chacune des trois autres images est un profil, à ajouter à la commande :

| Profil | Image | Port publié | À renseigner dans `.env` |
|---|---|---|---|
| `webmedia` | [WebMedia](12-webmedia.md) | `8082` | rien pour un essai local |
| `accueil-extcall` | [Accueil et EXTcall](13-accueil-extcall.md) | aucun | `MINIPAVI_DEFAULT_URL` et `MINIPAVI_EXTCALL_URL`, pour que la passerelle utilise ces services |
| `asterisk` | [Asterisk](14-asterisk.md) | `5060/udp`, `10000-10100/udp` | la ligne SIP, `MINIPAVI_AST_PORT`, et pour les appels sortants les variables de l'AMI |

```bash
# Exemple : passerelle, émulateur, accueil et WebMedia
docker compose --profile accueil-extcall --profile webmedia up -d --build
```

Les mêmes profils sont à répéter pour `docker compose down`.

Les lignes correspondantes sont prêtes, en commentaire, dans `.env.example`.

## Ce que Compose règle tout seul

- **Le réseau** : tous les services sont sur le même réseau et se joignent par leur nom (`minipavi`, `accueil-extcall`, `asterisk`). C'est pourquoi `.env.example` propose `http://accueil-extcall:8080/…` et `MINIPAVI_AMI_HOST=asterisk`.
- **Les valeurs communes** : la version de MiniPavi, la clé `MINIPAVI_CONNECT_KEY`, le port `MINIPAVI_AST_PORT`, l'utilisateur et le mot de passe de l'AMI ne s'écrivent qu'une fois dans `.env` et sont donnés aux deux images concernées.
- **Asterisk connaît la passerelle** : `MINIPAVI_HOST` vaut d'office `minipavi` pour ce service.

## Ports publiés sur la machine

| Port | Service |
|---|---|
| `8181` | Passerelle : websocket |
| `8080` | Passerelle : VisuWeb et WebMedia |
| `8081` | Émulateur |
| `8082` | WebMedia (profil) |
| `5060/udp`, `10000-10100/udp` | Asterisk (profil) |

Sur un serveur, ces ports se placent d'ordinaire derrière un proxy qui apporte le HTTPS ; seuls les ports UDP d'Asterisk sont à ouvrir tels quels.

## Changer de version de MiniPavi

Modifier `MINIPAVI_VERSION` dans `.env`, puis reconstruire : toutes les images suivent.

```bash
docker compose up -d --build
```

Avec `latest`, la même commande installe la dernière release dès qu'il en sort une.

Voir [01 - La version de MiniPavi](01-version-minipavi.md).

## Vérifié

Les cinq services ont été lancés ensemble avec ce fichier : la passerelle affiche la page d'accueil du profil `accueil-extcall` à un client websocket, l'émulateur et WebMedia servent les bonnes adresses, un appel simulé connecte Asterisk à la passerelle et la passerelle s'identifie sur l'AMI. Les limites sont les mêmes que pour chaque image : pas de vraie ligne téléphonique, pas d'envoi WebMedia réel.
