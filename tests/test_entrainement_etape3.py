"""Préparation de l'étape 3 (usine/entrainement/etape3.py) sur une petite racine factice."""

import json

import pytest

from usine.entrainement import etape3


def _racine(tmp_path):
    donnees = tmp_path / "donnees"
    for cours in etape3.COURS:
        livraison = donnees / "cours" / cours / "base" / "livraison"
        livraison.mkdir(parents=True)
        (livraison / f"base_{cours}_sharegpt.jsonl").write_text('{"conversations": []}\n' * 2, encoding="utf-8")
    image = donnees / "paires" / "voir" / "images" / "a.png"
    image.parent.mkdir(parents=True)
    image.write_bytes(b"png")
    entrainement = donnees / "entrainement"
    entrainement.mkdir(parents=True)
    avec = json.dumps({"conversations": [], "images": [image.as_posix()]})
    (entrainement / "palier_1.jsonl").write_text(avec + "\n" + '{"conversations": [1]}\n', encoding="utf-8")
    (entrainement / "palier_2.jsonl").write_text('{"conversations": [2]}\n', encoding="utf-8")
    return tmp_path


def test_le_dossier_contient_tout_avec_des_images_relatives(tmp_path):
    racine = _racine(tmp_path)
    sortie = tmp_path / "etape_3"
    bilan = etape3.preparer(sortie, courtes=3, graine=0, pod="/workspace", racine=racine)
    assert bilan["longues"] == {c: 2 for c in etape3.COURS}
    assert bilan["courtes"] == 3 and bilan["courtes_avec_images"] == 1 and bilan["images"] == 1
    images = [i for l in (sortie / "courtes_etape_3.jsonl").read_text(encoding="utf-8").splitlines()
              for i in json.loads(l).get("images", [])]
    assert images == ["images/voir/images/a.png"]
    assert (sortie / images[0]).read_bytes() == b"png"
    info = json.loads((sortie / "dataset_info.json").read_text(encoding="utf-8"))
    assert list(info) == ["base_kart", "base_roguelike", "base_boss_action_rpg", "courtes_etape_3"]
    assert "images" not in info["base_kart"]["columns"] and info["courtes_etape_3"]["columns"]["images"] == "images"
    yaml = (sortie / "etape_3.yaml").read_text(encoding="utf-8")
    for ligne in ("model_name_or_path: /workspace/qwen38_27b", "dataset_dir: /workspace/etape_3",
                  "cutoff_len: 32768", "adapter_name_or_path: /workspace/lora_etape_2", "template: qwen3_5",
                  "enable_thinking: false", "output_dir: /workspace/lora_etape_3"):
        assert ligne in yaml


def test_le_tirage_est_le_meme_a_graine_egale(tmp_path):
    racine = _racine(tmp_path)
    a = etape3.preparer(tmp_path / "a", courtes=2, graine=5, racine=racine)
    b = etape3.preparer(tmp_path / "b", courtes=2, graine=5, racine=racine)
    assert a == b
    assert (tmp_path / "a" / "courtes_etape_3.jsonl").read_text(encoding="utf-8") == \
           (tmp_path / "b" / "courtes_etape_3.jsonl").read_text(encoding="utf-8")


def test_une_image_hors_des_paires_est_refusee(tmp_path):
    racine = _racine(tmp_path)
    ailleurs = tmp_path / "ailleurs.png"
    ailleurs.write_bytes(b"x")
    (racine / "donnees" / "entrainement" / "palier_2.jsonl").write_text(
        json.dumps({"conversations": [], "images": [ailleurs.as_posix()]}) + "\n", encoding="utf-8")
    with pytest.raises(ValueError):
        etape3.preparer(tmp_path / "s", courtes=3, racine=racine)
