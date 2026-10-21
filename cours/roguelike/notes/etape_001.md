# Roguelike · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Pas encore de héros : on prépare ce qui le pilotera. Le clavier, la souris et la
manette deviennent des commandes de joueur, qu'un panneau affiche à l'écran.

Ce qu'on obtient : un sol, un personnage provisoire (une capsule bleue) et, à ses pieds, une flèche orange
qui montre la visée. En haut à gauche : les jauges de la marche, l'angle de la visée, le nombre de coups et
d'esquives demandés, l'appareil en cours et le nom de la manette branchée. Un coup fait vibrer la manette.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. F5. Bouger la souris : la flèche suit le pointeur. Taper W, A, S, D : les jauges bougent. Clic gauche :
   « Coups » augmente ; Espace : « Esquives ».
3. À la manette : pousser le stick droit, la flèche le suit ; le lâcher, elle suit le stick gauche (la
   marche). Le bouton X (ou la gâchette droite) frappe et fait vibrer ; le bouton A (ou la gâchette gauche)
   esquive. Toucher la souris rend la main à la souris.
4. Les tests : double-cliquer `7_tests/lancer_tests.bat` (adapter le chemin de Godot dans le fichier), ou
   le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Des actions, pas des touches

Le code ne parle jamais d'une touche ni d'un bouton. Il parle d'**actions** : `move_forward`, `move_back`,
`move_left`, `move_right` pour marcher, `aim_left`, `aim_right`, `aim_up`, `aim_down` pour viser, `attack`
et `dash`. Chacune est déclarée dans `project.godot`, section `[input]` (dans l'éditeur : Projet >
Paramètres du projet > Contrôles), avec la liste de ce qui la déclenche :

- une touche du clavier, par sa **position** (`physical_keycode`) : W est la touche du haut à gauche sur un
  clavier QWERTY, et la même touche s'appelle Z sur un clavier AZERTY ;
- un bouton de la souris (`InputEventMouseButton`) : le clic gauche pour `attack` ;
- un axe de la manette (`InputEventJoypadMotion`) : stick gauche (axes 0 et 1), stick droit (axes 2 et 3),
  gâchettes (axes 4 et 5) ;
- un bouton de la manette (`InputEventJoypadButton`) : la croix directionnelle, A, X.

Le jeu d'origine n'avait que le clavier et la souris, et son action de coup s'appelait `click`. Elle
s'appelle maintenant `attack` : c'est une intention, que la souris et la manette déclenchent toutes deux.

### 2. Le stick donne une valeur, et la zone morte coupe le bruit

Une touche est enfoncée ou non ; un stick peut être poussé à moitié. Au repos, il ne revient jamais
exactement au centre : il donne 0,06, puis −0,02… Chaque action a une **zone morte** (`"deadzone": 0.2`) :
en dessous, la force compte pour zéro.

`Input.get_vector()` lit quatre actions d'un coup et rend un vecteur. Il traite la zone morte comme un
cercle autour du centre, puis remet la course restante à l'échelle : juste après la zone morte on repart de
0, et le bout de la course vaut 1. Un stick poussé à moitié (0,5) donne donc `inverse_lerp(0.2, 1.0, 0.5)`,
soit 0,375. Le test `test_un_stick_a_moitie_donne_une_marche_remise_a_l_echelle_de_la_zone_morte` le
vérifie.

Les vecteurs sont ceux de l'écran : `x` vers la droite, `y` vers le bas. « En avant », c'est vers le haut
de l'écran : `y` vaut −1.

### 3. Une seule porte d'entrée : l'adaptateur

Un seul script lit `Input` : `3_entities/player/player_input.gd` (classe `PlayerInput`). Sa fonction
`read()` remplit un objet `PlayerCommands` (`1_core/input/player_commands.gd`) : `move`, `aim`, `attack`,
`dash`, `from_pad`. C'est la règle ARC-04 du projet : les entrées sont des intentions, et la logique
consomme des commandes.

Dans le jeu d'origine, la machine à états du joueur recevait les événements d'entrée et chaque état les
lisait (`handle_input`). Ici, aucun état ne lira jamais une touche : le joueur, à l'étape suivante, recevra
des commandes, qu'elles viennent du clavier, de la manette ou d'un test.

`attack` et `dash` passent par `Input.is_action_just_pressed()` : vrai pendant une seule image, celle où
l'on vient d'appuyer.

### 4. Viser à la souris ou au stick

La documentation de Godot prévient : quand une même action se joue à la souris et à la manette, il faut
deux chemins dans le code. C'est le cas de la visée.

- **À la souris**, on vise du personnage vers le pointeur. `Camera3D.unproject_position()` donne le point
  de l'écran où se trouve le personnage ; la visée est l'écart entre le pointeur et ce point
  (`aim_from_mouse`).
- **À la manette**, la visée est le stick droit. Lâché, il ne vise rien (`aim` nul) : le joueur frappera
  alors vers où il marche.

Qui décide ? Le **dernier appareil touché**. L'adaptateur écoute chaque événement (`_input`) : un bouton
de manette, ou un stick poussé au-delà de `PAD_MOTION_THRESHOLD` (0,5), fait passer la visée à la manette ;
la souris ou le clavier la rendent à la souris. Un stick à peine touché ne change rien : sans ce seuil, le
bruit d'une manette posée sur la table volerait la visée à la souris.

Tant que la souris n'a pas bougé sur la fenêtre, elle ne vise pas : la visée reste nulle et le joueur frappera
vers où il marche. Sans cette règle, une fenêtre ouverte hors de l'écran (les rendus de vérification du cours)
viserait vers le pointeur posé ailleurs sur le bureau, et deux parties identiques ne viseraient pas pareil.
Seul compte un vrai déplacement (`relative` non nul) : au démarrage, Godot envoie à la fenêtre un mouvement de
souris sans déplacement, et une fenêtre hors de l'écran lit quand même un pointeur au milieu de son image.

### 5. Tourner selon la caméra

La caméra regarde le personnage en biais, tournée autour de la verticale (son angle vient du jeu d'origine).
Pour que « droite » sur l'écran soit « droite » au sol, la scène tourne la direction de l'écran du même
angle que la caméra : `Vector3(aim.x, 0, aim.y).rotated(Vector3.UP, camera.global_rotation.y)`. La flèche
pointe dans cette direction (`look_at`).

### 6. La vibration

`Input.start_joy_vibration(manette, faible, fort, durée)` fait vibrer une manette : deux moteurs, l'un
léger et rapide, l'autre lourd et lent, chacun de 0 à 1. `PlayerInput.vibrate()` fait vibrer toutes les
manettes branchées ; sans manette, il ne fait rien.

Les valeurs ne sont pas dans le script. Elles sont dans une ressource, `5_data/input/attack_rumble.tres`,
de type `Rumble` (`1_core/input/rumble.gd`) : c'est la règle DAT-01 (aucun chiffre de réglage dans un
script) et DAT-02 (chaque famille de données a sa classe `Resource`, avec `class_name`, dans `1_core`).

### 7. L'affichage ne connaît pas le joueur

`4_ui/hud/input_display/` montre des `PlayerCommands`, sans savoir d'où elles viennent : l'interface n'a
pas le droit de connaître les acteurs (`3_entities`). C'est la scène principale (`2_sequence/main.gd`) qui
fait le lien : à chaque image physique, elle lit les commandes, les donne à l'affichage, oriente la flèche
et fait vibrer la manette quand un coup vient d'être demandé.

## Les tests

Ils sont dans `7_tests/`, au même chemin que ce qu'ils vérifient :

- `3_entities/player/test_player_input.gd` : chaque commande existe au clavier ou à la souris, et à la
  manette ; la zone morte et la remise à l'échelle ; le coup et l'esquive à l'image de l'appui ; la visée à
  la souris ; le passage à la manette par un bouton, le retour à la souris, le stick à peine touché ;
- `4_ui/hud/input_display/test_input_display.gd` : les jauges, l'angle de visée, les compteurs,
  l'appareil et les manettes ;
- `2_sequence/test_main.gd` : la scène montre ce que l'adaptateur a lu ; sans visée, la flèche suit la
  marche, tournée comme la caméra ;
- `1_core/test_documentation.gd` : chaque script et chaque membre public a son commentaire `##`.

Un test n'a pas besoin de manette : `Input.action_press("move_right", 0.5)` pousse l'action à moitié,
comme un stick, et `Input.parse_input_event()` envoie un événement de manette ou de souris inventé.

## Ce qu'il faut retenir

- Des actions dans la carte des entrées, jamais des touches dans le code.
- `get_vector()` pour deux axes, `is_action_just_pressed()` pour un appui.
- La zone morte coupe le bruit du stick, et `get_vector()` remet la course restante à l'échelle.
- Un seul script lit `Input` ; le reste du jeu reçoit des commandes.
- Souris et manette visent par deux chemins ; le dernier appareil touché décide.

## À essayer

- Passer `PAD_MOTION_THRESHOLD` à 0 dans `player_input.gd`, poser la manette et bouger la souris : le
  moindre frémissement du stick reprend la visée.
- Mettre `strong_magnitude` à 1 dans `attack_rumble.tres` : la vibration du coup devient lourde.
- Ajouter le bouton RB (`JOY_BUTTON_RIGHT_SHOULDER`, numéro 10) à l'action `attack` dans les Contrôles : il
  frappe aussi, sans toucher au code.

## Source

- Le jeu d'origine : le roguelike du cours GameDev.tv (« GDTV-Roguelike »), rangé selon le plan du dépôt ;
  angle de la caméra et noms des actions de marche repris tels quels.
- Documentation de Godot 4.7, *Controllers, gamepads, and joysticks*
  (`tutorials/inputs/controllers_gamepads_joysticks.rst`, dépôt godot-docs, révision `9adca4c`) :
  `get_vector()`, la zone morte, et l'avertissement sur la souris et la manette, qui demandent deux chemins
  dans le code pour une même action.
- Références des classes `Input`, `InputMap` et `Camera3D` (API de Godot 4.7.2) : `get_vector`,
  `is_action_just_pressed`, `start_joy_vibration`, `action_get_deadzone`, `unproject_position`.

## Étape suivante

Étape 002 : le joueur. Il reçoit ces commandes et marche, tourné vers sa course ; une machine à états
sépare la course de la chute.
