class_name AttackComponent extends Node
## Composant d'attaque, enfant du ShapeCast3D qui fait la zone du coup (sur l'arme, ou sur la boule de feu
## elle-même). deal_damage() inflige dégâts et recul à tout ce que la zone touche, une seule fois par coup : une
## cible touchée est exclue de la zone jusqu'à reset_exceptions(), qu'on appelle au début de chaque coup. Il
## cherche chez la cible ses composants par leur nom (HealthComponent, KnockbackComponent). Il ne connaît ni la
## caméra ni les singletons : il émet struck pour chaque cible, et son propriétaire réagit.

## Émis pour chaque cible touchée, après ses dégâts et son recul.
signal struck(target: Object)

## Demande une secousse de la caméra à chaque cible touchée ; la vue du propriétaire la fait, en écoutant struck.
@export var shake_on_damage: bool = false

## Cibles touchées pendant ce coup, exclues de la zone jusqu'à reset_exceptions().
var hit_targets: Array[CollisionObject3D] = []

@onready var _shapecast: ShapeCast3D = get_parent() as ShapeCast3D


func _ready() -> void:
	if _shapecast == null:
		push_error("AttackComponent : le parent doit être un ShapeCast3D")


## Inflige `damage` et le recul `knockback` (en m/s) à chaque cible dans la zone ; rien si la zone est désactivée.
func deal_damage(damage: float, knockback: Vector3) -> void:
	if not _shapecast.enabled:
		return
	_shapecast.force_shapecast_update()
	for index: int in _shapecast.get_collision_count():
		var target := _shapecast.get_collider(index) as CollisionObject3D
		if target == null:
			continue
		var health := target.get_node_or_null(^"HealthComponent") as HealthComponent
		if health != null:
			health.take_damage(damage)
			_shapecast.add_exception(target)
			hit_targets.append(target)
		var knockback_component := target.get_node_or_null(^"KnockbackComponent") as KnockbackComponent
		if knockback_component != null:
			knockback_component.add_knockback(knockback)
		struck.emit(target)


## Rend à nouveau touchables les cibles du coup précédent.
func reset_exceptions() -> void:
	for target: CollisionObject3D in hit_targets:
		if is_instance_valid(target):
			_shapecast.remove_exception(target)
	hit_targets.clear()
