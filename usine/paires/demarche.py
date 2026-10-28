"""Famille de paires « la démarche » : comment on crée un niveau, pas à pas (demande de laurent du 2026-10-28 : « créer
un système qui enseigne à Qwen ta démarche pour créer le niveau »).

Un cours de jeu tient son journal de démarche (`cours/<nom>/demarche.json`) : chaque pas est une décision réellement
prise en construisant le niveau, avec la situation, ce qu'on se demande, l'outil d'OpenCode employé pour le savoir
(recherche dans la documentation, vocabulaire de l'API), ce qu'on lit dans la sortie et ce qu'on décide. Chaque pas
devient une paire en plusieurs tours, comme à l'usage :
1. la situation (la demande) ;
2. la réponse dit pourquoi elle cherche, puis appelle l'outil `execute` du Code Mode
   (`tools["usine-godot"].search_docs({…})` ou `.vocab_lookup({…})`, la forme des paires RAG) ;
3. la vraie sortie de l'outil, rejouée maintenant par la classe qui sert le serveur MCP (`mcp_serveur.outils`) ;
4. la réponse lit la sortie (en la citant) et décide.

Vérification déterministe (décision 18.1) : le pas est écarté si un fragment attendu manque à la sortie rejouée, ou si
une citation de la lecture (entre « ») ne s'y trouve pas mot pour mot. Palier 1 (1 024 jetons, sans le plan) quand la
réponse ne cite aucune convention du plan (exception de la section 3 : requête au RAG, lecture d'une sortie) ; sinon
palier 2, plan compris.

    python -m usine.paires demarche
"""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any, Callable

from usine import config as cfg
from usine.paires import format as fmt

FAMILLE = "demarche"
PLAFONDS = {1: 1024, 2: 2048}
CODES = {
    "rag": 'return await tools["usine-godot"].search_docs({{ requete: "{requete}", n: {n} }});',
    "vocab": 'return await tools["usine-godot"].vocab_lookup({{ classe: "{classe}", membre: "{membre}" }});',
}
CITATION = re.compile(r"«\s*(.+?)\s*»", re.S)
CONVENTION = re.compile(r"\b[0-7]_[a-z]+/")  # un dossier du plan (1_core/, 5_data/…) : la réponse dépend du plan


def _outils() -> Any:
    from mcp_serveur.outils import Outils
    return Outils(cfg.RACINE / "godot" / "reference")


def rejouer(outil: dict[str, Any], outils: Any) -> tuple[str, str]:
    """(code du Code Mode, sortie réelle) de l'outil d'un pas."""
    genre = outil["genre"]
    if genre == "rag":
        return CODES["rag"].format(**outil), outils.search_docs(outil["requete"], int(outil["n"]))
    if genre == "vocab":
        return CODES["vocab"].format(**outil), outils.vocab_lookup(outil["classe"], outil["membre"])
    raise ValueError(f"outil inconnu : {genre}")


def _plat(texte: str) -> str:
    return re.sub(r"\s+", " ", texte).strip()


def verifier(pas: dict[str, Any], sortie: str) -> str:
    """La raison d'écarter le pas, ou "" s'il est vrai : fragments attendus et citations présents dans la sortie."""
    plate = _plat(sortie)
    for fragment in pas["attendu"]:
        if _plat(fragment) not in plate:
            return f"fragment attendu absent de la sortie : {fragment}"
    for citation in CITATION.findall(pas["lecture"]):
        if _plat(citation) not in plate:
            return f"citation absente de la sortie : {citation}"
    return ""


def paire(cours: str, pas: dict[str, Any], outils: Any) -> tuple[dict[str, Any] | None, str]:
    code, sortie = rejouer(pas["outil"], outils)
    raison = verifier(pas, sortie)
    if raison:
        return None, raison
    ident = f"demarche_{pas['id']}"
    tours = [
        {"role": "user", "content": pas["situation"]},
        {"role": "assistant", "content": pas["pensee"], "tool_calls": [fmt.appel(ident, "execute", {"code": code})]},
        {"role": "tool", "tool_call_id": ident, "content": sortie},
        {"role": "assistant", "content": pas["lecture"] + "\n\n" + pas["decision"]},
    ]
    preuve = {"cours": cours, "etape": pas["etape"], "pas": pas["id"], "outil": pas["outil"],
              "attendu": pas["attendu"], "verifie": "sortie rejouée, fragments et citations présents"}
    paliers = (2,) if CONVENTION.search(pas["lecture"] + pas["decision"] + pas["situation"]) else (1, 2)
    for palier in paliers:
        q = fmt.paire_tours(FAMILLE, pas["sujet"], pas["type"], tours, dict(preuve, palier=palier),
                            systeme=fmt.plan() if palier == 2 else None)
        if q["jetons"] <= PLAFONDS[palier]:
            return q, ""
    return None, f"trop long ({q['jetons']} jetons au palier 2)"


def journaux(racine: Path | None = None) -> list[tuple[str, Path]]:
    """Les cours qui tiennent un journal de démarche."""
    racine = racine or cfg.RACINE / "cours"
    return [(d.name, d / "demarche.json") for d in sorted(racine.iterdir()) if (d / "demarche.json").is_file()]


def generer(donnees: Path | None = None, journal: Callable[[str], None] = print,
            cours: list[tuple[str, Path]] | None = None) -> dict[str, Any]:
    outils = _outils()
    paires, rejets = [], []
    for nom, chemin in cours or journaux():
        for pas in json.loads(chemin.read_text(encoding="utf-8"))["pas"]:
            q, raison = paire(nom, pas, outils)
            if q is None:
                rejets.append(f"{nom} {pas['id']} : {raison}")
            else:
                paires.append(q)
        journal(f"{nom} : {len(paires)} paires de démarche, {len(rejets)} écartées")
    sortie = fmt.dossier(FAMILLE, donnees)
    fmt.ecrire(paires, sortie / "paires.jsonl")
    bilan = {"famille": FAMILLE, "paires": len(paires), "rejets": rejets,
             "paliers": {p: sum(1 for q in paires if q["preuve"]["palier"] == p) for p in (1, 2)},
             "jetons_reponse": sum(q["jetons_reponse"] for q in paires)}
    (sortie / "bilan.json").write_text(json.dumps(bilan, ensure_ascii=False, indent=1), encoding="utf-8")
    return bilan
