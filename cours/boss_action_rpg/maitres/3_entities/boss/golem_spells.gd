class_name GolemSpells extends Node3D
## Les sorts du Gardien : le combat dit quand il en prépare un et quand il part (signaux du golem) ; ce nœud montre
## l'annonce et lance les coups. Une boule de feu grandit au bout de son marteau, puis part vers le héros ; en seconde
## phase, une salve en éventail. Les éclairs marquent le sol sous le héros et de chaque côté, puis frappent depuis le
## marteau. Tout est préparé avec lui (ses enfants Fireball, GolemLightning et VfxBurst) : rien n'est créé en combat.

## Une boule de feu part de `at`.
signal ball_thrown(at: Vector3)
## Une boule de feu a explosé en `point`.
signal ball_exploded(point: Vector3)
## Un éclair marque le sol en `at`.
signal lightning_marked(at: Vector3)
## Un éclair frappe en `point`.
signal lightning_struck(point: Vector3)

## Le golem qui lance.
@export var golem: Golem
## Réglages des sorts.
@export var settings: GolemSpellSettings

## La boule qui grandit dans sa main (aucune : pas de boule en préparation).
var held: Fireball
## Sa croissance, de 0 à 1.
var charge: float = 0.0
## Ses boules de feu.
var balls: Array[Fireball] = []
## Ses éclairs.
var bolts: Array[GolemLightning] = []

var _blasts: Array[VfxBurst] = []
var _next_blast: int = 0
var _charge_time: float = 1.0
var _marks: int = 0

@onready var _hand: Node3D = golem.get_node(^"Model/Skeleton3D/WeaponR/HammerHit/Shape") as Node3D


func _ready() -> void:
	process_physics_priority = ProcessOrder.VIEWS
	for child: Node in get_children():
		if child is Fireball:
			balls.append(child as Fireball)
			(child as Fireball).exploded.connect(_on_exploded)
		elif child is GolemLightning:
			bolts.append(child as GolemLightning)
			(child as GolemLightning).struck.connect(lightning_struck.emit)
		elif child is VfxBurst:
			_blasts.append(child as VfxBurst)
	golem.charge_started.connect(_on_charge_started)
	golem.spell_cast.connect(_on_spell_cast)
	golem.charge_ended.connect(_on_charge_ended)
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	update(delta)


## Fait passer `delta` secondes : la boule grandit, au bout du marteau.
func update(delta: float) -> void:
	if held == null:
		return
	charge = minf(charge + delta / _charge_time, 1.0)
	held.hold(_hand.global_position, charge)


func _on_charge_started(strike: GolemAttack) -> void:
	var wind_up: float = (strike.cast_time - strike.charge_start) / (golem.clip_speed() * strike.clip_rate)
	match strike.spell:
		&"fireball":
			held = _free_ball()
			charge = 0.0
			_charge_time = maxf(wind_up, 0.01)
			set_physics_process(true)
		&"lightning":
			_mark_ground(strike.spell_count, wind_up)


func _on_spell_cast(strike: GolemAttack) -> void:
	match strike.spell:
		&"fireball":
			_throw(strike)
		&"lightning":
			for i: int in _marks:
				bolts[i].strike(_hand.global_position, strike.spell_damage)
			_marks = 0


## Un sort interrompu s'efface ; un sort parti ne change plus.
func _on_charge_ended() -> void:
	if held != null:
		held.cancel()
		held = null
	for i: int in _marks:
		bolts[i].cancel()
	_marks = 0
	set_physics_process(false)


func _throw(strike: GolemAttack) -> void:
	var from: Vector3 = _hand.global_position
	var target: Node3D = golem.target
	var aim: Vector3 = from.direction_to(target.global_position + Vector3.UP * Fireball.AIM_HEIGHT)
	var count: int = settings.phase_two_balls if golem.phase == 2 else strike.spell_count
	for i: int in count:
		var ball: Fireball = held if i == 0 and held != null else _free_ball()
		if ball == null:
			break
		ball.launch(from, aim.rotated(Vector3.UP, settings.fan_angle * _fan(i)), target, strike.spell_damage)
	held = null
	set_physics_process(false)
	ball_thrown.emit(from)


## Le sol est marqué sous la cible, puis de chaque côté, en travers de la ligne qui va du golem à elle.
func _mark_ground(count: int, warn: float) -> void:
	var center: Vector3 = golem.target.global_position
	center.y = golem.global_position.y
	var across: Vector3 = (center - golem.global_position).cross(Vector3.UP).normalized()
	_marks = mini(count, bolts.size())
	for i: int in _marks:
		var point: Vector3 = center + across * settings.lightning_spread * _fan(i)
		bolts[i].mark(point, warn)
		lightning_marked.emit(point)


## La place du rang `i` dans un éventail : 0, puis 1, -1, 2, -2.
func _fan(i: int) -> float:
	return ceilf(i * 0.5) * (1.0 if i % 2 == 1 else -1.0)


func _free_ball() -> Fireball:
	for ball: Fireball in balls:
		if ball.is_free():
			return ball
	return null


func _on_exploded(point: Vector3) -> void:
	var blast: VfxBurst = _blasts[_next_blast]
	_next_blast = (_next_blast + 1) % _blasts.size()
	blast.global_position = point
	blast.play()
	ball_exploded.emit(point)
