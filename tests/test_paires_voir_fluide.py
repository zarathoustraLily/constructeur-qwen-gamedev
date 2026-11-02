"""La famille « regarder un fluide » : les scènes, les mots qu'on met sur les images et les fenêtres de temps, sans Godot."""

import random

import pytest

from usine.paires import faute_calcul as fc
from usine.paires import voir_fluide as vf


def mesure(instant, pic=1.0, centre=(30.0, 20.0), haut=10, bas=30, gauche=20, droite=40, total=100.0):
    return {"instant": instant, "pic": pic, "centre": list(centre), "haut": haut, "bas": bas, "gauche": gauche, "droite": droite, "total": total,
            "emballe": False}


def scene_fumee(mur=None):
    return vf.Scene("essai", "gaz", "func build() -> FluidSolver:\n\treturn null\n", 1 / 30, 0, 1.0, 64, 36, (30, 30), "une fumée", "aller vers le haut",
                    "12 passes", ("le mur", "haut", 12, -1), vf.FICHIERS["gaz"], mur)


@pytest.mark.parametrize("genre", vf.GENRES)
def test_une_scene_tient_dans_sa_grille_et_ne_cite_que_du_gdscript_type(genre):
    for graine in range(30):
        s = vf.scene(genre, random.Random(graine), "essai")
        assert s.code.startswith("func build() -> ")
        assert ":=" not in s.code
        assert 0 <= s.depart[0] < s.largeur and 0 <= s.depart[1] < s.hauteur
        assert abs(s.largeur / s.hauteur - 16 / 9) < 0.05      # les images sont en 16:9 : une case reste à peu près carrée
        if s.mur:
            assert 0 < s.mur[0] <= s.mur[2] < s.largeur and 0 < s.mur[1] <= s.mur[3] < s.hauteur


def test_une_scene_sans_feu_ne_compte_pas_les_fonctions_du_feu():
    s = vf.panache(random.Random(1), "essai", feu=False)
    assert "burn" in s.mortes
    f = vf.panache(random.Random(1), "essai", feu=True)
    assert "burn" not in f.mortes


def test_les_images_vont_du_premier_pas_a_la_derniere():
    s = scene_fumee()
    assert s.pas()[0] == 0
    assert len(s.pas()) == vf.IMAGES == len(s.instants())
    assert all(max(fenetre) < vf.IMAGES and len(fenetre) == 5 for fenetre in (*vf.FENETRES_LARGES, vf.IMAGES_FAUTE))
    assert all(f[0] == 0 for f in vf.FENETRES_LARGES)       # la création doit voir la scène de départ


def test_un_pic_trop_haut_ne_dit_pas_qu_il_monte_s_il_descend():
    """Le cas relevé à l'œil : le pic sain tombe à 0,1 ; le fautif descend moins vite, de 1,45 à 0,53. Il ne « monte » pas."""
    s = scene_fumee()
    s.genre = "crue"
    sain = [mesure(0.1, 1.45), mesure(2.0, 0.1)]
    fautif = [mesure(0.1, 1.45), mesure(2.0, 0.53)]
    vus = vf.symptomes(s, sain, fautif)
    assert vus and "monte" not in vus[0]
    assert "de 1,45 à 0,53" in vus[0]


def test_un_pic_qui_monte_le_dit():
    s = scene_fumee()
    vus = vf.symptomes(s, [mesure(0.1, 0.3), mesure(2.0, 1.0)], [mesure(0.1, 0.3), mesure(2.0, 16.8)])
    assert any("s'accumule" in v and "de 0,30 à 16,80" in v for v in vus)


def test_des_particules_parlent_de_vitesse_pas_de_matiere():
    s = scene_fumee()
    s.genre = "sph"
    vus = vf.symptomes(s, [mesure(0.1, 6.0), mesure(2.0, 10.0)], [mesure(0.1, 6.0), mesure(2.0, 40.0)])
    assert any("vitesse" in v for v in vus)
    assert not any("s'accumule" in v or "pic" in v for v in vus)


def test_le_sens_inverse_se_voit():
    s = scene_fumee()
    sain = [mesure(0.1, centre=(30, 28)), mesure(2.0, centre=(30, 18))]
    fautif = [mesure(0.1, centre=(30, 28)), mesure(2.0, centre=(30, 34))]
    assert any("va vers le bas, pas vers le haut" in v for v in vf.symptomes(s, sain, fautif))


def test_une_scene_identique_ne_montre_rien():
    s = scene_fumee()
    images = [mesure(0.1), mesure(1.0), mesure(2.0)]
    assert vf.symptomes(s, images, images) == []


def test_un_calcul_emballe_le_dit_a_son_premier_instant():
    s = scene_fumee()
    sain = [mesure(0.1), mesure(0.2), mesure(0.3)]
    fautif = [mesure(0.1), {"instant": 0.2, "emballe": True}, {"instant": 0.3, "emballe": True}]
    assert vf.symptomes(s, sain, fautif) == ["le calcul s'emballe : à 0,20 s, les valeurs n'ont plus de sens"]


def test_passer_a_travers_le_mur_se_voit():
    s = scene_fumee(mur=(20, 12, 40, 13))
    sain = [mesure(0.1, haut=20), mesure(2.0, haut=14)]
    fautif = [mesure(0.1, haut=20), mesure(2.0, haut=4)]
    assert any("passe à travers le mur" in v for v in vf.symptomes(s, sain, fautif))


def test_une_eau_toute_plate_n_a_pas_zero_cases_d_epaisseur():
    s = scene_fumee()
    s.genre = "sph"
    sain = [mesure(0.1), mesure(2.0, haut=4, bas=30, gauche=2, droite=60)]
    fautif = [mesure(0.1), mesure(2.0, haut=18, bas=18, gauche=4, droite=36)]
    assert any("une simple ligne de 32 cases" in v for v in vf.symptomes(s, sain, fautif))


def test_lire_ne_repete_pas_des_colonnes_qui_ne_changent_pas():
    s = scene_fumee()
    s.genre = "sph"
    images = [mesure(0.1, gauche=1, droite=12, centre=(6, 12)), mesure(0.5, gauche=1, droite=12, centre=(7, 14))]
    assert vf.lecture(s, [0, 1], images).startswith("Le liquide reste entre les colonnes 1 et 12. Son centre passe de (6, 12) à (7, 14).")


def test_deux_symptomes_font_une_seule_phrase():
    assert vf._phrase(["la fumée reste ramassée", "La fumée s'éteint"]) == "La fumée reste ramassée ; la fumée s'éteint"


def test_l_extrait_garde_la_signature_et_la_faute_et_marque_les_coupures():
    code = "## Contrat.\nfunc longue(a: int) -> int:\n" + "\n".join(f"\tvar v{i}: int = {i}" for i in range(12)) + "\n\treturn a"
    f = fc.Faute("signe", "a.gd", 8, "\tvar v6: int = 7", "\tvar v6: int = 6", "", "7", "6")
    extrait = vf._extrait(code, f)
    lignes = extrait.split("\n")
    assert lignes[0] == "func longue(a: int) -> int:"
    assert "\tvar v6: int = 6" in lignes
    assert "\tvar v0: int = 0" not in lignes
    assert lignes[1] == lignes[-1] == "\t# [...]"
    assert "## Contrat." not in extrait


def test_l_extrait_renonce_si_la_ligne_n_est_pas_dans_la_fonction():
    f = fc.Faute("signe", "a.gd", 8, "", "\tabsente", "", "", "")
    assert vf._extrait("func f() -> void:\n\tpass", f) is None


def _serie(haut_par_image):
    return [mesure(i * 0.2 + 0.1, haut=h) for i, h in enumerate(haut_par_image)]


def test_trop_tot_propose_une_fenetre_qui_encadre_le_vrai_instant():
    s = scene_fumee()
    # Le bord monte de 2 lignes par image ; il atteint la ligne 12 à la huitième.
    mesures = _serie([26, 24, 22, 20, 18, 16, 14, 12, 10, 8, 6, 4])
    texte = vf.reponse_tempo(s, [0, 1, 2, 3, 4], mesures)
    assert texte.startswith("Non, c'est trop tôt.")
    assert "6 cases" in texte


def test_trop_tot_se_tait_si_le_bord_ne_bouge_plus():
    s = scene_fumee()
    mesures = _serie([20, 20, 20, 20, 20, 20, 12, 12, 12, 12, 12, 12])
    assert vf.reponse_tempo(s, [0, 1, 2, 3, 4], mesures) is None


def test_un_balayage_large_situe_l_instant_entre_deux_images():
    s = scene_fumee()
    mesures = _serie([26, 24, 22, 20, 18, 16, 14, 12, 10, 8, 6, 4])
    texte = vf.reponse_tempo(s, [1, 3, 5, 7, 9], mesures)
    assert texte.startswith("Oui, entre les images 3 et 4")


def test_trop_tard_le_dit():
    s = scene_fumee()
    mesures = _serie([26, 24, 12, 10, 8, 6, 4, 4, 4, 4, 4, 4])
    assert vf.reponse_tempo(s, [4, 5, 6, 7, 8], mesures).startswith("Non, c'est trop tard")


def test_rien_a_chercher_si_c_est_atteint_des_le_debut_ou_jamais():
    s = scene_fumee()
    assert vf.reponse_tempo(s, [0, 1, 2, 3, 4], _serie([4] * 12)) is None
    assert vf.reponse_tempo(s, [0, 1, 2, 3, 4], _serie([30] * 12)) is None


@pytest.mark.parametrize("genre", vf.GENRES)
def test_reconnaitre_nomme_ce_qu_on_voit_et_son_solveur(genre):
    s = vf.scene(genre, random.Random(4), "essai")
    texte = vf.texte_reconnaitre(s, mesure(1.0))
    assert texte.startswith(vf.NATURES[genre])
    assert f"`{vf.CLASSES[genre]}`" in texte
    assert "de la colonne 20 à la colonne 40, et de la ligne 10 à la ligne 30" in texte


def test_reconnaitre_cite_ce_qui_ne_bouge_pas():
    s = scene_fumee(mur=(20, 12, 40, 13))
    s.repere = "Le trait gris est un mur."
    assert "Le trait gris est un mur." in vf.texte_reconnaitre(s, mesure(1.0))


def test_deux_instants_sont_assez_loin_et_dans_la_scene():
    rng = random.Random(1)
    for _ in range(200):
        a, b = vf._deux_instants(rng)
        assert 0 <= a and b < vf.IMAGES and b - a >= vf.ECART_DEUX


def test_chaque_palier_a_son_plafond():
    assert vf.tient({"jetons": 2040, "preuve": {"palier": 2}})
    assert not vf.tient({"jetons": 2041, "preuve": {"palier": 2}})
    assert vf.tient({"jetons": 1024, "preuve": {"palier": 1}})
    assert not vf.tient({"jetons": 1025, "preuve": {"palier": 1}})


def test_un_nan_devient_un_calcul_emballe(tmp_path, monkeypatch):
    import json
    from types import SimpleNamespace

    from usine.cours.base import godot

    def faux(_chemin, _res, _delai, options):
        reponse = [{"nom": "a", "mesures": [{"instant": 0.1, "total": 1.0, "pic": 1.0, "centre": [None, 2.0]}, mesure(0.2)]}, {}]
        with open(options[2], "w", encoding="utf-8") as f:
            f.write(json.dumps(reponse))
        return SimpleNamespace(commande="godot", code=0, texte="")

    monkeypatch.setattr(godot, "tester", faux)
    verite, _ = vf.jouer(SimpleNamespace(chemin="."), [scene_fumee()], tmp_path)
    assert list(verite) == ["a"]        # un résultat vide, sans nom, ne donne rien
    assert verite["a"]["mesures"][0]["emballe"] is True
    assert verite["a"]["mesures"][1]["emballe"] is False


def test_une_faute_sans_images_est_ecartee_sans_tout_arreter(tmp_path, monkeypatch):
    from types import SimpleNamespace

    s = scene_fumee()
    saines = [mesure(0.1 * i) for i in range(vf.IMAGES)]
    vides = [mesure(0.1 * i, pic=0.0, total=0.0) for i in range(vf.IMAGES)]
    monkeypatch.setattr(vf, "jouer", lambda _projet, _scenes, _dossier: ({s.nom: {"nom": s.nom, "mesures": vides}}, None))
    projet = SimpleNamespace(remettre=lambda: None, ecrire=lambda _rel, _texte: None)
    faute = SimpleNamespace(fichier="1_core/fluid/fluid_field.gd", texte="")
    paires, raison = vf.essayer_faute(projet, s, faute, saines, tmp_path, tmp_path, 1)
    assert paires == []
    assert "images" in raison
