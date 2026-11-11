# 20 - Vérifier

Le script `test.sh` construit les images, les démarre avec des valeurs de test, puis contrôle que chacune fait son travail. Il affiche `OK` à la fin ; s'il s'arrête avant, la dernière ligne affichée indique l'image en cause.

```bash
./test.sh                    # les quatre images légères, avec la dernière release de MiniPavi
./test.sh 1.6.1              # avec une version précise
./test.sh latest asterisk    # en plus, l'image Asterisk (longue à construire)
```

Il ne demande que Docker. Il crée des conteneurs et un réseau dont le nom commence par `test-`, et les supprime en sortant. Les images `test-*` restent sur la machine.

## Ce qui est contrôlé

| Image | Contrôles |
|---|---|
| Passerelle | Elle reste démarrée, affiche sa version, ouvre ses ports, écrit correctement sa configuration (y compris un mot de passe avec des caractères spéciaux). La section Asterisk disparaît de la configuration quand elle n'est pas demandée |
| Émulateur | Ses deux pages servent l'adresse de passerelle donnée |
| WebMedia | La page est servie avec l'adresse donnée |
| Accueil et EXTcall | Les deux services répondent à une requête de passerelle. Leurs fichiers de configuration ne sont pas lisibles depuis le web |
| Toutes | Sans variable obligatoire, le conteneur refuse de démarrer |
| Asterisk | Le module est chargé, la configuration est lue, un appel simulé connecte le modem logiciel à la passerelle, la passerelle s'identifie sur l'AMI |

## Ce qui n'est pas contrôlé

- Une session complète dans un navigateur, de l'émulateur jusqu'à un service.
- L'envoi d'un contenu WebMedia.
- Un appel téléphonique réel et l'enregistrement auprès d'un fournisseur SIP.

## Quand le lancer

- Après une modification d'un Dockerfile, d'un script de démarrage ou d'un modèle de configuration.
- Avec le numéro d'une nouvelle release de MiniPavi, avant de la mettre en production : `./test.sh 1.7.0`.
