"""Sonde de la capture d'OpenCode (A5) : le scénario suit les outils que la requête déclare."""

from usine.capture import sonde


def _outil(nom, *params):
    return {"type": "function", "function": {"name": nom, "parameters": {
        "type": "object", "properties": {p: {"type": "string"} for p in params}, "required": list(params)}}}


def test_le_scenario_passe_par_le_code_mode_puis_lit_l_image():
    outils = [_outil("execute", "code"), _outil("read", "path")]
    corps = {"tools": outils, "messages": [{"role": "user", "content": "Cherche."}]}
    outil, args, _ = sonde.decision(corps, "C:/p/capture.png")
    assert outil == "execute" and args == {"code": sonde.CODE_PAR_DEFAUT}
    corps["messages"].append({"role": "assistant", "tool_calls": [{"id": "a"}]})
    assert sonde.decision(corps, "C:/p/capture.png")[:2] == ("read", {"path": "C:/p/capture.png"})
    corps["messages"].append({"role": "assistant", "tool_calls": [{"id": "b"}]})
    assert sonde.decision(corps, "C:/p/capture.png")[0] is None


def test_titre_et_amorce_recoivent_du_texte():
    assert sonde.decision({"messages": []}, "x")[0] is None
    corps = {"tools": [_outil("execute", "code")], "messages": [{"role": "user", "content": sonde.AMORCE}]}
    assert sonde.decision(corps, "x") == (None, {}, "Prêt.")
