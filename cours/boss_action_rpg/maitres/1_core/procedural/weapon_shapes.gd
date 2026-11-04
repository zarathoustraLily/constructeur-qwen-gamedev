class_name WeaponShapes extends RefCounted
## Les armes de Bobine : des maillages tournés, faits des restes du géant. Dans le repère d'une arme, la main droite
## tient le point (0, 0, 0), et le canon part vers -Z, à 9 cm au-dessus de la main. La couleur d'un sommet porte sa matière dans
## son alpha, comme celle du corps de Bobine.

## Le bois clair.
const WOOD: Color = Color(0.76, 0.52, 0.31, 1.0)
## Le bois foncé des poignées.
const WOOD_DARK: Color = Color(0.38, 0.22, 0.12, 1.0)
## L'acier du canon.
const STEEL: Color = Color(0.42, 0.44, 0.46, 0.0)
## L'acier noirci du chargeur.
const STEEL_DARK: Color = Color(0.17, 0.17, 0.19, 0.0)
## Le laiton de la bouche.
const BRASS: Color = Color(0.86, 0.70, 0.42, 0.0)
#@ 28+
## Le liège du Bouchon.
const CORK: Color = Color(0.62, 0.45, 0.28, 1.0)
## Le fil de la bobine de l'Aiguille.
const THREAD: Color = Color(0.66, 0.09, 0.07, 0.5)
#@ all
## La hauteur du canon au-dessus de la main.
const BORE: float = 0.092


#@ 28+
## La forme `shape`.
static func build(shape: WeaponKit.Shape) -> ArrayMesh:
	match shape:
		WeaponKit.Shape.CORK:
			return cork()
		WeaponKit.Shape.NEEDLE:
			return needle()
		WeaponKit.Shape.CAPS:
			return caps()
		WeaponKit.Shape.STICK:
			return stick()
	return nailer()


## Le Bouchon : un tube large, et le bouchon de liège qui attend au bout.
static func cork() -> ArrayMesh:
	var b: PuppetBuilder = PuppetBuilder.new()
	b.skinned = false
	_grip(b, WOOD_DARK)
	b.limb(Vector3(0.0, BORE, 0.1), Vector3(0.0, BORE, -0.2), PackedFloat32Array([0.05, 0.075, 0.075, 0.07]), 12, WOOD)
	b.turned(Vector3(0.0, BORE, -0.14), Vector3(0.0, BORE, -0.46), PackedVector2Array([Vector2(0.0, 0.07), Vector2(0.75, 0.066),
			Vector2(0.8, 0.078), Vector2(1.0, 0.078)]), PackedColorArray([BRASS]), 12)
	b.limb(Vector3(0.0, BORE, -0.44), Vector3(0.0, BORE, -0.55), PackedFloat32Array([0.066, 0.07, 0.074]), 12, CORK)
	return b.to_mesh()


## L'Aiguille : une longue aiguille d'acier fine, sur le fil d'une petite bobine.
static func needle() -> ArrayMesh:
	var b: PuppetBuilder = PuppetBuilder.new()
	b.skinned = false
	_grip(b, WOOD_DARK)
	b.turned(Vector3(0.0, BORE, 0.08), Vector3(0.0, BORE, -0.14), PackedVector2Array([Vector2(0.0, 0.068), Vector2(0.14, 0.068),
			Vector2(0.18, 0.05), Vector2(0.82, 0.05), Vector2(0.86, 0.068), Vector2(1.0, 0.068)]),
			PackedColorArray([WOOD, WOOD, THREAD, THREAD, WOOD, WOOD]), 12)
	b.limb(Vector3(0.0, BORE, -0.1), Vector3(0.0, BORE, -0.86), PackedFloat32Array([0.016, 0.014, 0.011, 0.008, 0.003]), 6, STEEL)
	return b.to_mesh()


## La Capsuleuse : un canon court, et une bouche évasée, crantée comme une capsule.
static func caps() -> ArrayMesh:
	var b: PuppetBuilder = PuppetBuilder.new()
	b.skinned = false
	_grip(b, WOOD_DARK)
	b.limb(Vector3(0.0, BORE, 0.12), Vector3(0.0, BORE, -0.14), PackedFloat32Array([0.04, 0.062, 0.062, 0.05]), 10, WOOD_DARK)
	b.turned(Vector3(0.0, BORE, -0.1), Vector3(0.0, BORE, -0.42), PackedVector2Array([Vector2(0.0, 0.042), Vector2(0.6, 0.044),
			Vector2(0.86, 0.076), Vector2(0.94, 0.112), Vector2(1.0, 0.118)]), PackedColorArray([BRASS, BRASS, BRASS, STEEL, STEEL]), 14, false)
	return b.to_mesh()


## La baguette : un rond de bois, qui ne tire pas.
static func stick() -> ArrayMesh:
	var b: PuppetBuilder = PuppetBuilder.new()
	b.skinned = false
	b.limb(Vector3(0.0, BORE, 0.2), Vector3(0.0, BORE, -0.5), PackedFloat32Array([0.022, 0.024, 0.02, 0.012]), 8, WOOD)
	return b.to_mesh()


#@ all
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
