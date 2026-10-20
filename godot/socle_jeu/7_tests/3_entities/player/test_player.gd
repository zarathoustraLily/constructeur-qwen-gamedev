extends GdUnitTestSuite
## Joueur : marche, dash invincible puis recharge (réglages de 5_data/actors/player.tres),
## piloté par les vraies touches à travers player_input.gd.

const SCENE := "res://3_entities/player/player.tscn"


# GdUnitSceneRunner déclare simulate_frames() abstraite, sans corps : l'analyse n'y voit pas d'await.
# Son implémentation (GdUnitSceneRunnerImpl) attend les images : l'avertissement « await inutile » ne vaut
# pas ici, et sans await les images ne seraient pas jouées.
func test_marche_normalisee() -> void:
	var player: Player = auto_free(load(SCENE).instantiate())
	add_child(player)
	assert_float(player.walk_velocity(Vector3(1, 0, 1)).length()).is_equal_approx(player.stats.speed, 0.001)


func test_marche_puis_arret() -> void:
	var runner := scene_runner(SCENE)
	var player := runner.scene() as Player
	runner.simulate_action_press(&"move_right")
	@warning_ignore("redundant_await")
	await runner.simulate_frames(3)
	assert_str(player.state_machine.current_name()).is_equal("move")
	runner.simulate_action_release(&"move_right")
	@warning_ignore("redundant_await")
	await runner.simulate_frames(3)
	assert_str(player.state_machine.current_name()).is_equal("idle")


func test_dash_invincible_puis_recharge() -> void:
	var runner := scene_runner(SCENE)
	var player := runner.scene() as Player
	runner.simulate_action_press(&"dash")
	@warning_ignore("redundant_await")
	await runner.simulate_frames(2)
	runner.simulate_action_release(&"dash")
	assert_str(player.state_machine.current_name()).is_equal("dash")
	assert_bool(player.health.take_damage(1)).is_false()
	for i in ceili(player.stats.dash_duration * Engine.physics_ticks_per_second) + 3:
		await get_tree().physics_frame
	assert_str(player.state_machine.current_name()).is_equal("idle")
	assert_bool(player.health.is_invulnerable()).is_false()
	assert_bool(player.can_dash()).is_false()
