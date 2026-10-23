extends Node
## Exemple minimal de LimboAI (v1.8.1, GDExtension) : une machine à états hiérarchique (LimboHSM) passe de la
## patrouille à la poursuite sur un événement, et un arbre de comportement (BehaviorTree) répète une action.

const IMAGES: int = 10


## Une action d'arbre de comportement : compte ses passages dans le tableau noir, puis réussit.
class Compter extends BTAction:
	func _tick(_delta: float) -> Status:
		var tableau: Blackboard = get_blackboard()
		tableau.set_var(&"passages", int(tableau.get_var(&"passages", 0, false)) + 1)
		return SUCCESS


var _hsm: LimboHSM
var _patrouille: LimboState
var _poursuite: LimboState
var _joueur: BTPlayer
var _image: int = 0


func _ready() -> void:
	# Machine à états : deux états, deux transitions nommées par des événements.
	_hsm = LimboHSM.new()
	_patrouille = LimboState.new().named("Patrouille")
	_poursuite = LimboState.new().named("Poursuite")
	_hsm.add_child(_patrouille)
	_hsm.add_child(_poursuite)
	_hsm.add_transition(_patrouille, _poursuite, &"cible_vue")
	_hsm.add_transition(_poursuite, _patrouille, &"cible_perdue")
	add_child(_hsm)
	_hsm.initialize(self)
	_hsm.set_active(true)
	# Arbre de comportement : une séquence qui contient l'action, joué par un BTPlayer à chaque image.
	var sequence := BTSequence.new()
	sequence.add_child(Compter.new())
	var arbre := BehaviorTree.new()
	arbre.set_root_task(sequence)
	_joueur = BTPlayer.new()
	_joueur.behavior_tree = arbre
	# créé par le code, il n'a pas de propriétaire : on lui dit quelle est la racine de la scène
	_joueur.set_scene_root_hint(self)
	add_child(_joueur)


func _physics_process(_delta: float) -> void:
	_image += 1
	if _image == 2:
		_hsm.dispatch(&"cible_vue")
	if _image < IMAGES:
		return
	var etat := _hsm.get_active_state()
	var passages := int(_joueur.get_blackboard().get_var(&"passages", 0, false))
	if etat == _poursuite and passages > 0:
		print("EXEMPLE VERIFIE : état actif %s, action jouée %d fois" % [etat.name, passages])
	else:
		push_error("état actif %s, action jouée %d fois" % [str(etat.name) if etat else "aucun", passages])
	get_tree().quit()
