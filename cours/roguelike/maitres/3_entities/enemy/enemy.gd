class_name Enemy extends CharacterBody3D
## Un ennemi. Sa machine à états le fait agir (attendre, poursuivre, attaquer, être étourdi, tomber, être vaincu) ;
## il suit la navigation du niveau (NavigationAgent3D) jusqu'à sa cible, le nœud du groupe « player ». Il ne
## connaît pas la classe du joueur : une entité n'en connaît pas une autre, sa cible n'est qu'un Node3D. Touché,
## il est étourdi ; vaincu, il le signale (defeated), ne bloque plus personne et passe à l'état de défaite. Ses
## tirages passent par son RandomNumberGenerator, à graine : une même partie se rejoue à l'identique.

## Émis quand l'ennemi est vaincu.
signal defeated

## Réglages de cette sorte d'ennemi (5_data/enemies/).
@export var settings: EnemySettings
## L'état d'étourdissement, où le met un coup reçu. Typé State, et non EnemyState : EnemyState connaît déjà Enemy,
## et deux scripts qui se citent l'un l'autre restent en mémoire jusqu'à la sortie (« resources still in use »).
@export var stun_state: State
## L'état de défaite.
@export var defeat_state: State
## Le support du modèle : c'est lui qui se tourne vers où l'ennemi regarde.
@export var mesh_mount: Node3D
## La zone de coup de son arme, s'il en a une : elle ne doit pas le toucher lui-même.
@export var weapon_shape_cast: ShapeCast3D

## Le hasard de l'ennemi ; sa graine vient des réglages.
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## La cible : le nœud du groupe « player », s'il y en a un.
var target: Node3D

@onready var animation_tree: AnimationTreeView = $AnimationAnchor/EnemyModel/AnimationTree
@onready var state_machine: StateMachine = $StateMachine
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var health_component: HealthComponent = $HealthComponent
@onready var knockback_component: KnockbackComponent = $KnockbackComponent
@onready var _collision_shape: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	if settings == null or stun_state == null or defeat_state == null or mesh_mount == null:
		push_error("Enemy : une dépendance manque (settings, stun_state, defeat_state, mesh_mount)")
		return
	rng.seed = settings.random_seed
	target = get_tree().get_first_node_in_group(&"player") as Node3D
	if weapon_shape_cast != null:
		weapon_shape_cast.add_exception(self)
	health_component.health_changed.connect(_on_health_changed)
	health_component.defeated.connect(_on_defeated)


## Distance à la cible, en m ; infinie sans cible.
func distance_to_target() -> float:
	return INF if target == null else global_position.distance_to(target.global_position)


func _on_health_changed(_value: float) -> void:
	state_machine.transition_to(stun_state.name)


func _on_defeated() -> void:
	defeated.emit()
	state_machine.transition_to(defeat_state.name)
	# On ne retire pas une forme de collision pendant un rappel physique : à la fin de l'image.
	_collision_shape.set_deferred(&"disabled", true)
