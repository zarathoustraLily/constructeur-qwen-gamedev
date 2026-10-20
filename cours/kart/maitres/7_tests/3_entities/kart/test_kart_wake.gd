extends GdUnitTestSuite
## Règles du sillage, sur une surface d'eau témoin plate : un kart qui flotte et roule laisse à chaque pas une
## ondulation sous chaque roue, de l'écume sous les deux roues arrière et une vague derrière lui ; arrêté sur
## l'eau, ou roulant sur le sol, il ne laisse rien.

const KART := preload("res://3_entities/kart/kart.tscn")
const SurfaceTemoin := preload("res://7_tests/1_core/water/surface_temoin.gd")

var _surface: WaterSurface
var _kart: Kart


func _frames(count: int) -> void:
	for _frame: int in count:
		await get_tree().physics_frame


## Un kart sans pilote posé sur l'eau témoin, laissé flotter `frames` images.
func _kart_on_water(frames: int) -> void:
	_surface = auto_free(SurfaceTemoin.new())
	add_child(_surface)
	_kart = auto_free(KART.instantiate())
	_kart.input = null
	_kart.position = Vector3(0.0, 0.5, 0.0)
	add_child(_kart)
	await _frames(frames)


## Vide les listes de la surface témoin, puis laisse passer un pas de physique.
func _one_step() -> void:
	for list: Array[Array] in [_surface.get("ondulations"), _surface.get("vagues"), _surface.get("ecume")]:
		list.clear()
	await _frames(1)


func test_en_roulant_sur_l_eau_le_kart_laisse_un_sillage() -> void:
	await _kart_on_water(180)
	_kart.commands.throttle = 1.0
	await _frames(90)
	await _one_step()
	assert_int((_surface.get("ondulations") as Array).size()).is_equal(4)
	assert_int((_surface.get("ecume") as Array).size()).is_equal(2)
	var waves: Array[Array] = _surface.get("vagues")
	assert_int(waves.size()).is_equal(1)
	# La vague part de derrière le kart, à la surface de l'eau.
	var wave_position: Vector3 = waves[0][0]
	var behind := (wave_position - _kart.global_position).dot(_kart.global_basis.z)
	assert_float(behind).is_greater(0.3)
	assert_float(wave_position.y).is_equal_approx(0.0, 0.001)


func test_arrete_sur_l_eau_le_kart_ne_laisse_rien() -> void:
	await _kart_on_water(180)
	await _one_step()
	assert_int((_surface.get("ondulations") as Array).size()).is_equal(0)
	assert_int((_surface.get("vagues") as Array).size()).is_equal(0)


func test_sur_le_sol_le_kart_ne_laisse_rien() -> void:
	_surface = auto_free(SurfaceTemoin.new())
	_surface.set("hauteur", func(_position: Vector3) -> float: return -10.0)
	add_child(_surface)
	var ground := StaticBody3D.new()
	ground.collision_layer = 8
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200.0, 1.0, 200.0)
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(shape)
	add_child(auto_free(ground))
	_kart = auto_free(KART.instantiate())
	_kart.input = null
	_kart.position = Vector3(0.0, 0.6, 0.0)
	add_child(_kart)
	_kart.commands.throttle = 1.0
	await _frames(90)
	await _one_step()
	assert_int((_surface.get("ondulations") as Array).size()).is_equal(0)
