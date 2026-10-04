"""Générateur des 10 tâches modèles de la session 1.

Source unique : le projet godot/reference/. Chaque tâche y applique des remplacements
textuels exacts (vérifiés : chaque motif doit apparaître une seule fois), puis :
  - depart/       = projet de référence modifié (sans addons) ;
  - reference/    = fichiers d'origine restaurés (+ ajouts propres à la tâche) ;
  - tests_caches/ = tests de non-régression du projet + tests propres à la tâche.
Les journaux (K3, D1) sont produits en lançant vraiment Godot sur depart/.

Règle 5 : une tâche fausse se corrige ici, puis on régénère :
    python outils/construire_taches_modeles.py
"""

from __future__ import annotations

import json
import shutil
import sys
import tempfile
from dataclasses import dataclass, field
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(RACINE))

from usine import config as cfg  # noqa: E402
from usine.juge import godot as juges  # noqa: E402
from usine.juge.projet import preparer_copie  # noqa: E402
from usine.juge.verdict import sans_ansi  # noqa: E402
from usine.processus import executer  # noqa: E402
from usine.taches import calculer_empreinte  # noqa: E402
# Gabarits partagés avec les générateurs de la session 3 (texte identique).
from usine.generateurs.gabarits import CATEGORIES_D1, CONSIGNE_D1, GABARIT_TEST_D1, GABARIT_TEST_S2  # noqa: E402,F401

REFERENCE = RACINE / "godot" / "reference"
SORTIE = RACINE / "godot" / "taches_modeles"
ORIGINE = "modele_manuel_session_01"


@dataclass
class Tache:
    id: str
    competence: str
    consigne: str
    remplacements: dict[str, list[tuple[str, str]]] = field(default_factory=dict)
    ajouts_depart: dict[str, str] = field(default_factory=dict)
    ajouts_reference: dict[str, str] = field(default_factory=dict)
    tests_specifiques: dict[str, str] = field(default_factory=dict)
    regression: bool = True          # copier les tests du projet dans tests_caches/
    restaurer: bool = True           # reference/ restaure les fichiers modifiés
    juge: dict = field(default_factory=dict)
    journal_tests: bool = False      # K3 : verdict des tests visibles dans depart/journal_tests.json
    d1: dict | None = None           # D1 : {"fichier", "repere", "categorie"} → journal + réponse attendue


# --- Scripts et tests ajoutés par les tâches S1 -----------------------------------------------

HEART_PICKUP_GD = '''class_name HeartPickup
extends Area2D
## Cœur à ramasser : rend des points de vie au héros.

signal consumed(amount: int)

@export var heal_amount: int = 1


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Hero:
		apply_to(body)


func apply_to(hero: Hero) -> void:
	hero.health.heal(heal_amount)
	consumed.emit(heal_amount)
	queue_free()
'''

HEART_PICKUP_TSCN = '''[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/heart_pickup.gd" id="1_heart"]

[sub_resource type="CircleShape2D" id="CircleShape2D_heart"]
radius = 5.0

[node name="HeartPickup" type="Area2D"]
script = ExtResource("1_heart")
heal_amount = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_heart")
'''

TEST_S1_HEART = '''extends GdUnitTestSuite
## Juge S1 : structure et comportement de res://scenes/heart_pickup.tscn.

const SCENE := "res://scenes/heart_pickup.tscn"


func _instance() -> Node:
	var scene: PackedScene = load(SCENE)
	assert_object(scene).is_not_null()
	var noeud: Node = auto_free(scene.instantiate())
	add_child(noeud)
	return noeud


func test_racine() -> void:
	var racine := _instance()
	assert_str(racine.name).is_equal("HeartPickup")
	assert_bool(racine is Area2D).is_true()
	assert_bool(racine is HeartPickup).is_true()


func test_forme_de_collision() -> void:
	var racine := _instance()
	var forme := racine.get_node_or_null("CollisionShape2D") as CollisionShape2D
	assert_object(forme).is_not_null()
	assert_bool(forme.shape is CircleShape2D).is_true()
	assert_float((forme.shape as CircleShape2D).radius).is_equal_approx(5.0, 0.001)


func test_rend_deux_points_de_vie() -> void:
	var coeur := _instance() as HeartPickup
	assert_int(coeur.heal_amount).is_equal(2)
	var hero: Hero = auto_free(load("res://scenes/hero.tscn").instantiate())
	add_child(hero)
	hero.health.take_damage(3)
	coeur.apply_to(hero)
	assert_int(hero.health.current_health).is_equal(4)
'''

SPIKE_TRAP_GD = '''class_name SpikeTrap
extends Area2D
## Piège à pointes : blesse le héros au contact, puis se recharge.

signal triggered(damage: int)

@export var damage: int = 1

@onready var cooldown: Timer = $Cooldown


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Hero:
		hit(body)


func is_armed() -> bool:
	return cooldown.is_stopped()


## Blesse le héros si le piège est armé, puis lance la recharge.
func hit(hero: Hero) -> bool:
	if not is_armed():
		return false
	hero.health.take_damage(damage)
	cooldown.start()
	triggered.emit(damage)
	return true
'''

SPIKE_TRAP_TSCN = '''[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/spike_trap.gd" id="1_spike"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_spike"]
size = Vector2(16, 16)

[node name="SpikeTrap" type="Area2D"]
script = ExtResource("1_spike")
damage = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_spike")

[node name="Cooldown" type="Timer" parent="."]
wait_time = 1.5
one_shot = true
'''

TEST_S1_SPIKE = '''extends GdUnitTestSuite
## Juge S1 : structure et comportement de res://scenes/spike_trap.tscn.

const SCENE := "res://scenes/spike_trap.tscn"


func _instance() -> Node:
	var scene: PackedScene = load(SCENE)
	assert_object(scene).is_not_null()
	var noeud: Node = auto_free(scene.instantiate())
	add_child(noeud)
	return noeud


func test_racine() -> void:
	var racine := _instance()
	assert_str(racine.name).is_equal("SpikeTrap")
	assert_bool(racine is SpikeTrap).is_true()
	assert_int((racine as SpikeTrap).damage).is_equal(2)


func test_forme_de_collision() -> void:
	var racine := _instance()
	var forme := racine.get_node_or_null("CollisionShape2D") as CollisionShape2D
	assert_object(forme).is_not_null()
	assert_bool(forme.shape is RectangleShape2D).is_true()
	assert_vector((forme.shape as RectangleShape2D).size).is_equal(Vector2(16, 16))


func test_minuteur_de_recharge() -> void:
	var racine := _instance()
	var minuteur := racine.get_node_or_null("Cooldown") as Timer
	assert_object(minuteur).is_not_null()
	assert_float(minuteur.wait_time).is_equal_approx(1.5, 0.001)
	assert_bool(minuteur.one_shot).is_true()
	assert_bool(minuteur.autostart).is_false()


func test_blesse_puis_se_recharge() -> void:
	var piege := _instance() as SpikeTrap
	var hero: Hero = auto_free(load("res://scenes/hero.tscn").instantiate())
	add_child(hero)
	assert_bool(piege.hit(hero)).is_true()
	assert_int(hero.health.current_health).is_equal(3)
	assert_bool(piege.hit(hero)).is_false()
	assert_int(hero.health.current_health).is_equal(3)
'''

# --- Les 10 tâches ---------------------------------------------------------------------------

TACHES: list[Tache] = [
    Tache(
        id="k2_001_take_damage",
        competence="K2",
        consigne=(
            "Implémenter le corps de HealthComponent.take_damage dans res://scripts/health_component.gd, "
            "en respectant le contrat écrit en commentaire au-dessus de la méthode. Les tests de "
            "res://tests/test_health_component.gd sont rouges : ils doivent passer, sans casser les autres. "
            "Ne pas changer la signature."
        ),
        remplacements={"scripts/health_component.gd": [(
            '''## Retire des points de vie. Renvoie vrai si les dégâts ont été appliqués.
func take_damage(amount: int) -> bool:
	if amount <= 0 or invulnerable or is_dead():
		return false
	current_health = maxi(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		died.emit()
	return true
''',
            '''## Retire `amount` points de vie et renvoie vrai si les dégâts ont été appliqués.
## Sans effet (renvoie faux) si amount <= 0, si `invulnerable` est vrai ou si déjà mort.
## Les points de vie ne descendent jamais sous 0. Après chaque changement, émet
## health_changed(current_health, max_health) ; émet died une seule fois, quand ils atteignent 0.
func take_damage(amount: int) -> bool:
	return false
''')]},
    ),
    Tache(
        id="k2_002_start_next_wave",
        competence="K2",
        consigne=(
            "Implémenter le corps de WaveSpawner.start_next_wave dans res://scripts/wave_spawner.gd, "
            "en respectant le contrat écrit en commentaire au-dessus de la méthode. Les tests de "
            "res://tests/test_wave_spawner.gd et res://tests/test_main.gd sont rouges : ils doivent passer, "
            "sans casser les autres. Ne pas changer la signature."
        ),
        remplacements={"scripts/wave_spawner.gd": [(
            '''func start_next_wave() -> void:
	current_wave += 1
	var count: int = enemies_for_wave(current_wave)
	alive = 0
	for pos in spawn_positions(count):
		var enemy: Ghost = enemy_scene.instantiate()
		enemy.position = pos
		enemy.target = target
		enemy.defeated.connect(_on_enemy_defeated)
		add_child(enemy)
		alive += 1
	wave_started.emit(current_wave, count)
''',
            '''## Démarre la vague suivante : incrémente current_wave, puis instancie
## enemies_for_wave(current_wave) ennemis depuis enemy_scene, un par position de
## spawn_positions(), dans cet ordre. Chaque ennemi reçoit `target`, voit son signal
## defeated relié à _on_enemy_defeated et devient enfant du spawner. `alive` vaut ensuite
## le nombre d'ennemis de la vague. Émet enfin wave_started(current_wave, nombre d'ennemis).
func start_next_wave() -> void:
	pass
''')]},
    ),
    Tache(
        id="k3_001_rayon_detection",
        competence="K3",
        consigne=(
            "Un test est rouge : res://tests/test_ghost.gd, test_poursuite_au_rayon_exact. Le verdict des tests "
            "est dans journal_tests.json. Corriger le bug avec le patch le plus petit possible, sans modifier "
            "les tests ; tous les tests doivent passer."
        ),
        remplacements={"scripts/ghost.gd": [(
            "return global_position.distance_to(target.global_position) <= detection_radius",
            "return global_position.distance_to(target.global_position) < detection_radius",
        )]},
        juge={"patch_max_lignes": 6},
        journal_tests=True,
    ),
    Tache(
        id="k3_002_duree_dash",
        competence="K3",
        consigne=(
            "Un test est rouge : res://tests/test_hero.gd, test_iframes_finissent_avec_le_dash. Le verdict des "
            "tests est dans journal_tests.json. Corriger le bug avec le patch le plus petit possible, sans "
            "modifier les tests ; tous les tests doivent passer."
        ),
        remplacements={"scripts/hero.gd": [(
            "\t_dash_time_left = dash_duration\n\t_cooldown_left = dash_cooldown\n",
            "\t_dash_time_left = dash_cooldown\n\t_cooldown_left = dash_duration\n",
        )]},
        juge={"patch_max_lignes": 6},
        journal_tests=True,
    ),
    Tache(
        id="s1_001_heart_pickup",
        competence="S1",
        consigne=(
            "Créer la scène res://scenes/heart_pickup.tscn, un cœur que le héros ramasse. Règles : la racine est "
            "un Area2D nommé HeartPickup qui porte le script res://scripts/heart_pickup.gd (déjà écrit) ; "
            "le cœur rend 2 points de vie ; il a un enfant CollisionShape2D dont la forme est un cercle de "
            "rayon 5. Ne pas modifier les scripts."
        ),
        ajouts_depart={"scripts/heart_pickup.gd": HEART_PICKUP_GD},
        ajouts_reference={"scenes/heart_pickup.tscn": HEART_PICKUP_TSCN},
        tests_specifiques={"test_s1_heart_pickup.gd": TEST_S1_HEART},
    ),
    Tache(
        id="s1_002_spike_trap",
        competence="S1",
        consigne=(
            "Créer la scène res://scenes/spike_trap.tscn, un piège à pointes. Règles : la racine est un Area2D "
            "nommé SpikeTrap qui porte le script res://scripts/spike_trap.gd (déjà écrit) ; le piège inflige "
            "2 dégâts ; il a un enfant CollisionShape2D dont la forme est un rectangle de 16 × 16 ; il a un "
            "enfant Timer nommé Cooldown, à un seul coup, de 1,5 seconde, qui ne démarre pas tout seul. "
            "Ne pas modifier les scripts."
        ),
        ajouts_depart={"scripts/spike_trap.gd": SPIKE_TRAP_GD},
        ajouts_reference={"scenes/spike_trap.tscn": SPIKE_TRAP_TSCN},
        tests_specifiques={"test_s1_spike_trap.gd": TEST_S1_SPIKE},
    ),
    Tache(
        id="s2_001_mort_du_fantome",
        competence="S2",
        consigne=(
            "Règle : quand le composant de vie d'un fantôme tombe à zéro, le fantôme est vaincu (il émet "
            "defeated puis quitte la scène). La logique existe déjà dans res://scripts/ghost.gd ; il manque le "
            "câblage. Ajouter la connexion dans res://scenes/ghost.tscn, sans modifier les scripts."
        ),
        remplacements={"scenes/ghost.tscn": [(
            '\n[connection signal="died" from="HealthComponent" to="." method="_on_died"]\n', "",
        )]},
        tests_specifiques={"test_s2_connexions.gd": GABARIT_TEST_S2.format(
            scene="res://scenes/ghost.tscn",
            attendues='[["HealthComponent", "died", ".", "_on_died"]]')},
    ),
    Tache(
        id="s2_002_cycle_des_vagues",
        competence="S2",
        consigne=(
            "Règles : (1) le HUD affiche le numéro de la vague dès qu'elle commence ; (2) quand une vague est "
            "terminée, la suivante démarre. Les méthodes existent déjà dans res://scripts/hud.gd et "
            "res://scripts/main.gd ; il manque le câblage. Ajouter les connexions dans res://scenes/main.tscn, "
            "sans modifier les scripts."
        ),
        remplacements={"scenes/main.tscn": [(
            '\n[connection signal="wave_started" from="WaveSpawner" to="Hud" method="_on_wave_started"]\n'
            '[connection signal="wave_cleared" from="WaveSpawner" to="." method="_on_wave_cleared"]\n', "",
        )]},
        tests_specifiques={"test_s2_connexions.gd": GABARIT_TEST_S2.format(
            scene="res://scenes/main.tscn",
            attendues='[["WaveSpawner", "wave_started", "Hud", "_on_wave_started"], '
                      '["WaveSpawner", "wave_cleared", ".", "_on_wave_cleared"]]')},
    ),
    Tache(
        id="d1_001_identifiant_inconnu",
        competence="D1",
        consigne=CONSIGNE_D1,
        remplacements={"scripts/hud.gd": [(
            'wave_label.text = "Vague %d" % number', 'wave_label.text = "Vague %d" % numero',
        )]},
        restaurer=False,
        regression=False,
        juge={"etapes": ["run_tests"]},
        d1={"fichier": "scripts/hud.gd", "repere": '"Vague %d" % numero', "categorie": "parse_error"},
    ),
    Tache(
        id="d1_002_cible_nulle",
        competence="D1",
        consigne=CONSIGNE_D1,
        remplacements={
            "scripts/ghost.gd": [("\tif target == null:\n\t\treturn false\n\treturn global_position.distance_to",
                                  "\treturn global_position.distance_to")],
            "scripts/wave_spawner.gd": [("\t\tenemy.target = target\n", "")],
        },
        restaurer=False,
        regression=False,
        juge={"etapes": ["run_tests"]},
        d1={"fichier": "scripts/ghost.gd", "repere": "return global_position.distance_to(target.global_position)",
            "categorie": "null_instance"},
    ),
]


def _copier_reference(destination: Path) -> None:
    shutil.copytree(REFERENCE, destination, ignore=shutil.ignore_patterns("addons", *IGNORES_COPIE_NOMS))


IGNORES_COPIE_NOMS = (".godot", "reports", "__pycache__", "*.uid")


def _ecrire(chemin: Path, texte: str) -> None:
    chemin.parent.mkdir(parents=True, exist_ok=True)
    chemin.write_text(texte, encoding="utf-8", newline="\n")


def _journal_execution(depart: Path) -> str:
    """Sortie de Godot quand on lance le projet de départ (3 images à pas fixe), chemins anonymisés.

    --fixed-fps rend le nombre de pas physiques indépendant de l'horloge : journal reproductible.
    """
    with tempfile.TemporaryDirectory(prefix="usine_d1_") as tmp:
        projet = preparer_copie(depart, Path(tmp) / "projet")
        juges.importer(projet)
        res = executer([cfg.chemin_godot(), "--headless", "--path", projet, "--fixed-fps", "60", "--quit-after", "3"], delai_s=120)
        texte = sans_ansi(res.sortie).replace(str(projet), "<projet>")
    return texte.replace("\r\n", "\n")


def _journal_tests(depart: Path) -> str:
    with tempfile.TemporaryDirectory(prefix="usine_k3_") as tmp:
        projet = preparer_copie(depart, Path(tmp) / "projet")
        verdict = juges.run_tests(projet, "res://tests")
    verdict.pop("journal", None)
    verdict.pop("duree_s", None)
    return json.dumps(verdict, ensure_ascii=False, indent=1) + "\n"


def construire(t: Tache) -> Path:
    dossier = SORTIE / t.competence / t.id
    depart, reference, caches = dossier / "depart", dossier / "reference", dossier / "tests_caches"
    _copier_reference(depart)
    for rel, regles in t.remplacements.items():
        chemin = depart / rel
        texte = chemin.read_text(encoding="utf-8")
        for avant, apres in regles:
            if texte.count(avant) != 1:
                raise ValueError(f"{t.id} : motif trouvé {texte.count(avant)} fois dans {rel} : {avant!r}")
            texte = texte.replace(avant, apres)
        _ecrire(chemin, texte)
        if t.restaurer:
            _ecrire(reference / rel, (REFERENCE / rel).read_text(encoding="utf-8"))
    for rel, texte in t.ajouts_depart.items():
        _ecrire(depart / rel, texte)
    for rel, texte in t.ajouts_reference.items():
        _ecrire(reference / rel, texte)
    if t.regression:
        shutil.copytree(REFERENCE / "tests", caches, dirs_exist_ok=True)
    for rel, texte in t.tests_specifiques.items():
        _ecrire(caches / rel, texte)

    if t.journal_tests:
        _ecrire(depart / "journal_tests.json", _journal_tests(depart))
    if t.d1:
        source = (depart / t.d1["fichier"]).read_text(encoding="utf-8").splitlines()
        lignes = [i + 1 for i, l in enumerate(source) if t.d1["repere"] in l]
        if len(lignes) != 1:
            raise ValueError(f"{t.id} : repère D1 trouvé {len(lignes)} fois")
        fichier = "res://" + t.d1["fichier"]
        journal = _journal_execution(depart)
        if f"{fichier}:{lignes[0]}" not in journal:
            raise ValueError(f"{t.id} : le journal ne mentionne pas {fichier}:{lignes[0]} :\n{journal}")
        _ecrire(depart / "journal.txt", journal)
        reponse = {"categorie": t.d1["categorie"], "fichier": fichier, "ligne": lignes[0]}
        _ecrire(reference / "reponse.json", json.dumps(reponse, ensure_ascii=False) + "\n")
        _ecrire(caches / "test_d1_reponse.gd",
                GABARIT_TEST_D1.format(categorie=reponse["categorie"], fichier=fichier, ligne=lignes[0]))

    tache = {"id": t.id, "competence": t.competence, "consigne": t.consigne, "origine": ORIGINE,
             "empreinte": "", "gelee": False}
    if t.juge:
        tache["juge"] = t.juge
    tache["empreinte"] = calculer_empreinte(dossier, tache)
    _ecrire(dossier / "tache.json", json.dumps(tache, ensure_ascii=False, indent=1) + "\n")
    return dossier


def main() -> int:
    if SORTIE.exists():
        shutil.rmtree(SORTIE)
    for t in TACHES:
        print(construire(t).relative_to(RACINE))
    return 0


if __name__ == "__main__":
    sys.exit(main())
