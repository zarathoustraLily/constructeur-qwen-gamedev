from pathlib import Path

import pytest

from usine import config as cfg


def test_config_absente_donne_dictionnaire_vide(tmp_path):
    assert cfg.charger_config(tmp_path / "absent.toml") == {}


def test_valeurs_a_renseigner_ignorees(tmp_path, monkeypatch):
    monkeypatch.setattr(cfg, "DOSSIER_GODOT_BIN", tmp_path / "vide")
    with pytest.raises(cfg.GodotIntrouvable):
        cfg.chemin_godot({"godot": {"console": "A_RENSEIGNER"}})


def test_chemin_configure_prioritaire(tmp_path):
    binaire = tmp_path / "godot_console.exe"
    binaire.write_bytes(b"")
    assert cfg.chemin_godot({"godot": {"console": str(binaire)}}) == binaire


def test_repli_sur_godot_bin(tmp_path, monkeypatch):
    dossier = tmp_path / "godot_bin"
    dossier.mkdir()
    nom = "Godot_v4.7.2-stable_win64_console.exe" if cfg.sys.platform == "win32" else "Godot_v4.7.2-stable_linux.x86_64"
    (dossier / nom).write_bytes(b"")
    monkeypatch.setattr(cfg, "DOSSIER_GODOT_BIN", dossier)
    assert cfg.chemin_godot({"godot": {"console": str(tmp_path / "inexistant.exe")}}) == dossier / nom


def test_dossier_donnees_relatif_a_la_racine():
    assert cfg.dossier_donnees({"chemins": {"donnees": "donnees"}}) == cfg.RACINE / "donnees"
    assert cfg.dossier_donnees({}) == cfg.RACINE / "donnees"


def test_exemple_de_config_lisible():
    config = cfg.charger_config(cfg.RACINE / "config.example.toml")
    assert config["godot"]["version"] == "4.7.2"
    assert Path(cfg.chemin_gdunit4(config)).name == "gdUnit4"
