"""Tri d'une session (béquille, points 3 et 10) : une session saine, sans modèle.

- le plan (ORGANISATION.md ou plan.md) a été lu avant la première écriture ;
- chaque fichier écrit est dans un dossier du plan ;
- aucune écriture n'en répète une autre à l'identique (même fichier, même contenu) ;
- chaque capture d'écran est suivie d'un verdict écrit (le message suivant de Qwen a du texte).
Les messages sont au format chat OpenAI de l'enregistreur (role, content, tool_calls).
"""

from __future__ import annotations

import hashlib
import json
from typing import Any, Iterable

from usine.structure.regles import DOSSIERS, FICHIERS_RACINE, dossier_de

PLANS = ("ORGANISATION.md", "plan.md")
LECTURES = {"read_file", "read", "view"}
ECRITURES = {"write_file", "write", "edit"}
CAPTURES = {"capture_frames", "capture_ecran"}


def _appels(messages: Iterable[dict[str, Any]]):
    for m in messages:
        for appel in m.get("tool_calls") or []:
            f = appel.get("function") or {}
            try:
                args = json.loads(f.get("arguments") or "{}")
            except json.JSONDecodeError:
                args = {}
            yield f.get("name", ""), args if isinstance(args, dict) else {}


def _chemin(args: dict[str, Any]) -> str:
    chemin = str(args.get("chemin") or args.get("path") or args.get("filePath") or "").replace("\\", "/")
    return chemin if chemin.startswith("res://") else "res://" + chemin.lstrip("./")


def _captures_sans_verdict(messages: list[dict[str, Any]]) -> int:
    """Captures après lesquelles le message suivant de Qwen n'a aucun texte."""
    manques = 0
    for i, m in enumerate(messages):
        if m.get("role") != "assistant" or not any((a.get("function") or {}).get("name") in CAPTURES
                                                   for a in m.get("tool_calls") or []):
            continue
        suivant = next((n for n in messages[i + 1:] if n.get("role") == "assistant"), None)
        manques += suivant is not None and not str(suivant.get("content") or "").strip()
    return manques


def verifier_session(messages: Iterable[dict[str, Any]]) -> dict[str, Any]:
    messages = list(messages)
    plan_lu = False
    plan_avant_ecriture: bool | None = None
    hors_plan: list[str] = []
    repetees = 0
    vues: set[tuple[str, str]] = set()
    for nom, args in _appels(messages):
        if nom in LECTURES and _chemin(args).rsplit("/", 1)[-1] in PLANS:
            plan_lu = True
        if nom not in ECRITURES:
            continue
        chemin = _chemin(args)
        if plan_avant_ecriture is None:
            plan_avant_ecriture = plan_lu
        nom_fichier = chemin.rsplit("/", 1)[-1]
        if dossier_de(chemin) is None and not (chemin.count("/") == 2 and nom_fichier in FICHIERS_RACINE):
            hors_plan.append(chemin)
        contenu = str(args.get("contenu") or args.get("content") or args.get("newString") or "")
        cle = (chemin, hashlib.sha256(contenu.encode()).hexdigest())
        repetees += cle in vues
        vues.add(cle)
    sans_verdict = _captures_sans_verdict(messages)
    return {
        "ok": plan_avant_ecriture is not False and not hors_plan and repetees == 0 and sans_verdict == 0,
        "plan_lu_avant_ecriture": plan_avant_ecriture,
        "ecritures_hors_plan": hors_plan,
        "ecritures_repetees": repetees,
        "captures_sans_verdict": sans_verdict,
        "dossiers_du_plan": list(DOSSIERS),
    }
