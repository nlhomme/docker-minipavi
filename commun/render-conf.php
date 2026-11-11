<?php
// Écrit un fichier de configuration XML à partir d'un modèle et des variables d'environnement.
// Usage : php render-conf.php <modèle> <fichier à écrire>
//
// Dans le modèle :
//   ${NOM}           variable obligatoire (le démarrage s'arrête si elle manque)
//   ${NOM:-valeur}   variable avec valeur par défaut
//   une ligne "SI NOM" et une ligne "FIN SI" en commentaires XML :
//                    les lignes entre les deux ne sont gardées que si la variable NOM est renseignée

function render_conf(string $template): string
{
    $set = fn ($name) => getenv($name) !== false && getenv($name) !== '';

    $text = preg_replace_callback(
        '/^[ \t]*<!--\s*SI (\w+)\s*-->\R(.*?)^[ \t]*<!--\s*FIN SI\s*-->\R?/ms',
        fn ($m) => $set($m[1]) ? $m[2] : '',
        file_get_contents($template)
    );

    return preg_replace_callback('/\$\{(\w+)(?::-([^}]*))?\}/', function ($m) use ($set) {
        if ($set($m[1])) {
            $value = getenv($m[1]);
        } elseif (isset($m[2])) {
            $value = $m[2];
        } else {
            fwrite(STDERR, "Variable d'environnement manquante : {$m[1]} (voir Documentation/)\n");
            exit(1);
        }
        return htmlspecialchars($value, ENT_XML1);
    }, $text);
}

if (isset($argv[0]) && realpath($argv[0]) === __FILE__) {
    if ($argc !== 3) {
        fwrite(STDERR, "Usage : php render-conf.php <modèle> <fichier à écrire>\n");
        exit(1);
    }
    file_put_contents($argv[2], render_conf($argv[1]));
}
