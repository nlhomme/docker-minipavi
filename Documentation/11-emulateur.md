# 11 - Émulateur

## Rôle

L'émulateur est une page web qui affiche un Minitel dans le navigateur et le connecte à la passerelle. C'est le moyen d'accès le plus simple : aucun matériel n'est nécessaire.

Deux présentations sont servies : la page classique (`/`) et une vue « vrai Minitel » (`/indexminitel.php`, ou `/?minitel`).

## Construire et lancer

```bash
docker build -t emulminitel . -f emulminitel/Dockerfile

docker run -d --name emulminitel -p 8081:8080 \
  -e GATEWAY_URL=ws://localhost:8181/ \
  emulminitel
```

## Ports

| Port | Usage |
|---|---|
| `8080` | La page web de l'émulateur |

## Variables

| Variable | Obligatoire | Valeur par défaut | Rôle |
|---|---|---|---|
| `GATEWAY_URL` | oui | | Adresse websocket publique de la passerelle, ex. `wss://passerelle.exemple.org:443/` |
| `WEBMEDIA_URL` | non | déduite de `GATEWAY_URL` | Adresse WebMedia de la passerelle, ex. `https://visuweb.exemple.org?action=webmedia` |

`GATEWAY_URL` commence par `ws://` ou `wss://` et ne contient ni espace ni guillemet. C'est le navigateur du visiteur qui s'y connecte : elle doit être joignable depuis l'extérieur.

Sans `WEBMEDIA_URL`, l'adresse WebMedia est déduite de `GATEWAY_URL` (`ws` devient `http`, `wss` devient `https`, suivie de `?action=webmedia`). Cette valeur n'est juste que si les ports websocket et VisuWeb de la passerelle sont joignables à la même adresse. Voir [12 - WebMedia](12-webmedia.md).

## Ce que fait le démarrage

Les fichiers de MiniPavi contiennent une adresse d'exemple (`mapasserelleminipavi.com`). Au démarrage, le conteneur la remplace par `GATEWAY_URL` et `WEBMEDIA_URL`. S'il reste une adresse d'exemple après ce remplacement, c'est qu'une nouvelle version de MiniPavi a changé ses fichiers : le conteneur s'arrête et le dit dans ses logs.

## Vérifier

Ouvrir la page : le Minitel s'affiche, et l'adresse de la passerelle est écrite sous l'écran. Si l'écran reste vide, vérifier que cette adresse est bien joignable depuis le navigateur.
