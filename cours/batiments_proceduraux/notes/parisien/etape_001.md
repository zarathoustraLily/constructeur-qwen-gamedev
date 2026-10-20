# Paris · étape 001 · Un mur percé de baies

**Piste : Building.** On fabrique de la géométrie, rien d'autre. Pas encore de matériau
calculé, pas encore de fenêtre.

Ce qu'on obtient : une façade en grille. 5 travées en largeur, 5 niveaux en hauteur, une baie
par case, et un volume nu derrière.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. F5 : l'immeuble, vu de trois quarts. Clic droit maintenu et souris : regarder. ZQSD : se
   déplacer. A et E : descendre, monter. F : recadrer. Échap : quitter.
3. Pour régler l'immeuble : ouvrir `{NAME}.tscn`, cliquer sur le nœud racine, changer une
   variable dans l'inspecteur. L'immeuble se reconstruit aussitôt, sans lancer le jeu.

## Les fichiers du projet

{FILES_TABLE}

Le seul fichier à étudier à cette étape est `{NAME}.gd`. Les autres font tourner la visite :
ils sont les mêmes dans tous les projets du cours.

Les dossiers `0_autoload`, `3_entities` et `5_data` sont vides : un fichier `LISEZMOI.md` y dit
pourquoi.

## Ce qu'on a fait, dans l'ordre

### 1. Fixer le repère une fois pour toutes

Avant d'écrire une ligne, on décide où est l'immeuble dans son propre espace. Cette décision
ne changera plus jusqu'à la dernière étape :

- la façade est dans le plan `z = 0` et regarde vers `+Z`, c'est-à-dire vers la rue ;
- elle est centrée sur `x = 0` ;
- le sol est à `y = 0` ;
- l'immeuble s'enfonce vers `-Z` ;
- une unité vaut un mètre.

Tout le reste s'appuie là-dessus. La fonction `_bay_center(bay)` en est la première
application : elle donne l'abscisse du milieu d'une travée, la façade étant centrée.

### 2. Déclarer les variables

Chaque `@export` devient un réglage dans l'inspecteur. Il y en a huit, rangés en trois
groupes par `@export_group` :

- **Plan** : `bay_count`, `bay_width`, `depth` ;
- **Niveaux** : `floor_count`, `floor_height` ;
- **Baies** : `window_width`, `window_height`, `sill_height`.

`@export_range(1, 12, 1)` borne la valeur et donne un curseur. `"suffix:m"` affiche l'unité.
Le commentaire `##` placé au-dessus d'une variable devient son aide au survol.

### 3. Faire tourner le script dans l'éditeur

La première ligne, `@tool`, fait tourner le script dans l'éditeur, pas seulement dans le jeu.
C'est ce qui permet de voir l'immeuble en réglant ses variables.

Il faut alors savoir quand reconstruire. On ne met pas de code sur chaque variable. À la
place, `_current_signature()` hache toutes les variables exportées en un seul nombre, et
`_process()` compare ce nombre à celui de la dernière construction. S'il a changé, on
reconstruit. Dans le jeu, `_ready()` coupe `_process()` : l'immeuble est monté une seule fois.

### 4. Écrire `rebuild()`, le chef d'orchestre

Toujours les mêmes quatre temps :

1. jeter l'ancien résultat ;
2. créer un nœud interne nommé `Generated` : il n'apparaît pas dans l'arbre de la scène et
   n'est pas enregistré avec elle. La scène ne garde donc que les variables ;
3. écrire les triangles dans des `SurfaceTool`, un par matériau ;
4. transformer chaque `SurfaceTool` en maillage avec `_commit()`.

### 5. Poser du mur autour des trous : `_build_level()`

C'est l'idée centrale de l'étape. **On ne perce pas un mur : on pose du mur autour du
trou.** Pour chaque baie, quatre boîtes :

| Boîte | Où |
|---|---|
| Trumeau gauche | de la limite de travée au bord de la baie, sur toute la hauteur du niveau |
| Trumeau droit | pareil, de l'autre côté |
| Allège | sous la baie, de la largeur de la baie |
| Linteau | au-dessus de la baie, jusqu'au plancher suivant |

Trois calculs à comprendre dans cette fonction :

- `opening` : la taille de la baie, rabotée par `minf()` pour qu'elle ne dépasse jamais sa case ;
- `pier = 0.5 * (bay_width - opening.x)` : la largeur d'un trumeau, ce qui reste de la travée
  de chaque côté de la baie ;
- `lintel = floor_height - sill_height - opening.y` : la hauteur du linteau, ce qui reste du
  niveau au-dessus de la baie.

Le mur est derrière le plan `z = 0` : son centre est à `-0.5 * WALL_DEPTH`.

### 6. Descendre jusqu'au triangle

Quatre petites fonctions, chacune bâtie sur la suivante :

- `_add_wall()` : une boîte élargie de 6 mm (`WALL_OVERLAP`). Deux boîtes posées bord à bord
  laissent passer un liseré de lumière à leur jonction ; un léger recouvrement le supprime ;
- `_add_box()` : six rectangles, deux par axe. La double boucle sur `axis` et `direction`
  évite d'écrire les six faces à la main ;
- `_add_quad()` : deux triangles qui partagent une diagonale ;
- `_add_triangle()` : trois sommets, chacun avec sa normale. Godot prend pour face avant celle
  dont les sommets tournent dans le sens des aiguilles d'une montre. Un produit vectoriel
  comparé à la normale dit dans quel sens tourne le triangle ; s'il tourne à l'envers, on
  échange deux sommets.

### 7. Fermer le volume

Une dernière boîte, derrière la façade, donne son épaisseur à l'immeuble. Elle a son propre
`SurfaceTool`, donc son propre matériau : un enduit uni.

## Ce qu'il faut retenir

1. Un maillage procédural est une liste de triangles écrite dans un `SurfaceTool`.
2. On pose du mur autour des trous.
3. Le repère et l'unité sont fixés avant tout le reste.
4. La scène n'enregistre que des variables ; la géométrie est refaite à chaque ouverture.

## À essayer

- `sill_height` à 0 : les baies deviennent des portes-fenêtres.
- `window_width` à 2,5 : la baie est rabotée, elle ne peut pas dépasser sa travée.
- `bay_count` à 2, `floor_count` à 8.
- Dans `_add_triangle()`, retirer l'échange des sommets : une partie des faces disparaît,
  parce qu'elles sont vues de dos.
{TWIN}
## Étape suivante

002 : le mur reçoit un matériau calculé, un shader. Et les fonctions `_add_triangle`,
`_add_quad`, `_add_box` et `_commit` partent dans un outil commun, pour ne plus les recopier.
