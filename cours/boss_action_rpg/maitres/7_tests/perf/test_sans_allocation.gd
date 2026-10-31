extends GdUnitTestSuite
## Règles de mémoire du combat : ce qui tourne à chaque image ne crée aucun objet. Le rayon de visée, le chemin du
## golem, ses effets (onde, éclats, traînée, braise) et le passage à la seconde phase (bouclier qui tombe compris)
## n'allouent rien. Le compteur d'allocations de l'ObjectDB (les bits hauts de l'identifiant d'un objet témoin, créé
## puis libéré) voit chaque objet créé, même libéré aussitôt. Chaque travail est répété sans attendre d'image : un
## `await` crée lui-même un objet.

const MASQUE: int = (1 << 39) - 1
const GOLEM := preload("res://3_entities/boss/golem.tscn")
#@ 19+
const MAIN := preload("res://2_sequence/main.tscn")
#@ all
const DT: float = 1.0 / 60.0


func _compteur() -> int:
	var temoin: Object = Object.new()
	var c: int = (temoin.get_instance_id() >> 24) & MASQUE
	temoin.free()
	return c


## Les objets créés par `fois` appels de `travail` (le témoin du second relevé est retiré).
func _allocations(travail: Callable, fois: int) -> int:
	travail.call()
	var avant: int = _compteur()
	for _i: int in fois:
		travail.call()
	return _compteur() - avant - 1


func _golem(distance: float) -> Golem:
	var mark: Node3D = auto_free(Node3D.new()) as Node3D
	mark.position = Vector3(0.0, 0.0, -distance)
	add_child(mark)
	var golem: Golem = auto_free(GOLEM.instantiate()) as Golem
	golem.target = mark
	add_child(golem)
	return golem


func test_viser_ne_cree_rien() -> void:
	var space: PhysicsDirectSpaceState3D = get_tree().root.world_3d.direct_space_state
	var viser: Callable = func() -> void: Aim.point(space, Vector3(0.0, 1.0, 0.0), Vector3.FORWARD, 60.0, 1)
	assert_int(_allocations(viser, 100)).is_equal(0)


func test_le_chemin_du_golem_ne_cree_rien() -> void:
	var golem: Golem = _golem(8.0)
	var ecrasement: GolemAttack = golem.choose_attack(8.0)
	assert_str(ecrasement.id).is_equal("crush")
	var chemin: Callable = func() -> void: golem.path_clear(ecrasement)
	assert_int(_allocations(chemin, 100)).is_equal(0)


func test_les_effets_ne_creent_rien() -> void:
	var golem: Golem = _golem(3.0)
	var effets: GolemEffects = golem.get_node("Effects") as GolemEffects
	effets.process_mode = Node.PROCESS_MODE_DISABLED
	golem.machine.process_mode = Node.PROCESS_MODE_DISABLED
	golem.attack = golem.choose_attack(3.0)
	golem.machine.transition_to(&"Attack")
	var state: GolemAttackState = golem.machine.current as GolemAttackState
	var image: Callable = func() -> void:
		if golem.machine.current == state and state.clip_time < golem.attack.strike_end:
			state.physics_update(DT)
		effets.update(DT)
	var impact: Callable = func() -> void:
		golem.slammed.emit(Vector3(0.0, 0.0, -4.0), 3.5)
		effets.update(DT)
	assert_int(_allocations(image, 80)).is_equal(0)
	assert_int(effets.trail_count).is_greater(0)
	assert_int(_allocations(impact, 20)).is_equal(0)


func test_la_seconde_phase_ne_cree_rien() -> void:
	var golem: Golem = _golem(20.0)
	var effets: GolemEffects = golem.get_node("Effects") as GolemEffects
	var view: GolemView = golem.get_node("View") as GolemView
	effets.process_mode = Node.PROCESS_MODE_DISABLED
	view.process_mode = Node.PROCESS_MODE_DISABLED
	var avant: int = _compteur()
	golem.enter_phase_two()
	for _i: int in 60:
		view._physics_process(DT)
		effets.update(DT)
	assert_int(_compteur() - avant - 1).is_equal(0)
	assert_float(view.thrown_shield.global_position.y).is_less(1.0)
	assert_float(effets.glow).is_greater(0.0)
	view.thrown_shield.queue_free()
#@ 18+


func test_un_son_ne_cree_que_sa_lecture_dans_le_moteur() -> void:
	var board: SoundBoard = auto_free(SoundBoard.new())
	add_child(board)
	var cue: SoundCue = (load("res://5_data/audio/combat_sounds.tres") as CombatSoundSet).shot
	var jouer: Callable = func() -> void: board.play(cue, Vector3.ZERO)
	assert_int(_allocations(jouer, 20)).is_equal(2 * 20)
#@ 19+


func test_rejouer_les_effets_d_un_tir_ne_cree_rien() -> void:
	var main: Node3D = auto_free(MAIN.instantiate()) as Node3D
	add_child(main)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var impacts: ImpactSparks = main.get_node("ImpactSparks") as ImpactSparks
	var eclair: VfxBurst = main.get_node("Hero/Gun/MuzzleFlash") as VfxBurst
	var jouer: Callable = func() -> void:
		eclair.play()
		eclair.update(DT)
		impacts.play(Vector3(1.0, 1.0, 1.0), Vector3.BACK, 12.0)
	assert_int(_allocations(jouer, 40)).is_equal(0)
#@ all
