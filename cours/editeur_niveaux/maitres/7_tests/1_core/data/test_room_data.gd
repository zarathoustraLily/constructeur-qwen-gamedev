extends GdUnitTestSuite
## Règles de validation d'une salle : les trois salles d'exemple sont valides ; une colonne de la mauvaise longueur, un
## identifiant en double, un calque inconnu, un parent absent, une échelle nulle, une forme de deux sommets, un rôle
## d'apparition inconnu ou des champs inconnus illisibles sont signalés, chacun par sa phrase.

const ROOMS: Array[String] = ["res://5_data/salles/hangar.tres", "res://5_data/salles/soute.tres",
	"res://5_data/salles/pont.tres"]


# Une copie privée du hangar : la modifier ne touche pas la ressource partagée du cache.
func _hangar() -> RoomData:
	return ResourceLoader.load(ROOMS[0], "", ResourceLoader.CACHE_MODE_IGNORE) as RoomData


func test_les_trois_salles_d_exemple_sont_valides() -> void:
	for path: String in ROOMS:
		var room: RoomData = ResourceLoader.load(path) as RoomData
		assert_object(room).is_not_null()
		assert_array(room.validate()).is_empty()
		assert_int(room.thing_count()).is_greater(0)


func test_une_colonne_trop_courte_est_signalee() -> void:
	var room: RoomData = _hangar()
	# Un tableau compact se lit et se réécrit en entier : le modifier sur place ne changerait que sa copie.
	var names: PackedStringArray = room.thing_names
	names.remove_at(0)
	room.thing_names = names
	var expected: String = "thing_names : %d valeurs pour %d choses" % [names.size(), room.thing_count()]
	assert_array(room.validate()).contains([expected])


func test_un_identifiant_en_double_est_signale() -> void:
	var room: RoomData = _hangar()
	var ids: PackedInt32Array = room.thing_ids
	ids[1] = ids[0]
	room.thing_ids = ids
	assert_array(room.validate()).contains(["thing_ids : identifiant %d en double" % ids[0]])


func test_un_calque_inconnu_est_signale() -> void:
	var room: RoomData = _hangar()
	var layers: PackedStringArray = room.thing_layers
	layers[0] = "plafond"
	room.thing_layers = layers
	assert_array(room.validate()).contains(["chose %d : calque inconnu plafond" % room.thing_ids[0]])


func test_un_parent_absent_est_signale() -> void:
	var room: RoomData = _hangar()
	var parents: PackedInt32Array = room.thing_parents
	parents[0] = 99999
	room.thing_parents = parents
	assert_array(room.validate()).contains(["chose %d : parent 99999 introuvable" % room.thing_ids[0]])


func test_une_echelle_nulle_est_signalee() -> void:
	var room: RoomData = _hangar()
	var scales: PackedFloat32Array = room.thing_scales
	scales[0] = 0.0
	room.thing_scales = scales
	assert_array(room.validate()).contains(["chose %d : échelle positive requise" % room.thing_ids[0]])


func test_une_forme_de_deux_sommets_est_signalee() -> void:
	var room: RoomData = _hangar()
	room.collisions.append(PackedVector2Array([Vector2.ZERO, Vector2.ONE]))
	var index: int = room.collisions.size() - 1
	assert_array(room.validate()).contains(["collision %d : au moins 3 sommets requis" % index])


func test_un_role_d_apparition_inconnu_est_signale() -> void:
	var room: RoomData = _hangar()
	var roles: PackedStringArray = room.spawn_roles
	roles[0] = "volant"
	room.spawn_roles = roles
	assert_array(room.validate()).contains(["apparition 0 : rôle inconnu volant"])


func test_des_champs_inconnus_illisibles_sont_signales() -> void:
	var room: RoomData = _hangar()
	var thing_id: int = room.thing_ids[0]
	room.thing_extras[thing_id] = "{pas du json"
	assert_array(room.validate()).contains(["chose %d : champs inconnus illisibles" % thing_id])


func test_l_indice_d_une_chose_se_retrouve_par_son_identifiant() -> void:
	var room: RoomData = _hangar()
	var last: int = room.thing_count() - 1
	assert_int(room.index_of(room.thing_ids[last])).is_equal(last)
	assert_int(room.index_of(-5)).is_equal(-1)
