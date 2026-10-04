"""Format commun du verdict et catégorisation des erreurs du moteur.

Tout est déterministe : expressions régulières sur la sortie de Godot et sur le
rapport JUnit de GdUnit4. Aucune heuristique floue, aucun LLM.
"""

from __future__ import annotations

import re
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any

# Catégories de départ (CLAUDE.md), plus missing_resource. Extensible sans casser.
CATEGORIES = (
    "parse_error",
    "null_instance",
    "invalid_node_path",
    "signal_missing",
    "type_error",
    "missing_resource",
    "test_failure",
    "autre",
)

# L'ordre compte : la première règle qui correspond gagne.
REGLES: list[tuple[str, re.Pattern[str]]] = [
    ("null_instance", re.compile(r"null instance|on a null value|base object of type 'Nil'|in base 'Nil'|previously freed", re.I)),
    ("invalid_node_path", re.compile(r"Node not found|Invalid node path|get_node: .*not found", re.I)),
    ("signal_missing", re.compile(r"nonexistent signal|signal '[^']*' (?:does not|doesn't) exist|Nonexistent signal|no signal named", re.I)),
    ("missing_resource", re.compile(r"File not found|non-existent resource|Failed loading resource|Cannot open file|Resource file not found|No loader found", re.I)),
    ("parse_error", re.compile(r"Parse Error|Compile Error|Failed to compile|error \"Parse error\"|Compilation failed", re.I)),
    ("type_error", re.compile(
        r"Invalid type|Invalid assignment|Trying to assign value of type|Invalid operands|Cannot convert|"
        r"Invalid argument|Invalid cast|cannot be assigned|Invalid call\. Nonexistent function|Nonexistent function|"
        r"expected .* but got|Invalid access to property", re.I)),
]

# Lignes de bruit connues (pas des erreurs du projet).
BRUIT = [
    re.compile(r"remote port number must be between", re.I),
    re.compile(r"Remote Debugger: Unable to connect", re.I),
    # Bilan de fuites à la fermeture du moteur (sons Ogg encore en lecture, etc.) :
    # sans localisation et sans effet sur le chargement ni sur les tests.
    # (« resources still in use at exit », « ObjectDB instances were leaked at exit »,
    # « RID allocations … were leaked at exit », « Pages in use exist at exit in PagedAllocator »).
    re.compile(r"\b(?:leaked|in use|exist) at exit\b", re.I),
]

_ANSI = re.compile(r"\x1b\[[0-9;?]*[A-Za-z]")
_DEBUT_ERREUR = re.compile(r"^\s*(?:USER )?(SCRIPT ERROR|ERROR): (.*)$")
_LOC_INLINE = re.compile(r"^(res://[^\s:]+):(\d+) - (.*)$")
_LOC_RES = re.compile(r"\(?(res://[^\s:()]+):(\d+)\)?")
_LOC_GDUNIT = re.compile(r"in (res://[^\s:]+):(\d+)")


def sans_ansi(texte: str) -> str:
    return _ANSI.sub("", texte)


def categoriser(message: str) -> str:
    for categorie, motif in REGLES:
        if motif.search(message):
            return categorie
    return "autre"


def nouveau_verdict(etape: str, ok: bool = False, duree_s: float = 0.0) -> dict[str, Any]:
    return {"ok": ok, "etape": etape, "duree_s": round(duree_s, 3), "erreurs": [],
            "tests": {"total": 0, "passes": 0, "echecs": []}}


def erreur(message: str, fichier: str | None = None, ligne: int | None = None, categorie: str | None = None) -> dict[str, Any]:
    return {"fichier": fichier, "ligne": ligne, "categorie": categorie or categoriser(message), "message": message.strip()}


def _est_projet(chemin: str) -> bool:
    return chemin.startswith("res://") and not chemin.startswith("res://addons/")


def _premiere_localisation(lignes: list[str]) -> tuple[str | None, int | None]:
    """Première position res:// hors addons dans un bloc d'erreur ; à défaut, la première tout court."""
    trouvees = []
    for ligne in lignes:
        for m in _LOC_RES.finditer(ligne):
            trouvees.append((m.group(1), int(m.group(2))))
    for fichier, num in trouvees:
        if _est_projet(fichier):
            return fichier, num
    return trouvees[0] if trouvees else (None, None)


def extraire_erreurs_journal(sortie: str) -> list[dict[str, Any]]:
    """Erreurs du moteur dans une sortie Godot (blocs « ERROR: » / « SCRIPT ERROR: »)."""
    lignes = sans_ansi(sortie).splitlines()
    erreurs: list[dict[str, Any]] = []
    i = 0
    while i < len(lignes):
        m = _DEBUT_ERREUR.match(lignes[i])
        if not m:
            i += 1
            continue
        message = m.group(2).strip()
        bloc = []
        j = i + 1
        while j < len(lignes) and lignes[j].startswith((" ", "\t")) and not _DEBUT_ERREUR.match(lignes[j]):
            bloc.append(lignes[j])
            j += 1
        i = j
        if any(b.search(message) for b in BRUIT):
            continue
        inline = _LOC_INLINE.match(message)
        if inline:
            fichier, num, message = inline.group(1), int(inline.group(2)), inline.group(3)
        else:
            fichier, num = _premiere_localisation(bloc)
        erreurs.append(erreur(message, fichier, num))
    return erreurs


def _message_runtime(texte: str) -> str | None:
    m = re.search(r"Godot Runtime Error !\s*'(.*?)'\s*(?:\tat|\n|$)", texte, re.S)
    return m.group(1) if m else None


def lire_junit(chemin: Path) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    """Rapport JUnit de GdUnit4 → (bloc « tests » du verdict, erreurs)."""
    racine = ET.parse(chemin).getroot()
    total = 0
    ignores = 0
    echecs: set[str] = set()
    erreurs: list[dict[str, Any]] = []
    for cas in racine.iter("testcase"):
        total += 1
        nom = f"{cas.get('classname')}:{cas.get('name')}"
        for enfant in cas:
            if enfant.tag == "skipped":
                ignores += 1
                continue
            if enfant.tag not in ("failure", "error"):
                continue
            echecs.add(nom)
            texte = sans_ansi(enfant.text or "")
            runtime = _message_runtime(texte)
            loc = _LOC_GDUNIT.search(texte)
            fichier, num = (loc.group(1), int(loc.group(2))) if loc else (None, None)
            if runtime:
                erreurs.append(erreur(runtime, fichier, num))
            else:
                corps = " ".join(l.strip() for l in texte.splitlines() if l.strip() and not l.strip().startswith("at '"))
                erreurs.append(erreur(f"{nom} : {corps}"[:500], fichier, num, "test_failure"))
    tests = {"total": total, "passes": total - len(echecs) - ignores, "echecs": sorted(echecs)}
    if ignores:
        tests["ignores"] = ignores
    return tests, erreurs


def dedoublonner(erreurs: list[dict[str, Any]]) -> list[dict[str, Any]]:
    vues = set()
    resultat = []
    for e in erreurs:
        cle = (e["fichier"], e["ligne"], e["categorie"], e["message"])
        if cle not in vues:
            vues.add(cle)
            resultat.append(e)
    return resultat


def comparable(verdict: dict[str, Any]) -> dict[str, Any]:
    """Verdict sans la durée, pour comparer deux exécutions."""
    return {k: v for k, v in verdict.items() if k != "duree_s"}
