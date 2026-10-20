class_name ItemType extends Resource
## Type d'objet (ressource) : son nom, son icône d'inventaire et la scène créée quand le joueur l'utilise.

## Nom de l'objet.
@export var name : String
## Icône affichée dans la case d'inventaire.
@export var sprite : Texture2D
## Scène créée quand le joueur utilise l'objet (la bombe, par exemple).
@export var scene : PackedScene

## Crée la scène de l'objet à la position du kart de `player` ; un corps rigide est lancé en avant
## et vers le haut, en tournant.
func use(player: Player) -> void:
	#TODO maybe add more modes 	
	var item : Node3D = scene.instantiate()
	
	player.add_child(item)
	item.global_position = player.get_kart_position()
	
	if item is RigidBody3D:
		var dir: Vector3 = player.get_item_direction()
		dir = (dir + Vector3.UP).normalized()
		item.apply_central_impulse(dir * 10)
		
		var up: Vector3 = Vector3.UP
		var side: Vector3 = up.cross(dir)

		if side.length_squared() > 0.001:
			var axis: Vector3 = side.normalized()
			item.angular_velocity = axis * 10.0
		
		item.global_position += dir * 2
