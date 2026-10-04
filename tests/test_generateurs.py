"""Générateurs sans moteur : masquage, aller-retour (consigne et plan), inverse, invention, difficulté."""

from __future__ import annotations

import json
import random
from pathlib import Path

import pytest

from usine.generateurs import aller_retour, inverse, masquage
from usine.generateurs.commun import SOURCE_REFERENCE, lire_projet
from usine.generateurs.invention import ErreurInvention, construire, materialiser
from usine.generateurs.mutation import tirer_un_par_ligne
from usine.generateurs.operateurs import mutants_projet
from usine.portillon.difficulte import classer, filtrer
from usine.projet.gdscript import lire_script
from usine.scene.spec import scene_read
from usine.taches import lire_tache, verifier_empreinte

DONNEES = Path(__file__).parent / "donnees"
PROJET = lire_projet(SOURCE_REFERENCE)


def test_vider_fonction_garde_le_contrat_et_la_signature():
    texte = PROJET["scripts/health_component.gd"]
    vide = masquage.vider_fonction(texte, "take_damage")
    assert "## Retire des points de vie." in vide
    assert "func take_damage(amount: int) -> bool:\n\treturn false\n" in vide
    assert "maxi(current_health - amount" not in vide
    # Les autres fonctions sont intactes.
    assert vide.count("func ") == texte.count("func ")
    assert "mini(current_health + amount, max_health)" in vide


def test_corps_vide_selon_le_type_de_retour():
    s = lire_script(PROJET["scripts/ghost.gd"])
    assert masquage.corps_vide(s.fonction("update_state"), s) == "return State.values()[0]"
    assert masquage.corps_vide(s.fonction("compute_velocity"), s) == "return Vector2.ZERO"
    s = lire_script(PROJET["scripts/wave_spawner.gd"])
    assert masquage.corps_vide(s.fonction("spawn_positions"), s) == "return []"
    assert masquage.corps_vide(s.fonction("start_next_wave"), s) == "pass"


def test_squelette_et_interface():
    sq = masquage.squelette(PROJET["scripts/hero.gd"])
    avant, apres = lire_script(PROJET["scripts/hero.gd"]), lire_script(sq)
    assert [f.signature() for f in avant.fonctions] == [f.signature() for f in apres.fonctions]
    assert "move_and_slide" not in sq
    interface = masquage.decrire_interface(PROJET["scripts/hero.gd"], "res://scripts/hero.gd")
    assert "- class_name Hero" in interface
    assert "- signal dashed(direction: Vector2)" in interface
    assert "- func try_dash(direction: Vector2) -> bool" in interface


def test_k2_produit_une_tache_par_fonction(tmp_path):
    prod = masquage.generer_k2(SOURCE_REFERENCE, tmp_path)
    nb = sum(len(lire_script(PROJET[r]).fonctions) for r in PROJET if r.startswith("scripts/"))
    assert len(prod.taches) == nb
    d = next(t for t in prod.taches if t.name == "k2_reference_health_component_take_damage")
    assert verifier_empreinte(d)
    t = lire_tache(d)
    assert t["competence"] == "K2" and t["consigne_a_ecrire"] is None
    assert (d / "reference" / "scripts" / "health_component.gd").read_text(encoding="utf-8") == \
        PROJET["scripts/health_component.gd"]
    assert (d / "tests_caches" / "test_health_component.gd").is_file()
    assert not (d / "depart" / "tests_juge").exists()


def test_consigne_s1_et_plan_tires_de_la_spec():
    spec = scene_read(PROJET["scenes/coin.tscn"], "res://scenes/coin.tscn")
    consigne = aller_retour.decrire_spec(spec)
    assert "- . : Coin, Area2D, script res://scripts/coin_pickup.gd" in consigne
    assert "shape = la ressource interne « CollisionShape2D:shape »" in consigne
    assert "« CollisionShape2D:shape » : CircleShape2D ; radius = 6.0" in consigne
    assert "- signal body_entered du nœud . → méthode _on_body_entered du nœud ." in consigne
    plan = aller_retour.plan_spec(spec)
    assert plan == {"noeuds": {".": {}, "CollisionShape2D": {"shape": {"radius": None}}}}


def test_inverse_tirage_reproductible_et_application():
    a = [inverse.tirer(random.Random("x")) for _ in range(3)]
    b = [inverse.tirer(random.Random("x")) for _ in range(3)]
    assert a == b
    for nom, v in a[0].items():
        mini, maxi, _, _ = inverse.GRILLE[nom]
        assert mini <= v <= maxi
    texte = inverse.appliquer(PROJET["scripts/hero.gd"], {"speed": 120.0, "dash_duration": 0.07})
    assert "@export var speed: float = 120.0" in texte
    assert "@export var dash_duration: float = 0.07" in texte
    assert "@export var dash_speed: float = 600.0" in texte


def test_mutation_un_mutant_par_ligne_et_par_graine():
    mutants = mutants_projet(PROJET)
    a = tirer_un_par_ligne(mutants, 1)
    assert a == tirer_un_par_ligne(mutants, 1)
    assert len({(m.fichier, m.ligne) for m in a}) == len(a)
    assert {m.id for m in a} != {m.id for m in tirer_un_par_ligne(mutants, 2)}


class _FauxVocab:
    def classe_existe(self, nom: str) -> bool:
        return nom in {"Node", "Node2D", "Area2D", "CharacterBody2D", "CanvasLayer", "Label", "Object"}


def _proposition() -> dict:
    return json.loads((DONNEES / "invention_exemple.json").read_text(encoding="utf-8"))


def test_invention_exemple_fictif_valide(tmp_path):
    dossier = materialiser(_proposition(), tmp_path, vocab=_FauxVocab())
    t = lire_tache(dossier)
    assert t["competence"] == "K3" and t["origine"] == "invention"
    assert t["id"].startswith("k3_inv_reference_exemple_fictif_add_coins_")
    assert "\tcoins = amount\n" in (dossier / "depart" / "scripts" / "game_state.gd").read_text(encoding="utf-8")
    assert (dossier / "tests_caches" / "test_game_state_invente.gd").is_file()
    assert verifier_empreinte(dossier)
    # Id stable : même proposition, même id.
    assert materialiser(_proposition(), tmp_path / "b", vocab=_FauxVocab()).name == dossier.name


@pytest.mark.parametrize("modifier, attendu", [
    (lambda p: p.update(competence="Z9"), "compétence inconnue"),
    (lambda p: p["reference"]["ajouts"].update({"../evasion.gd": "x"}), "chemin refusé"),
    (lambda p: p["depart"]["remplacements"][0].update(avant="absent"), "trouvé 0 fois"),
    (lambda p: p["depart"].update(ajouts={"tests_juge/test_x.gd": "extends GdUnitTestSuite"}), "réservé aux tests cachés"),
    (lambda p: p.update(tests_caches={"aide.gd": "extends Node"}), "au moins une suite"),
    (lambda p: p["reference"]["ajouts"].update({"scripts/x.gd": "extends NoeudInventé\n"}), "classe inconnue"),
    (lambda p: p.update(base="autre"), "base inconnue"),
])
def test_invention_refus(modifier, attendu):
    p = _proposition()
    modifier(p)
    with pytest.raises(ErreurInvention) as e:
        construire(p, vocab=_FauxVocab())
    assert any(attendu in m for m in e.value.erreurs), e.value.erreurs


def test_invention_refuse_un_doublon_gele(tmp_path):
    class Exclusion:
        def tache_exclue(self, dossier):
            return ("doublon_fragments", "k3_gelee")
    with pytest.raises(ErreurInvention) as e:
        materialiser(_proposition(), tmp_path, Exclusion(), vocab=_FauxVocab())
    assert "k3_gelee" in str(e.value)
    assert not any(tmp_path.rglob("tache.json"))


def test_filtre_de_difficulte():
    assert classer([True] * 8) == "trop_facile"
    assert classer([False] * 8) == "trop_difficile"
    assert classer([True] + [False] * 7) == "garder"
    assert classer([True] * 6 + [False] * 2) == "garder"
    assert classer([True] * 7 + [False]) == "trop_facile"
    assert classer([True] * 3) == "essais_incomplets"
    gardes, ecartes = filtrer({"a": [True] * 4 + [False] * 4, "b": [True] * 8})
    assert gardes == ["a"] and ecartes == {"b": "trop_facile"}
