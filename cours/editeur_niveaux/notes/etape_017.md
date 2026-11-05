# Éditeur de niveaux · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Les textures de laurent sont peintes à la main, déjà vues par la caméra du jeu : une dalle carrée y
est un losange. Posée à plat comme les autres sprites, une telle image serait projetée une seconde fois, et le losange
deviendrait un losange écrasé. Une pièce « peinte en projection » se pose donc autrement : couchée sur le sol, mais
étirée et cisaillée pour que la caméra la voie exactement telle qu'elle est peinte. Sa rotation tourne l'image dans le
plan de l'écran, comme dans un logiciel de dessin.

Ce qu'on obtient : une pièce marquée `painted` dans le catalogue apparaît dans la vue rendue au pixel près comme sur la
planche ; le cadre bleu l'entoure, la tourne et l'agrandit dans l'écran ; sur la carte, son emprise est un
parallélogramme. Les pièces de laurent arrivent à l'étape suivante, avec l'import des planches.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5 : rien ne change pour les assets posés à plat.
3. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Une pièce peinte, en données

`1_core/data/asset_def.gd` gagne `painted` : l'image montre déjà le sol tel que la caméra le voit. Sa taille (`size_m`)
se mesure alors à l'écran, en mètres de la vue au zoom 1 ; sa rotation tourne l'image dans l'écran.

### 2. Ramener l'écran au sol

`FlatLayout.ground_from_screen` dit quel déplacement au sol la caméra montre comme un déplacement donné à l'écran. La
droite de l'écran est horizontale : un mètre d'écran vers la droite est un mètre de sol. Le bas de l'écran descend vers la
caméra : à 30°, un mètre d'écran y couvre 1 / sin(30°) = 2 mètres de sol. Le test
`test_un_deplacement_d_ecran_ramene_au_sol_se_revoit_tel_quel` le vérifie par la projection de la caméra
(`CameraTransform`) : le déplacement ramené au sol se revoit, en pixels, tel qu'on l'avait demandé.

### 3. Poser la pièce peinte

`FlatLayout.painted_basis` construit l'orientation du sprite à partir de ces deux axes : l'axe x de l'image va au sol
par la droite de l'écran (tournée de la rotation de la chose), son axe y par le haut de l'écran, la normale reste la
verticale. La base n'est plus orthonormée : Godot affiche sans peine un sprite cisaillé, et la caméra orthographique le
redresse. `Room3DView` s'en sert pour les pièces peintes, d'après la caméra du jeu (`game_camera`, ajoutée au contrat
`RoomRenderer`) ; sans caméra, la pièce se pose à plat.

### 4. L'emprise, et le dessin de la carte

`RoomView.corners_of` ne change qu'une ligne : chaque coin de l'image (en mètres, tourné) passe par `_ground_offset`, qui
le laisse tel quel pour une pièce à plat et le ramène de l'écran au sol pour une pièce peinte. La vue rendue y voit le
rectangle de l'image, la carte un parallélogramme. Le dessin de la carte suit : au lieu d'une rotation et d'une taille
en pixels, l'image se dessine en mètres depuis son ancre, menée à l'écran par une transformation affine que trois points
projetés suffisent à donner (`_image_to_screen`).

### 5. Ce que la caméra de Godot a trouvé

Le test `test_une_piece_peinte_se_voit_telle_qu_elle_est_peinte` compare trois choses : le rectangle attendu, l'emprise
calculée par la vue, et les coins du sprite vus par la `Camera3D` de Godot (`unproject_position`). Au premier essai,
Godot voyait le sprite 0,6 pixel plus haut que l'emprise, du même écart à chaque coin. La cause ne venait pas des pièces
peintes : un sprite est relevé de la hauteur de son calque (0,05 m par cran, pour l'ordre de dessin), et l'emprise était
calculée au sol. Vu à 30°, un relevé se voit à cos(30°) de sa hauteur. Le défaut datait de la vue rendue (étape 6) :
le cadre bleu d'une chose d'un calque haut tombait sous son image. L'emprise se pose maintenant à la hauteur du sprite
(`FlatLayout.height`) ; vue de dessus, la hauteur ne change rien.

Un second échec venait du test lui-même : le clic au centre de la dalle désignait une autre chose, posée plus haut au
même endroit. La dalle des tests va maintenant au calque le plus haut, devant les autres.

## Vérifier

- `7_tests/lancer_tests.bat` : tous les tests passent, sans fuite signalée à la fin ;
- les tests des pièces peintes : `7_tests/4_ui/editor/test_rendered_view.gd`, `7_tests/1_core/graphics/test_flat_layout.gd`.
