"""Base « bâtiments procéduraux » : contrôles des exemples, consignes d'édition rejouées, lecture des sorties.

Ces tests ne lancent pas Godot. La génération réelle (Godot, godot-docs, source de Godot, vocabulaire de Qwen) se
vérifie par `python -m usine.cours.base tout` ; voir VERIFIER_EN_LOCAL.md.
"""

from __future__ import annotations

import shutil
from pathlib import Path

import pytest

from usine.cours.base import assembler, composer, debogage, etat, godot, ordonner, rejouer
from usine.cours.base.creation import bloc_commande, bloc_sortie
from usine.cours.base.etat import Morceau
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
    arguments = ["--path", ".", "--rendering-method", "gl_compatibility", "--quit-after", "6000", "++",
                 f"--shot={godot.IMAGE_RENDU}"]
    assert godot.commande(arguments) == ("godot --path . --rendering-method gl_compatibility --quit-after 6000 ++ "
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


def _morceaux(*morceaux: Morceau) -> list[Morceau]:
    for i, m in enumerate(morceaux):
        m.id = i
    return list(morceaux)


def _groupe_de(groupes: list[list[int]]) -> dict[int, int]:
    return {v: k for k, g in enumerate(groupes) for v in g}


def test_empaqueter_ne_perd_ni_ne_double_aucune_partie():
    """Une dernière partie minuscule rejoint la précédente, sans écraser l'avant-dernière (`p[-2] += p.pop()` lit
    sa cible avant le pop et la réécrit un rang trop haut)."""
    tous = _morceaux(*[Morceau("a.gd", i, i, i, i + 1, [], ["x" * (3000 if i < 3 else 2000)]) for i in range(4)])
    parties = ordonner.empaqueter([[0], [1], [2], [3]], tous, {i: 1 for i in range(4)}, {}, 3500)
    assert parties == [[0], [1], [2, 3]]


def test_une_locale_retiree_va_avec_sa_redeclaration_et_ses_emplois():
    """newyorkais 007 : un morceau retire `for side` et `var street`, un autre les redéclare plus bas, un troisième
    change une ligne qui emploie `street`. Séparés, l'état intermédiaire emploie une variable qui n'existe plus."""
    avant = ["func f() -> float:", "\tvar margin: float = 0.0", "\tfor side: int in range(4):",
             "\t\tvar street: float = g(side)", "\t\tmargin += street", "\treturn margin", ""]
    apres = ["func f() -> float:", "\tvar margin: float = 0.0", "\tif flag:", "\t\treturn 0.0",
             "\tfor side: int in range(4):", "\t\tvar street: float = g(side)", "\t\tif street > 0.0:",
             "\t\t\tmargin += street", "\treturn margin", ""]
    tous = _morceaux(Morceau("a.gd", 2, 4, 2, 4, avant[2:4], apres[2:4]),
                     Morceau("a.gd", 4, 4, 4, 7, [], apres[4:7]),
                     Morceau("a.gd", 4, 5, 7, 8, avant[4:5], apres[7:8]))
    groupes = ordonner.ordre(tous, {0: 1, 1: 1, 2: 1}, {"a.gd": "\n".join(avant)}, composer.ordre_fichier,
                             {"a.gd": "\n".join(apres)})
    assert len(groupes) == 1


def test_un_membre_pointe_de_gdscript_n_est_pas_une_fonction_de_shader():
    """`t.rect` en GDScript et la fonction `rect` retirée d'un shader : pas de lien (newyorkais 007 liait ainsi le
    script de la tour au shader des fenêtres)."""
    avant = {"a.gd": "func f(t: Node) -> void:\n\tprint(t.rect)\n",
             "s.gdshader": "shader_type spatial;\nfloat rect(vec2 p) {\n\treturn p.x;\n}\nvoid fragment() {\n"
                           "\tALBEDO = vec3(rect(UV));\n}\n"}
    apres = {"a.gd": "func f(t: Node) -> void:\n\tprint(t.rect.size)\n",
             "s.gdshader": "shader_type spatial;\nvoid fragment() {\n\tALBEDO = vec3(UV.x);\n}\n"}
    sa, sn = avant["s.gdshader"].split("\n"), apres["s.gdshader"].split("\n")
    tous = _morceaux(Morceau("a.gd", 1, 2, 1, 2, ["\tprint(t.rect)"], ["\tprint(t.rect.size)"]),
                     Morceau("s.gdshader", 1, 4, 1, 1, sa[1:4], []),
                     Morceau("s.gdshader", 5, 6, 2, 3, sa[5:6], sn[2:3]))
    groupe = _groupe_de(ordonner.ordre(tous, {0: 1, 1: 1, 2: 1}, avant, composer.ordre_fichier, apres))
    assert groupe[1] == groupe[2] and groupe[0] != groupe[1]


def test_une_fonction_privee_peut_preceder_son_premier_appel():
    """Pas d'avertissement pour une fonction privée sans appel : elle peut arriver dans une partie, son appel dans
    la suivante. Une variable membre privée sans emploi, elle, avertit (UNUSED_PRIVATE_CLASS_VARIABLE)."""
    for decl, emploi, ensemble in (("func _b() -> void:", "\t_b()", False), ("var _b: int = 0", "\tprint(_b)", True)):
        avant = ["extends Node", "", "func a() -> void:", "\tpass", ""]
        apres = ["extends Node", "", "func a() -> void:", emploi, "", decl, "\tpass" if decl.startswith("func") else "", ""]
        tous = _morceaux(Morceau("a.gd", 3, 4, 3, 4, ["\tpass"], [emploi]), Morceau("a.gd", 4, 4, 4, 7, [], apres[4:7]))
        groupes = ordonner.ordre(tous, {0: 1, 1: 1}, {"a.gd": "\n".join(avant)}, composer.ordre_fichier,
                                 {"a.gd": "\n".join(apres)})
        assert (len(groupes) == 1) is ensemble
        if not ensemble:
            assert groupes == [[1], [0]]      # la déclaration d'abord


def test_sortie_gardee_remise_au_chemin_de_son_dossier(tmp_path, monkeypatch):
    """Le même état sous un autre nom de dossier (dernière partie p2 ou p3) : la sortie gardée parle du nouveau."""
    monkeypatch.setattr(godot, "_EMPREINTES", {})
    monkeypatch.setattr(godot, "_GARDEES", {})
    p2, p3 = str(tmp_path / "p2"), str(tmp_path / "p3")
    godot._EMPREINTES[p2] = godot._EMPREINTES[p3] = "meme_etat"
    arguments = ["--headless", "--path", ".", "--import"]
    brut = f"ERROR: Cannot open file '{Path(p2).resolve()}/x.png'.\n"
    godot._GARDEES[("meme_etat", tuple(arguments))] = godot._avec_marque(("", 0, brut), p2)
    assert godot._lancer(arguments, p3)[2] == f"ERROR: Cannot open file '{Path(p3).resolve()}/x.png'.\n"


def test_simulation_rend_les_sorties_types_sans_lancer_godot(tmp_path):
    types = {g: godot._avec_marque(("", 0, f"Godot Engine v4.7.2\n{Path(tmp_path).resolve()}/{g}\n"), str(tmp_path))
             for g in ("import", "analyse", "test", "rendu")}
    projet = str(tmp_path / "autre")
    with godot.simulation(types):
        s = godot.tester(projet, "res://t.gd")
    assert s.brut == f"Godot Engine v4.7.2\n{Path(projet).resolve()}/test\n"     # le chemin du dossier simulé
    assert godot._SIMULATION is None


def test_constante_de_shader_et_signature_sur_deux_lignes():
    """newyorkais 010 : une constante nouvelle du fichier inclus (« const int ROOM_OFFICE = 0; », que la forme
    `const NOM` de GDScript lisait « int ») passe avant son emploi ; un paramètre changé sur la deuxième ligne d'une
    signature lie la définition à ses appels."""
    inc_avant = "vec3 room_view(vec2 q,\n\t\tbool lobby) {\n\treturn vec3(0.0);\n}\n"
    inc_apres = "const int ROOM_OFFICE = 0;\nvec3 room_view(vec2 q,\n\t\tint room_kind) {\n\treturn vec3(0.0);\n}\n"
    sh_avant = ('shader_type spatial;\n#include "res://c.gdshaderinc"\nvoid fragment() {\n'
                "\tALBEDO = room_view(UV, false);\n}\n")
    sh_apres = sh_avant.replace("room_view(UV, false)", "room_view(UV, ROOM_OFFICE)")
    tous = _morceaux(Morceau("c.gdshaderinc", 0, 0, 0, 1, [], ["const int ROOM_OFFICE = 0;"]),
                     Morceau("c.gdshaderinc", 1, 2, 2, 3, ["\t\tbool lobby) {"], ["\t\tint room_kind) {"]),
                     Morceau("s.gdshader", 3, 4, 3, 4, ["\tALBEDO = room_view(UV, false);"],
                             ["\tALBEDO = room_view(UV, ROOM_OFFICE);"]))
    assert ordonner.declarations(["const int ROOM_OFFICE = 0;"]) == {"ROOM_OFFICE"}
    assert ordonner.declarations(["const SPEED: float = 2.0"]) == {"SPEED"}
    groupes = ordonner.ordre(tous, {0: 1, 1: 1, 2: 1}, {"c.gdshaderinc": inc_avant, "s.gdshader": sh_avant},
                             composer.ordre_fichier, {"c.gdshaderinc": inc_apres, "s.gdshader": sh_apres})
    groupe = _groupe_de(groupes)
    assert groupe[1] == groupe[2]               # la signature et son appel
    assert groupe[0] <= groupe[2]               # la constante avant son emploi


def test_un_point_qui_nomme_un_fichier_recoit_ses_morceaux():
    """parisien 002 : « Le fichier commun `procedural_commun.gdshaderinc` » n'a pas d'extrait ; le point « Écrire le
    shader », qui cite le même fichier dans son texte, prenait ses morceaux. Le titre l'emporte."""
    from usine.cours.base import creation, rattacher
    from usine.cours.base.notes import Note, Point
    shader = Point(1, "Écrire le shader", "On écrit `pierre.gdshader`, qui inclut `procedural_commun.gdshaderinc`.",
                   [("glsl", "shader_type spatial;\nvoid fragment() {\n\tALBEDO = stone_color();\n}")])
    commun = Point(2, "Le fichier commun `procedural_commun.gdshaderinc`", "Des fonctions partagées.")
    note = Note("parisien", 2, "Étape 002", "", "", [shader, commun], "", "", "", "")
    inc = "6_assets/Shader/Procedural/procedural_commun.gdshaderinc"
    tous = _morceaux(Morceau(inc, 0, 0, 0, 3, [], ["vec3 stone_color() {", "\treturn vec3(0.8);", "}"]),
                     Morceau("6_assets/pierre.gdshader", 0, 0, 0, 4, [], shader.extraits[0][1].split("\n")),
                     Morceau("7_tests/test_pierre.gd", 0, 0, 0, 1, [], ["extends SceneTree"]))
    affect = rattacher.rattacher(note, tous, {m.fichier: "\n".join(m.nouvelles) for m in tous})
    assert affect[0] == 2 and affect[1] == 1
    # Le morceau du test, rattaché par défaut au dernier point, ne l'annonce pas : la seconde partie annonce le
    # shader, pas « Le fichier commun », qu'elle ne touche pas.
    assert creation.muets(note, tous, affect) == {2}
    assert creation.points_des_parties(note, [[0], [1, 2]], affect, creation.muets(note, tous, affect)) == \
        [([2], set()), ([1], set())]
