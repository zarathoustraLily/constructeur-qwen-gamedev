# Roguelike 002 · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Le menu principal est le premier écran où le joueur reste : il doit vivre. Le titre tombe à sa
place et rebondit à peine, les choix arrivent l'un après l'autre par la droite, le fond étoilé glisse lentement, la
planète flotte. On ne peut rien choisir pendant cette entrée ; ensuite « Jouer » a le focus, la croix, le stick ou les
flèches passent d'un choix à l'autre, et le choix mis en avant grandit et s'écarte. « Options » et « Jouer » ne mènent
encore nulle part : ils tremblent. « Quitter » ferme le jeu.

Ce qu'on obtient : F5 montre le studio, l'avertissement, puis ce menu.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. F5 : le studio, l'avertissement, le menu.
3. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Le mouvement est une fonction du temps

On aurait pu lancer des `Tween` qui déplacent les nœuds. Mais leur état vit dans les tweens : un test ne peut pas dire
« où est le titre à 0,7 s ? » sans attendre de vraies images. Ici, la vue (`MenuView`) calcule chaque position à
partir du temps écoulé et de l'âge de chaque événement, que l'écran lui donne :
- arrivée : `Tween.interpolate_value(depart, ecart, t, duree, Tween.TRANS_BACK, Tween.EASE_OUT)` pour le titre (un
  petit rebond), `TRANS_CUBIC` pour les choix ; chaque choix commence `item_stagger_s` après le précédent ;
- fond : `-pingpong(t * vitesse, course)` : il glisse puis revient, sans saut ;
- planète : `sin(t / periode * TAU) * amplitude` ;
- mise en avant : agrandissement de 1 à `focus_scale` autour du centre (`pivot_offset_ratio`) et décalage, sur
  `focus_s` ;
- tremblement d'un choix indisponible : un sinus qui s'amortit sur `refuse_s`.

Le même temps redonne la même image : les tests vérifient le mouvement image par image, sans attendre.

### 2. Toutes les valeurs sont dans la donnée

`MenuDef` (`5_data/jeu/menu.tres`) porte le titre, les choix, leurs textes, l'écran où mène chacun, la mise en page
et chaque durée, distance et amplitude du mouvement. `intro_s()` calcule la fin de l'entrée (le dernier arrivé). Les
scripts n'écrivent aucun nombre que 0 et 1 : même le centre de l'agrandissement (0,5 ; 0,5) est une donnée.
La vue lit `MenuDef` (une classe de `1_core`), jamais le fichier `menu.tres` (dans `5_data`) : c'est l'écran qui le
lui donne.

### 3. Des boutons pour la manette

Les choix sont des `Button` : Godot les parcourt lui-même avec `ui_up` et `ui_down` (flèches, croix, stick), et un
bouton émet `pressed` au relâchement de `ui_accept` (A, Entrée). Pendant l'entrée, leur `focus_mode` est
`FOCUS_NONE` : impossible de choisir avant la fin ; ensuite le premier prend le focus (`grab_focus`).

### 4. Chaque écran charge le suivant

L'avertissement charge maintenant le menu en fond (il ne part qu'une fois ce chargement fini), et le studio ne charge
plus que l'avertissement. Pourquoi pas tout au studio ? Une ressource chargée n'est gardée que tant que quelqu'un la
tient : quand l'écran du studio part, ses images du menu partent avec lui. L'écran juste avant le menu, lui, est
encore là quand la coquille ouvre le menu.

### 5. Un défaut vu à l'image

La première capture a montré la planète posée sur la fin du titre. La correction est dans la donnée seule
(`planet_rect_px`), et la capture suivante le confirme.

## Les tests

- `test_menu_screen.gd` : le titre tombe à sa place ; les choix arrivent l'un après l'autre, à l'écart prévu ; rien
  ne se choisit pendant l'entrée ; après, le focus est sur « Jouer » ; la flèche du bas met « Options » en avant, qui
  grandit ; un choix indisponible tremble puis revient ; « Quitter » le demande ; un choix qui mène quelque part fait
  partir l'écran ; le fond glisse puis revient ; dans le jeu, Entrée sur « Jouer » le fait trembler.
- `test_menu_def.gd` : la donnée du jeu est juste ; la durée d'entrée ; quatre fautes refusées.
- `test_disclaimer_screen.gd` : on ne passe pas l'avertissement avant que le menu soit chargé.
