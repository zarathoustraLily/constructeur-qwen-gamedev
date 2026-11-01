extends GdUnitTestSuite
## Règles des particules sur la carte : elles suivent le processeur, dans un courant uniforme comme dans un tourbillon ; toutes bougent, même
## après le premier groupe ; une particule sortie revient à son départ ; chacune vit le nombre de pas demandé ; le tampon d'instances a le
## rangement d'une `MultiMesh`.

const SIZE := 32

var _device: ComputeDevice


func before_test() -> void:
	_device = ComputeDevice.open()


func after_test() -> void:
	_device.release()


func _texture(field: FluidField) -> RID:
	return GridCheck.texture_of(_device, field)


func _uniform(value: float) -> FluidField:
	var field: FluidField = FluidField.new(SIZE, SIZE)
	field.fill(value)
	return field


func _point(tracers: GpuTracers, index: int) -> Vector2:
	_device.finish()
	var values: PackedFloat32Array = _device.read_buffer(tracers.positions)
	return Vector2(values[index * 2], values[index * 2 + 1])


func test_dans_un_courant_uniforme_elle_suit_le_processeur() -> void:
	var u: FluidField = _uniform(4.0)
	var v: FluidField = _uniform(-2.0)
	var tracers: GpuTracers = GpuTracers.new(_device, PackedVector2Array([Vector2(8.0, 20.0)]), SIZE, SIZE)
	tracers.step(_texture(u), _texture(v), 0.5)
	var attendu: Vector2 = Tracer.moved(Vector2(8.0, 20.0), u, v, 0.5)
	assert_vector(_point(tracers, 0)).is_equal_approx(attendu, Vector2(0.001, 0.001))


func test_dans_un_tourbillon_elle_suit_le_processeur() -> void:
	var u: FluidField = FluidField.new(SIZE, SIZE)
	var v: FluidField = FluidField.new(SIZE, SIZE)
	for y: int in SIZE:
		for x: int in SIZE:
			u.put(x, y, -(y - 16.0))
			v.put(x, y, x - 16.0)
	var depart: Vector2 = Vector2(24.0, 16.0)
	var tracers: GpuTracers = GpuTracers.new(_device, PackedVector2Array([depart]), SIZE, SIZE)
	var carte_u: RID = _texture(u)
	var carte_v: RID = _texture(v)
	var attendu: Vector2 = depart
	for _pas: int in 30:
		tracers.step(carte_u, carte_v, 0.05)
		_device.finish()
		attendu = Tracer.moved(attendu, u, v, 0.05)
	assert_vector(_point(tracers, 0)).is_equal_approx(attendu, Vector2(0.01, 0.01))


func test_toutes_les_particules_bougent_meme_apres_le_premier_groupe() -> void:
	var departs: PackedVector2Array = PackedVector2Array()
	for _i: int in GpuTracers.GROUP + 1:
		departs.append(Vector2(4.0, 4.0))
	var tracers: GpuTracers = GpuTracers.new(_device, departs, SIZE, SIZE)
	tracers.step(_texture(_uniform(2.0)), _texture(_uniform(0.0)), 0.5)
	assert_float(_point(tracers, GpuTracers.GROUP).x).is_equal_approx(5.0, 0.001)


func test_une_particule_sortie_revient_a_son_depart() -> void:
	var tracers: GpuTracers = GpuTracers.new(_device, PackedVector2Array([Vector2(30.0, 8.0)]), SIZE, SIZE)
	tracers.step(_texture(_uniform(10.0)), _texture(_uniform(0.0)), 1.0)
	assert_vector(_point(tracers, 0)).is_equal(Vector2(30.0, 8.0))


func test_chaque_particule_vit_le_nombre_de_pas_demande() -> void:
	var departs: PackedVector2Array = PackedVector2Array([Vector2(2.0, 2.0), Vector2(2.0, 4.0), Vector2(2.0, 6.0)])
	var tracers: GpuTracers = GpuTracers.new(_device, departs, SIZE, SIZE, 3)
	var u: RID = _texture(_uniform(1.0))
	var v: RID = _texture(_uniform(0.0))
	tracers.step(u, v, 1.0)
	tracers.step(u, v, 1.0)
	assert_float(_point(tracers, 2).x).is_equal_approx(4.0, 0.001)
	tracers.step(u, v, 1.0)
	assert_float(_point(tracers, 2).x).is_equal_approx(2.0, 0.001)
	assert_float(_point(tracers, 0).x).is_equal_approx(4.0, 0.001)


func test_le_tampon_d_instances_a_le_rangement_d_une_multimesh() -> void:
	var tracers: GpuTracers = GpuTracers.new(_device, PackedVector2Array([Vector2(3.0, 5.0), Vector2(7.0, 9.0)]), SIZE, SIZE)
	var zeros: PackedFloat32Array = PackedFloat32Array()
	zeros.resize(16)
	var tampon: RID = _device.new_buffer(zeros)
	tracers.write_instances(tampon)
	_device.finish()
	var valeurs: PackedFloat32Array = _device.read_buffer(tampon)
	assert_array(Array(valeurs)).is_equal([1.0, 0.0, 0.0, 3.0, 0.0, 1.0, 0.0, 5.0, 1.0, 0.0, 0.0, 7.0, 0.0, 1.0, 0.0, 9.0])
