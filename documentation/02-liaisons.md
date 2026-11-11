# 02 - Les liaisons entre images

Les images ne se connaissent pas : c'est par des variables d'environnement que chacune apprend où sont les autres. Cet article réunit ces variables, qui vont par paires.

## Deux sortes d'adresses

- **Les adresses publiques** sont utilisées par le navigateur du visiteur. Elles doivent être joignables depuis Internet (ou depuis `localhost` pour un essai).
- **Les adresses internes** sont utilisées d'un conteneur à l'autre. Sur un même réseau Docker, un conteneur se joint par son nom : `http://accueil-extcall:8080/`.

```bash
# Un réseau commun, puis --network et --name sur chaque conteneur
docker network create minipavi
docker run -d --name minipavi --network minipavi ... minipavi
docker run -d --name accueil-extcall --network minipavi ... accueil-extcall
```

## Adresses publiques

| Variable | Sur l'image | Doit désigner |
|---|---|---|
| `GATEWAY_URL` | Émulateur | Le port websocket de la passerelle (8181), ex. `wss://passerelle.exemple.org:443/` |
| `MINIPAVI_VIEWER_URL` | Passerelle | L'émulateur, ex. `https://minitel.exemple.org:443/` |
| `WEBMEDIA_URL` | WebMedia, Émulateur | Le port VisuWeb de la passerelle (8080), suivi de `?action=webmedia`, ex. `https://visuweb.exemple.org?action=webmedia` |

`WEBMEDIA_URL` désigne le port **VisuWeb** de la passerelle, pas son port websocket. Sur l'émulateur elle est facultative : sans elle, l'adresse est déduite de `GATEWAY_URL` (`ws` devient `http`, `wss` devient `https`), ce qui n'est juste que si les deux ports de la passerelle sont joignables à la même adresse.

## Adresses internes

| Variable | Sur l'image | Doit désigner |
|---|---|---|
| `MINIPAVI_DEFAULT_URL` | Passerelle | Le service affiché à la connexion, ex. `http://accueil-extcall:8080/MiniPaviAcc/` |
| `MINIPAVI_EXTCALL_URL` | Passerelle | Le service EXTcall, ex. `http://accueil-extcall:8080/EXTcall/` |
| `MINIPAVI_HOST` | Asterisk | Le conteneur de la passerelle, ex. `minipavi` |
| `MINIPAVI_AMI_HOST` | Passerelle | Le conteneur Asterisk, ex. `asterisk` |

Sans `MINIPAVI_DEFAULT_URL` ni `MINIPAVI_EXTCALL_URL`, la passerelle utilise les services publics de `www.minipavi.fr`.

## Valeurs qui doivent être identiques

| Valeur | Passerelle | Autre image |
|---|---|---|
| Clé d'autorisation des connexions vers l'extérieur | `MINIPAVI_CONNECT_KEY` | `MINIPAVI_CONNECT_KEY` sur Accueil et EXTcall |
| Port des connexions venant d'Asterisk | `MINIPAVI_AST_PORT` | `MINIPAVI_AST_PORT` sur Asterisk |
| Utilisateur de l'AMI | `MINIPAVI_AMI_USER` | `AMI_USER` sur Asterisk |
| Mot de passe de l'AMI | `MINIPAVI_AMI_PASSWORD` | `AMI_PASSWORD` sur Asterisk |
| Serveur SIP | dans `MINIPAVI_SIP_CHANNEL` | `SIP_SERVER` sur Asterisk |

`MINIPAVI_SIP_CHANNEL` s'écrit `PJSIP/trunk/sip:%NUM%@` suivi de la valeur de `SIP_SERVER`. `trunk` est le nom de la ligne SIP dans `asterisk/pjsip.conf.template`.

## Vue d'ensemble

```
 Navigateur ──► Émulateur          (page web)
     │
     ├─ websocket ──► Passerelle ──► Accueil et EXTcall   (services, en HTTP)
     │                   ▲  │
     └─ WebMedia ────────┘  └──────► autres services Minitel (en HTTP)
                         ▲  │
 Minitel ─ téléphone ─► Asterisk    (modem vers la passerelle, AMI depuis la passerelle)
```
