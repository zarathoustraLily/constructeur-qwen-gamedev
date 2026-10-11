"""Juge de structure et tri des sessions (béquille, points 2 et 3)."""

import json
import shutil

from usine import config as cfg
from usine.structure import verifier_projet, verifier_session

SOCLE = cfg.RACINE / "godot" / "socle_jeu"


def _copie(tmp_path):
    projet = tmp_path / "socle"
    shutil.copytree(SOCLE, projet, ignore=shutil.ignore_patterns(".godot", "*.uid"))
    return projet


def test_le_socle_est_conforme():
    v = verifier_projet(SOCLE)
    assert v["ok"], v["erreurs"]
    assert v["etape"] == "structure"


def test_un_projet_sans_plan_est_signale():
    v = verifier_projet(cfg.RACINE / "godot" / "reference")
    assert not v["ok"] and "pas de plan numéroté" in v["erreurs"][0]["message"]


def test_violations(tmp_path):
    projet = _copie(tmp_path)
    # Le cœur qui connaît le bus d'événements (0_autoload) : interdit.
    sm = projet / "1_core" / "state_machine" / "state_machine.gd"
    sm.write_text(sm.read_text(encoding="utf-8").replace("\tstate_changed.emit(from, current_name())",
                                                        "\tstate_changed.emit(from, current_name())\n\tEventBus.player_died.emit()"),
                  encoding="utf-8")
    # Un acteur qui charge une scène d'interface : interdit (ils se parlent par EventBus).
    drone = projet / "3_entities" / "enemies" / "drone" / "drone.gd"
    drone.write_text(drone.read_text(encoding="utf-8") + '\nconst HUD := preload("res://4_ui/hud/hud.tscn")\n',
                     encoding="utf-8")
    (projet / "5_data" / "calcul.gd").write_text("extends Node\n", encoding="utf-8")
    (projet / "TirLaser.gd").write_text("extends Node\n", encoding="utf-8")
    (projet / "scripts").mkdir()
    (projet / "scripts" / "boss.gd").write_text("class_name GrosBoss\nextends Node\n", encoding="utf-8")
    messages = [e["message"] for e in verifier_projet(projet)["erreurs"]]
    attendus = [
        "1_core (le cœur) ne doit pas connaître res://0_autoload/event_bus.gd",
        "3_entities (les acteurs) ne doit pas connaître res://4_ui/hud/hud.tscn",
        "script dans 5_data (les réglages) : ce dossier ne contient aucun code",
        "fichier à la racine",
        "dossier « scripts » hors du plan d'organisation",
    ]
    for a in attendus:
        assert any(m.startswith(a) for m in messages), (a, messages)


def _ecrit(chemin, contenu="x"):
    return {"role": "assistant", "content": "", "tool_calls": [{"id": "1", "type": "function", "function": {
        "name": "write_file", "arguments": json.dumps({"chemin": chemin, "contenu": contenu})}}]}


def _lit(chemin):
    return {"role": "assistant", "content": "", "tool_calls": [{"id": "1", "type": "function", "function": {
        "name": "read_file", "arguments": json.dumps({"chemin": chemin})}}]}


def test_session_saine():
    r = verifier_session([_lit("res://ORGANISATION.md"), _ecrit("res://3_entities/player/states/player_dash.gd")])
    assert r["ok"] and r["plan_lu_avant_ecriture"]


def test_session_a_trier():
    r = verifier_session([_ecrit("res://plan.md"), _lit("res://ORGANISATION.md"), _ecrit("res://scripts/laser.gd"),
                          _ecrit("res://scripts/laser.gd")])
    assert not r["ok"]
    assert r["plan_lu_avant_ecriture"] is False
    assert r["ecritures_hors_plan"] == ["res://scripts/laser.gd", "res://scripts/laser.gd"]
    assert r["ecritures_repetees"] == 1
