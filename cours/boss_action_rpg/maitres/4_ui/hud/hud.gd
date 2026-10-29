class_name Hud extends CanvasLayer
## L'interface du combat : vie, endurance et chaleur de l'arme en haut à gauche, fioles en bas à gauche, nom et vie du
## boss en bas, écran de chute. Elle ne connaît pas les entités (la règle des dossiers : 4_ui ne dépend pas de
## 3_entities) : elle écoute leurs composants de 1_core, que la scène principale lui donne (bind_…).

## La traîne des jauges, l'écran de chute, le nom du boss.
@export var settings: HudSettings

## La vie du héros.
@onready var health_bar: StatBar = $Health
## L'endurance du héros.
@onready var stamina_bar: StatBar = $Stamina
## La chaleur de l'arme.
@onready var heat_bar: StatBar = $Heat
## Les fioles.
@onready var flasks: FlaskCounter = $Flasks
## Le nom et la vie du boss.
@onready var boss_bar: BossBar = $BossBar
## L'écran de chute.
@onready var defeat: DefeatScreen = $Defeat


func _ready() -> void:
	for bar: StatBar in [health_bar, stamina_bar, heat_bar, boss_bar.bar]:
		bar.trail_delay = settings.trail_delay
		bar.trail_speed = settings.trail_speed
	defeat.fade_time = settings.defeat_fade_time


## Branche la jauge de vie sur la santé `health`.
func bind_health(health: HealthComponent) -> void:
	_bind_health_to(health_bar, health)


## Branche la jauge d'endurance sur `stamina`.
func bind_stamina(stamina: StaminaComponent) -> void:
	stamina_bar.snap(stamina.stamina, stamina.settings.max_stamina)
	stamina.changed.connect(stamina_bar.set_values)


## Branche la jauge de chaleur sur la chaleur de l'arme `heat`.
func bind_heat(heat: HeatComponent) -> void:
	heat_bar.snap(heat.heat, heat.settings.max_heat)
	heat.changed.connect(heat_bar.set_values)


## Branche le compte des fioles sur `flask_component`.
func bind_flasks(flask_component: FlaskComponent) -> void:
	flasks.set_charges(flask_component.charges, flask_component.max_charges)
	flask_component.changed.connect(flasks.set_charges)


## Montre la jauge du boss, à son nom, branchée sur sa santé `health`.
func bind_boss(health: HealthComponent) -> void:
	boss_bar.reveal(settings.boss_name)
	_bind_health_to(boss_bar.bar, health)


## Montre l'écran de chute.
func show_defeat() -> void:
	defeat.show_defeat(settings.defeat_text)


func _bind_health_to(bar: StatBar, health: HealthComponent) -> void:
	var maximum: float = health.settings.max_health
	bar.snap(health.health, maximum)
	health.damaged.connect(func(_amount: float, remaining: float) -> void: bar.set_values(remaining, maximum))
	health.healed.connect(func(_amount: float, remaining: float) -> void: bar.set_values(remaining, maximum))
