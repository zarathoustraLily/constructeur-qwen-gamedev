extends GdUnitTestSuite
## Temporary buffs. Pure, so the timing rules are assertable without a scene —
## and these rules are exactly the kind that break silently in play.


func test_a_granted_buff_is_active() -> void:
	var b := BuffState.new()
	assert_bool(b.has(BuffState.SHIELD)).is_false()
	b.grant(BuffState.SHIELD, 6.0)
	assert_bool(b.has(BuffState.SHIELD)).is_true()
	assert_float(float(b.remaining(BuffState.SHIELD))).is_equal_approx(float(6.0), float(0.001))


func test_it_expires_and_reports_the_expiry_once() -> void:
	var b := BuffState.new()
	b.grant(BuffState.HASTE, 1.0)
	assert_that(b.tick(0.5).size()).append_failure_message("still running").is_equal(0)
	var expired := b.tick(0.6)
	assert_that(expired.size()).is_equal(1)
	assert_that(expired[0]).is_equal(BuffState.HASTE)
	assert_bool(b.has(BuffState.HASTE)).is_false()
	assert_that(b.tick(1.0).size()).append_failure_message("expiry is reported once, not every tick").is_equal(0)


func test_refreshing_takes_the_longer_duration() -> void:
	# Picking up a second shield with 5s left must never SHORTEN it.
	var b := BuffState.new()
	b.grant(BuffState.SHIELD, 6.0)
	b.tick(1.0)
	b.grant(BuffState.SHIELD, 2.0)
	assert_float(float(b.remaining(BuffState.SHIELD))).append_failure_message("kept the longer one").is_equal_approx(float(5.0), float(0.001))
	b.grant(BuffState.SHIELD, 9.0)
	assert_float(float(b.remaining(BuffState.SHIELD))).append_failure_message("took the longer one").is_equal_approx(float(9.0), float(0.001))


func test_durations_never_stack_into_permanence() -> void:
	var b := BuffState.new()
	for i: int in 10:
		b.grant(BuffState.SHIELD, 6.0)
	assert_float(float(b.remaining(BuffState.SHIELD))).append_failure_message("ten pickups is still six seconds, not sixty").is_equal_approx(float(6.0), float(0.001))


func test_zero_or_negative_duration_grants_nothing() -> void:
	var b := BuffState.new()
	b.grant(BuffState.POWER, 0.0)
	b.grant(BuffState.POWER, -3.0)
	assert_bool(b.has(BuffState.POWER)).is_false()


func test_buffs_are_independent() -> void:
	var b := BuffState.new()
	b.grant(BuffState.SHIELD, 1.0)
	b.grant(BuffState.POWER, 5.0)
	b.tick(1.5)
	assert_bool(b.has(BuffState.SHIELD)).is_false()
	assert_bool(b.has(BuffState.POWER)).append_failure_message("one expiring must not clear the others").is_true()


func test_active_ids_are_ordered_longest_first() -> void:
	# A HUD listing these must not reshuffle every frame as the Dictionary rehashes.
	var b := BuffState.new()
	b.grant(BuffState.SHIELD, 2.0)
	b.grant(BuffState.POWER, 9.0)
	b.grant(BuffState.HASTE, 5.0)
	var ids := b.active_ids()
	assert_that(ids[0]).is_equal(BuffState.POWER)
	assert_that(ids[1]).is_equal(BuffState.HASTE)
	assert_that(ids[2]).is_equal(BuffState.SHIELD)


func test_shield_blocks_damage_without_touching_the_dev_flag() -> void:
	var h := Health.new(6)
	h.shielded = true
	assert_bool(h.take_damage(3, 0.0)).append_failure_message("shield blocks").is_false()
	assert_that(h.hp).is_equal(6)
	h.shielded = false
	assert_bool(h.take_damage(3, 5.0)).append_failure_message("and releases cleanly").is_true()
	assert_that(h.hp).is_equal(3)
	assert_bool(h.invincible).append_failure_message("the gameplay buff never wrote to the dev flag").is_false()
