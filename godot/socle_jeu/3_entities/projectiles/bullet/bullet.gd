class_name Bullet
extends HitboxComponent
## Projectile : avance tout droit, inflige ses dégâts au premier coup, disparaît au contact
## du décor ou en fin de vie.

var velocity: Vector3 = Vector3.ZERO
var _time_left: float = 1.0


func _ready() -> void:
	super()
	hit.connect(func(_hurtbox: HurtboxComponent) -> void: queue_free())
	body_entered.connect(func(_body: Node3D) -> void: queue_free())


func launch(new_velocity: Vector3, new_damage: int, lifetime: float) -> void:
	velocity = new_velocity
	damage = new_damage
	_time_left = lifetime


func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	_time_left -= delta
	if _time_left <= 0.0:
		queue_free()
