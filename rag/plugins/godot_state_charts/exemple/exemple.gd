extends Node
## Exemple minimal de Godot State Charts (v0.22.5, GDScript) : un diagramme d'états passe de la patrouille à la
## poursuite quand on lui envoie l'événement « cible_vue ».

const IMAGES: int = 10

var _diagramme: StateChart
var _poursuite: AtomicState
var _entrees_poursuite: int = 0
var _image: int = 0


func _ready() -> void:
	# StateChart → un seul état racine (CompoundState) → des états feuilles (AtomicState) ; les transitions sont
	# des nœuds enfants de l'état qu'elles quittent. Un CompoundState créé par le code doit nommer son état initial.
	var racine := CompoundState.new()
	racine.name = "Racine"
	var patrouille := AtomicState.new()
	patrouille.name = "Patrouille"
	_poursuite = AtomicState.new()
	_poursuite.name = "Poursuite"
	var vers_poursuite := Transition.new()
	vers_poursuite.name = "VersPoursuite"
	vers_poursuite.event = &"cible_vue"
	vers_poursuite.to = NodePath("../../Poursuite")
	patrouille.add_child(vers_poursuite)
	racine.add_child(patrouille)
	racine.add_child(_poursuite)
	racine.initial_state = NodePath("Patrouille")
	_poursuite.state_entered.connect(func() -> void: _entrees_poursuite += 1)
	_diagramme = StateChart.new()
	_diagramme.add_child(racine)
	add_child(_diagramme)


func _physics_process(_delta: float) -> void:
	_image += 1
	if _image == 3:
		_diagramme.send_event(&"cible_vue")
	if _image < IMAGES:
		return
	if _poursuite.active and _entrees_poursuite == 1:
		print("EXEMPLE VERIFIE : état Poursuite actif, entré une fois")
	else:
		push_error("Poursuite active : %s, entrées : %d" % [_poursuite.active, _entrees_poursuite])
	get_tree().quit()
