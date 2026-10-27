"""Exemples d'analyse tirés des sessions de débogage (étape A2) : même début, diagnostic sans rien modifier."""

import pytest

from usine.cours.base import analyse, assembler

DOSSIER = "D:\\GODOT\\cours\\kart_etape_001"


class Harnais:
    def dossier(self, nom):
        return DOSSIER


def _appel(i, nom, args):
    return {"id": f"c{i}", "type": "function", "function": {"name": nom, "arguments": args}}


def _session():
    oc = [
        {"role": "system", "content": "You are an AI agent running in OpenCode."},
        {"role": "user", "content": "Je travaille à l'étape 001. Vérifie que tout passe. Corrige ce qui ne va pas."},
        {"role": "assistant", "content": "Je lance l'analyse :", "tool_calls": [_appel(1, "shell", {"command": "godot"})]},
        {"role": "tool", "tool_call_id": "c1", "content": "SCRIPT ERROR: Parse Error\nCommand exited with code 1."},
        {"role": "assistant", "content": "**Lire l'erreur.** Godot signale, ligne 1.\n\nJe lis le code autour :",
         "tool_calls": [_appel(2, "read", {"filePath": DOSSIER + "\\a.gd"})]},
        {"role": "tool", "tool_call_id": "c2", "content": f"Read file {DOSSIER}\\a.gd, lines 1-1\n1: var a = 1"},
        {"role": "assistant", "content": "**Chercher.**\nLa déclaration n'a pas de type.\n\n**Corriger.** Une seule ligne "
         "change : la ligne 1 de `res://a.gd`.",
         "tool_calls": [_appel(3, "edit", {"path": DOSSIER + "\\a.gd", "oldString": "var a = 1",
                                           "newString": "var a: int = 1"})]},
        {"role": "tool", "tool_call_id": "c3", "content": "Edited a.gd (1 replacement)"},
        {"role": "assistant", "content": "**Vérifier.** Tout passe."},
    ]
    neutre = [
        {"role": "system", "content": "système"},
        {"role": "user", "content": "Sortie.\n\nCorrige jusqu'à ce que tout passe : l'analyse du script et le test."},
        {"role": "assistant", "content": "**Lire l'erreur.** Ligne 1.\n\n**Chercher.**\nPas de type.\n\n**Corriger.** "
         "Une seule ligne change :\nDans `res://a.gd`, ligne 1, je remplace :\n```gdscript\nvar a = 1\n```\npar :\n"
         "```gdscript\nvar a: int = 1\n```\n\n**Tester.** Je relance la même commande :\n```\n$ godot\n```"},
    ]
    return {"id": "kart-001-debogage-1", "ville": "kart", "etape": 1, "type": "debogage", "messages": neutre,
            "opencode": {"messages": oc, "tools": []}, "genres": ["non_type"], "nb_erreurs": 1,
            "preuves": {"ok": True, "mutations": [], "vues": ["analyse"], "commandes": []}}


def test_l_analyse_reprend_le_debut_et_finit_sans_rien_modifier():
    a = analyse.depuis_session(_session(), Harnais())
    assert a["id"] == "kart-001-analyse-1" and a["type"] == "analyse"
    ms = a["opencode"]["messages"]
    assert [m["role"] for m in ms] == ["system", "user", "assistant", "tool", "assistant", "tool", "assistant"]
    assert ms[1]["content"].endswith(analyse.ANALYSER_OC.strip()) and analyse.CORRIGER_OC not in ms[1]["content"]
    fin = ms[-1]
    assert not fin.get("tool_calls") and fin["content"].startswith("**Chercher.**")
    assert "Dans `res://a.gd`, remplacer :\n```gdscript\nvar a = 1\n```\npar :\n```gdscript\nvar a: int = 1\n```" in fin["content"]
    assert fin["content"].endswith(analyse.FIN)
    neutre = a["messages"][-1]["content"]
    assert "**À changer.**" in neutre and "**Tester.**" not in neutre and "$ godot" not in neutre
    assert a["opencode"]["jetons_reponse"] > 0


def test_une_session_sans_lecture_avant_l_edition_n_a_pas_d_analyse():
    e = _session()
    del e["opencode"]["messages"][4:6]
    with pytest.raises(analyse.PasDAnalyse):
        analyse.depuis_session(e, Harnais())


def test_l_equilibrage_garde_la_creation_et_vise_40_40_20(monkeypatch):
    monkeypatch.setattr(assembler, "ordre_lignes", lambda: {"kart": 0})

    def ex(i, t, n):
        return {"id": f"{t}-{i}", "ville": "kart", "etape": 1, "type": t, "jetons_reponse": n}
    exemples = [ex(1, "creation", 1000)] + [ex(i, "debogage", 300) for i in range(5)] + \
        [ex(i, "analyse", 100) for i in range(8)]
    gardes, ecartes = assembler.equilibrer(exemples)
    parts = assembler.parts(gardes)
    assert any(e["type"] == "creation" for e in gardes)
    assert abs(parts["creation"] - 0.4) < 0.05 and abs(parts["analyse"] - 0.2) < 0.05 and len(ecartes) == 5
