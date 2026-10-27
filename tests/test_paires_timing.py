"""Famille « timing : ce qu'on voit contre ce qu'on doit produire » : défauts, lecture de la légende, paires."""

import pytest

from usine.paires import timing as t

LEGENDE = """grille capture_essai.png : 5 cases, 4 par ligne (erreur 0)
case 1 (ligne 1, colonne 1) : image 10, 0.17 s de jeu
    0.18 s Player : idle → dash
case 2 (ligne 1, colonne 2) : image 17, 0.28 s de jeu
case 3 (ligne 1, colonne 3) : image 55, 0.92 s de jeu
    0.40 s Enemy : idle → alert
    0.45 s Player : dash → idle"""


def _evenements(legende):
    return [t.Evenement(float(m.group(1)), m.group(2), m.group(3), m.group(4))
            for l in legende.splitlines() if (m := t.RE_LIGNE.match(l))]


@pytest.mark.parametrize("graine", [1, 2, 3, 4, 5])
def test_chaque_defaut_est_une_edition_unique_et_reversible(graine):
    j = t.jeu(graine)
    sain = t.fichiers(j)
    for d in t.DEFAUTS:
        correct, faux = d.editer(j)
        assert sain[d.fichier].count(correct) == 1, d.nom  # règle 5.7
        fautif = sain[d.fichier].replace(correct, faux)
        assert fautif.count(faux) == 1 and fautif.replace(faux, correct) == sain[d.fichier], d.nom


def test_les_consignes_tombent_juste_en_images():
    for g in range(1, 30):
        j = t.jeu(g)
        assert abs(j.dash_duree * 60 - j.images(j.dash_duree)) < 1e-9
        assert abs(j.sommet * 60 - j.images(j.sommet)) < 1e-9
        assert (j.gravite / 60) * 4 == int((j.gravite / 60) * 4)  # pas de vitesse par image : un quart exact


def test_lecture_d_une_legende():
    j = t.jeu(1)  # dash de 0,25 s : 15 images
    ev = _evenements(LEGENDE)
    dash = t.MECANIQUES["dash"]
    texte, verdict = t.lecture(dash, t.mesurer(dash, ev), j, 55)
    assert verdict == "ecart" and "16 images, soit 0.27 s" in texte and "1 image de trop" in texte
    texte, verdict = t.lecture(dash, t.mesurer(dash, ev[:1]), j, 55)
    assert verdict == "jamais" and "ne se produit jamais" in texte
    texte, verdict = t.lecture(dash, t.mesurer(dash, ev[:1]), j, 20)
    assert verdict == "fenetre" and "trop courte" in texte and "image 26" in texte
    depart = t.MECANIQUES["depart"]
    texte, verdict = t.lecture(depart, t.mesurer(depart, ev), j, 55)
    assert verdict == "conforme" and "1 image, soit 0.02 s" in texte


def test_la_paire_de_debogage_porte_le_plan_et_ne_montre_la_faute_qu_a_remplacer():
    j = t.jeu(1)
    sain = t.fichiers(j)
    d = next(x for x in t.DEFAUTS if x.nom == "dash_reste_flottant")
    correct, faux = d.editer(j)
    fautifs = dict(sain)
    fautifs[d.fichier] = sain[d.fichier].replace(correct, faux)
    ev_sain = _evenements(LEGENDE.replace("0.45 s Player : dash → idle", "0.43 s Player : dash → idle"))
    rf = {"legende": LEGENDE, "images": [10, 17, 55], "evenements": _evenements(LEGENDE)}
    rs = {"legende": "", "images": [10, 17, 55], "evenements": ev_sain}
    p = t.paire_debogage(d, j, rf, rs, fautifs, (faux, correct))
    systeme, demande, reponse = (m["content"] for m in p["messages"])
    assert systeme == t.plan() and systeme.startswith("# EN PERMANENCE")
    assert faux in demande  # le script lu, tel quel
    assert f"remplacer :\n```\n{faux}\n```\npar :\n```\n{correct}\n```" in reponse
    assert faux not in reponse[:reponse.index("remplacer :")]  # règle 7.3
    assert "dash → idle doit arriver à 0.43 s (image 26), 15 images après idle → dash, à 0.18 s (image 11)" in reponse
    assert p["jetons"] <= t.PLAFONDS["débogage"]


@pytest.mark.godot
def test_godot_le_jeu_sain_tient_ses_consignes(tmp_path):
    j = t.jeu(2)
    r = t.jouer(t.ecrire_projet(t.fichiers(j), tmp_path / "jeu"), j)
    assert r["ok"], r["erreurs"]
    for m in t.MECANIQUES.values():
        assert t.mesurer(m, r["evenements"])["images"] == m.attendu(j), m.nom
