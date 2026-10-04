"""Mutation : un bug injecté dans un projet testé donne une tâche K3 et, parfois, une tâche D1.

Pour chaque ligne mutable d'un script du jeu, un seul mutant est tiré (graine fixe) parmi les
opérateurs « de corps » (operateurs.py) : deux tâches qui corrigent la même ligne auraient la
même réponse, ce qui fuirait d'un jeu gelé vers l'entraînement. Le mutant est jugé une fois
avec les tests du projet (verdict mis en cache, réutilisé par le portillon comme 1re répétition) :

- K3 si des tests échouent à l'étape run_tests (le projet compile) : depart = mutant +
  journal_tests.json (verdict des tests visibles), reference = fichier d'origine,
  tests cachés = tests du projet, patch plafonné.
- D1 si le journal de lancement du jeu (3 images à pas fixe) localise une erreur
  catégorisée (hors test_failure/autre) exactement sur la ligne mutée : depart = mutant +
  journal.txt, reference = reponse.json, test caché = gabarit D1. La réponse attendue est la
  ligne mutée elle-même (vérité connue par construction), et le générateur vérifie que le
  journal la mentionne.
"""

from __future__ import annotations

import json
import random
import tempfile
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from typing import Any

from usine.generateurs import gabarits
from usine.generateurs.commun import (Production, ecrire_projet, ecrire_tache, ident, journal_execution, lire_projet,
                                      nom_source, tests_regression)
from usine.generateurs.operateurs import Mutant, mutants_projet
from usine.juge import cache
from usine.juge.verdict import extraire_erreurs_journal

ORIGINE = "generateur:mutation"
# Les opérateurs de signature cassent la compilation des appelants : utiles pour K1, pas pour K3/D1.
OPERATEURS_CORPS = {"comparaison_inversee", "operateur_arithmetique", "constante_modifiee", "chemin_noeud_casse",
                    "connexion_supprimee", "await_retire", "type_exporte", "appel_supprime", "condition_niee",
                    "signal_renomme", "booleen_inverse"}
CATEGORIES_D1_LOCALISEES = {"parse_error", "null_instance", "invalid_node_path", "signal_missing", "type_error",
                            "missing_resource"}
PATCH_MAX_LIGNES = 6


def tirer_un_par_ligne(mutants: list[Mutant], graine: int) -> list[Mutant]:
    """Un mutant par (fichier, ligne), tiré avec une graine fixe ; ordre d'origine conservé."""
    par_ligne: dict[tuple[str, int], list[Mutant]] = {}
    for m in mutants:
        par_ligne.setdefault((m.fichier, m.ligne), []).append(m)
    choisis = []
    for cle in sorted(par_ligne):
        rng = random.Random(f"{graine}:{cle[0]}:{cle[1]}")
        choisis.append(rng.choice(par_ligne[cle]))
    return choisis


def projet_mute(projet: dict[str, str], m: Mutant) -> dict[str, str]:
    mute = dict(projet)
    mute[m.fichier] = m.appliquer(projet[m.fichier])
    return mute


def juger_mutant(projet: dict[str, str], m: Mutant, tests: dict[str, str]) -> dict[str, Any]:
    """Verdict (avec cache) du projet muté, tests du projet en tests cachés : clé identique à celle
    du départ de la tâche K3 correspondante (les journaux sont hors clé)."""
    with tempfile.TemporaryDirectory(prefix="usine_mut_") as tmp:
        src = ecrire_projet(projet_mute(projet, m), Path(tmp) / "src")
        t = ecrire_projet(tests, Path(tmp) / "tests")
        return cache.juger(src, [], t, repetition=1)


def _journal_tests(verdict: dict[str, Any]) -> str:
    v = {k: verdict[k] for k in ("ok", "etape", "erreurs", "tests")}
    texte = json.dumps(v, ensure_ascii=False, indent=1) + "\n"
    return texte.replace("res://tests_juge/", "res://tests/")


def _tache_k3(source: Path, sortie: Path, projet: dict[str, str], m: Mutant, verdict: dict[str, Any],
              tests: dict[str, str]) -> Path:
    echecs = verdict["tests"]["echecs"]
    depart = projet_mute(projet, m)
    depart["journal_tests.json"] = _journal_tests(verdict)
    rouges = ", ".join(echecs[:5]) + (f" (et {len(echecs) - 5} autres)" if len(echecs) > 5 else "")
    consigne = (f"Des tests sont rouges : {rouges}. Le verdict des tests est dans journal_tests.json. "
                "Corriger le bug avec le patch le plus petit possible, sans modifier les tests ; "
                "tous les tests doivent passer.")
    tache = {"id": ident("k3", nom_source(source), Path(m.fichier).stem, f"l{m.ligne}", m.operateur),
             "competence": "K3", "consigne": consigne, "consigne_a_ecrire": None, "origine": ORIGINE,
             "generateur": {"nom": "mutation", "source": nom_source(source), "mutant": m.id},
             "juge": {"patch_max_lignes": PATCH_MAX_LIGNES}}
    return ecrire_tache(sortie, tache, depart, {m.fichier: projet[m.fichier]}, tests)


def _tache_d1(source: Path, sortie: Path, projet: dict[str, str], m: Mutant) -> tuple[Path | None, str]:
    depart = projet_mute(projet, m)
    journal = journal_execution(depart)
    res = "res://" + m.fichier
    localisees = [e for e in extraire_erreurs_journal(journal)
                  if e["fichier"] == res and e["ligne"] == m.ligne and e["categorie"] in CATEGORIES_D1_LOCALISEES]
    if not localisees or f"{res}:{m.ligne}" not in journal:
        return None, "journal_sans_erreur_localisee"
    categorie = localisees[0]["categorie"]
    depart["journal.txt"] = journal
    reponse = {"categorie": categorie, "fichier": res, "ligne": m.ligne}
    tache = {"id": ident("d1", nom_source(source), Path(m.fichier).stem, f"l{m.ligne}", m.operateur),
             "competence": "D1", "consigne": gabarits.CONSIGNE_D1, "consigne_a_ecrire": None, "origine": ORIGINE,
             "generateur": {"nom": "mutation", "source": nom_source(source), "mutant": m.id},
             "juge": {"etapes": ["run_tests"]}}
    tests = {"test_d1_reponse.gd": gabarits.GABARIT_TEST_D1.format(categorie=categorie, fichier=res, ligne=m.ligne)}
    return ecrire_tache(sortie, tache, depart, {"reponse.json": json.dumps(reponse, ensure_ascii=False) + "\n"},
                        tests), ""


def generer(source: Path, sortie: Path, graine: int, travailleurs: int = 4) -> Production:
    prod = Production()
    projet = lire_projet(source)
    tests = tests_regression(projet)
    mutants = tirer_un_par_ligne(mutants_projet(projet, operateurs=OPERATEURS_CORPS), graine)

    with ThreadPoolExecutor(max_workers=max(1, travailleurs)) as pool:
        verdicts = list(pool.map(lambda m: juger_mutant(projet, m, tests), mutants))

    candidats_d1 = []
    for m, v in zip(mutants, verdicts):
        nom = f"{m.id}"
        if v["ok"]:
            prod.ecarter("mutation", nom, "mutant_survivant")
            continue
        res = "res://" + m.fichier
        if any(e["fichier"] == res and e["ligne"] == m.ligne and e["categorie"] in CATEGORIES_D1_LOCALISEES
               for e in v["erreurs"]) or v["etape"] != "run_tests":
            candidats_d1.append(m)
        if v["etape"] == "run_tests" and v["tests"]["echecs"]:
            prod.taches.append(_tache_k3(source, sortie, projet, m, v, tests))
        else:
            prod.ecarter("mutation", nom, "k3_tests_non_executes", f"échec à {v['etape']}")

    with ThreadPoolExecutor(max_workers=max(1, travailleurs)) as pool:
        resultats = list(pool.map(lambda m: _tache_d1(source, sortie, projet, m), candidats_d1))
    for m, (dossier, raison) in zip(candidats_d1, resultats):
        if dossier is None:
            prod.ecarter("mutation", m.id, "d1_" + raison)
        else:
            prod.taches.append(dossier)
    return prod
