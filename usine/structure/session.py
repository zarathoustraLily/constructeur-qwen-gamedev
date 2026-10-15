"""Tri d'une session (béquille, points 3 et 10) : une session saine, sans modèle.

- le plan (ORGANISATION.md ou plan.md) a été lu avant la première écriture ;
- chaque fichier écrit est dans un dossier du plan ;
- aucune écriture n'en répète une autre à l'identique (même fichier, même contenu) ;
- chaque capture d'écran est suivie d'un verdict écrit (le message suivant de Qwen a du texte) ;
- QA-03 : après un prepare_action, chaque fichier écrit a été déclaré (sauf plan.md) ;
- QA-07 : aucun test n'est annoncé vert sans un run_tests réussi juste avant.
QA-08 (compte rendu final : fichiers et tests) est relevé sans faire échouer la session : il
compte dans les violations qui classent les sessions réussies (usine/rft/filtre.py).
Détection textuelle, déterministe : les motifs sont ci-dessous.
Les messages sont au format chat OpenAI de l'enregistreur (role, content, tool_calls).
"""

from __future__ import annotations

import hashlib
import json
import re
from typing import Any, Iterable

from usine.structure.regles import DOSSIERS, FICHIERS_RACINE, dossier_de

PLANS = ("ORGANISATION.md", "plan.md")
LECTURES = {"read_file", "read", "view"}
ECRITURES = {"write_file", "write", "edit"}
CAPTURES = {"capture_frames", "capture_ecran"}
# Annonce de tests verts, en français ou en anglais.
ANNONCE_VERTS = re.compile(r"\b(tests?|suites?)\b[^.\n]{0,40}\b(verts?|passent|réussi(?:s|ssent)?|ok|pass(?:es|ed|ing)?|green)\b"
                           r"|\b(?:tout|tous)\b[^.\n]{0,20}\bvert", re.I)
FICHIER_CITE = re.compile(r"[\w/.-]+\.(?:gd|tscn|tres)\b")


def _nom_court(nom: str) -> str:
    """« godot-usine_run_tests » (préfixe d'OpenCode) → « run_tests »."""
    for connu in ("run_tests", "prepare_action"):
        if nom.endswith(connu):
            return connu
    return nom


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


def _relatif(chemin: str) -> str:
    return chemin.replace("\\", "/").removeprefix("res://").lstrip("./")


def _non_declarees(messages: list[dict[str, Any]]) -> list[str] | None:
    """QA-03 : écritures hors des fichiers déclarés à prepare_action ; None si rien n'a été déclaré."""
    declares: set[str] | None = None
    hors: list[str] = []
    for nom, args in _appels(messages):
        if _nom_court(nom) == "prepare_action":
            declares = (declares or set()) | {_relatif(str(f)) for f in args.get("fichiers") or []}
        elif nom in ECRITURES and declares is not None:
            rel = _relatif(_chemin(args))
            if rel.rsplit("/", 1)[-1] not in PLANS and not any(rel == d or rel.endswith("/" + d) for d in declares):
                hors.append("res://" + rel)
    return None if declares is None else hors


def _annonces_sans_test(messages: list[dict[str, Any]]) -> int:
    """QA-07 : messages qui annoncent des tests verts sans run_tests réussi depuis la dernière écriture."""
    resultats: dict[str, str] = {}
    dernier_ok: bool | None = None
    manques = 0
    for m in messages:
        if m.get("role") == "tool" and m.get("tool_call_id") in resultats:
            texte = str(m.get("content") or "")
            dernier_ok = '"ok":true' in texte.replace(" ", "") and '"echecs":[]' in texte.replace(" ", "")
            continue
        if m.get("role") != "assistant":
            continue
        if ANNONCE_VERTS.search(str(m.get("content") or "")) and dernier_ok is not True:
            manques += 1
        for appel in m.get("tool_calls") or []:
            nom = _nom_court((appel.get("function") or {}).get("name", ""))
            if nom == "run_tests":
                resultats[appel.get("id", "")] = nom
            elif nom in ECRITURES:
                dernier_ok = None  # le code a changé : le dernier résultat ne vaut plus
    return manques


def _compte_rendu(messages: list[dict[str, Any]]) -> bool:
    """QA-08 : le dernier message de Qwen est un compte rendu (fichiers cités et tests)."""
    dernier = next((m for m in reversed(messages) if m.get("role") == "assistant"), None)
    texte = str((dernier or {}).get("content") or "")
    return bool(FICHIER_CITE.search(texte)) and re.search(r"\btests?\b", texte, re.I) is not None


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
    non_declarees = _non_declarees(messages)
    annonces = _annonces_sans_test(messages)
    compte_rendu = _compte_rendu(messages)
    regles = {"QA-03": len(non_declarees or []), "QA-07": annonces, "QA-08": 0 if compte_rendu else 1}
    return {
        "ok": (plan_avant_ecriture is not False and not hors_plan and repetees == 0 and sans_verdict == 0
               and not non_declarees and annonces == 0),
        "ecritures_non_declarees": non_declarees,
        "tests_annonces_sans_preuve": annonces,
        "compte_rendu": compte_rendu,
        "regles": {k: v for k, v in regles.items() if v},
        "plan_lu_avant_ecriture": plan_avant_ecriture,
        "ecritures_hors_plan": hors_plan,
        "ecritures_repetees": repetees,
        "captures_sans_verdict": sans_verdict,
        "dossiers_du_plan": list(DOSSIERS),
    }
