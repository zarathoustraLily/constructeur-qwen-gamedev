# Atelier · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Une surface d'eau qui ondule quand quelque chose y tombe : un maillage construit sommet par
sommet, et une onde circulaire calculée en GDScript.

Ce qu'on obtient : une grille de 40 × 40 cases ; un impact y lance une onde dont le front avance, qui se creuse
en crêtes et en creux, et s'apaise avec la distance et avec le temps.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. Le calcul de l'onde est dans `1_core/procedural/ripple.gd`, la grille dans `1_core/procedural/grid_mesh.gd`.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Une grille, sommet par sommet

`1_core/procedural/grid_mesh.gd` range les sommets ligne par ligne, centrés sur l'origine, y nul, et coupe chaque
case en deux triangles (`indices`) tournés pour que leur face regarde vers le haut. `build` passe par un
`SurfaceTool` : pour chaque sommet, sa coordonnée de texture (`set_uv`, de 0 à 1) puis sa position
(`add_vertex`) ; les indices (`add_index`) ; les normales calculées (`generate_normals`) ; et `commit` rend
l'`ArrayMesh`. Le nombre de sommets : (colonnes + 1) × (lignes + 1).

### 2. L'onde d'un impact

`1_core/procedural/ripple.gd` : la hauteur à une distance d de l'impact, t secondes après, est
amplitude × exp(-a·d - b·t) × sin(k (v·t - d)), avec k = 2 PI / longueur d'onde. Au-delà du front (d > v·t), rien
n'a encore bougé. `displace` relève une liste de points sans toucher à leurs x et z.

### 3. La surface qui ondule

`3_entities/effects/ripple_surface.gd` est un `MeshInstance3D` : `drop` lance une onde ; `advance` fait passer le
temps et reconstruit le maillage avec les sommets relevés. Au repos, elle ne reconstruit rien. `height_at` donne la
hauteur de l'eau en un point : de quoi faire flotter un objet.
