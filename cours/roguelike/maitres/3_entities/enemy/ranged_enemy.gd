class_name RangedEnemy extends Enemy
## Un ennemi à distance : il erre, s'arrête, et lance des boules de feu. C'est l'animation de tir qui choisit
## l'instant du lancer : elle émet ranged_attack sur l'emplacement de l'arme, et la boule part de là, dans la
## direction où l'ennemi regarde. Elle ne touche jamais son lanceur.

## La boule de feu lancée.
@export var projectile_scene: PackedScene
## L'emplacement de l'arme, d'où part la boule et dont l'animation émet ranged_attack.
@export var attack_bone: WeaponSlot


func _ready() -> void:
	super._ready()
	if projectile_scene == null or attack_bone == null:
		push_error("RangedEnemy : une dépendance manque (projectile_scene, attack_bone)")
		return
	attack_bone.ranged_attack.connect(_on_ranged_attack)


func _on_ranged_attack() -> void:
	var fireball := projectile_scene.instantiate() as Fireball
	# La boule est top_level : enfant de l'ennemi, elle ne le suit pas.
	add_child(fireball)
	fireball.ignore(self)
	fireball.global_position = attack_bone.global_position
	fireball.global_rotation.y = mesh_mount.global_rotation.y
