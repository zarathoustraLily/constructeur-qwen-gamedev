# SmartShape2D (terrains et formes 2D texturés)

Version vérifiée : 3.3.2 (2026-08-07), GDScript, licence MIT, dépôt `SirRamEsq/SmartShape2D` (1 760 étoiles au
2026-10-22). Exemple minimal vérifié dans Godot 4.7.2 : `python -m usine.rag.plugins verifier smartshape2d`.

## Ce qu'il résout

Dessiner le sol et les plateformes d'un jeu 2D comme une courbe : on place des points (avec des poignées de courbe),
le plugin remplit l'intérieur d'une texture, habille les bords selon leur orientation (herbe dessus, roche sur les
côtés, coins), et calcule le polygone de collision. Une forme peut être fermée (`SS2D_Shape` fermée : un terrain) ou
ouverte (un rebord, un pont).

## Le choisir, ou Godot seul ?

- **Godot seul** : un `Polygon2D` texturé avec un `CollisionPolygon2D`, ou une `TileMapLayer`, suffisent pour des
  niveaux en tuiles ou des formes simples.
- **SmartShape2D** : des terrains organiques (pentes, collines) aux bords habillés automatiquement, modifiables dans
  l'éditeur sans retoucher de tuiles.

## API (lue dans le code de la 3.3.2)

- `SS2D_Shape` (`Node2D`) : `get_point_array()`, `shape_material` (`SS2D_Material_Shape`), `material_overrides`,
  `collision_polygon_node_path`, `collision_update_mode` (`Editor`, `Runtime`, `EditorAndRuntime`),
  `collision_generation_method`, `collision_size`, `collision_offset`, `flip_edges`, `render_edges`,
  `bake_collision()`, `force_update()`, `get_vertices()`, `get_tessellated_points()` ; signal `points_modified`.
- `SS2D_Point_Array` : `add_point(position, index, key)`, `add_points`, `close_shape()`, `is_shape_closed()`,
  `get_point_count()`, `get_tessellated_points()`.
- Matériaux : `SS2D_Material_Shape` (remplissage), `SS2D_Material_Edge` (bords), `SS2D_NormalRange` (quel bord
  pour quelle orientation).

## Installation

Copier `addons/rmsmartshape/` et activer le plugin (outils d'édition de forme dans la vue 2D).

## Exemple minimal (vérifié)

`exemple/exemple.gd` : un rectangle de 200 × 100 décrit par 4 points puis fermé ; le polygone de collision est
calculé au lancement. Mesuré : forme fermée de 5 points (le point de fermeture répète le premier), polygone de
collision de 4 sommets.

```gdscript
var points := _forme.get_point_array()
for p: Vector2 in [Vector2(0, 0), Vector2(200, 0), Vector2(200, 100), Vector2(0, 100)]:
	points.add_point(p)
points.close_shape()
_forme.collision_polygon_node_path = _forme.get_path_to(_polygone)
_forme.collision_update_mode = SS2D_Shape.CollisionUpdateMode.Runtime
_forme.bake_collision()
```

## Pièges

- La collision n'est calculée par défaut que dans l'éditeur (`CollisionUpdateMode.Editor`) : une forme créée ou
  modifiée en jeu doit passer en `Runtime` (ou `EditorAndRuntime`), sinon `bake_collision()` ne fait rien (lu dans
  `bake_collision`, vérifié par l'exemple).
- En 3.x, les fonctions de points de `SS2D_Shape` (`add_point`, `close_shape`, `is_shape_closed`…) sont dépréciées
  (`show_point_array_deprecation_warning`, lu dans le code) : passer par `get_point_array()`.
- Une forme fermée compte un point de plus que ses sommets : le dernier répète le premier.
- À la fermeture de l'éditeur, le plugin laisse des objets en mémoire (« 2 ObjectDB instances were leaked at exit »,
  relevé au chargement du plugin).
