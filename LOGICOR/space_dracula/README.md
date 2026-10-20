# README.md — Space Dracula

Ce fichier explique comment assembler le jeu à partir des données et de la SPEC.

---

## 1. Ce qu'il faut pour construire le jeu

### 1.1 Fichiers de données

| Fichier | Rôle |
|---------|------|
| `fiches/FICHES_ENNEMIS_V2.json` | 61 ennemis (CRT-001 à CRT-061) |
| `fiches/FICHES_BOSSES_V2.json` | 7 bosses (ANO-001 à ANO-007) |
| `fiches/FICHES_ARMES_V2.json` | 34 armes (REL-001 à REL-034) |
| `fiches/FICHES_MINI_BOSSES_V2.json` | 12 mini-bosses (MIN-001 à MIN-012) |
| `donnees/EncounterProfiles.json` | 9 profils de rencontre + mapping niveau→profil |
| `donnees/SpawnPools_Lvl01.json` à `SpawnPools_Lvl08.json` | Pools d'ennemis par niveau |
| `donnees/DT_EffectRegistry.csv` | Registre de tous les effets (8 types) |
| `donnees/MANIFEST.json` | Manifeste des fichiers (counts, schema, hashes) |
| `donnees/MAPPING_SPACE_DRACULA.json` | Mapping de renommage (371 tokens) |
| `donnees/MAPPING_RENOMMAGE.json` | Mapping des 160 entités |

### 1.2 Scripts Godot existants

| Fichier | Rôle | État |
|---------|------|------|
| `donnees/FicheHeros.gd` | Resource du héros | Fait |
| `donnees/FicheEnnemi.gd` | Resource d'un ennemi | Fait |
| `donnees/FicheBoss.gd` | Resource d'un boss | Fait |
| `donnees/FicheArme.gd` | Resource d'une arme | Fait |
| `donnees/FicheMiniBoss.gd` | Resource d'un mini-boss | Fait |
| `donnees/FicheSalle.gd` | Resource d'une salle | Fait |
| `systemes/BPC_Stats.gd` | Système de stats | Fait |
| `systemes/BPC_DegratsPipeline.gd` | Pipeline de dégâts | Fait |
| `systemes/BPC_Invuln.gd` | I-frames | Fait |
| `systemes/BPC_DernierEffort.gd` | Dernier effort | Fait |
| `systemes/BPC_DirectorRun.gd` | Directeur de run | Fait |
| `acteurs/BPC_HerosBase.gd` | Corps du héros | Squelette (pas de mouvement) |
| `acteurs/BPC_EnnemiBase.gd` | Corps d'un ennemi | Squelette (pas d'IA) |
| `acteurs/BPC_SalleBase.gd` | Corps d'une salle | Machine à états (pas de spawn) |
| `adversaires/BPC_AggroSense.gd` | Ciblage | Fait |
| `adversaires/BPC_PhaseManager.gd` | Arbre de décision | Fait |
| `adversaires/BPC_WeaponManager.gd` | Choix d'arme | Fait |

### 1.3 Fiches .tres (Godot Resources)

114 fichiers dans `donnees/` :
- 61 × `CRT-XXX.tres` (ennemis)
- 7 × `ANO-XXX.tres` (bosses)
- 34 × `REL-XXX.tres` (armes)
- 12 × `MIN-XXX.tres` (mini-bosses)

Chaque `.tres` référence le script `.gd` correspondant.

---

## 2. Ordre de construction

### Étape 1 : Scènes de base

Créer les scènes `.tscn` dans `scenes/` :

#### Heros.tscn

```
Heros (CharacterBody3D, script BPC_HerosBase.gd)
├── MeshInstance3D (visuel du héros, placeholder cube)
├── CollisionShape3D (capsule)
├── ZoneFrappe (Area3D, arc de 90° devant le héros)
│   └── CollisionShape3D (forme de l'arc)
└── Camera3D (top-down, offset Y=15, rotation X=-90°)
```

#### Ennemi.tscn

```
Ennemi (CharacterBody3D, script BPC_EnnemiBase.gd)
├── MeshInstance3D (visuel de l'ennemi, placeholder cube rouge)
├── CollisionShape3D (capsule)
└── ZoneFrappe (Area3D, pour les attaques de l'ennemi)
    └── CollisionShape3D
```

#### Boss.tscn

```
Boss (CharacterBody3D, script BPC_BossBase.gd)
├── MeshInstance3D (visuel du boss, placeholder cube grand)
├── CollisionShape3D (sphère)
└── ZoneFrappe (Area3D)
    └── CollisionShape3D
```

#### Salle.tscn

```
Salle (Node, script BPC_SalleBase.gd)
├── Sol (MeshInstance3D, plan 20x20)
├── Mur_Nord (StaticBody3D)
├── Mur_Sud (StaticBody3D)
├── Mur_Est (StaticBody3D)
├── Mur_Ouest (StaticBody3D)
├── SpawnPoints (Node)
│   ├── SpawnPoint_01 (Marker3D, position prédéfinie)
│   ├── SpawnPoint_02 (Marker3D)
│   ├── SpawnPoint_03 (Marker3D)
│   └── SpawnPoint_04 (Marker3D)
├── Ennemis (Node, les ennemis sont ajoutés ici)
└── Porte (Area3D, déverrouillée quand le combat est fini)
    └── CollisionShape3D
```

#### Jeu.tscn

```
Jeu (Node3D)
├── Camera3D (top-down, suit le héros)
├── HUD (CanvasLayer, script HUD.gd)
│   ├── BarrePV (ProgressBar)
│   ├── BarreSouffle (ProgressBar)
│   ├── LabelCombo (Label)
│   └── LabelSalle (Label)
├── DirectorRun (Node, script BPC_DirectorRun.gd)
├── Salle (Node, script BPC_SalleBase.gd)
│   └── (contenu de Salle.tscn)
└── Heros (CharacterBody3D, script BPC_HerosBase.gd)
    └── (contenu de Heros.tscn)
```

### Étape 2 : Mouvement du héros

Dans `BPC_HerosBase.gd`, compléter `_physics_process(delta)`:

```gdscript
func _physics_process(delta: float) -> void:
    if stats:
        stats.tick(delta)
    
    # Lecture des entrées
    var direction := Vector3.ZERO
    if Input.is_action_pressed("haut"):
        direction.z -= 1.0
    if Input.is_action_pressed("bas"):
        direction.z += 1.0
    if Input.is_action_pressed("gauche"):
        direction.x -= 1.0
    if Input.is_action_pressed("droite"):
        direction.x += 1.0
    
    # Normaliser et appliquer la vitesse
    if direction != Vector3.ZERO:
        direction = direction.normalized()
        velocity = direction * 300.0
    else:
        velocity = Vector3.ZERO
    
    move_and_slide()
    
    # Attaque
    if Input.is_action_just_pressed("attaque"):
        _attaquer()
    
    # Dash
    if Input.is_action_just_pressed("dash"):
        _dash()

func _attaquer() -> void:
    # Vérifier les ennemis dans la ZoneFrappe
    for ennemi in get_tree().get_nodes_in_group("ennemis"):
        var dist := global_position.distance_to(ennemi.global_position)
        if dist < 150.0:
            var degats := 10
            if stats.combo >= stats.fiche.seuil_combo:
                degats *= 2
            ennemi.prendre_degrats(degats, self, false)
            stats.combo += 1

func _dash() -> void:
    # Vitesse ×3 pendant dash_duree
    # Activer les i-frames pendant le dash
    pass
```

### Étape 3 : IA des ennemis

Dans `BPC_EnnemiBase.gd`, compléter `_physics_process(delta)`:

```gdscript
@export var aggro: BPC_AggroSense
@export var phase_manager: BPC_PhaseManager
@export var weapon_manager: BPC_WeaponManager
@export var heros: Node

func _ready() -> void:
    if not stats:
        stats = BPC_Stats.new()
        if fiche:
            stats.vie = fiche.PV_Max
    
    if not aggro:
        aggro = BPC_AggroSense.new(fiche.IA_PorteeAggro if fiche else 900.0)
    if not phase_manager:
        phase_manager = BPC_PhaseManager.new()
    if not weapon_manager:
        weapon_manager = BPC_WeaponManager.new()

func _physics_process(delta: float) -> void:
    if est_mort:
        return
    
    if not heros:
        heros = get_tree().get_first_node_in_group("heros")
    
    # Tick de l'IA
    var cible_valide := false
    if heros and is_instance_valid(heros):
        var dist := global_position.distance_to(heros.global_position)
        cible_valide = dist <= (fiche.IA_PorteeAggro if fiche else 900.0)
    
    if cible_valide:
        aggro.marquer(heros)
    
    var etat := phase_manager.tick(stats.vie, global_position, heros.global_position if heros else global_position, cible_valide)
    
    match etat:
        "S_ATTENTE":
            velocity = Vector3.ZERO
        "S_MARQUER":
            velocity = Vector3.ZERO
        "S_AVANCER":
            var direction := (heros.global_position - global_position).normalized()
            velocity = direction * (fiche.Vitesse if fiche else 200.0)
        "S_FRAPPER":
            _attaquer()
            velocity = Vector3.ZERO
        "S_REPLI":
            var direction := (global_position - heros.global_position).normalized()
            velocity = direction * (fiche.Vitesse if fiche else 200.0)
        "S_MORT":
            velocity = Vector3.ZERO
    
    move_and_slide()

func _attaquer() -> void:
    if not heros:
        return
    var dist := global_position.distance_to(heros.global_position)
    if dist < 200.0:
        var degats := 5
        heros.prendre_degrats(degats, self, false)
```

### Étape 4 : Boss et phases

Créer `acteurs/BPC_BossBase.gd` :

```gdscript
extends CharacterBody3D
## BPC_BossBase.gd
## Le corps de base d'un boss (CharacterBody3D).

@export var fiche: FicheBoss
@export var stats: BPC_Stats
@export var est_mort: bool = false
@export var heros: Node

var phase_actuelle: int = 0
var phase_manager: BPC_PhaseManager
var weapon_manager: BPC_WeaponManager

func _ready() -> void:
    if not stats:
        stats = BPC_Stats.new()
        if fiche:
            stats.vie = fiche.PV_Max
    
    if not phase_manager:
        phase_manager = BPC_PhaseManager.new(fiche.phases if fiche else [])
    if not weapon_manager:
        weapon_manager = BPC_WeaponManager.new()

func _physics_process(delta: float) -> void:
    if est_mort:
        return
    
    if not heros:
        heros = get_tree().get_first_node_in_group("heros")
    
    # Vérifier la transition de phase
    if fiche and not fiche.phases.is_empty():
        var ratio_pv := float(stats.vie) / float(fiche.PV_Max)
        while phase_actuelle < fiche.phases.size() - 1:
            var seuil: float = fiche.phases[phase_actuelle].get("props", {}).get("Seuil", 0.0)
            if ratio_pv <= seuil:
                phase_actuelle += 1
                _changer_phase()
    
    # IA (même que l'ennemi)
    # ...

func _changer_phase() -> void:
    # Effets de changement de phase (animation, son)
    pass
```

### Étape 5 : Spawn d'ennemis

Dans `BPC_SalleBase.gd`, compléter le spawn :

```gdscript
@export var spawn_points: Array[Marker3D] = []
@export var noeud_ennemis: Node

func _ready() -> void:
    if fiche:
        delai_apparition = fiche.delai_apparition
        delai_deverrouillage = fiche.delai_deverrouillage
        delai_fin_combat = fiche.delai_fin_combat

func _process(delta: float) -> void:
    match etat:
        EtatSalle.ATTENTE:
            temps_ecoulé += delta
            if temps_ecoulé >= delai_apparition:
                etat = EtatSalle.COMBAT
                temps_ecoulé = 0.0
                _spawner_ennemis()
        EtatSalle.COMBAT:
            if _combat_fini():
                etat = EtatSalle.COMBAT_FINI
                temps_ecoulé = 0.0
        EtatSalle.COMBAT_FINI:
            temps_ecoulé += delta
            if temps_ecoulé >= delai_fin_combat:
                etat = EtatSalle.VERROUILLEE

func _spawner_ennemis() -> void:
    # Choisir des ennemis aléatoires et les spawn dans les SpawnPoints
    pass

func _combat_fini() -> bool:
    # Vérifier si tous les ennemis sont morts
    if noeud_ennemis:
        for enfant in noeud_ennemis.get_children():
            if enfant.has_method("est_dead") and not enfant.est_dead():
                return false
        return true
    return false
```

### Étape 6 : Camera top-down

Dans `Jeu.tscn`, la Camera3D doit suivre le héros :

```gdscript
# Script CameraSuiveur.gd attaché à la Camera3D
extends Camera3D

@export var heros: Node
@export var vitesse_suivi: float = 5.0

func _physics_process(delta: float) -> void:
    if heros and is_instance_valid(heros):
        var cible := heros.global_position + Vector3(0, 15, 0)
        global_position = global_position.lerp(cible, vitesse_suivi * delta)
```

### Étape 7 : HUD

Créer `ui/HUD.gd` :

```gdscript
extends CanvasLayer

@onready var barre_pv: ProgressBar = $BarrePV
@onready var barre_souffle: ProgressBar = $BarreSouffle
@onready var label_combo: Label = $LabelCombo
@onready var label_salle: Label = $LabelSalle

@export var heros: Node

func _process(_delta: float) -> void:
    if heros and is_instance_valid(heros):
        if heros.stats:
            barre_pv.value = heros.stats.vie
            barre_pv.max_value = heros.stats.fiche.vie_max if heros.stats.fiche else 30
            barre_souffle.value = heros.stats.souffle
            barre_souffle.max_value = heros.stats.fiche.souffle_max if heros.stats.fiche else 50
            label_combo.text = "Combo: %d" % heros.stats.combo
```

### Étape 8 : Boucle de jeu complète

Dans `Jeu.tscn`, le nœud principal gère la progression :

```gdscript
extends Node3D

@export var director: BPC_DirectorRun
@export var salle: Node
@export var heros: Node

func _ready() -> void:
    director.fiches_ennemis = _charger_fiches_ennemis()
    director.fiches_salles = _charger_fiches_salles()
    director.demarrer_run()
    _charger_salle()

func _charger_salle() -> void:
    # Charger la salle actuelle dans la scène
    pass

func _salle_terminee() -> void:
    director.salle_suivante()
    _charger_salle()

func _charger_fiches_ennemis() -> Array:
    var fiches: Array = []
    for i in range(1, 62):
        var id := "CRT-%03d" % i
        var chemin := "res://donnees/%s.tres" % id
        if ResourceLoader.exists(chemin):
            fiches.append(load(chemin))
    return fiches

func _charger_fiches_salles() -> Array:
    # Charger les fiches de salles (à créer)
    return []
```

---

## 3. Vérification

### 3.1 Tests headless

```bash
D:\GODOT\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --headless --script preuves/L_TestOracles.gd
D:\GODOT\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --headless --script preuves/L_TestDegrats.gd
D:\GODOT\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --headless --script preuves/L_TestInvuln.gd
D:\GODOT\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --headless --script preuves/L_TestDernierEffort.gd
D:\GODOT\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --headless --script preuves/L_TestDirectorRun.gd
D:\GODOT\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --headless --script preuves/L_TestChargementFiches.gd
```

### 3.2 Vérification des tokens

```bash
python -X utf8 tools/verifier_tokens_sd.py
```

Doit retourner : "AUCUN token Hades II original trouvé."

### 3.3 Test du jeu

1. Ouvrir `LOGICOR/project.godot` dans Godot 4.7.
2. Charger `scenes/Jeu.tscn`.
3. Presser F5 pour lancer le jeu.
4. Vérifier :
   - Le héros se déplace avec ZQSD.
   - Les ennemis apparaissent dans la salle.
   - Les ennemis suivent le héros.
   - L'attaque du héros inflige des dégâts.
   - La mort de tous les ennemis déverrouille la porte.
   - Le HUD affiche les PV, le souffle, le combo.

---

## 4. Pièges à éviter

1. **Ne pas oublier les groupes** : le héros doit être dans le groupe "heros", les ennemis dans le groupe "ennemis".
2. **Ne pas oublier `move_and_slide()`** : sans ça, le héros et les ennemis ne se déplacent pas.
3. **Ne pas oublier les collisions** : chaque CharacterBody3D doit avoir un CollisionShape3D.
4. **Ne pas oublier les i-frames** : pendant les i-frames, les dégâts sont 0.
5. **Ne pas oublier le dernier effort** : il ne se déclenche qu'une fois.
6. **Ne pas oublier les phases des bosses** : le boss change de phase quand son PV passe sous un seuil.
7. **Ne pas oublier les SpawnPoints** : les ennemis spawnent dans des positions prédéfinies, pas au hasard.
8. **Ne pas oublier les groupes de salles** : chaque niveau a 3 salles (Combat, MiniBoss, Boss).

---

## 5. Résumé des actions

| # | Action | Fichier | État |
|---|--------|---------|------|
| 1 | Créer Heros.tscn | `scenes/Heros.tscn` | À faire |
| 2 | Créer Ennemi.tscn | `scenes/Ennemi.tscn` | À faire |
| 3 | Créer Boss.tscn | `scenes/Boss.tscn` | À faire |
| 4 | Créer Salle.tscn | `scenes/Salle.tscn` | À faire |
| 5 | Créer Jeu.tscn | `scenes/Jeu.tscn` | À faire |
| 6 | Compléter BPC_HerosBase.gd | `acteurs/BPC_HerosBase.gd` | À faire |
| 7 | Compléter BPC_EnnemiBase.gd | `acteurs/BPC_EnnemiBase.gd` | À faire |
| 8 | Créer BPC_BossBase.gd | `acteurs/BPC_BossBase.gd` | À faire |
| 9 | Compléter BPC_SalleBase.gd | `acteurs/BPC_SalleBase.gd` | À faire |
| 10 | Créer CameraSuiveur.gd | `ui/CameraSuiveur.gd` | À faire |
| 11 | Créer HUD.gd | `ui/HUD.gd` | À faire |
| 12 | Créer FICHES_SALLES_V2.json | `space_dracula/fiches/` | À faire |
| 13 | Tester le jeu | — | À faire |
