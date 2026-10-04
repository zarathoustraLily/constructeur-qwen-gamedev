"""Proxy de capture : relais à l'identique (SSE compris) et sessions JSONL."""

from __future__ import annotations

import http.client
import json
import socket

from usine.capture.enregistreur import Enregistreur, lire_session, reponse_depuis_sse
from usine.capture.faux_serveur import morceaux_sse
from usine.capture.preuve import executer_preuve
from usine.capture.proxy import ProxyCapture, amont_depuis_url


def test_preuve_faux_serveur(tmp_path):
    r = executer_preuve(tmp_path)
    assert r["ok"], r
    entete, messages = lire_session(next(tmp_path.glob("*.jsonl")))
    assert (entete["tache_id"], entete["competence"], entete["verdict_final"]) == (None, None, None)
    assert [t["function"]["name"] for t in entete["tools"]] == ["usine-godot_scene_write", "usine-godot_run_tests"]
    assert [m["role"] for m in messages] == ["system", "user", "assistant", "tool", "assistant", "tool", "assistant"]
    brut = list((tmp_path / "brut").glob("*.jsonl"))
    assert len(brut) == 1 and len(brut[0].read_text(encoding="utf-8").splitlines()) == 3


def test_reponse_sse_recompose_texte_et_appels():
    morceaux = morceaux_sse([
        {"choices": [{"index": 0, "delta": {"role": "assistant", "content": "Bon"}}]},
        {"choices": [{"index": 0, "delta": {"content": "jour", "tool_calls": [
            {"index": 0, "id": "a", "type": "function", "function": {"name": "run_", "arguments": "{\"fi"}}]}}]},
        {"choices": [{"index": 0, "delta": {"tool_calls": [
            {"index": 0, "function": {"name": "tests", "arguments": "ltre\": null}"}}]}, "finish_reason": "tool_calls"}],
         "usage": {"total_tokens": 5}}])
    r = reponse_depuis_sse("".join(morceaux).encode("utf-8"))
    assert r["message"] == {"role": "assistant", "content": "Bonjour", "tool_calls": [
        {"id": "a", "type": "function", "function": {"name": "run_tests", "arguments": "{\"filtre\": null}"}}]}
    assert (r["finish_reason"], r["usage"]) == ("tool_calls", {"total_tokens": 5})


def _echange(enr, messages, contenu):
    corps = json.dumps({"model": "q", "messages": messages}).encode()
    rep = json.dumps({"choices": [{"index": 0, "message": {"role": "assistant", "content": contenu}}]}).encode()
    return enr.enregistrer("/v1/chat/completions", corps, 200, {"content-type": "application/json"}, rep)


def test_sessions_distinctes_et_continuation(tmp_path):
    enr = Enregistreur(tmp_path)
    a = [{"role": "system", "content": "S"}, {"role": "user", "content": "A"}]
    b = [{"role": "system", "content": "S"}, {"role": "user", "content": "B"}]
    fa = _echange(enr, a, "ra")
    fb = _echange(enr, b, "rb")
    fa2 = _echange(enr, a + [{"role": "assistant", "content": "ra"}, {"role": "user", "content": "suite"}], "ra2")
    assert fa == fa2 and fa != fb
    entete, messages = lire_session(fa)
    assert entete["echanges"] == 2 and [m["content"] for m in messages] == ["S", "A", "ra", "suite", "ra2"]
    # Une réponse en erreur est gardée dans le journal brut, pas dans les sessions.
    assert enr.enregistrer("/v1/chat/completions", b"{}", 500, {}, b"oups") is None
    assert len(list(tmp_path.glob("*.jsonl"))) == 2


def test_amont_injoignable_donne_502(tmp_path):
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        port_libre = s.getsockname()[1]
    proxy = ProxyCapture(0, f"http://127.0.0.1:{port_libre}/v1", tmp_path)
    proxy.demarrer_en_fond()
    try:
        con = http.client.HTTPConnection("127.0.0.1", proxy.port, timeout=10)
        con.request("POST", "/v1/chat/completions", body=b"{}", headers={"Content-Type": "application/json"})
        rep = con.getresponse()
        assert rep.status == 502 and "injoignable" in json.loads(rep.read())["error"]["message"]
    finally:
        proxy.shutdown()
        proxy.server_close()


def test_amont_depuis_url():
    assert amont_depuis_url("http://127.0.0.1:8080/v1") == ("127.0.0.1", 8080)


def _echange_complet(enr, messages, contenu, outils=("scene_write",)):
    corps = json.dumps({"model": "q", "messages": messages,
                        "tools": [{"type": "function", "function": {"name": n}} for n in outils]}).encode()
    rep = json.dumps({"choices": [{"index": 0, "message": {"role": "assistant", "content": contenu}}]}).encode()
    return enr.enregistrer("/v1/chat/completions", corps, 200, {"content-type": "application/json"}, rep)


def test_prompt_systeme_qui_change_ne_coupe_pas_la_session(tmp_path):
    enr = Enregistreur(tmp_path)
    u = {"role": "user", "content": "Ajoute un piège"}
    f1 = _echange_complet(enr, [{"role": "system", "content": "fichiers : a.gd"}, u], "je regarde")
    f2 = _echange_complet(enr, [{"role": "system", "content": "fichiers : a.gd piege.tscn"}, u,
                                {"role": "assistant", "content": "je regarde"}, {"role": "user", "content": "et ?"}], "fait")
    assert f1 == f2
    entete, messages = lire_session(f2)
    assert entete["echanges"] == 2 and messages[0]["content"] == "fichiers : a.gd piege.tscn"


def test_meme_demande_dans_une_nouvelle_conversation_ouvre_une_autre_session(tmp_path):
    enr = Enregistreur(tmp_path)
    m = [{"role": "system", "content": "S"}, {"role": "user", "content": "Ajoute un piège"}]
    f1 = _echange_complet(enr, m, "r1")
    _echange_complet(enr, m + [{"role": "assistant", "content": "r1"}, {"role": "user", "content": "suite"}], "r2")
    f3 = _echange_complet(enr, m, "autre réponse")  # nouvelle conversation, même premier message
    assert f3 != f1
    assert lire_session(f1)[0]["echanges"] == 2  # la première n'est pas écrasée


def test_requete_de_titre_ne_capte_pas_la_conversation(tmp_path):
    enr = Enregistreur(tmp_path)
    u = {"role": "user", "content": "Ajoute un piège"}
    principal = _echange_complet(enr, [{"role": "system", "content": "Tu es OpenCode."}, u], "je regarde")
    titre = _echange_complet(enr, [{"role": "system", "content": "Donne un titre."}, u], "Piège", outils=())
    suite = _echange_complet(enr, [{"role": "system", "content": "Tu es OpenCode."}, u,
                                   {"role": "assistant", "content": "je regarde"}, {"role": "user", "content": "go"}], "ok")
    assert titre != principal and suite == principal


def test_reponse_gzip_enregistree_decompressee(tmp_path):
    import gzip
    enr = Enregistreur(tmp_path)
    corps = json.dumps({"model": "q", "messages": [{"role": "user", "content": "x"}]}).encode()
    rep = gzip.compress(json.dumps({"choices": [{"index": 0, "message": {"role": "assistant", "content": "é"}}]}).encode())
    f = enr.enregistrer("/v1/chat/completions", corps, 200, {"content-type": "application/json",
                                                             "content-encoding": "gzip"}, rep)
    assert lire_session(f)[1][-1] == {"role": "assistant", "content": "é"}


def test_outils_usine_appel_direct_et_code_mode():
    from usine.capture.enregistreur import outils_usine
    messages = [
        {"role": "assistant", "content": None, "tool_calls": [
            {"id": "1", "type": "function", "function": {"name": "usine-godot_scene_write", "arguments": "{}"}}]},
        {"role": "tool", "tool_call_id": "1", "content": "usine-godot_faux (résultat, ignoré)"},
        {"role": "assistant", "content": None, "tool_calls": [
            {"id": "2", "type": "function", "function": {"name": "code", "arguments": json.dumps(
                {"code": "const v = await tools[\"usine-godot\"].run_tests({});\nawait tools['godot-ai'].x()"})}}]}]
    assert outils_usine(messages) == ["scene_write", "run_tests"]
