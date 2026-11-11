# 12 - WebMedia

## Rôle

WebMedia permet à un service Minitel d'envoyer une vidéo, un son ou une image au visiteur pendant sa consultation. Cette image sert la page web sur laquelle ce contenu s'affiche : le visiteur y saisit le code Pin de sa connexion, puis la page interroge la passerelle.

Elle n'est utile que si des services utilisent WebMedia. L'émulateur intègre déjà son propre affichage WebMedia ; cette page séparée permet d'y accéder sans lui, par exemple quand on est connecté avec un vrai Minitel.

## Construire et lancer

```bash
docker build -t webmedia . -f webmedia/Dockerfile

docker run -d --name webmedia -p 8082:8080 \
  -e WEBMEDIA_URL='http://localhost:8080?action=webmedia' \
  webmedia
```

## Ports

| Port | Usage |
|---|---|
| `8080` | La page web WebMedia |

## Variables

| Variable | Obligatoire | Valeur par défaut | Rôle |
|---|---|---|---|
| `WEBMEDIA_URL` | oui | | Adresse WebMedia de la passerelle, ex. `https://visuweb.exemple.org?action=webmedia` |

`WEBMEDIA_URL` est l'adresse publique du port **VisuWeb** de la passerelle (8080), et non de son port websocket, suivie de `?action=webmedia`. C'est le navigateur du visiteur qui l'interroge.

## Contrôle de santé

Celui de l'image de base (`trafex/php-nginx`) : le serveur web et PHP doivent répondre dans le conteneur.

## Vérifier

Ouvrir la page : elle demande un code Pin. L'adresse utilisée se lit dans le fichier `webmedia.js` servi par le conteneur.

**Non vérifié ici :** l'envoi réel d'un contenu par un service jusqu'à cette page. Seuls la page et son adresse ont été contrôlés.
