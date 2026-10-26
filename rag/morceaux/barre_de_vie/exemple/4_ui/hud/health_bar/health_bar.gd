class_name HealthBar
extends ProgressBar
## Barre de vie : elle écoute le HealthComponent qu'on lui donne et glisse vers la nouvelle valeur. Elle affiche,
## elle ne décide de rien (aucune lecture à chaque image). Entrées : setup().

## Durée du glissement vers la nouvelle valeur, en secondes (réglée dans la scène du HUD).
@export var slide_duration: float = 0.0

var _tween: Tween


func setup(health: HealthComponent) -> void:
	max_value = health.max_health
	value = health.current_health
	health.damaged.connect(_on_damaged)


func _on_damaged(_amount: int, current: int) -> void:
	if _tween != null:
		_tween.kill()  # un coup pendant le glissement : on repart de la valeur affichée
	_tween = create_tween()
	_tween.tween_property(self, "value", float(current), slide_duration)
