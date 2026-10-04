extends GdUnitTestSuite
## The shard economy and the purchase rules. Pure logic on MetaState — the screen
## itself is measured by scenes/dev/pause_layout_check.tscn, since GUT here is
## logic-only by convention.


func test_shards_are_depth_weighted_not_kill_weighted() -> void:
	# The whole design choice, pinned. Kills would pay best for farming the easy
	# minutes; this pays for getting FURTHER, and it keeps a failed NOGAXEH
	# attempt worth something — which matters when that fight runs two minutes
	# and can end in a detonation.
	var shallow: int = MetaState.shards_for(180.0, 0)   # died at 3:00, no boss
	var deep: int = MetaState.shards_for(600.0, 2)      # the full ten minutes
	assert_that(shallow).is_equal(18)
	assert_that(deep).is_equal(110)
	assert_float(float(deep)).override_failure_message("depth has to pay several times what time alone does").is_greater(float(shallow * 4))


func test_a_boss_event_is_worth_more_than_four_minutes_of_hiding() -> void:
	assert_float(float(MetaState.SHARDS_PER_BOSS_EVENT)).is_greater(float(MetaState.SHARDS_PER_MINUTE * 4))


func test_absorbing_a_run_pays_it() -> void:
	var m := MetaState.new()
	m.absorb({"time": 300.0, "kills": 400, "won": true, "boss_events": 1})
	assert_that(m.shards).override_failure_message("5 minutes and the Prism").is_equal(55)


func test_continuing_into_endless_is_never_a_currency_loss() -> void:
	# A run banked at 5:20 that then dies at 11:00 earned the whole eleven
	# minutes and both events. Paying only the banked share, or paying twice,
	# would both make Continue the wrong button for the wrong reason.
	var m := MetaState.new()
	var banked: int = MetaState.shards_for(320.0, 1)
	m.absorb({"time": 320.0, "kills": 500, "won": true, "boss_events": 1,
			"shards_banked": 0})
	assert_that(m.shards).is_equal(banked)
	m.update_records({"time": 660.0, "kills": 2400, "won": true, "boss_events": 2,
			"shards_banked": banked})
	assert_that(m.shards).override_failure_message("the full run is paid exactly once").is_equal(MetaState.shards_for(660.0, 2))


func test_buying_spends_once_and_only_when_affordable() -> void:
	var m := MetaState.new()
	m.shards = 100
	assert_bool(m.buy(&"node_keen", 150)).override_failure_message("cannot buy what you cannot afford").is_false()
	assert_that(m.shards).is_equal(100)
	assert_bool(m.buy(&"node_keen", 95)).is_true()
	assert_that(m.shards).is_equal(5)
	assert_bool(m.has_purchase(&"node_keen")).is_true()
	m.shards = 500
	assert_bool(m.buy(&"node_keen", 95)).override_failure_message("and never twice").is_false()
	assert_that(m.shards).is_equal(500)


func test_purchases_survive_a_save_round_trip() -> void:
	var m := MetaState.new()
	m.shards = 240
	m.buy(&"node_hardy", 60)
	var back: MetaState = MetaState.from_dict(
		JSON.parse_string(JSON.stringify(m.to_dict())) as Dictionary)
	assert_that(back.shards).is_equal(180)
	assert_bool(back.has_purchase(&"node_hardy")).is_true()


func test_a_save_from_before_the_tree_reads_as_an_empty_tree() -> void:
	# The schema changed under existing profiles. A missing key must be an empty
	# tree and zero shards, never a crash — a corrupt save costs progress, a
	# crash on boot costs the whole game.
	var m: MetaState = MetaState.from_dict({"runs_played": 11, "unlocks": ["orbital"]})
	assert_that(m.runs_played).is_equal(11)
	assert_that(m.shards).is_equal(0)
	assert_that(m.purchases.size()).is_equal(0)
	assert_bool(m.has_unlock(&"orbital")).is_true()


func test_every_card_node_actually_gates_a_card_that_exists() -> void:
	# The content-drift guard. A CARD node whose upgrade was renamed or retired
	# would sell the player nothing at all, silently — which is exactly how a
	# retired upgrade got offered 62 times in this project already.
	for node: SkillNode in SkillList.ALL:
		if node.kind != SkillNode.Kind.CARD:
			continue
		var found: UpgradeResource = null
		for upgrade: UpgradeResource in UpgradeList.ALL:
			if upgrade.id == node.grants_card:
				found = upgrade
		assert_that(found).override_failure_message("%s sells a card that is not in the pool" % node.id).is_not_null()
		if found != null:
			assert_that(found.requires_unlock).override_failure_message("%s must be gated by the node that sells it" % found.id).is_equal(node.id)


func test_stat_nodes_carry_a_payload_and_card_nodes_do_not() -> void:
	for node: SkillNode in SkillList.ALL:
		if node.kind == SkillNode.Kind.STAT:
			assert_that(node.payload).override_failure_message("%s is a stat node with nothing to apply" % node.id).is_not_null()
		else:
			assert_that(node.grants_card).override_failure_message("%s is a card node that names no card" % node.id).is_not_equal(&"")


func test_stat_nodes_stay_small() -> void:
	# Every difficulty number in the game is tuned against a ZERO tree, so the
	# tree can only make a run easier than its target. That mitigation is what
	# made shipping a permanent stat tree acceptable next to a rebalance, and it
	# only holds while the nodes stay modest.
	var s := Stats.new()
	for node: SkillNode in SkillList.ALL:
		node.apply_to(s)
	assert_float(float(s.max_hp)).override_failure_message("a full tree must not double the starting HP pool").is_less(float(10))
	assert_float(float(s.damage_bonus)).is_less(float(3))
	assert_float(float(s.speed())).is_less(float(130.0 * 1.15))
	assert_float(float(s.xp_mult)).is_less(float(1.2))
