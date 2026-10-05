extends GdUnitTestSuite
## What is left of Difficulty after review finding 20.
##
## This file used to pin eleven exact values across `spawn_interval`, `hp_mult`
## and `fast_ratio` — and passed, while none of the three had a single
## production caller. The suite was green on functions that could not affect the
## game. They are gone; the real curve lives in the WaveResource `.tres` files
## and is pinned by `test_run_schedule.gd` instead.
##
## What remains here is the part that is genuinely live: the safety bound.


func test_spawn_guard_bounds_the_live_enemy_set() -> void:
	# The spawn curve outruns achievable DPS, so without this guard the live set
	# grows for the whole run. Boundedness is a property, not a play-test result.
	assert_bool(Difficulty.should_spawn(0)).append_failure_message("spawns from empty").is_true()
	assert_bool(Difficulty.should_spawn(Difficulty.MAX_ALIVE - 1)).append_failure_message("spawns up to the cap").is_true()
	assert_bool(Difficulty.should_spawn(Difficulty.MAX_ALIVE)).append_failure_message("refuses at the cap").is_false()
	assert_bool(Difficulty.should_spawn(Difficulty.MAX_ALIVE + 50)).append_failure_message("stays refused above it").is_false()


func test_elite_modifiers_are_a_step_up_not_a_new_archetype() -> void:
	# An elite is the SAME enemy under pressure: same silhouette, same behaviour,
	# more of everything. If any of these ever drops to 1.0 the elite stops being
	# readable as a threat and becomes a reskin.
	assert_float(float(Difficulty.ELITE_HP_MULT)).is_greater(float(1.0))
	assert_float(float(Difficulty.ELITE_XP_MULT)).append_failure_message("more danger must pay more").is_greater(float(1.0))
	assert_float(float(Difficulty.ELITE_SCALE)).append_failure_message("it has to LOOK bigger").is_greater(float(1.0))
	assert_float(float(Difficulty.ELITE_DAMAGE_BONUS)).is_greater(float(0))
