@tool
extends RefCounted
## Profils des pièces de métal plié : des contours fermés, prêts à être extrudés.
## {STATUS}
##
## Une couvertine, un auvent, un appui de fenêtre : ce sont des tôles pliées, toujours la même
## section d'un bout à l'autre. Ce script ne dessine que la section : une liste de points en
## deux dimensions, comme une coupe sur du papier millimétré. C'est MeshBuilder.extrude() qui
## en fait un volume, et MeshBuilder.sweep() qui la fait tourner le long d'un arc (le coude
## d'un tuyau).
##
## Convention : x est la saillie vers la rue (0 au nu du mur), y la hauteur. Les cotes sont
## plausibles ; elles ne sont pas relevées sur un catalogue.
##
## Toutes les fonctions sont « static » : on les appelle sans créer d'objet,
## par exemple Profiles.coping(0.2, 0.03, 0.05).


## Couvertine : le chapeau de tôle qui coiffe un acrotère de « thickness » d'épaisseur. Elle
## déborde de « overhang » de chaque côté et retombe en goutte d'eau. Le dessus penche vers
## le toit, pour que la pluie ne coule pas sur la façade.
static func coping(thickness: float, overhang: float, height: float) -> PackedVector2Array:
	var back: float = -thickness - overhang
	return PackedVector2Array([
		Vector2(overhang, -0.035), Vector2(overhang, height), Vector2(back, 0.7 * height), Vector2(back, -0.035),
		Vector2(back + 0.012, -0.035), Vector2(back + 0.012, 0.0), Vector2(overhang - 0.012, 0.0), Vector2(overhang - 0.012, -0.035),
	])


## Auvent : une dalle mince qui avance de « depth », avec un relevé au nez et une légère pente
## vers la rue.
static func canopy(depth: float, thickness: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(depth, -0.03), Vector2(depth, thickness + 0.05), Vector2(depth - 0.03, thickness + 0.05),
		Vector2(depth - 0.03, thickness - 0.01), Vector2(0.0, thickness + 0.02),
	])


## Appui de fenêtre en aluminium : une tôle en pente, pliée en goutte d'eau au nez.
static func sill(depth: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(depth, -0.012), Vector2(depth, -0.04), Vector2(depth - 0.006, -0.04),
		Vector2(depth - 0.006, -0.02), Vector2(0.0, -0.008),
	])


## Section ronde d'un tuyau ou d'une main courante, centrée sur l'origine.
static func circle(radius: float, steps: int = 10) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for index: int in range(steps):
		var angle: float = TAU * float(index) / float(steps)
		points.append(Vector2(radius * cos(angle), radius * sin(angle)))
	return points
