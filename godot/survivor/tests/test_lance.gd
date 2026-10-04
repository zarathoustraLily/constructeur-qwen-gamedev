extends GdUnitTestSuite
## The lance's hit test is pure geometry — pin it down without a scene.
## segment_hit(from, dir, length, half_width, point).


func test_point_on_the_line_hits() -> void:
	assert_bool(LanceWeapon.segment_hit(
			Vector2.ZERO, Vector2.RIGHT, 300.0, 10.0, Vector2(150, 0))).is_true()


func test_point_inside_corridor_hits() -> void:
	assert_bool(LanceWeapon.segment_hit(
			Vector2.ZERO, Vector2.RIGHT, 300.0, 10.0, Vector2(150, 9.9))).is_true()


func test_point_outside_corridor_misses() -> void:
	assert_bool(LanceWeapon.segment_hit(
			Vector2.ZERO, Vector2.RIGHT, 300.0, 10.0, Vector2(150, 10.1))).is_false()


func test_point_beyond_range_misses() -> void:
	assert_bool(LanceWeapon.segment_hit(
			Vector2.ZERO, Vector2.RIGHT, 300.0, 10.0, Vector2(320, 0))).is_false()


func test_point_behind_origin_misses() -> void:
	assert_bool(LanceWeapon.segment_hit(
			Vector2.ZERO, Vector2.RIGHT, 300.0, 10.0, Vector2(-40, 0))).is_false()


func test_endpoint_cap_is_round() -> void:
	# Just past the tip but within half_width of the endpoint still counts —
	# the clamp caps the segment with a circle, not a wall.
	assert_bool(LanceWeapon.segment_hit(
			Vector2.ZERO, Vector2.RIGHT, 300.0, 10.0, Vector2(306, 0))).is_true()


func test_diagonal_direction() -> void:
	var dir: Vector2 = Vector2.ONE.normalized()
	assert_bool(LanceWeapon.segment_hit(
			Vector2(10, 10), dir, 200.0, 8.0, Vector2(110, 110))).is_true()
	assert_bool(LanceWeapon.segment_hit(
			Vector2(10, 10), dir, 200.0, 8.0, Vector2(110, 140))).is_false()


func test_weapons_answer_to_the_run_not_the_profile() -> void:
	# M7.3: availability moved from "have you ever unlocked this" to "did you
	# draft it in THIS run". The gate is the weapon's own id, so a weapon and its
	# requirement cannot drift apart.
	var scatter: WeaponResource = load("res://resources/weapons/scattergun.tres")
	var lance: WeaponResource = load("res://resources/weapons/lance.tres")
	# A bare [] literal is an UNTYPED Array and trips the typed-argument check
	# at runtime (a debugger break, which stalls headless GUT at a prompt).
	var none: Array[StringName] = []
	var drafted_scatter: Array[StringName] = [&"scattergun"]
	var both: Array[StringName] = [&"scattergun", &"lance"]
	assert_bool(scatter.is_available(none)).override_failure_message("nothing is owned at spawn any more").is_false()
	assert_bool(lance.is_available(none)).is_false()
	assert_bool(scatter.is_available(drafted_scatter)).is_true()
	assert_bool(lance.is_available(drafted_scatter)).override_failure_message("drafting one weapon must not hand over the others").is_false()
	assert_bool(lance.is_available(both)).is_true()


func test_a_meta_unlock_offers_a_card_rather_than_a_weapon() -> void:
	# The delivery change, pinned where it would otherwise be invisible: beating
	# the Prism puts draft_orbital into the POOL, and only that card grants the
	# weapon. A profile with every unlock still starts every run blaster-only.
	var card: UpgradeResource = load("res://resources/upgrades/draft_orbital.tres")
	assert_that(card.requires_unlock).override_failure_message("the milestone gates the card...").is_equal(MetaState.UNLOCK_ORBITAL)
	assert_that(card.weapon_id).override_failure_message("...and the card grants the weapon").is_equal(&"orbital")
	var s := Stats.new()
	assert_bool(s.has_weapon(&"orbital")).override_failure_message("a run starts owning nothing").is_false()
	card.apply_to(s)
	assert_bool(s.has_weapon(&"orbital")).is_true()
	card.apply_to(s)
	assert_that(s.drafted_weapons.size()).override_failure_message("drafting twice is still one weapon").is_equal(1)


func test_a_weapons_branch_waits_on_the_draft_not_the_unlock() -> void:
	# The bug this closes: orbital cards used to gate on the META unlock, so a
	# veteran saw them in every run whether or not the orbital was in it.
	var spin: UpgradeResource = load("res://resources/upgrades/orbit_speed.tres")
	assert_that(spin.requires_unlock).is_equal(UpgradeResource.weapon_gate(&"orbital"))
	var unlocked_only: Array[StringName] = [MetaState.UNLOCK_ORBITAL]
	var drafted: Array[StringName] = [UpgradeResource.weapon_gate(&"orbital")]
	assert_bool(spin.is_eligible(0, unlocked_only)).override_failure_message("having ever unlocked the orbital must not open its branch").is_false()
	assert_bool(spin.is_eligible(0, drafted)).is_true()
