class_name HitboxComponent
extends Area3D
## Zone qui porte des coups : au contact d'une HurtboxComponent, elle lui inflige `damage`.
## Émet : hit.

signal hit(hurtbox: HurtboxComponent)

var damage: int = 0


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area3D) -> void:
	var hurtbox := area as HurtboxComponent
	if hurtbox != null and hurtbox.take_hit(damage):
		hit.emit(hurtbox)
