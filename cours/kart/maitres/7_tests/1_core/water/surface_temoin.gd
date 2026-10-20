extends WaterSurface
#@ 7-8
## Surface d'eau de test : sa hauteur est une fonction de la position. Elle se range dans le groupe
## « ocean », où les capteurs cherchent la surface de la scène.
#@ 9+
## Surface d'eau de test : sa hauteur est une fonction de la position, sans simulation de vagues ;
## elle garde la liste des ondulations, des vagues et de l'écume qu'on lui demande. Elle se range dans
## le groupe « ocean », où les capteurs cherchent la surface de la scène.
#@ all

## Hauteur de l'eau au point donné.
var hauteur: Callable = func(_position: Vector3) -> float: return 0.0
#@ 9+
## Ondulations demandées, dans l'ordre : [position, hauteur, rayon en pixels].
var ondulations: Array[Array] = []
## Vagues demandées, dans l'ordre : [position, hauteur, rayon en pixels].
var vagues: Array[Array] = []
## Écume demandée, dans l'ordre : [position, quantité, rayon en mètres].
var ecume: Array[Array] = []
#@ all


func _init() -> void:
	add_to_group("ocean")


func get_wave_height(global_pos: Vector3, _max_cascade: int = DEFAULT_CASCADES, _steps: int = DEFAULT_STEPS) -> float:
	return hauteur.call(global_pos)
#@ 9+


func add_ripple(pos: Vector3, height: float, radius_px: float) -> void:
	ondulations.append([pos, height, radius_px])


func add_wave(pos: Vector3, height: float, radius_px: float) -> void:
	vagues.append([pos, height, radius_px])


func add_foam(pos: Vector3, amount: float, radius: float) -> void:
	ecume.append([pos, amount, radius])
#@ all
