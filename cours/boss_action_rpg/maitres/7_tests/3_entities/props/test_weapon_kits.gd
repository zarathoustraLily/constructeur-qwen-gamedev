extends GdUnitTestSuite
## Règles des armes de l'Établi : chacune a un nom, une description, ses réglages et sa propre forme, avec un canon dans
## l'axe ; aucune n'a la cadence d'une autre ; une gerbe tient dans la réserve de 32 projectiles.

const KITS: Array[WeaponKit] = [
	preload("res://5_data/weapons/nailer.tres"), preload("res://5_data/weapons/cork.tres"),
	preload("res://5_data/weapons/needle.tres"), preload("res://5_data/weapons/caps.tres"),
]
## La réserve des niveaux (main.tscn, burrow.tscn).
const POOL_SIZE: int = 32


func test_chacune_a_un_nom_une_description_et_ses_reglages() -> void:
	for kit: WeaponKit in KITS:
		assert_str(kit.display_name).is_not_empty()
		assert_str(kit.description).is_not_empty()
		assert_object(kit.gun).is_not_null()
		assert_object(kit.heat).is_not_null()


func test_chacune_a_sa_forme_avec_un_canon_devant() -> void:
	var seen: Dictionary[int, bool] = {}
	for kit: WeaponKit in KITS:
		seen[kit.shape] = true
		var box: AABB = WeaponShapes.build(kit.shape).get_aabb()
		assert_float(box.position.z).is_less(-0.3)
		assert_float(box.end.z).is_greater(0.0)
	assert_int(seen.size()).is_equal(KITS.size())


func test_aucune_n_a_la_cadence_d_une_autre() -> void:
	var seen: Dictionary[float, bool] = {}
	for kit: WeaponKit in KITS:
		seen[kit.gun.fire_interval] = true
	assert_int(seen.size()).is_equal(KITS.size())


func test_ce_qui_vole_tient_dans_la_reserve() -> void:
	for kit: WeaponKit in KITS:
		var flying: float = ceilf(kit.gun.lifetime / kit.gun.fire_interval) * kit.gun.pellets
		assert_float(flying).override_failure_message(kit.display_name).is_less_equal(POOL_SIZE)
