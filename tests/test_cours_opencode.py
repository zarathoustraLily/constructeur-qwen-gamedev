"""Format d'OpenCode de la base « bâtiments procéduraux » : gabarit de chat, retours d'outils, éditions, export.

Le gabarit de référence est celui du GGUF de Qwen 3.8 de laurent (tests/donnees/qwen38_gabarit_chat.jinja, version
d'Unsloth) : `opencode.rendre` doit en donner exactement le texte. Sans jinja2, ce contrôle est sauté.
"""

from __future__ import annotations

import json
import random
from pathlib import Path

import pytest

from usine.cours.base import opencode

GABARIT = Path(__file__).parent / "donnees" / "qwen38_gabarit_chat.jinja"
GODOT = r"D:\GODOT\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
DOSSIER = r"D:\GODOT\projet_enseingement\001_Batiments proceduraux"


def _session(tmp_path: Path) -> Path:
    """Une session capturée minimale : les 12 outils d'OpenCode et un prompt avec ses lignes d'environnement."""
    outils = [{"type": "function", "function": {"name": n, "description": f"outil {n}",
                                                "parameters": {"type": "object", "properties": {}, "required": []}}}
              for n in opencode.OUTILS_ATTENDUS]
    systeme = ("You are an AI agent running in OpenCode, a coding agent harness.\n<env>\n"
               "  Current conversation session ID: ses_abc123DEF\n  Working directory: D:\\GODOT\\essai\n"
               "  Workspace root folder: D:\\GODOT\\essai\n</env>")
    chemin = tmp_path / "session.jsonl"
    chemin.write_text(json.dumps({"tools": outils}) + "\n" + json.dumps({"role": "system", "content": systeme}) + "\n",
                      encoding="utf-8")
    return chemin


def _conversation(tmp_path: Path) -> opencode.Conversation:
    h = opencode.Harnais.charger(_session(tmp_path), GODOT, DOSSIER)
    c = opencode.Conversation(h, "building_proceduraux_parisien_etape_003", "parisien-003-creation")
    c.utilisateur("Fais l'étape 003.  ")
    c.lire("**But** : la pierre.\n\nJe lis d'abord le code :",
           [("6_assets/a.gd", "extends Node\n\nfunc f() -> int:\n\treturn 1\n", 1, 3), ("6_assets/b.gd", "x\ny\n", 1, 2)])
    c.editer("### 1. Chercher\n…", "6_assets/a.gd", "\treturn 1", "\treturn 2")
    c.editer("", "6_assets/a.gd", "func f()", "func g()")
    c.ecrire("", "6_assets/c.gd", "extends Node\n", False)
    c.shell("### 3. Tester\n\nD'abord l'import :", "godot --headless --path . --import",
            "Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org\n\n", 0, str(tmp_path))
    c.chercher("Je cherche :", r"^\s*var \w+ = |\bSpatial\b", ["*.gd", "*.gdshader"], "")
    c.repondre("### 4. Vérifier\n\nTout passe.")
    return c


def test_prompt_et_commande_chez_laurent(tmp_path):
    c = _conversation(tmp_path)
    systeme = c.messages[0]["content"]
    dossier = DOSSIER + r"\building_proceduraux_parisien_etape_003"
    assert f"  Working directory: {dossier}\n" in systeme and f"  Workspace root folder: {dossier}\n" in systeme
    assert "ses_abc123DEF" not in systeme
    shell = next(tc for m in c.messages for tc in m.get("tool_calls") or [] if tc["function"]["name"] == "shell")
    assert shell["function"]["arguments"]["command"] == GODOT + " --headless --path . --import"


def test_retours_aux_formes_relevees(tmp_path):
    c = _conversation(tmp_path)
    retours = [m["content"] for m in c.messages if m["role"] == "tool"]
    assert retours[0].startswith(f"Read file {DOSSIER}\\building_proceduraux_parisien_etape_003\\6_assets\\a.gd, "
                                 "lines 1-3\n1: extends Node\n2: \n3: func f() -> int:\n[Output truncated. Continue "
                                 "reading with offset: 4]")
    assert retours[1].endswith("lines 1-2\n1: x\n2: y")          # fin du fichier : pas de suite, pas de ligne vide
    assert retours[2] == "Edited 6_assets/a.gd (1 replacement)"
    assert retours[4] == "Created file successfully: 6_assets/c.gd"
    assert retours[5] == ("Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org\n\n\n"
                          "Command exited with code 0.")
    assert retours[6] == "No matches found"
    grep = [tc for m in c.messages for tc in m.get("tool_calls") or [] if tc["function"]["name"] == "grep"][0]
    assert grep["function"]["arguments"]["include"] == "*.{gd,gdshader}"


def test_formes_non_relevees_refusees(tmp_path):
    """Une sortie vide a sa forme relevée ; une sortie qu'OpenCode tronquerait, ou un grep qui trouve quelque chose
    (forme non reproduite), ne deviennent pas des exemples."""
    assert opencode.retour_shell("", 0) == "(no output)\nCommand exited with code 0."
    with pytest.raises(opencode.FormatInconnu):
        opencode.retour_shell("x" * (opencode.LIMITE_SORTIE + 1), 0)
    c = opencode.Conversation(opencode.Harnais.charger(_session(tmp_path), GODOT, DOSSIER), "p", "e")
    c.utilisateur("Cherche.")
    with pytest.raises(opencode.FormatInconnu):
        c.chercher("Je cherche :", r"\bSpatial\b", ["*.gd"], "./a.gd:3:var s: Spatial")


def test_sortie_de_godot_sans_ce_qui_tient_a_la_machine(tmp_path):
    brut = ("Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org\n\n"
            "WARNING: Could not set V-Sync mode, as changing V-Sync mode is not supported by the graphics driver.\n"
            "     at: set_use_vsync (platform/linuxbsd/x11/gl_manager_x11.cpp:372)\n"
            "[   0% ] \x1b[90mfirst_scan_filesystem\x1b[22m | Started\x1b[39m\x1b[0m\n\x1b[0m\n"
            "OpenGL API 4.5 (Core Profile) Mesa 25.2.8 - Compatibility - Using Device: Mesa - llvmpipe\n"
            "SCRIPT ERROR: Parse Error: x\n          at: GDScript::reload (res://a.gd:3)\n"
            f"ERROR: Cannot open file '{tmp_path}/b.png'.\n")
    assert opencode.sortie_godot(brut, str(tmp_path), DOSSIER + r"\p") == (
        "Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org\n\n"
        "SCRIPT ERROR: Parse Error: x\n          at: GDScript::reload (res://a.gd:3)\n"
        f"ERROR: Cannot open file '{DOSSIER.replace(chr(92), '/')}/p/b.png'.\n")


def test_editions_uniques_qui_redonnent_le_fichier():
    """Sur des fichiers tirés au hasard : chaque passage est unique au moment de l'appliquer, et le résultat est
    exactement le fichier attendu, lignes vides comprises."""
    hasard = random.Random(7)
    mots = ["\treturn 1", "", "func f() -> int:", "extends Node", "var a: int = 0", "\tpass", "## doc"]
    for _ in range(200):
        avant = [hasard.choice(mots) for _ in range(hasard.randint(1, 25))]
        apres = list(avant)
        for _ in range(hasard.randint(1, 4)):
            i = hasard.randint(0, len(apres))
            choix = hasard.random()
            if choix < 0.4 and apres:
                apres[min(i, len(apres) - 1)] = hasard.choice(mots) + " # changé"
            elif choix < 0.7:
                apres[i:i] = [hasard.choice(mots) + " # ajouté"]
            elif apres:
                del apres[min(i, len(apres) - 1)]
        a, n = "\n".join(avant), "\n".join(apres)
        if a == n or not n.strip():
            continue
        try:
            eds = opencode.editions_fichier(a, n)
        except ValueError:
            continue        # un fichier fait d'une seule ligne répétée n'a pas toujours de passage unique
        assert opencode.appliquer({"x.gd": a}, [("edit", {"path": DOSSIER + "\\x.gd", "oldString": e.ancien,
                                                          "newString": e.nouveau}) for e in eds], DOSSIER)["x.gd"] == n


def test_appliquer_refuse_un_passage_repete():
    with pytest.raises(ValueError):
        opencode.appliquer({"x.gd": "a\na\n"}, [("edit", {"path": DOSSIER + "\\x.gd", "oldString": "a",
                                                          "newString": "b"})], DOSSIER)


def test_sharegpt_redonne_le_texte_du_gabarit(tmp_path):
    ex = _conversation(tmp_path).exemple()
    texte = opencode.rendre(ex["messages"], ex["tools"])
    sg = opencode.vers_sharegpt(ex["messages"], ex["tools"])
    assert opencode.rendre_sharegpt(sg) == texte
    assert [t["from"] for t in sg["conversations"]][:3] == ["human", "gpt", "human"]
    # Le texte qui précède un appel reste dans la réponse (section 3 des règles qui priment).
    assert sg["conversations"][1]["value"].startswith("**But** : la pierre.")
    assert "<tool_call>\n<function=read>\n<parameter=path>\n" in sg["conversations"][1]["value"]


@pytest.mark.skipif(not GABARIT.is_file(), reason="gabarit de Qwen 3.8 absent")
def test_rendu_identique_au_gabarit_de_qwen38(tmp_path):
    pytest.importorskip("jinja2")
    import jinja2
    import jinja2.ext
    from jinja2.sandbox import ImmutableSandboxedEnvironment

    def tojson(x, ensure_ascii=False, indent=None, separators=None, sort_keys=False):
        return json.dumps(x, ensure_ascii=ensure_ascii, indent=indent, separators=separators, sort_keys=sort_keys)

    def lever(message):
        raise jinja2.exceptions.TemplateError(message)

    env = ImmutableSandboxedEnvironment(trim_blocks=True, lstrip_blocks=True, extensions=[jinja2.ext.loopcontrols])
    env.filters["tojson"] = tojson
    env.globals["raise_exception"] = lever
    gabarit = env.from_string(GABARIT.read_text(encoding="utf-8"))
    ex = _conversation(tmp_path).exemple()
    attendu = gabarit.render(messages=ex["messages"], tools=ex["tools"], add_generation_prompt=False,
                             enable_thinking=False)
    assert opencode.rendre(ex["messages"], ex["tools"]) == attendu
    # Sans outils, le système seul.
    court = [{"role": "system", "content": "S"}, {"role": "user", "content": "Q"}, {"role": "assistant", "content": "R"}]
    assert opencode.rendre(court, []) == gabarit.render(messages=court, tools=None, add_generation_prompt=False,
                                                        enable_thinking=False)
