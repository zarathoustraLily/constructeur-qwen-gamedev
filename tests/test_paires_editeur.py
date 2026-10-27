"""Famille « lire l'éditeur Godot » : lecture de la vérité du plugin, gestes, paires (sans Godot)."""

import pytest

from usine.paires import camera
from usine.paires import editeur
from usine.paires import format as fmt

FENETRE = [1920, 1080]
ZONES = {"scene": {"titre": "Scène", "rect": [13, 103, 335, 453], "visible": True},
         "inspecteur": {"titre": "Inspecteur", "rect": [1573, 103, 335, 965], "visible": True},
         "vue_3d": {"titre": "3D", "rect": [358, 145, 1204, 876], "visible": True}}
ARBRE = [{"rang": k, "texte": t, "chemin": c, "type": ty, "visible": True, "selectionne": c == "Joueur/Pivot"}
         for k, (t, c, ty) in enumerate([("Niveau", ".", "Node3D"), ("Joueur", "Joueur", "Node3D"),
                                         ("Pivot", "Joueur/Pivot", "Node3D"),
                                         ("Camera3D", "Joueur/Pivot/Camera3D", "Camera3D")])]


def _prop(nom, libelle, affiche, valeur, groupe=""):
    return {"propriete": nom, "libelle": libelle, "affiche": affiche, "valeur": valeur, "groupe": groupe,
            "entiere": True}


def test_chaque_defaut_a_ses_reglages():
    n = camera.niveau(2)
    for d in camera.DEFAUTS:
        assert editeur.reglages(d.nom, n), d.nom


def test_places_et_arbre():
    assert editeur.place(ZONES["scene"]["rect"], FENETRE) == "en haut à gauche"
    assert editeur.place(ZONES["inspecteur"]["rect"], FENETRE) == "à droite"
    assert editeur.place(ZONES["vue_3d"]["rect"], FENETRE) == "au centre"
    d = {"arbre": ARBRE}
    assert editeur.dans_l_arbre(d, "Joueur/Pivot/Camera3D") == "`Camera3D` (4e ligne de l'arbre, sous Niveau > Joueur > Pivot)"


def test_gestes_dans_l_inspecteur():
    masque = _prop("cull_mask", "Cull Mask", [], "1048574")
    assert editeur.affiche(masque) == "couche 1 décochée"
    assert editeur.changer(masque, dict(masque, valeur="1048575")) == \
        "cocher la couche 1 de Cull Mask (couches 1 à 20 cochées)"
    visible = _prop("visible", "Visible", ["non coché"], "false", "Visibility")
    assert editeur.changer(visible, dict(visible, affiche=["coché"], valeur="true")) == "cocher Visibility > Visible"
    rotation = _prop("rotation", "Rotation", ["x 0.0°", "y 0.0°", "z 0.0°"], "Vector3(0, 0, 0)", "Transform")
    saine = dict(rotation, affiche=["x -50.0°", "y 0.0°", "z 0.0°"])
    assert editeur.changer(rotation, saine) == "mettre Transform > Rotation à x -50.0° y 0.0° z 0.0°"


def test_la_paire_de_debogage_montre_l_image_et_la_faute_seulement_a_remplacer(tmp_path):
    n = camera.niveau(2)
    sain = camera.scene(n)
    defaut = next(d for d in camera.DEFAUTS if d.nom == "inclinaison_absente")
    correct, faux = defaut.editer(n, sain)
    rendu = {"camera": {"position": [0, 15.32, 12.86], "regarde_vers": [0, 0, -1]}, "objets": [{"nom": "Corps"}] * 5}
    rendu_sain = {"camera": {"regarde_vers": [0, -0.77, -0.64]}, "objets": [{"nom": "Corps"}] * 5}
    c = camera.Cas(n, defaut, sain, sain.replace(correct, faux), {"donnees": rendu_sain}, {"donnees": rendu},
                   (faux, correct))
    rotation = _prop("rotation", "Rotation", ["x 0.0°", "y 0.0°", "z 0.0°"], "Vector3(0, 0, 0)", "Transform")
    position = _prop("position", "Position", ["x 0.0 m", "y 15.32 m", "z 12.86 m"], "Vector3(0, 15.32, 12.86)",
                     "Transform")
    d = {"fenetre": FENETRE, "zones": ZONES, "arbre": ARBRE, "selection": "Joueur/Pivot", "propriete": "rotation",
         "inspecteur": {"proprietes": [rotation]}, "vue_3d": {"noeuds": [
             {"chemin": "Joueur/Modele/Corps", "dans_la_vue": True}]},
         "releves": [dict(position, chemin="Joueur/Pivot/Camera3D")]}
    sains = {("Joueur/Pivot", "rotation"): dict(rotation, affiche=["x -50.0°", "y 0.0°", "z 0.0°"]),
             ("Joueur/Pivot/Camera3D", "position"): dict(position, affiche=["x 0.0 m", "y 0.0 m", "z 20.0 m"])}
    image = tmp_path / "editeur.png"
    image.write_bytes(b"\x89PNG\r\n\x1a\n" + b"\x00\x00\x00\x0dIHDR" + (1280).to_bytes(4, "big")
                      + (720).to_bytes(4, "big"))
    assert editeur.montre_le_defaut(c, {"donnees": d}, sains)
    p = editeur.paire_debogage(c, {"donnees": d}, str(image), sains)
    demande, reponse = p["messages"][0]["content"], p["messages"][1]["content"]
    assert demande.startswith(fmt.MARQUE_IMAGE) and p["images"] == [str(image)]
    assert "mettre Transform > Rotation à x -50.0° y 0.0° z 0.0°" in reponse
    assert "c'est la caméra de l'éditeur" in reponse
    assert f"remplacer :\n```\n{faux}\n```\npar :\n```\n{correct}\n```" in reponse
    assert faux not in reponse[:reponse.index("remplacer :")]  # règle 7.3
    assert p["jetons"] == fmt.jetons(p["messages"]) + 880  # 1 280 × 720 : 40 × 22 jetons d'image


@pytest.mark.parametrize("largeur, hauteur, attendu", [(640, 360, 220), (1280, 720, 880), (1920, 1080, 2040)])
def test_jetons_d_une_image(largeur, hauteur, attendu):
    assert fmt.jetons_image(largeur, hauteur) == attendu
