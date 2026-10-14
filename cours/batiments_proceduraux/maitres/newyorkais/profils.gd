@tool
extends RefCounted
## Profils de la tour new-yorkaise : des contours fermés, prêts à être extrudés.
## {STATUS}
##
## La tour de brique du cours n'a que deux moulures, horizontales : le chaperon de pierre qui
## coiffe chaque parapet, et un bandeau en gradins au-dessus du socle. Sa tour de verre de 1961
## n'en a que de verticales : des ailettes de métal, un profilé en T posé devant chaque meneau,
## du pied au sommet. Sa tour tout en verre n'a presque plus rien : son verre affleure, seul son
## parapet garde un chaperon de métal.
##
## Ce script ne dessine que les sections : des listes de points en deux dimensions, comme une
## coupe sur du papier millimétré. C'est MeshBuilder.extrude() qui en fait des volumes.
##
## Convention : x est la saillie vers le dehors (0 au nu du mur, ou du verre) ; y est la
## hauteur pour une moulure horizontale, la largeur pour une ailette verticale. Les cotes sont
## plausibles ; elles ne sont pas relevées sur une tour réelle.
##
## Toutes les fonctions sont « static » : on les appelle sans créer d'objet,
## par exemple Profiles.coping(0.35, 0.16, 0.15).


## Chaperon : la pierre plate (ou la tôle) qui coiffe un parapet de « thickness » d'épaisseur.
## Il déborde de « overhang » de chaque côté, avec une goutte d'eau dessous, pour que la pluie
## tombe loin du mur ; son dessus penche vers le toit.
static func coping(thickness: float, overhang: float, height: float) -> PackedVector2Array:
	var back: float = -thickness - overhang
	var drip: float = minf(0.03, 0.25 * overhang)
	return PackedVector2Array([
		Vector2(overhang, -0.02), Vector2(overhang, height), Vector2(back, 0.8 * height), Vector2(back, -0.02),
		Vector2(back + drip, -0.02), Vector2(back + drip, 0.0), Vector2(overhang - drip, 0.0), Vector2(overhang - drip, -0.02),
	])


## Bandeau en gradins : trois marches qui avancent chacune un peu plus que celle du dessous,
## jusqu'à « depth », sur « height » de haut. Des arêtes vives, pas de courbes, à la manière
## Art déco.
static func stepped_band(height: float, depth: float) -> PackedVector2Array:
	var step: float = height / 3.0
	return PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.4 * depth, 0.0), Vector2(0.4 * depth, step), Vector2(0.7 * depth, step),
		Vector2(0.7 * depth, 2.0 * step), Vector2(depth, 2.0 * step), Vector2(depth, height), Vector2(0.0, height),
	])


## Ailette : un profilé en T vu en coupe, posé devant un meneau. Son âme, mince, part du verre
## et avance de « depth » ; son aile, large de « flange », la termine. y est centré sur le
## meneau.
static func fin(depth: float, flange: float) -> PackedVector2Array:
	var web: float = 0.012
	var plate: float = 0.016
	return PackedVector2Array([
		Vector2(0.0, -0.5 * web), Vector2(depth - plate, -0.5 * web), Vector2(depth - plate, -0.5 * flange),
		Vector2(depth, -0.5 * flange), Vector2(depth, 0.5 * flange), Vector2(depth - plate, 0.5 * flange),
		Vector2(depth - plate, 0.5 * web), Vector2(0.0, 0.5 * web),
	])
