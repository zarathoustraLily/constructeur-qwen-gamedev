import json
import shutil

import pytest

from usine import config as cfg
from usine.juge.projet import DOSSIER_TESTS_JUGE
from usine.taches import (calculer_empreinte, juger_tache, lignes_modifiees, lire_tache, lister_taches,
                          verifier_empreinte)

MODELES = cfg.RACINE / "godot" / "taches_modeles"
TACHES = lister_taches(MODELES)


def test_dix_taches_sur_au_moins_cinq_competences():
    assert len(TACHES) == 10
    competences = {lire_tache(t)["competence"] for t in TACHES}
    assert {"K2", "K3", "S1", "S2", "D1"} <= competences


@pytest.mark.parametrize("dossier", TACHES, ids=lambda p: p.name)
def test_format_et_empreinte(dossier):
    tache = lire_tache(dossier)
    assert tache["id"] == dossier.name
    assert tache["competence"] == dossier.parent.name
    assert tache["gelee"] is False
    assert verifier_empreinte(dossier)
    for sous in ("depart", "reference", "tests_caches"):
        assert (dossier / sous).is_dir()
    assert (dossier / "depart" / "project.godot").is_file()


@pytest.mark.parametrize("dossier", TACHES, ids=lambda p: p.name)
def test_tests_caches_hors_de_depart(dossier):
    depart = dossier / "depart"
    assert not (depart / DOSSIER_TESTS_JUGE).exists()
    assert not (depart / "addons").exists()
    contenus_depart = {f.read_bytes() for f in depart.rglob("*") if f.is_file()}
    for cache in (dossier / "tests_caches").glob("test_*.gd"):
        if not (cfg.RACINE / "godot" / "reference" / "tests" / cache.name).is_file():
            # test propre à la tâche : jamais visible par l'agent
            assert cache.read_bytes() not in contenus_depart


def test_empreinte_change_avec_le_contenu(tmp_path):
    copie = tmp_path / "t"
    shutil.copytree(TACHES[0], copie)
    avant = calculer_empreinte(copie)
    (copie / "depart" / "scripts" / "hero.gd").write_text("# modifié\n", encoding="utf-8")
    assert calculer_empreinte(copie) != avant


def test_lignes_modifiees(tmp_path):
    a, b = tmp_path / "a", tmp_path / "b"
    (a / "scripts").mkdir(parents=True)
    (b / "scripts").mkdir(parents=True)
    (a / "scripts" / "x.gd").write_text("un\ndeux\ntrois\n", encoding="utf-8")
    (b / "scripts" / "x.gd").write_text("un\nDEUX\ntrois\n", encoding="utf-8")
    (b / "scripts" / "y.gd").write_text("nouveau\n", encoding="utf-8")
    assert lignes_modifiees(a, b) == 3


def test_plafond_de_patch_k3(tmp_path):
    dossier = MODELES / "K3" / "k3_001_rayon_detection"
    candidat = tmp_path / "candidat"
    shutil.copytree(dossier / "depart", candidat)
    hero = candidat / "scripts" / "ghost.gd"
    hero.write_text(hero.read_text(encoding="utf-8") + "\n" * 3 + "# a\n# b\n# c\n# d\n# e\n", encoding="utf-8")
    verdict = juger_tache(dossier, candidat=candidat)
    assert verdict["ok"] is False
    assert verdict["etape"] == "taille_patch"


def test_reponses_d1_coherentes_avec_le_journal():
    for dossier in (MODELES / "D1").iterdir():
        reponse = json.loads((dossier / "reference" / "reponse.json").read_text(encoding="utf-8"))
        journal = (dossier / "depart" / "journal.txt").read_text(encoding="utf-8")
        assert f"{reponse['fichier']}:{reponse['ligne']}" in journal


@pytest.mark.godot
def test_tache_k3_depart_echoue_reference_passe():
    dossier = MODELES / "K3" / "k3_001_rayon_detection"
    depart = juger_tache(dossier, "depart")
    assert depart["ok"] is False
    assert depart["tests"]["echecs"] == ["test_ghost:test_poursuite_au_rayon_exact"]
    assert juger_tache(dossier, "reference")["ok"] is True
