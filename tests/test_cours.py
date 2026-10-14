"""Cours « bâtiments procéduraux » : fabrication des 39 projets d'étape, juge des règles, Godot."""

from __future__ import annotations

from pathlib import Path

import pytest

from usine.cours import dossier_cours
from usine.cours.fabriquer import fabriquer, fabriquer_tout, nom_projet, plage
from usine.regles import verifier_regles

COURS = dossier_cours("batiments_proceduraux")


def _contenu(dossier: Path) -> dict[str, bytes]:
    return {p.relative_to(dossier).as_posix(): p.read_bytes() for p in dossier.rglob("*") if p.is_file()}


def test_plages_des_balises():
    assert plage("all", 2, 13) == (2, 13, True)
    assert plage("4+", 2, 13) == (4, 13, False)
    assert plage("4+ quiet", 2, 13) == (4, 13, True)
    assert plage("1+", 2, 13) == (2, 13, False)
    assert plage("4-6", 1, 13) == (4, 6, False)
    assert plage("7", 1, 13) == (7, 7, False)


def test_trente_neuf_projets_sans_ecart_au_juge_des_regles(tmp_path):
    rapports = fabriquer_tout(COURS, tmp_path)
    assert len(rapports) == 39
    for rapport in rapports:
        projet = tmp_path / rapport["nom"]
        verdict = verifier_regles(projet)
        assert verdict["applicable"], rapport["nom"]
        assert verdict["ok"], (rapport["nom"], verdict["erreurs"][:3])
        # La note de l'étape est le README.md du projet (le plan n'admet pas d'autre fichier à la racine).
        assert (projet / "README.md").is_file()
        assert "gdscript/warnings/untyped_declaration=2" in (projet / "project.godot").read_text(encoding="utf-8")


def test_fabrication_deterministe(tmp_path):
    fabriquer(COURS, "tokyoiste", 13, tmp_path / "a")
    fabriquer(COURS, "tokyoiste", 13, tmp_path / "b")
    assert _contenu(tmp_path / "a") == _contenu(tmp_path / "b")


def test_bandeaux_nouveau_seulement_sur_ce_qui_change(tmp_path):
    rapport = fabriquer(COURS, "parisien", 6, tmp_path)
    racine = tmp_path / rapport["nom"]
    for entree in rapport["fichiers"]:
        if not entree["chemin"].endswith((".gd", ".gdshader", ".gdshaderinc")):
            continue
        texte = (racine / entree["chemin"]).read_text(encoding="utf-8")
        if entree["etat"] in ("inchangé", "nouveau"):
            assert ">>> NOUVEAU" not in texte, entree["chemin"]
    assert any(e["etat"] == "modifié" for e in rapport["fichiers"])


def test_la_visite_recoit_ses_reglages(tmp_path):
    """La scène de visite donne au script ses réglages (5_data) : aucun chiffre dans 2_sequence (DAT-01)."""
    rapport = fabriquer(COURS, "newyorkais", 12, tmp_path)
    scene = (tmp_path / rapport["nom"] / "2_sequence/step_viewer/step_viewer.tscn").read_text(encoding="utf-8")
    assert 'path="res://5_data/visit/visit_settings.tres"' in scene
    assert 'settings = ExtResource("2")' in scene


@pytest.mark.godot
def test_une_etape_par_ville_passe_godot(tmp_path):
    """Import, analyse de chaque script (avertissements en erreurs), test de l'étape : sans rendu."""
    from usine.cours.verifier import verifier_projet
    for ville, etape in (("parisien", 13), ("tokyoiste", 9), ("newyorkais", 10)):
        fabriquer(COURS, ville, etape, tmp_path)
        bilan = verifier_projet(tmp_path / nom_projet(ville, etape), rendu=False)
        assert bilan["ok"], (ville, etape, bilan.get("analyses"), bilan.get("tests"))


def test_le_socle_traite_aussi_les_avertissements_en_erreurs():
    """Règle 5.3 : le socle a le même bloc [debug] que les projets du cours."""
    from usine import config as cfg
    modele = (COURS / "commun" / "project.godot.tpl").read_text(encoding="utf-8")
    bloc = modele[modele.index("[debug]\n"):modele.index("[display]")]
    socle = (cfg.RACINE / "godot" / "socle_jeu" / "project.godot").read_text(encoding="utf-8")
    manquants = [l for l in bloc.splitlines() if l.startswith("gdscript/") and l not in socle.splitlines()]
    assert not manquants, manquants
