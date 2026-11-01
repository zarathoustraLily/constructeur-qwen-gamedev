"""Famille de paires « la démarche » : comment on crée un niveau, pas à pas (demande de laurent du 2026-10-28 : « créer
un système qui enseigne à Qwen ta démarche pour créer le niveau »).

Un cours de jeu tient son journal de démarche (`cours/<nom>/demarche.json`) : chaque pas est une décision réellement
prise en construisant le niveau, avec la situation, ce qu'on se demande, l'outil d'OpenCode employé pour le savoir,
ce qu'on lit dans la sortie et ce qu'on décide. Chaque pas devient une paire en plusieurs tours, comme à l'usage :
1. la situation (la demande) ;
2. la réponse dit pourquoi elle cherche, puis appelle l'outil, selon le genre du pas :
   - `rag`, `vocab` : l'outil `execute` du Code Mode (`tools["usine-godot"].search_docs({…})` ou `.vocab_lookup({…})`,
     la forme des paires RAG), rejoué par la classe qui sert le serveur MCP (`mcp_serveur.outils`) ;
   - `lire` : l'outil `read`, sur un fichier du projet de l'étape, tel que l'étape l'a fabriqué ;
   - `sonde` : un petit script de mesure de `cours/<nom>/sondes/`, écrit par `write` (si le pas dit `ecrit`), puis lancé
     par `shell` sur le projet de l'étape, sans fenêtre et à cadence fixe : on mesure au lieu de deviner ;
   - `plan` : la liste des étapes écrite dans `plan.md` par `write`, tirée du manifeste du cours ;
3. la vraie sortie de l'outil ;
4. la réponse lit la sortie (en la citant) et décide.

Vérification déterministe (décision 18.1) : le pas est écarté si un fragment attendu manque à la sortie rejouée, ou si
une citation de la lecture (entre « ») ne s'y trouve pas mot pour mot ; une sonde doit finir par le code 0. Palier 1
(1 024 jetons, sans le plan) quand la réponse ne cite aucune convention du plan (exception de la section 3 : requête au
RAG, lecture d'une sortie) ; sinon palier 2, plan compris.

    python -m usine.paires demarche
"""

from __future__ import annotations

import json
import re
from pathlib import Path, PureWindowsPath
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
SONDES = "SUIVIS_PROGRESSION/outils/scenarios"  # où les sondes vivent dans le projet, écrites comme à l'usage
IMAGES_SONDE = 1200  # une sonde quitte d'elle-même ; ce plafond n'arrête que celle qui planterait


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


def sujet(nom: str) -> str:
    """Le sujet écrit comme dans les autres familles : la grille compte par sujet (« Graphisme 3D » → « graphisme 3D »)."""
    return nom if nom in ("UI", "VFX") else nom[0].lower() + nom[1:]


def chemin_jeu(cours: str, rel: str) -> str:
    """Le chemin Windows d'un fichier du jeu, celui que les outils d'OpenCode reçoivent à l'usage."""
    racine = cfg.charger_config().get("sources", {})[cours]
    return str(PureWindowsPath(racine) / PureWindowsPath(rel))


def _projet(cours: str, etape: int) -> Path:
    from usine.cours import dossier_projets
    from usine.cours.fabriquer import lire_manifeste
    prefixe = lire_manifeste(cfg.RACINE / "cours" / cours)["PREFIXE"]
    return Path(dossier_projets(cours, cfg.charger_config())) / f"{prefixe}_etape_{etape:03d}"


def _lire(cours: str, outil: dict[str, Any]) -> list[tuple[str, dict[str, Any], str]]:
    from usine.cours.base import opencode
    rel, debut, fin = outil["fichier"], int(outil["debut"]), int(outil["fin"])
    chemin = chemin_jeu(cours, rel)
    texte = (_projet(cours, int(outil["etape"])) / rel).read_text(encoding="utf-8")
    return [("read", {"path": chemin, "offset": debut, "limit": fin - debut + 1},
             opencode.retour_read(chemin, texte, debut, fin))]


def _sonde(cours: str, outil: dict[str, Any]) -> list[tuple[str, dict[str, Any], str]]:
    """La sonde posée dans le projet de l'étape, le temps de la lancer ; sa sortie est celle de Godot (règle 5.1)."""
    from usine.cours.base import godot, opencode
    from usine.paires import boucle
    source = cfg.RACINE / "cours" / cours / "sondes" / outil["script"]
    rel = f"{SONDES}/{outil['script']}"
    projet = _projet(cours, int(outil["etape"]))
    copie = projet / rel
    copie.parent.mkdir(parents=True, exist_ok=True)
    texte = source.read_text(encoding="utf-8")
    copie.write_text(texte, encoding="utf-8", newline="\n")
    arguments = ["--headless", "--path", ".", "--fixed-fps", "60", "--quit-after", str(IMAGES_SONDE), "-s", rel]
    if outil.get("arguments"):
        arguments += ["--", *outil["arguments"]]
    if not (projet / ".godot" / "global_script_class_cache.cfg").is_file():
        godot.importer(str(projet))     # un projet tout juste fabriqué ne connaît pas encore ses classes
    try:
        sortie, code, _ = godot._lancer(arguments, str(projet))
    finally:
        copie.unlink()
        for dossier in (copie.parent, copie.parent.parent, copie.parent.parent.parent):
            if not any(dossier.iterdir()):
                dossier.rmdir()
    appels: list[tuple[str, dict[str, Any], str]] = []
    if outil.get("ecrit"):
        appels.append(("write", {"path": chemin_jeu(cours, rel), "content": texte}, opencode.WRITE_CREE.format(chemin=rel)))
    retour = opencode.retour_shell(sortie.strip() + "\n", code)
    return appels + [("shell", {"command": boucle.commande_shell(godot.commande(arguments))}, retour)]


def _plan(cours: str, outil: dict[str, Any]) -> list[tuple[str, dict[str, Any], str]]:
    """`plan.md` à ce moment du travail : les étapes 1 à `a` du manifeste, cochées avant `de` : une liste vérifiable, pas
    une reformulation."""
    from usine.cours.base import opencode
    from usine.cours.fabriquer import lire_manifeste
    etapes = lire_manifeste(cfg.RACINE / "cours" / cours)["ETAPES"]
    de, a = int(outil["de"]), int(outil["a"])
    contenu = "\n".join(f"- [{'x' if n < de else ' '}] {n}. {etapes[n - 1]['titre']}" for n in range(1, a + 1)) + "\n"
    retour = (opencode.WRITE_CREE if de == 1 else opencode.WRITE_REMPLACE).format(chemin="plan.md")
    return [("write", {"path": chemin_jeu(cours, "plan.md"), "content": contenu}, retour)]


def appels(cours: str, pas: dict[str, Any], outils: Any) -> list[tuple[str, dict[str, Any], str]]:
    """Les appels d'outil d'un pas, comme à l'usage : (outil, arguments, vrai retour)."""
    outil = pas["outil"]
    if outil["genre"] in CODES:
        code, sortie = rejouer(outil, outils)
        return [("execute", {"code": code}, sortie)]
    return {"lire": _lire, "sonde": _sonde, "plan": _plan}[outil["genre"]](cours, outil)


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
    faits = appels(cours, pas, outils)
    sortie = "\n".join(retour for _, _, retour in faits)
    raison = verifier(pas, sortie)
    if raison:
        return None, raison
    if pas["outil"]["genre"] == "sonde" and not re.search(r"code 0\b", faits[-1][2].rsplit("\n", 1)[-1]):
        return None, f"la sonde ne finit pas par le code 0 : {faits[-1][2][-80:]}"
    ident = f"demarche_{pas['id']}"
    noms = [ident if len(faits) == 1 else f"{ident}_{i}" for i in range(len(faits))]
    tours = [
        {"role": "user", "content": pas["situation"]},
        {"role": "assistant", "content": pas["pensee"],
         "tool_calls": [fmt.appel(n, outil, arguments) for n, (outil, arguments, _) in zip(noms, faits)]},
        *({"role": "tool", "tool_call_id": n, "content": retour} for n, (_, _, retour) in zip(noms, faits)),
        {"role": "assistant", "content": pas["lecture"] + "\n\n" + pas["decision"]},
    ]
    preuve = {"cours": cours, "etape": pas["etape"], "pas": pas["id"], "outil": pas["outil"],
              "attendu": pas["attendu"], "verifie": "sortie rejouée, fragments et citations présents"}
    ecrit = "".join(str(arguments.get("content", "")) for _, arguments, _ in faits)
    conventions = CONVENTION.search(pas["lecture"] + pas["decision"] + pas["situation"] + ecrit)
    paliers = (2,) if conventions or pas["outil"]["genre"] == "plan" else (1, 2)
    for palier in paliers:
        q = fmt.paire_tours(FAMILLE, sujet(pas["sujet"]), pas["type"], tours, dict(preuve, palier=palier),
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
