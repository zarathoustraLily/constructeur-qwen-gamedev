class_name WeaponShapes extends RefCounted
## Les armes de Bobine : des maillages tournés, faits des restes du géant. Dans le repère d'une arme, la main droite
## tient le point (0, 0, 0), et le canon part vers -Z, à 9 cm au-dessus de la main.

## Le bois clair.
const WOOD: Color = BobineBody.WOOD
## Le bois foncé des poignées.
const WOOD_DARK: Color = BobineBody.WOOD_DARK
## L'acier du canon.
const STEEL: Color = Color(0.42, 0.44, 0.46, 0.0)
## L'acier noirci du chargeur.
const STEEL_DARK: Color = Color(0.17, 0.17, 0.19, 0.0)
## Le laiton de la bouche.
const BRASS: Color = BobineBody.BRASS
## La hauteur du canon au-dessus de la main.
const BORE: float = 0.092


## La Cloueuse : un bloc de bois, un long canon d'acier, un chargeur de clous.
static func nailer() -> ArrayMesh:
	var b: PuppetBuilder = PuppetBuilder.new()
	b.skinned = false
	_grip(b, WOOD_DARK)
	b.limb(Vector3(0.0, BORE, 0.13), Vector3(0.0, BORE, -0.17), PackedFloat32Array([0.04, 0.066, 0.066, 0.05]), 10, WOOD)
	b.limb(Vector3(0.0, BORE, -0.1), Vector3(0.0, BORE, -0.6), PackedFloat32Array([0.03, 0.028, 0.024, 0.024]), 8, STEEL)
	b.limb(Vector3(0.0, BORE, -0.55), Vector3(0.0, BORE, -0.6), PackedFloat32Array([0.036, 0.036]), 8, BRASS)
	b.limb(Vector3(0.0, 0.05, -0.12), Vector3(0.0, -0.08, -0.13), PackedFloat32Array([0.03, 0.03]), 8, STEEL_DARK)
	return b.to_mesh()


## La poignée sous la main droite, et celle que tient la main gauche.
static func _grip(b: PuppetBuilder, color: Color) -> void:
	b.limb(Vector3(0.0, 0.07, 0.02), Vector3(0.0, -0.13, 0.07), PackedFloat32Array([0.03, 0.034, 0.03]), 8, color)
	b.limb(Vector3(0.0, 0.07, -0.33), Vector3(0.0, -0.07, -0.33), PackedFloat32Array([0.022, 0.024, 0.02]), 8, color)
