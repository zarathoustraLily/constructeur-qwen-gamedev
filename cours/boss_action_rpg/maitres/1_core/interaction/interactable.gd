class_name Interactable extends Area3D
## Ce qu'on actionne à la main : une zone sur la couche des interactions, que la main du héros (Interactor) voit quand il
## passe assez près. Elle ne sait pas ce qu'elle déclenche : celui qui la porte écoute `used`.

## Le joueur vient de l'actionner.
signal used

## Ce que dit l'invite quand la main est assez près : « Souffler la bougie ».
@export var prompt: String = ""
## Faux : la main ne la voit plus (une porte déjà ouverte).
@export var enabled: bool = true


func _ready() -> void:
	collision_layer = Layers.bit(Layers.INTERACTIONS)
	collision_mask = 0
	monitoring = false


## L'actionne, si elle est active.
func use() -> void:
	if enabled:
		used.emit()
