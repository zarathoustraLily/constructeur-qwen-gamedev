# Particules d'impact (GPUParticles3D, salve unique)

Exemple vérifié dans Godot 4.7.2, rendu en Compatibilité, fenêtre hors de l'écran, en lisant les pixels de l'image : `python -m usine.rag.effets verifier particules_impact`.

## Ce que fait l'effet

Au moment d'un coup, une salve d'étincelles part du point touché dans toutes les directions et retombe : `one_shot` pour une seule salve, `explosiveness` 1 pour que toutes partent au même instant, `restart()` pour la relancer.

## Quand l'employer

Balle qui touche un mur, coup d'épée, objet brisé, atterrissage lourd, pièce ramassée.

Dans un projet qui suit le plan, le shader va dans `6_assets/` (aucun code) et ses réglages (couleurs, durées) dans un `.tres` de `5_data/` (principe 2) ; la fonction qui le pilote va dans la présentation : le `_view.gd` de l'entité, ou `4_ui/` pour un effet d'écran (principe 1).

## Le piloter depuis GDScript (vérifié)

```gdscript
## Les étincelles : une salve unique, toutes émises au même instant, projetées dans toutes les directions et retombant.
func creer_etincelles(nombre: int, duree_de_vie: float, couleur: Color) -> GPUParticles3D:
	var processus := ParticleProcessMaterial.new()
	processus.direction = Vector3.UP
	processus.spread = 180.0
	processus.initial_velocity_min = 2.0
	processus.initial_velocity_max = 4.0
	processus.gravity = Vector3(0.0, -9.8, 0.0)
	processus.color = couleur
	var apparence := StandardMaterial3D.new()
	apparence.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	apparence.vertex_color_use_as_albedo = true  # la couleur du processus arrive par la couleur des sommets
	var goutte := SphereMesh.new()
	goutte.radius = 0.04
	goutte.height = 0.08
	goutte.material = apparence
	var particules := GPUParticles3D.new()
	particules.amount = nombre
	particules.lifetime = duree_de_vie
	particules.one_shot = true
	particules.explosiveness = 1.0
	particules.emitting = false
	particules.process_material = processus
	particules.draw_pass_1 = goutte
	return particules


## Le coup : la salve part du point touché.
func eclater(particules: GPUParticles3D, ou: Vector3) -> void:
	particules.global_position = ou
	particules.restart()
```

## Ce que l'exemple mesure

`exemple/exemple.gd` : 0 pixels orange avant le coup, 586 juste après, 0 une fois la salve finie, 601 à la seconde salve.

## Pièges

- La couleur de `ParticleProcessMaterial.color` arrive par la couleur des sommets : le matériau du maillage doit avoir `vertex_color_use_as_albedo` (mesuré : étincelles orange).
- `restart()` relance la salve, au nouvel endroit (mesuré : seconde salve visible).
- Les particules sortent de la boîte `visibility_aabb` : trop petite, la salve disparaît quand l'émetteur quitte l'écran (référence des classes, `GPUParticles3D.visibility_aabb` ; non mesuré ici).
