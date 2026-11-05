class_name EnemyDef
extends Resource
## Un type d'ennemi du jeu (`5_data/ennemis/<id>.tres`) : son rôle, sa santé, sa vitesse, sa portée, la cadence de son
## attaque (préparation, coup, récupération), son poids dans le plafond des vagues et ses dégâts. Le jeu s'en sert pour
## le faire vivre ; l'éditeur, pour choisir les ennemis d'une salle et vérifier qu'ils ont où apparaître.

## Les rôles d'ennemis, et les rôles de points d'apparition qui les accueillent.
const ROLES: Dictionary[StringName, Array] = {&"melee": ["melee", "tous"], &"distance": ["distance", "tous"]}

## Identifiant, en snake_case, jamais renommé : les salles le citent.
@export var id: StringName = &""
## Nom affiché.
@export var display_name: String = ""
## Le rôle : au contact (`melee`) ou à distance (`distance`).
@export var role: StringName = &"melee"
## La santé de départ.
@export var max_health: float = 1.0
## La distance à laquelle il repère le héros, en mètres.
@export var aggro_m: float = 1.0
## Sa vitesse, en mètres par seconde (0 : immobile).
@export var speed_mps: float = 0.0
## La portée de son attaque, en mètres.
@export var attack_range_m: float = 1.0
## La préparation de l'attaque, en secondes.
@export var windup_s: float = 0.0
## Le coup lui-même, en secondes.
@export var fire_s: float = 0.0
## La récupération après le coup, en secondes.
@export var recover_s: float = 0.0
## Son poids dans le plafond des vagues.
@export var weight: float = 1.0
## Les dégâts d'un coup.
@export var damage: float = 0.0
## Sa couleur dans les aperçus.
@export var color: Color = Color.WHITE


## Les erreurs de la définition, une phrase par erreur ; vide si elle est valide.
func validate() -> Array[String]:
	var errors: Array[String] = []
	var label: String = "ennemi %s" % id
	if String(id).is_empty() or String(id) != String(id).to_snake_case():
		errors.append("%s : identifiant en snake_case requis" % label)
	if not ROLES.has(role):
		errors.append("%s : rôle inconnu %s" % [label, role])
	if max_health <= 0.0 or weight <= 0.0:
		errors.append("%s : santé et poids positifs requis" % label)
	if aggro_m <= 0.0 or attack_range_m <= 0.0:
		errors.append("%s : repère et portée positifs requis" % label)
	if speed_mps < 0.0 or windup_s < 0.0 or fire_s < 0.0 or recover_s < 0.0 or damage < 0.0:
		errors.append("%s : vitesse, durées et dégâts positifs ou nuls requis" % label)
	return errors


## Les erreurs de la rencontre de `room` face aux ennemis `enemies` : un ennemi inconnu, ou un rôle sans point
## d'apparition qui l'accueille.
static func pool_errors(room: RoomData, enemies: Array[EnemyDef]) -> Array[String]:
	var errors: Array[String] = []
	var by_id: Dictionary[StringName, EnemyDef] = {}
	for enemy: EnemyDef in enemies:
		by_id[enemy.id] = enemy
	for enemy_id: String in room.encounter_pool:
		if not by_id.has(StringName(enemy_id)):
			errors.append("rencontre : ennemi inconnu %s" % enemy_id)
			continue
		var accepted: Array[String] = []
		accepted.assign(ROLES.get(by_id[StringName(enemy_id)].role, []))
		var has_point: bool = false
		for spawn_role: String in room.spawn_roles:
			has_point = has_point or accepted.has(spawn_role)
		if not has_point:
			errors.append("rencontre : aucun point d'apparition pour %s (%s)" % [enemy_id, by_id[StringName(enemy_id)].role])
	return errors
