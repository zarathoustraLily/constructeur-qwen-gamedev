# Éditeur de niveaux · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Une chose de la salle ne contient pas son image : elle cite un asset du catalogue
(`thing_assets`). Le catalogue dit, pour chaque asset, où est son image (une région d'une planche), quelle taille il
fait en jeu, par quel point il se pose, et dans quel calque l'éditeur le range. L'éditeur et le jeu lisent le même
catalogue : un asset ajouté ici apparaît dans la palette, et le jeu sait le dessiner.

Ce qu'on obtient : `5_data/catalogue/catalogue.tres` (20 assets d'une planche fictive), sa validation, la vérification
d'une salle face au catalogue, et la recherche de la palette.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. Double-cliquer sur `5_data/catalogue/catalogue.tres` : la liste des assets, chacun avec sa planche et sa région.
3. Les tests : `7_tests/lancer_tests.bat`, ou le panneau GdUnit4.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Un asset : une région, une taille, une ancre

`1_core/data/asset_def.gd` décrit un asset :
- `atlas` et `region` : la planche d'images et le rectangle de l'asset, en pixels. Une planche regroupe beaucoup de
  petites images : un seul fichier à charger, et le jeu dessine plusieurs assets sans changer de texture ;
- `size_m` : la taille posée à l'échelle 1, en mètres. C'est elle qui compte en jeu, pas la taille en pixels : une
  image plus fine (un vrai dessin plus tard) ne change pas la taille de l'obstacle ;
- `anchor` : le point de l'image posé sur la position de la chose. Un obstacle se pose par le bas (0,5 ; 1), au pied,
  là où il touche le sol ; une dalle par son centre (0,5 ; 0,5) ;
- `category` et `default_layer` : la palette range les assets par catégorie, et l'éditeur pose un asset ajouté dans son
  calque par défaut ;
- `tags` : des mots de recherche.

`validate()` vérifie qu'il a une planche, que sa région tient dans la planche, que sa taille est positive et son ancre
dans [0, 1]. La taille de la planche se lit par `get_width()` et `get_height()`, des entiers : `get_size()` rend un
`Vector2` à virgule, qu'un `Rect2i` n'accepte pas.

### 2. Le catalogue, et la salle face au catalogue

`1_core/data/asset_catalog_def.gd` porte les calques des salles et la liste des assets. Sa validation signale un
identifiant en double et un calque par défaut inconnu. `room_errors(room)` vérifie une salle face au catalogue : chaque
calque et chaque asset qu'elle cite doivent exister. La salle seule ne peut pas le savoir (`RoomData.validate()`
ignore le catalogue) ; l'éditeur fera les deux contrôles avant d'enregistrer (étape 9).

### 3. Le catalogue en sous-ressources

Le catalogue a peu d'entrées (quelques dizaines, quelques centaines au plus), chacune avec plusieurs champs de types
différents : ici, une sous-ressource par asset (`Array[AssetDef]`) se lit mieux qu'un rangement en colonnes, et
l'Inspecteur de Godot l'édite tel quel. À l'inverse, une salle a des centaines de choses aux mêmes champs : là, les
colonnes de l'étape 2.

### 4. La recherche de la palette

`1_core/editor/asset_search.gd` cherche sans réseau ni index externe. Chaque mot de la requête doit se trouver dans
l'identifiant, les mots de recherche ou la catégorie (un « et » entre les mots : « sol tole » ne rend que `sol_tole`).
Les majuscules et les accents ne comptent pas (« Tôle » trouve `sol_tole`), et les tirets bas valent des espaces. Les
résultats viennent dans cet ordre : identifiant exact, identifiant qui commence par la requête (les quatre `sol_…`
pour « sol », avant `console`, qui contient « sol » au milieu), puis les autres, par ordre alphabétique.

## Vérifier

- `7_tests/lancer_tests.bat` : tous les tests passent, sans fuite signalée à la fin.
