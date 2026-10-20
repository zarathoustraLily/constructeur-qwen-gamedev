"""Compétence O1 par l'image : rendu hors de l'écran, comparaison d'images, opérateurs de shader, générateur,
portillon et juge sur une vraie étape du cours « bâtiments procéduraux »."""

from __future__ import annotations

import json
import struct
import zlib
from pathlib import Path

import pytest

from usine import config as cfg
from usine.generateurs import observation_visuelle as gen
from usine.generateurs.operateurs import masque_shader, mutants_fichier
from usine.observation import visuel


# --- Mots ----------------------------------------------------------------------------------------------

def _comparaison(part: float, boite: list[int], lum_a: float = 120.0, lum_b: float = 60.0) -> dict:
    return {"part": part, "boite": boite, "largeur": 960, "hauteur": 540, "lum_a": lum_a, "lum_b": lum_b}


def test_la_zone_dit_ou_est_l_ecart():
    assert visuel.zone([10, 10, 200, 100], 960, 540) == "en haut à gauche"
    assert visuel.zone([800, 450, 950, 530], 960, 540) == "en bas à droite"
    assert visuel.zone([400, 200, 560, 340], 960, 540) == "au centre"
    assert visuel.zone([400, 10, 560, 90], 960, 540) == "en haut, au centre"
    assert visuel.zone([0, 0, 959, 539], 960, 540) == "sur presque toute l'image"
    assert visuel.zone([], 960, 540) == "nulle part"


def test_la_description_dit_combien_ou_et_comment():
    assert visuel.decrire(_comparaison(0.0, []), "jour") == "vue « jour » : identique à la référence"
    texte = visuel.decrire(_comparaison(0.16, [300, 50, 620, 460]), "jour")
    assert texte == "vue « jour » : 16 % de l'image diffère de la référence, au centre (zone plus sombre)"
    assert "plus claire" in visuel.decrire(_comparaison(0.02, [0, 0, 100, 100], 60, 120), "nuit")
    assert "2,5 %" in visuel.decrire(_comparaison(0.025, [0, 0, 100, 100], 100, 105), "nuit")
    assert "d'une autre couleur" in visuel.decrire(_comparaison(0.025, [0, 0, 100, 100], 100, 105), "nuit")


def test_seuils_identique_et_visible():
    assert visuel.identique({"part": visuel.PART_IDENTIQUE})
    assert not visuel.identique({"part": visuel.PART_IDENTIQUE * 2})
    assert visuel.visible({"part": visuel.PART_VISIBLE})
    assert not visuel.visible({"part": visuel.PART_VISIBLE / 2})


def test_les_erreurs_de_rendu_gardent_la_ligne_at_et_laissent_le_bruit():
    sortie = ("Godot Engine v4.7.2.stable.official\nSHADER ERROR: Unknown identifier in expression: 'colr'.\n"
              "          at: (null) (res://6_assets/Shader/a.gdshader:42)\n"
              "ERROR: Failed to load cached shader, recompiling.\nok\n")
    assert visuel.erreurs_sortie(sortie) == [
        "SHADER ERROR: Unknown identifier in expression: 'colr'.", "at: (null) (res://6_assets/Shader/a.gdshader:42)"]


def test_le_rendu_se_fait_hors_de_l_ecran_en_compatibilite(tmp_path):
    cmd = [str(c) for c in visuel.commande_rendu(Path("godot"), tmp_path, tmp_path / "v.png", ["--night"])]
    assert cmd[cmd.index("--position") + 1] == visuel.POSITION_HORS_ECRAN
    assert cmd[cmd.index("--rendering-method") + 1] == "gl_compatibility"
    assert cmd[cmd.index("--") + 1] == f"--shot={(tmp_path / 'v.png').resolve()}"
    assert cmd[-1] == "--night"


# --- Opérateurs de shader ------------------------------------------------------------------------------

SHADER = """shader_type spatial;
// ALBEDO = vec3(1.0); dans un commentaire
/* un bloc
   ALBEDO = vec3(0.0);
*/
void fragment() {
	vec3 c = mix(base, joint, 1.0 - m);
	float t = smoothstep(0.2, 0.8, UV.y);
	ALBEDO = c.rgb * t;
}
"""


def _par_operateur(texte: str) -> dict[str, list[tuple[int, str | None]]]:
    resultat: dict[str, list[tuple[int, str | None]]] = {}
    for m in mutants_fichier("6_assets/Shader/a.gdshader", texte):
        resultat.setdefault(m.operateur, []).append((m.ligne, m.apres))
    return resultat


def test_le_masque_de_shader_couvre_les_commentaires_sur_plusieurs_lignes():
    code, bloc = masque_shader("x = 1; /* début", False)
    assert code.startswith("x = 1; ") and code.endswith("\x00" * 8) and bloc
    code, bloc = masque_shader("milieu */ y = 2; // fin", True)
    assert code.strip("\x00 ").startswith("y = 2;") and not bloc


def test_les_operateurs_de_shader_compilent_mais_changent_l_image():
    ops = _par_operateur(SHADER)
    assert (7, "\tvec3 c = mix(joint, base, 1.0 - m);") in ops["arguments_echanges"]
    assert (8, "\tfloat t = smoothstep(0.8, 0.2, UV.y);") in ops["arguments_echanges"]
    assert ops["un_moins_retire"] == [(7, "\tvec3 c = mix(base, joint, m);")]
    assert ops["composantes_permutees"] == [(9, "\tALBEDO = c.bgr * t;")]
    assert ops["sortie_retiree"] == [(9, None)]


def test_rien_n_est_mute_dans_les_commentaires():
    lignes = {ligne for liste in _par_operateur(SHADER).values() for ligne, _ in liste}
    assert lignes.isdisjoint({2, 3, 4, 5})


# --- Générateur ----------------------------------------------------------------------------------------

PROJET = {
    "6_assets/Shader/Procedural/a.gdshader": SHADER,
    "6_assets/Mesh/Procedural/DECORS/Building/b.gd": "extends Node3D\n\nfunc f() -> float:\n\treturn 2.0 * 3.0\n",
    "5_data/DECORS/Building/palette.gd": "extends RefCounted\n\nconst PIERRE: Color = Color(0.8, 0.7, 0.5)\n",
    "2_sequence/step_viewer/step_viewer.gd": "extends Node3D\n\nfunc g() -> float:\n\treturn 1.0 + 1.0\n",
    "7_tests/test_b.gd": "extends SceneTree\n\nfunc _init() -> void:\n\tquit(0 if 1 + 1 == 2 else 1)\n",
}


def test_les_candidats_viennent_des_shaders_generateurs_et_palettes():
    fichiers = {m.fichier for m in gen.candidats(PROJET, 100, "0")}
    assert fichiers == {"6_assets/Shader/Procedural/a.gdshader", "6_assets/Mesh/Procedural/DECORS/Building/b.gd",
                        "5_data/DECORS/Building/palette.gd"}
    gd = [m for m in gen.candidats(PROJET, 100, "0") if m.fichier.endswith(".gd")]
    assert {m.operateur for m in gd} <= gen.OPERATEURS_GD_VISUELS


def test_le_tirage_est_reproductible_et_varie_les_operateurs():
    a = gen.candidats(PROJET, 4, "7")
    assert [m.id for m in a] == [m.id for m in gen.candidats(PROJET, 4, "7")]
    assert len({m.operateur for m in a}) == 4


def test_nom_court_d_une_etape():
    assert gen.court("building_proceduraux_parisien_etape_005") == "parisien_005"
    assert gen.court("building_proceduraux_newyorkais_etape_013") == "newyorkais_013"


# --- Portillon -----------------------------------------------------------------------------------------

def _tache_visuelle(dossier: Path, avec_materiel: bool) -> Path:
    from usine.taches import calculer_empreinte
    (dossier / "depart").mkdir(parents=True)
    (dossier / "depart" / "project.godot").write_text("config_version=5\n", encoding="utf-8")
    (dossier / "reference").mkdir()
    m = dossier / "tests_caches" / "observation_visuelle"
    m.mkdir(parents=True)
    if avec_materiel:
        (m / "vues.json").write_text(json.dumps([{"nom": "jour", "args": []}]), encoding="utf-8")
        (m / "jour.png").write_bytes(_png(4, 4, lambda x, y: (0, 0, 0)))
    tache = {"id": "o1v_essai", "competence": "O1", "consigne": "…", "origine": "test", "gelee": False,
             "observation_visuelle": {"vues": [{"nom": "jour", "args": []}]}}
    tache["empreinte"] = calculer_empreinte(dossier, tache)
    (dossier / "tache.json").write_text(json.dumps(tache), encoding="utf-8")
    return dossier


def test_portillon_sans_materiel_d_observation_visuelle(tmp_path):
    from usine.portillon import regles
    d = regles.evaluer(_tache_visuelle(tmp_path / "t", False), regles.Reglages(repetitions=1))
    assert d.raison == "format_invalide" and "observation visuelle" in d.detail


def test_portillon_depart_qui_echoue_avant_l_observation_visuelle(tmp_path, monkeypatch):
    from usine.portillon import regles
    verdict = {"ok": False, "etape": "check_script", "tests": {"total": 0, "passes": 0, "echecs": []},
               "erreurs": [{"message": "erreur d'analyse"}]}
    monkeypatch.setattr(regles, "juger_tache", lambda *a, **k: verdict)
    d = regles.evaluer(_tache_visuelle(tmp_path / "t", True), regles.Reglages(repetitions=1))
    assert d.raison == "depart_hors_observation"


# --- Comparaison d'images par Godot ----------------------------------------------------------------------

def _png(largeur: int, hauteur: int, couleur) -> bytes:
    """Un PNG RVB 8 bits, écrit avec la bibliothèque standard."""
    brut = b"".join(b"\x00" + b"".join(bytes(couleur(x, y)) for x in range(largeur)) for y in range(hauteur))

    def morceau(genre: bytes, donnees: bytes) -> bytes:
        return struct.pack(">I", len(donnees)) + genre + donnees + struct.pack(">I", zlib.crc32(genre + donnees))
    return (b"\x89PNG\r\n\x1a\n" + morceau(b"IHDR", struct.pack(">IIBBBBB", largeur, hauteur, 8, 2, 0, 0, 0))
            + morceau(b"IDAT", zlib.compress(brut)) + morceau(b"IEND", b""))


@pytest.mark.godot
def test_godot_compare_deux_images(tmp_path):
    projet = tmp_path / "p"
    projet.mkdir()
    (projet / "project.godot").write_text("config_version=5\n", encoding="utf-8")
    gris = lambda x, y: (128, 128, 128)
    (tmp_path / "a.png").write_bytes(_png(96, 54, gris))
    (tmp_path / "b.png").write_bytes(_png(96, 54, gris))
    (tmp_path / "c.png").write_bytes(_png(96, 54, lambda x, y: (20, 20, 20) if x < 16 and y < 9 else (128, 128, 128)))
    assert visuel.comparer(tmp_path / "a.png", tmp_path / "b.png", projet)["changes"] == 0
    c = visuel.comparer(tmp_path / "a.png", tmp_path / "c.png", projet)
    assert c["changes"] == 16 * 9 and c["boite"] == [0, 0, 15, 8]
    assert visuel.decrire(c, "jour") == "vue « jour » : 2,8 % de l'image diffère de la référence, en haut à gauche " \
                                        "(zone plus sombre)"


@pytest.mark.godot
def test_godot_refuse_des_images_de_tailles_differentes(tmp_path):
    projet = tmp_path / "p"
    projet.mkdir()
    (projet / "project.godot").write_text("config_version=5\n", encoding="utf-8")
    (tmp_path / "a.png").write_bytes(_png(8, 8, lambda x, y: (0, 0, 0)))
    (tmp_path / "b.png").write_bytes(_png(8, 4, lambda x, y: (0, 0, 0)))
    with pytest.raises(visuel.ErreurComparaison, match="tailles"):
        visuel.comparer(tmp_path / "a.png", tmp_path / "b.png", projet)


# --- Juge sur une vraie étape du cours ---------------------------------------------------------------------

@pytest.mark.godot
def test_une_tache_visuelle_generee_est_jugee_par_l_image(tmp_path):
    from usine.taches import juger_tache
    projets = cfg.RACINE / "donnees" / "cours" / "batiments_proceduraux" / "projets"
    source = projets / "building_proceduraux_parisien_etape_005"
    if not (source / "project.godot").is_file():
        pytest.skip("cours non fabriqué (python -m usine.cours fabriquer batiments_proceduraux)")
    prod = gen.generer(source, tmp_path / "sortie", par_projet=1, essais=6, graine="0")
    assert len(prod.taches) == 1
    dossier = prod.taches[0]
    tache = json.loads((dossier / "tache.json").read_text(encoding="utf-8"))
    assert tache["competence"] == "O1" and tache["juge"]["patch_max_lignes"] == gen.PATCH_MAX_LIGNES
    assert not (dossier / "depart" / "tests_caches").exists()  # règle 3 : le juge hors de portée
    assert (dossier / "tests_caches" / "observation_visuelle" / "jour.png").is_file()
    depart = juger_tache(dossier, "depart")
    assert not depart["ok"] and depart["etape"] == "observation_visuelle"
    assert {e["categorie"] for e in depart["erreurs"]} == {"image"}
    reference = juger_tache(dossier, "reference")
    assert reference["ok"] and reference["etape"] == "observation_visuelle"
