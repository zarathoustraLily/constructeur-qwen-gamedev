"""Famille de paires « lire une sortie de Godot » (étape B4 du suivi) : analyse, sans rien modifier.

Une vraie sortie de Godot, celle d'une paire déjà vérifiée des familles B1 (analyse d'un script), B2 (rendu en
Compatibilité, où les shaders se compilent) ou B3 (suite GdUnit4) : la sortie fautive, ou celle de la même commande
une fois la ligne corrigée. Aucun nouveau lancement de Godot : la vérité vient de la paire source (la faute posée, son
fichier, sa ligne ; la commande qui passe après correction).

La réponse dit :
- le verdict, réussite ou échec, et sur quoi il repose : code de sortie, résumé de GdUnit4, lignes d'erreur (un code 0
  ne suffit pas : GdUnit4 ne fait échouer un cas que sur ses assertions, règle 5.5) ;
- l'erreur à traiter d'abord : fichier, ligne, catégorie (celles du juge, `usine/juge/verdict.py`), et d'où vient
  le numéro (ligne « at: », ou pile d'appels de GDScript quand « at: » désigne le moteur) ;
- le reste : les erreurs qui découlent de la première, les lignes du moteur qui ne viennent pas du projet ;
- la suite : corriger cette seule ligne et relancer ; après une réussite, ne rien retoucher et passer à la suite
  (décision 4 : ne pas refaire un travail déjà validé).

Paires de 1 024 jetons au plus, sans plan (exception de la section 3 : lecture d'une sortie).

    python -m usine.paires lecture
"""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any, Callable

from usine.paires import format as fmt

PLAFOND = 1024
FAMILLE = "lire_sortie"
SOURCES = {"compilation": "analyse", "shader": "rendu", "execution": "test"}
QUESTION = ("La commande a-t-elle réussi ? Si non, quelle erreur faut-il traiter d'abord (fichier, ligne, catégorie) ? "
            "Ne modifie rien.")
SUITE_ECHEC = "**Suite.** Lire le code autour de la ligne {ligne} de `res://{fichier}`, corriger cette seule ligne, puis relancer la même commande."
SUITE_REUSSITE = ("**Suite.** Rien à corriger : cette vérification est acquise. On ne retouche pas ce code, on passe à "
                  "l'étape suivante.")
NOMS = {"analyse": "L'analyse du script", "rendu": "Le rendu", "test": "La suite de tests",
        "scene": "La scène, lancée sans fenêtre,"}


def bloc(phase: str, commande: str, texte: str, code: int) -> str:
    """La sortie telle que la paire la montre : celle des familles sources (même compactage)."""
    from usine.cours.base import godot, sessions
    from usine.paires import execution
    s = godot.Sortie(commande, texte, code)
    return execution.bloc_court(s) if phase in ("test", "scene") else sessions.bloc_sortie(s, phase)


def categorie(message: str) -> str:
    """La catégorie du juge. Une « SHADER ERROR » est une erreur de compilation : la ligne « Shader compilation
    failed » qui la suit tombe dans `parse_error` chez le juge, quel que soit le message du compilateur."""
    from usine.juge.verdict import categoriser
    return "parse_error" if message.startswith("SHADER ERROR") else categoriser(message)


def _lignes_moteur(texte: str) -> list[str]:
    """Ce que la réponse dit des lignes du moteur qui ne viennent pas du projet."""
    from usine.cours.base import profil
    notes = []
    if profil.lignes_benignes(texte) and any(l.startswith('ERROR: Parameter "material" is null') for l in texte.splitlines()):
        notes.append("« ERROR: Parameter \"material\" is null » vient de `servers/rendering/dummy/`, le moteur de rendu "
                     "factice des lancements sans fenêtre : pas du projet.")
    note = profil.note_rendu(texte)
    if note:
        notes.append(note)
    return notes


def _lieu(e: Any, phase: str) -> str:
    if e.pile:
        return (f"Sa ligne « at: » désigne le moteur (`{e.moteur}`) ; le numéro vient de la pile d'appels de GDScript : "
                f"`{e.pile}`.")
    if phase == "rendu":
        return ("Le numéro sûr est celui de la ligne « at: » : l'extrait de code que Godot affiche au-dessus peut être "
                "décalé.")
    return "Le numéro vient de la ligne « at: » qui la suit."


def reponse_echec(phase: str, texte: str, code: int, fichier: str, ligne: int, genre: str) -> str | None:
    """La lecture d'une sortie fautive ; None si la sortie ne désigne pas la ligne connue (la paire est écartée)."""
    from usine.cours.base import profil
    from usine.paires import execution
    e = execution.premiere_erreur(texte)
    if e is None or (e.fichier, e.ligne) != (fichier, ligne):
        return None
    r = []
    if phase == "test":
        resume = profil.resume_gdunit(texte)
        if code != 0:
            v = f"**Verdict.** Échec : code de sortie {code}"
            v += (f", et GdUnit4 compte {resume[1]} erreur{'s' if resume[1] > 1 else ''} et {resume[2]} échec"
                  f"{'s' if resume[2] > 1 else ''} sur {resume[0]} cas (« Overall Summary »)." if resume else ".")
        else:
            v = ("**Verdict.** Échec, malgré le code de sortie 0 : la sortie contient une erreur du jeu. GdUnit4 ne fait "
                 "échouer un cas que sur ses assertions ; il faut lire chaque ligne.")
    elif phase == "scene":
        v = ("**Verdict.** Échec, malgré le code de sortie 0 : la scène se lance, mais la sortie contient une erreur du "
             "projet ; il faut lire chaque ligne." if code == 0 else
             f"**Verdict.** Échec : la scène s'arrête sur une erreur (code de sortie {code}).")
    elif phase == "analyse":
        v = (f"**Verdict.** Échec : l'analyse signale une erreur (code de sortie {code}) et le script ne se charge "
             "pas.")
    else:
        v = ("**Verdict.** Échec : un shader ne compile pas (« SHADER ERROR », puis « Shader compilation failed »)"
             + (", même si le code de sortie est 0 : le jeu se lance, mais ce shader n'est pas compilé." if code == 0 else
                f" ; code de sortie {code}."))
    r.append(v)
    r.append(f"**Erreur à traiter d'abord.** `res://{fichier}`, ligne {ligne}, catégorie `{categorie(e.message)}` : "
             f"« {e.message} » {_lieu(e, phase)}")
    reste = []
    if phase == "analyse":
        reste.append("« Failed to load script … with error \"Parse error\" » en découle : le script ne se charge pas "
                     "tant que l'erreur est là.")
        if genre == "godot3_annotation":
            reste.append("C'est une faute de syntaxe : tant qu'elle est là, Godot n'analyse pas le reste du script ; "
                         "d'autres erreurs peuvent se montrer une fois celle-ci corrigée.")
    elif phase == "rendu":
        reste.append("« Shader compilation failed » en découle.")
    else:
        m = type("M", (), {"fichier": fichier, "ligne": ligne})()
        suite = execution.consequences(texte, m)
        if suite:
            lieux = ", ".join((f"ligne {n}" if f == fichier else f"`res://{f}` ligne {n}") for f, n, _ in suite[:3])
            reste.append(f"Les erreurs suivantes ({lieux}{', …' if len(suite) > 3 else ''}) en découlent : les "
                         "corriger une à une cacherait la panne sans la réparer.")
    reste += _lignes_moteur(texte)
    if reste:
        r.append("**Le reste.** " + " ".join(reste))
    r.append(SUITE_ECHEC.format(ligne=ligne, fichier=fichier))
    return "\n\n".join(r)


def reponse_reussite(phase: str, texte: str, code: int) -> str | None:
    """La lecture d'une sortie qui passe ; None si elle ne passe pas aux yeux de la règle (la paire est écartée)."""
    from usine.cours.base import profil
    if code != 0:
        return None
    if phase == "analyse":
        if texte.strip():
            return None
        v = "**Verdict.** Réussite : l'analyse ne signale rien et le code de sortie est 0 ; le script se charge."
    elif phase == "rendu":
        if not profil.rendu_propre(code, texte):
            return None
        v = "**Verdict.** Réussite : aucune erreur du projet, aucune « SHADER ERROR », code de sortie 0."
    elif phase == "scene":
        if profil.erreurs_projet(texte) or "SCRIPT ERROR" in texte:
            return None
        v = "**Verdict.** Réussite : la scène se lance sans erreur du projet ni « SCRIPT ERROR », code de sortie 0."
    else:
        resume = profil.resume_gdunit(texte)
        if not resume or resume[1] or resume[2] or "SCRIPT ERROR" in texte or profil.erreurs_inattendues(texte):
            return None
        v = (f"**Verdict.** Réussite : {resume[0]} cas, 0 erreur, 0 échec (« Overall Summary »), aucune « SCRIPT "
             "ERROR », code de sortie 0.")
    notes = _lignes_moteur(texte)
    return "\n\n".join([v] + (["**Le reste.** " + " ".join(notes)] if notes else []) + [SUITE_REUSSITE])


def paires_de(source: dict[str, Any], famille_source: str) -> list[dict[str, Any]]:
    """Les deux lectures d'une paire source : la sortie fautive, la sortie corrigée."""
    pr = source["preuve"]
    phase = "scene" if pr.get("mode") == "scene" else SOURCES[famille_source]
    if "code" not in pr:
        return []  # paire produite avant que les codes de sortie soient gardés
    sortie = []
    cas = [("échec", pr["sortie"], pr["code"]), ("réussite", pr["sortie_apres"], pr["code_apres"])]
    for verdict, texte, code in cas:
        r = (reponse_echec(phase, texte, code, pr["fichier"], pr["ligne"], pr["genre"]) if verdict == "échec" else
             reponse_reussite(phase, texte, code))
        if r is None:
            continue
        demande = (f"Projet Godot 4.7.2. {NOMS[phase]} donne :\n{bloc(phase, pr['commande'], texte, code)}\n\n"
                   + QUESTION)
        sortie.append(fmt.paire(FAMILLE, source["sujet"], "analyse", demande, r,
                                {"source": famille_source, "verdict": verdict, "phase": phase, "commande": pr["commande"],
                                 "code": code, "etape": pr["etape"], "fichier": pr["fichier"], "ligne": pr["ligne"],
                                 "genre": pr["genre"]}))
    return sortie


def generer(donnees: Path | None = None, journal: Callable[[str], None] = print) -> dict[str, Any]:
    """Toutes les lectures tirées des paires B1, B2 et B3 déjà produites."""
    paires: list[dict[str, Any]] = []
    for famille_source in SOURCES:
        for fichier in sorted(fmt.dossier(famille_source, donnees).glob("paires_*.jsonl")):
            n = 0
            for ligne in fichier.read_text(encoding="utf-8").splitlines():
                nouvelles = paires_de(json.loads(ligne), famille_source)
                paires += nouvelles
                n += len(nouvelles)
            journal(f"{famille_source}/{fichier.name} : {n} lectures")
    retenues = [p for p in paires if p["jetons"] <= PLAFOND]
    sortie = fmt.dossier(FAMILLE, donnees)
    fmt.ecrire(retenues, sortie / "paires.jsonl")
    bilan: dict[str, Any] = {"famille": FAMILLE, "paires": len(retenues), "trop_longues": len(paires) - len(retenues),
                             "par_verdict": {}, "par_source": {}, "par_categorie": {},
                             "jetons_max": max((p["jetons"] for p in retenues), default=0)}
    for p in retenues:
        pr = p["preuve"]
        bilan["par_verdict"][pr["verdict"]] = bilan["par_verdict"].get(pr["verdict"], 0) + 1
        bilan["par_source"][pr["source"]] = bilan["par_source"].get(pr["source"], 0) + 1
        if pr["verdict"] == "échec":
            cat = re.search(r"catégorie `(\w+)`", p["messages"][-1]["content"])[1]
            bilan["par_categorie"][cat] = bilan["par_categorie"].get(cat, 0) + 1
    (sortie / "bilan.json").write_text(json.dumps(bilan, indent=1, ensure_ascii=False), encoding="utf-8")
    return bilan
