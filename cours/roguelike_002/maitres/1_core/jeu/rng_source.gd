class_name RngSource extends RefCounted
## La source du hasard du jeu (règle SIM-09) : un seul générateur, créé à partir d'une graine, et donné à ceux qui en
## ont besoin. Rien n'appelle randi() ni randf() : la même graine redonne la même partie, et un test la rejoue.

## La graine de la partie.
var seed_value: int = 0

var _rng: RandomNumberGenerator = null


## Une source à la graine `graine`.
func _init(graine: int = 0) -> void:
	seed_value = graine


## Le générateur de la source, créé au premier appel, puis toujours le même.
func instance() -> RandomNumberGenerator:
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.seed = seed_value
	return _rng
