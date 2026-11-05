# Éditeur de niveaux · étape {STEP} · {TITLE}

**Piste : {TRACK}.** La salle apparaît enfin : une vue de dessus qui dessine chaque chose depuis la planche du
catalogue, à sa place, à sa taille, tournée, dans le bon ordre. On la parcourt à la souris. Rien ne se modifie encore à
la souris : la vue montre, c'est tout ; le cadre bleu viendra à l'étape suivante.

Ce qu'on obtient : F5 ouvre le hangar, cadré au milieu de la fenêtre ; la molette zoome autour du curseur, le bouton du
milieu déplace la vue ; la barre d'état dit « Le hangar : 203 choses ».

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5 : le hangar, ses dalles, ses détails, ses obstacles et son avant-plan.
3. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Des mètres aux pixels

`1_core/editor/view_transform.gd` fait le passage entre la salle (en mètres, dans le plan x, z : la vue regarde d'en
haut) et l'écran (en pixels). Un mètre fait `pixels_per_meter × zoom` pixels ; `origin` est l'endroit de l'écran où
tombe le point (0, 0) de la salle. `world_to_screen` et `screen_to_world` vont dans les deux sens ; les tests vérifient
qu'un aller-retour retombe sur le même point. Le pixel par mètre et les bornes du zoom viennent des réglages.

Le zoom à la molette garde immobile **le point sous le curseur** : on retient le point de la salle sous le curseur,
on change le zoom, puis on recalcule `origin` pour que ce point retombe sous le curseur. Sans cela, la salle fuirait
vers un coin à chaque cran. `frame` cadre une salle entière au milieu de la vue, au plus grand zoom qui la montre.

### 2. L'ordre de dessin

`1_core/editor/draw_order.gd` trie les choses par calque (dans l'ordre des calques : sol, détails, obstacles,
avant-plan), puis par rang, puis par identifiant. Le dernier critère paraît inutile ; il ne l'est pas : sans lui, deux
choses de même rang se dessineraient dans l'ordre des tableaux, qui change après une suppression, et la vue
clignoterait d'un ordre à l'autre. Le tri passe par des clés `Vector3i` (calque, rang, identifiant), que Godot compare
dans cet ordre. Le jeu dessinera la salle avec la même règle.

### 3. La vue dessine, une autre partie écoute

`4_ui/editor/room_view.gd` dessine dans `_draw()` : pour chaque chose, `draw_set_transform_matrix` place l'origine sur
sa position et la tourne de sa rotation, puis `draw_texture_rect_region` dessine la région de la planche dans
l'emprise de la chose (la taille de son asset, en mètres, fois son échelle, convertie en pixels), décalée de son
ancre. Une chose inactive est dessinée en transparence ; un asset sans image, en magenta : on voit ce qui manque au
lieu de ne rien voir. La vue redessine (`queue_redraw`) quand le document ou le cadrage change, jamais à chaque image.

Elle ne dessine que les choses dont l'emprise touche la vue (`visible_ids`) : au zoom fort, sur une grande salle, la
plupart sont hors champ. La vue ne lit aucune entrée : `4_ui/editor/room_view_input.gd` écoute son signal `gui_input`,
reçoit les événements de souris qui la visent, et les traduit en commandes de cadrage (`pan`, `zoom_at`). C'est la
règle du projet : un script `_input` traduit les appareils en commandes ; les autres ne les connaissent pas. Ses tests
lui envoient des événements fabriqués (`InputEventMouseButton`, `InputEventMouseMotion`).

### 4. La coquille ouvre la salle de départ

`editor_shell.gd` reçoit, par la scène, la salle de départ, le catalogue et les réglages (`@export`). Au démarrage, il
ouvre la salle par `RoomStore`, la vérifie face au catalogue (`room_errors`) et la confie au document ; en cas d'échec,
la barre d'état dit pourquoi et rien n'est ouvert. Le cadrage attend que la vue ait une taille : le conteneur ne la
lui donne qu'après le premier passage de mise en page. La coquille cadre donc à chaque changement de taille de la vue
(signal `resized`).

### 5. Un défaut qui ne se voit qu'à l'image

Tous les tests passaient, mais la première image du hangar montrait un quadrillage de joints vides entre les dalles
du sol, comme si elles étaient posées avec un espace. Le code de la vue n'y était pour rien : les dalles sont bien
posées bord à bord (4 m de côté, tous les 4 m). La cause était dans la planche : chaque image y était dessinée avec une
marge transparente de 8 pixels dans sa case, et la région de l'asset couvrait la case entière, marge comprise. Pour un
obstacle, la marge ne gêne pas ; pour une dalle qui doit se raccorder à sa voisine, si. Le générateur de la planche
dessine maintenant les dalles de sol sans marge. On corrige ce qui a produit le défaut, pas l'image.

## Vérifier

- `7_tests/lancer_tests.bat` : tous les tests passent, sans fuite signalée à la fin ;
- F5 : le hangar s'affiche entier, les dalles du sol bord à bord ; la molette zoome autour du curseur ; le bouton du
  milieu déplace la vue.
