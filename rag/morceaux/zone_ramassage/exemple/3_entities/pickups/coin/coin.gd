class_name Coin
extends Area3D
## Pièce à ramasser : seul le joueur la ramasse. Couches et masque sont posés dans coin.tscn : la zone surveille la
## couche « joueur » (masque) et n'est elle-même sur aucune couche. Émet : collected (le niveau compte le score, la vue
## joue le son).

signal collected


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(_body: Node3D) -> void:
	collected.emit()
	queue_free()
