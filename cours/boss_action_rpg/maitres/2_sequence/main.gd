extends Node3D
#@ 1
## La scène principale du niveau. À cette étape : un sol, une lumière et une caméra, de quoi lancer le projet (F5)
## et voir qu'il tient debout ; le héros, le boss et l'arène arrivent aux étapes suivantes.
#@ 2
## La scène principale du niveau : le sol, la lumière, la caméra, et le héros qui court par rapport à elle.
#@ 3-6
## La scène principale du niveau : le sol, la lumière, le héros, la caméra à la troisième personne qui le suit, et
## une cible à verrouiller (le boss prendra sa place).
#@ 7+
## La scène principale du niveau : le saloon d'un géant (décor Quixel agrandi quatre fois), son ambiance (nuit froide,
## lampes chaudes, brouillard, brume au sol), le héros minuscule à l'entrée, la caméra à la troisième personne qui le
## suit, et le Gardien du Comptoir, le golem, qui l'attend devant le comptoir.
#@ 6+
## Quand le héros tombe, le niveau recommence après un délai : tout repart de zéro (héros, fioles, cible, et le boss
## quand il sera là), en rechargeant la scène.
#@ 9+
#@ 9-11
## Elle branche l'interface (4_ui ne connaît pas les entités) : vie, endurance, fioles du héros, chaleur de son arme,
## vie du boss ; et montre l'écran de chute quand le héros tombe.
#@ 12+
## Elle branche l'interface (4_ui ne connaît pas les entités) : vie, endurance, fioles du héros, chaleur de son arme ;
## la vie du boss quand il se réveille ; et montre l'écran de chute quand le héros tombe.
#@ 9+
#@ all
#@ 1-2

@onready var _camera: Camera3D = $Camera


func _ready() -> void:
	_camera.make_current()
#@ 6+

## Ce qui entoure le combat : le délai avant de recommencer.
@export var settings: EncounterSettings

@onready var _hero: Hero = $Hero
@onready var _restart_timer: Timer = $RestartTimer
#@ 9+
@onready var _hud: Hud = $Hud
@onready var _golem: Golem = $Golem
#@ 3+


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
#@ 6+
	_hero.defeated.connect(_on_hero_defeated)
	_restart_timer.timeout.connect(_restart)
#@ 9+
	_hud.bind_health(_hero.health)
	_hud.bind_stamina(_hero.stamina)
	_hud.bind_heat(_hero.gun.heat)
	_hud.bind_flasks(_hero.flasks)
#@ 9-11
	_hud.bind_boss(_golem.health)
#@ 12+
	_golem.woke.connect(_on_golem_woke)
#@ 9+
#@ 6+


func _on_hero_defeated() -> void:
	_restart_timer.start(settings.restart_delay)
#@ 9+
	_hud.show_defeat()
#@ 6+


func _restart() -> void:
	get_tree().reload_current_scene()
#@ 12+


func _on_golem_woke() -> void:
	_hud.bind_boss(_golem.health)
#@ all
