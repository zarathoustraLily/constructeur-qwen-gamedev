"""Vérifier avant d'écrire (plan « qualité maximale », point A), sur la vraie API 4.7.2 de la machine."""

import pytest

from usine.paires import verification as v


@pytest.fixture(autouse=True)
def _api():
    try:
        from usine.cours.base import api, chemins
        chemins.configurer(cours="kart")
        api._api()
        from mcp_serveur.outils import Outils
        Outils.vocab_lookup(None, "Node", "get_tree")
    except Exception as e:  # noqa: BLE001
        pytest.skip(f"API 4.7.2 ou vocabulaire absents : {e}")


def _paire(demande: str, reponse: str) -> dict:
    from usine.paires import format as fmt
    return fmt.paire("compilation", "gameplay", "débogage", demande, reponse, {})


def test_un_membre_neuf_est_verifie_avant_d_ecrire():
    demande = "Corrige :\n```gdscript\nextends Node3D\nvar items: Array = []\n\tif items.empty():\n```"
    reponse = ("**Lire.** …\n\n**Corriger.** je remplace :\n```gdscript\n\tif items.empty():\n```\npar :\n"
               "```gdscript\n\tif items.is_empty():\n```")
    q = v.ajouter(_paire(demande, reponse))
    roles = [m["role"] for m in q["messages"]]
    assert roles == ["user", "assistant", "tool", "assistant"]
    appel = q["messages"][1]["tool_calls"][0]["function"]
    assert appel["name"] == "execute" and "vocab_lookup" in appel["arguments"]["code"]
    assert "is_empty() -> bool" in q["messages"][2]["content"]
    assert q["messages"][3]["content"].startswith("**Lu.** `Array.is_empty` existe")
    assert "**Corriger.**" in q["messages"][3]["content"] and "**Lire.**" in q["messages"][1]["content"]
    assert q["preuve"]["verification_api"] == ["Array.is_empty"]


def test_un_membre_deja_employe_dans_le_code_montre_n_est_pas_reverifie():
    demande = "```gdscript\nextends Node3D\nfunc a() -> void:\n\tprint(get_tree())\n```"
    reponse = "**Écrire.**\n```gdscript\nfunc b() -> void:\n\tget_tree().quit()\n```"
    p = _paire(demande, reponse)
    q = v.ajouter(p)
    assert [x for x in v.a_verifier(p, 1) if x[1] == "get_tree"] == []
    assert all("get_tree" not in str(m.get("tool_calls")) for m in q["messages"])


def test_les_types_viennent_des_constructeurs_et_des_fonctions_du_projet():
    contexte = "```gdscript\nextends Node3D\nfunc get_speed() -> Vector3:\n\treturn Vector3.ZERO\n```"
    code = "func f() -> float:\n\tvar h := get_speed()\n\tvar d := Vector2(1.0, 0.0)\n\treturn h.length() + d.angle()"
    membres = v.membres_ecrits(code, contexte)
    assert ("Vector3", "length") in membres and ("Vector2", "angle") in membres


def test_une_paire_qui_verifie_deja_n_est_pas_touchee():
    from usine.paires import format as fmt
    p = _paire("x", "**Écrire.**\n```gdscript\nvar n: float = Vector3.UP.length()\n```")
    p["messages"][1]["tool_calls"] = [fmt.appel("a", "execute", {"code": 'tools["usine-godot"].search_docs({})'})]
    assert v.ajouter(p) is p
