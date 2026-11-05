# Éditeur de niveaux · étape {STEP} · {TITLE}

**Piste : {TRACK}.** laurent peint ses textures à la main sur une grande toile à fond transparent : des éléments de
toutes tailles, séparés par du vide, qui se marient ensuite dans la salle. Garder la toile telle quelle coûterait en
mémoire vidéo chaque pixel transparent. L'import la découpe : il trouve chaque pièce, la rogne au plus juste, range les
pièces dans des pages d'atlas compressées, et les ajoute au catalogue comme pièces peintes en projection (étape 17).

Ce qu'on obtient : « Importer une planche… », en haut, prend un PNG ; ses pièces apparaissent dans la palette, et la
barre d'état dit ce qu'on y gagne. Sur la planche de laurent (`6_assets/planches_peintes/sol_01.png`, 2000 × 2000) :
« Planche sol_01.png : 11 pièces ; pages d'atlas : 1 ; mémoire vidéo 1.01 MiB au lieu de 15.25 MiB ». « Sol verrouillé », décoché,
laisse prendre à la souris les pièces du sol.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5, puis « Importer une planche… » : choisir `6_assets/planches_peintes/sol_01.png`.
3. Décocher « Sol verrouillé », double-cliquer une pièce `sol_01_…` dans la palette, et la manipuler par son cadre bleu.
4. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Une planche hors de l'import de Godot

Godot importe toute image du projet. Une planche n'est pas une texture du jeu, c'est une source : son dossier porte un
fichier `.gdignore`, et l'import la lit comme un fichier (`Image.load_from_file`), pas comme une ressource. Une planche
sans transparence est refusée : un fond plein ferait une seule pièce de toute la toile.

### 2. Trouver les pièces, par plages

`1_core/editor/sheet_importer.gd` parcourt l'image en RGBA8 (l'alpha d'un pixel est son quatrième octet) et note, sur
chaque ligne, les plages de pixels non transparents. Deux plages de lignes voisines qui se touchent, même par un coin,
sont du même îlot : un union-find les réunit. Chaque pièce (`SheetPiece`) garde son cadre, rogné au plus juste, et ses
plages. Sur les 4 millions de pixels de la planche de laurent, le parcours entier, pages comprises, prend 194 ms.

Les plages comptent : le cadre d'un losange déborde sur ses voisins. Le test
`test_une_piece_n_emporte_pas_les_pixels_de_sa_voisine` pose un carré dans le cadre d'un L, sans le toucher : dans la
page, le L n'emporte que ses propres plages, pas les pixels du carré.

### 3. Regrouper ? Pas par défaut

Les six tirets de la planche sont six pièces. Les regrouper par la distance entre leurs cadres serait tentant, mais
la planche de laurent le défend : la dalle grise du bas (cadre à la ligne 485) n'est qu'à deux lignes vides des dalles du
haut (dernière ligne 482). Tout écart d'au moins trois pixels les collerait, et les cadres des tirets, en biais, se
recouvrent déjà entre eux. Le réglage `sheet_merge_gap_px` vaut donc 0 : seules les pièces qui se touchent n'en font
qu'une. Pour un marquage d'un seul tenant, on le peint d'un seul tenant, ou dans une planche à lui avec un grand écart.

### 4. Ranger les pièces dans des pages

`SheetImporter.pack` range les pièces par étagères : les plus hautes d'abord, de gauche à droite, une étagère neuve quand
la largeur est pleine, une page neuve quand la hauteur l'est. Chaque pièce garde deux pixels transparents autour d'elle,
contre le filtrage qui baverait d'une pièce sur l'autre, et sa case s'aligne sur les blocs de 4 × 4 pixels de la
compression : aucun bloc ne mêle deux pièces. Onze largeurs de page sont essayées ; on garde celle qui couvre le moins de
pixels. Les onze pièces de laurent tiennent dans une page de 936 × 1140.

### 5. Des pages que Godot charge telles quelles

L'éditeur tourne comme un jeu : il ne peut pas compter sur l'import de Godot pour une image qu'il vient d'écrire. Chaque
page s'écrit donc en `PortableCompressedTexture2D` (`.res`), une texture qui porte ses propres données compressées.
Compressée en BPTC, elle prend un octet par pixel en mémoire vidéo, quatre fois moins qu'en RGBA8 : 1 067 040 octets
pour la page, au lieu de 16 000 000 pour la planche telle quelle. La page s'écrit d'abord dans un fichier voisin, qui ne
remplace l'ancienne qu'une fois complet, puis se relit en remplaçant celle du cache.

Le premier essai, hors du cours, enregistrait des pages de 362 octets, relues à la taille (0, 0). Hors de l'éditeur de
Godot, une telle texture oublie ses données compressées une fois qu'elle les a données à la carte : il faut
`keep_compressed_buffer = true` avant `create_from_image` pour qu'elle les garde, et qu'elle puisse s'enregistrer.

### 6. Le catalogue, et des identifiants stables

`1_core/editor/sheet_import.gd` fait d'une pièce un asset peint en projection : `sol_01_01`, `sol_01_02`… dans l'ordre de
lecture de la planche, à l'échelle commune des planches (`painted_pixels_per_meter`, 120 pixels par mètre d'écran :
valeur proposée, à régler sur la grille de référence). Chaque asset garde sa planche (`source_sheet`) et son cadre dans
la planche (`source_rect`). Un nouvel import retrouve chaque pièce à son cadre (au moins la moitié de recouvrement) :
elle garde son identifiant, son calque et sa catégorie. Une pièce disparue quitte le catalogue ; si une salle s'en sert
encore, l'import est refusé et rien n'est écrit. Une pièce neuve prend un numéro neuf, jamais celui d'une disparue.

### 7. Le sol, pièce par pièce

Les choses du sol ne se prenaient pas à la souris (`locked_layers`, étape 7), pour qu'un clic sur le sol ne sélectionne
pas la dalle d'en dessous. Éditer le sol pièce par pièce demande l'inverse : « Sol verrouillé », en haut, le libère.

### 8. Ce que les tests ont trouvé

`test_documentation.gd` a refusé `sheet_category` : deux réglages partageaient un seul commentaire, et chaque membre public
doit avoir le sien (c'est l'aide intégrée de Godot, F1).

## Vérifier

- `7_tests/lancer_tests.bat` : tous les tests passent, sans fuite signalée à la fin ;
- F5, « Importer une planche… », `sol_01.png` : onze pièces dans la palette, et la mémoire vidéo dans la barre d'état.
