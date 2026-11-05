extends GdUnitTestSuite
## Les ennemis : les sept définitions du jeu se chargent du dossier, triées, et sont valides ; un rôle inconnu ou une
## santé nulle sont signalés ; une rencontre qui cite un ennemi inconnu, ou un ennemi sans point de son rôle, est
## signalée ; un point « tous » accueille tous les rôles ; un fichier d'une autre famille dans le dossier est signalé.

const FOLDER: String = "res://5_data/ennemis"


func _enemies() -> Array[EnemyDef]:
	var enemies: Array[EnemyDef] = []
	enemies.assign(DefinitionFolder.new().load_all(FOLDER, EnemyDef))
	return enemies


func _room() -> RoomData:
	return ResourceLoader.load("res://5_data/salles/soute.tres", "", ResourceLoader.CACHE_MODE_IGNORE) as RoomData


func test_les_sept_ennemis_se_chargent_tries_et_valides() -> void:
	var enemies: Array[EnemyDef] = _enemies()
	assert_int(enemies.size()).is_equal(7)
	assert_str(String(enemies[0].id)).is_equal("bombe")
	for enemy: EnemyDef in enemies:
		assert_array(enemy.validate()).is_empty()


func test_un_role_inconnu_ou_une_sante_nulle_sont_signales() -> void:
	var enemy: EnemyDef = _enemies()[0].duplicate() as EnemyDef
	enemy.role = &"volant"
	enemy.max_health = 0.0
	assert_array(enemy.validate()).contains_exactly(["ennemi bombe : rôle inconnu volant",
			"ennemi bombe : santé et poids positifs requis"])


func test_les_salles_d_exemple_ont_des_rencontres_completes() -> void:
	for room_name: String in ["hangar", "soute", "pont"]:
		var room: RoomData = ResourceLoader.load("res://5_data/salles/%s.tres" % room_name) as RoomData
		assert_array(EnemyDef.pool_errors(room, _enemies())).is_empty()


func test_un_ennemi_inconnu_ou_sans_point_est_signale() -> void:
	var room: RoomData = _room()
	room.encounter_pool = PackedStringArray(["licorne", "tireur"])
	room.spawn_roles = PackedStringArray(["melee", "melee", "melee", "melee", "melee", "melee", "melee", "melee"])
	assert_array(EnemyDef.pool_errors(room, _enemies())).contains_exactly(["rencontre : ennemi inconnu licorne",
			"rencontre : aucun point d'apparition pour tireur (distance)"])


func test_un_point_tous_accueille_tous_les_roles() -> void:
	var room: RoomData = _room()
	room.encounter_pool = PackedStringArray(["tireur", "brute"])
	room.spawn_roles = PackedStringArray(["tous", "tous", "tous", "tous", "tous", "tous", "tous", "tous"])
	assert_array(EnemyDef.pool_errors(room, _enemies())).is_empty()


func test_un_fichier_d_une_autre_famille_est_signale() -> void:
	var folder: DefinitionFolder = DefinitionFolder.new()
	var found: Array[Resource] = folder.load_all("res://5_data/salles", EnemyDef)
	assert_array(found).is_empty()
	assert_array(folder.errors).contains(["hangar.tres : pas une définition de cette famille"])
