class_name DebugOverlay
extends CanvasLayer
## Mise au point (touche F3) : l'état courant et la vie de chaque nœud du groupe « debuggable ».


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_overlay"):
		visible = not visible


func _process(_delta: float) -> void:
	if visible:
		($Text as Label).text = describe()


func describe() -> String:
	var lines: PackedStringArray = []
	for node in get_tree().get_nodes_in_group(&"debuggable"):
		var machine := node.get_node_or_null(^"StateMachine") as StateMachine
		var health := node.get_node_or_null(^"Health") as HealthComponent
		lines.append("%s  %s  vie %s" % [node.name, machine.current_name() if machine else "-",
			str(health.current_health) if health else "-"])
	return "\n".join(lines)
