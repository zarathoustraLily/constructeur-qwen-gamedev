# Éditeur de niveaux · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Les gestes de l'éditeur, sans encore de souris : déplacer, tourner, mettre à l'échelle, dupliquer,
supprimer, changer de calque, avancer ou reculer en profondeur, poser un asset. Le cadre bleu (étape 7) et les
raccourcis (étape 8) ne feront qu'appeler ces gestes ; on les écrit et on les teste d'abord ici, où un test les
vérifie sans fenêtre.

Ce qu'on obtient : `1_core/editor/editor_actions.gd`, des réglages d'éditeur dans `5_data/editeur/reglages.tres`
(grille, pas de rotation, bornes de l'échelle, décalage d'un double), et un document qui ajoute plusieurs choses d'un
coup.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. `5_data/editeur/reglages.tres` : les réglages, modifiables dans l'Inspecteur.
3. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Un geste, un pas d'annulation

Déplacer trois choses sélectionnées doit s'annuler en un seul Ctrl+Z. Chaque geste calcule donc les nouvelles valeurs
de **toutes** les choses concernées, puis les donne d'un coup à `RoomDocument.apply` : un seul pas, ou rien si une
seule valeur est refusée. Le test `_steps_to_undo` compte les pas après chaque geste.

Le premier jet de « poser un asset » en faisait deux : ajouter la chose, puis la passer devant les autres de son
calque. Un Ctrl+Z aurait laissé la chose posée, au mauvais rang. On calcule maintenant le rang avant d'ajouter
(`_extreme_sort`), et on ajoute la chose avec ce rang : un seul pas.

### 2. Ajouter plusieurs choses d'un coup

Dupliquer une sélection ajoute plusieurs choses : avec `add_thing` une par une, ce serait autant de pas. Le document
gagne `add_things(list)`, qui les ajoute toutes dans une seule copie validée ; `add_thing` devient un raccourci vers
lui. On factorise maintenant, parce que le besoin est apparu, pas avant.

### 3. Un groupe tourne et grandit autour de son centre

Comme dans un logiciel de dessin, tourner un groupe le fait tourner **autour de son centre** : chaque chose tourne sur
elle-même, et sa position tourne aussi autour du centre du groupe (`Vector2.rotated`, dans le plan x, z). La rotation
reste dans [0, 360[ grâce à `fposmod` : 350° + 20° donnent 10°. De même, agrandir un groupe écarte les positions du
centre, en plus de l'échelle de chaque chose, que les réglages bornent (`min_scale`, `max_scale`).

### 4. L'aimant

Avec l'aimant, une position se cale sur la grille (`snappedf`, au pas `snap_m`), une rotation sur le pas de rotation.
Les pas viennent des réglages : on ne les écrit pas dans le code.

### 5. La profondeur

Dans un calque, le rang (`sort`) décide qui se dessine par-dessus. `shift_depth` avance ou recule d'un rang ;
`to_extreme_depth` passe devant (ou derrière) toutes les autres choses du calque. C'est la profondeur que le cadre bleu
réglera au clavier.

### 6. Dupliquer sans casser les attaches

Une lampe attachée à une caisse : si l'on duplique les deux, le double de la lampe doit s'attacher au double de la
caisse, pas à l'originale. `duplicate` connaît les identifiants que recevront les doubles (le suivant du plus grand,
dans l'ordre) et remplace chaque parent dupliqué par son double.

## Vérifier

- `7_tests/lancer_tests.bat` : tous les tests passent, sans fuite signalée à la fin.
