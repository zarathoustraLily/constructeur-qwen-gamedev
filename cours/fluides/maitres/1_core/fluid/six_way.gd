class_name SixWay extends RefCounted
## Comment six images cuites éclairent une fumée. Le shader `six_way_view.gdshader` fait le même calcul : `first` tient la droite, le haut
## et l'arrière, `second` la gauche, le bas et l'avant.


## Ce qu'un point renvoie d'une lumière venue de `light`, un vecteur de longueur 1 dans le repère de la caméra : y monte, z vient vers la
## caméra. Chaque axe prend l'image de son côté. Les poids sont les carrés de `light` : leur somme fait toujours 1.
static func lit(first: Color, second: Color, light: Vector3) -> float:
	var side: float = first.r if light.x > 0.0 else second.r
	var height: float = first.g if light.y > 0.0 else second.g
	var depth: float = second.b if light.z > 0.0 else first.b
	return light.x * light.x * side + light.y * light.y * height + light.z * light.z * depth
