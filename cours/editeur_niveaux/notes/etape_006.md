# Éditeur de niveaux · étape {STEP} · {TITLE}

**Piste : {TRACK}.** La salle apparaît enfin, et telle que le jeu la montrera : chaque chose est un sprite posé à plat sur
le sol, filmé par la caméra du jeu, orthographique et inclinée de 30°. On édite dans cette vue, texture par texture : une
vue de dessus ne montre pas ce que verra le joueur (les dalles y sont carrées, alors qu'en jeu la profondeur est écrasée de
moitié). Elle reste utile autrement : en petit, dans un coin, c'est la carte de navigation.

Ce qu'on obtient : F5 ouvre le hangar dans la vue rendue, comme le jeu : au zoom du jeu, centré sur le départ du héros
(un roguelike se joue près du héros, pas en vue d'ensemble) ; la molette zoome autour du curseur, le bouton du milieu
déplace la vue ; en bas, la carte montre toute la salle vue de dessus et, en blanc, ce que filme la vue rendue ; un
clic sur la carte y centre la vue. La barre d'état dit « Le hangar : 203 choses ».

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5 : le hangar vu par la caméra du jeu ; la carte en bas à gauche.
3. `5_data/camera/camera.tres` : l'inclinaison (30°), la hauteur de salle montrée, la distance.
4. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. La caméra du jeu, en données

`1_core/data/camera_def.gd` décrit la caméra que le jeu et l'éditeur partagent : orthographique (les tailles ne
rétrécissent pas avec la distance), inclinée de `pitch_deg` = 30° au-dessus du sol, et la hauteur montrée au zoom 1
(sa taille orthographique) : 9 m, soit 18 m de sol en profondeur autour du héros. Le premier jet montrait 20 m et
ouvrait la salle entière : une vue de stratégie, pas celle d'un roguelike. L'éditeur s'ouvre maintenant comme le jeu
(`show_like_game`), et la salle entière se voit sur la carte. À 30°, une profondeur au sol se voit à sin(30°) = 0,5 de sa longueur, une hauteur à
cos(30°) ≈ 0,866 : c'est la perspective précise que doivent suivre les textures peintes.

### 2. La projection, en calcul pur, et la caméra de Godot au même pixel

`1_core/editor/camera_transform.gd` calcule la projection sans nœud : un point écarté du point regardé (`focus`) de
`(dx, dy, dz)` s'affiche à `(dx, dz × sin 30° − dy × cos 30°)`, en pixels par mètre. On en tire le chemin inverse (le
point du sol sous la souris), le zoom autour du curseur, le déplacement et le cadrage. `apply_to` règle la vraie
`Camera3D` d'après la même projection : orthographique, `size` = la hauteur montrée, tournée de −30° autour de x, en
recul du point regardé. Le test `test_le_calcul_et_godot_tombent_au_meme_pixel` le vérifie : pour plusieurs points,
`Camera3D.unproject_position` et le calcul tombent au même pixel. Tout le reste de l'éditeur s'appuie sur le calcul, que
l'on sait juste.

### 3. Un contrat commun aux deux vues

La carte vue de dessus (`ViewTransform`) et la vue rendue (`CameraTransform`) remplissent le même contrat,
`1_core/editor/view_projection.gd` : de la salle à l'écran et retour, déplacer, zoomer, cadrer, et le signal `changed`.
La souris, la sélection et les calques ne parlent qu'à ce contrat. L'emprise d'une chose (`RoomView.corners_of`) se
calcule donc **dans la salle**, en mètres, tournée autour de son ancre, puis se projette : la même emprise sert à la carte
et à la vue rendue. Le contrat déclare `changed` et l'émet par `notify_changed()` : un signal déclaré mais jamais émis par
sa classe est un avertissement, donc une erreur ici.

### 4. Les sprites à plat, le code du jeu

`3_entities/room/room_3d_view.gd` construit la salle comme le jeu la montrera : une chose = un `Sprite3D` qui affiche la
région de son asset dans la planche (`region_rect`), à sa couleur, sans éclairage, et couché sur le sol.
`1_core/graphics/flat_layout.gd` en fait le calcul :
- la taille d'un pixel (`pixel_size`) donne à l'image sa largeur en jeu ; la profondeur est ajustée à part ;
- un décalage (`offset`) pose le point d'ancrage de l'image sur la position de la chose ;
- l'orientation couche le quad (−90° autour de x), puis le tourne de la rotation de la chose autour de la verticale, dans
  le même sens que sur la carte ;
- l'ordre de dessin devient une hauteur : chaque calque monte d'un cran, chaque rang d'un cran plus fin. Vu par la caméra
  inclinée, le plus haut passe devant. Les crans sont trop fins pour se voir (une fraction de pixel).
Une chose inactive est cachée en jeu, et montrée en transparence par l'éditeur.

### 5. La vue rendue, et ce qu'elle a le droit de connaître

`4_ui/editor/rendered_view.gd` hérite de la vue de dessus et ne change que la projection et le dessin : elle a sa propre
`SubViewport` (son monde 3D, sa caméra), où vit la salle en 3D, et dessine l'image de cette fenêtre. La règle des dossiers
interdit à l'interface (`4_ui`) de connaître les entités du jeu (`3_entities`) : la vue ne parle qu'à un contrat de
`1_core`, `RoomRenderer`, que la salle du jeu remplit ; c'est la coquille (`2_sequence`, qui connaît tout) qui la lui
donne (`set_renderer`). De même, le cœur ne connaît pas les dossiers de données : le dossier des salles vient de la
coquille, plus d'une constante du magasin.

### 6. La carte de navigation

La vue de dessus de l'étape précédente devient la carte : en petit, en bas à gauche, elle montre toute la salle et, en
blanc, le contour au sol de ce que filme la vue rendue (`MapInput.footprint` : les quatre coins de la vue ramenés au
sol). Un clic ou un glisser sur la carte centre la vue rendue sur le point visé.

### 7. Ce que le juge des règles a trouvé

Le juge des règles d'architecture a relevé, en plus, des conteneurs sans type (`Dictionary` et `Array` nus, règle COD-02),
dans ce qu'on venait d'écrire et dans des étapes plus anciennes : un aperçu, des dictionnaires de champs. Ils sont
maintenant typés (`Dictionary[StringName, Variant]`, `Array[int]`), ou parcourus en `Variant` quand ils viennent de Godot
sans type (`get_property_list()`). La recherche de la palette range ses entrées en tableaux parallèles typés.

## Vérifier

- `7_tests/lancer_tests.bat` : tous les tests passent, sans fuite signalée à la fin ;
- F5 : le hangar vu à 30°, ses dalles bord à bord ; la molette, le bouton du milieu ; un clic sur la carte recentre.
