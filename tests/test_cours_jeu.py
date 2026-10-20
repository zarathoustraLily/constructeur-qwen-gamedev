"""Cours « de jeu » (usine/cours/jeu.py) : balises, ressources de proche en proche, refus d'une étape incohérente,
paramètres de matériau orphelins ; les étapes prêtes du kart passent le juge des règles."""

from __future__ import annotations

from pathlib import Path

import pytest

from usine import config as cfg
from usine.cours import dossier_cours
from usine.cours.jeu import ErreurEtape, fabriquer, lire_manifeste, rendre
from usine.cours.verifier import parametres_orphelins
from usine.regles import verifier_regles

MAITRE = """extends Node
#@ 2+
const ICONE := preload("res://icone.png")
#@ 3
const SCENE := "res://scene_absente.tscn"
#@ all
"""


def _cours(tmp_path: Path, maitre: str = MAITRE, autres: dict[str, str] | None = None) -> tuple[Path, Path, dict]:
    """Un cours minuscule (un maître, trois étapes) et son jeu source (une image importée)."""
    cours, source = tmp_path / "cours", tmp_path / "source"
    (cours / "maitres").mkdir(parents=True)
    (cours / "maitres" / "main.gd").write_text(maitre, encoding="utf-8")
    fichiers = {"main.gd": "1+"}
    for rel, (texte, spec) in (autres or {}).items():
        (cours / "maitres" / rel).parent.mkdir(parents=True, exist_ok=True)
        (cours / "maitres" / rel).write_text(texte, encoding="utf-8")
        fichiers[rel] = spec
    source.mkdir()
    (source / "project.godot").write_text("config_version=5\n", encoding="utf-8")
    (source / "icone.png").write_bytes(b"\x89PNG\r\n\x1a\n")
    (source / "icone.png.import").write_text('[remap]\n\nuid="uid://abc123"\n', encoding="utf-8")
    manifeste = {"GENRE": "jeu", "PREFIXE": "essai", "SOURCE": "essai", "DERNIERE": 3,
                 "ETAPES": [{"titre": f"Étape {n}", "piste": "Gameplay"} for n in (1, 2, 3)], "FICHIERS": fichiers}
    return cours, source, manifeste


def test_les_balises_gardent_les_lignes_de_leur_plage():
    assert "ICONE" not in rendre(MAITRE, 1, 1, 3)
    assert "ICONE" in rendre(MAITRE, 2, 1, 3) and "SCENE" not in rendre(MAITRE, 2, 1, 3)
    assert "SCENE" in rendre(MAITRE, 3, 1, 3)
    assert "#@" not in rendre(MAITRE, 3, 1, 3)


def test_une_ressource_designee_vient_du_jeu_source_avec_ses_compagnons(tmp_path):
    cours, source, manifeste = _cours(tmp_path)
    r1 = fabriquer(cours, 1, tmp_path / "sortie", manifeste, source)
    assert not (tmp_path / "sortie" / "essai_etape_001" / "icone.png").exists()
    r2 = fabriquer(cours, 2, tmp_path / "sortie", manifeste, source)
    projet = tmp_path / "sortie" / "essai_etape_002"
    assert (projet / "icone.png").is_file() and (projet / "icone.png.import").is_file()
    assert r1["fichiers"][0]["etat"] == "nouveau" and r2["fichiers"][0]["etat"] == "modifié"


def test_un_chemin_introuvable_dans_le_source_est_note(tmp_path):
    cours, source, manifeste = _cours(tmp_path)
    rapport = fabriquer(cours, 3, tmp_path / "sortie", manifeste, source)
    assert rapport["introuvables"] == ["main.gd → scene_absente.tscn"]


def test_designer_un_maitre_absent_a_l_etape_refuse_l_etape(tmp_path):
    maitre = 'extends Node\nconst AUTRE := preload("res://autre.gd")\n'
    cours, source, manifeste = _cours(tmp_path, maitre, {"autre.gd": ("extends Node\n", "3+")})
    with pytest.raises(ErreurEtape, match="autre.gd"):
        fabriquer(cours, 2, tmp_path / "sortie", manifeste, source)
    fabriquer(cours, 3, tmp_path / "sortie", manifeste, source)


def _materiau(projet: Path, parametres: list[str]) -> None:
    (projet / "inc").mkdir(parents=True, exist_ok=True)
    (projet / "inc" / "commun.gdshaderinc").write_text("global uniform vec3 player_position;\n", encoding="utf-8")
    (projet / "herbe.gdshader").write_text(
        'shader_type spatial;\n#include "res://inc/commun.gdshaderinc"\nuniform vec3 color : source_color;\n'
        "uniform highp float push_radius = 2.0;\nvoid vertex() {}\n", encoding="utf-8")
    lignes = "\n".join(f"shader_parameter/{p} = 1.0" for p in parametres)
    (projet / "herbe.tres").write_text(
        '[gd_resource type="ShaderMaterial" format=3]\n\n'
        '[ext_resource type="Shader" path="res://herbe.gdshader" id="1_s"]\n\n'
        f'[resource]\nshader = ExtResource("1_s")\n{lignes}\n', encoding="utf-8")


def test_un_parametre_sans_uniform_est_signale(tmp_path):
    _materiau(tmp_path, ["color", "push_radius", "player_position"])
    assert parametres_orphelins(tmp_path) == []
    _materiau(tmp_path, ["color", "tire_marks_texture_size"])
    assert parametres_orphelins(tmp_path) == ["herbe.tres : tire_marks_texture_size absent de res://herbe.gdshader"]


KART = dossier_cours("kart")


def _source_kart() -> Path:
    try:
        source = cfg.chemin_source(lire_manifeste(KART)["SOURCE"])
    except Exception:  # config.toml absent ou sans [sources]
        source = None
    if source is None or not (Path(source) / "project.godot").is_file():
        pytest.skip("jeu source du kart absent ([sources] de config.toml)")
    return Path(source)


def test_les_etapes_pretes_du_kart_passent_le_juge_et_leurs_materiaux_sont_coherents(tmp_path):
    source = _source_kart()
    manifeste = lire_manifeste(KART)
    for etape in manifeste["PRETES"]:
        rapport = fabriquer(KART, etape, tmp_path, manifeste, source)
        projet = tmp_path / rapport["nom"]
        verdict = verifier_regles(projet)
        assert verdict["ok"], (rapport["nom"], verdict["erreurs"][:5])
        assert parametres_orphelins(projet) == [], rapport["nom"]
