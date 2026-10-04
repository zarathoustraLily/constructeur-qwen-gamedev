extends GdUnitTestSuite
## Health is pure logic with injected time — these tests never touch the tree.


func test_damage_reduces_hp() -> void:
	var h := Health.new(6, 0.6)
	var applied := h.take_damage(2, 0.0)
	assert_bool(applied).override_failure_message("damage should apply").is_true()
	assert_that(h.hp).is_equal(4)


func test_iframes_block_then_expire() -> void:
	var h := Health.new(6, 0.6)
	h.take_damage(1, 0.0)
	assert_bool(h.take_damage(1, 0.3)).override_failure_message("inside i-frame window — blocked").is_false()
	assert_that(h.hp).is_equal(5)
	assert_bool(h.take_damage(1, 0.7)).override_failure_message("after i-frame window — applies").is_true()
	assert_that(h.hp).is_equal(4)


func test_hp_clamps_at_zero_and_died_fires_once() -> void:
	var h := Health.new(3, 0.0)
	# Portage GdUnit4 de watch_signals / assert_signal_emit_count (GUT) : un compteur.
	var morts := [0]
	h.died.connect(func() -> void: morts[0] += 1)
	h.take_damage(99, 0.0)
	assert_that(h.hp).is_equal(0)
	assert_that(morts[0]).is_equal(1)
	assert_bool(h.take_damage(1, 10.0)).override_failure_message("dead — no further damage").is_false()
	assert_that(morts[0]).is_equal(1)


func test_heal_clamps_at_max_and_not_when_dead() -> void:
	var h := Health.new(6, 0.0)
	h.take_damage(3, 0.0)
	h.heal(99)
	assert_that(h.hp).is_equal(6)
	h.take_damage(99, 1.0)
	h.heal(5)
	assert_that(h.hp).override_failure_message("healing the dead does nothing").is_equal(0)


func test_raise_max_also_heals_by_amount() -> void:
	var h := Health.new(6, 0.0)
	h.take_damage(2, 0.0)
	h.raise_max(2)
	assert_that(h.max_hp).is_equal(8)
	assert_that(h.hp).is_equal(6)
