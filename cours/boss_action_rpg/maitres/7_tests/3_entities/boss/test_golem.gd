extends GdUnitTestSuite
## Règles du golem, à cette étape : il est sur la couche du boss et regarde le monde et le héros ; il est quatre fois
## plus grand qu'un homme ; la zone qui reçoit les tirs passe les dégâts à sa santé ; le point verrouillé est dans le
## groupe des cibles, à hauteur de poitrine ; son modèle joue l'attente.

const GOLEM := preload("res://3_entities/boss/golem.tscn")


func _golem() -> Golem:
	var golem: Golem = auto_free(GOLEM.instantiate()) as Golem
	add_child(golem)
	return golem


func test_il_est_sur_sa_couche_et_regarde_le_monde_et_le_heros() -> void:
	var golem: Golem = _golem()
	assert_int(golem.collision_layer).is_equal(Layers.bit(Layers.BOSS))
	assert_bool(Layers.has(golem.collision_mask, Layers.WORLD)).is_true()
	assert_bool(Layers.has(golem.collision_mask, Layers.HERO)).is_true()


func test_il_est_quatre_fois_plus_grand_qu_un_homme() -> void:
	var golem: Golem = _golem()
	var model: Node3D = golem.get_node("Model") as Node3D
	var body: MeshInstance3D = model.get_node("Skeleton3D/Body_geo") as MeshInstance3D
	var hauteur: float = body.mesh.get_aabb().size.y * model.scale.y
	assert_float(hauteur).is_between(6.5, 8.0)


func test_ses_tirs_recus_vont_a_sa_sante() -> void:
	var golem: Golem = _golem()
	var hurtbox: Hurtbox = golem.get_node("Hurtbox") as Hurtbox
	assert_that(hurtbox.health).is_same(golem.health)
	assert_float(hurtbox.receive(30.0)).is_equal(30.0)
	assert_float(golem.health.health).is_equal(golem.health.settings.max_health - 30.0)


func test_le_point_verrouille_est_a_hauteur_de_poitrine() -> void:
	var golem: Golem = _golem()
	assert_bool(golem.lock_point.is_in_group(LockOn.GROUP)).is_true()
	assert_float(golem.lock_point.position.y).is_between(4.0, 6.0)


func test_son_modele_joue_l_attente() -> void:
	var golem: Golem = _golem()
	await get_tree().process_frame
	var animation: AnimationPlayer = golem.get_node("Model/AnimationPlayer") as AnimationPlayer
	assert_str(animation.current_animation).is_equal("idle1")
	assert_bool(animation.is_playing()).is_true()
