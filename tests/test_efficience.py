"""Compétence E (optimisation stricte) : gabarits, rendu intact, juge d'efficience, raisons de rejet."""

from __future__ import annotations

import random
import re
import shutil
from pathlib import Path

import pytest

from usine.efficience import juge as juge_e
from usine.efficience import mesure, rendu_intact
from usine.generateurs import efficience as gen
from usine.portillon.regles import RAISONS, raison_efficience
from usine.taches import calculer_empreinte, juger_tache, lire_tache


# ------------------------------------------------------------------ sans moteur

def test_gabarit_tabulations_et_blocs():
    code = gen.gd('''
        func f() -> void:
            if x:
                {bloc}
            pass
        '''.replace("{bloc}", gen.bloc("a = 1\nif b:\n    c = 2")))
    assert code == "func f() -> void:\n\tif x:\n\t\ta = 1\n\t\tif b:\n\t\t\tc = 2\n\tpass\n"


def test_renommer_respecte_chaines_commentaires_et_membres():
    code = 'var texture := 1 # texture\ne.texture = texture\nprint("texture")\n'
    assert gen.renommer(code, {"texture": "peau"}) == 'var peau := 1 # texture\ne.texture = peau\nprint("texture")\n'


def test_plan_reproductible_et_reparti():
    p = gen.plan(1, 120)
    assert p == gen.plan(1, 120)
    assert len(p) == 120 and len({i for i, _, _ in p}) == 120
    assert {v for _, v, _ in p} == set(gen.VARIANTES)
    assert gen.plan(2, 120) != p


@pytest.mark.parametrize("variante", sorted(gen.VARIANTES))
def test_chaque_variante_donne_une_paire_bien_formee(variante):
    for graine in range(4):
        c = gen.construire(f"e_{variante}_{graine:03d}", variante, graine)
        dep, ref = c.paire.depart["scripts/jeu.gd"], c.paire.reference["scripts/jeu.gd"]
        assert dep != ref
        for code in (dep, ref):
            assert "\x00" not in code and "\x01" not in code
            assert not re.search(r"^ +\S", code, re.M), "indentation en espaces"
            assert "func simuler(" in code and "func etat() -> Dictionary:" in code
        # Mêmes fichiers de rendu dans les deux versions : la référence ne remplace que du code.
        assert set(c.paire.reference) == {"scripts/jeu.gd"}
        assert c.paire.famille in ("allocations", "lots", "temps")
        assert c.paire.temps == (c.paire.famille == "temps")
    # Même graine, même paire (reproductible).
    a, b = gen.construire("e_x_001", variante, 7), gen.construire("e_x_001", variante, 7)
    assert a.paire.depart == b.paire.depart and a.paire.reference == b.paire.reference


def _projet(tmp: Path, paire: gen.Paire, version: str) -> Path:
    return gen.ecrire_projet(gen._fichiers(paire, version), tmp / version)


def test_rendu_intact_statique(tmp_path):
    random.seed(0)
    c = gen.construire("e_tir_001", "tir", 3)
    while not c.paire.decor.lumiere:
        c = gen.construire("e_tir_001", "tir", random.randint(0, 10_000))
    ref = _projet(tmp_path, c.paire, "reference")
    cand = tmp_path / "cand"
    shutil.copytree(ref, cand)
    assert rendu_intact.comparer(ref, cand) == []

    projet = (cand / "project.godot").read_text(encoding="utf-8")
    (cand / "project.godot").write_text(projet.replace("viewport_width=640", "viewport_width=320"), encoding="utf-8")
    ecarts = rendu_intact.comparer(ref, cand)
    assert any("[display] window/size/viewport_width : 640 → 320" in e for e in ecarts)

    shutil.rmtree(cand)
    shutil.copytree(ref, cand)
    scene = (cand / "scenes" / "jeu.tscn").read_text(encoding="utf-8")
    (cand / "scenes" / "jeu.tscn").write_text(re.sub(r"energy = [0-9.]+", "energy = 0.1", scene), encoding="utf-8")
    assert any("Lumiere.energy" in e for e in rendu_intact.comparer(ref, cand))

    debut = scene.index('[node name="Lumiere"')
    fin = scene.find("[node", debut + 1)
    (cand / "scenes" / "jeu.tscn").write_text(scene[:debut] + (scene[fin:] if fin > 0 else ""), encoding="utf-8")
    assert any("Lumiere (PointLight2D) retiré" in e for e in rendu_intact.comparer(ref, cand))


def test_comparer_rendu():
    sig = lambda h, r: {"rendu": [{"image": 180, "elements": {"hachage": h, "nombre": 2, "resume": r}}]}
    assert juge_e.comparer_rendu(sig("a", {"quad:x": 1}), sig("a", {"quad:x": 1})) == []
    ecarts = juge_e.comparer_rendu(sig("a", {"quad:x": 2}), sig("b", {"quad:x": 1}))
    assert ecarts and "quad:x 2→1" in ecarts[0]


def test_raisons_efficience():
    for r in ("efficience_draw_calls", "efficience_allocations", "efficience_temps", "rendu_degrade"):
        assert r in RAISONS
        v = {"ok": False, "etape": "mesure_efficience", "erreurs": [{"categorie": r, "message": "x"}]}
        assert raison_efficience(v) == r
    assert raison_efficience({"ok": False, "etape": "run_tests", "erreurs": []}) is None
    assert raison_efficience({"ok": True, "etape": "mesure_efficience", "erreurs": []}) is None


# ------------------------------------------------------------------ avec le moteur

@pytest.fixture(scope="module")
def taches(tmp_path_factory):
    """Trois tâches E générées et vérifiées : allocations (tir), lots (textures), temps (voisins)."""
    sortie = tmp_path_factory.mktemp("taches_e")
    resultat = {}
    for variante, graine in (("tir", 11), ("textures", 12), ("voisins", 13)):
        c = gen.verifier(gen.construire(f"e_{variante}_001", variante, graine))
        assert c.raison is None, (variante, c.raison, c.detail)
        resultat[variante] = gen.ecrire(c, sortie)
    return resultat


def _candidat(tmp: Path, dossier: Path, nom: str) -> Path:
    """Référence composée (départ + superposition), copiée pour être modifiée."""
    cand = tmp / nom
    shutil.copytree(dossier / "depart", cand)
    shutil.copytree(dossier / "reference", cand, dirs_exist_ok=True)
    return cand


@pytest.mark.godot
def test_tache_e_format(taches):
    for dossier in taches.values():
        t = lire_tache(dossier)
        assert t["competence"] == "E" and t["empreinte"] == calculer_empreinte(dossier, t)
        m = t["mesure_efficience"]
        assert m["reference"]["allocations"] == 0
        assert "Optimisation stricte" in t["consigne"] and "rendu" in t["consigne"]
        assert (dossier / "tests_caches" / "test_comportement.gd").is_file()
    assert lire_tache(taches["voisins"])["mesure_efficience"]["temps"] is True


@pytest.mark.godot
def test_reference_acceptee_et_departs_rejetes_pour_la_bonne_raison(taches):
    v = juger_tache(taches["tir"], "reference")
    assert v["ok"] and v["etape"] == "mesure_efficience", v
    assert v["metriques"]["allocations_actives_apres_warmup"] == {"delta_objets": 0, "ok": True}
    assert v["tests"]["passes"] == v["tests"]["total"] == len(gen.POINTS_CONTROLE)

    v = juger_tache(taches["tir"], "depart")
    assert not v["ok"] and raison_efficience(v) == "efficience_allocations", v
    assert v["tests"]["passes"] == v["tests"]["total"], "le départ garde le comportement"

    v = juger_tache(taches["textures"], "depart")
    assert raison_efficience(v) == "efficience_draw_calls", v
    assert v["metriques"]["draw_calls"]["valeur"] > v["metriques"]["draw_calls"]["reference"]

    v = juger_tache(taches["voisins"], "depart")
    assert raison_efficience(v) == "efficience_temps", v
    assert v["metriques"]["temps_cpu_relatif"]["ratio"] > juge_e.PLAFOND_TEMPS


@pytest.mark.godot
def test_rendu_degrade_rejete_meme_si_efficace(taches, tmp_path):
    dossier = taches["tir"]
    # À l'exécution : la couleur des projectiles change, l'efficience reste celle de la référence.
    cand = _candidat(tmp_path, dossier, "couleur")
    jeu = (cand / "scripts" / "jeu.gd").read_text(encoding="utf-8")
    jeu2 = re.sub(r"Color\([0-9., ]+\)\)\)", "Color(0.0, 0.0, 0.0, 1.0)))", jeu, count=1)
    assert jeu2 != jeu
    (cand / "scripts" / "jeu.gd").write_text(jeu2, encoding="utf-8")
    v = juger_tache(dossier, candidat=cand)
    assert raison_efficience(v) == "rendu_degrade", v
    assert v["metriques"]["allocations_actives_apres_warmup"]["ok"]

    # Statique : résolution divisée par deux dans project.godot.
    cand = _candidat(tmp_path, dossier, "resolution")
    p = (cand / "project.godot").read_text(encoding="utf-8")
    (cand / "project.godot").write_text(p.replace("viewport_height=360", "viewport_height=180"), encoding="utf-8")
    v = juger_tache(dossier, candidat=cand)
    assert raison_efficience(v) == "rendu_degrade", v


@pytest.mark.godot
def test_mesure_reproductible(taches, tmp_path):
    """Règle 3/3 : la mesure déterministe donne trois fois le même résultat."""
    dossier = taches["tir"]
    r = mesure.Reglages.depuis_tache(lire_tache(dossier)["mesure_efficience"])
    with mesure.Copie.ouvrir(dossier / "depart", [dossier / "reference"]) as c:
        mesures = [mesure.lancer(c.projet, r, "deterministe") for _ in range(3)]
    assert mesures[0] == mesures[1] == mesures[2]
    assert mesures[0]["allocations"] == 0 and len(mesures[0]["rendu"]) == len(r.images_rendu)
