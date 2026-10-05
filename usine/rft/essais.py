"""Essais : Qwen résout une tâche N fois, le juge note chaque essai, la session est enregistrée.

Compétences en un appel (D1, F1, K1, S1, S2) : appel direct à llama-server, sortie contrainte
par le schéma de la compétence (usine/mesure/reponses.py, les mêmes que pour la mesure), LoRA
choisi par requête (champ `lora`). Les N essais diffèrent par la graine (graine + n°) et une
température > 0 ; sinon les N réponses seraient identiques.

Compétences agentiques : sur une copie de travail de depart/ (socle posé), avec
  - « agent » : l'agent minimal maison (agent.py), mêmes outils que le serveur MCP ;
  - « opencode » : OpenCode en mode non interactif (opencode.py), à confirmer par laurent.
Le juge note ensuite la copie (tests cachés copiés seulement à ce moment, règle 3).

Session enregistrée (format commun de CLAUDE.md) : JSONL, une ligne d'en-tête
{tache_id, competence, verdict_final, …} puis un message par ligne (role, content, tool_calls,
tool_call_id). Fichier : <sessions>/<tache_id>/essai_<n>.jsonl, écrit de façon atomique.
"""

from __future__ import annotations

import json
import tempfile
import time
from dataclasses import dataclass, field, replace
from pathlib import Path
from typing import Any, Callable

from usine.capture.enregistreur import _ecrire_atomique
from usine.mesure import reponses
from usine.mesure.client import ErreurAppel, Reglages, Reponse, completer

HARNAIS = ("agent", "opencode")


@dataclass
class ReglagesRft:
    client: Reglages = field(default_factory=Reglages)
    n_essais: int = 8
    mini_reussites: int = 1                      # filtre de difficulté (usine/portillon/difficulte.py) :
    maxi_reussites: int | None = 6               # au-delà, tâche « acquise », non exportée ; None : sans plafond
    temperature: float = 0.7
    graine: int = 1
    lora: list[dict[str, Any]] | None = None     # champ `lora` des requêtes ; None : réglage du serveur
    avec_rag: bool = False                       # extraits du RAG dans le prompt des compétences en un appel
    n_docs: int = 5
    harnais: str = "agent"                       # compétences agentiques : agent | opencode
    max_pas: int = 40                            # budget de l'agent maison (appels au modèle)
    opencode: dict[str, Any] = field(default_factory=dict)


def reglages_depuis_config(config: dict[str, Any] | None = None) -> ReglagesRft:
    from usine import config as cfg
    from usine.mesure.executer import reglages_depuis_config as reglages_mesure
    config = cfg.charger_config() if config is None else config
    rft = config.get("rft", {})
    client = reglages_mesure(config).client
    lora_id = rft.get("lora_id")
    maxi = rft.get("maxi_reussites", 6)
    return ReglagesRft(client=client, n_essais=int(rft.get("n_essais", 8)),
                       mini_reussites=int(rft.get("mini_reussites", 1)),
                       maxi_reussites=None if maxi is None or int(maxi) < 0 else int(maxi),
                       temperature=float(rft.get("temperature", 0.7)), graine=int(rft.get("graine", 1)),
                       lora=None if lora_id is None or lora_id == -1 else [{"id": int(lora_id), "scale": 1.0}],
                       avec_rag=bool(rft.get("avec_rag", False)), n_docs=int(rft.get("n_docs", 5)),
                       harnais=str(rft.get("harnais", "agent")), max_pas=int(rft.get("max_pas", 40)),
                       opencode=dict(config.get("opencode", {})))


@dataclass
class Essai:
    tache_id: str
    competence: str
    essai: int
    ok: bool
    etape: str
    longueur: int
    duree_s: float
    session: str          # chemin relatif au dossier des sessions


def longueur(messages: list[dict[str, Any]]) -> int:
    """Taille de ce que le modèle a produit : contenu et appels d'outils des messages assistant."""
    n = 0
    for m in messages:
        if m.get("role") == "assistant":
            n += len(m.get("content") or "")
            n += sum(len(c["function"]["name"]) + len(c["function"]["arguments"]) for c in m.get("tool_calls") or [])
    return n


def ecrire_session(chemin: Path, entete: dict[str, Any], messages: list[dict[str, Any]]) -> None:
    lignes = [entete] + messages
    _ecrire_atomique(chemin, "".join(json.dumps(l, ensure_ascii=False, sort_keys=True) + "\n" for l in lignes))


def _resume(verdict: dict[str, Any]) -> dict[str, Any]:
    return {k: verdict.get(k) for k in ("ok", "etape", "duree_s", "erreurs", "tests")}


def essayer(dossier: Path, n: int, r: ReglagesRft, sessions: Path,
            appeler: Callable[..., Reponse] = completer,
            juger_un_appel: Callable[[Path, str], dict[str, Any]] = reponses.juger_reponse,
            juger_projet: Callable[[Path, Path], dict[str, Any]] | None = None) -> Essai:
    """Essai n° n sur la tâche `dossier`. Écrit la session, renvoie le résumé."""
    from usine.taches import juger_tache, lire_tache
    dossier = Path(dossier)
    tache = lire_tache(dossier)
    comp = tache["competence"]
    client = replace(r.client, temperature=r.temperature, graine=r.graine + n)
    debut = time.monotonic()
    outils: list[dict[str, Any]] = []
    fin = None
    if comp in reponses.COMPETENCES_UN_APPEL:
        docs = None
        if r.avec_rag:
            from usine.mesure.executer import ReglagesMesure, documentation
            docs = documentation(tache["consigne"], ReglagesMesure(n_docs=r.n_docs))
        messages = reponses.messages(dossier / "depart", tache["consigne"], comp, docs)
        try:
            rep = appeler(client, messages, reponses.SCHEMAS[comp], r.lora)
            texte, fin = rep.contenu, rep.fin
            messages = messages + [{"role": "assistant", "content": texte}]
            verdict = juger_un_appel(dossier, texte)
        except ErreurAppel as exc:
            verdict = reponses.verdict_reponse_invalide(f"appel en échec : {exc}", tache["id"])
            fin = "erreur_appel"
        harnais = "appel"
    else:
        from usine.juge.projet import preparer_copie
        juger = juger_projet or (lambda d, copie: juger_tache(d, candidat=copie))
        with tempfile.TemporaryDirectory(prefix="usine_rft_") as tmp:
            copie = preparer_copie(dossier / "depart", Path(tmp) / "projet")
            if r.harnais == "agent":
                from usine.rft import agent
                messages, outils, fin = agent.resoudre(copie, tache["consigne"], comp, client, r.lora, r.max_pas, appeler)
            elif r.harnais == "opencode":
                from usine.rft import opencode
                messages, outils, fin = opencode.resoudre(copie, tache["consigne"], comp, client, r.opencode)
            else:
                raise ValueError(f"harnais inconnu : {r.harnais} (attendu : {', '.join(HARNAIS)})")
            verdict = juger(dossier, copie)
        harnais = r.harnais
    duree = round(time.monotonic() - debut, 3)
    rel = Path(tache["id"]) / f"essai_{n}.jsonl"
    entete = {"tache_id": tache["id"], "competence": comp, "empreinte": tache["empreinte"],
              "verdict_final": _resume(verdict), "essai": n, "harnais": harnais, "graine": client.graine,
              "temperature": client.temperature, "lora": r.lora, "fin": fin, "duree_s": duree, "tools": outils}
    ecrire_session(Path(sessions) / rel, entete, messages)
    return Essai(tache["id"], comp, n, bool(verdict["ok"]), str(verdict.get("etape")), longueur(messages), duree,
                 rel.as_posix())
