"""Juge des règles, salissures et tri des sessions (document de laurent, sections 5 et 9)."""

import json
import shutil

import pytest

from usine import config as cfg
from usine.generateurs import salissures
from usine.generateurs.commun import lire_projet
from usine.regles import resume, verifier_regles
from usine.regles.catalogue import MECANIQUES, REGLES, texte
from usine.regles.controles import controler_script
from usine.rft import filtre
from usine.rft.essais import trier
from usine.structure.session import verifier_session
from usine.taches import completer_regles, lire_tache

SOCLE = cfg.RACINE / "godot" / "socle_jeu"


@pytest.fixture(scope="module")
def projet():
    return lire_projet(SOCLE)


def test_catalogue():
    assert set(MECANIQUES) <= set(REGLES)
    assert texte("SIM-08").startswith("SIM-08 : une durée de gameplay s'arrête en pause")


def test_le_socle_passe_a_100(projet):
    v = verifier_regles(SOCLE)
    assert v["applicable"] and v["ok"], v["erreurs"]
    assert resume(v) == {"applicable": True, "violations": 0, "structure_ok": True, "par_regle": {}}


def test_un_projet_sans_plan_n_est_pas_juge():
    v = verifier_regles(cfg.RACINE / "godot" / "reference")
    assert v["ok"] and not v["applicable"]


@pytest.mark.parametrize("ligne, regle", [
    ("\tyield(get_tree(), \"idle_frame\")", "COD-04"),
    ("export var vitesse: float = 0.0", "COD-04"),
    ("var vitesse = 0.0", "COD-02"),
    ("var cibles: Array = []", "COD-02"),
    ("func tirer(direction) -> void:\n\tpass", "COD-02"),
    ("func tirerVite() -> void:\n\tpass", "COD-01"),
    ("const vitesse_max: float = 0.0", "COD-01"),
    ("var hud: Node = get_node(\"/root/Main/Hud\")", "ARC-06"),
    ("var parent: Node = get_node(\"../Level\")", "ARC-06"),
    ("func f() -> void:\n\tget_tree().create_timer(0.5).timeout.connect(f)", "SIM-08"),
    ("func f() -> void:\n\tprocess_physics_priority = 10", "SIM-02"),
    ("func _process(delta: float) -> void:\n\tpass", "SIM-01"),
    ("func f() -> float:\n\treturn randf()", "SIM-09"),
    ("var sprite: Sprite3D", "ARC-03"),
    ("func f() -> bool:\n\treturn Input.is_action_pressed(&\"fire\")", "ARC-04"),
    ("func f() -> float:\n\treturn 4.5", "DAT-01"),
])
def test_chaque_regle_mecanique_est_detectee(ligne, regle):
    erreurs = list(controler_script("res://3_entities/drone/drone.gd", "extends Node\n\n" + ligne + "\n"))
    assert regle in {e["regle"] for e in erreurs}, erreurs
    assert all(e["message"].startswith(e["regle"] + " : ") for e in erreurs)


def test_vue_et_entree_ont_leurs_droits():
    vue = "extends Node\n\nvar sprite: Sprite3D\n\nfunc f() -> float:\n\treturn randf() * 4.5\n"
    assert list(controler_script("res://3_entities/drone/drone_view.gd", vue)) == []
    entree = "extends Node\n\nfunc f() -> bool:\n\treturn Input.is_action_pressed(&\"fire\")\n"
    assert list(controler_script("res://3_entities/player/player_input.gd", entree)) == []


def test_salissures_couvrent_dix_regles_et_les_isolent(projet):
    toutes = list(salissures.candidates(projet))
    regles = {s.regle for s in toutes}
    assert regles == {"COD-04", "COD-02", "COD-01", "DAT-01", "ARC-06", "SIM-08", "SIM-02", "SIM-01", "ORG-01",
                      "DOSSIERS"}
    # Une salissure par règle : le projet sali viole cette règle, et elle seule.
    for regle in sorted(regles):
        s = next(x for x in toutes if x.regle == regle)
        assert salissures.regles_violees(salissures.salir(projet, s)).keys() == {regle}, s.nom


def test_salissure_ne_touche_pas_les_commentaires(projet):
    for s in salissures.candidates(projet):
        for rel, sale in s.fichiers.items():
            avant = [l for l in projet.get(rel, "").splitlines() if l.lstrip().startswith("#")]
            apres = [l for l in sale.splitlines() if l.lstrip().startswith("#")]
            assert avant == apres or rel not in projet, (s.nom, rel)


def test_tache_nettoyer(tmp_path, projet, monkeypatch):
    s = next(x for x in salissures.candidates(projet) if x.regle == "ORG-01")
    monkeypatch.setattr(salissures, "candidates", lambda p: iter([s]))
    prod = salissures.generer(tmp_path)
    assert len(prod.taches) == 1 and not prod.ecartes
    dossier = prod.taches[0]
    tache = lire_tache(dossier)
    assert tache["competence"] == "K4" and tache["juge"] == {"regles_cibles": ["ORG-01"]}
    assert tache["reference_retire"] == s.ajoute
    assert (dossier / "tests_caches" / "3_entities" / "player" / "test_player.gd").is_file()
    # Le départ viole ORG-01 ; la référence composée (départ + reference/ − retirés) est le socle propre.
    assert set(salissures.regles_violees(lire_projet(dossier / "depart"))) == {"ORG-01"}
    compose = tmp_path / "compose"
    shutil.copytree(dossier / "depart", compose)
    shutil.copytree(dossier / "reference", compose, dirs_exist_ok=True)
    for rel in tache["reference_retire"]:
        (compose / rel).unlink()
    assert verifier_regles(compose)["ok"]


def test_regles_cibles_font_echouer_un_verdict_vert(tmp_path, projet):
    s = next(x for x in salissures.candidates(projet) if x.regle == "SIM-08")
    from usine.generateurs.commun import ecrire_projet
    sale = ecrire_projet(salissures.salir(projet, s), tmp_path / "p")
    vert = {"ok": True, "etape": "run_tests", "duree_s": 1.0, "erreurs": [], "tests": {"total": 31, "passes": 31}}
    v = completer_regles(dict(vert), sale, None)
    assert v["ok"] and v["regles"]["par_regle"] == {"SIM-08": 1}
    v = completer_regles(dict(vert, erreurs=[]), sale, ["SIM-08"])
    assert not v["ok"] and v["etape"] == "regles" and v["erreurs"][0]["regle"] == "SIM-08"


# --- session : QA-03, QA-07, QA-08


def _appel(nom, args, i="1"):
    return {"role": "assistant", "content": "", "tool_calls": [{"id": i, "type": "function", "function": {
        "name": nom, "arguments": json.dumps(args)}}]}


def _resultat(i, contenu):
    return {"role": "tool", "tool_call_id": i, "content": contenu}


VERT = '{"ok":true,"etape":"run_tests","tests":{"total":3,"passes":3,"echecs":[]}}'
ROUGE = '{"ok":false,"etape":"run_tests","tests":{"total":3,"passes":2,"echecs":["test_x"]}}'
RAPPORT = {"role": "assistant", "content": "Compte rendu : res://3_entities/player/states/player_shield.gd créé, "
                                           "tests lancés : 3 sur 3 verts."}


def test_session_qa_saine():
    msgs = [_appel("read_file", {"chemin": "res://ORGANISATION.md"}),
            _appel("prepare_action", {"but": "b", "type_action": "etat",
                                      "fichiers": ["3_entities/player/states/player_shield.gd"], "besoins": []}),
            _appel("write_file", {"chemin": "res://3_entities/player/states/player_shield.gd", "contenu": "x"}),
            _appel("run_tests", {}, "7"), _resultat("7", VERT), RAPPORT]
    r = verifier_session(msgs)
    assert r["ok"] and r["regles"] == {} and r["ecritures_non_declarees"] == [] and r["compte_rendu"]


def test_session_qa_violations():
    msgs = [_appel("read_file", {"chemin": "res://ORGANISATION.md"}),
            _appel("prepare_action", {"fichiers": ["3_entities/player/states/player_shield.gd"]}),
            _appel("write_file", {"chemin": "res://3_entities/player/player.gd", "contenu": "x"}),
            _appel("godot-usine_run_tests", {}, "7"), _resultat("7", ROUGE),
            {"role": "assistant", "content": "Les tests sont verts."}]
    r = verifier_session(msgs)
    assert not r["ok"]
    assert r["regles"] == {"QA-03": 1, "QA-07": 1, "QA-08": 1}
    assert r["ecritures_non_declarees"] == ["res://3_entities/player/player.gd"]


def test_qa03_sans_declaration_ne_s_applique_pas():
    r = verifier_session([_appel("read_file", {"chemin": "res://plan.md"}),
                          _appel("write_file", {"chemin": "res://3_entities/player/player.gd", "contenu": "x"})])
    assert r["ecritures_non_declarees"] is None and "QA-03" not in r["regles"]


def test_tri_additionne_projet_et_session():
    verdict = {"ok": True, "regles": {"applicable": True, "violations": 2, "structure_ok": True,
                                      "par_regle": {"DAT-01": 2}}}
    tri = trier(verdict, [_appel("run_tests", {}, "7"), _resultat("7", VERT), RAPPORT], "agent")
    assert tri == {"violations": 2, "structure_ok": True, "session_ok": True, "par_regle": {"DAT-01": 2}}
    tri = trier(verdict, [{"role": "assistant", "content": "fini"}], "agent")
    assert tri["violations"] == 3 and tri["par_regle"] == {"DAT-01": 2, "QA-08": 1} and tri["session_ok"]
    tri = trier(verdict, [RAPPORT], "agent")  # tests annoncés verts sans run_tests : QA-07
    assert not tri["session_ok"] and tri["par_regle"]["QA-07"] == 1
    assert trier({"ok": True}, [], "appel") == {"violations": 0, "structure_ok": True, "session_ok": True,
                                                "par_regle": {}}


def test_filtre_garde_la_plus_propre():
    def l(t, e, ok, lg, v=None, s=None, se=None):
        ligne = {"tache_id": t, "essai": str(e), "ok": str(ok), "longueur": str(lg)}
        for k, x in (("violations", v), ("structure_ok", s), ("session_ok", se)):
            if x is not None:
                ligne[k] = str(x)
        return ligne
    reg = [l("a", 0, True, 100, 3, True, True), l("a", 1, True, 900, 0, True, True), l("a", 2, True, 50, 0, False, True),
           l("b", 0, True, 10, 0, True, False), l("b", 1, False, 5, 0, True, True),
           l("c", 0, True, 70), l("c", 1, True, 60)]  # registre ancien : colonnes absentes
    retenus, a_refaire = filtre.retenir(reg)
    assert [(x["tache_id"], x["essai"]) for x in retenus] == [("a", "1"), ("c", "1")]
    assert a_refaire == ["b"]
