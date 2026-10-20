extends GdUnitTestSuite
## Règles du chef d'orchestre, qui seul charge les scènes : il charge la première étape de la séquence reçue,
## puis la suivante quand l'étape finit ; après la dernière, il revient à la première ; « retry » recharge
## l'étape en cours, « restart » la première ; une séquence vide ne charge rien. La séquence du jeu commence par
## la scène principale, et la scène de démarrage la lui remet.

const STEP_A := preload("res://7_tests/0_autoload/step_a.tscn")
const STEP_B := preload("res://7_tests/0_autoload/step_b.tscn")
const GAME_SEQUENCE := preload("res://2_sequence/sequence.tres")
const BOOT := preload("res://2_sequence/boot.tscn")

var _saved_sequence: Sequence
var _saved_index: int
var _saved_scene: Node
var _placeholder: Node


func before_test() -> void:
	_saved_sequence = GameFlow.sequence
	_saved_index = GameFlow.index
	_saved_scene = get_tree().current_scene
	# Une scène courante jetable : GameFlow la libère en chargeant la première étape.
	_placeholder = Node.new()
	get_tree().root.add_child(_placeholder)
	get_tree().current_scene = _placeholder


func after_test() -> void:
	var current := get_tree().current_scene
	if is_instance_valid(current) and current != _saved_scene:
		current.free()
	if is_instance_valid(_placeholder):
		_placeholder.free()
	get_tree().current_scene = _saved_scene
	GameFlow.sequence = _saved_sequence
	GameFlow.index = _saved_index


func _sequence() -> Sequence:
	var sequence := Sequence.new()
	sequence.steps = [STEP_A, STEP_B]
	return sequence


## Le nom de la scène courante, une fois les nœuds libérés en fin d'image.
func _current_name() -> String:
	await get_tree().process_frame
	return str(get_tree().current_scene.name)


func test_il_charge_la_premiere_etape_de_la_sequence() -> void:
	GameFlow.start(_sequence())
	assert_str(await _current_name()).is_equal("StepA")
	assert_int(GameFlow.index).is_equal(0)


func test_quand_l_etape_finit_il_charge_la_suivante() -> void:
	GameFlow.start(_sequence())
	GameFlow.current_step.finish()
	assert_str(await _current_name()).is_equal("StepB")


func test_apres_la_derniere_il_revient_a_la_premiere() -> void:
	GameFlow.start(_sequence())
	GameFlow.current_step.finish()
	GameFlow.current_step.finish()
	assert_str(await _current_name()).is_equal("StepA")
	assert_int(GameFlow.index).is_equal(0)


func test_retry_recharge_l_etape_en_cours() -> void:
	GameFlow.start(_sequence())
	GameFlow.current_step.finish()
	var previous_step := GameFlow.current_step
	GameFlow.current_step.finish(&"retry")
	assert_str(await _current_name()).is_equal("StepB")
	assert_object(GameFlow.current_step).is_not_same(previous_step)


func test_restart_revient_a_la_premiere() -> void:
	GameFlow.start(_sequence())
	GameFlow.current_step.finish()
	GameFlow.current_step.finish(&"restart")
	assert_str(await _current_name()).is_equal("StepA")


func test_une_sequence_vide_ne_charge_rien() -> void:
	assert_error(func() -> void: GameFlow.start(Sequence.new())).is_push_error("GameFlow.start : séquence vide")
	assert_object(get_tree().current_scene).is_same(_placeholder)


func test_la_sequence_du_jeu_commence_par_la_scene_principale() -> void:
	assert_array(GAME_SEQUENCE.steps).is_not_empty()
	assert_str(GAME_SEQUENCE.steps[0].resource_path).is_equal("res://2_sequence/main.tscn")


func test_la_scene_de_demarrage_remet_la_sequence_du_jeu() -> void:
	var boot := BOOT.instantiate()
	assert_object(boot.get("sequence")).is_same(GAME_SEQUENCE)
	boot.free()
