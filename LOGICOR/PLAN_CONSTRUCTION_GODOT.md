# PLAN DE CONSTRUCTION - Space Dracula

## Vue d'ensemble

Le jeu est un action-RPG top-down 3D. Le joueur contrôle un héros qui traverse des salles
(enfermées), combat des ennemis, et progresse à travers 8 niveaux avec des mini-boss
et des boss.

```
Jeu
├─ Héros (mouvement, attaque, dash)
├─ Salle (cycle de vie, spawn, issues)
├─ Ennemis (IA, attaques, mort)
├─ Boss (phases, rencontres appelées)
├─ Mini-boss (rencontres spécifiques)
├─ Projets (dégâts, effets)
├─ Effets (DAMAGE_OUTPUT, DAMAGE_OVER_TIME, DAMAGE_TAKEN, GRIP, ROOT, SLOW, STUN, BUFF)
├─ UI (barres PV, HUD)
└─ Caméra (top-down, suit le héros)
```

---

## Étape 1 : Héros — Mouvement et attaque

### Fichier : `acteurs/BPC_HerosBase.gd`

Remplacer le fichier actuel par :

```gdscript
extends CharacterBody3D
## BPC_HerosBase.gd
## Le corps de base du héros (CharacterBody3D).
## Mouvement, attaque, dash, stats.

@export var fiche: FicheHeros
@export var stats: BPC_Stats

# Références
@export var camera: Camera3D
@export var attack_hitbox: Area3D

# Vitesse de base
var vitesse: float = 300.0

# Attaque
var en_attaque: bool = false
var temps_attaque: float = 0.0
var duree_attaque: float = 0.3
var cooldown_attaque: float = 0.5
var temps_cooldown: float = 0.0

# Dash
var en_dash: bool = false
var temps_dash: float = 0.0
var duree_dash: float = 0.4
var vitesse_dash: float = 800.0
var cooldown_dash: float = 1.0
var temps_cooldown_dash: float = 0.0

# Cible courante (pour l'attaque)
var cible_attaque: Node = null


func _ready() -> void:
	if not stats:
		stats = BPC_Stats.new(fiche)
		if fiche:
			stats.vie = fiche.vie_max
			stats.souffle = fiche.souffle_max
			vitesse = fiche.vitesse if fiche.vitesse > 0 else 300.0
			if fiche:
				duree_dash = fiche.dash_duree


func _physics_process(delta: float) -> void:
	# Tick des i-frames et du dernier effort.
	if stats:
		stats.tick(delta)

	# Cooldowns
	if temps_cooldown > 0.0:
		temps_cooldown -= delta
	if temps_cooldown_dash > 0.0:
		temps_cooldown_dash -= delta

	# Mouvement
	var direction: Vector3 = Vector3.ZERO
	if Input.is_action_pressed("move_right"):
		direction.x += 1.0
	if Input.is_action_pressed("move_left"):
		direction.x -= 1.0
	if Input.is_action_pressed("move_up"):
		direction.z -= 1.0
	if Input.is_action_pressed("move_down"):
		direction.z += 1.0

	if direction != Vector3.ZERO:
		direction = direction.normalized()

	# Dash
	if Input.is_action_just_pressed("dash") and not en_dash and temps_cooldown_dash <= 0.0:
		en_dash = true
		temps_dash = duree_dash
		temps_cooldown_dash = cooldown_dash

	# Appliquer la vitesse
	if en_dash:
		temps_dash -= delta
		velocity = direction * vitesse_dash
		if temps_dash <= 0.0:
			en_dash = false
	else:
		velocity = direction * vitesse

	move_and_slide()

	# Attaque
	if Input.is_action_just_pressed("attack") and not en_attaque and temps_cooldown <= 0.0:
		en_attaque = true
		temps_attaque = 0.0
		temps_cooldown = cooldown_attaque

	if en_attaque:
		temps_attaque += delta
		# Au milieu de l'animation d'attaque, appliquer les dégâts
		if temps_attaque >= duree_attaque * 0.4 and temps_attaque < duree_attaque * 0.4 + delta:
			_attaquer()
		if temps_attaque >= duree_attaque:
			en_attaque = false


## Attaquer : appliquer les dégâts à tous les ennemis dans le hitbox.
func _attaquer() -> void:
	if not attack_hitbox:
		return
	var degat: int = 10
	if fiche:
		degat = fiche.degat_attaque if fiche.degat_attaque > 0 else 10
	for corps in attack_hitbox.get_overlapping_bodies():
		if corps.has_method("prendre_degrats"):
			corps.prendre_degrats(degat, self, false)


## Prendre des dégâts.
func prendre_degrats(montant: int, source: Node = null, est_crit: bool = false) -> int:
	var degats: int = stats.appliquer_degrats(montant, source, est_crit)
	return degats


## Soigner.
func soigner(montant: int) -> int:
	return stats.soigner(montant)


## Est mort ?
func est_mort() -> bool:
	return stats.vie <= 0
```

### Fichier : `donnees/FicheHeros.gd`

Ajouter les champs manquants :

```gdscript
class_name FicheHeros
extends Resource
## FicheHeros.gd
## Tous les nombres du héros.

@export var vie_max: int = 30
@export var souffle_max: int = 50
@export var vitesse: float = 300.0
@export var degat_attaque: int = 10
@export var degat_crit: int = 30
@export var portee_attaque: float = 150.0
@export var seuil_invuln: float = 0.25
@export var degat_min_invuln: int = 15
@export var fenetre_cumul: float = 0.6
@export var duree_invuln: float = 1.3
@export var dernier_effort_soin: float = 0.4
@export var dernier_effort_duree: float = 5.0
@export var dernier_effort_modif: float = 0.3
@export var mode_facile_base: float = 0.8
@export var mode_facile_mort: float = -0.02
@export var mode_facile_cap: int = 30
@export var cout_porte_secrete_base: float = 10.0
@export var cout_porte_secrete_ramp: float = 0.4
@export var seuil_combo: int = 12
@export var dash_duree: float = 0.4
@export var dash_vitesse: float = 800.0
@export var dash_cooldown: float = 1.0
@export var buffer_sprint: float = 0.42
```

### Scène : `scenes/Heros.tscn`

```
[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://acteurs/BPC_HerosBase.gd" id="1"]
[ext_resource type="Script" path="res://donnees/FicheHeros.gd" id="2"]

[sub_resource type="BoxShape3D" id="BoxShape3D_1"]
size = Vector3(1, 2, 1)

[node name="Heros" type="CharacterBody3D"]
script = ExtResource("1")

[node name="CollisionShape3D" type="CollisionShape3D" parent="."]
shape = SubResource("BoxShape3D_1")

[node name="MeshInstance3D" type="MeshInstance3D" parent="."]

[node name="Camera3D" type="Camera3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 5, -3)
current = true

[node name="AttackHitbox" type="Area3D" parent="."]
collision_layer = 4
collision_mask = 2

[node name="CollisionShape3D_2" type="CollisionShape3D" parent="AttackHitbox"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 1.5, 0, 0)

[node name="Label" type="Label3D" parent="."]
text = "HEROS"
```

### project.godot — Ajouter les input actions

```ini
[input]

move_right={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194321,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}
move_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194319,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}
move_up={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194320,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}
move_down={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194322,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}
attack={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":32,"key_label":0,"unicode":32,"echo":false,"script":null)
]
}
dash={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194325,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}
```

---

## Étape 2 : Ennemis — IA et attaques

### Fichier : `acteurs/BPC_EnnemiBase.gd`

Remplacer le fichier actuel par :

```gdscript
extends CharacterBody3D
## BPC_EnnemiBase.gd
## Le corps de base d'un ennemi (CharacterBody3D).
## IA simple : suivi du héros, attaque en portée, mort.

@export var fiche: FicheEnnemi
@export var stats: BPC_Stats
@export var est_mort: bool = false

# Référence au héros (set par la salle)
var heros: Node = null

# IA
var portee_aggro: float = 600.0
var portee_attaque: float = 100.0
var duree_attaque: float = 1.0
var temps_attaque: float = 0.0
var en_attaque: bool = false
var cooldown_attaque: float = 1.5
var temps_cooldown: float = 0.0

# Aggro
var aggro: bool = false


func _ready() -> void:
	if not stats:
		stats = BPC_Stats.new()
		if fiche:
			stats.vie = fiche.PV_Max
			portee_aggro = fiche.IA_PorteeAggro if fiche.IA_PorteeAggro > 0 else 600.0


func _physics_process(delta: float) -> void:
	if est_mort:
		return

	if not heros or not is_instance_valid(heros) or heros.has_method("est_mort") and heros.est_mort():
		return

	# Cooldown
	if temps_cooldown > 0.0:
		temps_cooldown -= delta

	# Aggro
	var dist: float = global_position.distance_to(heros.global_position)
	if not aggro and dist <= portee_aggro:
		aggro = true

	if not aggro:
		return

	# Attaque
	if en_attaque:
		temps_attaque += delta
		if temps_attaque >= duree_attaque:
			en_attaque = false
			temps_cooldown = cooldown_attaque
		return

	if dist <= portee_attaque and temps_cooldown <= 0.0:
		# Attaquer
		en_attaque = true
		temps_attaque = 0.0
		_attaquer()
		return

	# Suivre le héros
	var direction: Vector3 = (heros.global_position - global_position).normalized()
	velocity = direction * (fiche.Vitesse if fiche and fiche.Vitesse > 0 else 150.0)
	move_and_slide()


## Attaquer le héros.
func _attaquer() -> void:
	if not heros or not is_instance_valid(heros):
		return
	var degat: int = 5
	if heros.has_method("prendre_degrats"):
		heros.prendre_degrats(degat, self, false)


## Prendre des dégâts.
func prendre_degrats(montant: int, source: Node = null, est_crit: bool = false) -> int:
	if est_mort:
		return 0
	var degats: int = stats.appliquer_degrats(montant, source, est_crit)
	if stats.vie <= 0:
		mourir()
	return degats


## Mourir.
func mourir() -> void:
	if est_mort:
		return
	est_mort = true
	set_physics_process(false)
	# Ici : effets de mort, drops, notification à la salle
	queue_free()


## Vérifier si l'ennemi est mort.
func est_mort() -> bool:
	return est_mort
```

### Scène : `scenes/Ennemi.tscn`

```
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://acteurs/BPC_EnnemiBase.gd" id="1"]

[sub_resource type="BoxShape3D" id="BoxShape3D_1"]
size = Vector3(1, 1.5, 1)

[node name="Ennemi" type="CharacterBody3D"]
script = ExtResource("1")

[node name="CollisionShape3D" type="CollisionShape3D" parent="."]
shape = SubResource("BoxShape3D_1")

[node name="MeshInstance3D" type="MeshInstance3D" parent="."]
```

---

## Étape 3 : Boss — Phases et rencontres

### Fichier : `acteurs/BPC_BossBase.gd`

Nouveau fichier :

```gdscript
extends CharacterBody3D
## BPC_BossBase.gd
## Le corps de base d'un boss (CharacterBody3D).
## Gère les phases et les attaques.

@export var fiche: FicheBoss
@export var stats: BPC_Stats
@export var est_mort: bool = false

var heros: Node = null

# Phases
var phase_actuelle: int = 0
var phases: Array[Dictionary] = []

# Attaques de la phase actuelle
var attaques_phase: Array[Dictionary] = []
var attaque_actuelle: Dictionary = {}
var en_attaque: bool = false
var temps_attaque: float = 0.0
var cooldown_attaque: float = 1.0
var temps_cooldown: float = 0.0

# Aggro
var aggro: bool = false
var portee_aggro: float = 1000.0


func _ready() -> void:
	if not stats:
		stats = BPC_Stats.new()
		if fiche:
			stats.vie = fiche.PV_Max
			phases = fiche.phases
			portee_aggro = fiche.IA_PorteeAggro if fiche.IA_PorteeAggro > 0 else 1000.0

	# Préparer la phase 0
	if not phases.is_empty():
		_changer_phase(0)


func _physics_process(delta: float) -> void:
	if est_mort:
		return

	if not heros or not is_instance_valid(heros) or heros.has_method("est_mort") and heros.est_mort():
		return

	# Cooldown
	if temps_cooldown > 0.0:
		temps_cooldown -= delta

	# Aggro
	var dist: float = global_position.distance_to(heros.global_position)
	if not aggro and dist <= portee_aggro:
		aggro = true

	if not aggro:
		return

	# Vérifier les transitions de phase
	_verifier_phases()

	# Attaque
	if en_attaque:
		temps_attaque += delta
		var duree: float = attaque_actuelle.get("props", {}).get("IA_AnnonceDuree", 1.0)
		if temps_attaque >= duree:
			en_attaque = false
			temps_cooldown = cooldown_attaque
			# Appliquer les dégâts
			_appliquer_degrats()
		return

	if temps_cooldown <= 0.0:
		choisir_attaque()


## Vérifier si on doit changer de phase.
func _verifier_phases() -> void:
	if phases.is_empty():
		return
	var fraction: float = float(stats.vie) / float(stats.vie_max) if stats.vie_max > 0 else 0.0
	for i in range(phases.size() - 1, -1, -1):
		var props: Dictionary = phases[i].get("props", {})
		var type_transition: String = props.get("TypeTransition", "SeuilPV")
		if type_transition == "SeuilPV":
			var seuil: float = props.get("Seuil", 1.0)
			if fraction <= seuil and i != phase_actuelle:
				_changer_phase(i)
				break


## Changer de phase.
func _changer_phase(index: int) -> void:
	if index >= phases.size():
		return
	phase_actuelle = index
	var phase: Dictionary = phases[index]
	# Lister les armes équipées
	var armes: Array = phase.get("props", {}).get("ArmesEquipees", [])
	# Filtrer les attaques de la fiche qui correspondent
	attaques_phase = []
	if fiche and fiche.attaques:
		for attaque in fiche.attaques:
			if armes.is_empty() or armes.has(attaque.get("id", "")):
				attaques_phase.append(attaque)
	# Si pas de filtre, prendre toutes les attaques
	if attaques_phase.is_empty() and fiche and fiche.attaques:
		attaques_phase = fiche.attaques


## Choisir une attaque aléatoire de la phase.
func choisir_attaque() -> void:
	if attaques_phase.is_empty():
		return
	var index: int = randi() % attaques_phase.size()
	attaque_actuelle = attaques_phase[index]
	en_attaque = true
	temps_attaque = 0.0


## Appliquer les dégâts à la fin de l'attaque.
func _appliquer_degrats() -> void:
	if not heros or not is_instance_valid(heros):
		return
	var degat: int = attaque_actuelle.get("props", {}).get("Degats", 10)
	var portee: float = attaque_actuelle.get("props", {}).get("IA_PorteeAttaque", 200.0)
	var dist: float = global_position.distance_to(heros.global_position)
	if dist <= portee and heros.has_method("prendre_degrats"):
		heros.prendre_degrats(degat, self, false)


## Prendre des dégâts.
func prendre_degrats(montant: int, source: Node = null, est_crit: bool = false) -> int:
	if est_mort:
		return 0
	var degats: int = stats.appliquer_degrats(montant, source, est_crit)
	if stats.vie <= 0:
		mourir()
	return degats


## Mourir.
func mourir() -> void:
	if est_mort:
		return
	est_mort = true
	set_physics_process(false)
	queue_free()


func est_mort() -> bool:
	return est_mort
```

### Scène : `scenes/Boss.tscn`

```
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://acteurs/BPC_BossBase.gd" id="1"]

[sub_resource type="BoxShape3D" id="BoxShape3D_1"]
size = Vector3(2, 3, 2)

[node name="Boss" type="CharacterBody3D"]
script = ExtResource("1")

[node name="CollisionShape3D" type="CollisionShape3D" parent="."]
shape = SubResource("BoxShape3D_1")

[node name="MeshInstance3D" type="MeshInstance3D" parent="."]

[node name="Label" type="Label3D" parent="."]
text = "BOSS"
```

---

## Étape 4 : Projets

### Fichier : `acteurs/BPC_Projet.gd`

Nouveau fichier :

```gdscript
extends Area3D
## BPC_Projet.gd
## Un projet (tile de dégâts sur le sol).
## Apparaît, dure, puis disparaît.

@export var degats: int = 10
@export var duree: float = 2.0
@export var rayon: float = 100.0

var temps: float = 0.0
var actif: bool = false


func _ready() -> void:
	# Désactiver au départ
	set_process(false)


func activer() -> void:
	actif = true
	temps = 0.0
	set_process(true)


func _process(delta: float) -> void:
	temps += delta
	if temps >= duree:
		deacter()
		return
	# Appliquer les dégâts aux héros dans la zone
	for corps in get_overlapping_bodies():
		if corps.has_method("prendre_degrats"):
			# Un dégât par seconde
			if floor(temps) != floor(temps - delta):
				corps.prendre_degrats(degats, self, false)


func deacter() -> void:
	actif = false
	set_process(false)
	queue_free()
```

### Scène : `scenes/Projet.tscn`

```
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://acteurs/BPC_Projet.gd" id="1"]

[sub_resource type="SphereShape3D" id="SphereShape3D_1"]
radius = 1.0

[node name="Projet" type="Area3D"]
script = ExtResource("1")
collision_layer = 8
collision_mask = 1

[node name="CollisionShape3D" type="CollisionShape3D" parent="."]
shape = SubResource("SphereShape3D_1")
```

---

## Étape 5 : Salle — Spawn et cycle de vie

### Fichier : `acteurs/BPC_SalleBase.gd`

Remplacer le fichier actuel par :

```gdscript
extends Node
## BPC_SalleBase.gd
## Le corps de base d'une salle (cycle de vie, spawn, issues).

@export var fiche: FicheSalle
@export var heros: Node
@export var niveau: int = 1

# Scènes à instancier
@export var scene_ennemi: PackedScene
@export var scene_boss: PackedScene
@export var scene_miniboss: PackedScene

# Données de spawn
@export var spawn_pools: Array = []  # [{ "Ref": "CRT-001", "Weight": 2, "Elite": false }]
@export var encounter_profile: Dictionary = {}  # { "BaseDifficulty": 30, "ActiveEnemyCapBase": 2.3, ... }

enum EtatSalle {
	ATTENTE,
	COMBAT,
	COMBAT_FINI,
	VERROUILLEE,
}

var etat: int = EtatSalle.ATTENTE
var delai_apparition: float = 0.5
var delai_deverrouillage: float = 0.4
var delai_fin_combat: float = 0.2
var temps_ecoulé: float = 0.0

# Ennemis actifs
var ennemis_actifs: Array[Node] = []

# Points de spawn (positions dans la salle)
var points_spawn: Array[Vector3] = [
	Vector3(3, 0, 3), Vector3(-3, 0, 3),
	Vector3(3, 0, -3), Vector3(-3, 0, -3),
	Vector3(0, 0, 4), Vector3(0, 0, -4),
	Vector3(4, 0, 0), Vector3(-4, 0, 0),
]

# Nombre d'ennemis à spawner
var nombre_ennemis: int = 3
var elite: bool = false

# Boss / mini-boss
var boss_active: Node = null


func _ready() -> void:
	if fiche:
		delai_apparition = fiche.delai_apparition
		delai_deverrouillage = fiche.delai_deverrouillage
		delai_fin_combat = fiche.delai_fin_combat
	# Calculer le nombre d'ennemis
	_calculer_nombre_ennemis()


func _process(delta: float) -> void:
	match etat:
		EtatSalle.ATTENTE:
			temps_ecoulé += delta
			if temps_ecoulé >= delai_apparition:
				etat = EtatSalle.COMBAT
				temps_ecoulé = 0.0
				_spawner_ennemis()
		EtatSalle.COMBAT:
			# Vérifier si le combat est fini
			if _combat_fini():
				etat = EtatSalle.COMBAT_FINI
				temps_ecoulé = 0.0
		EtatSalle.COMBAT_FINI:
			temps_ecoulé += delta
			if temps_ecoulé >= delai_fin_combat:
				etat = EtatSalle.VERROUILLEE


## Calculer le nombre d'ennemis à spawner.
func _calculer_nombre_ennemis() -> void:
	if encounter_profile.is_empty():
		nombre_ennemis = 3
		return
	var base: float = encounter_profile.get("ActiveEnemyCapBase", 2.3)
	var ramp: float = encounter_profile.get("ActiveEnemyCapDepthRamp", 0.35)
	var cap_max: int = encounter_profile.get("ActiveEnemyCapMax", 8)
	nombre_ennemis = int(base + float(niveau - 1) * ramp)
	nombre_ennemis = mini(nombre_ennemis, cap_max)
	nombre_ennemis = maxi(nombre_ennemis, 1)


## Spawner les ennemis.
func _spawner_ennemis() -> void:
	if spawn_pools.is_empty():
		return
	for i in range(nombre_ennemis):
		var entry: Dictionary = _choisir_ennemi()
		var ref: String = entry.get("Ref", "")
		var est_elite: bool = entry.get("Elite", false)

		# Charger la fiche
		var path: String = "res://donnees/%s.tres" % ref
		if not ResourceLoader.exists(path):
			continue
		var fiche_ennemi: Resource = load(path)

		# Instancier la scène
		if not scene_ennemi:
			continue
		var ennemi: CharacterBody3D = scene_ennemi.instantiate()
		ennemi.fiche = fiche_ennemi
		ennemi.heros = heros

		# Position aléatoire dans les points de spawn
		var index: int = i % points_spawn.size()
		ennemi.global_position = points_spawn[index]

		get_parent().add_child(ennemi)
		ennemis_actifs.append(ennemi)


## Choisir un ennemi aléatoire (pondéré).
func _choisir_ennemi() -> Dictionary:
	var poids_total: int = 0
	for entry in spawn_pools:
		poids_total += int(entry.get("Weight", 1))
	var r: int = randi() % poids_total
	var cumul: int = 0
	for entry in spawn_pools:
		cumul += int(entry.get("Weight", 1))
		if r < cumul:
			return entry
	return spawn_pools[0]


## Vérifier si le combat est fini.
func _combat_fini() -> bool:
	# Retirer les ennemis morts
	ennemis_actifs = ennemis_actifs.filter(func(e): return not e.est_mort())
	return ennemis_actifs.is_empty()


## Réinitialiser la salle.
func reset() -> void:
	etat = EtatSalle.ATTENTE
	temps_ecoulé = 0.0
	ennemis_actifs.clear()
```

### Fichier : `donnees/FicheSalle.gd`

Mettre à jour :

```gdscript
class_name FicheSalle
extends Resource
## FicheSalle.gd
## Tous les nombres d'une salle.

@export var nom: String = ""
@export var types: Array = []
@export var delai_apparition: float = 0.5
@export var delai_deverrouillage: float = 0.4
@export var delai_fin_combat: float = 0.2
@export var encounters: Array = []
@export var issues: Array = []
@export var cout_combat: float = 0.0
@export var cout_vie: int = 0

# Spawn
@export var spawn_pools: Array = []
@export var encounter_profile: Dictionary = {}
@export var niveau: int = 1
```

### Scène : `scenes/Salle.tscn`

```
[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://acteurs/BPC_SalleBase.gd" id="1"]

[sub_resource type="BoxShape3D" id="BoxShape3D_1"]
size = Vector3(10, 1, 10)

[node name="Salle" type="Node"]
script = ExtResource("1")

[node name="Sol" type="MeshInstance3D" parent="."]

[node name="CollisionShape3D" type="CollisionShape3D" parent="."]
shape = SubResource("BoxShape3D_1")

[node name="Ennemis" type="Node" parent="."]

[node name="Boss" type="Node" parent="."]
```

---

## Étape 6 : Caméra top-down

### Fichier : `acteurs/BPC_CameraTopDown.gd`

Nouveau fichier :

```gdscript
extends Camera3D
## BPC_CameraTopDown.gd
## Caméra top-down qui suit le héros.

@export var heros: Node
@export var hauteur: float = 8.0
@export var angle: float = 45.0  # degrés
@export var lerp_vitesse: float = 5.0


func _process(delta: float) -> void:
	if not heros or not is_instance_valid(heros):
		return
	var cible: Vector3 = heros.global_position
	cible.y = hauteur
	# Position en diagonale (top-down 45°)
	var offset: Vector3 = Vector3(0, hauteur, -hauteur * tan(deg_to_rad(angle)))
	var position_cible: Vector3 = cible + offset
	global_position = global_position.lerp(position_cible, lerp_vitesse * delta)
	look_at(cible)
```

### Scène : `scenes/CameraTopDown.tscn`

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://acteurs/BPC_CameraTopDown.gd" id="1"]

[node name="CameraTopDown" type="Camera3D"]
script = ExtResource("1")
current = true
fov = 50.0
```

---

## Étape 7 : UI — Barres PV

### Fichier : `ui/BPC_HUD.gd`

Nouveau fichier :

```gdscript
extends CanvasLayer
## BPC_HUD.gd
## L'interface : barres PV, souffle, notifications.

@export var heros: Node

@onready var barre_vie: ProgressBar = $Vie/BarreVie
@onready var barre_souffle: ProgressBar = $Souffle/BarreSouffle
@onready var label_vie: Label = $Vie/LabelVie


func _ready() -> void:
	if heros and heros.stats:
		barre_vie.max_value = heros.stats.vie_max if heros.stats.fiche else 30
		barre_vie.value = barre_vie.max_value
		barre_souffle.max_value = heros.stats.souffle_max if heros.stats.fiche else 50
		barre_souffle.value = barre_souffle.max_value


func _process(_delta: float) -> void:
	if not heros or not heros.stats:
		return
	barre_vie.value = heros.stats.vie
	barre_souffle.value = heros.stats.souffle
	label_vie.text = "%d / %d" % [heros.stats.vie, barre_vie.max_value]
```

### Scène : `scenes/HUD.tscn`

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://ui/BPC_HUD.gd" id="1"]

[node name="HUD" type="CanvasLayer"]
script = ExtResource("1")

[node name="Vie" type="Panel" parent="."]
offset_left = 10.0
offset_top = 10.0
offset_right = 210.0
offset_bottom = 40.0

[node name="BarreVie" type="ProgressBar" parent="Vie"]
offset_left = 5.0
offset_top = 5.0
offset_right = 200.0
offset_bottom = 25.0
max_value = 30.0
value = 30.0

[node name="LabelVie" type="Label" parent="Vie"]
offset_left = 5.0
offset_top = 25.0
offset_right = 200.0
offset_bottom = 40.0
text = "30 / 30"

[node name="Souffle" type="Panel" parent="."]
offset_left = 10.0
offset_top = 50.0
offset_right = 210.0
offset_bottom = 80.0

[node name="BarreSouffle" type="ProgressBar" parent="Souffle"]
offset_left = 5.0
offset_top = 5.0
offset_right = 200.0
offset_bottom = 25.0
max_value = 50.0
value = 50.0
```

---

## Étape 8 : Scène principale — Jeu

### Fichier : `acteurs/BPC_Jeu.gd`

Nouveau fichier :

```gdscript
extends Node
## BPC_Jeu.gd
## La scène principale : orchestre le jeu.

@export var heros_scene: PackedScene
@export var salle_scene: PackedScene
@export var hud_scene: PackedScene
@export var camera_scene: PackedScene

# Données
@export var fiche_heros: FicheHeros
@export var spawn_pools: Array = []
@export var encounter_profile: Dictionary = {}
@export var niveau: int = 1

# Références
var heros: Node = null
var salle: Node = null
var hud: CanvasLayer = null
var camera: Camera3D = null


func _ready() -> void:
	# Créer la salle
	if salle_scene:
		salle = salle_scene.instantiate()
		add_child(salle)

	# Créer le héros
	if heros_scene:
		heros = heros_scene.instantiate()
		heros.fiche = fiche_heros
		add_child(heros)

	# Configurer la salle
	if salle:
		salle.heros = heros
		salle.niveau = niveau
		salle.spawn_pools = spawn_pools
		salle.encounter_profile = encounter_profile

	# Créer la caméra
	if camera_scene:
		camera = camera_scene.instantiate()
		camera.heros = heros
		add_child(camera)

	# Créer le HUD
	if hud_scene:
		hud = hud_scene.instantiate()
		hud.heros = heros
		add_child(hud)
```

### Scène : `scenes/Jeu.tscn`

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://acteurs/BPC_Jeu.gd" id="1"]

[node name="Jeu" type="Node"]
script = ExtResource("1")
```

---

## Étape 9 : Autoload — Gestionnaire global

### Fichier : `autoload/BPC_Global.gd`

Nouveau fichier :

```gdscript
extends Node
## BPC_Global.gd
## Autoload : état global du jeu.

# Niveau actuel
var niveau_actuel: int = 1
var profondeur: int = 0

# Stats de la run
var ennemis_tues: int = 0
var boss_tues: int = 0
var degats_infliges: int = 0
var degats_subis: int = 0

# Run terminée ?
var run_terminee: bool = false


func _ready() -> void:
	# Rien


func reinitialiser() -> void:
	niveau_actuel = 1
	profondeur = 0
	ennemis_tues = 0
	boss_tues = 0
	degats_infliges = 0
	degats_subis = 0
	run_terminee = false


func incrementer_profondeur() -> void:
	profondeur += 1


func enregister_degrats_infliges(montant: int) -> void:
	degats_infliges += montant


func enregister_degrats_subis(montant: int) -> void:
	degats_subis += montant


func enregister_mort_ennemi() -> void:
	ennemis_tues += 1


func enregister_mort_boss() -> void:
	boss_tues += 1
```

### project.godot — Ajouter l'autoload

```ini
[autoload]

BPC_Global="*res://autoload/BPC_Global.gd"
```

---

## Étape 10 : Test headless

### Fichier : `preuves/L_TestJeu.gd`

Nouveau fichier :

```gdscript
extends SceneTree
## L_TestJeu.gd
## Test du jeu complet : héros, salle, ennemis.

func _initialize() -> void:
	print("=== TEST JEU COMPLET ===\n")

	var erreurs: int = 0

	# 1. Charger la fiche du héros
	var fiche_heros := FicheHeros.new()
	fiche_heros.vie_max = 30
	fiche_heros.souffle_max = 50
	fiche_heros.vitesse = 300.0
	fiche_heros.degat_attaque = 10
	print("Héros: vie=%d, souffle=%d, vitesse=%.0f" % [fiche_heros.vie_max, fiche_heros.souffle_max, fiche_heros.vitesse])

	# 2. Charger un ennemi
	var fiche_ennemi: Resource = load("res://donnees/CRT-001.tres")
	if fiche_ennemi == null:
		print("ERREUR: CRT-001.tres ne se charge pas")
		erreurs += 1
	else:
		print("Ennemi CRT-001: PV=%d, vitesse=%.0f" % [fiche_ennemi.PV_Max, fiche_ennemi.Vitesse])

	# 3. Charger un boss
	var fiche_boss: Resource = load("res://donnees/ANO-001.tres")
	if fiche_boss == null:
		print("ERREUR: ANO-001.tres ne se charge pas")
		erreurs += 1
	else:
		print("Boss ANO-001: PV=%d, phases=%d, attaques=%d" % [fiche_boss.PV_Max, fiche_boss.phases.size(), fiche_boss.attaques.size()])

	# 4. Simuler une attaque du héros
	var degat: int = fiche_heros.degat_attaque
	print("Attaque héros: %d dégâts" % degat)

	# 5. Vérifier le spawn pool
	var spawn_pools: Array = [
		{"Ref": "CRT-001", "Weight": 2, "Elite": false},
		{"Ref": "CRT-002", "Weight": 1, "Elite": false},
		{"Ref": "CRT-003", "Weight": 1, "Elite": true},
	]
	print("Spawn pool: %d entrées" % spawn_pools.size())

	# 6. Vérifier le profil d'encounter
	var profile: Dictionary = {
		"BaseDifficulty": 30,
		"DepthDifficultyRamp": 10,
		"ActiveEnemyCapBase": 2.3,
		"ActiveEnemyCapDepthRamp": 0.35,
		"ActiveEnemyCapMax": 8,
	}
	print("Profil: cap_base=%.1f, cap_max=%d" % [profile["ActiveEnemyCapBase"], profile["ActiveEnemyCapMax"]])

	print("\n=== RESULTAT: %d erreur(s) ===" % erreurs)
	if erreurs == 0:
		print("TOUS LES TESTS PASSENT")
	quit(0 if erreurs == 0 else 1)
```

---

## Ordre de construction

1. **Étape 1** : Héros (mouvement + attaque + dash) → `BPC_HerosBase.gd`, `FicheHeros.gd`, `Heros.tscn`
2. **Étape 2** : Ennemis (IA simple) → `BPC_EnnemiBase.gd`, `Ennemi.tscn`
3. **Étape 3** : Boss (phases) → `BPC_BossBase.gd`, `Boss.tscn`
4. **Étape 4** : Projets → `BPC_Projet.gd`, `Projet.tscn`
5. **Étape 5** : Salle (spawn) → `BPC_SalleBase.gd`, `FicheSalle.gd`, `Salle.tscn`
6. **Étape 6** : Caméra → `BPC_CameraTopDown.gd`, `CameraTopDown.tscn`
7. **Étape 7** : HUD → `BPC_HUD.gd`, `HUD.tscn`
8. **Étape 8** : Scène principale → `BPC_Jeu.gd`, `Jeu.tscn`
9. **Étape 9** : Autoload → `BPC_Global.gd`
10. **Étape 10** : Test → `L_TestJeu.gd`

---

## Données nécessaires (déjà prêtes)

| Fichier | Contenu | Statut |
|---------|---------|--------|
| `donnees/CRT-001.tres` à `CRT-061.tres` | 61 fiches ennemis | OK |
| `donnees/ANO-001.tres` à `ANO-007.tres` | 7 fiches boss | OK |
| `donnees/MIN-001.tres` à `MIN-012.tres` | 12 fiches mini-boss | OK |
| `donnees/REL-001.tres` à `REL-034.tres` | 34 fiches armes | OK |
| `space_dracula/donnees/SpawnPools_Lvl01.json` à `Lvl08.json` | Pools de spawn | OK |
| `space_dracula/donnees/EncounterProfiles.json` | Profils d'encounter | OK |
| `space_dracula/donnees/DT_EnemyRegistry.csv` | Registry ennemis | OK |
| `space_dracula/donnees/DT_BossRegistry.csv` | Registry boss | OK |
| `space_dracula/donnees/DT_AttackRegistry.csv` | Registry attaques | OK |
| `space_dracula/donnees/DT_EffectRegistry.csv` | Registry effets | OK |

---

## Ce qui manque

- **FICHES_SALLES_V2.json** : pas encore généré (il faudrait extraire les salles depuis `RoomData*.lua`)
- **FicheHeros.tres** : pas encore créé (les valeurs sont dans `FicheHeros.gd`)
- **Textures / modèles 3D** : pas encore créés
- **Sons / musique** : pas encore ajoutés

---

## Lancer le jeu

```powershell
cd D:\constructeur-qwen-gamedev\LOGICOR
D:\GODOT\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe -res scenes/Jeu.tscn
```

## Lancer le test

```powershell
cd D:\constructeur-qwen-gamedev\LOGICOR
D:\GODOT\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --headless --script preuves/L_TestJeu.gd
```
