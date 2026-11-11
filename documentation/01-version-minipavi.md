# 01 - La version de MiniPavi

Le code de MiniPavi est téléchargé depuis le dépôt de son auteur à chaque construction d'image. La version téléchargée est choisie par la variable de build `MINIPAVI_VERSION`, la même pour toutes les images.

## Choisir la version

| Valeur de `MINIPAVI_VERSION` | Version installée |
|---|---|
| absente, vide ou `latest` | la dernière release publiée par l'auteur |
| un numéro de release, ex. `1.6.1` | cette version précise |

`latest` s'écrit en minuscules. Les numéros sont ceux de la [liste des releases](https://github.com/ludosevilla/minipavi/releases) de MiniPavi.

```bash
# Dernière release
docker build -t minipavi . -f minipavi/Dockerfile

# Version imposée
docker build --build-arg MINIPAVI_VERSION=1.6.1 -t minipavi . -f minipavi/Dockerfile
```

## Savoir quelle version tourne

Chaque conteneur l'affiche en première ligne de ses logs :

```bash
docker logs minipavi | head -1
# MiniPavi version 1.6.1
```

## ⚠️ Avertissement : la version n'est pas figée

Par défaut, les images suivent la dernière release de MiniPavi. C'est pratique, mais il faut en connaître les conséquences :

- **Une reconstruction peut changer la version de MiniPavi sans que personne ne l'ait décidé.** Une reconstruction faite pour une autre raison installe la release du jour.
- **Les images peuvent se retrouver sur des versions différentes**, si elles ne sont pas reconstruites au même moment. Il en va de même entre un environnement de test et la production.
- **Une nouvelle release peut avoir besoin de quelque chose que l'image n'a pas** (une extension PHP, un programme), ou changer les fichiers que les scripts de démarrage modifient. Dans ce dernier cas, le conteneur refuse de démarrer et le dit dans ses logs.
- **Une nouvelle release n'a été essayée par personne ici** avant d'arriver en production.

L'image Asterisk suit de la même façon la dernière version de la branche 22 d'Asterisk (variable de build `ASTERISK_VERSION`).

## En cas de problème après une reconstruction

1. Lire la version dans les logs d'un conteneur qui fonctionnait encore (`MiniPavi version …`), ou choisir la release précédente dans la liste des releases.
2. Imposer cette version avec `MINIPAVI_VERSION` et reconstruire **toutes** les images.
3. Revenir à `latest` quand le problème est réglé.

## Limite de GitHub

Pour connaître la dernière release, la construction interroge l'API publique de GitHub, limitée à 60 requêtes par heure et par adresse IP. Au-delà, la construction échoue ; il suffit d'attendre, ou d'imposer une version.
