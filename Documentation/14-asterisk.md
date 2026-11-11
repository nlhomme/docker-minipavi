# 14 - Asterisk

## Rôle

Cette image permet d'appeler la passerelle par téléphone avec un vrai Minitel, et à la passerelle d'appeler des serveurs Minitel par téléphone. Elle contient le serveur téléphonique Asterisk, compilé avec le modem logiciel V23 (`app_softmodemminipavi`) et la librairie spandsp fournis avec MiniPavi, en suivant le chapitre 9 de sa documentation.

## ⚠️ Non essayée avec une vraie ligne téléphonique

Ce qui est vérifié : l'image se construit, Asterisk démarre, le module est chargé, la configuration est lue, un appel simulé connecte bien le modem logiciel à la passerelle, et la passerelle peut s'identifier auprès d'Asterisk.

Ce qui reste à valider : l'enregistrement auprès d'un fournisseur SIP et un appel réel avec un Minitel.

## À prévoir

- **Une ligne SIP** chez un fournisseur de téléphonie (l'exemple de MiniPavi utilise OVH), avec un numéro.
- **Des ports UDP publiés directement sur le serveur** : `5060` (SIP) et `10000` à `10100` (voix), à ouvrir aussi dans le pare-feu. La téléphonie ne passe pas par un proxy web ni par un tunnel de type Cloudflare.
- **Un réseau Docker commun avec la passerelle** : chacun des deux doit pouvoir joindre l'autre par son nom de conteneur.
- **Une construction longue** : la compilation d'Asterisk prend plusieurs minutes. L'image pèse environ 320 Mo.

## Construire et lancer

```bash
docker build -t asterisk-minipavi . -f asterisk/Dockerfile

docker run -d --name asterisk --network minipavi \
  -p 5060:5060/udp -p 10000-10100:10000-10100/udp \
  -e SIP_SERVER=sip.exemple.org \
  -e SIP_USERNAME=0033123456789 \
  -e SIP_PASSWORD=mot-de-passe-sip \
  -e ASTERISK_EXTERNAL_ADDRESS=203.0.113.10 \
  -e MINIPAVI_HOST=minipavi \
  -e AMI_PASSWORD=mot-de-passe-ami \
  asterisk-minipavi
```

Côté passerelle, sur le même réseau, ajouter :

```bash
  -e MINIPAVI_AST_PORT=8183 \
  -e MINIPAVI_AMI_HOST=asterisk \
  -e MINIPAVI_AMI_PASSWORD=mot-de-passe-ami \
  -e MINIPAVI_SIP_CHANNEL='PJSIP/trunk/sip:%NUM%@sip.exemple.org' \
```

`MINIPAVI_AST_PORT` suffit pour les appels entrants ; les trois autres servent aux appels sortants. Voir [02 - Les liaisons entre images](02-liaisons.md).

## Ports

| Port | Usage |
|---|---|
| `5060/udp` | SIP : à publier |
| `10000-10100/udp` | Voix (RTP) : à publier. Modifiable avec `RTP_START` et `RTP_END` |
| `5038` | AMI : réservé à la passerelle. **À ne jamais publier** |

## Variables

| Variable | Obligatoire | Valeur par défaut | Rôle |
|---|---|---|---|
| `SIP_SERVER` | oui | | Serveur du fournisseur SIP, ex. `sip.exemple.org` |
| `SIP_USERNAME` | oui | | Identifiant de la ligne SIP (souvent le numéro, ex. `0033123456789`) |
| `SIP_PASSWORD` | oui | | Mot de passe de la ligne SIP |
| `ASTERISK_EXTERNAL_ADDRESS` | oui | | Adresse publique du serveur (IP ou nom), annoncée au fournisseur SIP |
| `MINIPAVI_HOST` | oui | | Nom du conteneur de la passerelle |
| `AMI_PASSWORD` | oui | | Mot de passe de l'AMI (le même que `MINIPAVI_AMI_PASSWORD` sur la passerelle) |
| `MINIPAVI_AST_PORT` | non | `8183` | Port de la passerelle pour Asterisk (le même que sur la passerelle) |
| `ASTERISK_LOCAL_NET` | non | `172.16.0.0/12` | Réseau local du conteneur (celui de Docker) |
| `AMI_USER` | non | `minipavi` | Utilisateur de l'AMI |
| `AMI_PERMIT` | non | `172.16.0.0/255.240.0.0` | Adresses autorisées à utiliser l'AMI (par défaut : les réseaux Docker) |
| `RTP_START`, `RTP_END` | non | `10000`, `10100` | Ports UDP de la voix |

La variable de build `ASTERISK_VERSION` (par défaut `22`) choisit la branche d'Asterisk compilée. MiniPavi est testé par son auteur avec les versions 20 et 22.

## Fichiers à adapter

Le dossier `asterisk/` contient les quatre fichiers de configuration, repris des exemples de MiniPavi :

- `pjsip.conf.template` : la ligne SIP ;
- `extensions.conf.template` : ce qu'Asterisk fait d'un appel entrant ou sortant ;
- `manager.conf.template` : l'AMI, par laquelle la passerelle demande un appel sortant ;
- `rtp.conf.template` : les ports de la voix.

Deux différences entre `pjsip.conf.template` et l'exemple de MiniPavi : la ligne s'appelle `trunk` (et non `ovh1`), et le mot de passe n'est plus écrit dans l'adresse `client_uri`, seulement dans la section d'authentification. Selon le fournisseur, ce fichier peut demander des ajustements.

## Vérifier

```bash
# Le module est chargé (état "Running")
docker exec asterisk asterisk -rx 'module show like minipavi'

# La ligne SIP est enregistrée auprès du fournisseur (état "Registered")
docker exec asterisk asterisk -rx 'pjsip show registrations'

# Le plan de numérotation désigne bien la passerelle
docker exec asterisk asterisk -rx 'dialplan show minipavi'
```

Côté passerelle, les logs indiquent `Port TCP Asterisk: 8183` et, pour les appels sortants, `Configuration AMI`.
