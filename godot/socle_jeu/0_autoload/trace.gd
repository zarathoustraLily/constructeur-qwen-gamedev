extends Node
## Journal de comportement : ce que fait le jeu, en texte, horodaté.
##   « 2.40 s Drone2 : chase → attack », « 2.61 s Player : touché -1, vie 2 ».
## Il se branche tout seul sur chaque StateMachine et chaque HealthComponent qui entre dans l'arbre.
## Avec `-- --trace=<fichier>` en argument, il écrit aussi les positions des nœuds du groupe
## « trace » toutes les SAMPLE_PERIOD secondes, puis tout le journal dans le fichier en quittant.
## Le temps noté est le temps de jeu (images physiques / cadence) : avec --fixed-fps 60 il est exact
## et il correspond à la légende des captures (0_autoload/capture.gd).
## Entrées : event(source, texte), clear(). Dépend de : StateMachine, HealthComponent (1_core).
## Possède : lines. Il est dans le groupe « journal » (la capture le trouve ainsi).

const MAX_LINES := 2000
const SAMPLE_PERIOD := 0.5

var lines: PackedStringArray = []
var file_path: String = ""
var _sample_left: float = SAMPLE_PERIOD
var _watched: Dictionary[int, bool] = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"journal")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--trace="):
			file_path = arg.trim_prefix("--trace=")
	get_tree().node_added.connect(_on_node_added)
	# La scène principale peut entrer dans l'arbre avant ce _ready : on branche aussi ce qui y est déjà.
	_watch_tree(get_tree().root)


func event(source: Node, text: String) -> void:
	var game_time := float(Engine.get_physics_frames()) / Engine.physics_ticks_per_second
	var line := "%.2f s %s : %s" % [game_time, source.name if source != null else "?", text]
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


func _watch_tree(node: Node) -> void:
	_on_node_added(node)
	for child in node.get_children():
		_watch_tree(child)


func _on_node_added(node: Node) -> void:
	if _watched.has(node.get_instance_id()):
		return
	if node is StateMachine or node is HealthComponent:
		_watched[node.get_instance_id()] = true  # un nœud qui sort puis rentre n'est branché qu'une fois
	var machine := node as StateMachine
	if machine != null:
		machine.state_changed.connect(func(from: StringName, to: StringName) -> void:
			event(machine.get_parent(), "%s → %s" % [from, to]))
		return
	var health := node as HealthComponent
	if health != null:
		health.damaged.connect(func(amount: int, current: int) -> void:
			event(health.get_parent(), "touché -%d, vie %d" % [amount, current]))
