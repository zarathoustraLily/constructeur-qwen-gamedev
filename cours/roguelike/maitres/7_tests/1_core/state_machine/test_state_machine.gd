extends GdUnitTestSuite
## Règles de la machine à états : elle entre dans son état de départ (à défaut, son premier enfant) quand
## son propriétaire est prêt ; seul l'état actif reçoit l'image physique ; un état qui émet finished passe la
## main à l'état nommé, qui sait d'où il vient ; un nom inconnu ne change rien.

const TEMOIN := preload("res://7_tests/1_core/state_machine/etat_temoin.gd")

var _machine: StateMachine
var _a: State
var _b: State


## Une machine à deux états témoins, A puis B, partant de `start` (vide : pas d'état de départ).
func _build(start: String) -> void:
	var owner_node: Node = auto_free(Node.new())
	_machine = StateMachine.new()
	_machine.name = "StateMachine"
	owner_node.add_child(_machine)
	_machine.owner = owner_node
	_a = TEMOIN.new()
	_a.name = "A"
	_b = TEMOIN.new()
	_b.name = "B"
	for state: State in [_a, _b]:
		_machine.add_child(state)
		state.owner = owner_node
	if start != "":
		_machine.initial_state = _machine.get_node(start)
	add_child(owner_node)


func test_elle_entre_dans_son_etat_de_depart_quand_le_proprietaire_est_pret() -> void:
	_build("B")
	assert_object(_machine.state).is_same(_b)
	assert_array(_b.get("calls")).is_equal(["enter "])


func test_sans_etat_de_depart_elle_prend_son_premier_enfant() -> void:
	_build("")
	assert_object(_machine.state).is_same(_a)


func test_seul_l_etat_actif_recoit_l_image_physique() -> void:
	_build("A")
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_array(_a.get("calls")).contains(["physics"])
	assert_array(_b.get("calls")).is_empty()


func test_finished_passe_a_l_etat_nomme() -> void:
	_build("A")
	var changes: Array[String] = []
	_machine.state_changed.connect(func(from: StringName, to: StringName) -> void: changes.append(from + ">" + to))
	_a.finished.emit(&"B")
	assert_object(_machine.state).is_same(_b)
	assert_array(_a.get("calls")).is_equal(["enter ", "exit"])
	assert_array(_b.get("calls")).is_equal(["enter A"])
	assert_array(changes).is_equal(["A>B"])


func test_un_etat_inconnu_ne_change_rien() -> void:
	_build("A")
	assert_error(func() -> void: _a.finished.emit(&"Z")) \
		.is_push_error("StateMachine StateMachine : état inconnu « Z »")
	assert_object(_machine.state).is_same(_a)
	assert_array(_a.get("calls")).is_equal(["enter "])
