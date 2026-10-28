# Atelier · étape {STEP} · {TITLE}

**Piste : {TRACK}.** La manette devient un vrai contrôleur : un stick qui ne dérive pas, des vibrations à la
mesure des chocs, et des boutons que le joueur choisit lui-même.

Ce qu'on obtient : un bouton « Commandes » dans le menu principal ; dans ce menu, une ligne par action (Sauter,
Attaquer, Esquiver) avec son bouton ; A sur une ligne, puis n'importe quel bouton de la manette : il devient celui
de l'action, et si une autre action l'avait, elles échangent.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. F5, puis Commandes. A sur une ligne : « Appuyez sur un bouton… » ; un bouton de la manette le remplace. B
   annule l'écoute ; B encore ferme le menu.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Les actions de jeu

`project.godot` déclare les actions `move_left`, `move_right`, `move_up`, `move_down` (touches W A S D par leur
position, stick gauche, croix), `move_jump` (Espace, A), `move_attack` (K, X) et `move_dash` (Maj, RB). Le code
ne parle que d'actions : changer une commande, c'est changer cette liste ou la remapper en jeu.

### 2. Une zone morte ronde

Un stick au repos ne revient jamais tout à fait au centre : sans zone morte, le personnage dériverait.
`1_core/input/stick_filter.gd` met le stick à zéro sous un rayon (`radial`), puis remet la course restante à
l'échelle de 0 à 1 (`inverse_lerp`) : une légère poussée donne une petite valeur, au lieu de sauter d'un coup à
0,2. Une zone ronde ne favorise aucune direction, contrairement à une zone par axe. Les gâchettes ont la leur
(`trigger`). `from_actions` lit le stick sur quatre actions avec `Input.get_vector`, sans la zone morte des
actions (0), pour que la zone se règle à un seul endroit : `5_data/input/gamepad_settings.tres`.

### 3. Des vibrations à la mesure des chocs

Une manette a deux moteurs : le petit vibre finement, le gros lourdement. `1_core/input/rumble.gd` donne au petit
une part de la force de chaque choc, ne fait tourner le gros qu'au-delà d'un seuil, et allonge la vibration avec
la force (`lerpf` entre deux durées). `play` appelle `Input.start_joy_vibration(appareil, faible, fort, durée)`,
sauf si les vibrations sont coupées dans les réglages.

### 4. Remapper un bouton

`1_core/input/action_remap.gd` lit les boutons de manette d'une action (`InputMap.action_get_events`, filtrés sur
`InputEventJoypadButton`), les remplace par un autre (`action_erase_event`, puis `action_add_event`, appareil -1
pour toutes les manettes) sans toucher aux touches, repère les actions qui emploient déjà un bouton, donne le nom
court d'un bouton (A, B, LB…), et écrit ou relit les boutons dans un dictionnaire, pour la sauvegarde à venir.

### 5. Le menu des commandes

`4_ui/menus/remap_menu.gd` construit une ligne par action remappable. A sur une ligne la met en écoute ; dans
`_input`, le prochain `InputEventJoypadButton` pressé devient le bouton de l'action. Si une autre action l'avait,
elle reçoit l'ancien bouton : aucune action ne reste sans bouton. `ui_cancel` (B) annule l'écoute, puis ferme le
menu. `set_input_as_handled` empêche le même appui d'agir aussi ailleurs.

### 6. Le menu principal gagne « Commandes »

Un quatrième bouton dans `main_menu.tscn`, un signal `controls_requested`, et la scène principale ouvre et ferme
le menu des commandes comme celui des options.
