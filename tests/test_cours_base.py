"""Base « bâtiments procéduraux » : contrôles des exemples, consignes d'édition rejouées, lecture des sorties.

Ces tests ne lancent pas Godot. La génération réelle (Godot, godot-docs, source de Godot, vocabulaire de Qwen) se
vérifie par `python -m usine.cours.base tout` ; voir VERIFIER_EN_LOCAL.md.
"""

from __future__ import annotations

import shutil

import pytest

from usine.cours.base import assembler, composer, debogage, etat, godot, rejouer
from usine.cours.base.creation import bloc_commande, bloc_sortie
from usine.cours.base.godot import Sortie


def _exemple(messages: list[dict], type_: str = "debogage") -> dict:
    return {"id": f"essai-001-{type_}", "type": type_, "ville": "parisien", "etape": 1, "messages": messages,
            "jetons": 100, "preuves": {"ok": True}}


SYSTEME = {"role": "system", "content": "Tu es un développeur Godot."}


def test_une_commande_par_tour_et_sa_sortie_dans_le_tour_suivant():
    s = Sortie("godot --headless --path . --import", "", 0)
    bon = _exemple([SYSTEME, {"role": "user", "content": "Fais l'étape."},
                    {"role": "assistant", "content": "Je code, puis j'importe :\n" + bloc_commande(s.commande)},
                    {"role": "user", "content": bloc_sortie(s)},
                    {"role": "assistant", "content": "L'import est propre. Rien à corriger."}], "creation")
    assert assembler.controler([bon]) == []
    # La sortie qui ne répond pas à la commande demandée.
    faux = _exemple([*bon["messages"][:3], {"role": "user", "content": bloc_sortie(Sortie("godot --autre", "", 0))},
                     bon["messages"][4]], "creation")
    assert any("ne répond pas à la commande" in p for p in assembler.controler([faux]))


def test_une_reponse_n_ecrit_jamais_une_sortie():
    """Règle 7.2 : la sortie d'une commande arrive dans le message suivant, jamais dans la réponse."""
    assert assembler.sortie_ecrite("Je lance :\n```\n$ godot --headless --path . --import\n```") is None
    assert assembler.sortie_ecrite("```\n$ godot -s res://t.gd\nok        1 scène(s)\n```")
    assert assembler.sortie_ecrite("Le test a donné (code de sortie : 0).")
    ex = _exemple([SYSTEME, {"role": "user", "content": "Fais l'étape."},
                   {"role": "assistant", "content": "```\n$ godot -s res://t.gd\nok        12 triangles\n```"}])
    assert any("écrit une sortie de commande" in p for p in assembler.controler([ex]))


def test_la_commande_montree_est_celle_qui_tourne():
    """Arguments compris : un rendu montré sans `--shot` ni `--quit-after` ne s'arrêterait pas chez l'utilisateur."""
    arguments = ["--path", ".", "--rendering-method", "gl_compatibility", "--quit-after", "6000", "--",
                 f"--shot={godot.IMAGE_RENDU}"]
    assert godot.commande(arguments) == ("godot --path . --rendering-method gl_compatibility --quit-after 6000 -- "
                                         "--shot=.godot/rendu.png")


def test_sortie_nettoyee_sans_perdre_les_erreurs(tmp_path):
    """Codes de couleur et progression de l'import retirés ; une erreur garde sa ligne « at: » (règle 5.1)."""
    projet = tmp_path / "p"
    brut = ("Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org\n\n"
            "[   0% ] \x1b[90m\x1b[1mfirst_scan_filesystem\x1b[22m | Started Project initialization (5 steps)\x1b[39m\x1b[0m\n"
            "\x1b[92m[ DONE ]\x1b[39m \x1b[1mfirst_scan_filesystem\x1b[22m\n\x1b[0m\n"
            "SCRIPT ERROR: Parse Error: Identifier \"street\" not declared in the current scope.\n"
            f"          at: GDScript::reload (res://a.gd:3)\ncapture: {projet}/.godot/x.png (960, 540) erreur=0\n")
    assert godot.nettoyer(brut, str(projet)) == (
        "SCRIPT ERROR: Parse Error: Identifier \"street\" not declared in the current scope.\n"
        "          at: GDScript::reload (res://a.gd:3)\ncapture: .godot/x.png (960, 540) erreur=0")


def test_image_du_rendu_lue_dans_la_sortie():
    ok = Sortie("godot …", "capture: .godot/rendu.png (960, 540) erreur=0", 0)
    assert godot.image_enregistree(ok) == (960, 540)
    assert godot.image_enregistree(Sortie("godot …", "capture: .godot/rendu.png (960, 540) erreur=15", 0)) is None
    assert godot.image_enregistree(Sortie("godot …", "ERROR: Shader compilation failed.", 0)) is None


def test_roles_alternes():
    assert assembler.roles_valides(["system", "user", "assistant", "user", "assistant"])
    assert not assembler.roles_valides(["system", "user", "assistant", "assistant"])
    assert not assembler.roles_valides(["system", "user", "assistant", "user"])


@pytest.mark.skipif(shutil.which("git") is None, reason="git absent (différences par git diff --histogram)")
def test_consignes_d_edition_rejouees_a_la_lettre():
    """Règle 5.7 : appliquées à la lettre, les consignes redonnent le code attendu."""
    avant = {"a.gd": "extends Node\n\n\nfunc f() -> int:\n\treturn 1\n\n\nfunc g() -> int:\n\treturn 1\n"}
    apres = {"a.gd": "extends Node\n\n\nfunc f() -> int:\n\treturn 2\n\n\nfunc g() -> int:\n\treturn 1\n\n\n"
                     "func h() -> int:\n\treturn 3\n",
             "b.gd": "extends Node\n"}
    morceaux = etat.morceaux(avant, apres)
    consignes = composer.editions(avant, apres, morceaux)
    obtenu, problemes = rejouer.rejouer(avant, consignes)
    assert problemes == []
    assert rejouer.comparer(obtenu, apres, etat.CODE) == []
    # « return 1 » existe deux fois : la consigne cite un passage élargi, unique dans le fichier.
    assert "return 2" in consignes and "func f() -> int:" in consignes


def test_erreur_repetee_compactee():
    bloc = "SCRIPT ERROR: Parse Error: x\n          at: GDScript::reload (res://a.gd:3)"
    texte = "\n".join([bloc] * 5)
    compacte = debogage.compacter(texte)
    assert compacte.count("SCRIPT ERROR") == 2
    assert "reviennent encore 3 fois" in compacte


def test_extrait_de_shader_decale_par_un_include():
    """Règle 5.6 : avec un #include au-dessus de l'erreur, l'extrait affiché glisse d'une ligne ; « at: » fait foi."""
    fichier = ("shader_type spatial;\n#include \"res://commun.gdshaderinc\"\nuniform float a = 1;\nvoid fragment() {\n"
               "\tALBEDO = vec3(1);\n}")
    # Ce que Godot 4.7.2 affiche : sous chaque numéro, le texte de la ligne d'avant ; la flèche est sur la ligne 5.
    sortie = ("--res://s.gdshader--\n    3 | #include \"res://commun.gdshaderinc\"\n    4 | uniform float a = 1;\n"
              "E   5 | void fragment() {\n    6 | \tALBEDO = vec3(1);\n    7 | }\n"
              "SHADER ERROR: erreur\n          at: (res://s.gdshader:5)")
    note = debogage.lecture_extrait_shader(sortie, "res://s.gdshader", 5, "\tALBEDO = vec3(1);", fichier)
    assert "décalé d'une ligne" in note
    assert "ligne 5 du fichier" in note
    assert "`#include` placé plus haut" in note
    # Sans décalage, rien à dire.
    juste = sortie.replace("E   5 | void fragment() {\n    6 | \tALBEDO", "    4 | void fragment() {\nE   5 | \tALBEDO")
    assert debogage.lecture_extrait_shader(juste, "res://s.gdshader", 5, "\tALBEDO = vec3(1);", fichier) == ""
