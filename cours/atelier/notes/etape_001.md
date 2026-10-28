# Atelier · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Le jeu commence par ses menus : un menu principal, des options de volume, et tout se
pilote à la manette comme au clavier.

Ce qu'on obtient : un menu Jouer / Options / Quitter, la croix ou le stick pour choisir, A pour valider ; dans
les options, deux curseurs (musique, effets) qui règlent vraiment les bus audio, et B pour revenir.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. F5. Croix ou stick : le focus passe d'un bouton à l'autre et boucle. A : valider. Dans les options, gauche
   et droite déplacent le curseur ; B ou Échap : retour.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat` (adapter le chemin de Godot dans le fichier), ou le
   panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Un service audio et ses bus

`0_autoload/audio_manager.gd` est le seul à toucher aux bus d'`AudioServer`. Au démarrage, il crée les bus
`Music` et `SFX` s'ils n'existent pas (`add_bus`, `set_bus_name`, `set_bus_send` vers `Master`). Un volume se
donne comme un curseur, de 0 à 1 : `set_volume` le borne, le convertit en décibels, coupe le bus à 0, et
annonce le changement par le signal `volume_changed`. `volume` relit la valeur.

### 2. Du curseur aux décibels

L'oreille entend en décibels : un curseur à moitié ne vaut pas la moitié du son, mais environ -6 dB.
`1_core/audio/volume.gd` fait la conversion dans les deux sens (`linear_to_db`, `db_to_linear`) avec un
plancher à -60 dB, en dessous duquel on considère le bus coupé. Il donne aussi le libellé « 75 % ».

### 3. Le focus, pour la manette

Une manette n'a pas de pointeur : elle déplace le **focus** d'un contrôle à l'autre. Chaque `Control` peut
nommer son voisin du dessus et du dessous (`focus_neighbor_top`, `focus_neighbor_bottom`, des chemins de
nœud). `4_ui/menus/menu_focus.gd` relie une liste de contrôles, avec ou sans boucle, et trouve le premier
contrôle qui peut prendre le focus : visible, `focus_mode` différent de `FOCUS_NONE`, et pas un bouton
désactivé. Sans focus de départ, la manette ne peut rien faire : un menu qui s'ouvre le donne tout de suite.

### 4. Le menu principal

`4_ui/menus/main_menu.tscn` : trois boutons dans un `VBoxContainer` centré. Le script ne décide rien : chaque
bouton émet une demande (`start_requested`, `options_requested`, `quit_requested`), et `open` montre le menu et
donne le focus au premier bouton utilisable. Les boutons A et B de la manette sont déclarés dans
`project.godot` pour `ui_accept` et `ui_cancel` : par défaut, ces actions n'ont que des touches.

### 5. Les options de volume

`4_ui/menus/options_menu.tscn` : un curseur `HSlider` par bus, de 0 à 1, au pas des réglages
(`5_data/ui/menu_settings.tres`). La croix ou le stick, à gauche et à droite, déplace le curseur du pas.
`show_volumes` place les curseurs sur les volumes actuels sans rien annoncer (`set_value_no_signal`) ; un
curseur déplacé par le joueur met son libellé à jour et émet `volume_changed`. Retour, B ou Échap
(`ui_cancel`, lu dans `_unhandled_input`) ferme le menu.

### 6. La scène principale relie tout

`2_sequence/main.gd` ouvre le menu principal, ouvre les options sur les volumes actuels, renvoie chaque
curseur au service audio, et revient au menu à la fermeture des options.
