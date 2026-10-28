class_name Galaxy extends RefCounted
## Une galaxie spirale : chaque étoile est tirée sur un des bras, à une distance du centre, puis l'angle du bras
## s'enroule avec la distance (spirale) et l'étoile s'écarte un peu de son bras ; les étoiles du cœur sont chaudes,
## celles du bord froides. Le tout se dessine en un seul MultiMesh coloré.


## L'angle (radians) du bras `arm` à la distance relative `t` (0 : centre, 1 : bord) : les bras partent à
## intervalles égaux et s'enroulent de `winding` tours jusqu'au bord.
static func arm_angle(arm: int, t: float, settings: GalaxySettings) -> float:
	return TAU * float(arm) / float(settings.arms) + TAU * settings.winding * t


## Les positions des étoiles, tirées avec la graine : distance (plus d'étoiles près du centre : t au carré), bras,
## écart au bras et hauteur dans le disque.
static func star_positions(settings: GalaxySettings) -> PackedVector3Array:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = settings.random_seed
	var points: PackedVector3Array = PackedVector3Array()
	for i: int in settings.star_count:
		var t: float = rng.randf() * rng.randf()
		var angle: float = arm_angle(i % settings.arms, t, settings)
		var distance: float = t * settings.radius
		var offset: Vector2 = Vector2(rng.randfn(0.0, 1.0), rng.randfn(0.0, 1.0)) * settings.arm_spread * settings.radius
		points.append(Vector3(cos(angle) * distance + offset.x, rng.randf_range(-1.0, 1.0) * settings.thickness * (1.0 - t),
			sin(angle) * distance + offset.y))
	return points


## La couleur d'une étoile à `distance` mètres du centre : du cœur vers le bord.
static func star_color(distance: float, settings: GalaxySettings) -> Color:
	return settings.core_color.lerp(settings.edge_color, clampf(distance / settings.radius, 0.0, 1.0))


## Le MultiMesh des étoiles : une petite sphère par étoile, chacune de sa couleur.
static func build(settings: GalaxySettings) -> MultiMesh:
	var star: SphereMesh = SphereMesh.new()
	star.radius = 0.15
	star.height = 0.3
	star.radial_segments = 6
	star.rings = 3
	var transforms: Array[Transform3D] = []
	var colors: PackedColorArray = PackedColorArray()
	for point: Vector3 in star_positions(settings):
		transforms.append(Transform3D(Basis.IDENTITY, point))
		colors.append(star_color(Vector2(point.x, point.z).length(), settings))
	return Scatter.multimesh(star, transforms, colors)
