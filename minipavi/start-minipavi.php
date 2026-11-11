<?php
// Démarrage de la passerelle : écrit minipavi.conf à partir de minipavi.conf.template
// et des variables d'environnement (voir render-conf.php), puis lance MiniPavi.

require __DIR__ . '/render-conf.php';

file_put_contents(__DIR__ . '/minipavi.conf', render_conf(__DIR__ . '/minipavi.conf.template'));

echo 'MiniPavi version ' . trim(file_get_contents(__DIR__ . '/VERSION')) . "\n";

// Remplace ce processus par MiniPavi (qui reçoit ainsi directement les signaux d'arrêt)
pcntl_exec(PHP_BINARY, [__DIR__ . '/minipavi.php', '--cfgfile', 'minipavi.conf']);
fwrite(STDERR, "Impossible de lancer minipavi.php\n");
exit(1);
