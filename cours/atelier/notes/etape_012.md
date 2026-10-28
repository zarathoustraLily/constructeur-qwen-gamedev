# Atelier · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Ce que le joueur a réglé ne se perd plus en quittant le jeu, et une partie se sauvegarde
dans un format qui survit aux versions suivantes.

Ce qu'on obtient : les volumes et les boutons remappés enregistrés à chaque changement et repris au démarrage ; une
sauvegarde de partie en JSON, versionnée, qui migre une ancienne version et refuse un fichier abîmé.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. F5, changer un volume ou un bouton, quitter, relancer : le réglage est revenu. Le fichier est
   `user://reglages.cfg` (Projet > Ouvrir le dossier de données utilisateur).
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Les réglages dans un ConfigFile

`1_core/save/settings_store.gd` écrit un `ConfigFile` : un fichier texte par sections (`[audio]`, `[manette]`,
`[meta]` pour la version), qu'on peut lire et corriger à la main. `user://` est le dossier de données du joueur, le
seul où un jeu exporté a le droit d'écrire. Un fichier absent ou illisible (`load` qui ne rend pas `OK`) donne des
réglages vides : le jeu garde ses valeurs par défaut, sans planter. Un volume hors bornes est borné à la lecture.

### 2. Repris au démarrage, écrits à chaque changement

La scène principale relit les réglages au démarrage : volumes vers le service audio, boutons vers `InputMap`
(`ActionRemap.from_config`, étape 2). Elle se branche ensuite sur `volume_changed` et sur `rebound` pour réécrire
le fichier à chaque changement (`Callable.unbind`, parce que ces signaux portent des arguments dont elle n'a pas
besoin). Elle se branche après la relecture : relire ne réécrit rien.

### 3. Une sauvegarde de partie versionnée

`1_core/save/save_game.gd` écrit `{"version": 2, "state": …}` avec `JSON.stringify`. À la lecture
(`JSON.parse_string`), un texte qui n'est pas un dictionnaire, une version inconnue ou plus récente, un état qui
n'est pas un dictionnaire : tout est refusé (état vide) plutôt que de charger n'importe quoi. Une sauvegarde de la
version 1 est migrée (`hp` devient `health`) : les joueurs gardent leurs parties quand le format change.
