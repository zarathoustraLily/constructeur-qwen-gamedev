# Roguelike 002 · étape {STEP} · {TITLE}

**Piste : {TRACK}.** « Jouer » mène maintenant aux sauvegardes : quatre emplacements. Un emplacement libre lance tout
de suite une partie neuve. Un emplacement occupé montre sa salle et sa date, et ouvre ses actions : continuer,
effacer, retour. Effacer demande confirmation, et c'est « Non » qui a le focus : un appui de trop n'efface rien.
B revient d'un cran : de la confirmation aux actions, des actions à la liste, de la liste au menu.

Ce qu'on obtient : F5, « Jouer », puis les emplacements. Tant que le camp n'existe pas, une partie lancée ramène au
menu (`start_screen` dans la donnée : on le changera quand le camp sera là, sans toucher au code).

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. F5, puis « Jouer ».
3. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Un fichier JSON par emplacement, versionné

`SaveSystem` (`1_core/jeu/`) écrit `user://sauvegardes/emplacement_1.json`… (nom dans `SavesDef`, numéros à partir
de 1). Chaque fichier porte `version`, `graine`, `temps_s`, `salle`, `date`. À la lecture, `state_of(slot)` rend
`EMPTY`, `VALID`, `UNREADABLE` (pas du JSON, ou une clé manque) ou `OTHER_VERSION` : seul `VALID` se charge. La
lecture passe par `JSON.new().parse(...)`, qui rend un code d'erreur au lieu d'écrire une erreur dans la sortie.

### 2. L'écriture atomique

On n'écrit jamais directement sur la sauvegarde : on écrit `emplacement_1.json.tmp`, puis
`DirAccess.rename_absolute` le met à la place de l'ancien. Si le jeu s'arrête pendant l'écriture, seul le fichier
temporaire est abîmé ; la sauvegarde reste entière. Un test le vérifie en laissant un `.tmp` coupé au milieu.

### 3. La graine vient du hasard du jeu

Une partie neuve tire sa graine du générateur de la coquille (règle SIM-09) : `Main` donne `rng()` à tout écran qui
a une méthode `use_rng`. Le même générateur redonne les mêmes graines : un test le vérifie.

### 4. Un outil commun : `FocusChain`

L'étape 5 avait déclaré à la main les voisins de focus des lignes des options. Les sauvegardes en ont besoin deux fois
(emplacements, actions) : c'est le moment d'en faire un outil (`1_core/ui/focus_chain.gd`, `link_column`), et les
options l'utilisent aussi. Pas d'abstraction avant ce deuxième besoin.

### 5. Une faute vue par l'analyse stricte

Premier essai : « The local function parameter "rng" is shadowing an already-declared function ». Le paramètre de
`use_rng(rng)` portait le nom de la méthode `rng()`. Avec les avertissements en erreurs, le script ne se charge plus,
ni les tests qui en dépendent. Le paramètre s'appelle maintenant `generator`.

## Les tests

- `test_saves_screen.gd`, au clavier : quatre emplacements libres ; bas puis Entrée lance une partie neuve dans le
  deuxième, avec la graine attendue ; un occupé ouvre continuer, effacer, retour, et Continuer lance sa partie ;
  Effacer met « Non » en avant et Non revient aux actions ; Oui efface et revient à la liste ; Échap revient d'un cran
  jusqu'au menu ; un fichier illisible n'offre pas Continuer.
- `test_save_system.gd` : libre, numérotation, écriture et relecture, remplacement sans `.tmp` restant, `.tmp`
  abandonné sans dégât, illisible et autre version jamais chargés, effacement.
- `test_saves_def.gd` : la donnée, « Jouer » mène aux sauvegardes, quatre fautes refusées.
- `test_main.gd` : la coquille donne son hasard aux écrans qui en ont besoin.
