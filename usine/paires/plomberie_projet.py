"""Les petits projets complets de la famille « plomberie de projet » (décision 24 de laurent, 2026-11-18).

Un projet suit le plan (`godot/socle_jeu/AGENTS.md`) : un autoload de score (0_autoload), un composant de santé et
une classe de réglages (1_core), les réglages de l'ennemi en `.tres` (5_data), l'ennemi et sa scène (3_entities),
l'arène qui fait apparaître les ennemis et branche leur signal au score, avec sa caméra (2_sequence), et deux suites
GdUnit4 en miroir (7_tests). Les avertissements de GDScript sont des erreurs (règle 5.3 : le bloc [debug] du socle).

Les noms et les chiffres sont tirés d'une graine : deux projets ne se ressemblent pas mot pour mot (règle 7.7), mais
la plomberie est la même, celle où un modèle se trompe (autoloads, `class_name`, nœuds des scènes, ressources,
signaux, caméra, scène principale).
"""

from __future__ import annotations

import random
import re
from dataclasses import dataclass

from usine import config as cfg

ENNEMIS = [("Slime", "slime"), ("Drone", "drone"), ("Golem", "golem"), ("Bat", "bat"), ("Wisp", "wisp"),
           ("Crab", "crab"), ("Beetle", "beetle"), ("Turret", "turret"), ("Ghoul", "ghoul"), ("Spore", "spore"),
           ("Mimic", "mimic"), ("Sentinel", "sentinel")]
NIVEAUX = ["arena", "cave", "forest", "dock", "crypt", "garden", "factory", "canyon", "temple", "harbor"]
AUTOLOADS = [("GameState", "game_state"), ("ScoreBoard", "score_board"), ("RunState", "run_state"),
             ("Session", "session")]
COMPOSANTS = [("HealthComponent", "health_component"), ("LifeComponent", "life_component"),
              ("HitPoints", "hit_points")]
REGLAGES = [("ActorStats", "actor_stats"), ("EnemyStats", "enemy_stats"), ("ActorSettings", "actor_settings")]
PROJETS = ["Arène", "Survie", "Vagues", "Donjon", "Défense", "Chasse"]


@dataclass
class Theme:
    graine: int
    projet: str
    ennemi: str          # classe de l'ennemi
    dossier: str         # dossier et fichiers de l'ennemi
    niveau: str
    autoload: str
    autoload_fichier: str
    composant: str
    composant_fichier: str
    reglages: str
    reglages_fichier: str
    vie: float
    points: int
    nombre: int
    ecart: float


def theme(graine: int) -> Theme:
    rng = random.Random(graine)
    ennemi, dossier = rng.choice(ENNEMIS)
    autoload, autoload_fichier = rng.choice(AUTOLOADS)
    composant, composant_fichier = rng.choice(COMPOSANTS)
    reglages, reglages_fichier = rng.choice(REGLAGES)
    return Theme(graine, f"{rng.choice(PROJETS)} {graine}", ennemi, dossier, rng.choice(NIVEAUX), autoload,
                 autoload_fichier, composant, composant_fichier, reglages, reglages_fichier,
                 float(rng.choice([20, 30, 40, 50, 60, 80, 100])), rng.choice([5, 10, 15, 20, 25, 50]),
                 rng.choice([1, 2]), float(rng.choice([2, 3, 4])))


def niveau_classe(th: Theme) -> str:
    return th.niveau.capitalize() + "Level"


def _debug_strict() -> str:
    """Le bloc [debug] du socle (avertissements traités en erreurs, règle 5.3), tel quel."""
    texte = (cfg.RACINE / "godot" / "socle_jeu" / "project.godot").read_text(encoding="utf-8")
    debut = texte.index("[debug]")
    fin = texte.find("\n[", debut + 1)
    return texte[debut:fin if fin > 0 else len(texte)].strip()


def chemins(th: Theme) -> dict[str, str]:
    """Les chemins relatifs des fichiers du projet, par rôle."""
    return {
        "projet": "project.godot",
        "autoload": f"0_autoload/{th.autoload_fichier}.gd",
        "composant": f"1_core/components/{th.composant_fichier}.gd",
        "reglages": f"1_core/data/{th.reglages_fichier}.gd",
        "donnees": f"5_data/enemies/{th.dossier}.tres",
        "ennemi": f"3_entities/enemies/{th.dossier}/{th.dossier}.gd",
        "ennemi_scene": f"3_entities/enemies/{th.dossier}/{th.dossier}.tscn",
        "niveau": f"2_sequence/levels/{th.niveau}/{th.niveau}.gd",
        "niveau_scene": f"2_sequence/levels/{th.niveau}/{th.niveau}.tscn",
        "test_composant": f"7_tests/1_core/components/test_{th.composant_fichier}.gd",
        "test_niveau": f"7_tests/2_sequence/levels/{th.niveau}/test_{th.niveau}.gd",
    }


def fichiers(th: Theme) -> dict[str, str]:
    c = chemins(th)
    t = th
    f: dict[str, str] = {}
    f[c["projet"]] = f"""; Projet de l'usine (plomberie) : {t.projet}.
config_version=5

[application]

config/name="{t.projet}"
run/main_scene="res://{c['niveau_scene']}"
config/features=PackedStringArray("4.7")

[autoload]

{t.autoload}="*res://{c['autoload']}"

{_debug_strict()}
"""
    f[c["autoload"]] = f"""extends Node
## Le score de la partie, pour tout le jeu : il augmente quand un ennemi est vaincu.

## Le score a changé.
signal score_changed(score: int)

## Le score de la partie.
var score: int = 0


## Ajoute `points` au score et le signale.
func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)
"""
    f[c["composant"]] = f"""class_name {t.composant} extends Node
## La vie d'un acteur : elle baisse sous les coups, sans passer sous zéro ; à zéro, l'acteur meurt une seule fois.

## La vie a changé.
signal changed(current: float)
## La vie est tombée à zéro.
signal died

## La vie qui reste.
var current: float = 0.0


## Donne à l'acteur sa vie de départ.
func setup(maximum: float) -> void:
	current = maximum


## Retire `amount` à la vie ; rien si le coup est nul ou si l'acteur est déjà mort.
func take_damage(amount: float) -> void:
	if amount <= 0.0 or current <= 0.0:
		return
	current = maxf(current - amount, 0.0)
	changed.emit(current)
	if is_zero_approx(current):
		died.emit()
"""
    f[c["reglages"]] = f"""class_name {t.reglages} extends Resource
## Les réglages d'un ennemi : sa vie et les points qu'il rapporte (valeurs dans 5_data).

## La vie de départ.
@export var max_health: float = 0.0
## Les points rapportés quand il est vaincu.
@export var points: int = 0
"""
    f[c["donnees"]] = f"""[gd_resource type="Resource" script_class="{t.reglages}" load_steps=2 format=3]

[ext_resource type="Script" path="res://{c['reglages']}" id="1_stats"]

[resource]
script = ExtResource("1_stats")
max_health = {t.vie}
points = {t.points}
"""
    f[c["ennemi"]] = f"""class_name {t.ennemi} extends Node3D
## Un ennemi : il encaisse les coups par sa vie et, vaincu, annonce les points qu'il rapporte avant de disparaître.

## L'ennemi est vaincu.
signal defeated(points: int)

## Ses réglages (5_data).
@export var stats: {t.reglages}

@onready var _health: {t.composant} = %Health


func _ready() -> void:
	_health.setup(stats.max_health)
	_health.died.connect(_on_died)


## Encaisse un coup de `amount`.
func hit(amount: float) -> void:
	_health.take_damage(amount)


## La vie qui reste.
func health() -> float:
	return _health.current


func _on_died() -> void:
	defeated.emit(stats.points)
	queue_free()
"""
    f[c["ennemi_scene"]] = f"""[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://{c['ennemi']}" id="1_enemy"]
[ext_resource type="Resource" path="res://{c['donnees']}" id="2_stats"]
[ext_resource type="Script" path="res://{c['composant']}" id="3_health"]

[node name="{t.ennemi}" type="Node3D"]
script = ExtResource("1_enemy")
stats = ExtResource("2_stats")

[node name="Health" type="Node" parent="."]
unique_name_in_owner = true
script = ExtResource("3_health")
"""
    f[c["niveau"]] = f"""class_name {niveau_classe(t)} extends Node3D
## Le niveau : il fait apparaître ses ennemis en ligne et branche chacun au score de la partie.

const ENEMY_SCENE: PackedScene = preload("res://{c['ennemi_scene']}")

## Le nombre d'ennemis.
@export var enemy_count: int = 0
## L'écart entre deux ennemis, en mètres.
@export var spacing: float = 0.0


func _ready() -> void:
	for i: int in enemy_count:
		var enemy: {t.ennemi} = ENEMY_SCENE.instantiate() as {t.ennemi}
		enemy.position = Vector3(float(i) * spacing, 0.0, 0.0)
		add_child(enemy)
		enemy.defeated.connect({t.autoload}.add_score)


## Les ennemis encore là.
func enemies() -> Array[{t.ennemi}]:
	var found: Array[{t.ennemi}] = []
	for child: Node in get_children():
		if child is {t.ennemi}:
			found.append(child as {t.ennemi})
	return found
"""
    f[c["niveau_scene"]] = f"""[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://{c['niveau']}" id="1_level"]

[node name="{t.niveau.capitalize()}" type="Node3D"]
script = ExtResource("1_level")
enemy_count = {t.nombre}
spacing = {t.ecart}

[node name="Camera3D" type="Camera3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 0.866025, 0.5, 0, -0.5, 0.866025, 0, 6, 10)
current = true
"""
    f[c["test_composant"]] = f"""extends GdUnitTestSuite
## La vie baisse sous les coups sans passer sous zéro ; l'acteur meurt une seule fois.


func test_un_coup_retire_de_la_vie() -> void:
	var health: {t.composant} = auto_free({t.composant}.new())
	health.setup(10.0)
	health.take_damage(4.0)
	assert_float(health.current).is_equal_approx(6.0, 0.0001)


func test_la_mort_arrive_une_seule_fois() -> void:
	var health: {t.composant} = auto_free({t.composant}.new())
	var deaths: Array[int] = [0]
	health.died.connect(func() -> void: deaths[0] += 1)
	health.setup(5.0)
	health.take_damage(9.0)
	health.take_damage(9.0)
	assert_float(health.current).is_equal(0.0)
	assert_int(deaths[0]).is_equal(1)
"""
    f[c["test_niveau"]] = f"""extends GdUnitTestSuite
## Le niveau fait apparaître ses ennemis ; un ennemi vaincu rapporte ses points au score.

const LEVEL: PackedScene = preload("res://{c['niveau_scene']}")


func before_test() -> void:
	{t.autoload}.score = 0


func _level() -> {niveau_classe(t)}:
	var level: {niveau_classe(t)} = auto_free(LEVEL.instantiate())
	add_child(level)
	return level


func test_les_ennemis_apparaissent() -> void:
	var level: {niveau_classe(t)} = _level()
	assert_int(level.enemies().size()).is_equal({t.nombre})


func test_un_ennemi_vaincu_rapporte_ses_points() -> void:
	var level: {niveau_classe(t)} = _level()
	var enemy: {t.ennemi} = level.enemies()[0]
	enemy.hit({t.vie})
	assert_int({t.autoload}.score).is_equal({t.points})
"""
    return {rel: (_sobre(texte) if rel.endswith(".gd") and not rel.startswith("7_tests/") else texte)
            for rel, texte in f.items()}


def _sobre(texte: str) -> str:
    """Le script sans les commentaires `##` de ses membres : seul celui de la classe reste (sous la première ligne).
    Les paires de 2 048 jetons portent le plan, l'arbre, deux fichiers et de vraies sorties : chaque ligne compte."""
    lignes = texte.split("\n")
    entete = 1
    while entete < len(lignes) and lignes[entete].startswith("## "):
        entete += 1
    return "\n".join(l for i, l in enumerate(lignes) if i < entete or not l.startswith("## "))


def arbre(f: dict[str, str]) -> str:
    """Les fichiers du projet, un chemin par ligne, rangés (addons/ résumé)."""
    return "\n".join(["res://", "  addons/gdUnit4/  (extension de tests)"] + ["  " + rel for rel in sorted(f)])


def sans_debug(projet_godot: str) -> str:
    """project.godot montré sans son bloc [debug] (les avertissements traités en erreurs, dit à part)."""
    return re.sub(r"\n\[debug\]\n.*?(?=\n\[|\Z)", "\n[debug]\n; (les avertissements de GDScript traités en erreurs, typage compris)",
                  projet_godot, flags=re.S).rstrip() + "\n"
