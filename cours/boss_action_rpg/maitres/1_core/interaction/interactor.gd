class_name Interactor extends Area3D
## La main du héros : une zone qui voit ce qui est assez près (Interactable) et retient le plus proche. Elle redit l'invite
## quand ce choix change, ou quand le texte de l'objet change : une bougie soufflée propose de la rallumer.

## L'invite à montrer ; vide : rien à portée.
signal focus_changed(prompt: String)

## Ce que la main actionnerait maintenant, ou null.
var focused: Interactable = null

var _near: Array[Interactable] = []
var _shown: String = ""


func _ready() -> void:
	process_physics_priority = ProcessOrder.COMPONENTS
	collision_layer = 0
	collision_mask = Layers.bit(Layers.INTERACTIONS)
	monitorable = false
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func _physics_process(_delta: float) -> void:
	refresh()


## Choisit l'objet actif le plus proche, et redit l'invite si elle a changé.
func refresh() -> void:
	focused = null
	var nearest: float = INF
	for item: Interactable in _near:
		var distance: float = global_position.distance_squared_to(item.global_position)
		if item.enabled and distance < nearest:
			nearest = distance
			focused = item
	var prompt: String = focused.prompt if focused != null else ""
	if prompt != _shown:
		_shown = prompt
		focus_changed.emit(prompt)


## Actionne ce qui est à portée ; rend faux s'il n'y a rien.
func use_focused() -> bool:
	if focused == null:
		return false
	focused.use()
	return true


func _on_area_entered(area: Area3D) -> void:
	if area is Interactable:
		_near.append(area as Interactable)


func _on_area_exited(area: Area3D) -> void:
	if area is Interactable:
		_near.erase(area as Interactable)
