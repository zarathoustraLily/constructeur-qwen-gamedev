# Terrain3D (grands terrains 3D sculptables)

Version vérifiée : v1.0.2-stable (2026-05-19), GDExtension (`compatibility_minimum = "4.4"`, annoncée pour 4.4 à
4.6), licence MIT, dépôt `TokisanGames/Terrain3D` (4 393 étoiles au 2026-10-22). Exemple minimal vérifié dans
Godot 4.7.2 : `python -m usine.rag.plugins verifier terrain3d`.

## Ce qu'il résout

Un terrain découpé en régions (`Terrain3DRegion`), chacune avec ses cartes de hauteur, de contrôle (textures,
trous, navigation) et de couleur, rendu avec des niveaux de détail autour de la caméra (clipmap). On le sculpte et
on le peint dans l'éditeur ; on pose dessus des objets instanciés ; il fournit sa collision et sa géométrie de
navigation. Le code C++ tient de très grandes cartes.

## Le choisir, ou Godot seul ?

- **Godot seul** : un `MeshInstance3D` (un maillage exporté de Blender, ou fabriqué par `SurfaceTool`) avec une
  `HeightMapShape3D` suffit pour une île ou une arène.
- **Terrain3D** : un monde ouvert, sculpté et peint dans Godot, avec niveaux de détail, trous, et des milliers
  d'objets posés dessus.

## API (relevée dans `ClassDB` avec l'extension chargée dans 4.7.2)

- `Terrain3D` (`Node3D`) : `get_data()`, `set_material`, `set_assets`, `set_camera(camera)`, `change_region_size(size)`,
  `set_vertex_spacing`, `set_mesh_lods`, `set_collision_mode`, `set_collision_layer`,
  `set_collision_mask`, `get_intersection(src_pos, direction, gpu_mode)`, `bake_mesh(lod, filter)`,
  `generate_nav_mesh_source_geometry(global_aabb, require_nav)`.
- `Terrain3DData` : `add_region_blankp(global_position)`, `get_region_count()`, `has_regionp(global_position)`,
  `set_height(global_position, height)`, `get_height(global_position)`, `get_normal`, `set_color`,
  `set_control_hole`, `set_control_navigation`, `is_in_slope`, `update_maps(map_type)`, `import_images`,
  `save_directory`, `load_directory`.
- `Terrain3DAssets` : `set_texture(id, texture)`, `set_mesh_asset(id, mesh)`.

## Installation

Copier `addons/terrain_3d/` (bibliothèques de chaque plateforme dans `bin/`), puis rouvrir l'éditeur.

## Exemple minimal (vérifié)

`exemple/exemple.gd` : une région vide, un point élevé à 5 m, puis lecture de la hauteur. Mesuré : 1 région,
5,0 m au point élevé, 0,0 m ailleurs.

```gdscript
var donnees := _terrain.get_data()
donnees.add_region_blankp(Vector3.ZERO)
donnees.set_height(Vector3(10.0, 0.0, 10.0), 5.0)
donnees.update_maps(Terrain3DRegion.TYPE_HEIGHT)
var haut := donnees.get_height(Vector3(10.0, 0.0, 10.0))
```

## Pièges (relevés par l'exemple)

- Sans caméra active, le terrain s'arrête : « Cannot find the active camera. Set it manually with
  Terrain3D.set_camera(). Stopping _physics_process() ». Une `Camera3D` dans la scène suffit.
- Dans Godot 4.7.2, il écrit « WARNING: instance_reset_physics_interpolation() is deprecated. » : la version 1.0.2
  est compilée pour 4.4 à 4.6 et appelle une fonction de `RenderingServer` absente de la référence des classes
  4.7.2. Le terrain fonctionne quand même ; la ligne vient du plugin.
- À la fermeture de l'éditeur, il laisse des objets en mémoire (fuite relevée au chargement du plugin).
