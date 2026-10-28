"""Famille de paires « écrire un cas de test GdUnit4 » (création ; sujet « création de tests », décision 2 ; demande de
laurent du 2026-10-28 : « des paires d'excellente qualité, qui enseignent vraiment à créer »).

Les suites GdUnit4 des cours de jeu (kart, roguelike, atelier), étape par étape : chaque cas (`func test_…`) devient
une paire. La demande donne la règle à vérifier (le nom du cas, la description `##` de la suite), ce que la suite
déclare déjà (constantes, variables, fonctions d'aide) et le contrat des fonctions du jeu que le cas appelle ; la
réponse écrit le cas, puis le lance seul (les autres cas écartés par `-i`) : la vraie sortie suit, puis sa lecture
(boucle.py).

Gardée seulement si le cas juge vraiment le code : seul (les autres écartés), il passe sur l'état de l'étape, et il
échoue quand le corps d'une fonction du jeu qu'il appelle est vidé (`creation.masque`, valeur nulle du type de retour,
script qui passe l'analyse). Un test qui passerait sur du code vide n'apprend rien.

    python -m usine.paires test_cas [--cours kart] [--par-etape N] [--etapes 1,2]
"""

from __future__ import annotations

import json
import random
import re
from pathlib import Path
from typing import Any, Callable

from usine.paires import boucle
from usine.paires import creation as cf
from usine.paires import format as fmt

FAMILLE = "creation_test"
SUJET = "création de tests"
CORPS_MAX = 30
APPEL = re.compile(r"\b([a-z_]\w*)\(")


def fonctions_du_jeu(apres: dict[str, str]) -> dict[str, list[tuple[str, Any]]]:
    """Nom → [(script, fonction)] des fonctions documentées des scripts du jeu (hors tests et extensions)."""
    from usine.projet.gdscript import lire_script
    sortie: dict[str, list[tuple[str, Any]]] = {}
    for rel, texte in apres.items():
        if not rel.endswith(".gd") or rel.startswith(("7_tests/", "addons/")):
            continue
        for f in lire_script(texte, "res://" + rel).fonctions:
            if not f.une_ligne and cf.contrat(texte.split("\n"), f):
                sortie.setdefault(f.nom, []).append((rel, f))
    return sortie


def appelees(corps: str, jeu: dict[str, list[tuple[str, Any]]]) -> list[tuple[str, Any]]:
    """Les fonctions du jeu que le corps d'un cas appelle, dans l'ordre de leur premier appel (un nom défini dans
    plusieurs scripts est ambigu : écarté)."""
    vus, sortie = set(), []
    for nom in APPEL.findall(corps):
        if nom in vus or len(jeu.get(nom, [])) != 1:
            continue
        vus.add(nom)
        sortie.append(jeu[nom][0])
    return sortie


def entete_suite(texte: str, s: Any) -> str:
    """Ce que la suite déclare avant ses cas : `extends`, sa description, constantes et variables, et ses fonctions
    d'aide (hors cas) en entier ; les cas sont omis."""
    lignes = texte.split("\n")
    garder = [k for k in range(len(lignes)) if not any(f.ligne_debut <= k < f.ligne_fin for f in s.fonctions)]
    aides = {k for f in s.fonctions if not f.nom.startswith("test_")
             for k in range(cf._doc_et_ligne(lignes, f.ligne_debut)[0], f.ligne_fin)}
    cas = {k for f in s.fonctions if f.nom.startswith("test_")
           for k in range(cf._doc_et_ligne(lignes, f.ligne_debut)[0], f.ligne_fin)}
    morceaux = [lignes[k] for k in sorted(set(garder) | aides) if k not in cas]
    return re.sub(r"\n{3,}", "\n\n", "\n".join(morceaux)).strip() + "\n"


def contrat_de(texte: str, f: Any) -> str:
    """La déclaration de la classe (`class_name` … `extends` …), puis le contrat et la signature de `f`."""
    lignes = texte.split("\n")
    debut = cf._doc_et_ligne(lignes, f.ligne_debut)[0]
    classe = [l for l in lignes[:12] if l.startswith(("class_name", "extends"))][:1]
    return "\n".join(classe + ([""] if classe else []) + lignes[debut:f.ligne_corps]) + "\n\t…"


def paire(projet: Any, suite: str, cas: Any, cibles: list[tuple[str, Any]],
          sujet: str) -> tuple[dict[str, Any] | None, str]:
    from usine.cours.base import godot, profil, sessions
    from usine.projet.gdscript import lire_script
    apres = projet.apres
    texte_suite = apres[suite]
    s = lire_script(texte_suite, "res://" + suite)
    autres = [f"{Path(suite).stem}:{f.nom}" for f in s.fonctions if f.nom.startswith("test_") and f.nom != cas.nom]
    attendus = profil.messages_attendus(apres)
    projet.remettre()
    juge = None
    try:
        vert = godot.tester_gdunit(projet.chemin, ["res://" + suite], ignorer=autres)
        if not profil.test_reussi(vert.code, vert.texte, attendus) or (profil.resume_gdunit(vert.texte) or (0,))[0] != 1:
            return None, "le cas seul ne passe pas sur l'état de l'étape"
        for rel, f in cibles[:3]:
            for vide in cf.masque(apres[rel], f):
                projet.ecrire(rel, vide)
                if sessions.propre("analyse", projet.lancer("analyse", rel)):
                    break
            else:
                projet.remettre()
                continue
            rouge = godot.tester_gdunit(projet.chemin, ["res://" + suite], ignorer=autres)
            projet.remettre()
            if not profil.test_reussi(rouge.code, rouge.texte, attendus):
                juge = (rel, f)
                break
        if juge is None:
            return None, "aucune fonction vidée ne fait échouer le cas : il ne juge pas le code"
    finally:
        projet.remettre()
    lignes = texte_suite.split("\n")
    code_cas = "\n".join(lignes[cas.ligne_debut:cas.ligne_fin]).rstrip()
    contrats = "\n\n".join(f"`res://{rel}` :\n```gdscript\n{contrat_de(apres[rel], f)}\n```" for rel, f in cibles[:3])
    demande = (f"Projet Godot 4.7.2. Dans la suite GdUnit4 `res://{suite}`, écris le cas `{cas.nom}` : son nom dit la "
               f"règle qu'il vérifie. Ce que la suite déclare déjà (sa description dit ses règles) :\n```gdscript\n"
               f"{entete_suite(texte_suite, s)}```\nCe que le cas appelle dans le jeu :\n{contrats}")
    ecrire = [f"**Écrire.** Le cas `{cas.nom}` :", f"```gdscript\n{code_cas}\n```"]
    tester = ["", "**Tester.** Je lance ce cas seul ; les autres cas de la suite sont écartés par `-i`."]
    sorties = [(vert, "test")]
    lire = boucle.lecture(sorties, "", [], suite)
    if lire is None:
        return None, "la sortie de vérification ne passe pas la lecture"
    preuve = {"etape": f"{projet.ville}-{projet.n:03d}", "suite": suite, "cas": cas.nom, "vert_seul": True,
              "tue_le_vidage_de": f"{juge[0]}:{juge[1].nom}", "commande_test": vert.commande}
    return boucle.paire(FAMILLE, sujet, f"verif_{cas.nom}", demande, ecrire, [], tester, sorties, lire, preuve, True)


def generer(cours: str = "kart", par_etape: int = 40, graine: int = 1, etapes: list[int] | None = None,
            donnees: Path | None = None, journal: Callable[[str], None] = print) -> dict[str, Any]:
    """`par_etape` cas tirés par étape (graine fixe), chaque cas une seule fois dans le cours (règle 7.7)."""
    from usine.cours.base import assembler, chemins, creation, sessions
    from usine.projet.gdscript import lire_script
    chemins.configurer(cours=cours)
    sortie = fmt.dossier(FAMILLE, donnees)
    paires: list[dict[str, Any]] = []
    rejets: list[str] = []
    rng = random.Random(graine)
    vues: set[tuple[str, str]] = set()
    for ville in assembler.ordre_lignes():
        for n in etapes or list(assembler.etapes_du_cours()):
            _, apres = creation.etats(ville, n)
            jeu = fonctions_du_jeu(apres)
            dispo = []
            for suite in sorted(r for r in apres if r.startswith("7_tests/") and r.endswith(".gd")):
                texte = apres[suite]
                if "extends GdUnitTestSuite" not in texte:
                    continue
                lignes = texte.split("\n")
                for f in lire_script(texte, "res://" + suite).fonctions:
                    if not f.nom.startswith("test_") or f.ligne_fin - f.ligne_corps > CORPS_MAX:
                        continue
                    corps = "\n".join(lignes[f.ligne_corps:f.ligne_fin])
                    cibles = appelees(corps, jeu)
                    cle = (fmt.commun(suite), fmt.commun("\n".join(lignes[f.ligne_debut:f.ligne_fin])))
                    if cibles and cle not in vues:
                        dispo.append((suite, f, cibles, cle))
            if not dispo:
                continue
            rng.shuffle(dispo)
            projet = sessions.Projet(ville, n, apres)
            gardees = essais = 0
            for suite, f, cibles, cle in dispo:
                if gardees >= par_etape or essais >= par_etape * 2:
                    break
                essais += 1
                q, raison = paire(projet, suite, f, cibles, SUJET)
                if not q:
                    rejets.append(f"{ville}-{n:03d} {suite} {f.nom} : {raison}")
                    continue
                paires.extend(q if isinstance(q, list) else [q])
                vues.add(cle)
                gardees += 1
            journal(f"{ville}-{n:03d} : {gardees}/{essais} paires")
    fmt.ecrire(paires, sortie / f"paires_{cours}.jsonl")
    bilan: dict[str, Any] = {"famille": FAMILLE, "cours": cours, "paires": len(paires), "rejets": rejets,
                             "par_palier": {},
                             "jetons_max": max((p["jetons"] for p in paires), default=0),
                             "jetons_moyens": round(sum(p["jetons"] for p in paires) / max(len(paires), 1))}
    for p in paires:
        bilan["par_palier"][p["preuve"]["palier"]] = bilan["par_palier"].get(p["preuve"]["palier"], 0) + 1
    (sortie / f"bilan_{cours}.json").write_text(json.dumps(bilan, indent=1, ensure_ascii=False), encoding="utf-8")
    return bilan
