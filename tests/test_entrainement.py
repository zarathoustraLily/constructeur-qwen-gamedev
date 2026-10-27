"""Réglages de LLaMA-Factory (C1) : les règles 7.5 et 7.6, la reprise d'une étape à l'autre, les images."""

from pathlib import Path

from usine.entrainement import reglages


def test_les_trois_etapes_suivent_les_regles():
    for etape, cutoff in ((1, 1024), (2, 2048), (3, 32768)):
        r = reglages.reglages(etape, Path("D:/jeu"), "palier", Path("D:/lora"))
        assert r["cutoff_len"] == cutoff and r["enable_thinking"] is False and r["template"] == "qwen3_5"
        assert r["num_train_epochs"] == 1.0 and r["per_device_train_batch_size"] == 1
    r = reglages.reglages(2, Path("D:/jeu"), "palier", Path("D:/lora"), reprise=Path("D:/lora_1"))
    assert r["adapter_name_or_path"] == "D:/lora_1"
    assert r["image_max_pixels"] >= 1280 * 720  # les images de l'éditeur ne sont pas réduites


def test_le_yaml_est_plat_et_relisible(tmp_path):
    chemin = reglages.ecrire(1, tmp_path, "palier_1", tmp_path / "lora")
    lignes = chemin.read_text(encoding="utf-8").splitlines()
    assert "enable_thinking: false" in lignes and "cutoff_len: 1024" in lignes
    assert all(": " in l for l in lignes)


def test_la_duree_suit_le_debit_mesure():
    assert reglages.duree_estimee_h(266 * 3600) == 1.0
