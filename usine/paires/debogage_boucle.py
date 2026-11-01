"""Famille « corriger, relancer, lire » (débogage au palier de 2 048 jetons, avec le plan ; décision 4 : tester après chaque
modification et lire le résultat avant d'aller plus loin).

Une paire de compilation ou de shader déjà vérifiée (`compilation.py`) dit la faute et sa correction, mais s'arrête à la
commande à relancer. Ici la correction se fait comme à l'usage dans OpenCode : la réponse lit l'erreur et cherche, corrige
par l'outil `edit`, relance par l'outil `shell`, reçoit la vraie sortie gardée par la paire source (`sortie_apres`, celle de
Godot sur le projet corrigé, règle 7.2), et la lit. Aucun nouveau lancement de Godot.

Gardée seulement si la correction se lit dans la réponse source, si le texte fautif n'existe nulle part dans le fichier de
l'étape (l'édition y trouve un passage unique, règle 5.7) et si la sortie relue passe la règle de lecture.

Les mêmes fautes donnent aussi de l'analyse à ce palier (`paire_analyse`, la forme de `usine/cours/base/analyse.py`) : « dis-moi
ce qui ne va pas, sans rien modifier » ; la réponse lit l'erreur, cherche et dit les lignes à changer. Rien n'est relancé.

Par sujet, on produit juste ce qu'il faut pour tenir 40/40/20 face à la création de ce palier, qui n'est jamais coupée.

    python -m usine.paires debogage_boucle [--graine G]
"""

from __future__ import annotations

import json
import random
import re
from pathlib import Path, PureWindowsPath
from typing import Any, Callable

from usine import config as cfg
from usine.paires import boucle
from usine.paires import format as fmt

FAMILLE = "debogage_boucle"
FAMILLE_ANALYSE = "analyse_boucle"
PLAFOND = 2048
SOURCES = {"compilation": "analyse", "shader": "rendu"}
REMPLACE = re.compile(r"Dans `res://(?P<rel>[^`]+)`, ligne (?P<ligne>\d+), je remplace :\n"
                      r"```\w*\n(?P<avant>.*?)\n```\npar :\n```\w*\n(?P<apres>.*?)\n```", re.S)
CORRIGER = "**Corriger.**"
TESTER = "**Tester.**"


def dossier_jeu(cours: str) -> str:
    """Le dossier du projet chez laurent : celui des cours d'OpenCode, sinon celui de ses sources."""
    config = cfg.charger_config()
    cle = "dossier_cours" if cours == "batiments_proceduraux" else f"dossier_{cours}"
    return config.get("opencode", {}).get(cle) or config.get("sources", {}).get(cours) or f"D:\\GODOT\\{cours}"


def correction(reponse: str) -> tuple[str, dict[str, str]] | None:
    """(ce que la réponse dit avant de corriger, le remplacement), ou None si elle n'a pas cette forme."""
    m = REMPLACE.search(reponse)
    if m is None or CORRIGER not in reponse or len(REMPLACE.findall(reponse)) != 1:
        return None
    return reponse[:reponse.index(CORRIGER)].rstrip(), m.groupdict()


def paire(cours: str, source: dict[str, Any], fichier: str | None) -> tuple[dict[str, Any] | None, str]:
    """La paire de cette source, ou (None, raison). `fichier` : le texte du fichier à l'étape, sans la faute."""
    from usine.cours.base import godot, opencode
    preuve = source["preuve"]
    if preuve.get("code_apres") is None:
        return None, "pas de sortie après correction"
    trouve = correction(source["messages"][-1]["content"])
    if trouve is None:
        return None, "correction illisible"
    lire, c = trouve
    avant = c["avant"].strip()
    if fichier is None or avant in fichier:
        return None, "passage fautif introuvable ou non unique"
    phase = SOURCES[source["famille"]]
    apres = godot.Sortie(preuve["commande"], preuve["sortie_apres"], preuve["code_apres"])
    quoi = f"la ligne {c['ligne']} de `{c['rel']}` corrigée"
    lecture = boucle.lecture([(apres, phase)], quoi, [], None)
    if lecture is None:
        return None, "la sortie après correction ne passe pas la lecture"
    ident = f"boucle_{source['famille']}_{preuve['etape']}_{c['ligne']}"
    chemin = str(PureWindowsPath(dossier_jeu(cours)) / PureWindowsPath(c["rel"]))
    texte = f"{lire}\n\n{CORRIGER} Une seule ligne change, la ligne {c['ligne']}.\n\n{TESTER} Je relance la même commande."
    sortie = (apres.texte.strip() + "\n") if apres.texte.strip() else ""
    tours = [
        {"role": "user", "content": source["messages"][0]["content"]},
        {"role": "assistant", "content": texte, "tool_calls": [
            fmt.appel(f"{ident}_0", "edit", {"path": chemin, "oldString": c["avant"], "newString": c["apres"]}),
            fmt.appel(f"{ident}_1", "shell", {"command": boucle.commande_shell(apres.commande)})]},
        {"role": "tool", "tool_call_id": f"{ident}_0", "content": opencode.EDIT_FAIT.format(chemin=c["rel"])},
        {"role": "tool", "tool_call_id": f"{ident}_1", "content": opencode.retour_shell(sortie, apres.code)},
        {"role": "assistant", "content": lecture},
    ]
    q = fmt.paire_tours(FAMILLE, source["sujet"], "débogage", tours,
                        {"source": source["famille"], "cours": cours, "etape": preuve["etape"], "fichier": c["rel"],
                         "ligne": int(c["ligne"]), "genre": preuve.get("genre"), "commande": apres.commande,
                         "sortie_apres": apres.texte, "code_apres": apres.code, "palier": 2}, systeme=fmt.plan())
    return (q, "") if q["jetons"] <= PLAFOND else (None, f"trop longue ({q['jetons']} jetons)")


def paire_analyse(source: dict[str, Any]) -> tuple[dict[str, Any] | None, str]:
    """La même faute, analysée sans rien modifier : la lecture de la source, puis les lignes à changer, en texte."""
    from usine.cours.base import analyse
    trouve = correction(source["messages"][-1]["content"])
    demande = source["messages"][0]["content"]
    if trouve is None or "Corrige l'erreur." not in demande:
        return None, "correction illisible"
    lire, c = trouve
    reponse = (f"{lire}\n\n**À changer.** Dans `res://{c['rel']}`, ligne {c['ligne']}, remplacer :\n```gdscript\n{c['avant']}\n```\n"
               f"par :\n```gdscript\n{c['apres']}\n```\n\n{analyse.FIN}")
    preuve = source["preuve"]
    q = fmt.paire(FAMILLE_ANALYSE, source["sujet"], "analyse", demande.replace("Corrige l'erreur.", analyse.ANALYSER_NEUTRE), reponse,
                  {"source": source["famille"], "etape": preuve["etape"], "fichier": c["rel"], "ligne": int(c["ligne"]),
                   "genre": preuve.get("genre"), "palier": 2}, systeme=fmt.plan())
    return (q, "") if q["jetons"] <= PLAFOND else (None, f"trop longue ({q['jetons']} jetons)")


def budgets(racine: Path) -> tuple[dict[str, int], dict[str, int]]:
    """Par sujet, au palier 2, les jetons de réponse qui manquent pour tenir 40/40/20 face à la création : (débogage, analyse)."""
    compte: dict[str, dict[str, int]] = {t: {} for t in fmt.TYPES}
    for f in sorted(racine.glob("*/paires*.jsonl")):
        if f.parent.name in (FAMILLE, FAMILLE_ANALYSE):
            continue
        for ligne in f.read_text(encoding="utf-8").splitlines():
            p = json.loads(ligne)
            if p["messages"][0]["role"] == "system":
                compte[p["type"]][p["sujet"]] = compte[p["type"]].get(p["sujet"], 0) + p["jetons_reponse"]
    creation = compte["création"]
    return ({s: n - compte["débogage"].get(s, 0) for s, n in creation.items()},
            {s: n // 2 - compte["analyse"].get(s, 0) for s, n in creation.items()})


def _ecrire(famille: str, paires: list[dict[str, Any]], rejets: list[str], donnees: Path | None,
            journal: Callable[[str], None]) -> dict[str, Any]:
    sortie = fmt.dossier(famille, donnees)
    fmt.ecrire(paires, sortie / "paires.jsonl")
    bilan: dict[str, Any] = {"famille": famille, "paires": len(paires), "rejets": len(rejets), "par_sujet": {},
                             "jetons_max": max((p["jetons"] for p in paires), default=0), "exemples_de_rejets": rejets[:12]}
    for p in paires:
        bilan["par_sujet"][p["sujet"]] = bilan["par_sujet"].get(p["sujet"], 0) + 1
    (sortie / "bilan.json").write_text(json.dumps(bilan, indent=1, ensure_ascii=False), encoding="utf-8")
    journal(f"{famille} : {len(paires)} paires, {len(rejets)} écartées")
    return bilan


def generer(graine: int = 1, donnees: Path | None = None, journal: Callable[[str], None] = print) -> dict[str, Any]:
    from usine.cours.base import chemins, etat
    racine = Path(donnees or cfg.dossier_donnees()) / "paires"
    reste, reste_analyse = budgets(racine)
    sources = []
    for famille in SOURCES:
        for f in sorted((racine / famille).glob("paires_*.jsonl")):
            cours = f.stem.removeprefix("paires_")
            sources += [(cours, json.loads(l)) for l in f.read_text(encoding="utf-8").splitlines() if l.strip()]
    random.Random(graine).shuffle(sources)
    paires, rejets, vus = [], [], set()
    analyses, rejets_analyse = [], []
    etats: dict[tuple[str, int], dict[str, str]] = {}
    for cours, s in sources:
        preuve = s["preuve"]
        cle = (cours, preuve["fichier"], preuve["ligne"], preuve.get("genre"))
        if cle in vus:
            continue
        vus.add(cle)
        if reste_analyse.get(s["sujet"], 0) > 0:
            a, raison = paire_analyse(s)
            if a is None:
                rejets_analyse.append(f"{preuve['etape']} {preuve['fichier']}:{preuve['ligne']} : {raison}")
            else:
                analyses.append(a)
                reste_analyse[s["sujet"]] -= a["jetons_reponse"]
        if reste.get(s["sujet"], 0) <= 0:
            continue
        ville, n = preuve["etape"].rsplit("-", 1)
        if chemins.actuels().nom_cours != cours:
            chemins.configurer(cours=cours)
        if (ville, int(n)) not in etats:
            etats[(ville, int(n))] = etat.lire(ville, int(n))
        q, raison = paire(cours, s, etats[(ville, int(n))].get(preuve["fichier"]))
        if q is None:
            rejets.append(f"{preuve['etape']} {preuve['fichier']}:{preuve['ligne']} : {raison}")
            continue
        paires.append(q)
        reste[s["sujet"]] -= q["jetons_reponse"]
    return {"debogage": _ecrire(FAMILLE, paires, rejets, donnees, journal),
            "analyse": _ecrire(FAMILLE_ANALYSE, analyses, rejets_analyse, donnees, journal),
            "manque_debogage": {s: n for s, n in reste.items() if n > 0},
            "manque_analyse": {s: n for s, n in reste_analyse.items() if n > 0}}
