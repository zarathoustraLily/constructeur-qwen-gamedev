extends GdUnitTestSuite
## Joueur : marche, dash invincible puis recharge (réglages de 5_data/actors/player.tres).

const SCENE := "res://3_entities/player/player.tscn"


func _joueur() -> Player:
	var player: Player = auto_free(load(SCENE).instantiate())
	player.read_input = false
	add_child(player)
	return player


func _pas(player: Player, n: int = 1) -> void:
	for i in n:
		player._physics_process(1.0 / 60.0)
		player.state_machine._physics_process(1.0 / 60.0)


func test_marche_normalisee() -> void:
	var player := _joueur()
	assert_float(player.walk_velocity(Vector3(1, 0, 1)).length()).is_equal_approx(player.stats.speed, 0.001)


func test_marche_puis_arret() -> void:
	var player := _joueur()
	player.move_input = Vector3.RIGHT
	_pas(player, 2)
	assert_str(player.state_machine.current_name()).is_equal("move")
	player.move_input = Vector3.ZERO
	_pas(player, 2)
	assert_str(player.state_machine.current_name()).is_equal("idle")


func test_dash_invincible_puis_recharge() -> void:
	var player := _joueur()
	player.wants_dash = true
	_pas(player)
	player.wants_dash = false
	assert_str(player.state_machine.current_name()).is_equal("dash")
	assert_bool(player.health.take_damage(1)).is_false()
	_pas(player, ceili(player.stats.dash_duration * 60.0) + 2)
	assert_str(player.state_machine.current_name()).is_equal("idle")
	assert_bool(player.health.invulnerable).is_false()
	assert_bool(player.can_dash()).is_false()
	player.wants_dash = true
	_pas(player)
	assert_str(player.state_machine.current_name()).is_equal("idle")
