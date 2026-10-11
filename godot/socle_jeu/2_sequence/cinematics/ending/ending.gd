extends Step
## Fin : le score, puis retour au début.

const DURATION := 4.0

var _time_left: float = DURATION


func _ready() -> void:
	($Ui/Text as Label).text = "Secteur nettoyé\n\nScore %d" % GameState.score


func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		set_process(false)
		finish(&"restart")
