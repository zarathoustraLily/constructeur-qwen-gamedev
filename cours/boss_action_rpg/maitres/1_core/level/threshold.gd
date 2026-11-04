class_name Threshold extends Area3D
## Le seuil d'une salle : le héros qui le passe part vers la salle suivante. Le seuil ne change pas de salle lui-même : il le
## dit, et la salle le répète au jeu.

## Le héros vient de passer vers la salle `path`.
signal crossed(path: String)

## La salle qui suit.
@export_file("*.tscn") var next: String = ""


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.bit(Layers.HERO)
	monitorable = false
	body_entered.connect(_on_body_entered)


func _on_body_entered(_body: Node3D) -> void:
	crossed.emit(next)
