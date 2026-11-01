# Fluides · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Le raymarching coûte des centaines de lectures par pixel : aucun jeu ne le paie pour une petite explosion. On simule donc une seule fois, on photographie, et on ne garde que les images. En jeu, il reste une lecture de texture.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. Lancer le projet : la scène principale est maintenant `2_sequence/flipbook_puff.tscn`. La cuisson est dans `1_core/gpu/flipbook_baker.gd`, le rangement dans `1_core/fluid/flipbook.gd`.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Photographier un volume

`project_volume.glsl` regarde le volume de face : pour chaque colonne de cases, il additionne la fumée, et la loi de Beer-Lambert donne une opacité. Ce shader lit un `image3D` et écrit un `image2D` : rien n'oblige une passe à garder le nombre d'axes.

Attention au sens. Dans un volume, y monte. Dans une image, les lignes descendent. Sans le `size.y - 1 - cell.y`, la fumée tombe. `test_le_haut_de_l_image_est_le_haut_du_volume` le garde.

### 2. Sur l'appareil local

La cuisson a besoin de relire chaque image : c'est le travail de l'appareil local. Le `device.release()` qui suit la cuisson rend toute la mémoire du volume : la simulation ne coûte plus rien en jeu.

`Image.create_from_data` en `FORMAT_RF` reçoit les octets de `texture_get_data` tels quels : une texture `R32_SFLOAT` et une image `RF` ont le même rangement. `blit_rect` les pose sur la planche. Pour le jeu, `convert(Image.FORMAT_L8)` ramène chaque pixel à un octet : une planche de 128 × 192 passe de 98 Ko à 25 Ko.

### 3. Ranger la planche

Les images vont de gauche à droite, puis de haut en bas. `Flipbook.cell` le dit en deux divisions : `%` donne la colonne, la division la ligne. `floori(float(index) / columns)` et non `index / columns` : le projet traite la division entière comme une erreur.

### 4. Mélanger deux images

Seize images pour deux secondes, cela fait huit images par seconde : à l'écran, on les voit se suivre. `frame` est un flottant. Sa partie entière choisit l'image, sa partie fractionnaire la mêle à la suivante. Le coût : deux lectures au lieu d'une.

La suivante de la dernière image est la première : `mod(first + 1.0, …)` ferme la boucle. `test_apres_la_derniere_image_on_revient_a_la_premiere` lit les deux bouts de la planche.

### 5. Un plan tourné vers la caméra

`vertex()` remplace les trois axes du plan par ceux de la caméra (`MAIN_CAM_INV_VIEW_MATRIX`) et garde sa position (`MODEL_MATRIX[3]`) : c'est le billboard, et c'est le même calcul que `StandardMaterial3D` en mode billboard.

Le filtre de la texture lit aussi les cases voisines : au bord d'une image, on verrait l'image d'à côté. La fumée doit donc rester loin des bords de son volume.

## Ce qu'il faut retenir

Cuire, c'est échanger de la mémoire contre du calcul. Une image n'est plus une simulation : elle ne réagit plus à rien, mais elle tient sur n'importe quelle carte.
