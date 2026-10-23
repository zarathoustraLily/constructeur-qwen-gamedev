"""Banc du RAG : des demandes en français tirées des notes de nos cours, la réponse attendue connue d'avance.

Chaque point des notes (« ### N. Titre » dans le README d'un projet d'étape fabriqué) donne une demande : son titre,
tel qu'un développeur l'écrirait. La réponse attendue : les classes de Godot que le point cite entre accents graves
(`ConcavePolygonShape3D`, `RenderingServer.global_shader_parameter_set()`…), vérifiées dans `extension_api.json`.
Un point est trouvé si, parmi les n premiers résultats, une page de la référence (classe ou membre) porte sur l'une
de ces classes. Les fragments tirés de la même étape du même cours ne comptent pas : le banc mesure ce que le RAG
apporte, pas qu'il retrouve la note d'où vient la demande.

    python -m usine.rag banc [-n 5]
"""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

from usine import config as cfg

RE_POINT = re.compile(r"^### \d+\.\s+(.+)$", re.M)
RE_CODE = re.compile(r"`([^`]+)`")
RE_IDENT_CLASSE = re.compile(r"^@?([A-Z][A-Za-z0-9_]*)(?:\.[A-Za-z_]\w*(?:\(\))?)?$")


def classes_godot(donnees: Path | None = None) -> set[str]:
    api = Path(donnees or cfg.dossier_donnees()) / "vocab" / f"extension_api_{cfg.version_godot()}.json"
    d = json.loads(api.read_text(encoding="utf-8"))
    return {c["name"] for c in d["classes"]} | {c["name"] for c in d["builtin_classes"]}


def points(readme: Path, classes: set[str]) -> list[dict[str, Any]]:
    """Les points d'une note : titre, classes attendues (au moins une), source de la note."""
    texte = readme.read_text(encoding="utf-8")
    resultat = []
    titres = list(RE_POINT.finditer(texte))
    for i, m in enumerate(titres):
        fin = titres[i + 1].start() if i + 1 < len(titres) else len(texte)
        suite = texte[m.end():fin]
        fin_section = re.search(r"^## ", suite, re.M)
        corps = suite[:fin_section.start()] if fin_section else suite
        attendues = sorted({c.group(1) for code in RE_CODE.findall(corps)
                            if (c := RE_IDENT_CLASSE.match(code.strip())) and c.group(1) in classes})
        if attendues:
            resultat.append({"demande": m.group(1).strip(), "attendues": attendues})
    return resultat


def demandes(donnees: Path | None = None) -> list[dict[str, Any]]:
    donnees = Path(donnees or cfg.dossier_donnees())
    classes = classes_godot(donnees)
    tout = []
    for readme in sorted((donnees / "cours").glob("*/projets/*/README.md")):
        cours, projet = readme.parts[-4], readme.parts[-2]
        for p in points(readme, classes):
            tout.append({**p, "cours": cours, "projet": projet})
    return tout


def meme_etape(resultat: dict[str, Any], d: dict[str, Any], tout_le_cours: bool = False) -> bool:
    """Fragment tiré de l'étape d'où vient la demande (ou, avec tout_le_cours, de n'importe quelle étape du même
    cours : le code des étapes suivantes reprend celui de l'étape)."""
    if not resultat["source"].startswith(f"cours/{d['cours']}/"):
        return False
    return tout_le_cours or d["projet"] in resultat["source"]


def mesurer(n: int = 5, base: Path | None = None, donnees: Path | None = None,
            tout_le_cours: bool = False) -> dict[str, Any]:
    from usine.rag.index import IndexDocs

    idx = IndexDocs(base)
    try:
        liste = demandes(donnees)
        trouves, utiles, par_cours, rates = 0, 0, {}, []
        for d in liste:
            res = [r for r in idx.chercher(d["demande"], n + 40) if not meme_etape(r, d, tout_le_cours)][:n]
            ok = any(r["genre"] in ("classe", "membre") and r["classe"] in d["attendues"] for r in res)
            # utile : un fragment, quel qu'il soit (page, exemple, note de cours), qui emploie une classe attendue
            utile = ok or any(re.search(rf"\b{re.escape(c)}\b", r["texte"]) for r in res for c in d["attendues"])
            trouves += ok
            utiles += utile
            c = par_cours.setdefault(d["cours"], [0, 0, 0])
            c[0] += ok
            c[1] += utile
            c[2] += 1
            if not utile:
                rates.append({"demande": d["demande"], "attendues": d["attendues"],
                              "obtenus": [r["titre"] for r in res]})
        total = len(liste) or 1
        return {"n": n, "points": len(liste), "reference": trouves, "utiles": utiles,
                "taux_reference": round(trouves / total, 3), "taux_utiles": round(utiles / total, 3),
                "par_cours": {k: f"référence {v[0]}/{v[2]}, utiles {v[1]}/{v[2]}" for k, v in sorted(par_cours.items())},
                "rates": rates}
    finally:
        idx.fermer()
