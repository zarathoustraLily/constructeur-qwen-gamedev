# Debug Draw 3D (dessin de débogage en 3D et en 2D)

Version vérifiée : 1.7.3 (2026-04-04), GDExtension (`compatibility_minimum = "4.4.1"`), licence MIT, dépôt
`DmitriySalnikov/godot_debug_draw_3d` (1 074 étoiles au 2026-10-22). Exemple minimal vérifié dans Godot 4.7.2,
fenêtre hors de l'écran : `python -m usine.rag.plugins verifier debug_draw_3d`.

## Ce qu'il résout

Voir ce que le code calcule, sans créer de nœud : deux singletons, `DebugDraw3D` (formes dans le monde) et
`DebugDraw2D` (textes et graphiques à l'écran), appelables depuis n'importe quel script. Chaque appel dessine
pour une image, ou pendant `duration` secondes. Pour les jeux exportés, `libs/` fournit une bibliothèque de
version finale et une variante `.enabled` (`libdd3d.windows.template_release.x86_64.enabled.dll`) ; d'après leur
nom, seule la seconde garde le dessin dans un jeu exporté (non vérifié).

## Le choisir, ou Godot seul ?

- **Godot seul** : `ImmediateMesh` ou des `MeshInstance3D` créés à la main, et l'option Débogage → Formes de
  collision visibles de l'éditeur.
- **Debug Draw 3D** : une ligne par forme, pour suivre un rayon, une zone de détection, une trajectoire, le cône de
  vision d'un ennemi ou un chemin de navigation pendant la partie.

## API (relevée dans `ClassDB` avec l'extension chargée dans 4.7.2)

- `DebugDraw3D` : `draw_box(position, rotation, size, color, is_box_centered, duration)`, `draw_box_ab`,
  `draw_aabb(aabb, color, duration)`, `draw_sphere(position, radius, color, duration)`, `draw_cylinder_ab`,
  `draw_capsule`, `draw_line(a, b, color, duration)`, `draw_lines`, `draw_ray(origin, direction, length, color,
  duration)`, `draw_line_hit(start, end, hit, is_hit, …)`, `draw_arrow`, `draw_arrow_ray`, `draw_line_path`,
  `draw_point_path`, `draw_points`, `draw_square`, `draw_plane`, `draw_camera_frustum(camera, color, duration)`,
  `draw_position`, `draw_gizmo`, `clear_all()`, `is_debug_enabled()`, `get_render_stats()`.
- `DebugDraw2D` : `set_text(key, value, priority, color_of_value, duration)`, `begin_text_group`,
  `end_text_group`, `clear_texts()`, `get_render_stats()`.
- `DebugDraw3DStats` : `instances`, `lines`, `instances_physics`, `lines_physics`, `visible_instances`,
  `total_time_spent_usec`…

## Installation

Copier `addons/debug_draw_3d/` (les bibliothèques de chaque plateforme sont dans `libs/`), puis rouvrir l'éditeur.
Rien à activer.

## Exemple minimal (vérifié)

`exemple/exemple.gd` : à chaque image physique, une boîte, un rayon, une sphère et un texte. Après 10 images,
fenêtre hors de l'écran en Compatibilité : 6 instances comptées dans les tampons de la physique
(`instances_physics`).

```gdscript
func _physics_process(_delta: float) -> void:
	DebugDraw3D.draw_box(Vector3.ZERO, Quaternion.IDENTITY, Vector3.ONE, Color.YELLOW)
	DebugDraw3D.draw_ray(Vector3.ZERO, Vector3.FORWARD, 3.0, Color.RED)
	DebugDraw2D.set_text("image", _image)
```

## Pièges (relevés par l'exemple)

- Sans rendu (`--headless`), rien n'est dessiné ni compté : `get_render_stats()` rend 0 partout (mesuré). Un test
  qui vérifie un dessin tourne fenêtre ouverte (ici hors de l'écran, en Compatibilité).
- Un dessin fait dans `_physics_process` est compté dans `instances_physics`, pas dans `instances`.
- C'est un outil de débogage : rien de ce qu'il dessine ne doit servir au jeu lui-même.
