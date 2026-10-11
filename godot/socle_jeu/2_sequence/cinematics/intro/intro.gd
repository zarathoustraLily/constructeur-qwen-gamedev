extends Step
## Cinématique d'introduction : un texte, puis la suite après rules.intro_duration (Entrée pour passer).
## Dépend de : rules, posé dans intro.tscn.

@export var rules: GameRules

var _time_left: float = 0.0


func _ready() -> void:
	if rules == null:
		push_error("Intro : rules n'est pas posé dans intro.tscn")
		return
	_time_left = rules.intro_duration


func _physics_process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		set_physics_process(false)
		finish()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_accept") and is_physics_processing():
		set_physics_process(false)
		finish()
