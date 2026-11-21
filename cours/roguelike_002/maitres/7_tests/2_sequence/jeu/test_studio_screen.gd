extends GdUnitTestSuite
## L'écran du studio : la marque apparaît de 0 à 1, tient tant que le chargement n'est pas fini (même après la tenue
## minimale), disparaît quand il l'est, puis émet `finished` une seule fois avec l'écran suivant. La vue montre le nom
## et suit le chargement. L'écran du jeu, avec ses vraies données, charge les images du menu puis finit.

const SCENE: String = "res://2_sequence/jeu/studio_screen.tscn"
const PAS: float = 0.1
## Le délai d'attente du vrai chargement, en millisecondes de vraie horloge (voir test_background_loader.gd).
const DELAI_MS: int = 10000


## Un chargement dont le test décide la fin.
class FauxChargement extends BackgroundLoader:
	var fini: bool = false
	var avance: float = 0.0

	func start(_paths: Array[String]) -> void:
		pass

	func poll() -> void:
		pass

	func is_done() -> bool:
		return fini

	func progress() -> float:
		return avance


func _donnee() -> StudioDef:
	var studio := StudioDef.new()
	studio.studio_name = "Studio témoin"
	studio.fade_in_s = 0.5
	studio.min_hold_s = 0.5
	studio.fade_out_s = 0.5
	studio.next_screen = &"suite"
	return studio


func _ecran(chargement: BackgroundLoader) -> StudioScreen:
	var ecran: StudioScreen = auto_free(load(SCENE).instantiate())
	ecran.studio = _donnee()
	ecran.setup(chargement)
	add_child(ecran)
	ecran.set_process(false)
	return ecran


func _avancer(ecran: StudioScreen, secondes: float) -> void:
	var reste: float = secondes
	while reste > 0.0:
		ecran.advance(minf(PAS, reste))
		reste -= PAS


func test_la_marque_apparait() -> void:
	var ecran := _ecran(FauxChargement.new())
	assert_float(ecran.opacity()).is_equal(0.0)
	_avancer(ecran, 0.25)
	assert_float(ecran.opacity()).is_between(0.4, 0.6)
	_avancer(ecran, 0.3)
	assert_int(ecran.phase).is_equal(StudioScreen.Phase.HOLD)
	assert_float(ecran.opacity()).is_equal(1.0)


func test_l_ecran_attend_la_fin_du_chargement() -> void:
	var chargement := FauxChargement.new()
	var ecran := _ecran(chargement)
	_avancer(ecran, 3.0)
	assert_int(ecran.phase).is_equal(StudioScreen.Phase.HOLD)
	chargement.fini = true
	ecran.advance(PAS)
	assert_int(ecran.phase).is_equal(StudioScreen.Phase.FADE_OUT)


func test_l_ecran_finit_une_seule_fois_avec_le_suivant() -> void:
	var chargement := FauxChargement.new()
	chargement.fini = true
	var ecran := _ecran(chargement)
	var suivants: Array[StringName] = []
	ecran.finished.connect(func(next: StringName) -> void: suivants.append(next))
	_avancer(ecran, 3.0)
	assert_int(ecran.phase).is_equal(StudioScreen.Phase.DONE)
	assert_float(ecran.opacity()).is_equal(0.0)
	assert_array(suivants).is_equal([&"suite"])


func test_la_vue_montre_le_nom_et_suit_le_chargement() -> void:
	var chargement := FauxChargement.new()
	var ecran := _ecran(chargement)
	var vue: StudioView = ecran.get_node("View")
	assert_str(vue.shown_name()).is_equal("Studio témoin")
	chargement.avance = 0.4
	ecran.advance(PAS)
	assert_float(vue.shown_progress()).is_equal_approx(0.4, 0.001)
	assert_float(vue.shown_opacity()).is_equal_approx(ecran.opacity(), 0.001)


func test_l_ecran_du_jeu_charge_le_menu_puis_finit() -> void:
	var ecran: StudioScreen = auto_free(load(SCENE).instantiate())
	add_child(ecran)
	ecran.set_process(false)
	var fins: Array[StringName] = []
	ecran.finished.connect(func(next: StringName) -> void: fins.append(next))
	var limite: int = Time.get_ticks_msec() + DELAI_MS
	while Time.get_ticks_msec() < limite:
		ecran.advance(PAS)
		if not fins.is_empty():
			break
		await get_tree().process_frame
	assert_array(fins).has_size(1)
	assert_float(ecran.load_progress()).is_equal(1.0)
