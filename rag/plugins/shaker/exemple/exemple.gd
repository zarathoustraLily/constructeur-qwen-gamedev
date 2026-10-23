extends Node3D
## Exemple minimal de Shaker (v1.0.7, GDScript) : secouer un nœud 3D (une caméra, un objet touché) une demi-seconde,
## puis le laisser revenir à sa place.

const IMAGES: int = 90

var _cible: Node3D
var _secoueur: ShakerComponent3D
var _ecart_max: float = 0.0
var _image: int = 0


func _ready() -> void:
	_cible = Node3D.new()
	add_child(_cible)
	# Un préréglage : une liste de formes de secousse pour la position (ici, aléatoire, amplitude 0,5 m).
	var forme := ShakerTypeRandom3D.new()
	forme.amplitude = Vector3(0.5, 0.5, 0.5)
	var prereglage := ShakerPreset3D.new()
	prereglage.PositionShake = [forme]
	_secoueur = ShakerComponent3D.new()
	_secoueur.custom_target = true
	_secoueur.Targets = [_cible]
	_secoueur.shakerPreset = prereglage
	_secoueur.duration = 0.5
	add_child(_secoueur)
	_secoueur.play_shake()


func _process(_delta: float) -> void:
	_ecart_max = maxf(_ecart_max, _cible.position.length())


func _physics_process(_delta: float) -> void:
	_image += 1
	if _image < IMAGES:
		return
	var reste := _cible.position.length()
	if _ecart_max > 0.05 and reste < 0.01:
		print("EXEMPLE VERIFIE : écart maximal %.3f m, revenu à %.4f m" % [_ecart_max, reste])
	else:
		push_error("écart maximal %.3f m, reste %.4f m" % [_ecart_max, reste])
	get_tree().quit()
