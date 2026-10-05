"""Projets sources multiples : socle des fichiers binaires, portage GUT, ciblage, plafonds, registre."""

from __future__ import annotations

import shutil
import sys
from pathlib import Path

import pytest

from usine import config as cfg
from usine import socle
from usine.generateurs import masquage
from usine.generateurs.commun import (SOURCE_REFERENCE, echantillon, ecrire_projet, fichiers_testes, identifiants_tests,
                                      lire_projet)
from usine.generateurs.sources import SOURCES, par_nom
from usine.juge.projet import juger_projet, preparer_copie

sys.path.insert(0, str(cfg.RACINE / "outils"))
from porter_gut import porter  # noqa: E402

GODOT = cfg.RACINE / "godot"


@pytest.fixture
def donnees(tmp_path, monkeypatch):
    monkeypatch.setattr(cfg, "dossier_donnees", lambda config=None: tmp_path / "donnees")
    return tmp_path / "donnees"


# --- portage GUT → GdUnit4 -----------------------------------------------------------------------

def test_porter_gut_assertions_et_messages():
    gut = ('extends GutTest\n\n\nfunc test_x() -> void:\n'
           '\tassert_eq(f(1, 2), 3, "somme %d" % [3])\n'
           '\tassert_true(ok)\n'
           '\tassert_almost_eq(v, 2.83, 0.01, "proche")\n'
           '\tassert_gt(a, b)\n'
           '\tassert_between(n,\n\t\t24, 26)\n'
           '\t# assert_eq(commentaire, intact)\n')
    porte = porter(gut)
    assert porte.startswith("extends GdUnitTestSuite\n")
    assert 'assert_that(f(1, 2)).append_failure_message("somme %d" % [3]).is_equal(3)' in porte
    assert "assert_bool(ok).is_true()" in porte
    assert 'assert_float(float(v)).append_failure_message("proche").is_equal_approx(float(2.83), float(0.01))' in porte
    assert "assert_float(float(a)).is_greater(float(b))" in porte
    assert "assert_float(float(n)).is_between(float(24), float(26))" in porte
    assert "# assert_eq(commentaire, intact)" in porte


def test_porter_gut_refuse_ce_qu_il_ne_sait_pas_traduire():
    with pytest.raises(ValueError, match="watch_signals"):
        porter("extends GutTest\nfunc test_x():\n\twatch_signals(h)\n", "t.gd")


# --- socle ---------------------------------------------------------------------------------------

def test_reference_sans_socle_lecture_inchangee():
    assert socle.nom_socle(SOURCE_REFERENCE) is None
    projet = lire_projet(SOURCE_REFERENCE)
    assert socle.MARQUEUR not in projet
    assert all(rel.endswith((".gd", ".tscn", ".godot")) for rel in projet)


def test_socle_d_un_jeu_avec_binaires(donnees):
    source = GODOT / "kenney_racing"
    projet = lire_projet(source)
    nom = projet[socle.MARQUEUR].strip()
    assert nom.startswith("kenney_racing-") and len(nom) == len("kenney_racing-") + 12
    assert not any(rel.endswith((".glb", ".ogg", ".png", ".import")) for rel in projet)
    dossier = socle.chemin(nom)
    assert (dossier / "models" / "track-straight.glb").is_file()
    assert not any(f.suffix in (".gd", ".tscn") for f in dossier.rglob("*"))


def test_copie_de_travail_etend_le_socle_sans_rien_ecraser(donnees, tmp_path):
    projet = lire_projet(GODOT / "kenney_racing")
    projet["models/Textures/colormap.png.import"] = "remplacé par la tâche\n"
    src = ecrire_projet(projet, tmp_path / "src")
    copie = preparer_copie(src, tmp_path / "copie")
    assert (copie / "audio" / "engine.ogg").read_bytes() == (GODOT / "kenney_racing" / "audio" / "engine.ogg").read_bytes()
    assert (copie / "models" / "Textures" / "colormap.png.import").read_text(encoding="utf-8") == "remplacé par la tâche\n"


def test_socle_modifie_refuse(donnees):
    nom = socle.construire(GODOT / "kenney_racing")
    (donnees / "socles" / nom / "audio" / "engine.ogg").write_bytes(b"autre son")
    with pytest.raises(ValueError, match="contenu modifié"):
        socle.chemin(nom)


def test_socle_absent_reconstruit_depuis_godot(donnees):
    nom = socle.nom_socle(GODOT / "kenney_platformer")
    assert not (donnees / "socles" / nom).exists()
    assert socle.chemin(nom).is_dir()


# --- ciblage et plafonds ---------------------------------------------------------------------------

def test_echantillon_reproductible_et_ordonne():
    elements = list(range(100))
    a = echantillon(elements, 10, "cle")
    assert a == echantillon(elements, 10, "cle") and a == sorted(a) and len(a) == 10
    assert echantillon(elements, 10, "autre") != a
    assert echantillon(elements, None, "cle") == elements
    assert echantillon(elements[:5], 10, "cle") == elements[:5]


def test_fichiers_testes_par_classe_scene_et_autoload():
    survivor = fichiers_testes(lire_projet(GODOT / "survivor"))
    assert "scripts/health.gd" in survivor            # class_name Health cité dans les tests
    assert "scenes/main/main.gd" not in survivor      # aucun test ne charge la scène principale
    plateforme = fichiers_testes(lire_projet(GODOT / "kenney_platformer"))
    assert {"scripts/player.gd", "objects/player.tscn", "objects/character.tscn"} <= plateforme  # par la scène
    assert "scripts/audio.gd" in plateforme           # autoload « Audio » cité dans les tests


def test_k2_ciblee_et_plafonnee(tmp_path):
    source = GODOT / "survivor"
    prod = masquage.generer_k2(source, tmp_path, plafond=40, graine=1, ciblee=True)
    assert len(prod.taches) == 40
    noms = identifiants_tests(lire_projet(source))
    for d in prod.taches:
        methode = d.name.rsplit("_", 1)[-1]
        assert any(n in d.name for n in noms) or methode in ("ready", "process") or "_on_" in d.name


def test_registre_des_sources():
    assert [s.nom for s in SOURCES][0] == "reference"
    for s in SOURCES:
        assert (s.chemin / "project.godot").is_file()
        assert any((s.chemin / "tests").glob("test_*.gd"))
        assert (s.chemin / "SOURCE.md").is_file() or s.nom == "reference"
    assert [s.f1 for s in SOURCES] == [True, False, False, False]
    with pytest.raises(ValueError, match="inconnues"):
        par_nom(["inexistant"])


# --- moteur ------------------------------------------------------------------------------------------

@pytest.mark.godot
@pytest.mark.parametrize("nom, total", [("survivor", 128), ("kenney_platformer", 29), ("kenney_racing", 22)])
def test_jeux_sources_verts(nom, total):
    verdict = juger_projet(GODOT / nom)
    assert verdict["ok"], verdict["erreurs"][:3]
    assert verdict["tests"] == {"total": total, "passes": total, "echecs": []}


@pytest.mark.godot
def test_lot_puis_detail_sur_un_script_casse(tmp_path):
    src = tmp_path / "p"
    shutil.copytree(SOURCE_REFERENCE, src, ignore=shutil.ignore_patterns(".godot", "addons"))
    chemin = src / "scripts" / "hud.gd"
    chemin.write_text(chemin.read_text(encoding="utf-8") + "\nfunc casse(:\n", encoding="utf-8")
    verdict = juger_projet(src, etapes=["check_script"])
    assert not verdict["ok"] and verdict["etape"] == "check_script"
    assert any(e["fichier"] == "res://scripts/hud.gd" and e["categorie"] == "parse_error" for e in verdict["erreurs"])


def test_journal_d1_sans_bilan_de_sortie():
    from usine.generateurs.commun import sans_bilan_de_sortie
    journal = ("ERROR: res://scripts/hero.gd:10 - Node not found: \"Corps\".\n"
               "WARNING: 12 ObjectDB instances were leaked at exit (run with `--verbose` for details).\n"
               "   at: cleanup (core/object/object.cpp:2536)\n"
               "ERROR: 6 resources still in use at exit (run with --verbose for details).\n"
               "   at: clear (core/io/resource.cpp:822)\n")
    assert sans_bilan_de_sortie(journal) == "ERROR: res://scripts/hero.gd:10 - Node not found: \"Corps\".\n"


# --- revue de la PR des jeux sources -------------------------------------------------------------

def test_ids_de_fichiers_homonymes_distincts():
    from usine.generateurs.commun import nom_fichier
    projet = lire_projet(GODOT / "survivor")
    assert nom_fichier(projet, "resources/power_up.gd") != nom_fichier(projet, "scenes/pickups/power_up.gd")
    assert nom_fichier(projet, "scripts/health.gd") == "health"


def test_reponse_par_suppression_a_des_fragments(tmp_path):
    from usine.portillon.dedoublonnage import fragments_texte, texte_reponse
    for sous, op in (("depart", ">="), ("reference", ">")):
        (tmp_path / sous).mkdir()
        (tmp_path / sous / "hero.gd").write_text(f"func est_en_dash() -> bool:\n\treturn _dash {op} 0.0\n",
                                                 encoding="utf-8", newline="\n")
    assert fragments_texte(texte_reponse(tmp_path))


def test_modele_importe_est_une_packed_scene():
    from usine.scene.spec import type_par_extension
    assert type_par_extension("res://models/brick.glb") == "PackedScene"


def test_tri_des_chemins_independant_de_la_casse_du_systeme():
    from pathlib import PurePosixPath, PureWindowsPath
    noms = ["assets/a.ogg", "LICENSE", "README.md", "models/Textures/c.png", "models/block.glb"]
    # Sans clé, Windows compare en minuscules : l'ordre (donc l'empreinte) changerait.
    assert sorted(map(PureWindowsPath, noms)) != [PureWindowsPath(n) for n in sorted(map(PurePosixPath, noms))]
    assert ([p.as_posix() for p in sorted(map(PureWindowsPath, noms), key=lambda p: p.parts)]
            == [p.as_posix() for p in sorted(map(PurePosixPath, noms), key=lambda p: p.parts)])


def test_cle_du_cache_change_avec_le_juge(monkeypatch, tmp_path):
    from usine.juge import cache
    (tmp_path / "a.gd").write_text("extends Node\n", encoding="utf-8")
    avant = cache.cle_jugement(tmp_path)
    monkeypatch.setattr(cache, "_VERSION_JUGE", "autre")
    assert cache.cle_jugement(tmp_path) != avant
