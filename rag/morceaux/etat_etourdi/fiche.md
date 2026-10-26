# Ajouter un état à un acteur : étourdi après un coup (machine à états du socle)

Exemple vérifié dans Godot 4.7.2, sans fenêtre, en mesurant son comportement : `python -m usine.rag.morceaux verifier etat_etourdi`.

## Ce que fait le morceau

Un nouvel état, « étourdi », pour un acteur piloté par la `StateMachine` du socle : un coup le fait entrer dans l'état, qui décompte sa durée (lue dans les données de l'acteur) dans `physics_update`, puis demande le retour au repos par `transition_requested`.

## Quand l'employer

Étourdissement, recul, gel, sort qui immobilise, temps de récupération après une attaque : tout comportement temporaire d'un acteur.

Dans un projet qui suit le plan : l'état dans `3_entities/<acteur>/states/<acteur>_<etat>.gd`, un nœud de ce nom dans la `StateMachine` de la scène de l'acteur, la durée dans la classe de `1_core/data/` et sa valeur dans le `.tres` de `5_data/` (principe 2) ; le test dans `7_tests/3_entities/<acteur>/`.

## Le code (`1_core/data/robot_stats.gd`, vérifié)

```gdscript
class_name RobotStats
extends Resource
## Définition du robot, immuable pendant la partie : ses valeurs vivent dans 5_data/actors/robot.tres.

## Identifiant stable, en snake_case, jamais renommé.
@export var id: StringName
## Durée de l'étourdissement après un coup, en secondes.
@export var stun_duration: float = 0.0


## Erreurs de la définition ; vide si elle est valide.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if String(id).is_empty() or String(id) != String(id).to_snake_case():
		errors.append("%s : id « %s » vide ou hors snake_case" % [resource_path, id])
	if stun_duration <= 0.0:
		errors.append("%s : stun_duration %.2f (attendu > 0)" % [resource_path, stun_duration])
	return errors
```

## Le code (`3_entities/robot/robot.gd`, vérifié)

```gdscript
class_name Robot
extends Node3D
## Le robot (simulation). Comportements : états (states/). Réglages : 5_data/actors/robot.tres.
## Entrées : take_hit(). Émet : stunned.

## Émis quand un coup l'étourdit ; sa vue (robot_view.gd) l'écoute pour le montrer.
signal stunned

@export var stats: RobotStats

@onready var state_machine: StateMachine = $StateMachine


func _ready() -> void:
	if stats == null:
		push_error("Robot : stats n'est pas posé dans la scène")
		return
	for message in stats.validate():
		push_error("Robot : %s" % message)


## Un coup reçu : appeler vers le bas (la machine), signaler vers le haut (stunned).
func take_hit() -> void:
	state_machine.transition_to(&"stunned")
	stunned.emit()
```

## Le code (`3_entities/robot/robot.tscn`, vérifié)

```ini
[gd_scene format=3]

[ext_resource type="Script" path="res://3_entities/robot/robot.gd" id="1_robot"]
[ext_resource type="Resource" path="res://5_data/actors/robot.tres" id="2_stats"]
[ext_resource type="Script" path="res://1_core/state_machine/state_machine.gd" id="3_sm"]
[ext_resource type="Script" path="res://3_entities/robot/states/robot_idle.gd" id="4_idle"]
[ext_resource type="Script" path="res://3_entities/robot/states/robot_stunned.gd" id="5_stunned"]

[node name="Robot" type="Node3D"]
script = ExtResource("1_robot")
stats = ExtResource("2_stats")

[node name="StateMachine" type="Node" parent="." node_paths=PackedStringArray("initial_state")]
script = ExtResource("3_sm")
initial_state = NodePath("Idle")

[node name="Idle" type="Node" parent="StateMachine"]
script = ExtResource("4_idle")

[node name="Stunned" type="Node" parent="StateMachine"]
script = ExtResource("5_stunned")
```

## Le code (`3_entities/robot/states/robot_idle.gd`, vérifié)

```gdscript
extends State
## Robot au repos : il attend.
```

## Le code (`3_entities/robot/states/robot_stunned.gd`, vérifié)

```gdscript
extends State
## Étourdi : le robot ne fait rien pendant stats.stun_duration, puis revient au repos. Le décompte avance dans
## physics_update : il s'arrête quand l'arbre est en pause.

var _time_left: float = 0.0


func enter() -> void:
	_time_left = (actor as Robot).stats.stun_duration


func physics_update(delta: float) -> void:
	_time_left -= delta
	# 0,5 s ôtées par pas de 1/60 laissent un reste infime au-dessus de 0 : sans is_zero_approx, une image de trop.
	if _time_left <= 0.0 or is_zero_approx(_time_left):
		transition_requested.emit(&"idle")
```

## Le code (`5_data/actors/robot.tres`, vérifié)

```ini
[gd_resource type="Resource" script_class="RobotStats" format=3]

[ext_resource type="Script" path="res://1_core/data/robot_stats.gd" id="1_script"]

[resource]
script = ExtResource("1_script")
id = &"robot"
stun_duration = 0.5
```

## Ce que l'exemple mesure

`exemple/exemple.gd` : étourdi 30 images de physique (attendu 30) ; avec 60 images de pause au milieu, 90 ; décompte de 0.5 s par pas de 1/60 : 31 images avec <= 0 seul, 30 avec is_zero_approx.

## Pièges

- Le décompte avance dans `physics_update` : il s'arrête quand l'arbre est en pause (mesuré : 60 images de pause au milieu, l'étourdissement dure 60 images de plus en temps réel). Un décompte dans `_process` ou un minuteur de `get_tree().create_timer(durée)` sans `false` continuerait (principe du plan SIM-08).
- Un nœud hérite du `process_mode` de son parent : sous un parent `PROCESS_MODE_ALWAYS`, l'acteur ignore la pause ; il faut le remettre en `PROCESS_MODE_PAUSABLE` (mesuré par l'exemple, dont la racine compte pendant la pause).
- Le nom passé à `transition_requested` est celui du nœud de l'état, en minuscules (`&"stunned"` pour le nœud `Stunned`) : la `StateMachine` du socle range ses états ainsi (principe du plan : un comportement = un état).
- L'acteur appelle vers le bas (`state_machine.transition_to`) et signale vers le haut (`stunned`) ; sa vue écoute le signal pour montrer l'étourdissement (principe 1 du plan).
