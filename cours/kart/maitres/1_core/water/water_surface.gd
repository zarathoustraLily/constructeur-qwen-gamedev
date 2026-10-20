class_name WaterSurface extends Node3D
#@ 7-8
## Contrat d'une surface d'eau, lu par les mécanismes de flottaison (1_core/water/buoyancy/) : la hauteur de
## l'eau en un point. La surface de la scène se range dans le groupe global « ocean » (project.godot), où
## les capteurs la trouvent.
## Cette surface de base est plate, à hauteur 0 : la mer calme de l'île.
#@ 9+
## Contrat d'une surface d'eau, lu par les mécanismes de flottaison (1_core/water/buoyancy/) :
## la hauteur de l'eau en un point, et ce qu'on y ajoute : ondulations, vagues d'impact, écume. L'océan du
## jeu (3_entities/ocean/ocean.gd) en hérite. La surface de la scène se range dans le groupe global
## « ocean » (project.godot), où les capteurs la trouvent.
## Cette surface de base est plate, à hauteur 0, et ignore ce qu'on lui ajoute.
#@ all

## Précision par défaut de get_wave_height(), pour les surfaces qui en ont besoin : nombre de cascades lues.
const DEFAULT_CASCADES := 3
## Précision par défaut : nombre de corrections du déplacement horizontal.
const DEFAULT_STEPS := 4


## Hauteur de l'eau à la verticale de `global_pos` (seuls x et z comptent).
## `max_cascade` et `steps` règlent la précision du calcul pour les surfaces qui en ont besoin.
func get_wave_height(_global_pos: Vector3, _max_cascade: int = DEFAULT_CASCADES, _steps: int = DEFAULT_STEPS) -> float:
	return 0.0
#@ 9+


## Ajoute une ondulation en `pos`, de hauteur `height` et de rayon `radius_px` (pixels de la simulation
## d'ondulations). Cette surface de base l'ignore.
func add_ripple(_pos: Vector3, _height: float, _radius_px: float) -> void:
	pass


## Ajoute une vague d'impact en `pos`, de hauteur `height` et de rayon `radius_px` (pixels de la simulation
## de vagues). Cette surface de base l'ignore.
func add_wave(_pos: Vector3, _height: float, _radius_px: float) -> void:
	pass


## Ajoute de l'écume en `pos` : quantité `amount` (de 0 à 1), rayon `radius` (m). Cette surface de base
## l'ignore.
func add_foam(_pos: Vector3, _amount: float, _radius: float) -> void:
	pass
#@ all
