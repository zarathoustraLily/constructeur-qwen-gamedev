extends GdUnitTestSuite
## Damage application and XP values — the acceptance criterion M3 declared and
## never delivered. Everything here is pure: enemy HP scaling and XP rounding
## were extracted out of Enemy/Main precisely so they could be tested without
## instancing a scene (hub D12: logic only, never scenes).


func _stats(max_hp: int, xp_value: int = 3) -> EnemyStats:
	var s := EnemyStats.new()
	s.id = &"test"
	s.max_hp = max_hp
	s.xp_value = xp_value
	return s


## Hits needed to kill, mirroring Enemy.take_hit: damage subtracts, death at <= 0.
func _shots_to_kill(hp: int, damage: int) -> int:
	return ceili(float(hp) / float(damage))


# --- enemy HP scaling -------------------------------------------------------

## HP multipliers are authored per WAVE in tools/gen_waves.gd, not derived from a
## time curve — `Difficulty.hp_mult` was removed as dead code (review finding
## 20). These are the real shipped values: opening 1.0, swarm 2.0, endless_1 3.4.
const WAVE_OPENING: float = 1.0
const WAVE_SWARM: float = 2.0
const WAVE_ENDLESS_1: float = 3.4


func test_effective_hp_is_base_hp_at_run_start() -> void:
	assert_that(_stats(3).effective_hp(WAVE_OPENING)).is_equal(3)


func test_effective_hp_scales_with_the_wave_multiplier() -> void:
	assert_that(_stats(4).effective_hp(1.5)).is_equal(6)
	assert_that(_stats(3).effective_hp(WAVE_SWARM)).is_equal(6)


func test_effective_hp_rounds_rather_than_truncates() -> void:
	# 3 * 1.5 = 4.5 must not silently become 4.
	assert_that(_stats(3).effective_hp(1.5)).is_equal(5)
	assert_that(_stats(1).effective_hp(1.5)).is_equal(2)


func test_effective_hp_never_drops_below_one() -> void:
	# A sub-1 result would round to 0 and make the enemy unkillable — take_hit
	# early-returns on hp <= 0, so it would never emit died and never free.
	assert_that(_stats(1).effective_hp(0.4)).is_equal(1)
	assert_that(_stats(2).effective_hp(0.0)).is_equal(1)


# --- damage application -----------------------------------------------------

func test_one_damage_kills_a_one_hp_enemy() -> void:
	assert_that(_shots_to_kill(_stats(1).effective_hp(1.0), 1)).is_equal(1)


func test_overkill_damage_still_takes_one_hit() -> void:
	assert_that(_shots_to_kill(_stats(3).effective_hp(1.0), 99)).is_equal(1)


func test_shots_to_kill_scales_with_enemy_hp_not_damage_alone() -> void:
	var hp: int = _stats(3).effective_hp(WAVE_SWARM)  # 3 * 2.0 -> 6 HP
	assert_that(hp).is_equal(6)
	assert_that(_shots_to_kill(hp, 1)).is_equal(6)
	assert_that(_shots_to_kill(hp, 2)).is_equal(3)
	assert_that(_shots_to_kill(hp, 4)).override_failure_message("partial damage still requires a second hit").is_equal(2)


func test_damage_curve_keeps_the_base_enemy_killable_late() -> void:
	# At 5 minutes a chaser must not be a sponge for a player who took no damage
	# upgrades — this is the balance assumption the 5:00 boss depends on, and it
	# is now pinned against the wave the run is actually in at that moment.
	var hp: int = _stats(3).effective_hp(WAVE_ENDLESS_1)
	assert_float(float(_shots_to_kill(hp, 1))).override_failure_message("base weapon still kills a chaser in under 25 shots at 5min").is_less(float(25))


# --- ricochet carry ---------------------------------------------------------

## Playtest 2026-08-03: bounces redirected at FULL damage, which made Ricochet a
## flat 5x on every shot and hit a boss as hard as a crowd. A bounce now carries
## only what the last target could not absorb, and `Enemy.absorbed_by` IS that
## rule — static and pure precisely so it can be pinned here.


func test_a_body_absorbs_only_the_hp_it_actually_had() -> void:
	# 40 damage into a 1 HP Dart spends 1; the other 39 bounce onward.
	assert_that(Enemy.absorbed_by(1, 40)).is_equal(1)
	assert_that(Enemy.absorbed_by(6, 40)).is_equal(6)


func test_a_body_that_survives_absorbs_the_whole_hit() -> void:
	# Nothing left over means nothing to bounce with. This is the BOSS case, and
	# it is the entire reason Ricochet no longer feeds single-target DPS.
	assert_that(Enemy.absorbed_by(2400, 40)).is_equal(40)
	assert_that(Enemy.absorbed_by(41, 40)).is_equal(40)


func test_an_exact_kill_leaves_no_remainder() -> void:
	assert_that(Enemy.absorbed_by(40, 40)).override_failure_message("spent exactly, so the shot stops").is_equal(40)


func test_absorption_is_never_negative() -> void:
	# A corpse absorbs nothing rather than refunding damage to the shot — a
	# negative here would hand the bounce MORE damage than it started with.
	assert_that(Enemy.absorbed_by(0, 40)).is_equal(0)
	assert_that(Enemy.absorbed_by(-3, 40)).is_equal(0)
	assert_that(Enemy.absorbed_by(10, 0)).is_equal(0)


# --- multishot tax ----------------------------------------------------------

func test_volley_tax_is_neutral_at_a_weapons_base_count() -> void:
	# A weapon firing its authored number of projectiles pays nothing. The
	# scattergun's 5 pellets ARE its design; only growth the player bought is taxed.
	assert_float(float(Stats.volley_damage_mult(1, 1))).is_equal_approx(float(1.0), float(0.001))
	assert_float(float(Stats.volley_damage_mult(5, 5))).is_equal_approx(float(1.0), float(0.001))
	assert_float(float(Stats.volley_damage_mult(5, 3))).override_failure_message("never a bonus").is_equal_approx(float(1.0), float(0.001))


func test_volley_damage_grows_sublinearly_with_projectile_count() -> void:
	# The whole point: total volley damage rises as sqrt(N), not N. The measured
	# failure was 8 projectiles x +19 damage multiplying into a 7-second boss.
	var total_at_8: float = 8.0 * Stats.volley_damage_mult(1, 8)
	assert_float(float(total_at_8)).override_failure_message("8 projectiles deal ~2.8x, not 8x").is_equal_approx(float(2.83), float(0.01))
	assert_float(float(total_at_8)).override_failure_message("must never scale linearly").is_less(float(8.0))
	assert_float(float(total_at_8)).override_failure_message("must still be worth taking").is_greater(float(1.0))


func test_volley_tax_still_rewards_every_extra_projectile() -> void:
	# Sub-linear must not mean non-monotonic: taking Split Shot has to be an
	# upgrade, or the card is a trap.
	var previous: float = 0.0
	for n: int in range(1, 13):
		var total: float = float(n) * Stats.volley_damage_mult(1, n)
		assert_float(float(total)).override_failure_message("volley %d must beat volley %d" % [n, n - 1]).is_greater(float(previous))
		previous = total


# --- XP values --------------------------------------------------------------

func test_xp_gain_is_base_value_without_multiplier() -> void:
	assert_that(Progression.xp_gain(3, 1.0)).is_equal(3)


func test_xp_gain_applies_and_rounds_the_multiplier() -> void:
	assert_that(Progression.xp_gain(3, 1.25)).is_equal(4)   # 3.75 rounds up
	assert_that(Progression.xp_gain(4, 1.25)).is_equal(5)
	assert_that(Progression.xp_gain(10, 1.5)).is_equal(15)


func test_xp_gain_never_returns_zero() -> void:
	# A gem worth nothing is a gem that reads as a bug to the player.
	assert_that(Progression.xp_gain(1, 0.1)).is_equal(1)
	assert_that(Progression.xp_gain(3, 0.0)).is_equal(1)


func test_xp_from_a_kill_feeds_the_level_curve() -> void:
	# Level 1 needs 3 XP and a chaser gives 3, so the FIRST KILL levels you up —
	# and Progression.FIRST_CARD_LEVEL makes that first level-up a card screen.
	# Deliberate: the audience is a stranger's first ten minutes, and one kill
	# into the run they have been shown the entire loop. It cost three kills
	# before M7.2, when levels were 2.4x more expensive.
	var per_kill: int = Progression.xp_gain(_stats(3, 3).xp_value, 1.0)
	assert_that(per_kill).is_equal(3)
	assert_that(per_kill).override_failure_message("one kill, one level, one card").is_equal(Progression.xp_required(1))
	assert_bool(Progression.offers_card(2)).override_failure_message("and that level-up must offer a card").is_true()
