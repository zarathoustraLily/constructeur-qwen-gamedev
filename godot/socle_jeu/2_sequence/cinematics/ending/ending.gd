extends Step
## Fin : le score, puis retour au début après rules.ending_duration.
## Dépend de : rules, posé dans ending.tscn ; GameState pour le score.

@export var rules: GameRules

var _time_left: float = 0.0


func _ready() -> void:
	($Ui/Text as Label).text = "Secteur nettoyé\n\nScore %d" % GameState.score
	if rules == null:
		push_error("Ending : rules n'est pas posé dans ending.tscn")
		return
	_time_left = rules.ending_duration


func _physics_process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		set_physics_process(false)
		finish(&"restart")
