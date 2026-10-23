extends Node
## Exemple minimal de Juicee (v2.0.0, GDScript) : un « hit stop », le temps qui s'arrête un instant quand un coup
## porte, joué par un JuiceePlayer, puis rendu à la normale.

const IMAGES: int = 60

var _joueur: JuiceePlayer
var _echelle_min: float = 1.0
var _image: int = 0


func _ready() -> void:
	var arret := JuiceeHitStopEffect.new()
	arret.freeze_duration = 0.1
	arret.time_scale_during = 0.0
	var sequence := JuiceeSequence.new()
	sequence.effects = [arret]
	_joueur = JuiceePlayer.new()
	_joueur.sequence = sequence
	add_child(_joueur)


# À Engine.time_scale = 0, _process et _physics_process sont toujours appelés, mais avec un delta nul.
func _process(_delta: float) -> void:
	_image += 1
	if _image == 5:
		_joueur.play()
	_echelle_min = minf(_echelle_min, Engine.time_scale)
	if _image < IMAGES:
		return
	if is_equal_approx(_echelle_min, 0.0) and is_equal_approx(Engine.time_scale, 1.0):
		print("EXEMPLE VERIFIE : temps arrêté (échelle %.1f), puis rendu (échelle %.1f)" % [_echelle_min, Engine.time_scale])
	else:
		push_error("échelle minimale %.2f, échelle finale %.2f" % [_echelle_min, Engine.time_scale])
	get_tree().quit()
