class_name Scatter extends RefCounted
## Répartir des objets au hasard, mais avec une graine (le même résultat à chaque fois), et les dessiner en un seul
## lot : un MultiMesh dessine des milliers de copies d'un maillage en un seul appel de dessin, là où autant de
## MeshInstance3D en feraient autant d'appels.


## `count` points répartis uniformément dans un disque de rayon `radius` : le rayon tiré est la racine d'un tirage
## uniforme, sans quoi les points s'entasseraient au centre.
static func points_in_disc(count: int, radius: float, random_seed: int) -> PackedVector2Array:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = random_seed
	var points: PackedVector2Array = PackedVector2Array()
	for _i: int in count:
		var r: float = radius * sqrt(rng.randf())
		var angle: float = rng.randf() * TAU
		points.append(Vector2(cos(angle), sin(angle)) * r)
	return points


## Un MultiMesh qui dessine `mesh` à chaque transformation de `transforms` ; avec `colors`, une couleur par copie.
static func multimesh(mesh: Mesh, transforms: Array[Transform3D], colors: PackedColorArray = PackedColorArray()) -> MultiMesh:
	var batch: MultiMesh = MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_colors = not colors.is_empty()
	batch.mesh = mesh
	batch.instance_count = transforms.size()
	for i: int in transforms.size():
		batch.set_instance_transform(i, transforms[i])
		if batch.use_colors:
			batch.set_instance_color(i, colors[i])
	return batch


## Les transformations des bouffées d'un champ de nuages : chaque point du disque à une hauteur et une taille tirées
## dans leurs bornes, avec la même graine.
static func cloud_puffs(count: int, radius: float, height: Vector2, size: Vector2, random_seed: int) -> Array[Transform3D]:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = random_seed + 1
	var result: Array[Transform3D] = []
	for point: Vector2 in points_in_disc(count, radius, random_seed):
		var scale_factor: float = rng.randf_range(size.x, size.y)
		var origin: Vector3 = Vector3(point.x, rng.randf_range(height.x, height.y), point.y)
		result.append(Transform3D(Basis.from_scale(Vector3.ONE * scale_factor), origin))
	return result
