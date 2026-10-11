extends Node
## Journal de comportement : ce que fait le jeu, en texte, horodaté.
##   « 2.40 s Drone2 : chase → attack », « 2.61 s Player : touché, vie 2 », « score +100 ».
## Il se branche tout seul sur chaque StateMachine et chaque HealthComponent qui entre dans l'arbre.
## Avec `-- --trace=<fichier>` en argument, il écrit aussi les positions des nœuds du groupe
## « trace » toutes les SAMPLE_PERIOD secondes, puis tout le journal dans le fichier en quittant.

const MAX_LINES := 2000
const SAMPLE_PERIOD := 0.5

var lines: PackedStringArray = []
var file_path: String = ""
var _sample_left: float = SAMPLE_PERIOD


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--trace="):
			file_path = arg.trim_prefix("--trace=")
	get_tree().node_added.connect(_on_node_added)
	EventBus.enemy_killed.connect(func(enemy: Node3D, points: int) -> void: event(enemy, "détruit, score +%d" % points))
	EventBus.player_died.connect(func() -> void: event(self, "joueur mort"))


func event(source: Node, text: String) -> void:
	var line := "%.2f s %s : %s" % [Time.get_ticks_msec() / 1000.0, source.name if source != null else "?", text]
	lines.append(line)
	if lines.size() > MAX_LINES:
		lines = lines.slice(lines.size() - MAX_LINES)


func clear() -> void:
	lines.clear()


func _physics_process(delta: float) -> void:
	if file_path.is_empty():
		return
	_sample_left -= delta
	if _sample_left > 0.0:
		return
	_sample_left = SAMPLE_PERIOD
	for node in get_tree().get_nodes_in_group(&"trace"):
		var body := node as Node3D
		if body != null:
			event(body, "position (%.1f, %.1f)" % [body.global_position.x, body.global_position.z])


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		_write_file()


func _write_file() -> void:
	if file_path.is_empty():
		return
	var f := FileAccess.open(file_path, FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(lines) + "\n")


func _on_node_added(node: Node) -> void:
	var machine := node as StateMachine
	if machine != null:
		machine.state_changed.connect(func(from: StringName, to: StringName) -> void:
			event(machine.get_parent(), "%s → %s" % [from, to]))
		return
	var health := node as HealthComponent
	if health != null:
		health.damaged.connect(func(amount: int, current: int) -> void:
			event(health.get_parent(), "touché -%d, vie %d" % [amount, current]))
