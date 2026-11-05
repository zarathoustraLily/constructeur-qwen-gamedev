extends GdUnitTestSuite
## Le document : une modification valide devient un pas d'annulation et rend la salle modifiée ; une valeur invalide,
## d'un mauvais type ou d'un champ inconnu est refusée sans rien changer ; ajouter, supprimer et changer plusieurs
## choses d'un coup font chacun un seul pas ; une chose attachée protège son parent ; « enregistré » se suit par
## révision ; un abonné ne peut pas modifier la salle pendant une notification.

const PONT: String = "res://5_data/salles/pont.tres"

var _dirty_events: Array[bool] = []


func _document() -> RoomDocument:
	_dirty_events.clear()
	var document: RoomDocument = RoomDocument.new()
	document.dirty_changed.connect(func(dirty: bool) -> void: _dirty_events.append(dirty))
	assert_bool(document.open(RoomStore.new().load_room(PONT))).is_true()
	return document


func test_une_salle_ouverte_n_est_pas_modifiee() -> void:
	var document: RoomDocument = _document()
	assert_bool(document.is_dirty()).is_false()
	assert_bool(document.can_undo()).is_false()


func test_une_modification_se_defait_et_se_refait() -> void:
	var document: RoomDocument = _document()
	var thing_id: int = document.ids()[0]
	var before_position: Vector3 = document.value(thing_id, &"position")
	assert_bool(document.set_value(thing_id, &"position", Vector3(5, 0, 7))).is_true()
	assert_vector(document.value(thing_id, &"position")).is_equal(Vector3(5, 0, 7))
	assert_bool(document.is_dirty()).is_true()
	assert_bool(document.undo()).is_true()
	assert_vector(document.value(thing_id, &"position")).is_equal(before_position)
	assert_bool(document.is_dirty()).is_false()
	assert_bool(document.redo()).is_true()
	assert_vector(document.value(thing_id, &"position")).is_equal(Vector3(5, 0, 7))
	assert_array(_dirty_events).is_equal([true, false, true])


func test_une_valeur_invalide_est_refusee_sans_rien_changer() -> void:
	var document: RoomDocument = _document()
	var thing_id: int = document.ids()[0]
	assert_bool(document.set_value(thing_id, &"scale", 0.0)).is_false()
	assert_array(document.errors).contains(["chose %d : échelle positive requise" % thing_id])
	assert_float(document.value(thing_id, &"scale")).is_equal(1.0)
	assert_bool(document.is_dirty()).is_false()
	assert_bool(document.can_undo()).is_false()


func test_un_mauvais_type_et_un_champ_inconnu_sont_refuses() -> void:
	var document: RoomDocument = _document()
	var thing_id: int = document.ids()[0]
	assert_bool(document.set_value(thing_id, &"position", Vector2(1, 2))).is_false()
	assert_array(document.errors).is_equal(["position : Vector3 attendu"])
	assert_bool(document.set_value(thing_id, &"couleur_preferee", 3)).is_false()
	assert_array(document.errors).is_equal(["couleur_preferee : champ inconnu ou non modifiable"])
	assert_bool(document.set_value(99999, &"scale", 2.0)).is_false()
	assert_array(document.errors).is_equal(["chose 99999 introuvable"])


func test_un_entier_vaut_pour_un_nombre_a_virgule() -> void:
	var document: RoomDocument = _document()
	var thing_id: int = document.ids()[0]
	assert_bool(document.set_value(thing_id, &"scale", 2)).is_true()
	assert_float(document.value(thing_id, &"scale")).is_equal(2.0)


func test_ajouter_une_chose_fait_un_pas() -> void:
	var document: RoomDocument = _document()
	var count: int = document.ids().size()
	var new_id: int = document.add_thing({&"asset": "caisse_cargo", &"layer": "obstacles", &"position": Vector3(3, 0, 3)})
	assert_int(new_id).is_greater(0)
	assert_int(document.ids().size()).is_equal(count + 1)
	assert_str(document.value(new_id, &"asset")).is_equal("caisse_cargo")
	assert_float(document.value(new_id, &"scale")).is_equal(1.0)
	document.undo()
	assert_int(document.ids().size()).is_equal(count)


func test_une_nouvelle_chose_sans_calque_est_refusee() -> void:
	var document: RoomDocument = _document()
	assert_int(document.add_thing({&"asset": "caisse_cargo"})).is_equal(0)
	assert_array(document.errors).is_equal(["layer : champ requis pour une nouvelle chose"])


func test_une_chose_attachee_protege_son_parent() -> void:
	var document: RoomDocument = _document()
	var parent: int = document.ids()[0]
	var child: int = document.add_thing({&"asset": "lampe", &"layer": "avant_plan", &"parent": parent})
	assert_bool(document.remove_things([parent])).is_false()
	assert_array(document.errors).is_equal(["Suppression refusée : la chose %d est attachée à la chose %d" % [child,
			parent]])
	assert_bool(document.remove_things([parent, child])).is_true()
	assert_int(document.ids().find(parent)).is_equal(-1)


func test_plusieurs_choses_changent_en_un_seul_pas() -> void:
	var document: RoomDocument = _document()
	var a: int = document.ids()[0]
	var b: int = document.ids()[1]
	assert_bool(document.apply({a: {&"rotation": 90.0}, b: {&"rotation": 180.0, &"scale": 2.0}})).is_true()
	assert_bool(document.undo()).is_true()
	assert_bool(document.can_undo()).is_false()
	assert_float(document.value(b, &"rotation")).is_equal(0.0)


func test_enregistrer_se_suit_par_revision() -> void:
	var document: RoomDocument = _document()
	var thing_id: int = document.ids()[0]
	document.set_value(thing_id, &"height", 1.5)
	document.mark_saved()
	assert_bool(document.is_dirty()).is_false()
	document.undo()
	assert_bool(document.is_dirty()).is_true()


func test_un_abonne_ne_modifie_pas_la_salle_pendant_la_notification() -> void:
	var document: RoomDocument = _document()
	var thing_id: int = document.ids()[0]
	var refused: Array[bool] = []
	var handler: Callable = func() -> void: refused.append(not document.set_value(thing_id, &"height", 9.0))
	document.changed.connect(handler)
	document.set_value(thing_id, &"height", 1.0)
	# La fonction garde le document, et le document la garde par son signal : sans ce débranchement, aucun des deux ne
	# serait jamais libéré (« ObjectDB instances were leaked at exit »).
	document.changed.disconnect(handler)
	assert_array(refused).is_equal([true])
	assert_float(document.value(thing_id, &"height")).is_equal(1.0)


func test_les_champs_inconnus_suivent_leur_chose() -> void:
	var store: RoomStore = RoomStore.new()
	var room: RoomData = store.load_room("res://5_data/salles/hangar.tres")
	var document: RoomDocument = RoomDocument.new()
	document.open(room)
	var thing_id: int = room.thing_extras.keys()[0]
	assert_str(document.extras(thing_id)).is_not_empty()
	assert_bool(document.remove_things([thing_id])).is_true()
	assert_str(document.extras(thing_id)).is_empty()
	document.undo()
	assert_str(document.extras(thing_id)).is_not_empty()
#@ 10+


func test_les_champs_de_la_salle_se_modifient_en_un_pas() -> void:
	var document: RoomDocument = _document()
	assert_bool(document.set_room_fields({&"hero_start": Vector3(4, 0, 5), &"encounter_depth": 2})).is_true()
	assert_vector(document.room_value(&"hero_start")).is_equal(Vector3(4, 0, 5))
	assert_bool(document.undo()).is_true()
	assert_bool(document.can_undo()).is_false()


func test_un_champ_de_salle_inconnu_ou_mal_type_est_refuse() -> void:
	var document: RoomDocument = _document()
#@ 10-15
	assert_bool(document.set_room_fields({&"display_name": "Autre"})).is_false()
	assert_array(document.errors).is_equal(["display_name : champ de salle inconnu ou non modifiable"])
#@ 16+
	assert_bool(document.set_room_fields({&"size_m": Vector2.ONE})).is_false()
	assert_array(document.errors).is_equal(["size_m : champ de salle inconnu ou non modifiable"])
#@ 10+
	assert_bool(document.set_room_fields({&"encounter_depth": "trois"})).is_false()
	assert_array(document.errors).is_equal(["encounter_depth : int attendu"])


func test_une_collision_croisee_est_refusee_par_le_document() -> void:
	var document: RoomDocument = _document()
	var polygons: Array = document.room_value(&"collisions")
	polygons.append(PackedVector2Array([Vector2(0, 0), Vector2(2, 2), Vector2(2, 0), Vector2(0, 2)]))
	assert_bool(document.set_room_fields({&"collisions": polygons})).is_false()
	assert_array(document.errors).contains(["collision %d : des côtés se croisent" % (polygons.size() - 1)])
#@ all
