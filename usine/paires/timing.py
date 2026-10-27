"""Famille de paires « timing : ce qu'on voit contre ce qu'on doit produire » (étape A10 du suivi).

laurent (2026-10-27) : « le timng de deplacement rrection entre ce qu'on voit et ceuq o'n doit produire ca serait
bien » ; à la proposition, « oui ». Un petit jeu est généré d'après une graine, rangé selon le plan (socle : machine
à états, ordre d'exécution, journal Trace) : un joueur qui fait un dash et saute, un ennemi qui réagit quand il le
voit. Chaque mécanique a une consigne chiffrée (durée du dash, temps jusqu'au sommet du saut, délai de réaction de
l'ennemi, départ du dash à l'appui). Un défaut de timing est posé par une seule édition d'un script ; on joue le jeu
sans fenêtre à 60 images/s avec des appuis scriptés (`capture_frames`), et la légende, qui reprend le journal Trace,
donne l'instant de chaque changement d'état à l'image près.

Vérité : le jeu sain doit tenir chaque consigne à l'image près ; le jeu fautif doit s'en écarter sur la mécanique
visée ; la correction est l'édition inverse, qui redonne le jeu sain (mesuré).
- analyse (1 024 jetons, sans plan : lire une sortie) : la consigne et la légende → les instants, le compte en
  images, l'écart ou « conforme », ou « jamais produit » (ce n'est pas le temps : la cause est dans le code) ;
- débogage (2 048 jetons, avec le plan) : la consigne, la légende et le script en cause → la mesure, la cause, le
  texte à remplacer, et ce que doit montrer la mesure suivante.

    python -m usine.paires timing [--niveaux N] [--graine G] [--paires P]
"""

from __future__ import annotations

import json
import random
import re
import shutil
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable

from usine import config as cfg
from usine.paires import format as fmt

FAMILLE = "timing"
SUJET = "gameplay"
IMAGES_PAR_SECONDE = 60
SOCLE = cfg.RACINE / "godot" / "socle_jeu"
FICHIERS_DU_SOCLE = ("1_core/state_machine/state.gd", "1_core/state_machine/state_machine.gd",
                     "1_core/process_order.gd", "1_core/components/health_component.gd", "0_autoload/trace.gd")
SCENE = "res://2_sequence/levels/level.tscn"
APPUI_DASH = 10  # image de l'appui sur dash (--capture-press=dash:10-10)


# ------------------------------------------------------------------ réglages d'un jeu

@dataclass
class Jeu:
    graine: int
    dash_duree: float  # s
    dash_vitesse: float  # m/s
    gravite: float  # m/s²
    sommet: float  # s jusqu'au sommet du saut
    reaction: float  # s entre « voit le joueur » et « poursuit »
    portee: float  # m
    ennemi_x: float  # m

    @property
    def saut_vitesse(self) -> float:
        return round(self.gravite * self.sommet, 3)

    def images(self, secondes: float) -> int:
        return round(secondes * IMAGES_PAR_SECONDE)

    @property
    def appui_saut(self) -> int:
        return APPUI_DASH + self.images(self.dash_duree) + 30


def jeu(graine: int) -> Jeu:
    rng = random.Random(graine)
    duree = rng.choice([0.2, 0.25, 0.3, 0.4, 0.5])
    vitesse = float(rng.choice([10, 12, 15]))
    portee = float(rng.choice([3, 4, 5]))
    # La gravité est un multiple de 15 : le pas de vitesse par image (g/60) tombe juste, le sommet aussi.
    return Jeu(graine, duree, vitesse, float(rng.choice([15, 30, 45, 60])), rng.choice([0.3, 0.4, 0.5]),
               rng.choice([0.2, 0.25, 0.3, 0.5]), portee, round(vitesse * duree + portee - 0.5, 2))


# ------------------------------------------------------------------ fichiers du jeu

def _touche(code: int) -> str:
    return ('Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,'
            '"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,'
            f'"keycode":0,"physical_keycode":{code},"key_label":0,"unicode":0,"location":0,"echo":false,'
            '"script":null)')


def _debug_du_socle() -> str:
    texte = (SOCLE / "project.godot").read_text(encoding="utf-8")
    return re.search(r"^\[debug\]\n.*?(?=^\[)", texte, re.S | re.M).group(0).rstrip("\n")


def project_godot() -> str:
    return "\n".join([
        "config_version=5", "", "[application]", "", 'config/name="Timing"', f'run/main_scene="{SCENE}"',
        'config/features=PackedStringArray("4.7")', "", "[autoload]", "", 'Trace="*res://0_autoload/trace.gd"', "",
        _debug_du_socle(), "", "[input]", "",
        'dash={\n"deadzone": 0.2,\n"events": [' + _touche(4194325) + "\n]\n}",
        'jump={\n"deadzone": 0.2,\n"events": [' + _touche(32) + "\n]\n}", ""])


STATS_JOUEUR = '''class_name PlayerStats
extends Resource
## Définition du joueur, immuable pendant la partie : ses valeurs vivent dans 5_data/actors/player.tres.

## Durée du dash, en secondes.
@export var dash_duration: float = 0.0
## Vitesse du dash, en mètres par seconde.
@export var dash_speed: float = 0.0
## Vitesse verticale au départ du saut, en mètres par seconde.
@export var jump_velocity: float = 0.0
## Gravité, en mètres par seconde carrée.
@export var gravity: float = 0.0
'''

STATS_ENNEMI = '''class_name EnemyStats
extends Resource
## Définition de l'ennemi, immuable pendant la partie : ses valeurs vivent dans 5_data/actors/enemy.tres.

## Distance à laquelle il voit sa cible, en mètres.
@export var sight_range: float = 0.0
## Délai entre le moment où il voit sa cible et le début de la poursuite, en secondes.
@export var reaction_time: float = 0.0
## Vitesse de poursuite, en mètres par seconde.
@export var chase_speed: float = 0.0
'''

JOUEUR = '''class_name Player
extends CharacterBody3D
## Le joueur (simulation). Il consomme des intentions (set_intent), jamais le clavier : player_input.gd les lui
## donne. Comportements : états (states/). Réglages : 5_data/actors/player.tres.
## Entrées : set_intent(). Possède : les intentions du tour.

@export var stats: PlayerStats

## Intentions du tour, posées par player_input.gd.
var wants_dash: bool = false
var wants_jump: bool = false


func set_intent(dash: bool, jump: bool) -> void:
	wants_dash = dash
	wants_jump = jump
'''

ENTREES = '''class_name PlayerInput
extends Node
## Adaptateur d'entrées : lit le clavier et donne au joueur des intentions, au pas fixe, avant les
## déplacements (ProcessOrder.INPUT). Dépend de : player (posé dans la scène).

@export var player: Player

var _dash_held: bool = false
var _jump_held: bool = false


func _ready() -> void:
	process_physics_priority = ProcessOrder.INPUT


func _physics_process(_delta: float) -> void:
	var dash := Input.is_action_pressed(&"dash")
	var jump := Input.is_action_pressed(&"jump")
	# Une seule intention par appui, comptée au pas fixe.
	player.set_intent(dash and not _dash_held, jump and not _jump_held)
	_dash_held = dash
	_jump_held = jump
'''

JOUEUR_REPOS = '''extends State
## Joueur au repos : il part en dash ou en saut à l'appui.


func physics_update(_delta: float) -> void:
	var player := actor as Player
	if player.wants_dash:
		transition_requested.emit(&"dash")
	elif player.wants_jump:
		transition_requested.emit(&"jump")
'''

JOUEUR_DASH = '''extends State
## Dash : le joueur file vers +X à stats.dash_speed pendant stats.dash_duration, puis revient au repos.

var _time_left: float = 0.0


func enter() -> void:
	_time_left = (actor as Player).stats.dash_duration


func physics_update(delta: float) -> void:
	var player := actor as Player
	player.velocity = Vector3(player.stats.dash_speed, 0.0, 0.0)
	player.move_and_slide()
	_time_left -= delta
	if _time_left <= 0.0 or is_zero_approx(_time_left):
		player.velocity = Vector3.ZERO
		transition_requested.emit(&"idle")
'''

JOUEUR_SAUT = '''extends State
## Saut : le joueur part vers le haut à stats.jump_velocity, la gravité le freine ; au sommet, il retombe.


func enter() -> void:
	var player := actor as Player
	player.velocity = Vector3(0.0, player.stats.jump_velocity, 0.0)


func physics_update(delta: float) -> void:
	var player := actor as Player
	player.velocity.y -= player.stats.gravity * delta
	player.move_and_slide()
	if player.velocity.y <= 0.0 or is_zero_approx(player.velocity.y):
		transition_requested.emit(&"fall")
'''

JOUEUR_CHUTE = '''extends State
## Chute : la gravité tire le joueur vers le bas jusqu'au sol, puis il revient au repos.


func physics_update(delta: float) -> void:
	var player := actor as Player
	player.velocity.y -= player.stats.gravity * delta
	player.move_and_slide()
	if player.is_on_floor():
		player.velocity = Vector3.ZERO
		transition_requested.emit(&"idle")
'''

ENNEMI = '''class_name Enemy
extends CharacterBody3D
## L'ennemi (simulation). Il surveille sa cible, que le niveau lui donne (setup). Comportements : états
## (states/). Réglages : 5_data/actors/enemy.tres.
## Entrées : setup(). Possède : sa cible.

@export var stats: EnemyStats

var target: Node3D


func setup(new_target: Node3D) -> void:
	target = new_target


func sees_target() -> bool:
	return target != null and global_position.distance_to(target.global_position) <= stats.sight_range
'''

ENNEMI_REPOS = '''extends State
## Ennemi au repos : il guette ; dès qu'il voit sa cible, il passe en alerte.


func physics_update(_delta: float) -> void:
	if (actor as Enemy).sees_target():
		transition_requested.emit(&"alert")
'''

ENNEMI_ALERTE = '''extends State
## Alerte : l'ennemi a vu sa cible ; après stats.reaction_time, il la poursuit.

var _time_left: float = 0.0


func enter() -> void:
	_time_left = (actor as Enemy).stats.reaction_time


func physics_update(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0 or is_zero_approx(_time_left):
		transition_requested.emit(&"chase")
'''

ENNEMI_POURSUITE = '''extends State
## Poursuite : l'ennemi va vers sa cible à stats.chase_speed, sur le sol.


func physics_update(_delta: float) -> void:
	var enemy := actor as Enemy
	var toward := enemy.target.global_position - enemy.global_position
	toward.y = 0.0
	enemy.velocity = toward.normalized() * enemy.stats.chase_speed
	enemy.move_and_slide()
'''

NIVEAU = '''extends Node3D
## Niveau d'essai du timing : le sol, le joueur, l'ennemi. Il donne à l'ennemi sa cible (setup).

@onready var _player: Player = $Player
@onready var _enemy: Enemy = $Enemy


func _ready() -> void:
	_enemy.setup(_player)
'''


def _tres(classe: str, script: str, valeurs: dict[str, float]) -> str:
    lignes = [f'[gd_resource type="Resource" script_class="{classe}" format=3]', "",
              f'[ext_resource type="Script" path="res://{script}" id="1_stats"]', "", "[resource]",
              'script = ExtResource("1_stats")']
    lignes += [f"{k} = {v!r}" for k, v in valeurs.items()]
    return "\n".join(lignes) + "\n"


def _scene_acteur(nom: str, script: str, stats: str, etats: list[str], entrees: bool, couleur: str) -> str:
    dossier = f"3_entities/{nom.lower()}"
    ext = [(f"res://{dossier}/{script}", "Script", "1_acteur"), (f"res://{stats}", "Resource", "2_stats"),
           ("res://1_core/state_machine/state_machine.gd", "Script", "3_machine")]
    ext += [(f"res://{dossier}/states/{nom.lower()}_{e}.gd", "Script", f"{4 + k}_{e}") for k, e in enumerate(etats)]
    if entrees:
        ext.append((f"res://{dossier}/player_input.gd", "Script", "9_entrees"))
    blocs = ["[gd_scene format=3]",
             "\n".join(f'[ext_resource type="{t}" path="{p}" id="{i}"]' for p, t, i in ext),
             '[sub_resource type="CapsuleShape3D" id="CapsuleShape3D_corps"]',
             f'[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_corps"]\nalbedo_color = {couleur}',
             '[sub_resource type="CapsuleMesh" id="CapsuleMesh_corps"]\nmaterial = SubResource("StandardMaterial3D_corps")',
             f'[node name="{nom}" type="CharacterBody3D"]\nscript = ExtResource("1_acteur")\nstats = ExtResource("2_stats")',
             '[node name="Forme" type="CollisionShape3D" parent="."]\nshape = SubResource("CapsuleShape3D_corps")',
             '[node name="Corps" type="MeshInstance3D" parent="."]\nmesh = SubResource("CapsuleMesh_corps")']
    if entrees:
        blocs.append('[node name="PlayerInput" type="Node" parent="." node_paths=PackedStringArray("player")]\n'
                     'script = ExtResource("9_entrees")\nplayer = NodePath("..")')
    blocs.append('[node name="StateMachine" type="Node" parent="." node_paths=PackedStringArray("initial_state")]\n'
                 f'script = ExtResource("3_machine")\ninitial_state = NodePath("{etats[0].capitalize()}")')
    blocs += [f'[node name="{e.capitalize()}" type="Node" parent="StateMachine"]\nscript = ExtResource("{4 + k}_{e}")'
              for k, e in enumerate(etats)]
    return "\n\n".join(blocs) + "\n"


def _scene_niveau(j: Jeu) -> str:
    return "\n\n".join([
        "[gd_scene format=3]",
        '[ext_resource type="Script" path="res://2_sequence/levels/level.gd" id="1_niveau"]\n'
        '[ext_resource type="PackedScene" path="res://3_entities/player/player.tscn" id="2_joueur"]\n'
        '[ext_resource type="PackedScene" path="res://3_entities/enemy/enemy.tscn" id="3_ennemi"]',
        '[sub_resource type="BoxShape3D" id="BoxShape3D_sol"]\nsize = Vector3(80, 1, 12)',
        '[sub_resource type="BoxMesh" id="BoxMesh_sol"]\nsize = Vector3(80, 1, 12)',
        '[node name="Level" type="Node3D"]\nscript = ExtResource("1_niveau")',
        '[node name="Soleil" type="DirectionalLight3D" parent="."]\nrotation = Vector3(-0.9, 0.6, 0)',
        '[node name="Sol" type="StaticBody3D" parent="."]\nposition = Vector3(20, -0.5, 0)',
        '[node name="Forme" type="CollisionShape3D" parent="Sol"]\nshape = SubResource("BoxShape3D_sol")',
        '[node name="Dalle" type="MeshInstance3D" parent="Sol"]\nmesh = SubResource("BoxMesh_sol")',
        '[node name="Player" parent="." instance=ExtResource("2_joueur")]\nposition = Vector3(0, 1, 0)',
        f'[node name="Enemy" parent="." instance=ExtResource("3_ennemi")]\nposition = Vector3({j.ennemi_x:g}, 1, 0)',
        '[node name="Camera3D" type="Camera3D" parent="."]\nposition = Vector3(6, 4, 16)\n'
        'rotation = Vector3(-0.2, 0, 0)\nfov = 60.0',
    ]) + "\n"


def fichiers(j: Jeu) -> dict[str, str]:
    """Le jeu sain : chemin dans le projet → texte."""
    f = {"project.godot": project_godot(),
         "1_core/data/player_stats.gd": STATS_JOUEUR, "1_core/data/enemy_stats.gd": STATS_ENNEMI,
         "5_data/actors/player.tres": _tres("PlayerStats", "1_core/data/player_stats.gd", {
             "dash_duration": j.dash_duree, "dash_speed": j.dash_vitesse, "jump_velocity": j.saut_vitesse,
             "gravity": j.gravite}),
         "5_data/actors/enemy.tres": _tres("EnemyStats", "1_core/data/enemy_stats.gd", {
             "sight_range": j.portee, "reaction_time": j.reaction, "chase_speed": 2.0}),
         "3_entities/player/player.gd": JOUEUR, "3_entities/player/player_input.gd": ENTREES,
         "3_entities/player/states/player_idle.gd": JOUEUR_REPOS,
         "3_entities/player/states/player_dash.gd": JOUEUR_DASH,
         "3_entities/player/states/player_jump.gd": JOUEUR_SAUT,
         "3_entities/player/states/player_fall.gd": JOUEUR_CHUTE,
         "3_entities/player/player.tscn": _scene_acteur("Player", "player.gd", "5_data/actors/player.tres",
                                                        ["idle", "dash", "jump", "fall"], True,
                                                        "Color(0.2, 0.5, 1, 1)"),
         "3_entities/enemy/enemy.gd": ENNEMI, "3_entities/enemy/states/enemy_idle.gd": ENNEMI_REPOS,
         "3_entities/enemy/states/enemy_alert.gd": ENNEMI_ALERTE,
         "3_entities/enemy/states/enemy_chase.gd": ENNEMI_POURSUITE,
         "3_entities/enemy/enemy.tscn": _scene_acteur("Enemy", "enemy.gd", "5_data/actors/enemy.tres",
                                                      ["idle", "alert", "chase"], False, "Color(1, 0.3, 0.2, 1)"),
         "2_sequence/levels/level.gd": NIVEAU, "2_sequence/levels/level.tscn": _scene_niveau(j)}
    return f


def ecrire_projet(textes: dict[str, str], dossier: Path) -> Path:
    if dossier.exists():
        shutil.rmtree(dossier)
    for chemin in FICHIERS_DU_SOCLE:
        cible = dossier / chemin
        cible.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(SOCLE / chemin, cible)
    for chemin, texte in textes.items():
        cible = dossier / chemin
        cible.parent.mkdir(parents=True, exist_ok=True)
        cible.write_text(texte, encoding="utf-8", newline="\n")
    return dossier


# ------------------------------------------------------------------ jouer et mesurer

RE_LIGNE = re.compile(r"^\s+(\d+\.\d\d) s (\w+) : (\w+) → (\w+)$")


@dataclass(frozen=True)
class Evenement:
    temps: float
    acteur: str
    avant: str
    apres: str

    @property
    def image(self) -> int:
        return round(self.temps * IMAGES_PAR_SECONDE)


def touches(j: Jeu) -> list[str]:
    return [f"dash:{APPUI_DASH}-{APPUI_DASH}", f"jump:{j.appui_saut}-{j.appui_saut}"]


def images_capturees(j: Jeu) -> list[int]:
    fin = j.appui_saut + 2 * j.images(j.sommet) + 20
    return [APPUI_DASH, APPUI_DASH + j.images(j.dash_duree) // 2, j.appui_saut, j.appui_saut + j.images(j.sommet),
            fin]


def jouer(projet: Path, j: Jeu, images: list[int] | None = None, fenetre: bool = False) -> dict[str, Any]:
    """Joue le jeu avec les appuis du scénario (`capture_frames`) : {ok, legende, images, evenements, erreurs}.
    `fenetre` : fenêtre hors de l'écran, comme à l'usage (la légende nomme la grille) ; sinon sans fenêtre."""
    from usine.retour.capture import capturer
    images = images or images_capturees(j)
    r = capturer(projet, images, touches=touches(j), sans_image=not fenetre, hors_ecran=fenetre,
                 compatibilite=fenetre)
    evenements = [Evenement(float(m.group(1)), m.group(2), m.group(3), m.group(4))
                  for l in r.get("legende", "").splitlines() if (m := RE_LIGNE.match(l))]
    erreurs = [l for l in r.get("erreurs", []) if l.startswith(("ERROR", "SCRIPT ERROR"))]
    return {"ok": r["ok"] and not erreurs, "legende": r.get("legende", "").rstrip("\n"), "images": images,
            "evenements": evenements, "erreurs": erreurs, "erreur": r.get("erreur")}


def premier(ev: list[Evenement], acteur: str, avant: str | None, apres: str, apres_image: int = 0) -> Evenement | None:
    return next((e for e in ev if e.acteur == acteur and e.apres == apres and (avant is None or e.avant == avant)
                 and e.image >= apres_image), None)


# ------------------------------------------------------------------ mécaniques et consignes

@dataclass(frozen=True)
class Mecanique:
    nom: str
    acteur: str
    debut: tuple[str, str] | None  # la ligne du journal qui ouvre la mesure ; None : l'appui sur dash
    fin: tuple[str, str]
    sujet: str
    consigne: Callable[[Jeu], str]
    attendu: Callable[[Jeu], int]  # images entre le début et la fin


MECANIQUES = {m.nom: m for m in [
    Mecanique("dash", "Player", ("idle", "dash"), ("dash", "idle"), "gameplay",
              lambda j: f"le dash dure {j.dash_duree:g} s, soit {j.images(j.dash_duree)} images à 60 images/s",
              lambda j: j.images(j.dash_duree)),
    Mecanique("depart", "Player", None, ("idle", "dash"), "contrôle à la manette",
              lambda j: f"le dash part à l'image qui suit l'appui (appui scripté à l'image {APPUI_DASH})",
              lambda j: 1),
    Mecanique("saut", "Player", ("idle", "jump"), ("jump", "fall"), "physique",
              lambda j: f"le saut atteint son sommet {j.sommet:g} s après le départ, soit {j.images(j.sommet)} images",
              lambda j: j.images(j.sommet)),
    Mecanique("reaction", "Enemy", ("idle", "alert"), ("alert", "chase"), "gameplay",
              lambda j: (f"l'ennemi se lance à la poursuite {j.reaction:g} s après avoir vu le joueur, soit "
                         f"{j.images(j.reaction)} images"),
              lambda j: j.images(j.reaction)),
]}


def mesurer(mec: Mecanique, ev: list[Evenement]) -> dict[str, Any]:
    """{debut (image), debut_ev, fin_ev, images (None si la fin manque)}."""
    if mec.debut is None:
        debut, debut_ev = APPUI_DASH, None
    else:
        debut_ev = premier(ev, mec.acteur, *mec.debut)
        debut = debut_ev.image if debut_ev else None
    fin_ev = premier(ev, mec.acteur, *mec.fin, apres_image=debut) if debut is not None else None
    return {"debut": debut, "debut_ev": debut_ev, "fin_ev": fin_ev,
            "images": fin_ev.image - debut if fin_ev is not None and debut is not None else None}


# ------------------------------------------------------------------ défauts

@dataclass(frozen=True)
class Defaut:
    nom: str
    mecanique: str
    fichier: str  # le fichier édité ; montré en premier dans la paire de débogage
    editer: Callable[[Jeu], tuple[str, str]]  # (texte sain, texte fautif)
    cause: Callable[[Jeu], str]
    montres: tuple[str, ...] = ()  # autres fichiers montrés


DASH = "3_entities/player/states/player_dash.gd"
SAUT = "3_entities/player/states/player_jump.gd"
ALERTE = "3_entities/enemy/states/enemy_alert.gd"
ENTREES_F = "3_entities/player/player_input.gd"
FIN_FLOTTANTE = "\tif _time_left <= 0.0 or is_zero_approx(_time_left):"
CAUSE_FLOTTANTE = ("le décompte en float, ôté par pas de 1/60, garde un reste infime au-dessus de 0 quand la durée "
                   "tombe juste : `_time_left <= 0.0` seul attend une image de plus. Avec `is_zero_approx(_time_left)`, "
                   "{quoi} s'arrête à la bonne image")

DEFAUTS = [
    Defaut("dash_reste_flottant", "dash", DASH, lambda j: (FIN_FLOTTANTE, "\tif _time_left <= 0.0:"),
           lambda j: CAUSE_FLOTTANTE.format(quoi="le dash")),
    Defaut("dash_double_decompte", "dash", DASH,
           lambda j: ("func physics_update(delta: float) -> void:",
                      "func _process(delta: float) -> void:\n\t_time_left -= delta\n\n\n"
                      "func physics_update(delta: float) -> void:"),
           lambda j: ("le décompte descend deux fois par image : `_process` ôte aussi `delta`, en plus de "
                      "`physics_update` ; le dash dure moitié moins. Le décompte d'un état avance dans "
                      "`physics_update` seulement, au pas fixe")),
    Defaut("depart_ordre", "depart", ENTREES_F,
           lambda j: ("\tprocess_physics_priority = ProcessOrder.INPUT",
                      "\tprocess_physics_priority = ProcessOrder.ATTACK"),
           lambda j: ("les entrées passent après la machine à états : `ProcessOrder.ATTACK` (0) vient après "
                      "`ProcessOrder.MOVEMENT` (-10), et Godot traite d'abord la plus petite valeur. L'état lit donc "
                      "l'intention posée à l'image précédente : une image de retard au départ. Les entrées passent "
                      "en premier, avec `ProcessOrder.INPUT` (-30)"),
           ("1_core/process_order.gd",)),
    Defaut("depart_en_process", "depart", ENTREES_F,
           lambda j: ("func _physics_process(_delta: float) -> void:", "func _process(_delta: float) -> void:"),
           lambda j: ("les intentions sont posées dans `_process`, qui passe après la physique de chaque image : "
                      "l'état ne les lit qu'à l'image suivante. Lues dans `_physics_process`, avant les "
                      "déplacements, elles servent à la même image")),
    Defaut("saut_sommet_strict", "saut", SAUT,
           lambda j: ("\tif player.velocity.y <= 0.0 or is_zero_approx(player.velocity.y):",
                      "\tif player.velocity.y < 0.0:"),
           lambda j: ("au sommet, la vitesse verticale tombe à 0 (la gravité ôte gravity/60 par image) ; "
                      "`velocity.y < 0.0` attend l'image suivante pour passer en chute. Avec `<= 0.0` (et "
                      "`is_zero_approx`), le sommet est pris à la bonne image")),
    Defaut("saut_gravite_double", "saut", "3_entities/player/player.gd",
           lambda j: ("func set_intent(dash: bool, jump: bool) -> void:\n\twants_dash = dash\n\twants_jump = jump\n",
                      "func set_intent(dash: bool, jump: bool) -> void:\n\twants_dash = dash\n\twants_jump = jump\n"
                      "\n\nfunc _physics_process(delta: float) -> void:\n\tif not is_on_floor():\n"
                      "\t\tvelocity.y -= stats.gravity * delta\n"),
           lambda j: ("la gravité est appliquée deux fois par image en l'air : par l'état (jump, fall) et par le "
                      "`_physics_process` de player.gd ; la vitesse verticale tombe à 0 presque deux fois plus tôt. "
                      "Le comportement vit dans l'état : retirer la gravité de player.gd"),
           (SAUT,)),
    Defaut("saut_donnee", "saut", "5_data/actors/player.tres",
           lambda j: (f"jump_velocity = {j.saut_vitesse!r}", f"jump_velocity = {2 * j.saut_vitesse!r}"),
           lambda j: (f"dans les données, jump_velocity vaut {2 * j.saut_vitesse:g} m/s : avec gravity = "
                      f"{j.gravite:g} m/s², le sommet arrive après {2 * j.saut_vitesse:g} / {j.gravite:g} = "
                      f"{2 * j.sommet:g} s. Pour {j.sommet:g} s : jump_velocity = gravity × {j.sommet:g} = "
                      f"{j.saut_vitesse:g}"),
           (SAUT,)),
    Defaut("reaction_reste_flottant", "reaction", ALERTE, lambda j: (FIN_FLOTTANTE, "\tif _time_left <= 0.0:"),
           lambda j: CAUSE_FLOTTANTE.format(quoi="l'alerte")),
    Defaut("reaction_relance", "reaction", ALERTE,
           lambda j: ("\t_time_left -= delta\n", "\t_time_left = (actor as Enemy).stats.reaction_time\n"
                                                 "\t_time_left -= delta\n"),
           lambda j: ("le décompte est remis à stats.reaction_time à chaque image, juste avant d'ôter `delta` : il "
                      "ne descend jamais sous reaction_time - 1/60 et la poursuite ne part jamais. Le décompte se "
                      "pose une seule fois, dans `enter()`")),
    Defaut("reaction_millisecondes", "reaction", "5_data/actors/enemy.tres",
           lambda j: (f"reaction_time = {j.reaction!r}", f"reaction_time = {j.reaction * 1000:.1f}"),
           lambda j: (f"dans les données, reaction_time vaut {j.reaction * 1000:g} : la valeur est en secondes "
                      f"(« Délai … en secondes », enemy_stats.gd), soit {j.reaction * 1000:g} s, et la poursuite ne "
                      f"part pas pendant la capture. Pour {j.reaction:g} s : reaction_time = {j.reaction:g}"),
           ("1_core/data/enemy_stats.gd",)),
]

# Où regarder quand la consigne n'est pas tenue (sans dire la cause : la légende seule ne la donne pas).
INDICES = {"dash": "le décompte de l'état dash et sa condition de fin",
           "depart": "l'ordre d'exécution des entrées et des états",
           "saut": "la gravité appliquée en l'air, la détection du sommet et jump_velocity",
           "reaction": "le décompte de l'état alert et reaction_time"}


# ------------------------------------------------------------------ lire la légende

def _t(e: Evenement) -> str:
    return f"{e.temps:.2f} s (image {e.image})"


def _n(n: int) -> str:
    return f"{n} image{'s' if abs(n) > 1 else ''}"


def _s(images: int) -> str:
    return f"{images / IMAGES_PAR_SECONDE:.2f} s"


def lecture(mec: Mecanique, m: dict[str, Any], j: Jeu, derniere_image: int) -> tuple[str, str]:
    """Ce que dit la légende pour cette mécanique : (texte, verdict) ; verdict : conforme, ecart, jamais,
    fenetre (la capture s'arrête avant l'instant attendu), ou illisible (le début manque)."""
    attendu = mec.attendu(j)
    a, b = mec.fin
    if mec.debut is None:
        debut = f"l'appui sur dash est posé à l'image {APPUI_DASH}"
    elif m["debut_ev"] is None:
        return f"Aucune ligne {mec.acteur} : {mec.debut[0]} → {mec.debut[1]} dans la légende.", "illisible"
    else:
        debut = f"{mec.acteur} : {mec.debut[0]} → {mec.debut[1]} à {_t(m['debut_ev'])}"
    texte = f"Les instants viennent du journal (temps × 60 = numéro d'image) : {debut}"
    if m["fin_ev"] is not None:
        n = m["images"]
        texte += f", {a} → {b} à {_t(m['fin_ev'])} : {_n(n)}, soit {_s(n)}."
        if n == attendu:
            return texte + f" La consigne demande {_n(attendu)} : elle est tenue.", "conforme"
        ecart = n - attendu
        texte += (f" La consigne demande {_n(attendu)} : {_n(abs(ecart))} de "
                  f"{'trop' if ecart > 0 else 'moins'}. À chercher : {INDICES[mec.nom]}.")
        return texte, "ecart"
    attendue = m["debut"] + attendu
    texte += f" ; aucune ligne {mec.acteur} : {a} → {b}."
    if derniere_image < attendue:
        return texte + (f" La capture s'arrête à l'image {derniere_image} ({_s(derniere_image)}), et {a} → {b} est "
                        f"attendu à l'image {attendue} ({_s(attendue)}) : la fenêtre est trop courte, ce n'est pas "
                        f"un défaut. Relancer capture_frames avec une dernière image après {attendue}, par exemple "
                        f"{attendue + 10}."), "fenetre"
    texte += (f" La capture va jusqu'à l'image {derniere_image}, {derniere_image - m['debut']} images après le début, "
              f"et la consigne en demande {attendu} : ce n'est pas la fenêtre, {a} → {b} ne se produit jamais. "
              f"À chercher : {INDICES[mec.nom]}.")
    return texte, "jamais"


# ------------------------------------------------------------------ paires

plan = fmt.plan  # le bloc permanent du socle (section 3)


def _demande(mec: Mecanique, j: Jeu, r: dict[str, Any]) -> str:
    return (f"Consigne : {mec.consigne(j)}.\ncapture_frames, images {', '.join(map(str, r['images']))}, appuis "
            f"{', '.join(touches(j))}. Sortie :\n{r['legende']}")


def paire_analyse(mec: Mecanique, j: Jeu, r: dict[str, Any], defaut: Defaut | None = None) -> dict[str, Any]:
    texte, verdict = lecture(mec, mesurer(mec, r["evenements"]), j, max(r["images"]))
    return fmt.paire(FAMILLE, mec.sujet, "analyse", _demande(mec, j, r) + "\n\nLa consigne est-elle tenue ?", texte,
                     {"outil": "capture_frames", "graine": j.graine, "mecanique": mec.nom, "verdict": verdict,
                      "defaut": defaut.nom if defaut else None})


def _bloc(chemin: str, texte: str) -> str:
    langue = "gdscript" if chemin.endswith(".gd") else ""
    return f"res://{chemin} :\n```{langue}\n{texte.rstrip(chr(10))}\n```"


def paire_debogage(d: Defaut, j: Jeu, rf: dict[str, Any], rs: dict[str, Any], fautifs: dict[str, str],
                   edition: tuple[str, str]) -> dict[str, Any]:
    """`edition` : (texte fautif, texte correct)."""
    mec = MECANIQUES[d.mecanique]
    texte, verdict = lecture(mec, mesurer(mec, rf["evenements"]), j, max(rf["images"]))
    texte = texte.split(" À chercher : ")[0]  # la cause suit, lue dans le code
    sain = mesurer(mec, rs["evenements"])
    debut = (f"l'image {APPUI_DASH} de l'appui" if mec.debut is None
             else f"{mec.debut[0]} → {mec.debut[1]}, à {_t(sain['debut_ev'])}")
    texte += (f"\nCause : {d.cause(j)}.\n\nDans res://{d.fichier}, remplacer :\n```\n{edition[0]}\n```\npar :\n```\n"
              f"{edition[1]}\n```\nPuis relancer capture_frames avec les mêmes appuis : {mec.fin[0]} → {mec.fin[1]} "
              f"doit arriver à {_t(sain['fin_ev'])}, {_n(mec.attendu(j))} après {debut}.")
    blocs = "\n\n".join(_bloc(c, fautifs[c] if c in fautifs else (SOCLE / c).read_text(encoding="utf-8"))
                        for c in (d.fichier, *d.montres))
    return fmt.paire(FAMILLE, mec.sujet, "débogage", f"{_demande(mec, j, rf)}\n\n{blocs}\n\nCorrige pour tenir la "
                     "consigne.", texte,
                     {"outil": "capture_frames", "graine": j.graine, "mecanique": mec.nom, "verdict": verdict,
                      "defaut": d.nom, "symptome_mesure": True, "correction_mesuree": True}, systeme=plan())


# ------------------------------------------------------------------ générer

PLAFONDS = {"analyse": 1024, "débogage": 2048}


def _jouer_valide(projet: Path, j: Jeu, images: list[int] | None = None) -> dict[str, Any]:
    """Une partie valide contient au moins le départ du dash (tous les cas le gardent) ; sinon on la rejoue une
    fois : une partie vide ne doit jamais passer pour « jamais produit »."""
    for _ in range(2):
        r = jouer(projet, j, images, fenetre=True)
        if r["ok"] and premier(r["evenements"], "Player", "idle", "dash"):
            return r
    return r


def cas_du_jeu(graine: int, travail: Path) -> tuple[list[dict[str, Any]], list[str]]:
    j = jeu(graine)
    sain = fichiers(j)
    rs = _jouer_valide(ecrire_projet(sain, travail / "sain"), j)
    ecarts = {n: (mesurer(m, rs["evenements"])["images"], m.attendu(j)) for n, m in MECANIQUES.items()}
    if not rs["ok"] or any(a != b for a, b in ecarts.values()):
        return [], [f"graine {graine} : jeu sain hors consigne {ecarts} {rs['erreurs'][:2]}"]
    paires = [paire_analyse(m, j, rs) for m in MECANIQUES.values()]
    # Fenêtre trop courte : le même jeu sain, capturé jusqu'à 5 images avant le sommet du saut.
    courte = [i for i in images_capturees(j) if i < j.appui_saut + j.images(j.sommet) - 5]
    courte.append(j.appui_saut + j.images(j.sommet) - 5)
    rc = _jouer_valide(ecrire_projet(sain, travail / "sain"), j, sorted(set(courte)))
    if rc["ok"] and lecture(MECANIQUES["saut"], mesurer(MECANIQUES["saut"], rc["evenements"]), j,
                            max(rc["images"]))[1] == "fenetre":
        paires.append(paire_analyse(MECANIQUES["saut"], j, rc))
    rejets = []
    for d in DEFAUTS:
        correct, faux = d.editer(j)
        if sain[d.fichier].count(correct) != 1:
            rejets.append(f"graine {graine}, {d.nom} : texte à remplacer absent ou répété")
            continue
        fautifs = dict(sain)
        fautifs[d.fichier] = sain[d.fichier].replace(correct, faux)
        rf = _jouer_valide(ecrire_projet(fautifs, travail / "fautif"), j)
        mec = MECANIQUES[d.mecanique]
        verdict = lecture(mec, mesurer(mec, rf["evenements"]), j, max(rf["images"]))[1]
        if not rf["ok"] or verdict not in ("ecart", "jamais"):
            rejets.append(f"graine {graine}, {d.nom} : pas de symptôme ({verdict}) {rf['erreurs'][:2]}")
            continue
        paires += [paire_analyse(mec, j, rf, d), paire_debogage(d, j, rf, rs, fautifs, (faux, correct))]
    return paires, rejets


def generer(niveaux: int, graine: int = 1, donnees: Path | None = None,
            journal: Callable[[str], None] = print, cible: int | None = None) -> dict[str, Any]:
    """Comme les familles A8 et A9 : `niveaux` jeux au plus, arrêt au jeu qui atteint `cible`, jeux complets."""
    sortie = fmt.dossier(FAMILLE, donnees)
    paires: list[dict[str, Any]] = []
    rejets: list[str] = []
    faits = 0
    with tempfile.TemporaryDirectory(prefix="usine_timing_") as tmp:
        for g in range(graine, graine + niveaux):
            nouvelles, rej = cas_du_jeu(g, Path(tmp))
            paires += nouvelles
            rejets += rej
            faits += 1
            journal(f"graine {g} : {len(nouvelles)} paires, {len(rej)} rejets")
            if cible is not None and sum(p["jetons"] <= PLAFONDS[p["type"]] for p in paires) >= cible:
                break
    trop_longues = [p for p in paires if p["jetons"] > PLAFONDS[p["type"]]]
    retenues = [p for p in paires if p["jetons"] <= PLAFONDS[p["type"]]]
    fmt.ecrire(retenues, sortie / "paires.jsonl")
    bilan: dict[str, Any] = {
        "jeux": faits, "graine": graine, "paires": len(retenues), "trop_longues": len(trop_longues),
        "rejets": rejets, "par_type": {t: sum(p["type"] == t for p in retenues) for t in fmt.TYPES},
        "par_verdict": {}, "par_defaut": {},
        "jetons_max": {t: max((p["jetons"] for p in retenues if p["type"] == t), default=0) for t in fmt.TYPES}}
    for p in retenues:
        v, dn = p["preuve"]["verdict"], p["preuve"]["defaut"] or "aucun"
        bilan["par_verdict"][v] = bilan["par_verdict"].get(v, 0) + 1
        bilan["par_defaut"][dn] = bilan["par_defaut"].get(dn, 0) + 1
    (sortie / "bilan.json").write_text(json.dumps(bilan, indent=1, ensure_ascii=False), encoding="utf-8")
    return bilan
