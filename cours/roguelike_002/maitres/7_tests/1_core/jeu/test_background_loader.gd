extends GdUnitTestSuite
## Le chargement en fond : de vraies textures du jeu arrivent, la progression finit à 1 ; un chemin absent compte
## tout de suite comme un échec, sans être demandé ; une liste vide est finie d'emblée.

const FOND: String = "res://6_assets/jeu/menu/fond.png"
const PLANETE: String = "res://6_assets/jeu/menu/planete.png"
const ABSENT: String = "res://6_assets/jeu/menu/absent.png"
## Le délai d'attente d'un chargement, en millisecondes de vraie horloge : sans fenêtre, à cadence fixe, des
## centaines d'images passent en un dixième de seconde, bien avant qu'une grande texture soit lue.
const DELAI_MS: int = 10000


func _attendre(loader: BackgroundLoader) -> void:
	var limite: int = Time.get_ticks_msec() + DELAI_MS
	while Time.get_ticks_msec() < limite:
		loader.poll()
		if loader.is_done():
			return
		await get_tree().process_frame


func test_les_textures_du_menu_arrivent() -> void:
	var loader := BackgroundLoader.new()
	loader.start([FOND, PLANETE])
	await _attendre(loader)
	assert_bool(loader.is_done()).is_true()
	assert_float(loader.progress()).is_equal(1.0)
	assert_object(loader.get_resource(FOND)).is_instanceof(Texture2D)
	assert_object(loader.get_resource(PLANETE)).is_instanceof(Texture2D)
	assert_array(loader.failed()).is_empty()


func test_un_chemin_absent_est_un_echec_immediat() -> void:
	var loader := BackgroundLoader.new()
	loader.start([ABSENT])
	assert_array(loader.failed()).is_equal([ABSENT])
	assert_bool(loader.is_done()).is_true()
	assert_float(loader.progress()).is_equal(1.0)
	assert_object(loader.get_resource(ABSENT)).is_null()


func test_un_absent_compte_pour_sa_part() -> void:
	var loader := BackgroundLoader.new()
	loader.start([ABSENT, FOND])
	assert_float(loader.progress()).is_greater_equal(0.5)
	await _attendre(loader)
	assert_float(loader.progress()).is_equal(1.0)
	assert_array(loader.failed()).is_equal([ABSENT])


func test_un_chargement_abandonne_est_repris() -> void:
	var loader := BackgroundLoader.new()
	loader.start([FOND, PLANETE])
	loader.release()
	assert_bool(loader.is_done()).is_true()
	assert_object(loader.get_resource(PLANETE)).is_instanceof(Texture2D)


func test_rien_a_charger_est_fini() -> void:
	var loader := BackgroundLoader.new()
	loader.start([])
	assert_bool(loader.is_done()).is_true()
	assert_float(loader.progress()).is_equal(1.0)
