# 13 - Accueil et EXTcall

## Rôle

Cette image contient les deux services fournis avec MiniPavi :

- **MiniPaviAcc**, servi à `/MiniPaviAcc/` : la page d'accueil d'une passerelle. Le visiteur y saisit le code ou l'adresse d'un service, ou consulte l'annuaire.
- **EXTcall**, servi à `/EXTcall/` : la mise en relation avec un serveur Minitel externe (par websocket, telnet ou téléphone). Il sert aussi à VisuWeb pour visualiser les sessions en cours.

Elle est facultative : sans elle, la passerelle utilise les services publics de `www.minipavi.fr`. Elle ne contient pas vos propres services Minitel, qui ont leur propre hébergement.

## Construire et lancer

```bash
docker build -t accueil-extcall . -f accueil-extcall/Dockerfile

docker network create minipavi
docker run -d --name accueil-extcall --network minipavi accueil-extcall
```

Puis indiquer ces services à la passerelle, lancée sur le même réseau :

```bash
docker run -d --name minipavi --network minipavi -p 8181:8181 -p 8080:8080 \
  -e MINIPAVI_HTTP_PASSWORD=change-moi \
  -e MINIPAVI_VIEWER_URL=http://localhost:8081/ \
  -e MINIPAVI_DEFAULT_URL=http://accueil-extcall:8080/MiniPaviAcc/ \
  -e MINIPAVI_EXTCALL_URL=http://accueil-extcall:8080/EXTcall/ \
  minipavi
```

## Ports

| Port | Usage |
|---|---|
| `8080` | Les deux services. Seule la passerelle a besoin de le joindre : il n'est pas nécessaire de le publier |

## Variables

| Variable | Obligatoire | Valeur par défaut | Rôle |
|---|---|---|---|
| `MINIPAVI_CONNECT_KEY` | non | `Key1234` | Clé d'autorisation utilisée par EXTcall : la même que celle de la passerelle |

## Fichiers à adapter

Le contenu des deux services se règle dans deux fichiers du dépôt, livrés avec l'exemple de MiniPavi :

- `accueil-extcall/MiniPaviAcc/paviacc.conf.template` : l'annuaire, c'est-à-dire les services proposés à l'accueil, chacun avec son code, sa description et son adresse ;
- `accueil-extcall/EXTcall/extcall.conf.template` : les serveurs Minitel externes joignables. Ceux de type `tel` (appel téléphonique) demandent l'image [Asterisk](14-asterisk.md).

Après une modification, reconstruire l'image. Ces fichiers ne sont pas lisibles depuis le web.

## Vérifier

Un navigateur qui ouvre `/MiniPaviAcc/` ne voit pas le service lui-même : les services ne répondent qu'à la passerelle. Le bon contrôle est de se connecter avec l'émulateur : la page d'accueil « Passerelle MINIPAVI » doit s'afficher, avec son annuaire.
