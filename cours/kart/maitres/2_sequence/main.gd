#@ 1-13
extends Node3D
#@ 14+
extends Step
#@ all
#@ 1
## Scène principale. À chaque image physique, l'adaptateur d'entrées du kart (KartInput) traduit le clavier
## et la manette en commandes de conduite, et l'affichage (InputDisplay) les montre ; un saut fait vibrer la
## manette (jump_rumble). La scène fait le lien : l'adaptateur et l'affichage ne se connaissent pas.
#@ 2-3
## Scène principale : une aire d'essai (un sol, une rampe) et le kart. À chaque image physique, l'affichage
## (InputDisplay) montre les commandes que le kart a reçues de son adaptateur d'entrées ; un saut fait vibrer
## la manette (jump_rumble). La scène fait le lien : le kart et l'affichage ne se connaissent pas.
#@ 4-5
## Scène principale : l'île et le kart. À chaque image physique, l'affichage (InputDisplay) montre les
## commandes que le kart a reçues de son adaptateur d'entrées ; un saut fait vibrer la manette (jump_rumble).
## La scène fait le lien : le kart et l'affichage ne se connaissent pas.
#@ 6-8
## Scène principale : l'île et le kart. À chaque image physique, l'affichage (InputDisplay) montre les
## commandes que le kart a reçues de son adaptateur d'entrées ; un saut fait vibrer la manette (jump_rumble) ;
## la position du kart est recopiée dans GameState.player_position, que GameState passe au paramètre global
## de shader du même nom : l'herbe le lit pour s'écarter sous le kart. La scène fait le lien : le kart,
## l'affichage et les shaders ne se connaissent pas.
#@ 9-10
## Scène principale : l'île et le kart. À chaque image physique, l'affichage (InputDisplay) montre les
## commandes que le kart a reçues de son adaptateur d'entrées ; un saut fait vibrer la manette (jump_rumble) ;
## la position du kart est recopiée dans GameState.player_position, que GameState passe au paramètre global
## de shader du même nom : l'herbe le lit pour s'écarter sous le kart ; l'océan recentre sur le kart ses
## simulations d'ondulations, de vagues et d'écume. La scène fait le lien : le kart, l'affichage, l'océan et
## les shaders ne se connaissent pas.
#@ 11-12
## Scène principale : l'île et le kart, sous l'orage. À chaque image physique, l'affichage (InputDisplay)
## montre les commandes que le kart a reçues de son adaptateur d'entrées ; un saut fait vibrer la manette
## (jump_rumble) ; la position du kart est recopiée dans GameState.player_position, que GameState passe au
## paramètre global de shader du même nom : l'herbe le lit pour s'écarter sous le kart ; l'océan recentre sur
## le kart ses simulations d'ondulations, de vagues et d'écume. La scène tient la météo (Weather, réglée par
## `weather_settings`) : elle en donne la pluie et le mouillage aux shaders (GameState), à la pluie dessinée
## (Rain) et aux roues du kart, et lance un éclair sur le kart quand l'orage le décide. La scène fait le lien :
## le kart, l'affichage, l'océan, la pluie et les shaders ne se connaissent pas.
#@ 13
## Scène principale : l'île et le kart, sous l'orage. À chaque image physique, l'affichage (InputDisplay)
## montre les commandes que le kart a reçues de son adaptateur d'entrées ; un saut fait vibrer la manette
## (jump_rumble) ; la position du kart est recopiée dans GameState.player_position, que GameState passe au
## paramètre global de shader du même nom : l'herbe le lit pour s'écarter sous le kart ; l'océan recentre sur
## le kart ses simulations d'ondulations, de vagues et d'écume. La scène tient la météo (Weather, réglée par
## `weather_settings`) : elle en donne la pluie et le mouillage aux shaders (GameState), à la pluie dessinée
## (Rain) et aux roues du kart, et lance un éclair sur le kart quand l'orage le décide. Elle tient aussi
## l'inventaire : une boîte que le kart traverse y ajoute un objet tiré dans `item_pool` (et un éclair frappe
## le kart) ; la commande « use_item » lance le plus ancien vers l'arrière ; une plaque de turbo donne son turbo
## au kart. La scène fait le lien : le kart, les boîtes, les plaques, les affichages, l'océan, la pluie et les
## shaders ne se connaissent pas.
#@ 14+
## Scène principale : l'île et le kart, sous l'orage. À chaque image physique, l'affichage (InputDisplay)
## montre les commandes que le kart a reçues de son adaptateur d'entrées ; un saut fait vibrer la manette
## (jump_rumble) ; la position du kart est recopiée dans GameState.player_position, que GameState passe au
## paramètre global de shader du même nom : l'herbe le lit pour s'écarter sous le kart ; l'océan recentre sur
## le kart ses simulations d'ondulations, de vagues et d'écume. La scène tient la météo (Weather, réglée par
## `weather_settings`) : elle en donne la pluie et le mouillage aux shaders (GameState), à la pluie dessinée
## (Rain) et aux roues du kart, et lance un éclair sur le kart quand l'orage le décide. Elle tient aussi
## l'inventaire : une boîte que le kart traverse y ajoute un objet tiré dans `item_pool` (et un éclair frappe
## le kart) ; la commande « use_item » lance le plus ancien vers l'arrière ; une plaque de turbo donne son turbo
## au kart. La scène fait le lien : le kart, les boîtes, les plaques, les affichages, l'océan, la pluie et les
## shaders ne se connaissent pas. C'est la première étape (Step) de la séquence du jeu : le chef d'orchestre
## (GameFlow) la charge ; la pause et le menu des contrôles (UI) sont posés par-dessus.
#@ all

## Vibration jouée à chaque saut (5_data/input/jump_rumble.tres).
@export var jump_rumble: Rumble
#@ 11+
## Réglages de la météo (5_data/weather/storm.tres).
@export var weather_settings: WeatherSettings
## L'éclair lancé sur le kart.
@export var lightning_scene: PackedScene
#@ 13+
## Réserve dans laquelle les boîtes tirent l'objet donné (5_data/items/item_pool.tres).
@export var item_pool: ItemPool
## La scène que crée chaque objet quand on l'utilise.
@export var item_scenes: Dictionary[ItemType, PackedScene] = {}
## Nombre d'objets que le kart peut porter (donné par la scène).
@export var inventory_capacity: int = 0
## Graine du hasard des objets.
@export var item_seed: int = 0
#@ 11+

## La météo de la partie.
var weather: Weather
#@ 13+
## Les objets que porte le kart.
var inventory: Inventory

var _item_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _strike: LightningStrike
#@ all

#@ 1
@onready var _input: KartInput = $KartInput
#@ 2+
@onready var _kart: Kart = $Kart
#@ 9+
@onready var _ocean: Ocean = $Island/Ocean
#@ 11+
@onready var _rain: RainView = $Rain
@onready var _wheel_effects: WheelSplashEffects = $Kart/WheelEffects
#@ 13+
@onready var _camera: Node3D = $FollowCamera
@onready var _inventory_display: InventoryDisplay = $InventoryDisplay
#@ all
@onready var _display: InputDisplay = $InputDisplay


func _ready() -> void:
	if jump_rumble == null:
		push_error("Main : la vibration du saut (jump_rumble) manque")
#@ 2+
	_kart.jumped.connect(_on_kart_jumped)
#@ 11+
	if weather_settings == null:
		push_error("Main : les réglages de la météo (weather_settings) manquent")
		return
	weather = Weather.new(weather_settings)
#@ 13+
	_item_rng.seed = item_seed
	inventory = Inventory.new(inventory_capacity)
	inventory.changed.connect(func() -> void: _inventory_display.show_items(inventory.items))
	for box: Node in find_children("*", "ItemBox", true, false):
		(box as ItemBox).collected.connect(_on_item_box_collected)
	for panel: Node in find_children("*", "BoostPanel", true, false):
		(panel as BoostPanel).crossed.connect(_on_boost_panel_crossed)
#@ all


#@ 1-10
func _physics_process(_delta: float) -> void:
#@ 11+
func _physics_process(delta: float) -> void:
#@ all
#@ 1
	var commands := _input.read()
	if commands.jump and jump_rumble != null:
		_input.vibrate(jump_rumble)
	_display.show_commands(commands, _input.joypad_names())
#@ 2+
	# Un kart piloté par un script n'a pas d'adaptateur d'entrées : pas de manette à montrer.
	var pads := _kart.input.joypad_names() if _kart.input != null else PackedStringArray()
	_display.show_commands(_kart.commands, pads)
#@ 6+
	GameState.player_position = _kart.global_position
#@ 9+
	_ocean.set_player_position(_kart.global_position)
#@ 11+
	if weather != null:
		_update_weather(delta)
#@ 13+
	if _kart.commands.use_item:
		use_item()
#@ all
#@ 2+


func _on_kart_jumped() -> void:
	if jump_rumble != null and _kart.input != null:
		_kart.input.vibrate(jump_rumble)
#@ all
#@ 11+


func _update_weather(delta: float) -> void:
	var strikes := weather.update(delta)
	GameState.rain_intensity = weather.intensity
	GameState.rain_wetness = weather.wetness
	_rain.intensity = weather.intensity
	_wheel_effects.road_wetness = weather.wetness
	if strikes:
		_strike_kart()


#@ 11-12
func _strike_kart() -> void:
	if lightning_scene == null:
		return
	var strike := lightning_scene.instantiate() as LightningStrike
	strike.target = _kart
	add_child(strike)
#@ 13+
## Un éclair frappe le kart ; s'il en frappe déjà un, il repart.
func _strike_kart() -> void:
	if is_instance_valid(_strike):
		_strike.restart()
		return
	if lightning_scene == null:
		return
	_strike = lightning_scene.instantiate() as LightningStrike
	_strike.target = _kart
	add_child(_strike)


## Lance le plus ancien objet de l'inventaire, depuis le kart, vers l'arrière (vers la caméra) ; rien si
## l'inventaire est vide.
func use_item() -> void:
	var item := inventory.take()
	if item == null:
		return
	if not item_scenes.has(item):
		push_error("Main : l'objet « %s » n'a pas de scène (item_scenes)" % item.display_name)
		return
	var backward := _camera.global_basis.z
	item.launch(item_scenes[item], self, _kart.global_position, Vector3(backward.x, 0.0, backward.z))


func _on_item_box_collected(body: Node3D) -> void:
	if body != _kart:
		return
	inventory.add(item_pool.draw(_item_rng))
	_strike_kart()


func _on_boost_panel_crossed(body: Node3D, boost_time: float) -> void:
	if body == _kart:
		_kart.set_boost(boost_time)
#@ all
