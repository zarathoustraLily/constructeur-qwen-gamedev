extends GdUnitTestSuite
## Règles des améliorations : une amélioration augmente la propriété nommée de son bonus ; sa description montre la
## valeur actuelle puis la valeur après ; sans cible, le seul bonus ; l'amélioration de la santé monte la santé
## maximale et la santé actuelle d'autant ; une amélioration ne touche pas aux réglages du joueur.

const TEMOIN := preload("res://7_tests/1_core/upgrades/cible_temoin.gd")
const DAMAGE := preload("res://5_data/upgrades/damage.tres")
const HEALTH := preload("res://5_data/upgrades/health.tres")
const SPEED := preload("res://5_data/upgrades/speed.tres")
const PLAYER := preload("res://3_entities/player/player.tscn")


func test_elle_augmente_la_propriete_nommee_de_son_bonus() -> void:
	var target: Node = auto_free(TEMOIN.new())
	DAMAGE.apply(target)
	assert_float(target.get("damage_stat") as float).is_equal(150.0)


func test_sa_description_montre_la_valeur_actuelle_puis_la_valeur_apres() -> void:
	var target: Node = auto_free(TEMOIN.new())
	assert_str(DAMAGE.describe(target)).contains("100 %").contains("150 %")
	assert_str(DAMAGE.describe(null)).is_equal("+50.0")


func test_la_sante_monte_le_maximum_et_la_sante_actuelle() -> void:
	var target: Node = auto_free(Node.new())
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = 60.0
	target.add_child(health)
	add_child(target)
	health.take_damage(10.0)
	HEALTH.apply(target)
	assert_float(health.max_health).is_equal(80.0)
	assert_float(health.current_health).is_equal(70.0)


func test_la_vitesse_monte_l_etat_du_joueur_pas_ses_reglages() -> void:
	var player: Player = auto_free(PLAYER.instantiate())
	add_child(player)
	var initial := player.settings.movement_speed
	SPEED.apply(player)
	assert_float(player.movement_speed).is_equal(initial + SPEED.bonus)
	assert_float(player.settings.movement_speed).is_equal(initial)
