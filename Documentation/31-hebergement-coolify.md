# 31 - Héberger dans Coolify

Cet article est facultatif : il ne concerne que l'hébergement dans [Coolify](https://coolify.io/). Les images fonctionnent avec n'importe quel hébergement Docker.

Les noms des écrans et des cases peuvent varier d'une version de Coolify à l'autre.

## Une ressource par image

Créer une ressource par image voulue, toutes branchées sur ce dépôt :

| Ressource | Dockerfile Location | Ports Exposés |
|---|---|---|
| Passerelle | `/minipavi/Dockerfile` | `8181` (websocket) et `8080` (VisuWeb et WebMedia) |
| Émulateur | `/emulminitel/Dockerfile` | `8080` |
| WebMedia | `/webmedia/Dockerfile` | `8080` |
| Accueil et EXTcall | `/accueil-extcall/Dockerfile` | `8080` |
| Asterisk | `/asterisk/Dockerfile` | aucun port web (voir plus bas) |

Laisser « Base Directory » à `/` : chaque Dockerfile est dans le dossier de son image, mais copie aussi des fichiers du dossier `commun/`. Avec un autre « Base Directory », la construction échoue.

## Deux réglages que Coolify ne devine pas

**Le build pack.** Le dépôt contient cinq Dockerfiles, rangés dans des sous-dossiers, et un `docker-compose.yml` : Coolify ne peut pas deviner lequel utiliser. Pour chaque ressource, choisir le build pack **Dockerfile** (et non Docker Compose), puis vérifier que « Dockerfile Location » désigne le bon fichier du tableau ci-dessus. Ce que Coolify propose de lui-même à cette étape dépend de sa version et n'a pas été essayé avec cette organisation du dépôt.

Déployer les cinq images d'un coup avec le build pack Docker Compose de Coolify n'a pas été essayé non plus.

**Le port.** Pour un dépôt Git, Coolify ne lit pas le port dans le Dockerfile : il propose `3000` par défaut. « Ports Exposés » est donc à renseigner à la main. Avec un mauvais port, le conteneur tourne mais le site répond par une **erreur 502**.

## Variables

Dans les variables d'environnement de chaque ressource :

- les variables décrites dans l'article de chaque image sont des variables ordinaires, disponibles à l'exécution ; les mots de passe sont à marquer comme secrets ;
- `MINIPAVI_VERSION` est une variable **de build** (case « Build Variable » ou « Available at Buildtime »).

Une variable cochée seulement comme variable de build n'arrive pas au conteneur : celui-ci s'arrête en signalant une variable manquante.

## `MINIPAVI_VERSION` en variable partagée

Pour que toutes les images soient toujours sur la même version de MiniPavi, ne pas écrire le numéro dans chaque ressource mais dans une **variable partagée** :

1. Créer une fois la variable partagée `MINIPAVI_VERSION` au niveau du projet (Shared Variables), avec la valeur `latest`.
2. Dans chaque ressource, ajouter la variable de build `MINIPAVI_VERSION` avec pour valeur la référence `{{project.MINIPAVI_VERSION}}`.
3. Pour imposer une version : mettre par exemple `1.6.1` dans la variable partagée, puis redéployer **toutes** les ressources. Modifier la variable ne reconstruit rien tout seul.
4. Pour revenir à la dernière release : remettre `latest` dans la variable partagée (plutôt que de la supprimer), puis redéployer les ressources.

## Quand la version de MiniPavi change

Coolify ne reconstruit une image que lors d'un push sur ce dépôt ou d'un clic sur Redeploy. La sortie d'une nouvelle release de MiniPavi ne déclenche rien : la nouvelle version arrive au redéploiement suivant, quelle qu'en soit la raison. Voir [01 - La version de MiniPavi](01-version-minipavi.md).

## Message « Validating DNS failed »

En enregistrant un domaine, Coolify vérifie que son enregistrement DNS de type A désigne directement l'adresse IP du serveur. Si le domaine passe par Cloudflare (enregistrement proxifié ou tunnel), il désigne les adresses de Cloudflare : la vérification échoue alors que le site fonctionne.

C'est une fausse alerte dans ce cas. On peut l'ignorer, ou désactiver la validation DNS dans les réglages de l'instance. Ne pas « corriger » en retirant le proxy de Cloudflare : cela exposerait directement l'adresse du serveur.

## Asterisk dans Coolify

**Non essayé.** Les points à prévoir, à partir de [14 - Asterisk](14-asterisk.md) :

- **Publier les ports UDP sur le serveur** avec « Ports Mappings », par exemple `5060:5060/udp,10000-10100:10000-10100/udp`, et les ouvrir dans le pare-feu. La téléphonie ne passe ni par le proxy de Coolify ni par un tunnel Cloudflare ; aucun domaine n'est nécessaire pour cette ressource.
- **Ne pas publier le port `5038`** (AMI).
- **Mettre Asterisk et la passerelle sur un même réseau Docker**, et utiliser leurs noms de conteneur dans `MINIPAVI_HOST` et `MINIPAVI_AMI_HOST`. La façon de partager un réseau entre deux ressources et le nom exact des conteneurs dépendent de la version de Coolify : à vérifier dans son interface.
- **Prévoir un déploiement long** : la compilation d'Asterisk prend plusieurs minutes.
