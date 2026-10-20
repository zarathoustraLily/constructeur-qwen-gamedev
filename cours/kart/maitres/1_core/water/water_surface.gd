class_name WaterSurface extends Node3D
## Contrat d'une surface d'eau, lu par les mécanismes de flottaison (1_core/water/buoyancy/) :
## la hauteur de l'eau en un point, et les vagues qu'on y ajoute. L'océan du jeu
## (3_entities/ocean/ocean.gd) en hérite. La surface de la scène se range dans le groupe global
## « ocean » (project.godot), où les capteurs la trouvent.
## Cette surface de base est plate, à hauteur 0, et ignore les vagues.


## Hauteur de l'eau à la verticale de `global_pos` (seuls x et z comptent).
## `max_cascade` et `steps` règlent la précision du calcul pour les surfaces qui en ont besoin.
func get_wave_height(_global_pos: Vector3, _max_cascade: int = 3, _steps: int = 4) -> float:
	return 0.0


## Ajoute une vague d'impact en `pos`, de hauteur `height` et de rayon `radius_px` (pixels de la simulation
## de vagues). Cette surface de base l'ignore.
func add_wave(_pos: Vector3, _height: float, _radius_px: float) -> void:
	pass
