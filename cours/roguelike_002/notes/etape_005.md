# Roguelike 002 · étape {STEP} · {TITLE}

**Piste : {TRACK}.** « Options » mène maintenant quelque part : un écran d'une ligne par réglage. Haut et bas passent
d'une ligne à l'autre, gauche et droite changent la valeur, A la change aussi, B revient au menu. Chaque changement
s'applique tout de suite (on entend la musique baisser pendant qu'on règle son volume), et tout est enregistré en
revenant. Au lancement suivant, le jeu rouvre avec ces réglages.

Ce qu'on obtient : F5, puis Options dans le menu : difficulté, définition, plein écran, trois volumes, Retour.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. F5, puis « Options ».
3. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Les options sont une donnée

`OptionsDef` (`5_data/jeu/options.tres`) liste les difficultés, les définitions, les bus audio réglables, les valeurs
par défaut, le pas du volume, le fichier (`user://options.cfg`) et chaque texte de l'écran. `rows()` donne les
lignes dans l'ordre.

### 2. Les réglages du joueur, enregistrés et relus sans planter

`GameSettings` (`1_core/jeu/`) enregistre dans un `ConfigFile` (texte lisible, sections `jeu`, `ecran`, `son`) et
relit en corrigeant : une difficulté inconnue, une définition absente de la liste ou un volume hors de [0, 1] (venus
d'un vieux fichier ou d'une main) reprennent leur valeur par défaut ; un fichier absent donne les valeurs par défaut.

### 3. Appliquer : bus audio et fenêtre

`SettingsApplier` règle le volume de chaque bus (`AudioServer.set_bus_volume_linear`), puis la fenêtre
(`DisplayServer.window_set_mode`, `window_set_size`). Les bus « Musique » et « Effets » existent parce que
`project.godot` désigne `6_assets/jeu/audio/bus_layout.tres` (`[audio] buses/default_bus_layout`). Sans fenêtre
(`DisplayServer.get_name() == "headless"`), on ne touche pas à l'écran. La coquille (`Main`) applique les réglages
enregistrés dès l'ouverture du jeu.

### 4. Gauche et droite sont à l'écran, pas à l'interface

Godot se sert de `ui_left` et `ui_right` pour déplacer le focus de côté. `OptionsInput` les prend dans `_input`,
appelé avant l'interface, et marque l'événement traité (`set_input_as_handled`) : ils changent la valeur au lieu de
bouger le focus.

### 5. Chaque ligne nomme ses voisines

Les lignes sont des boutons dans un `VBoxContainer`. Le premier essai a montré que la flèche du bas ne bougeait pas le
focus : le conteneur ne place ses enfants qu'à l'image suivante, et Godot cherchait la ligne « du dessous » parmi des
boutons tous en (0, 0). `OptionsView` déclare donc les voisins (`focus_neighbor_bottom`, `focus_neighbor_top`, la
dernière ligne menant à la première) : la navigation ne dépend plus de la place à l'écran.

## Les tests

- `test_options_screen.gd`, piloté au clavier et à la manette : la difficulté tourne dans les deux sens ; bas puis
  droite change la définition ; Entrée sur le plein écran le bascule ; le volume monte d'un cran, s'entend
  (`AudioServer`) et s'arrête à 1 ; B enregistre et ramène au menu une seule fois ; à la réouverture, l'écran montre
  ce qui a été enregistré.
- `test_game_settings.gd` : défauts, aller-retour par le fichier, fichier absent, valeurs écrites à la main corrigées.
- `test_settings_applier.gd` : les bus existent ; leur volume change ; un bus inconnu est ignoré.
- `test_options_def.gd`, `test_menu_def.gd`, `test_main.gd` : la donnée, « Options » mène à l'écran, les réglages
  enregistrés s'appliquent à l'ouverture.
- Chaque test écrit dans son propre fichier `user://test_…` et l'efface après lui.
