extends GdUnitTestSuite
## Lire et écrire une salle : la lecture rend une copie privée ; l'écriture garde toutes les valeurs, champs inconnus
## compris ; deux enregistrements successifs donnent les mêmes octets ; une salle invalide ou une destination hors du
## dossier des salles sont refusées sans toucher au fichier déjà là ; aucun fichier voisin ne reste après l'écriture.

const HANGAR: String = "res://5_data/salles/hangar.tres"
const ROOT: String = "user://test_salles"

var _store: RoomStore


func before_test() -> void:
	_vider()
	_store = RoomStore.new()
	_store.setup(ROOT)


func after_test() -> void:
	_vider()


func _vider() -> void:
	if not DirAccess.dir_exists_absolute(ROOT):
		return
	for file: String in DirAccess.get_files_at(ROOT):
		DirAccess.remove_absolute(ROOT.path_join(file))
	DirAccess.remove_absolute(ROOT)


func _bytes(path: String) -> PackedByteArray:
	return FileAccess.get_file_as_bytes(path)


func test_la_lecture_rend_une_copie_privee() -> void:
	var shared: RoomData = ResourceLoader.load(HANGAR) as RoomData
	var copy: RoomData = _store.load_room(HANGAR)
	assert_object(copy).is_not_null()
	assert_object(copy).is_not_same(shared)
	copy.display_name = "Autre nom"
	assert_str(shared.display_name).is_equal("Le hangar")


func test_l_ecriture_garde_toutes_les_valeurs() -> void:
	var room: RoomData = _store.load_room(HANGAR)
	assert_bool(_store.save_room(room, "hangar.tres")).is_true()
	var again: RoomData = _store.load_room(_store.path_of("hangar.tres"))
	assert_array(_store.errors).is_empty()
	assert_array(Array(again.thing_ids)).is_equal(Array(room.thing_ids))
	assert_array(Array(again.thing_positions)).is_equal(Array(room.thing_positions))
	assert_array(again.collisions).is_equal(room.collisions)
	assert_dict(again.thing_extras).is_equal(room.thing_extras)
	assert_dict(again.thing_extras).is_not_empty()


func test_deux_enregistrements_donnent_les_memes_octets() -> void:
	var room: RoomData = _store.load_room(HANGAR)
	assert_bool(_store.save_room(room, "premier.tres")).is_true()
	var reread: RoomData = _store.load_room(_store.path_of("premier.tres"))
	assert_bool(_store.save_room(reread, "second.tres")).is_true()
	assert_array(Array(_bytes(_store.path_of("second.tres")))).is_equal(Array(_bytes(_store.path_of("premier.tres"))))


func test_une_salle_invalide_ne_touche_pas_au_fichier() -> void:
	var room: RoomData = _store.load_room(HANGAR)
	assert_bool(_store.save_room(room, "hangar.tres")).is_true()
	var before_bytes: PackedByteArray = _bytes(_store.path_of("hangar.tres"))
	room.size_m = Vector2.ZERO
	assert_bool(_store.save_room(room, "hangar.tres")).is_false()
	assert_array(_store.errors).contains(["size_m : largeur et profondeur positives requises"])
	assert_array(Array(_bytes(_store.path_of("hangar.tres")))).is_equal(Array(before_bytes))


func test_une_destination_hors_du_dossier_est_refusee() -> void:
	var room: RoomData = _store.load_room(HANGAR)
	for filename: String in ["../hangar.tres", "hangar.json", "sous/hangar.tres"]:
		assert_bool(_store.save_room(room, filename)).is_false()
		assert_array(_store.errors).contains(["Destination refusée : un nom simple en .tres est requis"])


func test_aucun_fichier_voisin_ne_reste() -> void:
	var room: RoomData = _store.load_room(HANGAR)
	assert_bool(_store.save_room(room, "hangar.tres")).is_true()
	assert_bool(_store.save_room(room, "hangar.tres")).is_true()
	assert_array(Array(DirAccess.get_files_at(ROOT))).is_equal(["hangar.tres"])


func test_une_salle_introuvable_est_signalee() -> void:
	assert_object(_store.load_room(_store.path_of("absente.tres"))).is_null()
	assert_array(_store.errors).is_equal(["Salle introuvable : " + _store.path_of("absente.tres")])
