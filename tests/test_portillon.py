"""Portillon sans moteur : fragments, doublons, tirage du gel, manifeste, exclusion."""

from __future__ import annotations

import json
from pathlib import Path

from usine.generateurs.commun import ecrire_tache
from usine.portillon.dedoublonnage import Index, fragments_texte, signature_tache, texte_reponse
from usine.portillon.exclusion import Exclusion
from usine.portillon.gel import geler, lire_manifeste, tirer
from usine.taches import lire_tache

DEPART = {"project.godot": "config_version=5\n", "a.gd": "func f() -> int:\n\treturn 1 + 2\n"}


def _tache(racine: Path, ident: str, competence: str, reponse: str, consigne: str = "Corriger a.gd.") -> Path:
    return ecrire_tache(racine, {"id": ident, "competence": competence, "consigne": consigne, "origine": "test"},
                        DEPART, {"a.gd": reponse}, {"test_a.gd": "extends GdUnitTestSuite\n"})


def test_fragments_normalises():
    assert fragments_texte("Le Héros  court") == fragments_texte("le héros court")
    assert fragments_texte("") == set()
    assert len(fragments_texte("a b c d e f g h")) == 3


def test_reponse_limitee_a_la_zone_changee(tmp_path):
    d = _tache(tmp_path, "k3_a", "K3", "func f() -> int:\n\treturn 1 - 2\n")
    assert texte_reponse(d) == ": return 1 - 2"


def test_doublons_par_reponse_et_par_empreinte(tmp_path):
    a = _tache(tmp_path / "a", "k3_a", "K3", "func f() -> int:\n\treturn 1 - 2\n")
    meme = _tache(tmp_path / "b", "k3_b", "K3", "func f() -> int:\n\treturn 1 - 2\n", "Autre consigne, même réponse.")
    autre = _tache(tmp_path / "c", "k3_c", "K3", "func f() -> int:\n\treturn 7 * 9\n")
    index = Index(0.8)
    index.ajouter(signature_tache(a))
    assert index.doublon(signature_tache(meme)) == ("doublon_fragments", "k3_a")
    assert index.doublon(signature_tache(autre)) is None
    assert index.doublon(signature_tache(a)) == ("doublon_empreinte", "k3_a")
    # Même réponse, autre compétence : pas un doublon de compétence.
    k2 = _tache(tmp_path / "d", "k2_x", "K2", "func f() -> int:\n\treturn 1 - 2\n")
    assert index.doublon(signature_tache(k2)) is None


def test_reponses_qui_ne_different_que_par_des_nombres_ne_sont_pas_des_doublons(tmp_path):
    texte = "@export var speed: float = {}\n@export var dash_speed: float = {}\n"
    a = ecrire_tache(tmp_path / "a", {"id": "f1_a", "competence": "F1", "consigne": "c", "origine": "t"},
                     {"h.gd": texte.format("1.0", "2.0")}, {"h.gd": texte.format("120.0", "640.0")}, {"test_x.gd": ""})
    b = ecrire_tache(tmp_path / "b", {"id": "f1_b", "competence": "F1", "consigne": "c", "origine": "t"},
                     {"h.gd": texte.format("1.0", "2.0")}, {"h.gd": texte.format("180.0", "300.0")}, {"test_x.gd": ""})
    index = Index(0.8)
    index.ajouter(signature_tache(a))
    assert index.doublon(signature_tache(b)) is None


def test_tirage_du_gel_reproductible_et_plafonne():
    dossiers = {"K2": [Path(f"k2_{i:03d}") for i in range(30)], "K3": [Path(f"k3_{i:03d}") for i in range(300)]}
    a = tirer(dossiers, 7, 50, 0.5)
    assert a == tirer({k: list(reversed(v)) for k, v in dossiers.items()}, 7, 50, 0.5)
    assert len(a["K2"]) == 15 and len(a["K3"]) == 50
    assert a != tirer(dossiers, 8, 50, 0.5)


def test_geler_ecrit_le_manifeste_puis_le_reutilise(tmp_path):
    candidats = [_tache(tmp_path / "c", f"k3_{i}", "K3", f"func f() -> int:\n\treturn {i} * {i + 1}\n")
                 for i in range(6)]
    m = geler(tmp_path / "sortie", {"K3": candidats}, graine=1, cible=50, part_max=0.5)
    ids = [t["id"] for t in m["competences"]["K3"]["taches"]]
    assert len(ids) == 3 and m["competences"]["K3"]["complet"] is False
    assert lire_manifeste(tmp_path / "sortie") == m
    for i in ids:
        gelee = lire_tache(tmp_path / "sortie" / "geles" / "K3" / i)
        assert gelee["gelee"] is True
    # Second appel, autre graine : le gel existant est réutilisé tel quel.
    assert geler(tmp_path / "sortie", {"K3": candidats}, graine=2) == m
    texte = (tmp_path / "sortie" / "geles" / "manifeste.json").read_text(encoding="utf-8")
    assert json.loads(texte)["graine"] == 1


def test_exclusion_tache_session_texte(tmp_path):
    candidats = [_tache(tmp_path / "c", f"k3_{i}", "K3",
                        f"func f() -> int:\n\treturn compute_bonus({i}, {i} * 2) + extra_points\n") for i in range(2)]
    m = geler(tmp_path / "s", {"K3": candidats}, graine=1, cible=1, part_max=1.0)
    gelee = m["competences"]["K3"]["taches"][0]
    excl = Exclusion(m)
    assert excl.tache_exclue(next(d for d in candidats if d.name == gelee["id"]))
    assert excl.session_exclue({"tache_id": gelee["id"]})
    assert not excl.session_exclue({"tache_id": "autre"})
    n = gelee["id"].split("_")[1]
    doc = f"Exemple : return compute_bonus({n}, {n} * 2) + extra_points dans a.gd"
    assert excl.texte_exclu(doc) == gelee["id"]
    assert excl.texte_exclu("Une page de documentation sur CharacterBody2D.move_and_slide.") is None
    assert not Exclusion(None)
