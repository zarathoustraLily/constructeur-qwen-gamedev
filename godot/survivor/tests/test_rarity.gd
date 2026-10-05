extends GdUnitTestSuite
## Rarity odds and the pity floor. Pure, so the distribution is assertable
## without playing thirty runs to eyeball it.


func _rng(seed_value: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r


func _sample(progress: float, n: int = 4000) -> Dictionary:
	var counts: Dictionary = {}
	var rng := _rng(4242)
	for i: int in n:
		var t: Rarity.Tier = Rarity.roll(rng, progress, 0)
		counts[t] = int(counts.get(t, 0)) + 1
	return counts


func test_common_dominates_early_and_recedes_late() -> void:
	var early := _sample(0.0)
	var late := _sample(1.0)
	assert_float(float(float(early.get(Rarity.Tier.COMMON, 0)) / 4000.0)).append_failure_message("early runs are mostly Commons").is_greater(float(0.5))
	assert_float(float(float(late.get(Rarity.Tier.COMMON, 0)) / 4000.0)).append_failure_message("Commons must recede as the run progresses").is_less(float(float(early.get(Rarity.Tier.COMMON, 0)) / 4000.0))


func test_legendaries_are_rare_but_reachable() -> void:
	var early := _sample(0.0)
	var late := _sample(1.0)
	var early_rate: float = float(early.get(Rarity.Tier.LEGENDARY, 0)) / 4000.0
	var late_rate: float = float(late.get(Rarity.Tier.LEGENDARY, 0)) / 4000.0
	assert_float(float(early_rate)).append_failure_message("a level-2 Legendary should be a shock, not a Tuesday").is_less(float(0.02))
	assert_float(float(late_rate)).append_failure_message("late runs must improve the odds").is_greater(float(early_rate))
	assert_float(float(late_rate)).append_failure_message("still rare at full progress, or the word means nothing").is_less(float(0.10))


func test_progress_saturates() -> void:
	assert_float(float(Rarity.progress_for_level(1))).is_equal_approx(float(0.0), float(0.001))
	assert_float(float(Rarity.progress_for_level(int(Rarity.PROGRESS_FULL_LEVEL)))).is_equal_approx(float(1.0), float(0.001))
	assert_float(float(Rarity.progress_for_level(999))).append_failure_message("a long endless run must not drift into all-Legendary screens").is_equal_approx(float(1.0), float(0.001))


func test_pity_floors_the_roll() -> void:
	# The cold streak is the worst thing a random reward can do, and it is
	# invisible in aggregate stats — so it gets a hard floor, not a hope.
	var rng := _rng(7)
	for i: int in 500:
		var t: Rarity.Tier = Rarity.roll(rng, 0.0, Rarity.PITY_LIMIT)
		assert_bool(int(t) >= int(Rarity.PITY_TIER)).append_failure_message("at the pity limit every roll is Rare or better").is_true()


func test_pity_below_the_limit_does_not_floor() -> void:
	var rng := _rng(11)
	var saw_common: bool = false
	for i: int in 500:
		if Rarity.roll(rng, 0.0, Rarity.PITY_LIMIT - 1) == Rarity.Tier.COMMON:
			saw_common = true
			break
	assert_bool(saw_common).append_failure_message("pity must not trigger early").is_true()


func test_weights_lerp_between_the_two_ends() -> void:
	var mid := Rarity.weights(0.5)
	for i: int in Rarity.TIER_COUNT:
		var expected: float = (Rarity.EARLY[i] + Rarity.LATE[i]) * 0.5
		assert_float(float(mid[i])).is_equal_approx(float(expected), float(0.001))


func test_every_tier_has_a_name_a_colour_and_a_glow() -> void:
	for i: int in Rarity.TIER_COUNT:
		assert_that(Rarity.name_of(i as Rarity.Tier)).is_not_equal("")
		assert_bool(Rarity.glow_of(i as Rarity.Tier) >= 0.0).is_true()
	assert_float(float(Rarity.glow_of(Rarity.Tier.LEGENDARY))).append_failure_message("glow is a second rarity channel so the ladder survives a screenshot").is_greater(float(Rarity.glow_of(Rarity.Tier.COMMON)))
