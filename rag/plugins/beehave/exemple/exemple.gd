extends Node
## Exemple minimal de Beehave (v2.9.3, GDScript) : un arbre de comportement choisit, à chaque image physique,
## entre poursuivre (si la cible est visible) et patrouiller.

const IMAGES: int = 10

var cible_visible: bool = false
var poursuites: int = 0
var patrouilles: int = 0
var _image: int = 0


## Condition : réussit si l'acteur voit sa cible.
class CibleVisible extends ConditionLeaf:
	func tick(actor: Node, _blackboard: Blackboard) -> int:
		return SUCCESS if bool(actor.get("cible_visible")) else FAILURE


## Action : ajoute un à un compteur de l'acteur, puis réussit.
class Compter extends ActionLeaf:
	var compteur: StringName

	func _init(nom: StringName) -> void:
		compteur = nom

	func tick(actor: Node, _blackboard: Blackboard) -> int:
		actor.set(compteur, int(actor.get(compteur)) + 1)
		return SUCCESS


func _ready() -> void:
	# Sélecteur : essaie la poursuite (condition puis action) ; si elle échoue, patrouille.
	var choix := SelectorComposite.new()
	var poursuite := SequenceComposite.new()
	poursuite.add_child(CibleVisible.new())
	poursuite.add_child(Compter.new(&"poursuites"))
	choix.add_child(poursuite)
	choix.add_child(Compter.new(&"patrouilles"))
	var arbre := BeehaveTree.new()
	arbre.actor = self
	arbre.add_child(choix)
	add_child(arbre)


func _physics_process(_delta: float) -> void:
	_image += 1
	if _image == 5:
		cible_visible = true
	if _image < IMAGES:
		return
	if patrouilles > 0 and poursuites > 0:
		print("EXEMPLE VERIFIE : %d patrouilles, puis %d poursuites" % [patrouilles, poursuites])
	else:
		push_error("%d patrouilles, %d poursuites" % [patrouilles, poursuites])
	get_tree().quit()
