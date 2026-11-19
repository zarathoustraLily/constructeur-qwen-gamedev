"""Les autres petits projets de la plomberie (plan « qualité maximale », point D, feu vert de laurent du 2026-11-19 :
« fais 1 et 2 ») : chacun couvre des zones de Godot que les paires couvraient à peine (mesure de `zones.py` du
2026-11-19 : audio 0,5 %, sauvegarde 0,6 %, animation 0,7 %, InputMap 0,7 %, particules 0,7 % du palier 1) et les
fautes de la critique du 2026-11-18 qui manquaient (classe inventée, membre absent à l'exécution, nombre d'arguments,
variable écrasée chaque image, `look_at` sur sa propre position).

- `decor` : un générateur de maillages et de texture (1_core/procedural), une balise qui s'allume avec ses
  particules, un niveau qui les compte et dont la caméra vise la première ;
- `joueur` : un joueur piloté par l'InputMap, ses couches de collision, son animation ;
- `reglages` : des réglages sauvegardés dans `user://` (ConfigFile) et appliqués à un bus audio.

Mêmes règles que le petit projet de base (`plomberie_projet`) : le plan, les avertissements en erreurs, des noms et
des chiffres tirés d'une graine, deux suites GdUnit4 en miroir.
"""

from __future__ import annotations

import random
from dataclasses import dataclass
from typing import Any

from usine.paires.plomberie_fautes import Faute
from usine.paires.plomberie_projet import PROJETS, _debug_strict, _sobre


def _projet(titre: str, principale: str, autoloads: str = "", extra: str = "") -> str:
    return (f"; Projet de l'usine (plomberie) : {titre}.\nconfig_version=5\n\n[application]\n\n"
            f'config/name="{titre}"\nrun/main_scene="res://{principale}"\nconfig/features=PackedStringArray("4.7")\n'
            + (f"\n[autoload]\n\n{autoloads}\n" if autoloads else "") + (f"\n{extra.strip()}\n" if extra else "")
            + f"\n{_debug_strict()}\n")


def _sans_commentaires(f: dict[str, str]) -> dict[str, str]:
    """Les scripts du jeu sans leurs commentaires `##` (ni de classe, ni de membres) : les fichiers de ces projets
    sont plus longs que ceux du projet de base, et la paire de 2 048 jetons porte aussi le plan et de vraies sorties.
    Les tests gardent les leurs : ils disent ce qu'ils jugent."""
    sortie: dict[str, str] = {}
    for rel, texte in f.items():
        if rel.endswith(".gd") and not rel.startswith("7_tests/"):
            lignes = [l for l in _sobre(texte).split("\n") if not l.startswith("## ")]
            texte = "\n".join(lignes)
        sortie[rel] = texte
    return sortie


def _poser_toutes(fautes: list[Faute], f: dict[str, str]) -> list[Faute]:
    for x in fautes:
        x.poser(f)
    return fautes


# --------------------------------------------------------------------------------------------- décor
OBJETS = [("Beacon", "beacon"), ("Lantern", "lantern"), ("Totem", "totem"), ("Pylon", "pylon"), ("Brazier", "brazier"),
          ("Obelisk", "obelisk"), ("Spire", "spire"), ("Torch", "torch")]
LIEUX = ["ridge", "harbor", "ruins", "plaza", "swamp", "summit", "quarry", "orchard"]


@dataclass
class ThemeDecor:
    graine: int
    projet: str
    objet: str
    dossier: str
    lieu: str
    hauteur: float
    rayon: float
    taille: int
    nombre: int
    ecart: float
    couleur: str


def theme_decor(graine: int) -> ThemeDecor:
    rng = random.Random(graine * 7919 + 1)
    objet, dossier = rng.choice(OBJETS)
    return ThemeDecor(graine, f"{rng.choice(PROJETS)} {graine}", objet, dossier, rng.choice(LIEUX),
                      float(rng.choice([1, 2, 3])), rng.choice([0.25, 0.5, 0.75]), rng.choice([8, 16, 32]),
                      rng.choice([1, 2, 3]), float(rng.choice([2, 3, 4])),
                      rng.choice(["Color(1, 0.6, 0.2, 1)", "Color(0.3, 0.8, 1, 1)", "Color(0.9, 0.2, 0.3, 1)"]))


def chemins_decor(th: ThemeDecor) -> dict[str, str]:
    d, l = th.dossier, th.lieu
    return {
        "projet": "project.godot",
        "reglages": f"1_core/data/{d}_settings.gd",
        "constructeur": f"1_core/procedural/{d}_builder.gd",
        "donnees": f"5_data/decor/{d}.tres",
        "objet": f"3_entities/decor/{d}/{d}.gd",
        "objet_scene": f"3_entities/decor/{d}/{d}.tscn",
        "niveau": f"2_sequence/levels/{l}/{l}.gd",
        "niveau_scene": f"2_sequence/levels/{l}/{l}.tscn",
        "test_constructeur": f"7_tests/1_core/procedural/test_{d}_builder.gd",
        "test_niveau": f"7_tests/2_sequence/levels/{l}/test_{l}.gd",
    }


def fichiers_decor(th: ThemeDecor) -> dict[str, str]:
    c = chemins_decor(th)
    o, R, B, N = th.objet, f"{th.objet}Settings", f"{th.objet}Builder", th.lieu.capitalize() + "Level"
    f: dict[str, str] = {}
    f[c["projet"]] = _projet(th.projet, c["niveau_scene"])
    f[c["reglages"]] = f"""class_name {R} extends Resource
## Les cotes d'une balise de décor : sa hauteur, son rayon, sa couleur et la taille de sa texture de lueur.

@export var height: float = 0.0
@export var radius: float = 0.0
@export var color: Color = Color.WHITE
@export var glow_size: int = 0
"""
    f[c["donnees"]] = f"""[gd_resource type="Resource" script_class="{R}" load_steps=2 format=3]

[ext_resource type="Script" path="res://{c['reglages']}" id="1_settings"]

[resource]
script = ExtResource("1_settings")
height = {th.hauteur}
radius = {th.rayon}
color = {th.couleur}
glow_size = {th.taille}
"""
    f[c["constructeur"]] = f"""class_name {B} extends RefCounted
## Les maillages et la texture d'une balise, tirés de ses cotes : un cône (un cylindre au sommet nul), une capsule
## de repère, et une lueur d'un pixel au centre.


static func cone(settings: {R}) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = settings.radius
	mesh.height = settings.height
	return mesh


static func marker(settings: {R}) -> CapsuleMesh:
	var mesh := CapsuleMesh.new()
	mesh.radius = settings.radius
	mesh.height = settings.height
	return mesh


static func glow(settings: {R}) -> Image:
	var image := Image.create(settings.glow_size, settings.glow_size, false, Image.FORMAT_RGBAF)
	image.fill(Color.TRANSPARENT)
	var center: int = settings.glow_size >> 1
	image.set_pixel(center, center, settings.color)
	return image
"""
    f[c["objet"]] = f"""class_name {o} extends Node3D
## Une balise du décor : son cône et son repère se construisent à l'apparition ; allumée, elle lance ses étincelles
## et le dit, une seule fois.

signal lit

@export var settings: {R}

var is_lit: bool = false

@onready var _cone: MeshInstance3D = %Cone
@onready var _marker: MeshInstance3D = %Marker
@onready var _sparks: GPUParticles3D = %Sparks


func _ready() -> void:
	_cone.mesh = {B}.cone(settings)
	_marker.mesh = {B}.marker(settings)
	var material := StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image({B}.glow(settings))
	_marker.material_override = material


func light() -> void:
	if is_lit:
		return
	is_lit = true
	_sparks.restart()
	lit.emit()


func sparks() -> GPUParticles3D:
	return _sparks
"""
    f[c["objet_scene"]] = f"""[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://{c['objet']}" id="1_obj"]
[ext_resource type="Resource" path="res://{c['donnees']}" id="2_settings"]

[node name="{o}" type="Node3D"]
script = ExtResource("1_obj")
settings = ExtResource("2_settings")

[node name="Cone" type="MeshInstance3D" parent="."]
unique_name_in_owner = true

[node name="Marker" type="MeshInstance3D" parent="."]
unique_name_in_owner = true

[node name="Sparks" type="GPUParticles3D" parent="."]
unique_name_in_owner = true
emitting = false
one_shot = true
"""
    f[c["niveau"]] = f"""class_name {N} extends Node3D
## Le niveau : ses balises en ligne ; il compte celles qui sont allumées, et sa caméra vise la première.

const OBJECT_SCENE: PackedScene = preload("res://{c['objet_scene']}")

@export var count: int = 0
@export var spacing: float = 0.0

var lit_count: int = 0
var _objects: Array[{o}] = []

@onready var _camera: Camera3D = %Camera3D


func _ready() -> void:
	for i: int in count:
		var object: {o} = OBJECT_SCENE.instantiate() as {o}
		object.position = Vector3(float(i) * spacing, 0.0, 0.0)
		add_child(object)
		object.lit.connect(_on_lit)
		_objects.append(object)


func _process(_delta: float) -> void:
	if not _objects.is_empty():
		_camera.look_at(_objects[0].global_position)


func objects() -> Array[{o}]:
	return _objects


func _on_lit() -> void:
	lit_count += 1
"""
    f[c["niveau_scene"]] = f"""[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://{c['niveau']}" id="1_level"]

[node name="{N[:-5]}" type="Node3D"]
script = ExtResource("1_level")
count = {th.nombre}
spacing = {th.ecart}

[node name="Camera3D" type="Camera3D" parent="."]
unique_name_in_owner = true
transform = Transform3D(1, 0, 0, 0, 0.866025, 0.5, 0, -0.5, 0.866025, 0, 6, 10)
current = true
"""
    f[c["test_constructeur"]] = f"""extends GdUnitTestSuite
## Les maillages et la lueur suivent les cotes de la balise.

const SETTINGS: {R} = preload("res://{c['donnees']}")


func test_le_cone() -> void:
	var mesh: CylinderMesh = {B}.cone(SETTINGS)
	assert_float(mesh.top_radius).is_equal(0.0)
	assert_float(mesh.bottom_radius).is_equal_approx({th.rayon}, 0.0001)
	assert_float(mesh.height).is_equal_approx({th.hauteur}, 0.0001)


func test_repere_et_lueur() -> void:
	var marker: CapsuleMesh = {B}.marker(SETTINGS)
	assert_float(marker.height).is_equal_approx({th.hauteur}, 0.0001)
	var image: Image = {B}.glow(SETTINGS)
	assert_int(image.get_width()).is_equal({th.taille})
	assert_bool(image.get_pixel({th.taille >> 1}, {th.taille >> 1}).is_equal_approx(SETTINGS.color)).is_true()
"""
    f[c["test_niveau"]] = f"""extends GdUnitTestSuite
## Les balises apparaissent ; chacune allumée compte une fois ; la caméra vise la première.

const LEVEL: PackedScene = preload("res://{c['niveau_scene']}")


func _level() -> {N}:
	var level: {N} = auto_free(LEVEL.instantiate())
	add_child(level)
	return level


func test_allumer_compte_une_fois() -> void:
	var level: {N} = _level()
	assert_int(level.objects().size()).is_equal({th.nombre})
	var object: {o} = level.objects()[0]
	object.light()
	object.light()
	await await_idle_frame()
	assert_int(level.lit_count).is_equal(1)
	assert_bool(object.sparks().emitting).is_true()


func test_la_camera_vise() -> void:
	var level: {N} = _level()
	await await_idle_frame()
	var camera: Camera3D = level.get_node(^"Camera3D")
	var to_object: Vector3 = (level.objects()[0].global_position - camera.global_position).normalized()
	assert_float(-camera.global_basis.z.dot(to_object)).is_greater(0.999)
"""
    return _sans_commentaires(f)


def fautes_decor(th: ThemeDecor) -> list[Faute]:
    c = chemins_decor(th)
    f = fichiers_decor(th)
    R, N = f"{th.objet}Settings", th.lieu.capitalize() + "Level"
    sortie = [
        Faute("classe_inventee", c["constructeur"], "\tvar mesh := CylinderMesh.new()\n\tmesh.top_radius = 0.0\n",
              "\tvar mesh := ConeMesh.new()\n",
              "`ConeMesh` n'existe pas dans Godot 4.7.2 : aucune classe de l'API ne porte ce nom. Un cône se fait avec "
              "`CylinderMesh` et un rayon du haut nul (`top_radius = 0.0`) ; la fonction rend d'ailleurs un "
              "`CylinderMesh`.", "le projet ne démarre plus : le générateur de la balise refuse de se charger."),
        Faute("membre_absent_execution", c["constructeur"], "\tmesh.height = settings.height\n\treturn mesh\n\n\nstatic func glow",
              "\tmesh.mid_height = settings.height\n\treturn mesh\n\n\nstatic func glow",
              "`CapsuleMesh` n'a pas de propriété `mid_height` dans Godot 4.7.2 (c'était Godot 3) : la hauteur est "
              "`height`, hauteur totale de la capsule. L'analyse du script ne le voit pas (`mesh` est un objet : un "
              "script pourrait ajouter la propriété) ; l'erreur n'arrive qu'à l'exécution.",
              "la balise n'a plus son repère et la sortie se remplit d'erreurs."),
        Faute("nombre_arguments", c["constructeur"], "\timage.set_pixel(center, center, settings.color)",
              "\timage.set_pixel(center, center, 0, settings.color)",
              "`Image.set_pixel` prend 3 arguments dans Godot 4.7.2 : `set_pixel(x: int, y: int, color: Color)`. Il "
              "n'y a pas d'argument de calque ou de mipmap.", "le générateur de la balise ne marche plus."),
        Faute("variable_ecrasee", c["niveau"], "func _process(_delta: float) -> void:\n\tif not _objects.is_empty():",
              "func _process(_delta: float) -> void:\n\tlit_count = 0\n\tif not _objects.is_empty():",
              "`_process` remet `lit_count` à 0 à chaque image : le compte des balises allumées est écrasé avant d'avoir "
              "servi. Un compteur ne se remet à zéro qu'au début de la partie, pas à chaque image. Aucune erreur ne le "
              "dit : seul le test qui attend une image le voit.", "le compte des balises allumées reste à zéro.",
              silence=True),
        Faute("look_at_soi", c["niveau"], "\t\t_camera.look_at(_objects[0].global_position)",
              "\t\t_camera.look_at(_camera.global_position)",
              "`look_at` vise la position de la caméra elle-même : la cible et l'origine sont confondues, Godot ne peut "
              "pas en tirer une direction et le signale à chaque image. La caméra doit viser la première balise.",
              "la caméra ne vise plus rien et la sortie se remplit d'erreurs."),
        Faute("particules_non_relancees", c["objet"], "\tis_lit = true\n\t_sparks.restart()\n", "\tis_lit = true\n",
              "Des particules à un seul tir (`one_shot = true`, `emitting = false` dans la scène) ne partent que si on "
              "les relance : `light()` ne lance plus `_sparks.restart()`. Aucune erreur ; seul le test le voit.",
              "les étincelles ne partent plus quand une balise s'allume.", silence=True,
              intention="Quand une balise s'allume, ses étincelles (particules à un seul tir) doivent partir."),
        Faute("signal_lit_non_branche", c["niveau"],
              "\t\tadd_child(object)\n\t\tobject.lit.connect(_on_lit)\n", "\t\tadd_child(object)\n",
              f"Une balise allumée émet `lit`, mais le niveau ne branche plus ce signal à `_on_lit` : `lit_count` ne "
              "bouge pas. Aucune erreur : seul le test le voit.", "le compte des balises allumées reste à zéro.",
              silence=True, intention="Le niveau doit compter chaque balise allumée (signal `lit` de la balise)."),
    ]
    del R, N
    return _poser_toutes(sortie, f)


# --------------------------------------------------------------------------------------------- joueur
COUREURS = [("Pilot", "pilot"), ("Runner", "runner"), ("Scout", "scout"), ("Ranger", "ranger"), ("Courier", "courier")]
OBJETS_RAMASSES = [("Coin", "coin"), ("Gem", "gem"), ("Shard", "shard"), ("Relic", "relic"), ("Orb", "orb")]  # pas « Key » : la classe masquerait l'énumération globale Key
TOUCHES = [(65, 68), (81, 69), (74, 76)]   # (gauche, droite) en physical_keycode : A D, Q E, J L


@dataclass
class ThemeJoueur:
    graine: int
    projet: str
    joueur: str
    dossier: str
    objet: str
    objet_dossier: str
    lieu: str
    vitesse: float
    touches: tuple[int, int]


def theme_joueur(graine: int) -> ThemeJoueur:
    rng = random.Random(graine * 104729 + 3)
    joueur, dossier = rng.choice(COUREURS)
    objet, objet_dossier = rng.choice(OBJETS_RAMASSES)
    return ThemeJoueur(graine, f"{rng.choice(PROJETS)} {graine}", joueur, dossier, objet, objet_dossier,
                       rng.choice(LIEUX), float(rng.choice([3, 4, 5, 6])), rng.choice(TOUCHES))


def chemins_joueur(th: ThemeJoueur) -> dict[str, str]:
    d, o, l = th.dossier, th.objet_dossier, th.lieu
    return {
        "projet": "project.godot",
        "reglages": f"1_core/data/{d}_settings.gd",
        "donnees": f"5_data/actors/{d}.tres",
        "entree": f"3_entities/player/{d}_input.gd",
        "joueur": f"3_entities/player/{d}.gd",
        "joueur_scene": f"3_entities/player/{d}.tscn",
        "objet": f"3_entities/pickups/{o}/{o}.gd",
        "objet_scene": f"3_entities/pickups/{o}/{o}.tscn",
        "niveau_scene": f"2_sequence/levels/{l}/{l}.tscn",
        "niveau": f"2_sequence/levels/{l}/{l}.gd",
        "test_joueur": f"7_tests/3_entities/player/test_{d}.gd",
        "test_niveau": f"7_tests/2_sequence/levels/{l}/test_{l}.gd",
    }


def _action(nom: str, touche: int) -> str:
    return (f'{nom}={{\n"deadzone": 0.2,\n"events": [Object(InputEventKey,"resource_local_to_scene":false,'
            f'"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,'
            f'"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":{touche},'
            f'"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)\n]\n}}')


def fichiers_joueur(th: ThemeJoueur) -> dict[str, str]:
    c = chemins_joueur(th)
    J, I, R, O, N = th.joueur, th.joueur + "Input", th.joueur + "Settings", th.objet, th.lieu.capitalize() + "Level"
    entrees = "[input]\n\n" + _action("move_left", th.touches[0]) + "\n" + _action("move_right", th.touches[1])
    couches = '[layer_names]\n\n3d_physics/layer_1="monde"\n3d_physics/layer_2="joueur"\n3d_physics/layer_3="objets"'
    f: dict[str, str] = {}
    f[c["projet"]] = _projet(th.projet, c["niveau_scene"], extra=entrees + "\n\n" + couches)
    f[c["reglages"]] = f"""class_name {R} extends Resource

@export var speed: float = 0.0
"""
    f[c["donnees"]] = f"""[gd_resource type="Resource" script_class="{R}" load_steps=2 format=3]

[ext_resource type="Script" path="res://{c['reglages']}" id="1_settings"]

[resource]
script = ExtResource("1_settings")
speed = {th.vitesse}
"""
    f[c["entree"]] = f"""class_name {I} extends Node


func direction() -> float:
	return Input.get_axis(&"move_left", &"move_right")
"""
    f[c["joueur"]] = f"""class_name {J} extends CharacterBody3D

@export var settings: {R}
@export var input: {I}

@onready var _animation: AnimationPlayer = %AnimationPlayer


func _physics_process(_delta: float) -> void:
	step()


func step() -> void:
	velocity.x = input.direction() * settings.speed
	move_and_slide()
	_animation.play(&"idle" if is_zero_approx(velocity.x) else &"run")


func animation() -> StringName:
	return _animation.current_animation
"""
    f[c["joueur_scene"]] = f"""[gd_scene load_steps=8 format=3]

[ext_resource type="Script" path="res://{c['joueur']}" id="1_player"]
[ext_resource type="Resource" path="res://{c['donnees']}" id="2_settings"]
[ext_resource type="Script" path="res://{c['entree']}" id="3_input"]

[sub_resource type="CapsuleShape3D" id="CapsuleShape3D_1"]

[sub_resource type="Animation" id="Animation_idle"]
resource_name = "idle"
length = 1.0
loop_mode = 1

[sub_resource type="Animation" id="Animation_run"]
resource_name = "run"
length = 0.5
loop_mode = 1

[sub_resource type="AnimationLibrary" id="AnimationLibrary_1"]
_data = {{
&"idle": SubResource("Animation_idle"),
&"run": SubResource("Animation_run")
}}

[node name="{J}" type="CharacterBody3D" node_paths=PackedStringArray("input")]
collision_layer = 2
collision_mask = 1
script = ExtResource("1_player")
settings = ExtResource("2_settings")
input = NodePath("{I}")

[node name="CollisionShape3D" type="CollisionShape3D" parent="."]
shape = SubResource("CapsuleShape3D_1")

[node name="{I}" type="Node" parent="."]
script = ExtResource("3_input")

[node name="AnimationPlayer" type="AnimationPlayer" parent="."]
unique_name_in_owner = true
libraries = {{
&"": SubResource("AnimationLibrary_1")
}}
"""
    f[c["objet"]] = f"""class_name {O} extends Area3D

signal collected


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(_body: Node3D) -> void:
	collected.emit()
	queue_free()
"""
    f[c["objet_scene"]] = f"""[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://{c['objet']}" id="1_pickup"]

[sub_resource type="SphereShape3D" id="SphereShape3D_1"]

[node name="{O}" type="Area3D"]
collision_layer = 4
collision_mask = 2
script = ExtResource("1_pickup")

[node name="CollisionShape3D" type="CollisionShape3D" parent="."]
shape = SubResource("SphereShape3D_1")
"""
    f[c["niveau"]] = f"""class_name {N} extends Node3D

var collected: int = 0

@onready var _pickup: {O} = %{O}


func _ready() -> void:
	_pickup.collected.connect(_on_collected)


func _on_collected() -> void:
	collected += 1
"""
    f[c["niveau_scene"]] = f"""[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://{c['niveau']}" id="1_level"]
[ext_resource type="PackedScene" path="res://{c['joueur_scene']}" id="2_player"]
[ext_resource type="PackedScene" path="res://{c['objet_scene']}" id="3_pickup"]

[node name="{N[:-5]}" type="Node3D"]
script = ExtResource("1_level")

[node name="{J}" parent="." instance=ExtResource("2_player")]
unique_name_in_owner = true

[node name="{O}" parent="." instance=ExtResource("3_pickup")]
unique_name_in_owner = true
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 8, 0, 0)
"""
    f[c["test_joueur"]] = f"""extends GdUnitTestSuite
## Les actions de l'InputMap pilotent le coureur ; il joue « run » en courant, « idle » à l'arrêt.

const PLAYER: PackedScene = preload("res://{c['joueur_scene']}")


func after_test() -> void:
	Input.action_release(&"move_right")


func test_les_actions_existent() -> void:
	assert_bool(InputMap.has_action(&"move_left") and InputMap.has_action(&"move_right")).is_true()


func test_droite_fait_courir() -> void:
	var player: {J} = auto_free(PLAYER.instantiate())
	add_child(player)
	player.set_physics_process(false)
	Input.action_press(&"move_right")
	player.step()
	assert_float(player.velocity.x).is_equal_approx({th.vitesse}, 0.0001)
	assert_str(String(player.animation())).is_equal("run")
"""
    f[c["test_niveau"]] = f"""extends GdUnitTestSuite
## Le coureur ramasse l'objet en passant dessus : leurs couches de collision se répondent.

const LEVEL: PackedScene = preload("res://{c['niveau_scene']}")


func test_passer_dessus_ramasse() -> void:
	var level: {N} = auto_free(LEVEL.instantiate())
	add_child(level)
	var player: {J} = level.get_node(^"{J}")
	player.set_physics_process(false)
	player.global_position = level.get_node(^"{O}").global_position
	for i: int in 4:
		await get_tree().physics_frame
	assert_int(level.collected).is_equal(1)
"""
    return _sans_commentaires(f)


def fautes_joueur(th: ThemeJoueur) -> list[Faute]:
    c = chemins_joueur(th)
    f = fichiers_joueur(th)
    J, I = th.joueur, th.joueur + "Input"
    gauche, droite = _action("move_left", th.touches[0]), _action("move_right", th.touches[1])
    sortie = [
        Faute("action_absente", c["projet"], gauche + "\n" + droite + "\n", gauche + "\n",
              "Le script d'entrée lit l'action `move_right`, mais la section `[input]` de `project.godot` ne la "
              "déclare plus : Godot le signale à chaque lecture. Une action se déclare dans l'InputMap du projet "
              "(Projet > Paramètres du projet > Contrôles), avec ses touches.", "le coureur ne bouge plus et la sortie "
              "se remplit d'erreurs.", intention="Le coureur doit aller à droite avec l'action `move_right`, déclarée "
              f"dans l'InputMap du projet sur la touche de code physique {th.touches[1]}."),
        Faute("action_mal_nommee", c["entree"], '&"move_left", &"move_right")', '&"move_left", &"move_rigth")',
              "Le script lit l'action `move_rigth`, que l'InputMap ne connaît pas : l'action déclarée dans "
              "`project.godot` s'appelle `move_right`. Le nom d'une action est une chaîne, aucune analyse ne la "
              "vérifie : seule l'exécution le dit.", "le coureur ne bouge plus et la sortie se remplit d'erreurs."),
        Faute("masque_collision", c["objet_scene"], "collision_layer = 4\ncollision_mask = 2\n",
              "collision_layer = 4\ncollision_mask = 1\n",
              "La zone de l'objet ne détecte que la couche 1 (« monde ») : `collision_mask = 1`. Le coureur est sur la "
              "couche 2 (« joueur », `collision_layer = 2`) : la zone ne le voit jamais. Le masque de la zone doit "
              "contenir la couche du coureur. Aucune erreur : seul le test le voit.",
              "le coureur passe sur l'objet sans le ramasser.", silence=True,
              intention="L'objet ne doit détecter que le coureur, qui est sur la couche de collision 2 (« joueur »)."),
        Faute("animation_absente", c["joueur"], '&"idle" if is_zero_approx(velocity.x) else &"run")',
              '&"idle" if is_zero_approx(velocity.x) else &"running")',
              "La bibliothèque de l'AnimationPlayer du coureur a les clips `idle` et `run` ; `running` n'existe pas, "
              "et Godot le signale dès que le coureur court.", "le coureur n'anime plus sa course et la sortie se "
              "remplit d'erreurs.", silence=True),
        Faute("dependance_non_assignee", c["joueur_scene"], f'settings = ExtResource("2_settings")\ninput = NodePath("{I}")\n',
              'settings = ExtResource("2_settings")\n',
              f"Le coureur reçoit son entrée par la propriété exportée `input` (principe 4 du plan : un objet reçoit ce "
              f"dont il a besoin) ; la scène ne l'assigne plus : `input` vaut `null`, et `step()` échoue à chaque "
              "image.", "le coureur ne bouge plus et la sortie se remplit d'erreurs.",
              intention=f"Le coureur doit recevoir son nœud d'entrée `{I}` par sa propriété exportée `input`."),
        Faute("zone_sans_detection", c["objet_scene"], "collision_layer = 4\ncollision_mask = 2\n",
              "collision_layer = 4\ncollision_mask = 2\nmonitoring = false\n",
              "La zone de l'objet a `monitoring = false` : elle ne détecte plus rien, `body_entered` n'est jamais émis. "
              "Aucune erreur : seul le test le voit.", "le coureur passe sur l'objet sans le ramasser.", silence=True),
    ]
    del J
    return _poser_toutes(sortie, f)


# --------------------------------------------------------------------------------------------- réglages
SERVICES = [("Settings", "settings"), ("Preferences", "preferences"), ("Options", "options_store")]
BUS = ["Effects", "Sfx", "Ambience", "Voices"]
SECTIONS = ["audio", "sound", "mix"]


@dataclass
class ThemeReglages:
    graine: int
    projet: str
    service: str
    fichier: str
    bus: str
    section: str
    volume: float


def theme_reglages(graine: int) -> ThemeReglages:
    rng = random.Random(graine * 15485863 + 5)
    service, fichier = rng.choice(SERVICES)
    return ThemeReglages(graine, f"{rng.choice(PROJETS)} {graine}", service, fichier, rng.choice(BUS),
                         rng.choice(SECTIONS), float(rng.choice([-6, -12, -18, -24])))


def chemins_reglages(th: ThemeReglages) -> dict[str, str]:
    return {
        "projet": "project.godot",
        "bus": "default_bus_layout.tres",
        "service": f"0_autoload/{th.fichier}.gd",
        "curseur": "4_ui/menus/volume_slider.gd",
        "menu": "2_sequence/menus/options/options.gd",
        "menu_scene": "2_sequence/menus/options/options.tscn",
        "test_service": f"7_tests/0_autoload/test_{th.fichier}.gd",
        "test_curseur": "7_tests/4_ui/menus/test_volume_slider.gd",
    }


def fichiers_reglages(th: ThemeReglages) -> dict[str, str]:
    c = chemins_reglages(th)
    S = th.service
    f: dict[str, str] = {}
    f[c["projet"]] = _projet(th.projet, c["menu_scene"], autoloads=f'{S}="*res://{c["service"]}"')
    f[c["bus"]] = f"""[gd_resource type="AudioBusLayout" format=3]

[resource]
bus/1/name = &"{th.bus}"
bus/1/solo = false
bus/1/mute = false
bus/1/bypass_fx = false
bus/1/volume_db = 0.0
bus/1/send = &"Master"
"""
    f[c["service"]] = f"""extends Node

signal changed

const PATH: String = "user://reglages.cfg"

var volume_db: float = 0.0


func set_volume(db: float) -> void:
	volume_db = db
	apply()
	save_settings()
	changed.emit()


func apply() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"{th.bus}"), volume_db)


func save_settings() -> Error:
	var file := ConfigFile.new()
	file.set_value("{th.section}", "volume_db", volume_db)
	return file.save(PATH)


func load_settings() -> void:
	var file := ConfigFile.new()
	if file.load(PATH) == OK:
		volume_db = file.get_value("{th.section}", "volume_db", volume_db)
"""
    f[c["curseur"]] = f"""class_name VolumeSlider extends HSlider


func _ready() -> void:
	value = {S}.volume_db
	value_changed.connect(_on_value_changed)


func _on_value_changed(db: float) -> void:
	{S}.set_volume(db)
"""
    f[c["menu"]] = f"""extends Control


func _ready() -> void:
	{S}.load_settings()
	{S}.apply()
"""
    f[c["menu_scene"]] = f"""[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://{c['menu']}" id="1_menu"]
[ext_resource type="Script" path="res://{c['curseur']}" id="2_slider"]

[node name="Options" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1_menu")

[node name="VolumeSlider" type="HSlider" parent="."]
layout_mode = 0
offset_right = 200.0
offset_bottom = 16.0
min_value = -40.0
max_value = 0.0
script = ExtResource("2_slider")
"""
    f[c["test_service"]] = f"""extends GdUnitTestSuite
## Le volume réglé s'applique au bus « {th.bus} » et se relit après la sauvegarde.


func after_test() -> void:
	{S}.set_volume(0.0)


func test_le_volume_s_applique_au_bus() -> void:
	{S}.set_volume({th.volume})
	assert_float(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"{th.bus}"))).is_equal_approx({th.volume}, 0.001)


func test_le_volume_se_relit() -> void:
	{S}.set_volume({th.volume})
	{S}.volume_db = 0.0
	{S}.load_settings()
	assert_float({S}.volume_db).is_equal_approx({th.volume}, 0.001)
"""
    f[c["test_curseur"]] = f"""extends GdUnitTestSuite
## Bouger le curseur règle le volume du jeu.


func after_test() -> void:
	{S}.set_volume(0.0)


func test_le_curseur_regle_le_volume() -> void:
	var slider: VolumeSlider = auto_free(VolumeSlider.new())
	slider.min_value = -40.0
	slider.max_value = 0.0
	add_child(slider)
	slider.value = {th.volume}
	assert_float({S}.volume_db).is_equal_approx({th.volume}, 0.001)
"""
    return _sans_commentaires(f)


def fautes_reglages(th: ThemeReglages) -> list[Faute]:
    c = chemins_reglages(th)
    f = fichiers_reglages(th)
    S = th.service
    sortie = [
        Faute("bus_mal_nomme", c["service"], f'get_bus_index(&"{th.bus}")', f'get_bus_index(&"{th.bus}s")',
              f"`AudioServer.get_bus_index(&\"{th.bus}s\")` rend -1 : aucun bus ne porte ce nom. Le bus déclaré dans "
              f"`default_bus_layout.tres` s'appelle `{th.bus}`, et `set_bus_volume_db` refuse l'index -1.",
              "régler le volume fait une erreur."),
        Faute("bus_absent", c["bus"], f'bus/1/name = &"{th.bus}"\n', f'bus/1/name = &"Master2"\n',
              f"Le script règle le bus `{th.bus}`, mais `default_bus_layout.tres` (la disposition des bus du projet) "
              "ne le déclare plus : son bus 1 s'appelle autrement. Les bus se déclarent dans la disposition (onglet "
              "Audio de l'éditeur), le nom doit être le même des deux côtés.", "régler le volume fait une erreur.",
              intention=f"La disposition des bus `default_bus_layout.tres` doit avoir un bus `{th.bus}` envoyé vers "
              "`Master`, que le réglage du volume emploie."),
        Faute("cle_lecture", c["service"], f'volume_db = file.get_value("{th.section}", "volume_db", volume_db)',
              f'volume_db = file.get_value("{th.section}", "volume", volume_db)',
              f"La lecture cherche la clé `volume` alors que la sauvegarde écrit `volume_db`, dans la section "
              f"`{th.section}` : `get_value` rend la valeur par défaut, sans erreur. Seul le test qui relit le voit.",
              "le volume réglé n'est pas retrouvé au lancement suivant.", silence=True),
        Faute("sauvegarde_oubliee", c["service"], "\tapply()\n\tsave_settings()\n", "\tapply()\n",
              "`set_volume` applique le volume mais ne le sauvegarde plus : le fichier `user://reglages.cfg` garde "
              "l'ancienne valeur. Aucune erreur ; seul le test qui relit le voit.",
              "le volume réglé n'est pas retrouvé au lancement suivant.", silence=True,
              intention="Le volume réglé doit être sauvegardé dans `user://reglages.cfg` (ConfigFile) à chaque "
              "changement, pour être retrouvé au lancement suivant."),
        Faute("chargement_inverse", c["service"], "\tif file.load(PATH) == OK:", "\tif file.load(PATH) != OK:",
              "`load_settings` ne lit la valeur que quand le chargement échoue (`!= OK`) : il faut `== OK`. Aucune "
              "erreur ; seul le test qui relit le voit.", "le volume réglé n'est pas retrouvé au lancement suivant.",
              silence=True),
        Faute("curseur_non_branche", c["curseur"], "\tvalue = " + S + ".volume_db\n\tvalue_changed.connect(_on_value_changed)\n",
              "\tvalue = " + S + ".volume_db\n",
              "Le curseur ne branche plus `value_changed` à `_on_value_changed` : le bouger ne change rien au volume. "
              "Aucune erreur ; seul le test le voit.", "bouger le curseur ne change pas le volume.", silence=True,
              intention=f"Bouger le curseur de volume doit régler le volume du jeu (`{S}.set_volume`)."),
    ]
    return _poser_toutes(sortie, f)


def kits() -> dict[str, Any]:
    from usine.paires.plomberie import Kit

    def suite_decor(th: ThemeDecor, x: Faute) -> str:
        c = chemins_decor(th)
        return c["test_constructeur"] if x.fichier == c["constructeur"] else c["test_niveau"]
    def suite_joueur(th: ThemeJoueur, x: Faute) -> str:
        c = chemins_joueur(th)
        return c["test_niveau"] if x.fichier == c["objet_scene"] else c["test_joueur"]
    def suite_reglages(th: ThemeReglages, x: Faute) -> str:
        c = chemins_reglages(th)
        return c["test_curseur"] if x.fichier == c["curseur"] else c["test_service"]
    return {
        "reglages": Kit("reglages", theme_reglages, fichiers_reglages, fautes_reglages,
                        lambda th: [chemins_reglages(th)["test_service"], chemins_reglages(th)["test_curseur"]],
                        suite_reglages),
        "joueur": Kit("joueur", theme_joueur, fichiers_joueur, fautes_joueur,
                      lambda th: [chemins_joueur(th)["test_joueur"], chemins_joueur(th)["test_niveau"]], suite_joueur),
        "decor": Kit("decor", theme_decor, fichiers_decor, fautes_decor,
                     lambda th: [chemins_decor(th)["test_constructeur"], chemins_decor(th)["test_niveau"]], suite_decor),
    }
