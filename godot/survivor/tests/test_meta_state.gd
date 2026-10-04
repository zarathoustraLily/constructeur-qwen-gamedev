extends GdUnitTestSuite
## Run/meta separation, unlock rules, and save round-trips.
##
## This is the system V2 reuses wholesale, so its invariants are tested here
## where they are still cheap to change. No file I/O: the round trip goes through
## real JSON TEXT in memory, not through a Dictionary — that is what exercises
## the actual serialization path, including JSON turning every int into a float
## on the way back.


func _result(kills: int, time: float, won: bool) -> Dictionary:
	return {"seed": 1, "time": time, "kills": kills, "level": 5, "won": won}


func _round_trip(m: MetaState) -> MetaState:
	var text: String = JSON.stringify(m.to_dict())
	var parsed: Variant = JSON.parse_string(text)
	assert_bool(parsed is Dictionary).override_failure_message("save parses as an object").is_true()
	return MetaState.from_dict(parsed as Dictionary)


# --- run / meta separation --------------------------------------------------

func test_absorb_takes_values_not_a_reference() -> void:
	var meta := MetaState.new()
	var run := RunState.with_seed(42)
	run.kills = 10
	run.elapsed = 100.0
	meta.absorb(run.to_result())
	# Mutating the run afterwards must not reach into the saved record.
	run.kills = 9999
	run.elapsed = 9999.0
	assert_that(meta.best_kills).override_failure_message("meta kept its own copy").is_equal(10)
	assert_that(meta.best_time).is_equal(100.0)


func test_run_state_result_is_a_flat_snapshot() -> void:
	var run := RunState.with_seed(7)
	run.kills = 3
	var first: Dictionary = run.to_result()
	run.kills = 4
	assert_that(int(first["kills"])).override_failure_message("an earlier snapshot is not live").is_equal(3)


func test_unlocks_array_is_not_aliased_by_round_trip() -> void:
	var meta := MetaState.new()
	meta.absorb(_result(5, 10.0, true))
	var loaded := _round_trip(meta)
	loaded.unlocks.append(&"injected")
	assert_bool(meta.has_unlock(&"injected")).override_failure_message("loaded state is independent").is_false()


# --- records ----------------------------------------------------------------

func test_records_keep_the_best_not_the_last() -> void:
	var meta := MetaState.new()
	meta.absorb(_result(50, 300.0, false))
	meta.absorb(_result(10, 60.0, false))
	assert_that(meta.best_kills).override_failure_message("a worse run never lowers a record").is_equal(50)
	assert_that(meta.best_time).is_equal(300.0)
	assert_that(meta.runs_played).is_equal(2)
	assert_that(meta.total_kills).override_failure_message("totals accumulate, records do not").is_equal(60)


# --- unlock rules -----------------------------------------------------------

func test_first_victory_unlocks_the_orbital() -> void:
	var meta := MetaState.new()
	assert_bool(meta.has_unlock(MetaState.UNLOCK_ORBITAL)).is_false()
	var gained := meta.absorb(_result(200, 320.0, true))
	assert_bool(gained.has(MetaState.UNLOCK_ORBITAL)).override_failure_message("reported as newly gained").is_true()
	assert_bool(meta.has_unlock(MetaState.UNLOCK_ORBITAL)).is_true()


func test_losing_never_unlocks_the_orbital() -> void:
	var meta := MetaState.new()
	assert_that(meta.absorb(_result(500, 290.0, false)).size()).is_equal(0)
	assert_bool(meta.has_unlock(MetaState.UNLOCK_ORBITAL)).is_false()


func test_an_unlock_is_reported_once_and_kept_forever() -> void:
	var meta := MetaState.new()
	meta.absorb(_result(200, 320.0, true))
	var second := meta.absorb(_result(200, 320.0, true))
	assert_bool(second.has(MetaState.UNLOCK_ORBITAL)).override_failure_message("not re-reported").is_false()
	assert_bool(meta.has_unlock(MetaState.UNLOCK_ORBITAL)).override_failure_message("still held").is_true()


func test_banked_victory_survives_dying_in_endless() -> void:
	# BRIEF: continuing is pure upside — a later loss can never revoke a win.
	var meta := MetaState.new()
	meta.absorb(_result(200, 320.0, true))
	meta.absorb(_result(5, 30.0, false))
	assert_bool(meta.has_unlock(MetaState.UNLOCK_ORBITAL)).is_true()
	assert_that(meta.victories).is_equal(1)


# --- persistence ------------------------------------------------------------

func test_save_round_trip_preserves_everything() -> void:
	var meta := MetaState.new()
	meta.absorb(_result(120, 340.0, true))
	meta.absorb(_result(80, 150.0, false))
	var loaded := _round_trip(meta)
	assert_that(loaded.runs_played).is_equal(meta.runs_played)
	assert_that(loaded.victories).is_equal(meta.victories)
	assert_that(loaded.best_kills).is_equal(meta.best_kills)
	assert_float(float(loaded.best_time)).is_equal_approx(float(meta.best_time), float(0.001))
	assert_that(loaded.total_kills).is_equal(meta.total_kills)
	assert_bool(loaded.has_unlock(MetaState.UNLOCK_ORBITAL)).override_failure_message("unlocks survive").is_true()


func test_empty_save_loads_as_a_fresh_profile() -> void:
	var loaded := MetaState.from_dict({})
	assert_that(loaded.runs_played).is_equal(0)
	assert_that(loaded.unlocks.size()).is_equal(0)


func test_corrupt_values_fall_back_instead_of_crashing() -> void:
	# A corrupt save costs progress; a crash on boot costs the whole game.
	var loaded := MetaState.from_dict({
		"runs_played": "not a number", "unlocks": "not an array",
	})
	assert_that(loaded.runs_played).is_equal(0)
	assert_that(loaded.unlocks.size()).is_equal(0)


func test_duplicate_unlocks_in_a_save_are_collapsed() -> void:
	assert_that(MetaState.from_dict({"unlocks": ["orbital", "orbital"]}).unlocks.size()).is_equal(1)


func test_json_floats_are_narrowed_back_to_ints() -> void:
	# JSON has one number type and it is a double. Without narrowing on the way
	# in, runs_played comes back as 12.0 and every integer comparison against it
	# starts quietly lying. This is the failure mode the format change bought.
	var m := MetaState.new()
	m.runs_played = 12
	m.best_kills = 947
	m.total_kills = 30412
	var back := _round_trip(m)
	assert_that(typeof(back.runs_played)).override_failure_message("runs_played is an int").is_equal(TYPE_INT)
	assert_that(back.runs_played).is_equal(12)
	assert_that(back.best_kills).is_equal(947)
	assert_that(back.total_kills).is_equal(30412)


func test_a_hostile_save_cannot_construct_anything() -> void:
	# The reason this project is not on ConfigFile. That parser, measured on
	# 4.7.1, builds live objects out of a crafted file and runs an attacker's
	# _init() during load() — before any type check can intervene. JSON's
	# grammar cannot name a class, so the same payload is not a dangerous value,
	# it is a parse failure, and a parse failure is a fresh profile.
	var payload: String = '[meta]
x=Object(Node,"name":"pwned")
y=Resource("user://evil.tres")'
	# UserStore.parse is the exact code path a real save takes, and it stays
	# quiet on malformed input rather than pushing an engine error the smoke
	# gate would then grep as a failure.
	assert_that(UserStore.parse(payload)).override_failure_message("hostile payload does not parse as a save").is_equal({})
	var loaded := MetaState.from_dict(UserStore.parse(payload))
	assert_that(loaded.runs_played).override_failure_message("falls back to a fresh profile").is_equal(0)


func test_endless_survival_earns_endless_proven_via_update_records() -> void:
	# The exact shape of a real winning run: banked at victory (~5:20), then
	# death in endless past 10:00. Absorb sees time=320 so it can never grant
	# ENDLESS_PROVEN; the records-only update after the endless death must.
	var meta := MetaState.new()
	meta.absorb(_result(200, 320.0, true))
	assert_bool(meta.has_unlock(MetaState.UNLOCK_ENDLESS_PROVEN)).override_failure_message("not proven at the banking point").is_false()
	var gained: Array[StringName] = meta.update_records(_result(900, 640.0, true))
	assert_bool(meta.has_unlock(MetaState.UNLOCK_ENDLESS_PROVEN)).override_failure_message("surviving to the double boss earns it").is_true()
	assert_bool(gained.has(MetaState.UNLOCK_ENDLESS_PROVEN)).override_failure_message("and it is reported").is_true()
	assert_that(meta.runs_played).override_failure_message("endless still never counts as a second run").is_equal(1)


func test_update_records_reports_an_unlock_only_once() -> void:
	var meta := MetaState.new()
	meta.absorb(_result(200, 320.0, true))
	meta.update_records(_result(900, 640.0, true))
	assert_that(meta.update_records(_result(950, 700.0, true)).size()).is_equal(0)


# --- seeding ----------------------------------------------------------------

func test_same_seed_reproduces_the_same_draw() -> void:
	var a := RandomNumberGenerator.new()
	var b := RandomNumberGenerator.new()
	var run := RunState.with_seed(20260802)
	a.seed = run.seed_value
	b.seed = RunState.with_seed(20260802).seed_value
	for i: int in 8:
		assert_that(a.randi()).override_failure_message("draw %d matches" % i).is_equal(b.randi())
