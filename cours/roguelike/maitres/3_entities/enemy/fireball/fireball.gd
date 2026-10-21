class_name Fireball extends ShapeCast3D
## Une boule de feu : elle file tout droit, vers son +Z, blesse et repousse ce qu'elle touche, et à son premier
## choc (une cible, un mur) laisse un impact et disparaît. Au bout de sa durée de vie, elle s'éteint. Sa forme
## de collision la suit (un ShapeCast3D sans portée) : elle se teste là où elle est.

## Réglages de la boule (5_data/enemies/attacks/fireball.tres).
@export var settings: ProjectileSettings
## L'impact laissé au choc.
@export var impact_scene: PackedScene

@onready var _attack: AttackComponent = $AttackComponent
@onready var _lifetime: Timer = $Lifetime


func _ready() -> void:
	if settings == null or impact_scene == null:
		push_error("Fireball : une dépendance manque (settings, impact_scene)")
		set_physics_process(false)
		return
	_lifetime.timeout.connect(queue_free)
	_lifetime.start(settings.lifetime)


## Ne touche jamais `shooter`, celui qui la lance.
func ignore(shooter: CollisionObject3D) -> void:
	add_exception(shooter)


func _physics_process(delta: float) -> void:
	global_position += global_basis.z * settings.speed * delta
	_attack.deal_damage(settings.damage, global_basis.z * settings.knockback)
	if is_colliding():
		var impact := impact_scene.instantiate() as Node3D
		get_parent().add_child(impact)
		impact.global_position = global_position
		queue_free()
