class_name PuppetBuilder extends MeshBuilder
## L'outil de maillage d'un pantin. Un pantin ne se déforme pas : ses pièces rigides tournent à leurs rotules. Chaque
## sommet suit donc un seul os, celui qui est posé quand on l'ajoute (`bone`). Il porte aussi des coordonnées de texture
## prises le long de sa pièce : le fil du bois suit le membre et ne glisse pas quand le membre bouge.
## Sa forme propre est la pièce tournée (`turned`) : un profil de rayons le long d'un axe, comme au tour à bois.

## Les coordonnées de texture par mètre.
const UV_PER_METER: float = 2.0

## L'os des sommets qui viennent.
var bone: int = 0
## Le repère des sommets qui viennent : son axe Y suit le fil du bois.
var grain: Basis = Basis.IDENTITY
## Faux pour une pièce qui ne suit aucun squelette (une arme posée) : le maillage n'a alors ni os ni poids.
var skinned: bool = true
## Les coordonnées de texture.
var uvs: PackedVector2Array = PackedVector2Array()
## Les os, quatre par sommet.
var bones: PackedInt32Array = PackedInt32Array()
## Les poids, quatre par sommet.
var weights: PackedFloat32Array = PackedFloat32Array()


## Ajoute un sommet, lié à l'os `bone` ; rend son indice.
func add_vertex(position: Vector3, color: Color) -> int:
	var along: Vector3 = grain.transposed() * position
	uvs.append(Vector2(along.x + along.z, along.y) * UV_PER_METER)
	for k: int in 4:
		bones.append(bone if k == 0 else 0)
		weights.append(1.0 if k == 0 else 0.0)
	return super(position, color)


## Une pièce tournée de `from` à `to` : `profile[i]` vaut (part de la longueur, rayon), `tints[i]` la couleur de cet
## anneau (le dernier ton vaut pour les anneaux suivants). `capped` ferme ses deux bouts à plat ; une jupe reste ouverte.
func turned(from: Vector3, to: Vector3, profile: PackedVector2Array, tints: PackedColorArray, sides: int,
		capped: bool = true) -> void:
	var axis: Vector3 = from.direction_to(to)
	var side: Vector3 = _perpendicular(axis)
	var other: Vector3 = axis.cross(side)
	grain = Basis(side, axis, other)
	begin_part()
	var first: int = vertices.size()
	var rings: int = profile.size()
	for ring: int in rings:
		var center: Vector3 = from.lerp(to, profile[ring].x)
		for k: int in sides:
			var angle: float = TAU * k / sides
			add_vertex(center + (side * cos(angle) + other * sin(angle)) * profile[ring].y, tints[mini(ring, tints.size() - 1)])
	for ring: int in rings - 1:
		stitch(first + ring * sides, first + (ring + 1) * sides, sides, true)
	if capped:
		fan(add_vertex(from.lerp(to, profile[0].x), tints[0]), first, sides, false)
		var last: Vector3 = from.lerp(to, profile[rings - 1].x)
		fan(add_vertex(last, tints[mini(rings - 1, tints.size() - 1)]), first + (rings - 1) * sides, sides, true)
	end_part()


## Partage le sommet `index` avec l'os `other`, qui en prend le poids `weight` : un tissu suit plusieurs os. L'os posé à son
## ajout rend ce poids ; il en faut encore à sa première place.
func share(index: int, other: int, weight: float) -> void:
	var slot: int = 1
	while weights[index * 4 + slot] > 0.0:
		slot += 1
	bones[index * 4 + slot] = other
	weights[index * 4 + slot] = weight
	weights[index * 4] -= weight


## Un membre : une pièce tournée de rayons `radii`, régulièrement espacés de `from` à `to`, d'une seule couleur.
func limb(from: Vector3, to: Vector3, radii: PackedFloat32Array, sides: int, color: Color) -> void:
	var profile: PackedVector2Array = PackedVector2Array()
	for i: int in radii.size():
		profile.append(Vector2(float(i) / (radii.size() - 1), radii[i]))
	turned(from, to, profile, PackedColorArray([color]), sides)


## Une boule, le long du fil présent.
func ball(center: Vector3, radii: Vector3, color: Color) -> void:
	begin_part()
	ellipsoid(center, radii, 7, 10, color)
	end_part()


## Le maillage : une surface de triangles, avec ses coordonnées de texture, et ses os si elle suit un squelette.
func to_mesh() -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	if skinned:
		arrays[Mesh.ARRAY_BONES] = bones
		arrays[Mesh.ARRAY_WEIGHTS] = weights
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
