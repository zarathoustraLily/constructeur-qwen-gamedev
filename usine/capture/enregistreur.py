"""Enregistreur des échanges OpenAI-compatibles → sessions JSONL (format de CLAUDE.md).

Une session = une conversation d'OpenCode. OpenCode renvoie à chaque tour toute la
conversation. Une requête continue la session qui partage avec elle le plus long début de
conversation (messages hors `system`, au moins le premier message utilisateur), à condition
d'avoir plus de messages qu'elle : une nouvelle conversation qui commence par la même demande
ouvre donc une autre session. Le prompt système peut changer d'un tour à l'autre (date, liste
de fichiers) sans couper la session ; à égalité, on préfère la session de même prompt système
et de mêmes outils (une requête annexe, comme la génération du titre, n'a ni l'un ni l'autre),
puis la plus récente. Le fichier de la session est réécrit (atomiquement) à chaque échange :
en-tête, puis les messages de la dernière requête, puis la réponse.

    donnees/sessions/<AAAAMMJJ-HHMMSS>_<id>.jsonl
      {"tache_id": null, "competence": null, "verdict_final": null, "session": id, ...}
      {"role": "system", "content": "..."}
      {"role": "user", "content": "..."}
      {"role": "assistant", "content": null, "tool_calls": [...]}
      {"role": "tool", "tool_call_id": "...", "content": "..."}
      ...
    donnees/sessions/brut/<AAAAMMJJ>.jsonl     un échange brut par ligne (requête, réponse telle quelle)

tache_id, competence et verdict_final restent null à la capture : la boucle RFT (session 5)
ou un tri manuel les renseignent.
"""

from __future__ import annotations

import gzip
import hashlib
import json
import os
import re
import tempfile
import threading
import time
from pathlib import Path
from typing import Any

CHAMPS_MESSAGE = ("role", "content", "tool_calls", "tool_call_id", "name", "reasoning_content")


def _empreinte(objet: Any) -> str:
    return hashlib.sha256(json.dumps(objet, sort_keys=True, ensure_ascii=False).encode("utf-8")).hexdigest()


def message_normalise(m: dict[str, Any]) -> dict[str, Any]:
    """Message au format de session : seulement les champs OpenAI utiles, dans un ordre fixe."""
    sortie = {k: m[k] for k in CHAMPS_MESSAGE if k in m and m[k] is not None}
    sortie.setdefault("role", m.get("role"))
    if "content" not in sortie:
        sortie["content"] = None
    return sortie


def cle_message(m: dict[str, Any]) -> str:
    """Identité d'un message pour reconnaître une conversation qui continue."""
    appels = [(c.get("id"), (c.get("function") or {}).get("name"), (c.get("function") or {}).get("arguments"))
              for c in (m.get("tool_calls") or [])]
    return _empreinte([m.get("role"), m.get("content"), m.get("tool_call_id"), appels])


def reponse_depuis_sse(corps: bytes) -> dict[str, Any]:
    """Recompose le message assistant d'un flux SSE `chat.completion.chunk`."""
    message: dict[str, Any] = {"role": "assistant", "content": None}
    appels: dict[int, dict[str, Any]] = {}
    fin = None
    usage = None
    modele = None
    for ligne in corps.decode("utf-8", errors="replace").splitlines():
        ligne = ligne.strip()
        if not ligne.startswith("data:"):
            continue
        donnee = ligne[5:].strip()
        if donnee == "[DONE]":
            break
        try:
            morceau = json.loads(donnee)
        except json.JSONDecodeError:
            continue
        modele = morceau.get("model", modele)
        usage = morceau.get("usage") or usage
        for choix in morceau.get("choices") or []:
            if choix.get("index", 0) != 0:
                continue
            delta = choix.get("delta") or {}
            for champ in ("content", "reasoning_content"):
                if delta.get(champ):
                    message[champ] = (message.get(champ) or "") + delta[champ]
            for appel in delta.get("tool_calls") or []:
                a = appels.setdefault(appel.get("index", len(appels)),
                                      {"id": None, "type": "function", "function": {"name": "", "arguments": ""}})
                if appel.get("id"):
                    a["id"] = appel["id"]
                if appel.get("type"):
                    a["type"] = appel["type"]
                f = appel.get("function") or {}
                if f.get("name"):
                    a["function"]["name"] += f["name"]
                if f.get("arguments"):
                    a["function"]["arguments"] += f["arguments"]
            fin = choix.get("finish_reason") or fin
    if appels:
        message["tool_calls"] = [appels[i] for i in sorted(appels)]
    return {"message": message, "finish_reason": fin, "usage": usage, "model": modele}


def reponse_depuis_json(corps: bytes) -> dict[str, Any]:
    donnees = json.loads(corps.decode("utf-8"))
    choix = (donnees.get("choices") or [{}])[0]
    return {"message": dict(choix.get("message") or {"role": "assistant", "content": None}),
            "finish_reason": choix.get("finish_reason"), "usage": donnees.get("usage"), "model": donnees.get("model")}


class Enregistreur:
    def __init__(self, dossier: Path):
        self.dossier = Path(dossier)
        self.verrou = threading.Lock()
        # session → {"cles": clés des messages de la dernière requête, "fichier", "debut", "echanges"}
        self.sessions: dict[str, dict[str, Any]] = {}

    def _session_pour(self, cles: list[str], systeme: str, outils: str) -> str | None:
        meilleure, rang = None, None
        for ordre, (ident, s) in enumerate(self.sessions.items()):
            if len(cles) <= len(s["cles"]):
                continue
            commun = 0
            while commun < len(s["cles"]) and cles[commun] == s["cles"][commun]:
                commun += 1
            if commun == 0:
                continue
            r = (commun, s["systeme"] == systeme, s["outils"] == outils, ordre)
            if rang is None or r > rang:
                meilleure, rang = ident, r
        return meilleure

    def enregistrer(self, chemin: str, requete: bytes, statut: int, entetes: dict[str, str], reponse: bytes) -> Path | None:
        """Enregistre un échange /chat/completions. Ne lève jamais vers le proxy."""
        maintenant = time.time()
        horodatage = time.strftime("%Y-%m-%dT%H:%M:%S", time.localtime(maintenant))
        try:
            corps = json.loads(requete.decode("utf-8")) if requete else {}
        except (UnicodeDecodeError, json.JSONDecodeError):
            corps = None
        if entetes.get("content-encoding", "").lower() == "gzip":
            try:
                reponse = gzip.decompress(reponse)  # copie décompressée pour l'enregistrement seulement
            except (OSError, EOFError):
                pass
        with self.verrou:
            self._brut(maintenant, {"horodatage": horodatage, "chemin": chemin, "statut": statut,
                                    "requete": corps if corps is not None else requete.decode("utf-8", "replace"),
                                    "reponse": reponse.decode("utf-8", "replace")})
            if not isinstance(corps, dict) or statut != 200 or not isinstance(corps.get("messages"), list):
                return None
            flux = "text/event-stream" in entetes.get("content-type", "").lower() or bool(corps.get("stream"))
            try:
                rep = reponse_depuis_sse(reponse) if flux else reponse_depuis_json(reponse)
            except (UnicodeDecodeError, json.JSONDecodeError):
                return None
            messages = [message_normalise(m) for m in corps["messages"] if isinstance(m, dict)]
            cles = [cle_message(m) for m in messages if m.get("role") != "system"]
            systeme = _empreinte([m.get("content") for m in messages if m.get("role") == "system"])
            outils = _empreinte(sorted(((t.get("function") or {}).get("name") or "")
                                       for t in corps.get("tools") or [] if isinstance(t, dict)))
            ident = self._session_pour(cles, systeme, outils)
            if ident is None:
                ident = _empreinte([horodatage, cles[:1], len(self.sessions)])[:12]
                nom = time.strftime("%Y%m%d-%H%M%S", time.localtime(maintenant)) + f"_{ident}.jsonl"
                self.sessions[ident] = {"fichier": self.dossier / nom, "debut": horodatage, "echanges": 0}
            s = self.sessions[ident]
            s.update({"cles": cles, "systeme": systeme, "outils": outils})
            s["echanges"] += 1
            entete = {"tache_id": None, "competence": None, "verdict_final": None, "session": ident,
                      "source": "capture", "debut": s["debut"], "fin": horodatage, "echanges": s["echanges"],
                      "modele": corps.get("model"), "finish_reason": rep["finish_reason"], "usage": rep["usage"],
                      "tools": corps.get("tools") or []}
            lignes = [entete] + messages + [message_normalise(rep["message"])]
            _ecrire_atomique(s["fichier"], "".join(json.dumps(l, ensure_ascii=False) + "\n" for l in lignes))
            return s["fichier"]

    def _brut(self, instant: float, entree: dict[str, Any]) -> None:
        dossier = self.dossier / "brut"
        dossier.mkdir(parents=True, exist_ok=True)
        with (dossier / (time.strftime("%Y%m%d", time.localtime(instant)) + ".jsonl")).open("a", encoding="utf-8") as f:
            f.write(json.dumps(entree, ensure_ascii=False) + "\n")


def _ecrire_atomique(chemin: Path, texte: str) -> None:
    chemin.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix=f".{chemin.name}.", dir=chemin.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as f:
            f.write(texte)
        os.replace(tmp, chemin)
    except BaseException:
        Path(tmp).unlink(missing_ok=True)
        raise


RE_OUTIL_USINE = re.compile(r"""usine-godot(?:_|\\?["']\s*\]\s*\.\s*)([A-Za-z_]\w*)""")


def outils_usine(messages: list[dict[str, Any]]) -> list[str]:
    """Outils de l'usine appelés par l'assistant, dans l'ordre : appel direct (`usine-godot_run_tests`)
    ou via le Code Mode d'OpenCode (`tools["usine-godot"].run_tests({...})` dans le code envoyé)."""
    vus: list[str] = []
    for m in messages:
        if m.get("role") != "assistant":
            continue
        for appel in m.get("tool_calls") or []:
            f = appel.get("function") or {}
            vus += RE_OUTIL_USINE.findall(f.get("name") or "")
            vus += RE_OUTIL_USINE.findall(f.get("arguments") or "")
    return vus


def lire_session(chemin: Path) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    lignes = [json.loads(l) for l in Path(chemin).read_text(encoding="utf-8").splitlines() if l.strip()]
    return lignes[0], lignes[1:]
