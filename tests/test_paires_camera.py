"""Famille de paires « situer la caméra et les objets » : niveaux, défauts, paires (sans Godot, puis un vrai rendu)."""

import pytest

from usine.paires import camera
from usine.scene.texte import lire_document


def test_meme_graine_meme_niveau_et_deux_styles():
    assert camera.scene(camera.niveau(3)) == camera.scene(camera.niveau(3))
    assert camera.niveau(1).style != camera.niveau(2).style


@pytest.mark.parametrize("graine", [1, 2, 3, 4])
def test_chaque_defaut_est_une_edition_unique_et_reversible(graine):
    n = camera.niveau(graine)
    sain = camera.scene(n)
    lire_document(sain)
    for defaut in camera.DEFAUTS:
        if n.style not in defaut.styles:
            continue
        correct, faux = defaut.editer(n, sain)
        assert sain.count(correct) == 1, defaut.nom  # règle 5.7 : un passage unique
        fautif = sain.replace(correct, faux)
        assert fautif != sain, defaut.nom
        lire_document(fautif)
        assert fautif.count(faux) == 1, defaut.nom
        assert fautif.replace(faux, correct) == sain, defaut.nom  # la correction redonne la scène saine
        for nom in defaut.blocs(n):
            assert camera.bloc(fautif, nom).startswith(f'[node name="{nom}"'), (defaut.nom, nom)


def test_la_paire_de_debogage_ne_montre_la_faute_que_comme_texte_a_remplacer():
    n = camera.niveau(1)
    sain = camera.scene(n)
    defaut = next(d for d in camera.DEFAUTS if d.nom == "inclinaison_absente")
    correct, faux = defaut.editer(n, sain)
    donnees = {"image": 10, "scene": camera.SCENE, "caches": [], "lumieres": [], "cameras": [],
               "bornes": {"centre": [0, 5, 0], "taille": [12, 12, 12]},
               "camera": {"chemin": "/root/Niveau/Joueur/Pivot/Camera3D", "position": [0, 0, 20],
                          "regarde_vers": [0, 0, -1], "haut": [0, 1, 0], "projection": "orthographique", "fov": 75,
                          "size": 13, "near": 0.05, "far": 4000, "cull_mask": 1048575},
               "objets": [{"chemin": "/root/Niveau/Joueur/Modele/Corps", "nom": "Corps", "type": "MeshInstance3D",
                           "centre": [0, 0.6, 0], "taille": [0.7, 1.2, 0.7], "dans_le_champ": False,
                           "hors_champ": ["bas"], "distance": 20}]}
    sain_d = dict(donnees, camera=dict(donnees["camera"], regarde_vers=[0, -0.82, -0.57]),
                  objets=[dict(donnees["objets"][0], dans_le_champ=True, hors_champ=[], ecran=[576, 324])])
    c = camera.Cas(n, defaut, sain, sain.replace(correct, faux), {"donnees": sain_d, "erreurs": []},
                   {"donnees": donnees, "erreurs": []}, (faux, correct))
    p = camera.paire_debogage(c)
    reponse = p["messages"][1]["content"]
    assert "(à l'horizontale)" in reponse and "remplacer :" in reponse
    # La faute n'apparaît que comme texte à remplacer, et rien ne la précède (règle 7.3). Ici c'est une absence :
    # l'en-tête du nœud se retrouve aussi dans le texte correct, qui l'étend.
    assert f"remplacer :\n```\n{faux}\n```\npar :\n```\n{correct}\n```" in reponse
    assert faux not in reponse[:reponse.index("remplacer :")]
    assert p["type"] == "débogage" and p["jetons"] <= 1024


@pytest.mark.godot
def test_godot_un_niveau_sain_et_le_bug_reel(tmp_path):
    n = camera.niveau(2)  # vue de dessus orthographique, comme le roguelike
    assert n.style == "dessus"
    sain = camera.scene(n)
    r = camera.rendre(sain, tmp_path)
    assert r["ok"] and camera.niveau_sain(r["donnees"])
    defaut = next(d for d in camera.DEFAUTS if d.nom == "inclinaison_absente")
    correct, faux = defaut.editer(n, sain)
    rf = camera.rendre(sain.replace(correct, faux), tmp_path)
    assert defaut.verifier(rf["donnees"], n)
