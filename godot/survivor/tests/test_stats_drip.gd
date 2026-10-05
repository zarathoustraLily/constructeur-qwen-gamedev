extends GdUnitTestSuite
## The seam between the level drip and the things that read it. Progression owns
## the numbers (test_progression pins those); this pins that every weapon and the
## player actually go THROUGH the seam, because the failure mode is silent — a
## call site that still reads `damage_bonus` directly just quietly misses two
## thirds of the player's level-ups and nothing errors.


func _at_level(level: int) -> Stats:
	var s := Stats.new()
	s.drip_damage_bonus = Progression.drip_damage_bonus(level)
	s.drip_projectile_bonus = Progression.drip_projectiles(level)
	s.drip_cooldown_mult = Progression.drip_cooldown_mult(level)
	s.drip_move_speed_mult = Progression.drip_move_speed_mult(level)
	return s


func test_damage_from_folds_cards_and_drip() -> void:
	var s: Stats = _at_level(13)  # +3 flat (was +4 before the 2026-08-03 cut)
	s.damage_bonus = 3
	# A base-1 weapon, +3 from cards, +3 from the drip.
	assert_float(float(s.damage_from(1))).is_equal_approx(float(7.0), float(0.001))
	# Float on the way out: the multishot and ring taxes still have to multiply
	# it, and rounding here would round three times per shot instead of once.
	assert_float(float(s.damage_from(5))).is_equal_approx(float(11.0), float(0.001))


func test_cooldown_scale_folds_cards_and_drip() -> void:
	var s: Stats = _at_level(75)
	s.fire_rate_mult = 0.88  # one fire-rate card
	assert_float(float(s.cooldown_scale())).is_equal_approx(float(0.88 * Progression.drip_cooldown_mult(75)), float(0.0001))
	assert_float(float(s.cooldown_scale())).append_failure_message("the drip can only make it faster").is_less(float(0.88))


func test_cooldown_never_falls_through_the_floor() -> void:
	# Fire-rate cards MULTIPLY and M7.3 made each one bigger. Eleven picks on
	# that one axis would otherwise reach a weapon firing every frame.
	var s: Stats = _at_level(75)
	s.fire_rate_mult = 0.001
	assert_float(float(s.cooldown_scale())).is_equal_approx(float(Stats.COOLDOWN_FLOOR), float(0.0001))


func test_volley_count_folds_cards_and_drip() -> void:
	var s: Stats = _at_level(41)  # +2 from the drip
	s.projectile_bonus = 1
	assert_that(s.volley_count(1)).append_failure_message("base + card + drip").is_equal(4)
	assert_that(s.volley_count(5)).append_failure_message("the scattergun widens by the same amount").is_equal(8)


func test_speed_folds_cards_and_capped_drip() -> void:
	var s: Stats = _at_level(200)  # deep endless, drip pinned at its cap
	s.move_speed = 130.0 * 1.12    # one pair of boots
	assert_float(float(s.speed())).is_equal_approx(float(130.0 * 1.12 * 1.20), float(0.001))


func test_a_fresh_stats_is_unchanged_by_the_seam() -> void:
	# Level 1, no cards: every helper must be the identity, or the drip has
	# silently moved the baseline the whole game is authored against.
	var s := Stats.new()
	assert_float(float(s.damage_from(1))).is_equal_approx(float(1.0), float(0.0001))
	assert_float(float(s.cooldown_scale())).is_equal_approx(float(1.0), float(0.0001))
	assert_float(float(s.speed())).is_equal_approx(float(130.0), float(0.0001))
