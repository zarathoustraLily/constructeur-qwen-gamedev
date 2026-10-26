extends Node3D
## Exemple minimal de ProtonScatter (branche main, commit 7198cc0, GDScript) : disperser 20 cailloux au hasard dans
## une boîte de 10 × 1 × 10 m, avec une graine fixe, puis compter les instances produites.

const CREER_AU_HASARD: GDScript = preload("res://addons/proton_scatter/src/modifiers/create_inside_random.gd")

var _dispersion: ProtonScatter
var _instances: int = -1


func _ready() -> void:
	_dispersion = ProtonScatter.new()
	_dispersion.global_seed = 7
	_dispersion.dbg_disable_thread = true  # calcul sur le fil principal : plus lent, mais simple à suivre
	# La pile de modificateurs décrit comment placer : ici, 20 positions au hasard dans les formes.
	var pile := ProtonScatterModifierStack.new()
	var au_hasard: ScatterBaseModifier = CREER_AU_HASARD.new()
	au_hasard.set(&"amount", 20)
	pile.add(au_hasard)
	_dispersion.modifier_stack = pile
	# Quoi disperser : une scène sur le disque. Où : une forme (une boîte).
	var objet := ProtonScatterItem.new()
	objet.path = "res://exemple/caillou.tscn"
	_dispersion.add_child(objet)
	var zone := ProtonScatterShape.new()
	var boite := ProtonScatterBoxShape.new()
	boite.size = Vector3(10.0, 1.0, 10.0)
	zone.shape = boite
	_dispersion.add_child(zone)
	_dispersion.build_completed.connect(_on_build_completed)
	add_child(_dispersion)


func _on_build_completed() -> void:
	_instances = 0
	for mmi: Node in _dispersion.find_children("*", "MultiMeshInstance3D", true, false):
		_instances += (mmi as MultiMeshInstance3D).multimesh.instance_count


func _physics_process(_delta: float) -> void:
	if _instances < 0:
		return
	if _instances == 20:
		print("EXEMPLE VERIFIE : %d cailloux dispersés" % _instances)
	else:
		push_error("%d instances au lieu de 20" % _instances)
	get_tree().quit()
