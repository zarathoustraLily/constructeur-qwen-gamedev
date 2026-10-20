"""Fiches par besoin et déclaration d'action (béquille, points 3, 4 et 5)."""

import pytest

from usine import config as cfg
from usine.fiches import MODELES, charger, extraire_exemple, ids, preparer_action, signature_api
from usine.fiches import _disque, verifier_fichiers
from usine.regles.catalogue import REGLES
from usine.retour.verification import Signatures
from usine.vocab import ouvrir

SOCLE = cfg.RACINE / "godot" / "socle_jeu"
RUBRIQUES = {"id", "genre", "titre", "a_considerer", "ou_travailler", "api", "exemples", "pieges", "voisins", "regles"}


@pytest.fixture(scope="module")
def vocab():
    return ouvrir()


def test_listes_fermees():
    assert set(ids("besoin")) == {"minuterie", "etat", "collision", "son", "effet_visuel", "animation",
                                  "interface", "donnees", "camera", "sauvegarde"}
    assert set(ids("situation")) == {"ennemi_touche", "mort_acteur", "tir", "apparition_ennemis", "fin_de_niveau"}


@pytest.mark.parametrize("fid", sorted(charger()))
def test_fiche_reelle(fid, vocab):
    fiche = charger()[fid]
    assert set(fiche) == RUBRIQUES
    assert all(fiche[r] for r in ("a_considerer", "ou_travailler", "api", "exemples", "pieges"))
    signatures = Signatures(vocab)
    # Règle 6 : chaque nom d'API existe dans extension_api.json.
    assert [n for n in fiche["api"] if signature_api(n, signatures) is None] == []
    assert [v for v in fiche["voisins"] if v not in charger()] == []
    # Chaque fiche rappelle au moins une règle, et seulement des règles du catalogue.
    assert fiche["regles"] and [r for r in fiche["regles"] if r not in REGLES] == []
    # Chaque exemple est extrait d'un vrai fichier du socle (fonction ou nœud présents).
    assert [e for e in fiche["exemples"] if extraire_exemple(e) is None] == []


def test_chaines_des_modeles_existent():
    assert set(MODELES) == {"etat", "ennemi", "arme", "reglage", "interface", "niveau", "effet_visuel"}
    absents = [r for m in MODELES.values() for r in m["chaine"] if _disque(r, None) is None]
    assert absents == []
    assert all(b in charger() for m in MODELES.values() for b in m["besoins"])


def test_preparer_action(vocab):
    texte = preparer_action(SOCLE, "ajouter un bouclier", "etat",
                            ["3_entities/player/states/player_shield.gd", "scripts/Shield.gd"],
                            ["etat", "minuterie", "bouclier"], ["ennemi_touche"], vocab)
    assert "Inconnus (ignorés) : bouclier" in texte
    assert "res://3_entities/player/states/player_dash.gd (dans le projet)" in texte
    assert "player_shield.gd : nouveau ; dans le plan" in texte
    assert "scripts/Shield.gd : nouveau ; hors du plan" in texte
    assert "aucun test déclaré" in texte
    assert "Timer.start(time_sec: float = -1)" in texte
    assert "func physics_update(delta: float) -> void:" in texte  # exemple tiré de player_dash.gd
    assert "SIM-08 : une durée de gameplay s'arrête en pause" in texte  # règle rappelée par la fiche minuterie
    for titre in ("Comportement par états", "Minuterie", charger()["ennemi_touche"]["titre"]):
        assert titre in texte


def test_exemple_pris_dans_le_projet_d_abord(tmp_path, vocab):
    (tmp_path / "1_core" / "components").mkdir(parents=True)
    (tmp_path / "1_core" / "components" / "health_component.gd").write_text(
        "extends Node\n\nfunc _process(delta: float) -> void:\n\tpass  # version du projet\n", encoding="utf-8")
    origine, bloc = extraire_exemple({"fichier": "res://1_core/components/health_component.gd", "fonction": "_process"},
                                     tmp_path)
    assert "(projet)" in origine and "version du projet" in bloc
    # Fichier absent du projet : on retombe sur le socle de l'usine.
    origine, _ = extraire_exemple({"fichier": "res://3_entities/player/states/player_dash.gd"}, tmp_path)
    assert "socle" in origine


def test_decor_procedural_dans_le_plan(tmp_path):
    """Un générateur de décor procédural a sa place dans 6_assets/Mesh/Procedural/ ; ailleurs, 6_assets reste sans code."""
    remarques = verifier_fichiers(["res://6_assets/Mesh/Procedural/DECORS/Building/immeuble.gd",
                                   "res://6_assets/materials/outil.gd"], None, tmp_path)
    assert remarques[0].endswith("dans le plan (la matière)"), remarques
    assert "ce dossier ne contient aucun code" in remarques[1], remarques
