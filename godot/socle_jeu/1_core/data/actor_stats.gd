class_name ActorStats
extends Resource
## Définition d'un acteur (joueur ou ennemi), immuable pendant la partie (DAT-04) : ses valeurs
## vivent dans un .tres de 5_data/. L'état courant (vie, recharge) est dans les composants.

## Identifiant stable, en snake_case, jamais renommé (DAT-06).
@export var id: StringName
@export var max_health: int = 0
@export var speed: float = 0.0
@export var hit_invulnerability: float = 0.0
@export_group("Ennemi")
@export var detection_range: float = 0.0
@export var attack_range: float = 0.0
## Distance au-delà de laquelle une attaque en cours reprend la poursuite (> attack_range).
@export var attack_leave_range: float = 0.0
@export var score_value: int = 0
## Durée entre la mort et la disparition.
@export var death_duration: float = 0.0
@export_group("Dash")
@export var dash_speed: float = 0.0
@export var dash_duration: float = 0.0
@export var dash_cooldown: float = 0.0


## Erreurs de la définition (DAT-07) ; vide si elle est valide.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if String(id).is_empty() or String(id) != String(id).to_snake_case():
		errors.append("%s : id « %s » vide ou hors snake_case" % [resource_path, id])
	if max_health <= 0:
		errors.append("%s : max_health %d (attendu > 0)" % [resource_path, max_health])
	if speed < 0.0 or hit_invulnerability < 0.0 or death_duration < 0.0:
		errors.append("%s : vitesse ou durée négative" % resource_path)
	if attack_range > 0.0 and attack_leave_range < attack_range:
		errors.append("%s : attack_leave_range %.1f < attack_range %.1f" % [resource_path, attack_leave_range, attack_range])
	return errors
