extends GdUnitTestSuite
## Règles de la machine à états : elle entre dans l'état initial au départ ; une transition fait sortir l'ancien
## état puis entrer le nouveau, et s'annonce ; un état inconnu ou déjà actif ne change rien ; un état qui a fini
## fait passer au suivant ; seul l'état actif tourne.


## Un état de test qui note ce qu'on lui fait.
class Recorder extends State:
	var calls: Array[String] = []

	func enter(previous: StringName) -> void:
		calls.append("enter:%s" % previous)

	func exit() -> void:
		calls.append("exit")

	func physics_update(_delta: float) -> void:
		calls.append("update")


var _machine: StateMachine
var _first: Recorder
var _second: Recorder


func before_test() -> void:
	_machine = auto_free(StateMachine.new())
	_first = Recorder.new()
	_first.name = "First"
	_second = Recorder.new()
	_second.name = "Second"
	_machine.add_child(_first)
	_machine.add_child(_second)
	_machine.initial_state = _first
	add_child(_machine)


func test_au_depart_elle_entre_dans_l_etat_initial() -> void:
	assert_that(_machine.current).is_same(_first)
	assert_array(_first.calls).is_equal(["enter:"])
	assert_array(_machine.state_names()).contains_exactly_in_any_order([&"First", &"Second"])


func test_une_transition_fait_sortir_puis_entrer_et_s_annonce() -> void:
	var changes: Array = []
	_machine.state_changed.connect(func(from: StringName, to: StringName) -> void: changes.append([from, to]))
	assert_bool(_machine.transition_to(&"Second")).is_true()
	assert_that(_machine.current).is_same(_second)
	assert_array(_first.calls).is_equal(["enter:", "exit"])
	assert_array(_second.calls).is_equal(["enter:First"])
	assert_array(changes).is_equal([[&"First", &"Second"]])


func test_un_etat_inconnu_ou_deja_actif_ne_change_rien() -> void:
	assert_bool(_machine.transition_to(&"Nulle_part")).is_false()
	assert_bool(_machine.transition_to(&"First")).is_false()
	assert_that(_machine.current).is_same(_first)
	assert_array(_first.calls).is_equal(["enter:"])


func test_un_etat_qui_a_fini_fait_passer_au_suivant() -> void:
	_first.finished.emit(&"Second")
	assert_that(_machine.current).is_same(_second)


func test_seul_l_etat_actif_tourne() -> void:
	_machine._physics_process(0.016)
	assert_array(_first.calls).is_equal(["enter:", "update"])
	assert_array(_second.calls).is_empty()
