"""La boucle de vérification des paires de création (demande de laurent du 2026-10-28 : des paires « d'excellente
qualité », qui emploient la place des 1 024 jetons ; décision 4 : tester après chaque modification et lire le
résultat avant d'aller plus loin).

Une paire de création finit ainsi, comme à l'usage dans OpenCode :
1. la réponse écrit le code, vérifie l'API, puis appelle l'outil `shell` pour l'analyse du script et pour les tests
   (la commande Godot par son chemin complet, comme les sessions des cours, `opencode.Harnais.commande`) ;
2. les retours de l'outil sont les vraies sorties de Godot, sur l'état vérifié (règle 7.2 : la réponse n'écrit
   jamais une sortie) ; celle des tests est compactée comme dans les autres paires courtes (`execution.bloc_court`) ;
3. la réponse lit ces sorties : le verdict et sur quoi il repose, les cas qui jugent ce qui vient d'être écrit (ceux
   qui échouaient sans lui, relevés par le juge), puis la suite : ce travail est validé, on n'y retouche plus.

Une sortie qui ne passe pas aux yeux de la règle de lecture (`lecture.reponse_reussite`) écarte la paire.
"""

from __future__ import annotations

import re
from typing import Any

from usine.paires import format as fmt

CAS = re.compile(r"^func (test_\w+)\(", re.M)


def commande_shell(neutre: str) -> str:
    """La commande telle qu'OpenCode la lance chez laurent : Godot par son chemin complet."""
    from usine.cours.base import chemins
    godot = chemins.actuels().godot_windows
    return godot + neutre[len("godot"):] if godot and neutre.startswith("godot ") else neutre


def retour(s: Any, phase: str) -> str:
    """Le retour de l'outil `shell` : la sortie (celle des tests compactée), puis le code de sortie."""
    from usine.cours.base import debogage, opencode
    from usine.paires.execution import sans_bandeau
    corps = s.texte if phase == "analyse" else debogage.compacter(sans_bandeau(s.texte), garder=1, pile=1)
    return opencode.retour_shell(corps.strip() + ("\n" if corps.strip() else ""), s.code)


def cas_rouges(suite_texte: str, sortie_rouge: str, suite: str) -> list[str]:
    """Les cas de la suite qui ne passent pas sans le code écrit : ceux qui le jugent."""
    from usine.cours.base import profil
    passes = {c.split(" > ", 1)[-1] for c in profil.cas_passes(sortie_rouge)}
    return [c for c in CAS.findall(suite_texte) if c not in passes]


def suite_passe(projet: Any, suite: str, attendus: set[str]) -> bool | str:
    """True si la suite passe sur l'état de l'étape ; sinon la première ligne qui la fait échouer. Une seconde
    tentative : sous Windows, la suppression de l'ancien rapport de GdUnit4 échoue parfois quand les lancements se
    suivent de près (`profil.arguments_gdunit`)."""
    from usine.cours.base import godot, profil
    for _ in range(2):
        v = godot.tester_gdunit(projet.chemin, ["res://" + suite])
        if profil.test_reussi(v.code, v.texte, attendus):
            return True
    fautes = profil.erreurs_inattendues(v.texte, attendus)
    return (fautes[0] if fautes else f"code {v.code}")[:160]


def ecartes(suite_texte: str, cas: list[str], suite: str) -> list[str]:
    """Les cas de la suite à écarter (`-i suite:cas` de GdUnit4 6.2.1, qui n'a pas d'option pour lancer un seul
    cas) : tous sauf ceux qui jugent ; aucun si on ne sait pas lesquels jugent."""
    from pathlib import Path
    if not cas:
        return []
    return [f"{Path(suite).stem}:{c}" for c in CAS.findall(suite_texte) if c not in cas]


def phrase_cas(suite_texte: str, cas: list[str]) -> str:
    """La fin de la phrase « **Tester.** J'analyse le script, puis je lance … »."""
    tous = CAS.findall(suite_texte)
    if not cas or len(cas) == len(tous):
        return "la suite qui couvre ce code."
    if len(cas) == 1:
        return "le cas de la suite qui juge ce code ; les autres sont écartés par `-i`."
    return f"les {len(cas)} cas de la suite qui jugent ce code ; les autres sont écartés par `-i`."


def lecture(sorties: list[tuple[Any, str]], quoi: str, cas: list[str], suite: str | None) -> str | None:
    """La lecture des sorties `[(sortie, phase)]` : verdict, cas qui jugent `quoi`, suite. None si une sortie ne
    passe pas."""
    from usine.cours.base import profil
    from usine.paires.lecture import reponse_reussite
    phrases = []
    for s, phase in sorties:
        if phase == "test" and suite is None:
            # Test d'étape des bâtiments : un script SceneTree, pas GdUnit4.
            ok = [l for l in s.texte.splitlines() if l.startswith("ok")]
            if s.code != 0 or not ok or "SCRIPT ERROR" in s.texte or "ÉCHEC" in s.texte:
                return None
            phrases.append(f"Le test de l'étape passe : {len(ok)} ligne{'s' if len(ok) > 1 else ''} « ok », aucun "
                           "« ÉCHEC » ni « SCRIPT ERROR », code de sortie 0.")
            continue
        r = reponse_reussite(phase, s.texte, s.code)
        if r is None:
            return None
        if phase == "analyse":
            phrases.append("Analyse propre, code de sortie 0 : le script se charge.")
        else:
            resume = profil.resume_gdunit(s.texte)
            juges = ((f"les {len(cas)} cas qui échouaient sans {quoi} passent" if len(cas) > 1 else
                      f"le cas qui échouait sans {quoi} passe") if cas else
                     "le cas écrit passe" if not quoi else "la suite passe")
            phrases.append(f"Tests : {juges} ({resume[0] if resume else '?'} cas, 0 erreur, 0 échec, aucune "
                           "« SCRIPT ERROR », code 0).")
    return "**Lire.** " + " ".join(phrases) + "\n\n**Suite.** Vérifié : on n'y retouche plus, on passe à la suite."


def paire(famille: str, sujet: str, ident: str, demande: str, ecrire: list[str], api: list[str], tester: list[str],
          sorties: list[tuple[Any, str]], lire: str, preuve: dict[str, Any], palier_1: bool,
          demande_2: str | None = None) -> tuple[list[dict[str, Any]], str]:
    """Les paires de création d'un même travail vérifié, et la raison s'il n'y en a aucune :
    - au palier 1 (sans le plan, `palier_1` : le plan n'y joue aucun rôle), avec sa boucle si elle tient dans 1 024
      jetons, au besoin sans la vérification de l'API ; c'est alors la seule ;
    - sinon, au palier 1 sans la boucle (les commandes écrites en fin de réponse, leur sortie non écrite, règle 7.2),
      et au palier 2 avec la boucle et le plan (`demande_2` : la demande du palier 2, par défaut la même). Le palier 1
      garde ainsi toute la création ; le palier 2 reçoit la version qui vérifie (2026-10-28)."""
    from usine.paires import creation as cf

    def faire(texte: list[str], palier: int) -> dict[str, Any]:
        d = demande if palier == 1 or demande_2 is None else demande_2
        return fmt.paire_tours(famille, sujet, "création", tours(ident, d, "\n".join(texte), sorties, lire),
                               dict(preuve, palier=palier), systeme=fmt.plan() if palier == 2 else None)

    sortie: list[dict[str, Any]] = []
    if palier_1:
        for texte in (ecrire + api + tester, ecrire + tester):
            q = faire(texte, 1)
            if q["jetons"] <= cf.PLAFOND_COURT:
                return [q], ""
        commandes = ["```", *(f"$ {s.commande}" for s, _ in sorties), "```"]
        for texte in (ecrire + api + tester, ecrire + tester):
            court = fmt.paire(famille, sujet, "création", demande, "\n".join(texte + commandes),
                              dict(preuve, palier=1, boucle=False))
            if court["jetons"] <= cf.PLAFOND_COURT:
                sortie.append(court)
                break
    for texte in (ecrire + api + tester, ecrire + tester):
        q = faire(texte, 2)
        if q["jetons"] <= cf.PLAFOND:
            sortie.append(q)
            break
    return sortie, "" if sortie else f"trop longue ({q['jetons']} jetons)"


def tours(ident: str, demande: str, texte: str, sorties: list[tuple[Any, str]], lire: str) -> list[dict[str, Any]]:
    """Demande ; réponse avec les appels `shell` ; leurs vrais retours ; lecture."""
    appels = [fmt.appel(f"{ident}_{i}", "shell", {"command": commande_shell(s.commande)})
              for i, (s, _) in enumerate(sorties)]
    sortie: list[dict[str, Any]] = [{"role": "user", "content": demande},
                                    {"role": "assistant", "content": texte, "tool_calls": appels}]
    for i, (s, phase) in enumerate(sorties):
        sortie.append({"role": "tool", "tool_call_id": f"{ident}_{i}", "content": retour(s, phase)})
    sortie.append({"role": "assistant", "content": lire})
    return sortie
