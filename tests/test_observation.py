"""Compétence O1 (corriger en observant) : règles de partie, description du kart, générateur, portillon, juge."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from usine import config as cfg
from usine.observation import partie

REGLES = partie.lire_config(partie.config_jeu("kart"))["regles"]


def _image(i: int, **champs) -> dict:
    e = {"i": i, "p": [0.0, 1.0, 0.0], "vy": 0.0, "v": 0.0, "vh": 0.0, "appui": "sol", "sol": 1.0, "haut": 0.5,
         "sous": -0.4, "sous_obj": None, "pen": 0.0, "pen_obj": None, "enf_carrosserie": -0.3, "enf_roues": 0.02,
         "cam_champ": True, "cam_sous": -2.0, "cam_al": 1.0}
    e.update(champs)
    return e


def _trace(images: list[dict]) -> dict:
    return {"sequence": "essai", "images": len(images), "enregistrements": images}


def _cassees(images: list[dict]) -> list[str]:
    return partie.cassees(partie.evaluer(_trace(images), REGLES))


# --- Règles --------------------------------------------------------------------------------------------

def test_une_partie_propre_ne_casse_aucune_regle():
    assert _cassees([_image(i) for i in range(11, 200)]) == []


def test_en_l_air_sans_gravite_le_kart_vole():
    vol = [_image(i, appui="air", vy=1.0) for i in range(11, 40)]
    ev = partie.evaluer(_trace(vol), REGLES)
    assert partie.cassees(ev) == ["gravite"]
    assert ev["gravite"]["premiere"] == 13  # dès la troisième image en l'air (11, 12, 13)
    assert "en l'air depuis 3 images" in ev["gravite"]["pire"]["message"]


def test_une_chute_normale_respecte_la_gravite():
    chute = [_image(i, appui="air", vy=-2.0 * 9.81 * (i - 11) / 60) for i in range(11, 40)]
    assert _cassees(chute) == []


def test_trop_haut_au_dessus_de_la_surface():
    assert _cassees([_image(50, haut=REGLES["hauteur_max"] + 0.5)]) == ["hauteur"]


def test_sous_le_sol():
    ev = partie.evaluer(_trace([_image(50, sous=2.0, sous_obj="island.tscn (0, 0, 0)")]), REGLES)
    assert partie.cassees(ev) == ["sous_le_sol"]
    assert "island.tscn" in ev["sous_le_sol"]["pire"]["message"]


def test_traversee_nomme_l_obstacle_et_garde_la_pire_image():
    images = [_image(100, pen=0.4, pen_obj="small_palm.tscn (52.9, 3.2, -44.9)"), _image(101, pen=0.9, pen_obj="small_palm.tscn")]
    ev = partie.evaluer(_trace(images), REGLES)
    assert partie.cassees(ev) == ["traversee"]
    assert ev["traversee"]["fautes"] == 2 and ev["traversee"]["premiere"] == 100
    assert ev["traversee"]["pire"]["image"] == 101 and "0,90 m" in ev["traversee"]["pire"]["message"]


def test_un_contact_leger_n_est_pas_une_traversee():
    assert _cassees([_image(100, pen=REGLES["penetration_max"])]) == []


def test_enfouissement_par_partie_du_corps():
    seuil = REGLES["enfouissement_max"]
    assert _cassees([_image(50, enf_roues=seuil["roues"] + 0.1, enf_roues_obj="WheelMesh")]) == ["enfouissement"]
    assert _cassees([_image(50, enf_carrosserie=seuil["carrosserie"] + 0.1)]) == ["enfouissement"]
    # Sur la mer, pas de sol de référence : pas de mesure.
    assert _cassees([_image(50, enf_roues=None, enf_carrosserie=None)]) == []


def test_camera_hors_champ_apres_le_debut_seulement():
    debut = REGLES["camera_debut"]
    assert _cassees([_image(debut, cam_champ=False)]) == []
    assert _cassees([_image(debut + 1, cam_champ=False)]) == ["camera"]
    assert _cassees([_image(debut + 1, cam_sous=0.5)]) == ["camera"]


def test_camera_a_contresens_seulement_quand_le_kart_roule():
    debut, vitesse = REGLES["camera_alignement_debut"], REGLES["camera_alignement_vitesse"]
    assert _cassees([_image(debut + 1, cam_al=-1.0, vh=vitesse + 1)]) == ["camera_derriere"]
    assert _cassees([_image(debut + 1, cam_al=-1.0, vh=vitesse - 1)]) == []
    assert _cassees([_image(debut - 1, cam_al=-1.0, vh=vitesse + 1)]) == []


def test_le_resume_montre_les_regles_cassees_puis_le_parcours():
    config = partie.lire_config(partie.config_jeu("kart"))
    trace = _trace([_image(i, pen=0.98 if i == 60 else 0.0, pen_obj="rock.tscn") for i in range(11, 121)])
    texte = partie.resume("rocher", trace, partie.evaluer(trace, REGLES), config)
    assert texte.startswith("Séquence « rocher »")
    assert "traversée : 1 images, dès l'image 60" in texte and "rock.tscn" in texte
    assert "Parcours" in texte and "30 : (" in texte


def test_les_marges_relevent_les_extremes():
    m = partie.marges(_trace([_image(11, appui="air"), _image(12, appui="air"), _image(13, pen=0.05, haut=1.7)]))
    assert m["images_en_l_air_max"] == 2 and m["penetration_max"] == 0.05 and m["hauteur_max"] == 1.7


# --- Description du kart -------------------------------------------------------------------------------

def test_la_description_du_kart_est_complete():
    d = partie.lire_config(partie.config_jeu("kart"))
    for nom, seq in d["sequences"].items():
        assert seq["images"] > d["echauffement"], nom
        actions = [a for t in seq.get("tenir", []) for a in t["actions"]] + seq.get("alterner", {}).get("actions", []) \
            + [e["action"] for e in seq.get("evenements", [])]
        assert set(actions) <= set(d["commandes"]), nom
        if "pilote" in seq:
            assert seq["pilote"]["vers"] in d["obstacles"], nom
    for cle in ("gravite_min", "hauteur_max", "sous_le_sol_max", "penetration_max", "enfouissement_max", "camera_debut"):
        assert cle in d["regles"]
    assert {b["nom"] for b in d["bugs_modeles"]} >= {"gravite nulle", "palmier sans collision", "roulis excessif"}


def test_un_jeu_inconnu_est_refuse():
    with pytest.raises(partie.ErreurObservation):
        partie.config_jeu("jeu_qui_n_existe_pas")


# --- Générateur et source ------------------------------------------------------------------------------

def test_un_bug_modele_doit_designer_un_texte_unique():
    from usine.generateurs.observation import candidats
    desc = {"bugs_modeles": [{"nom": "double", "fichier": "a.gd", "avant": "x = 1", "apres": "x = 2"}]}
    with pytest.raises(ValueError, match="une seule fois"):
        candidats({"a.gd": "x = 1\nx = 1\n"}, desc, 0)
    liste = candidats({"a.gd": "y = 0\nx = 1\n"}, desc, 0)
    assert liste[0]["ligne"] == 2 and liste[0]["mute"] == "y = 0\nx = 2\n"


def test_les_mutants_sont_tires_de_facon_reproductible():
    from usine.generateurs.observation import candidats
    texte = "extends Node\n\nvar a := 1.0\nvar b := 2.0\n\nfunc f() -> float:\n\treturn a * b + 3.0\n"
    desc = {"fichiers_bugs": ["s.gd"], "mutants_max": 2}
    premiers = [c["id"] for c in candidats({"s.gd": texte}, desc, 7)]
    assert premiers == [c["id"] for c in candidats({"s.gd": texte}, desc, 7)] and len(premiers) == 2


def test_la_source_kart_ne_donne_que_des_taches_o1():
    from usine.generateurs.sources import par_nom
    kart = par_nom(["kart"])[0]
    assert kart.observation == "kart"
    assert not any(kart.permet(g) for g in ("k2", "k1", "s1", "s2", "mutation"))
    assert par_nom(["reference"])[0].permet("k2")


# --- Portillon -----------------------------------------------------------------------------------------

def _tache_o1(dossier: Path, avec_materiel: bool) -> Path:
    from usine.taches import calculer_empreinte
    (dossier / "depart").mkdir(parents=True)
    (dossier / "depart" / "project.godot").write_text("config_version=5\n", encoding="utf-8")
    (dossier / "reference").mkdir()
    (dossier / "tests_caches" / "observation").mkdir(parents=True)
    if avec_materiel:
        (dossier / "tests_caches" / "observation" / "config.json").write_text("{}", encoding="utf-8")
        (dossier / "tests_caches" / "observation" / "monde_verite.tscn").write_text("[gd_scene format=3]\n", encoding="utf-8")
    tache = {"id": "o1_essai", "competence": "O1", "consigne": "…", "origine": "test", "gelee": False,
             "observation": {"jeu": "kart", "sequences": ["virages"]}}
    tache["empreinte"] = calculer_empreinte(dossier, tache)
    (dossier / "tache.json").write_text(json.dumps(tache), encoding="utf-8")
    return dossier


def test_portillon_sans_materiel_d_observation(tmp_path):
    from usine.portillon import regles
    d = regles.evaluer(_tache_o1(tmp_path / "t", False), regles.Reglages(repetitions=1))
    assert d.raison == "format_invalide" and "observation" in d.detail


def test_portillon_depart_qui_echoue_avant_l_observation(tmp_path, monkeypatch):
    from usine.portillon import regles
    verdict = {"ok": False, "etape": "load_scene", "tests": {"total": 0, "passes": 0, "echecs": []},
               "erreurs": [{"message": "la scène ne se charge pas"}]}
    monkeypatch.setattr(regles, "juger_tache", lambda *a, **k: verdict)
    d = regles.evaluer(_tache_o1(tmp_path / "t", True), regles.Reglages(repetitions=1))
    assert d.raison == "depart_hors_observation"


# --- Juge sur le vrai kart -----------------------------------------------------------------------------

@pytest.mark.godot
def test_une_tache_generee_est_jugee_par_l_observation(tmp_path):
    from usine.generateurs import observation
    from usine.taches import juger_tache
    source = cfg.chemin_source("kart")
    if source is None or not (source / "project.godot").is_file():
        pytest.skip("source kart absente de cette machine ([sources] de config.toml)")
    prod = observation.generer(source, tmp_path / "sortie", "kart", "kart", graine=0, plafond=1)
    assert len(prod.taches) == 1
    dossier = prod.taches[0]
    tache = json.loads((dossier / "tache.json").read_text(encoding="utf-8"))
    assert tache["competence"] == "O1" and tache["bug"]["symptome"] == "le kart vole"
    assert not (dossier / "depart" / "tests_caches").exists()  # règle 3 : le juge hors de portée
    depart = juger_tache(dossier, "depart")
    assert not depart["ok"] and depart["etape"] == "observation"
    assert {e["categorie"] for e in depart["erreurs"]} >= {"partie_gravite"}
    reference = juger_tache(dossier, "reference")
    assert reference["ok"] and reference["etape"] == "observation"
