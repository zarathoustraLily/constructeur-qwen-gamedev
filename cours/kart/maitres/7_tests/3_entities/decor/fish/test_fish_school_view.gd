extends GdUnitTestSuite
## Règles des bancs de poissons, au-dessus d'un fond plat à 3 m sous la mer : tous les poissons s'installent
## dans l'eau ; ils nagent entre le fond et la surface ; ils fuient la menace qui s'approche, plus vite ; sans
## eau assez profonde, il n'y a pas de banc ; une même graine, les mêmes bancs.

const SCHOOL := preload("res://3_entities/decor/fish/fish_school.tscn")
const FLOOR_DEPTH := 3.0

var _threat: Node3D


## Un fond plat, sur la couche Terrain, à `depth` mètres sous le niveau de la mer.
func _floor(depth: float) -> void:
	var ground := StaticBody3D.new()
	ground.collision_layer = 8
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200.0, 1.0, 200.0)
	shape.shape = box
	shape.position = Vector3(0.0, -depth - 0.5, 0.0)
	ground.add_child(shape)
	add_child(auto_free(ground))


func _school(random_seed: int = 0) -> FishSchoolView:
	var school := SCHOOL.instantiate() as FishSchoolView
	school.random_seed = random_seed
	_threat = auto_free(Node3D.new())
	_threat.position = Vector3(500.0, 0.0, 500.0)
	add_child(_threat)
	school.threat = _threat
	add_child(auto_free(school))
	return school


func _frames(count: int) -> void:
	for _frame: int in count:
		await get_tree().physics_frame
		await get_tree().process_frame


func test_tous_les_poissons_s_installent_dans_l_eau() -> void:
	_floor(FLOOR_DEPTH)
	var school := _school()
	await _frames(5)
	assert_int(school.fish_in_water()).is_equal(school.fish_count)


func test_ils_nagent_entre_le_fond_et_la_surface() -> void:
	_floor(FLOOR_DEPTH)
	var school := _school()
	await _frames(120)
	for fish: ProceduralFishView in school.get_fish():
		var head := fish.get_head_position()
		assert_float(head.y).is_between(-FLOOR_DEPTH, school.sea_level)


func test_ils_fuient_la_menace_plus_vite() -> void:
	_floor(FLOOR_DEPTH)
	var school := _school()
	await _frames(5)
	var fish := school.get_fish()[0]
	_threat.global_position = fish.get_head_position() + Vector3(1.0, 0.0, 0.0)
	await _frames(1)
	assert_float(fish.desired_speed).is_equal_approx(school.fish_speed * 3.5, 0.0001)
	var away := fish.target_position - fish.get_head_position()
	assert_float(away.x).is_less(0.0)


func test_sans_eau_assez_profonde_pas_de_banc() -> void:
	_floor(10.0)
	var school := _school()
	await _frames(5)
	assert_int(school.fish_in_water()).is_equal(0)


func test_une_meme_graine_les_memes_bancs() -> void:
	_floor(FLOOR_DEPTH)
	var first := _school(5)
	await _frames(5)
	var heads: Array[Vector3] = []
	for fish: ProceduralFishView in first.get_fish():
		heads.append(fish.get_head_position())
	var again := _school(5)
	await _frames(5)
	for index: int in heads.size():
		assert_vector(again.get_fish()[index].get_head_position()).is_equal_approx(heads[index], Vector3.ONE * 0.5)
