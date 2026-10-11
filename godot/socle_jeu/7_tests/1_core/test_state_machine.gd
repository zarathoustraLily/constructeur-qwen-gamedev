extends GdUnitTestSuite
## La machine à états : état initial, transitions demandées par les états, signal.


func _machine() -> StateMachine:
	var owner_node: Node = auto_free(Node.new())
	var machine := StateMachine.new()
	for nom in ["Idle", "Run"]:
		var state := State.new()
		state.name = nom
		machine.add_child(state)
	owner_node.add_child(machine)
	add_child(owner_node)
	return machine


func test_premier_etat_par_defaut() -> void:
	assert_str(_machine().current_name()).is_equal("idle")


func test_transition_et_signal() -> void:
	var machine := _machine()
	var vus: Array[String] = []
	machine.state_changed.connect(func(from: StringName, to: StringName) -> void: vus.append("%s>%s" % [from, to]))
	machine.current.transition_requested.emit(&"run")
	assert_str(machine.current_name()).is_equal("run")
	assert_array(vus).contains_exactly(["idle>run"])

