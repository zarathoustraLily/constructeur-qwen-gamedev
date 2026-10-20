# Kart · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Pas encore de kart : on prépare ce qui le pilotera. Le clavier et la manette
deviennent des commandes de conduite, qu'un panneau affiche à l'écran.

Ce qu'on obtient : un sol, un ciel, et en haut à gauche les jauges des gaz et de la direction, l'état du
frein et du saut, et le nom de la manette branchée. Le bouton A fait vibrer la manette.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. F5. Appuyer sur les gâchettes, pousser le stick gauche, ou taper W, S, A, D : les jauges bougent.
   Espace ou le bouton A : la manette vibre. Ctrl ou le bouton B : « Frein : oui ».
3. Les tests : double-cliquer `7_tests/lancer_tests.bat` (adapter le chemin de Godot dans le fichier), ou
   le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Des actions, pas des touches

Le code ne parle jamais d'une touche ni d'un bouton. Il parle d'**actions** : `move_forward`,
`move_backward`, `move_left`, `move_right`, `move_jump`, `move_brake`. Chacune est déclarée dans
`project.godot`, section `[input]` (dans l'éditeur : Projet > Paramètres du projet > Contrôles), avec la
liste de ce qui la déclenche :

- une touche du clavier, par sa **position** (`physical_keycode`) : W est la touche du haut à gauche
  sur un clavier QWERTY, et la même touche s'appelle Z sur un clavier AZERTY ;
- un axe de la manette (`InputEventJoypadMotion`) : stick gauche, gâchettes ;
- un bouton de la manette (`InputEventJoypadButton`) : la croix directionnelle, A, B.

Changer une commande, c'est changer cette liste ; aucun script ne bouge.

### 2. Les gâchettes et le stick donnent une valeur, pas un oui ou un non

Une touche est enfoncée ou non. Une gâchette, elle, peut être enfoncée à moitié. Godot donne à chaque
action une **force** entre 0 et 1 : `Input.get_action_strength()`. Ici, la gâchette droite
(`JOY_AXIS_TRIGGER_RIGHT`, l'axe 5) déclenche `move_forward`, et la gauche (`JOY_AXIS_TRIGGER_LEFT`,
l'axe 4) `move_backward`. Une gâchette à moitié, c'est donc des gaz à moitié.

### 3. La zone morte

Un stick au repos ne revient jamais exactement au centre : il donne 0,03, puis −0,02… Sans précaution,
le kart tournerait tout seul. Chaque action a une **zone morte** (`"deadzone": 0.2`) : en dessous, la
force compte pour zéro.

`Input.get_vector()` lit quatre actions d'un coup et rend un vecteur : `x` pour la direction, `y` pour les
gaz. Il traite la zone morte comme un cercle autour du centre, puis remet la course restante à l'échelle :
juste après la zone morte on repart de 0, et le bout de la course vaut toujours 1. Une gâchette enfoncée
à moitié (0,5) donne donc `inverse_lerp(0.2, 1.0, 0.5)`, soit 0,375. Le test
`test_une_gachette_a_moitie_donne_des_gaz_remis_a_l_echelle_de_la_zone_morte` le vérifie.

### 4. Une seule porte d'entrée : l'adaptateur

Un seul script lit `Input` : `3_entities/kart/kart_input.gd` (classe `KartInput`). Sa fonction `read()`
remplit un objet `DriveCommands` (`1_core/input/drive_commands.gd`) : `throttle`, `steering`, `brake`,
`jump`, `jump_held`, `jump_released`. C'est la règle ARC-04 du projet : les entrées sont des intentions, et
la logique consomme des commandes.

Le gain se verra dès l'étape suivante. Le kart ne saura pas d'où viennent ses commandes : le clavier, la
manette, ou un test qui les écrit lui-même. Le freinage en est un premier exemple : « frein » vaut vrai
avec la touche de frein, mais aussi avec l'avant et l'arrière enfoncés ensemble, et c'est l'adaptateur qui
le décide.

### 5. Le saut : enfoncé, tenu, relâché

`Input.is_action_just_pressed()` ne vaut vrai que pendant une image, celle où l'on vient d'appuyer :
c'est le saut (`jump`). `is_action_pressed()` vaut vrai tant qu'on tient (`jump_held`), et
`is_action_just_released()` à l'image où l'on lâche (`jump_released`). Le kart s'en servira pour sauter,
puis pour déraper tant que la touche est tenue.

### 6. La vibration

`Input.start_joy_vibration(manette, faible, fort, durée)` fait vibrer une manette : deux moteurs, l'un
léger et rapide, l'autre lourd et lent, chacun de 0 à 1. `KartInput.vibrate()` fait vibrer toutes les
manettes branchées ; sans manette, il ne fait rien.

Les valeurs ne sont pas dans le script. Elles sont dans une ressource, `5_data/input/jump_rumble.tres`, de
type `Rumble` (`1_core/input/rumble.gd`) : c'est la règle DAT-01 (aucun chiffre de réglage dans un script)
et DAT-02 (chaque famille de données a sa classe `Resource`, avec `class_name`, dans `1_core`). Pour
changer la vibration, on ouvre le `.tres` dans l'inspecteur.

### 7. L'affichage ne connaît pas le kart

`4_ui/hud/input_display/` montre des `DriveCommands`, sans savoir d'où elles viennent : l'interface n'a
pas le droit de connaître les acteurs (`3_entities`). C'est la scène principale (`2_sequence/main.gd`) qui
fait le lien : à chaque image physique, elle lit les commandes, les donne à l'affichage, et fait vibrer la
manette quand le saut vient d'être demandé.

## Les tests

Ils sont dans `7_tests/`, au même chemin que ce qu'ils vérifient :

- `3_entities/kart/test_kart_input.gd` : chaque commande existe au clavier et à la manette ; les gâchettes
  donnent les gaz ; la zone morte et la remise à l'échelle ; le frein ; le saut enfoncé, tenu, relâché ;
- `4_ui/hud/input_display/test_input_display.gd` : les jauges, le frein et le saut, les manettes ;
- `2_sequence/test_main.gd` : la scène montre ce que l'adaptateur a lu ;
- `1_core/test_documentation.gd` : chaque script et chaque membre public a son commentaire `##`.

Un test n'a pas besoin de manette : `Input.action_press("move_forward", 0.5)` enfonce l'action à moitié,
exactement comme une gâchette.

## Ce qu'il faut retenir

- Des actions dans la carte des entrées, jamais des touches dans le code.
- `get_vector()` pour deux axes (direction, gaz), `get_action_strength()` pour une seule valeur
  analogique, `is_action_just_pressed()` pour un appui.
- La zone morte coupe le bruit du stick, et `get_vector()` remet la course restante à l'échelle.
- Un seul script lit `Input` ; le reste du jeu reçoit des commandes.
- Les chiffres de réglage vivent dans `5_data`.

## À essayer

- Passer la zone morte de `move_left` et `move_right` à 0,5 (Paramètres du projet > Contrôles), puis
  pousser doucement le stick : la direction ne bouge plus avant mi-course.
- Mettre `strong_magnitude` à 0 dans `jump_rumble.tres` : la vibration devient légère.
- Brancher une deuxième manette : les deux noms s'affichent, et un saut les fait vibrer toutes les deux.

## Source

- Documentation de Godot 4.7, *Controllers, gamepads, and joysticks*
  (`tutorials/inputs/controllers_gamepads_joysticks.rst`, dépôt godot-docs, révision `9adca4c`) : les trois
  façons de lire une entrée analogique (`get_vector()`, `get_action_strength()`, `is_action_pressed()`) et
  la vibration (`start_joy_vibration`, `stop_joy_vibration`). La page conseille de laisser le joueur
  couper la vibration ou en baisser la force.
- Référence des classes `Input` et `InputMap` (API de Godot 4.7.2) : signatures de `get_vector`,
  `start_joy_vibration`, `action_get_deadzone`.

## Étape suivante

Étape 002 : le kart. Il reçoit ces commandes et roule : roues, suspension, accélération, direction,
frein, saut.
