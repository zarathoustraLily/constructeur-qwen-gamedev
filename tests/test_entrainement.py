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


def test_le_releve_de_memoire_se_resume(tmp_path):
    import json

    from usine.entrainement import lancer
    assert lancer.resume_memoire(tmp_path / "absent.jsonl") is None
    f = tmp_path / "memoire.jsonl"
    f.write_text("".join(json.dumps(l) + "\n" for l in (
        {"pas": 1, "pic_occupe_mio": 20000, "pic_reserve_mio": 24000, "libre_en_morceaux_mio": 900, "reessais": 0},
        {"pas": 2, "pic_occupe_mio": 21000, "pic_reserve_mio": 23000, "libre_en_morceaux_mio": 2500, "reessais": 3})),
        encoding="utf-8")
    assert lancer.resume_memoire(f) == {"pas": 2, "max_pic_occupe_mio": 21000, "max_pic_reserve_mio": 24000,
                                        "max_libre_en_morceaux_mio": 2500, "max_reessais": 3}
    assert lancer.python_de("G:/v/Scripts/llamafactory-cli.exe").replace("\\", "/").startswith("G:/v/Scripts/python")
