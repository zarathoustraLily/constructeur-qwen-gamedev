extends GdUnitTestSuite
## Règles de Bobine : les clips du héros font bouger ses grands os ; son corps est une seule surface,
## liée à ce squelette, un lot de dessin ; le haut de sa jupe suit les hanches, son ourlet suit les cuisses ; elle tient debout, les pieds au sol ; aucune pièce de bois ne suit un os qui
## n'existe pas ; le canon de son arme finit à la bouche que lit la vue ; le héros de la scène est bien elle.


const MODEL := preload("res://3_entities/hero/bobine/bobine_model.tscn")
const HERO := preload("res://3_entities/hero/hero.tscn")


func _model() -> BobineModel:
	var model: BobineModel = auto_free(MODEL.instantiate())
	add_child(model)
	return model


func test_les_clips_du_heros_font_bouger_ses_grands_os() -> void:
	var model: BobineModel = _model()
	var skeleton: Skeleton3D = model.get_node(^"%GeneralSkeleton") as Skeleton3D
	var player: AnimationPlayer = model.get_node(^"AnimationPlayer") as AnimationPlayer
	assert_int(player.get_animation_list().size()).is_greater_equal(13)
	var run: Animation = player.get_animation(&"run")
	for bone: String in ["Hips", "Chest", "Head", "LeftUpperArm", "RightLowerArm", "LeftUpperLeg", "RightLowerLeg", "LeftFoot"]:
		assert_int(skeleton.find_bone(bone)).is_greater_equal(0)
		var path: NodePath = NodePath("%GeneralSkeleton:" + bone)
		assert_int(run.find_track(path, Animation.TYPE_ROTATION_3D)).override_failure_message("sans piste : " + bone).is_greater_equal(0)


func test_son_corps_est_une_seule_surface_liee_a_son_squelette() -> void:
	var model: BobineModel = _model()
	var body: MeshInstance3D = model.get_node(^"%Body") as MeshInstance3D
	var skeleton: Skeleton3D = model.get_node(^"%GeneralSkeleton") as Skeleton3D
	assert_int(body.mesh.get_surface_count()).is_equal(1)
	assert_that(body.get_node(body.skeleton)).is_same(skeleton)
	assert_int(body.skin.get_bind_count()).is_equal(skeleton.get_bone_count())


func test_le_haut_de_sa_jupe_suit_les_hanches_et_son_ourlet_les_cuisses() -> void:
	var model: BobineModel = _model()
	var skeleton: Skeleton3D = model.get_node(^"%GeneralSkeleton") as Skeleton3D
	var body: MeshInstance3D = model.get_node(^"%Body") as MeshInstance3D
	var arrays: Array = body.mesh.surface_get_arrays(0)
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var left: int = skeleton.find_bone("LeftUpperLeg")
	var on_leg: float = 0.0
	for i: int in vertices.size():
		for k: int in 4:
			if bones[i * 4 + k] == left and vertices[i].length() > 0.0 and absf(vertices[i].y - 0.66) < 0.02 and Vector2(vertices[i].x, vertices[i].z).length() > 0.29:
				on_leg = maxf(on_leg, weights[i * 4 + k])
	assert_float(on_leg).is_greater(0.4)


func test_elle_tient_debout_les_pieds_au_sol() -> void:
	var box: AABB = (_model().get_node(^"%Body") as MeshInstance3D).mesh.get_aabb()
	assert_float(box.position.y).is_between(-0.02, 0.03)
	assert_float(box.end.y).is_between(1.85, 2.05)


func test_chaque_sommet_suit_un_os_qui_existe() -> void:
	var model: BobineModel = _model()
	var count: int = (model.get_node(^"%GeneralSkeleton") as Skeleton3D).get_bone_count()
	var arrays: Array = (model.get_node(^"%Body") as MeshInstance3D).mesh.surface_get_arrays(0)
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	for bone: int in bones:
		assert_int(bone).is_between(0, count - 1)


func test_le_canon_de_son_arme_finit_a_la_bouche_que_lit_la_vue() -> void:
	var model: BobineModel = _model()
	var weapon: MeshInstance3D = model.get_node(^"%WeaponMesh") as MeshInstance3D
	var muzzle: Marker3D = model.get_node(^"%Muzzle") as Marker3D
	assert_float(weapon.mesh.get_aabb().position.z).is_equal_approx(muzzle.position.z, 0.02)


func test_le_heros_de_la_scene_est_bobine() -> void:
	var hero: Hero = auto_free(HERO.instantiate())
	add_child(hero)
	assert_object(hero.get_node(^"View/Model") as BobineModel).is_not_null()
