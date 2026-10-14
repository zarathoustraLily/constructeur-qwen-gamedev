@tool
extends RefCounted
## Profils de moulures : des contours fermés, prêts à être extrudés.
## {STATUS}
##
## Une moulure, c'est une section qu'on fait glisser le long d'une ligne. Ce script ne dessine
## que la section : une liste de points en deux dimensions, comme une coupe sur du papier
## millimétré. C'est MeshBuilder.extrude() qui en fait un volume.
##
## Convention : x est la saillie par rapport au nu du mur (0 contre le mur), y la hauteur à
## partir du bas de la moulure. Les proportions sont celles qu'on lit sur une façade
## haussmannienne ordinaire ; elles ne sont pas relevées sur un immeuble précis.
##
## Toutes les fonctions sont « static » : on les appelle sans créer d'objet,
## par exemple Profiles.cornice(0.5, 0.6).

const ARC_STEPS: int = 6


## Bandeau filant entre deux niveaux : cavet, plate-bande, quart-de-rond, filet.
static func string_course(height: float, depth: float) -> PackedVector2Array:
	var points: PackedVector2Array = [Vector2(0.0, 0.0), Vector2(0.3 * depth, 0.0)]
	_quarter(points, Vector2(0.3 * depth, 0.0), Vector2(0.72 * depth, 0.32 * height), false)
	points.append(Vector2(0.72 * depth, 0.7 * height))
	_quarter(points, Vector2(0.72 * depth, 0.7 * height), Vector2(depth, 0.88 * height), true)
	points.append(Vector2(depth, height))
	points.append(Vector2(0.0, height + 0.012))
	return points


## Corniche de couronnement : quart-de-rond, bande des denticules, larmier, doucine, filet.
static func cornice(height: float, depth: float) -> PackedVector2Array:
	var points: PackedVector2Array = [Vector2(0.0, 0.0), Vector2(0.08 * depth, 0.0)]
	_quarter(points, Vector2(0.08 * depth, 0.0), Vector2(0.26 * depth, 0.2 * height), true)
	points.append(Vector2(0.26 * depth, 0.44 * height))
	# Sous-face du larmier, avec sa goutte d'eau.
	points.append(Vector2(0.7 * depth, 0.44 * height))
	points.append(Vector2(0.7 * depth, 0.4 * height))
	points.append(Vector2(0.78 * depth, 0.4 * height))
	points.append(Vector2(0.78 * depth, 0.68 * height))
	# Doucine : bombée en bas, creuse en haut.
	_quarter(points, Vector2(0.78 * depth, 0.68 * height), Vector2(0.9 * depth, 0.81 * height), true)
	_quarter(points, Vector2(0.9 * depth, 0.81 * height), Vector2(depth, 0.93 * height), false)
	points.append(Vector2(depth, height))
	points.append(Vector2(0.0, height))
	return points


## Chambranle : ici x part du bord de la baie et s'en éloigne, y est la saillie.
static func architrave(width: float, depth: float) -> PackedVector2Array:
	var points: PackedVector2Array = [
		Vector2(0.0, 0.0), Vector2(0.0, 0.45 * depth), Vector2(0.48 * width, 0.45 * depth),
		Vector2(0.48 * width, 0.7 * depth), Vector2(0.76 * width, 0.7 * depth),
	]
	_quarter(points, Vector2(0.76 * width, 0.7 * depth), Vector2(0.92 * width, depth), true)
	points.append(Vector2(width, depth))
	points.append(Vector2(width, 0.0))
	return points


## Appui de fenêtre, au nez arrondi.
static func sill(height: float, depth: float) -> PackedVector2Array:
	var points: PackedVector2Array = [Vector2(0.0, 0.0), Vector2(0.7 * depth, 0.0)]
	_quarter(points, Vector2(0.7 * depth, 0.0), Vector2(depth, 0.55 * height), true)
	points.append(Vector2(depth, height))
	points.append(Vector2(0.0, height + 0.01))
	return points


## Console en S : ici x est la saillie et y la hauteur, la console s'extrude dans son épaisseur.
static func console(height: float, depth: float) -> PackedVector2Array:
	var points: PackedVector2Array = [Vector2(0.0, 0.0)]
	var start: Vector2 = Vector2(0.14 * depth, 0.0)
	var control_a: Vector2 = Vector2(0.14 * depth, 0.5 * height)
	var control_b: Vector2 = Vector2(depth, 0.3 * height)
	var end: Vector2 = Vector2(depth, 0.84 * height)
	for step: int in range(13):
		points.append(start.bezier_interpolate(control_a, control_b, end, float(step) / 12.0))
	points.append(Vector2(depth, height))
	points.append(Vector2(0.0, height))
	return points


## Clef d'arc ou de linteau : un trapèze plus large en haut, vu de face (x horizontal, y vertical).
static func keystone(bottom_width: float, top_width: float, height: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-0.5 * bottom_width, 0.0), Vector2(0.5 * bottom_width, 0.0),
		Vector2(0.5 * top_width, height), Vector2(-0.5 * top_width, height),
	])


#@ 9+
## Contour d'une baie à linteau en arc d'ellipse, vu de face : x de -half_width à +half_width,
## y de 0 au sommet. « rise » est la flèche de l'arc ; 0 donne un rectangle, « height » une
## demi-ellipse.
static func arched_outline(half_width: float, height: float, rise: float, steps: int = 20) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var spring: float = height - rise
	if rise <= 0.001:
		points.append(Vector2(half_width, height))
		points.append(Vector2(-half_width, height))
	else:
		for step: int in range(steps + 1):
			var angle: float = PI * float(step) / float(steps)
			points.append(Vector2(half_width * cos(angle), spring + rise * sin(angle)))
	if spring > 0.001:
		points.append(Vector2(-half_width, 0.0))
		points.append(Vector2(half_width, 0.0))
	return points


## Rectangle centré en x, posé sur y = 0.
static func rectangle(width: float, height: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-0.5 * width, 0.0), Vector2(0.5 * width, 0.0),
		Vector2(0.5 * width, height), Vector2(-0.5 * width, height),
	])


#@ all
## Quart d'ellipse de « from » à « to ». Bombé vers l'extérieur si « convex », creusé sinon.
## Le point de départ est supposé déjà présent dans « points ».
static func _quarter(points: PackedVector2Array, from: Vector2, to: Vector2, convex: bool) -> void:
	var center: Vector2 = Vector2(from.x, to.y) if convex else Vector2(to.x, from.y)
	for step: int in range(1, ARC_STEPS + 1):
		var angle: float = 0.5 * PI * float(step) / float(ARC_STEPS)
		if convex:
			points.append(Vector2(center.x + (to.x - from.x) * sin(angle), center.y - (to.y - from.y) * cos(angle)))
		else:
			points.append(Vector2(center.x - (to.x - from.x) * cos(angle), center.y + (to.y - from.y) * sin(angle)))
