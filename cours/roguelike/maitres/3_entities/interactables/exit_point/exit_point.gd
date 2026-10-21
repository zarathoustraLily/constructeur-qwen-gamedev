class_name ExitPoint extends Node3D
## La sortie du niveau. Invisible et fermée au départ ; unlock() l'ouvre et la montre. Le joueur (le nœud du
## groupe « player ») qui y entre, sortie ouverte, la referme, joue l'animation « Exit » (la colonne de lumière
## se remplit, un anneau s'élève) et la signale (reached), une seule fois ; l'animation finie, elle se cache. Elle
## ne connaît pas la classe du joueur.

## Émis quand le joueur atteint la sortie ouverte.
signal reached

## Vrai tant que la sortie est fermée.
var locked: bool = true

@onready var _animation: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	visible = false
	($Area3D as Area3D).body_entered.connect(_on_body_entered)
	_animation.animation_finished.connect(_on_animation_finished)


## Ouvre et montre la sortie.
func unlock() -> void:
	_animation.play(&"RESET")
	visible = true
	locked = false


func _on_body_entered(body: Node3D) -> void:
	if locked or not body.is_in_group(&"player"):
		return
	locked = true
	_animation.play(&"Exit")
	reached.emit()


func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == &"Exit":
		visible = false
