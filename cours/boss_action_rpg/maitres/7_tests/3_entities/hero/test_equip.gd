extends GdUnitTestSuite
## Règles d'une arme prise : le héros reçoit ses réglages et repart à froid ; il le dit ; il n'est plus désarmé ; la forme
## en main change, et la bouche suit. Un tir à plusieurs projectiles en lance autant ; le premier part droit, les autres à
## l'écart voulu ; sans assez de projectiles prêts, le tir ne part pas.

const HERO := preload("res://3_entities/hero/hero.tscn")
const SHOT := preload("res://3_entities/hero/hero_shot.tscn")
const CAPS := preload("res://5_data/weapons/caps.tres")
const CORK := preload("res://5_data/weapons/cork.tres")


func _hero(pool_size: int = 16) -> Hero:
	var pool: ProjectilePool = auto_free(ProjectilePool.new())
	pool.scene = SHOT
	pool.size = pool_size
	add_child(pool)
	var hero: Hero = auto_free(HERO.instantiate())
	hero.projectiles = pool
	hero.unarmed = true
	add_child(hero)
	hero.get_node("Input").free()
	return hero


func test_il_recoit_ses_reglages_et_repart_a_froid() -> void:
	var hero: Hero = _hero()
	hero.gun.heat.add(100.0)
	assert_bool(hero.gun.heat.is_overheated).is_true()
	hero.equip(CORK)
	assert_that(hero.gun.settings).is_same(CORK.gun)
	assert_that(hero.gun.heat.settings).is_same(CORK.heat)
	assert_float(hero.gun.heat.heat).is_equal(0.0)
	assert_bool(hero.gun.heat.is_overheated).is_false()


func test_il_le_dit_et_n_est_plus_desarme() -> void:
	var hero: Hero = _hero()
	var said: Array[WeaponKit] = []
	hero.weapon_changed.connect(func(kit: WeaponKit) -> void: said.append(kit))
	hero.equip(CORK)
	assert_array(said).contains_exactly([CORK])
	assert_bool(hero.unarmed).is_false()


func test_la_forme_en_main_change_et_la_bouche_suit() -> void:
	var hero: Hero = _hero()
	var model: Node3D = hero.get_node("View/Model") as Node3D
	var mesh: MeshInstance3D = model.get_node(^"%WeaponMesh") as MeshInstance3D
	var old_tip: float = mesh.mesh.get_aabb().position.z
	hero.equip(CORK)
	assert_float(mesh.mesh.get_aabb().position.z).is_not_equal(old_tip)
	assert_float((model.get_node(^"%Muzzle") as Marker3D).position.z).is_equal_approx(mesh.mesh.get_aabb().position.z, 0.001)


func test_un_tir_a_plusieurs_projectiles_en_lance_autant() -> void:
	var hero: Hero = _hero()
	hero.equip(CAPS)
	var ready_shots: int = hero.projectiles.available()
	assert_bool(hero.gun.pull(Vector3(0.0, 1.0, -30.0))).is_true()
	assert_int(hero.projectiles.available()).is_equal(ready_shots - CAPS.gun.pellets)


func test_le_premier_part_droit_et_les_autres_a_l_ecart_voulu() -> void:
	var hero: Hero = _hero()
	hero.equip(CAPS)
	var direction: Vector3 = Vector3.FORWARD
	assert_vector(hero.gun.scattered(direction, 0)).is_equal(direction)
	for pellet: int in range(1, CAPS.gun.pellets):
		var angle: float = rad_to_deg(direction.angle_to(hero.gun.scattered(direction, pellet)))
		assert_float(angle).is_equal_approx(CAPS.gun.spread_degrees, 0.01)


func test_sans_assez_de_projectiles_prets_le_tir_ne_part_pas() -> void:
	var hero: Hero = _hero(4)
	hero.equip(CAPS)
	assert_bool(hero.gun.pull(Vector3(0.0, 1.0, -30.0))).is_false()
	assert_int(hero.projectiles.available()).is_equal(4)
