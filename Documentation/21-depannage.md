# 21 - Dépannage

Le premier réflexe est de lire les logs du conteneur : `docker logs <nom>`. Les conteneurs de ce dépôt s'arrêtent d'eux-mêmes quand leur configuration est incomplète, en disant pourquoi.

## Le conteneur s'arrête dès le démarrage

| Message dans les logs | Cause | Solution |
|---|---|---|
| `Variable d'environnement manquante : NOM` | Une variable obligatoire n'est pas renseignée | La renseigner (voir l'article de l'image) |
| `Variable GATEWAY_URL manquante…` | Idem, sur l'émulateur | Renseigner `GATEWAY_URL` |
| `Variable WEBMEDIA_URL manquante…` | Idem, sur WebMedia | Renseigner `WEBMEDIA_URL` |
| `GATEWAY_URL invalide : …` | L'adresse ne commence pas par `ws://` ou `wss://`, ou contient un caractère interdit (espace, guillemet…) | Corriger l'adresse |
| `WEBMEDIA_URL invalide : …` | L'adresse ne commence pas par `http://` ou `https://`, ou contient un caractère interdit | Corriger l'adresse |
| `Adresse d'exemple encore présente dans : …` | Une nouvelle version de MiniPavi a changé les fichiers que le démarrage modifie | Imposer la version précédente ([01](01-version-minipavi.md)), puis adapter `commun/start-web.sh` |
| `Variable … invalide : elle contient un retour à la ligne` | Sur Asterisk, une valeur contient un retour à la ligne | Corriger la valeur |

Une variable doit être disponible **à l'exécution** du conteneur. Si l'hébergeur distingue variables de build et variables d'exécution, une variable de build seule n'arrive pas au conteneur.

## La construction échoue

| Message | Cause | Solution |
|---|---|---|
| `Version de MiniPavi introuvable` | La dernière release n'a pas pu être lue, souvent à cause de la limite de l'API de GitHub (60 requêtes par heure) | Attendre, ou imposer une version avec `MINIPAVI_VERSION` |
| Erreur au téléchargement de l'archive | Le numéro de version n'existe pas (attention : `latest` s'écrit en minuscules) | Vérifier le numéro dans la liste des releases de MiniPavi |

## Le conteneur tourne, mais rien ne s'affiche

- **L'émulateur s'affiche mais l'écran reste vide** : le navigateur n'arrive pas à joindre la passerelle. Vérifier que `GATEWAY_URL`, écrite sous l'écran du Minitel, est joignable depuis le navigateur, et qu'elle désigne bien le port websocket (8181) de la passerelle.
- **Erreur 502 devant un conteneur qui tourne** : le proxy placé devant le conteneur ne s'adresse pas au bon port. Les images web écoutent sur le port `8080`, la passerelle sur `8181` et `8080`.
- **La passerelle affiche « ERR#03 Réponse non JSON »** : le service appelé a renvoyé autre chose qu'une réponse de service, souvent une erreur PHP. Lire les logs du conteneur du service.
- **La passerelle n'atteint pas un service** : depuis un conteneur, `localhost` désigne le conteneur lui-même. Utiliser le nom du conteneur du service, sur un réseau Docker commun ([02](02-liaisons.md)).

## Le conteneur est marqué `unhealthy`

Le contrôle de santé de l'image a échoué trois fois de suite : le programme ne répond plus, même si le conteneur tourne encore. Le détail des derniers contrôles se lit avec :

```bash
docker inspect -f '{{json .State.Health}}' <nom>
```

- **Passerelle** : son port 8080 ne répond plus. Lire ses logs, puis redémarrer le conteneur.
- **Asterisk** : le serveur ne répond plus à sa ligne de commande. Pendant les 30 premières secondes après le démarrage, l'état `starting` est normal.
- **Images web** : le serveur web ou PHP ne répond plus dans le conteneur.

## Après une reconstruction, quelque chose ne marche plus

La version de MiniPavi a peut-être changé. La comparer dans les logs (`MiniPavi version …`) et suivre [01 - La version de MiniPavi](01-version-minipavi.md).

## Asterisk

- **`Identify 'trunk' failed when adding resolution results`** : le nom donné dans `SIP_SERVER` n'est pas résolu. Vérifier son orthographe.
- **La ligne n'est pas `Registered`** (`pjsip show registrations`) : identifiant ou mot de passe refusé, ou ports UDP non joignables. Vérifier `SIP_USERNAME`, `SIP_PASSWORD`, `ASTERISK_EXTERNAL_ADDRESS` et la publication des ports.
- **`undefined symbol: fsk_rx_set_signal_cutoff`** au chargement du module : la librairie spandsp n'est pas la version 3. Cela ne devrait pas arriver avec cette image, qui compile celle fournie par MiniPavi.
- **L'appel aboutit mais le Minitel n'affiche rien** : Asterisk n'atteint pas la passerelle. Vérifier `MINIPAVI_HOST`, que `MINIPAVI_AST_PORT` a la même valeur des deux côtés, et que les deux conteneurs partagent un réseau.
