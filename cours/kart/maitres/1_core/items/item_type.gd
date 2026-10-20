class_name ItemType extends Resource
## Un type d'objet : son nom, son icône d'inventaire, et la façon de lancer ce qu'il crée. Les objets vivent dans
## des .tres de 5_data (5_data/items/bomb.tres) ; la scène créée par chacun est donnée par la séquence qui les
## emploie : une donnée ne connaît pas les acteurs (règle des dossiers).

## Nom de l'objet.
@export var display_name: String = ""
## Icône de la case d'inventaire.
@export var icon: Texture2D
## Impulsion donnée à un objet qui est un corps rigide, vers l'avant et vers le haut.
@export_custom(PROPERTY_HINT_NONE, "suffix:N·s") var throw_impulse: float = 0.0
## Distance (m) du point de départ de l'objet devant son lanceur.
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var throw_offset: float = 0.0
## Vitesse de rotation (rad/s) de l'objet lancé, autour de l'axe de côté.
@export_custom(PROPERTY_HINT_NONE, "suffix:rad/s") var throw_spin: float = 0.0


## Crée `scene` sous `parent`, en `origin`, lancée vers `direction` (à l'horizontale) selon cet objet ; rend le
## nœud créé. Un corps rigide part en avant et vers le haut, en tournant.
func launch(scene: PackedScene, parent: Node, origin: Vector3, direction: Vector3) -> Node3D:
	var item := scene.instantiate() as Node3D
	parent.add_child(item)
	var aim := (direction.normalized() + Vector3.UP).normalized()
	item.global_position = origin + aim * throw_offset
	var body := item as RigidBody3D
	if body != null:
		body.apply_central_impulse(aim * throw_impulse)
		var side := Vector3.UP.cross(aim)
		if side.length_squared() > 0.001:
			body.angular_velocity = side.normalized() * throw_spin
	return item
