<?php
// Contrôle de santé de la passerelle : elle doit répondre sur son port VisuWeb/WebMedia (8080).
// La requête est une interrogation WebMedia avec un code Pin inexistant : elle ne demande pas de
// mot de passe, ne compte pas comme une connexion de Minitel et ne laisse rien dans les logs.
// Code de sortie : 0 si la passerelle répond, 1 sinon.

$socket = @fsockopen('127.0.0.1', 8080, $errno, $error, 3);
if (!$socket) {
    exit(1);
}
stream_set_timeout($socket, 3);
// La requête doit être complète : la passerelle lit les en-têtes jusqu'à la ligne vide
fwrite($socket, "GET /?action=webmedia&pin=0000 HTTP/1.1\r\n\r\n");
exit(str_starts_with((string) fgets($socket), 'HTTP/') ? 0 : 1);
