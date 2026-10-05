extends GdUnitTestSuite
## Every Effect must mutate Stats exactly as its .tres description promises —
## the regression net for "adding upgrade #11 silently broke upgrade #4".


func _mk(effect: UpgradeResource.Effect, magnitude: float) -> UpgradeResource:
	var u := UpgradeResource.new()
	u.effect = effect
	u.magnitude = magnitude
	return u


func test_move_speed_is_multiplicative() -> void:
	var s := Stats.new()
	_mk(UpgradeResource.Effect.MOVE_SPEED, 0.12).apply_to(s)
	assert_float(float(s.move_speed)).is_equal_approx(float(130.0 * 1.12), float(0.001))


func test_max_hp_and_damage_are_flat() -> void:
	var s := Stats.new()
	_mk(UpgradeResource.Effect.MAX_HP, 2.0).apply_to(s)
	_mk(UpgradeResource.Effect.DAMAGE, 1.0).apply_to(s)
	assert_that(s.max_hp).is_equal(8)
	assert_that(s.damage_bonus).append_failure_message("a modifier, not an absolute").is_equal(1)


func test_fire_rate_reduces_interval() -> void:
	var s := Stats.new()
	_mk(UpgradeResource.Effect.FIRE_RATE, 0.12).apply_to(s)
	assert_float(float(s.fire_rate_mult)).is_equal_approx(float(0.88), float(0.001))


func test_projectiles_and_magnet_and_xp() -> void:
	var s := Stats.new()
	_mk(UpgradeResource.Effect.PROJECTILE_COUNT, 1.0).apply_to(s)
	_mk(UpgradeResource.Effect.PROJECTILE_SPEED, 0.2).apply_to(s)
	_mk(UpgradeResource.Effect.MAGNET, 28.0).apply_to(s)
	_mk(UpgradeResource.Effect.XP_GAIN, 0.15).apply_to(s)
	assert_that(s.projectile_bonus).is_equal(1)
	assert_float(float(s.projectile_speed_mult)).is_equal_approx(float(1.2), float(0.001))
	assert_float(float(s.magnet_radius)).is_equal_approx(float(76.0), float(0.001))
	assert_float(float(s.xp_mult)).is_equal_approx(float(1.15), float(0.001))


func test_heal_does_not_touch_stats() -> void:
	var s := Stats.new()
	var before_hp: int = s.max_hp
	_mk(UpgradeResource.Effect.HEAL, 3.0).apply_to(s)
	assert_that(s.max_hp).append_failure_message("HEAL is Main's job against Health, not Stats").is_equal(before_hp)


func test_stacking_compounds() -> void:
	var s := Stats.new()
	var boots := _mk(UpgradeResource.Effect.MOVE_SPEED, 0.12)
	boots.apply_to(s)
	boots.apply_to(s)
	assert_float(float(s.move_speed)).is_equal_approx(float(130.0 * 1.12 * 1.12), float(0.001))


func test_xp_effects_are_additive_and_capped() -> void:
	# M7.2. These two used to stack MULTIPLICATIVELY: greed (Epic, +50%, two
	# stacks) with scholar at 3 held xp_mult at 3.0x from 2:30 onward, so income
	# worth level 54 bought level 79 and greed alone was worth 25 levels.
	var s := Stats.new()
	_mk(UpgradeResource.Effect.GREED, 0.5).apply_to(s)
	assert_float(float(s.xp_mult)).is_equal_approx(float(1.5), float(0.001))
	_mk(UpgradeResource.Effect.XP_GAIN, 0.15).apply_to(s)
	assert_float(float(s.xp_mult)).append_failure_message("1.5 + 0.15 additive, then clipped to the cap — not 1.5 x 1.15").is_equal_approx(float(1.6), float(0.001))
	assert_bool(s.greed).append_failure_message("greed still grants the gem magnet").is_true()
	# Everything the pool can offer, twice over, must not exceed the ceiling.
	for i: int in 8:
		_mk(UpgradeResource.Effect.GREED, 0.5).apply_to(s)
	assert_float(float(s.xp_mult)).append_failure_message("the cap is hard").is_equal_approx(float(Stats.XP_MULT_CAP), float(0.001))
