extends Node3D
## Boîte à objets : le kart d'un joueur qui la traverse reçoit un objet tiré dans `item_pool`, un éclair
## le frappe, et la boîte disparaît une seconde. Elle flotte, tourne sur elle-même et change de couleur.

## Éclair qui frappe le kart quand il ramasse ce bonus
const LIGHTNING_STRIKE := preload("res://3_entities/effects/lightning/lightning_strike.tscn")

## Vrai si la boîte peut être ramassée.
@export var active : bool = true;
@onready var box_mesh : MeshInstance3D = $VisualParent/Visual/Box
@onready var visual_item_box : Node3D = $VisualParent/Visual
@onready var light : OmniLight3D = $OmniLight3D
## Réserve dans laquelle l'objet donné est tiré.
@export var item_pool : ItemPool
## Couleur courante de la lumière et de la boîte ; elle défile avec le temps.
var color : Color;

@onready var light_radius: float = light.omni_range;

## Rend la boîte visible, allumée et ramassable.
func activate() -> void:
	active = true;
	visual_item_box.visible = true
	light.omni_range = light_radius

## Cache et éteint la boîte ; elle ne peut plus être ramassée.
func deactivate() -> void:
	active = false;
	visual_item_box.visible = false
	light.omni_range = 0

## Donne un objet à `player`, frappe son kart d'un éclair, puis cache la boîte une seconde.
func add_item_to_player(player : Player) -> void:	
	player.add_item(item_pool.get_item());
	_strike_lightning(player.kart)
	
	deactivate()
	await get_tree().create_timer(1).timeout
	activate()


func _ready() -> void:
	pass # Replace with function body.


func _strike_lightning(kart : Node3D) -> void:
	# Un seul éclair à la fois par kart : une deuxième boîte ramassée aussitôt relance le premier
	var current: Variant = kart.get_meta("lightning_strike") if kart.has_meta("lightning_strike") else null
	if is_instance_valid(current):
		(current as LightningStrike).restart()
		return
	var strike := LIGHTNING_STRIKE.instantiate() as LightningStrike
	strike.target = kart
	get_tree().current_scene.add_child(strike)
	kart.set_meta("lightning_strike", strike)


func _process(_delta: float) -> void:
	var time : float = Time.get_ticks_msec() * 0.001;
	# vertical bobbing + rotation
	visual_item_box.position.y = 0.5 * sin(2 * PI * 0.5 * time);
	
	var rot_x := Quaternion(Vector3.RIGHT, time * 1.2)
	var rot_y := Quaternion(Vector3.UP, time * 0.8)
	var rot_z := Quaternion(Vector3.FORWARD, time * 1.5)
	visual_item_box.basis = Basis(rot_x * rot_y * rot_z)
	
	# cycle through the color for the light and the shader
	color = Color.from_hsv(time * 0.5, 0.8, 1.0);	
	light.light_color = color;
	box_mesh.set_instance_shader_parameter("box_color", Vector3(color.r, color.g, color.b));


func _on_area_3d_body_entered(body: Node3D) -> void:
	var parent: Node = body.get_parent()
	if active and parent is Player:
		add_item_to_player(parent)
