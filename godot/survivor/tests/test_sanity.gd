extends GdUnitTestSuite
## Proves the GUT harness runs. Real logic tests replace this as systems appear.


func test_engine_is_godot_4_7() -> void:
	var v: Dictionary = Engine.get_version_info()
	assert_that(v["major"]).append_failure_message("major version").is_equal(4)
	assert_that(v["minor"]).append_failure_message("minor version").is_equal(7)
