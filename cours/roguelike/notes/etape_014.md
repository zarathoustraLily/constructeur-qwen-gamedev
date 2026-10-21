# Roguelike · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Le jeu se met en pause, au clavier comme à la manette, et le joueur choisit ses touches et
ses boutons. Les choix sont sauvegardés et reviennent au lancement suivant.

Ce qu'on obtient : le jeu complet. Trois niveaux tirés au sort, une boutique entre chaque, une pause, et des
commandes à son goût.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5, puis Échap (ou Start à la manette) : le jeu se fige, le menu de pause s'ouvre, le focus sur « Reprendre ».
3. « Commandes » : une ligne par action, avec ses liaisons au clavier et à la souris, puis à la manette.
   Choisir « Espace » sur la ligne « Esquiver », appuyer sur K : l'esquive passe sur K, la manette garde A et LT.
4. B ou Échap revient en arrière ; relancer le jeu : K esquive toujours.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Deux actions de plus : pause, et retour

`project.godot` déclare l'action `pause` (Échap, Start). Il redéfinit aussi `ui_cancel` : dans Godot 4.7.2, elle
n'a que Échap (lu dans l'`InputMap` d'un projet lancé), et le projet y ajoute B. L'étape 13 avait déjà ajouté A à
`ui_accept`. La croix et le stick gauche déplacent le focus sans rien ajouter : `ui_up`, `ui_down`, `ui_left` et
`ui_right` les ont déjà.

### 2. Les liaisons : une règle, en données

`1_core/input/input_bindings.gd` (`InputBindings`) dit tout ce qu'on peut faire d'une liaison, sans lire aucune
entrée : on lui donne des événements.

- **Par appareil.** Le clavier et la souris d'un côté, la manette de l'autre. Lier une entrée à une action
  remplace celles du même appareil et garde celles de l'autre : changer la touche de l'esquive ne touche pas au
  bouton A.
- **Ce qui se lie.** Une touche appuyée, par sa place sur le clavier (`physical_keycode` : la même touche sur un
  AZERTY et sur un QWERTY) ; un bouton de souris ou de manette appuyé ; un stick ou une gâchette poussé au-delà de
  0,6, avec son sens. Un relâchement, une répétition, un petit mouvement ne lient rien. La liaison vaut pour
  toutes les manettes (appareil -1, comme les actions de `project.godot`) : un `InputEventJoypadButton.new()` a
  l'appareil 0, la première manette seule.
- **La sauvegarde.** Un `ConfigFile` avec un numéro de version, et des codes lisibles (« physical 87 », « axis 3
  - ») : jamais d'objets dans un fichier que le joueur peut modifier. Une sauvegarde d'une autre version est
  ignorée. « Par défaut » revient aux liaisons de `project.godot` (`InputMap.load_from_project_settings()`) et
  efface la sauvegarde.

`1_core/input/binding_settings.gd` (`BindingSettings`) et `5_data/input/bindings.tres` disent quelles actions on
peut lier, dans quel ordre, sous quel nom, et où sauvegarder. La visée au stick droit n'y est pas : à la souris,
elle suit le pointeur.

### 3. Au démarrage, les liaisons sauvegardées

La scène de démarrage (`2_sequence/boot.gd`) remet les liaisons sauvegardées avant de donner la séquence à
GameFlow : le premier niveau part avec les touches choisies.

### 4. Le menu des contrôles

`4_ui/overlays/input_remap/` : une ligne par action (`BindingRow`, deux boutons qui montrent les liaisons), et le
menu (`InputRemapMenu`). Choisir un bouton attend la nouvelle entrée de cet appareil. Pendant l'attente, le menu
garde toutes les entrées pour lui (`set_input_as_handled`) : le clic ou le bouton suivant ne presse rien d'autre.
La pause (Échap, Start) annule l'attente : elle ne se lie donc jamais, et on ne peut pas perdre le moyen d'ouvrir
le menu. Une entrée déjà liée à une autre action est signalée (« aussi lié à : Haut »). Chaque liaison est
sauvegardée tout de suite.

Les noms montrés (`binding_names.gd`) : une touche liée par sa place prend le nom qu'elle porte sur le clavier du
joueur. Sur la machine de laurent (AZERTY), les places W, A, S, D s'affichent Z, Q, S, D (rendu du menu). Sans
fenêtre, Godot ne connaît aucune disposition de clavier : `DisplayServer.keyboard_get_layout_count()` vaut 0, et
`keyboard_get_keycode_from_physical()` lève « Not supported by this display server » ; le menu montre alors le nom
de la place sur un QWERTY. Les deux ont été lancés dans Godot 4.7.2, avec et sans fenêtre.

L'interface ne connaît pas les données (règle des dossiers : `4_ui` connaît `0_autoload`, `1_core`, `6_assets`).
Le menu ne charge donc pas `bindings.tres` : il reçoit ses réglages (`setup()`), du menu de pause, qui les reçoit
du niveau.

### 5. Le menu de pause

`4_ui/overlays/pause_menu/` (`PauseMenu`, un `CanvasLayer` au-dessus du jeu). La pause fige l'arbre
(`SceneTree.paused`) ; le menu tourne quand même (`process_mode` ALWAYS, posé dans la scène), et ses enfants
avec lui. Le héros, les ennemis et les minuteurs s'arrêtent. Les boutons : « Reprendre », « Commandes », « Quitter
le jeu ». Le modèle de niveau en porte un : les trois niveaux l'ont.

Qui reçoit une entrée en premier ? Godot appelle `_input` des enfants avant celui du parent (lancé dans Godot
4.7.2). Le menu des contrôles, enfant du menu de pause, voit donc chaque entrée d'abord et garde celles dont il se
sert : pendant une attente, Start annule l'attente sans fermer la pause.

Un bouton presse au relâchement (lancé : `pressed` est émis au relâchement d'Entrée). L'appui qui ouvre l'attente
est donc fini quand elle commence : il ne se lie pas lui-même.

### 6. Un stick qu'on vient de lier

Pousser un stick vers le bas enfonce aussi `ui_down`. L'interface ne suit un stick que quand `Input` voit son
action s'enfoncer à cette image (`is_action_just_pressed`) : lancé dans un test, un mouvement poussé directement
dans l'interface ne déplace pas le focus, le même passé par `Input` le déplace. À l'image où on lie le stick, la
suite du mouvement descendrait donc d'une ligne. Le menu ignore cet axe jusqu'à ce qu'il revienne au repos (sous
0,3).

## Les tests

- `1_core/input/test_input_bindings.gd` : l'appareil de chaque entrée ; une liaison ne naît que d'un appui, ou
  d'un axe poussé au-delà du seuil avec son sens, et vaut pour toutes les manettes ; lier garde l'autre appareil ;
  la sauvegarde rend les liaisons des actions demandées, seulement elles ; une sauvegarde absente, ou d'une autre
  version, ne change rien ; « par défaut » efface la sauvegarde ; chaque code redonne son entrée ;
- `4_ui/overlays/input_remap/test_binding_names.gd` : touches, souris, boutons et axes de la manette ;
- `4_ui/overlays/input_remap/test_input_remap_menu.gd`, avec de vrais événements poussés dans l'interface : une
  ligne par action et le focus ; une touche se lie, garde la manette, se sauvegarde ; à la manette, la croix,
  puis A, puis un bouton ; un stick lié ne déplace pas le focus à la même image (mouvements passés par `Input`) ;
  la pause annule l'attente ; une entrée déjà prise est signalée ; « Par défaut » ; B ferme le menu, sauf pendant
  l'attente, où il se lie ;
- `4_ui/overlays/pause_menu/test_pause_menu.gd` : Start et Échap ouvrent et ferment, B et « Reprendre »
  referment ; « Commandes », puis B revient à la pause ; Start pendant une attente ; le menu tourne pendant la
  pause, un nœud du jeu non ; sans réglages des liaisons, le menu le dit ;
- `2_sequence/test_boot.gd` : la scène de démarrage porte les réglages et remet les liaisons sauvegardées ;
- `2_sequence/levels/test_levels.gd` : chaque niveau a son menu de pause, avec les réglages des liaisons.

Les tests écrivent leurs sauvegardes dans des fichiers à eux (`user://test_*.cfg`), jamais dans celle du joueur,
et remettent l'`InputMap` du projet après chaque test.

## Ce qu'il faut retenir

- Les entrées d'un menu sont des actions : `pause`, `ui_accept`, `ui_cancel`. Par défaut, `ui_accept` et
  `ui_cancel` n'ont aucun bouton de manette.
- Une liaison se fait par appareil, par la place de la touche, pour toutes les manettes.
- On sauvegarde des codes et un numéro de version, pas des objets.
- `_input` va de l'enfant au parent ; `set_input_as_handled()` arrête l'entrée.
- La pause fige l'arbre ; ce qui doit tourner pendant la pause le dit (`process_mode`).
- Un test d'interface pousse de vrais événements ; pour un stick, ils passent par `Input`.

## À essayer

- Ajouter « aim_up » (« Viser en haut ») à `bindings.tres` : une ligne de plus, la manette seule.
- Lier « Esquiver » à W : le menu prévient qu'elle sert aussi à « Haut ».
- Passer `process_mode` du menu de pause à « Inherit » : la pause s'ouvre, puis plus rien ne répond.

## Source

- Le jeu d'origine (« GDTV-Roguelike », cours GameDev.tv) n'a ni pause ni menu des contrôles (aucun fichier de
  pause ni de remappage dans la source) ; ils suivent le cours du kart de ce dépôt (étape 14), découpés ici en
  règles (`1_core`), données (`5_data`) et interface (`4_ui`).
- Documentation de Godot 4.7, *Pausing games and process mode* (`tutorials/scripting/pausing_games.rst`) ;
  *Using InputEvent* (`tutorials/inputs/inputevent.rst`) ; *Keyboard/Controller Navigation and Focus*
  (`tutorials/ui/gui_navigation.rst`) ; *File paths in Godot projects* (`tutorials/io/data_paths.rst`).
- Références des classes `InputMap`, `InputEventKey` (`physical_keycode`), `InputEventJoypadMotion`, `ConfigFile`,
  `DisplayServer` (`keyboard_get_layout_count`, `keyboard_get_keycode_from_physical`), `Viewport`
  (`push_input`, `set_input_as_handled`), `Input` (`parse_input_event`, `flush_buffered_events`), `SceneTree`
  (`paused`) : API de Godot 4.7.2.

## Fin du cours

Les quatorze étapes ont construit le roguelike entier : les commandes, le héros et sa machine à états,
l'animation, le niveau, l'esquive, le combat, deux familles d'ennemis, le retour des coups, la vague, trois
niveaux éclairés, le chef d'orchestre, la boutique, la pause et les commandes à son goût.
