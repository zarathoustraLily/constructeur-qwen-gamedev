class_name CombatSounds extends Node
## Les sons du combat : il écoute le héros, le Gardien, les spectres et les tirs, et fait jouer à la table des sons le
## son de chaque événement, là où il a lieu. Il lance la musique au réveil du Gardien et l'éteint à la fin du combat.
## Les pas suivent la distance parcourue au sol. Il ne décide rien du jeu.
##
## Un tir qui touche une cible passe d'abord par sa zone de dégâts (Hurtbox.received), puis le projectile dit son
## impact (ProjectilePool.impacted) : la zone touchée choisit le son, l'impact donne sa place. Sans zone touchée juste
## avant, le tir a fini dans le décor.

## Les sons, par événement.
@export var sounds: CombatSoundSet
## La table qui les joue.
@export var board: SoundBoard
## La musique du combat.
@export var music: MusicPlayer
## Le héros.
@export var hero: Hero
## Le Gardien.
@export var golem: Golem
## Ses spectres.
@export var spectres: Array[Spectre] = []
## Les tirs du héros.
@export var projectiles: ProjectilePool

var _target_cue: SoundCue
var _hero_walked: float = 0.0
var _golem_walked: float = 0.0
var _hero_last: Vector3 = Vector3.ZERO
var _golem_last: Vector3 = Vector3.ZERO


func _ready() -> void:
	process_physics_priority = ProcessOrder.VIEWS
	hero.gun.fired.connect(_on_fired)
	hero.machine.state_changed.connect(_on_hero_state)
	hero.defeated.connect(_on_fight_over)
	golem.woke.connect(_on_golem_woke)
	golem.slammed.connect(_on_golem_slammed)
	golem.phase_changed.connect(_on_golem_phase)
	golem.defeated.connect(_on_golem_defeated)
	golem.hammer.landed.connect(_on_hammer_landed)
	projectiles.impacted.connect(_on_impacted)
	(golem.get_node(^"Hurtbox") as Hurtbox).received.connect(_on_received.bind(sounds.hit_golem))
	(golem.get_node(^"BackWeakPoint") as Hurtbox).received.connect(_on_received.bind(sounds.hit_weak_point))
	golem.shield.received.connect(_on_received.bind(sounds.hit_shield))
	for spectre: Spectre in spectres:
		spectre.hurtbox.received.connect(_on_received.bind(sounds.hit_spectre))
		spectre.machine.state_changed.connect(_on_spectre_state.bind(spectre))
	_hero_last = hero.global_position
	_golem_last = golem.global_position


## Les pas : un son de pas à chaque foulée parcourue au sol, pour le héros qui court et pour le Gardien éveillé.
func _physics_process(_delta: float) -> void:
	var h: Vector3 = hero.global_position
	if hero.is_on_floor() and hero.machine.current.name == &"Move":
		_hero_walked += Vector2(h.x - _hero_last.x, h.z - _hero_last.z).length()
		if _hero_walked >= sounds.hero_stride:
			_hero_walked = fmod(_hero_walked, sounds.hero_stride)
			board.play(sounds.hero_step, h)
	_hero_last = h
	var g: Vector3 = golem.global_position
	var etat: StringName = golem.machine.current.name
	if etat != &"Dormant" and etat != &"Dead":
		_golem_walked += Vector2(g.x - _golem_last.x, g.z - _golem_last.z).length()
		if _golem_walked >= sounds.golem_stride:
			_golem_walked = fmod(_golem_walked, sounds.golem_stride)
			board.play(sounds.golem_step, g)
	_golem_last = g


func _on_fired(origin: Vector3, _direction: Vector3) -> void:
	board.play(sounds.shot, origin)


func _on_hero_state(from: StringName, to: StringName) -> void:
	var at: Vector3 = hero.global_position
	match to:
		&"Roll":
			board.play(sounds.roll, at)
		&"Jump":
			board.play(sounds.jump, at)
		&"Hit":
			board.play(sounds.hero_hurt, at)
		&"Heal":
			board.play(sounds.heal, at)
		&"Dead":
			board.play(sounds.hero_down, at)
		&"Move":
			if from == &"Jump":
				board.play(sounds.land, at)


func _on_fight_over() -> void:
	music.fade_out()


func _on_golem_woke() -> void:
	board.play(sounds.golem_wake, golem.global_position)
	music.start()


func _on_golem_slammed(point: Vector3, _radius: float) -> void:
	board.play(sounds.golem_slam, point)


func _on_golem_phase(phase: int) -> void:
	if phase == 2:
		board.play(sounds.golem_phase, golem.global_position)


func _on_golem_defeated() -> void:
	board.play(sounds.golem_down, golem.global_position)
	music.fade_out()


func _on_hammer_landed(body: Node3D, dealt: float) -> void:
	if dealt > 0.0:
		board.play(sounds.golem_hammer, body.global_position)


func _on_received(_amount: float, _dealt: float, cue: SoundCue) -> void:
	_target_cue = cue


func _on_impacted(point: Vector3, _normal: Vector3, _dealt: float) -> void:
	board.play(_target_cue if _target_cue != null else sounds.hit_decor, point)
	_target_cue = null


func _on_spectre_state(_from: StringName, to: StringName, spectre: Spectre) -> void:
	if to == &"Windup":
		board.play(sounds.spectre_windup, spectre.global_position)
	elif to == &"Fade":
		board.play(sounds.spectre_gone, spectre.global_position)
