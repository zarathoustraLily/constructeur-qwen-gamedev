"""Preuve du proxy de capture : un faux serveur OpenAI rejoue un échange scripté.

Le scénario imite OpenCode sur une petite fonctionnalité : Qwen appelle `scene_write`
(réponse en flux SSE, arguments découpés en plusieurs morceaux), puis `run_tests`
(réponse JSON d'un bloc), puis conclut (flux SSE, texte accentué). Chaque requête passe
par le proxy ; on vérifie :
- requête reçue par le serveur = requête envoyée par le client (octets du corps) ;
- réponse reçue par le client = réponse scriptée (octets), en-tête Content-Type identique ;
- flux : le premier morceau arrive avant que le serveur ait fini d'envoyer ;
- une seule session enregistrée, 3 échanges, appels d'outils scene_write puis run_tests.
"""

from __future__ import annotations

import http.client
import json
import tempfile
import time
from pathlib import Path
from typing import Any

from usine.capture.enregistreur import lire_session
from usine.capture.faux_serveur import FauxServeur, morceaux_sse
from usine.capture.proxy import ProxyCapture

PAUSE_S = 0.05


def _chunk(delta: dict[str, Any], fin: str | None = None) -> dict[str, Any]:
    return {"id": "chatcmpl-1", "object": "chat.completion.chunk", "model": "qwen3.8-27b",
            "choices": [{"index": 0, "delta": delta, "finish_reason": fin}]}


SPEC = {"racine": {"nom": "Piege", "type": "Area2D", "enfants": [
    {"nom": "CollisionShape2D", "type": "CollisionShape2D"}]}}
ARGS_SCENE = json.dumps({"chemin": "res://scenes/piege.tscn", "spec": SPEC}, ensure_ascii=False)


def scenario() -> list[dict[str, Any]]:
    morceaux_args = [ARGS_SCENE[i:i + 20] for i in range(0, len(ARGS_SCENE), 20)]
    appel1 = [_chunk({"role": "assistant", "content": None, "tool_calls": [
        {"index": 0, "id": "appel_1", "type": "function", "function": {"name": "usine-godot_scene_write", "arguments": ""}}]})]
    appel1 += [_chunk({"tool_calls": [{"index": 0, "function": {"arguments": a}}]}) for a in morceaux_args]
    appel1 += [_chunk({}, "tool_calls")]
    reponse2 = {"id": "chatcmpl-2", "object": "chat.completion", "model": "qwen3.8-27b",
                "choices": [{"index": 0, "finish_reason": "tool_calls", "message": {
                    "role": "assistant", "content": None, "tool_calls": [
                        {"id": "appel_2", "type": "function",
                         "function": {"name": "usine-godot_run_tests", "arguments": "{}"}}]}}],
                "usage": {"prompt_tokens": 900, "completion_tokens": 12, "total_tokens": 912}}
    final = [_chunk({"role": "assistant", "content": ""})]
    final += [_chunk({"content": t}) for t in ["Le piège ", "est ajouté ; ", "les 37 tests ", "passent. ✓"]]
    final += [_chunk({}, "stop")]
    return [{"flux": True, "morceaux": morceaux_sse(appel1), "pause_s": PAUSE_S},
            {"flux": False, "corps": reponse2},
            {"flux": True, "morceaux": morceaux_sse(final), "pause_s": PAUSE_S}]


def requetes() -> list[dict[str, Any]]:
    outils = [{"type": "function", "function": {"name": f"usine-godot_{n}", "description": "…",
                                                "parameters": {"type": "object", "properties": {}}}}
              for n in ("scene_write", "run_tests")]
    m = [{"role": "system", "content": "Tu es OpenCode."},
         {"role": "user", "content": "Ajoute un piège à pointes à la scène principale."}]
    r1 = {"model": "qwen3.8-27b", "stream": True, "messages": list(m), "tools": outils}
    m += [{"role": "assistant", "content": None, "tool_calls": [
              {"id": "appel_1", "type": "function", "function": {"name": "usine-godot_scene_write", "arguments": ARGS_SCENE}}]},
          {"role": "tool", "tool_call_id": "appel_1", "content": '{"ok":true,"etape":"load_scene","applique":true}'}]
    r2 = {"model": "qwen3.8-27b", "stream": False, "messages": list(m), "tools": outils}
    m += [{"role": "assistant", "content": None, "tool_calls": [
              {"id": "appel_2", "type": "function", "function": {"name": "usine-godot_run_tests", "arguments": "{}"}}]},
          {"role": "tool", "tool_call_id": "appel_2", "content": '{"ok":true,"tests":{"total":37,"passes":37,"echecs":[]}}'}]
    r3 = {"model": "qwen3.8-27b", "stream": True, "messages": list(m), "tools": outils}
    return [r1, r2, r3]


def _envoyer(port: int, methode: str, chemin: str, corps: bytes | None) -> tuple[int, dict[str, str], bytes, float, float]:
    """(statut, en-têtes, corps, délai du premier morceau, durée totale)."""
    con = http.client.HTTPConnection("127.0.0.1", port, timeout=30)
    debut = time.monotonic()
    entetes = {"Content-Type": "application/json", "Authorization": "Bearer sk-local"} if corps else {}
    con.request(methode, chemin, body=corps, headers=entetes)
    rep = con.getresponse()
    premier = None
    recu = bytearray()
    while True:
        m = rep.read1(65536)
        if not m:
            break
        if premier is None:
            premier = time.monotonic() - debut
        recu += m
    con.close()
    return rep.status, {k.lower(): v for k, v in rep.getheaders()}, bytes(recu), premier or 0.0, time.monotonic() - debut


def executer_preuve(dossier: Path) -> dict[str, Any]:
    scen = scenario()
    faux = FauxServeur(scen)
    faux.demarrer_en_fond()
    proxy = ProxyCapture(0, faux.url, dossier)
    proxy.demarrer_en_fond()
    lignes = []
    ok = True
    try:
        st, en, corps, _, _ = _envoyer(proxy.port, "GET", "/v1/models", None)
        conforme = st == 200 and json.loads(corps)["data"][0]["id"] == "qwen3.8-27b"
        ok &= conforme
        lignes.append(("GET /v1/models", "relayé" if conforme else "ÉCHEC"))
        for i, (req, rep) in enumerate(zip(requetes(), scen), 1):
            octets = json.dumps(req, ensure_ascii=False).encode("utf-8")
            st, en, corps, premier, total = _envoyer(proxy.port, "POST", "/v1/chat/completions", octets)
            attendu = "".join(rep["morceaux"]).encode("utf-8") if rep["flux"] \
                else json.dumps(rep["corps"], ensure_ascii=False).encode("utf-8")
            requete_identique = faux.recues[-1]["corps"] == octets
            reponse_identique = corps == attendu
            type_identique = en.get("content-type") == ("text/event-stream" if rep["flux"] else "application/json; charset=utf-8")
            progressif = (premier < total - PAUSE_S * 3) if rep["flux"] else True
            conforme = st == 200 and requete_identique and reponse_identique and type_identique and progressif
            ok &= conforme
            mode = "SSE" if rep["flux"] else "JSON"
            lignes.append((f"POST chat/completions #{i} ({mode})",
                           f"requête {'=' if requete_identique else '≠'}  réponse {len(corps)} octets "
                           f"{'=' if reponse_identique else '≠'} script  type {'=' if type_identique else '≠'}"
                           + (f"  1er morceau à {premier:.2f} s / {total:.2f} s" if rep["flux"] else "")
                           + ("" if conforme else "  ÉCHEC")))
    finally:
        proxy.shutdown()
        proxy.server_close()
        faux.shutdown()
        faux.server_close()
    sessions = sorted(Path(dossier).glob("*.jsonl"))
    resume: dict[str, Any] = {"sessions": len(sessions)}
    if len(sessions) == 1:
        entete, messages = lire_session(sessions[0])
        appels = [c["function"]["name"] for m in messages for c in (m.get("tool_calls") or [])]
        resume.update({"echanges": entete["echanges"], "messages": len(messages), "appels": appels,
                       "dernier": messages[-1], "entete_ok": all(k in entete for k in ("tache_id", "competence", "verdict_final")),
                       "args_scene_write": json.loads(messages[2]["tool_calls"][0]["function"]["arguments"]) == json.loads(ARGS_SCENE)})
        ok &= (resume["echanges"] == 3 and appels == ["usine-godot_scene_write", "usine-godot_run_tests"]
               and messages[-1] == {"role": "assistant", "content": "Le piège est ajouté ; les 37 tests passent. ✓"}
               and resume["entete_ok"] and resume["args_scene_write"] and len(messages) == 7)
    else:
        ok = False
    return {"ok": ok, "lignes": lignes, "session": resume}


def preuve() -> int:
    with tempfile.TemporaryDirectory(prefix="usine_capture_") as tmp:
        r = executer_preuve(Path(tmp))
    for a, b in r["lignes"]:
        print(f"{a:<34} {b}")
    s = r["session"]
    print(f"sessions enregistrées : {s['sessions']}")
    if s["sessions"] == 1:
        print(f"session : {s['echanges']} échanges, {s['messages']} messages, en-tête tache_id/competence/verdict_final : "
              f"{'oui' if s['entete_ok'] else 'NON'}")
        print(f"appels d'outils : {' → '.join(s['appels'])}")
        print(f"arguments de scene_write recomposés depuis le flux : {'identiques' if s['args_scene_write'] else 'DIFFÉRENTS'}")
        print(f"dernier message : {json.dumps(s['dernier'], ensure_ascii=False)}")
    print("CONFORME" if r["ok"] else "NON CONFORME")
    return 0 if r["ok"] else 1
