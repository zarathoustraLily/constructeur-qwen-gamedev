"""Famille de paires « écrire les lignes qui manquent dans une fonction » (création ; étape D1 du suivi, demande de
laurent du 2026-10-28 : « crée les paires manquantes qui soient EXTRÊMEMENT UTILES »).

Une fonction ne donnait qu'une paire de création (son corps entier, `creation.py`), alors qu'une étape de cours donne
jusqu'à 150 paires de débogage : la création manquait (ETAT, 2026-10-28). Ici, chaque instruction de premier niveau
du corps d'une fonction documentée (une ligne, ou un `if`, un `for`, un `while`, un `match` avec ses lignes, ses
`elif` et son `else`) devient un trou à combler, comme dans un vrai travail où l'on complète un passage précis.

Gardée seulement si :
- sans le bloc, le script passe l'analyse (avertissements en erreurs) ;
- sans le bloc, une suite de tests qui charge le script échoue (cours de jeu), ou l'empreinte des maillages change
  (bâtiments, `maillage.py`) : les tests jugent vraiment ces lignes ;
- avec le bloc, la même suite passe (l'état de l'étape), ou l'empreinte est celle de l'étape.

La demande montre le contrat, la fonction avec son trou et ce qu'elle emploie ; la réponse écrit les lignes, cite la
signature réelle des appels de Godot employés, puis lance l'analyse et les tests (sortie non écrite, règle 7.2).
Palier 1 sans le plan quand les lignes n'engagent aucune convention du plan (section 3), sinon palier 2.

    python -m usine.paires bloc [--cours kart] [--par-etape N] [--etapes 1,2]
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
from usine.paires import maillage

FAMILLE = "creation_bloc"
BLOC_MAX = 8
SUITES = ("elif", "else")


def _retrait(ligne: str) -> int:
    return len(ligne) - len(ligne.lstrip("\t"))


def _code(ligne: str) -> bool:
    texte = ligne.strip()
    return bool(texte) and not texte.startswith("#")


def blocs(lignes: list[str], f: Any) -> list[tuple[int, int]]:
    """Les instructions de premier niveau du corps de `f`, en intervalles [début, fin) de lignes : une ligne et
    les lignes plus en retrait qui la suivent, `elif` et `else` rattachés à leur `if`. Ni le corps entier, ni plus
    de BLOC_MAX lignes."""
    corps = [k for k in range(f.ligne_corps, f.ligne_fin) if _code(lignes[k])]
    if not corps:
        return []
    niveau = min(_retrait(lignes[k]) for k in corps)
    debuts = [k for k in corps if _retrait(lignes[k]) == niveau
              and not lignes[k].strip().startswith(SUITES)]
    sortie = []
    for i, d in enumerate(debuts):
        fin = debuts[i + 1] if i + 1 < len(debuts) else f.ligne_fin
        while fin > d + 1 and not _code(lignes[fin - 1]):
            fin -= 1
        if len(debuts) > 1 and fin - d <= BLOC_MAX:
            sortie.append((d, fin))
    return sortie


def sans_bloc(lignes: list[str], debut: int, fin: int) -> str:
    return "\n".join(lignes[:debut] + lignes[fin:])


DECLARATION = re.compile(r"^(\s*)var (\w+)\s*:\s*([\w\[\], ]+?)\s*=\s*\S.*$")


def variantes(texte: str, f: Any, debut: int, fin: int) -> list[str]:
    """Les versions du script sans les lignes du bloc à essayer pour le juge (la demande montre seulement le trou) :
    le bloc retiré ; une déclaration typée gardée avec la valeur nulle de son type (la suite de la fonction l'emploie) ;
    le dernier bloc d'une fonction qui rend une valeur remplacé par le retour de la valeur nulle (sinon « not all code
    paths return a value ») ; chacune aussi avec les avertissements que le retrait fait naître ignorés (`creation.IGNORES`)."""
    from types import SimpleNamespace

    from usine.generateurs.masquage import corps_vide
    from usine.projet.gdscript import lire_script
    lignes = texte.split("\n")
    s = lire_script(texte)
    retrait = "\t" * _retrait(lignes[debut])
    sortie = [sans_bloc(lignes, debut, fin)]
    m = DECLARATION.match(lignes[debut]) if fin - debut == 1 else None
    if m:
        neutre = corps_vide(SimpleNamespace(retour=m[3].strip()), s)
        if neutre.startswith("return ") and neutre != "return null":
            sortie.append("\n".join(lignes[:debut] + [f"{m[1]}var {m[2]}: {m[3].strip()} = {neutre[7:]}"] + lignes[fin:]))
    dernier = not any(_code(l) for l in lignes[fin:f.ligne_fin])
    if dernier and f.retour not in (None, "void"):
        sortie.append("\n".join(lignes[:debut] + [retrait + corps_vide(f, s)] + lignes[fin:]))
    ignores = "@warning_ignore_start(" + ", ".join(f'"{w}"' for w in cf.IGNORES) + ")"
    for v in list(sortie):
        ls = v.split("\n")
        k = 0
        while k < len(ls) and (not ls[k].strip() or ls[k].startswith(("@tool", "@icon", "class_name", "extends", "#"))):
            k += 1
        sortie.append("\n".join(ls[:k] + [ignores] + ls[k:]))
    return sortie


def fonction_trouee(lignes: list[str], f: Any, debut: int, fin: int) -> str:
    retrait = "\t" * _retrait(lignes[debut])
    return "\n".join(lignes[f.ligne_debut:debut] + [f"{retrait}# À écrire."] + lignes[fin:f.ligne_fin])


def contexte(original: str, f: Any, debut: int, fin: int) -> str:
    """Le contexte minimal de la fonction (`creation.contexte_minimal`), la fonction montrée entière avec son trou."""
    lignes = original.split("\n")
    entete = "\n".join(lignes[f.ligne_debut:f.ligne_corps])
    ctx = cf.contexte_minimal(original, f)
    return ctx.replace(f"{entete}\n{cf.TROU}", fonction_trouee(lignes, f, debut, fin), 1)


def paire(projet: Any, rel: str, f: Any, debut: int, fin: int, juge: dict[str, Any],
          sujet: str) -> tuple[dict[str, Any] | None, str]:
    """`juge` : {"suites", "passe"} (cours de jeu) ou {"scenes", "reference", "sortie_test", "test"} (bâtiments)."""
    from usine.cours.base import godot, profil, sessions
    original = projet.apres[rel]
    lignes = original.split("\n")
    projet.remettre()
    try:
        compile_ok = False
        for v in variantes(original, f, debut, fin):
            projet.ecrire(rel, v)
            if sessions.propre("analyse", projet.lancer("analyse", rel)):
                compile_ok = True
                break
        if not compile_ok:
            return None, "sans le bloc, le script ne passe pas l'analyse"
        if "scenes" in juge:
            if maillage.empreintes(projet, juge["scenes"]) == juge["reference"]:
                return None, "le maillage ne change pas sans le bloc : rien ne le juge"
            phrase = f"Le test de l'étape, `res://{juge['test']}`, construit le bâtiment et le vérifie."
            vu: dict[str, Any] = {"test": juge["test"], "maillage_change_sans_bloc": True,
                                  "maillage_identique_avec": True}
            cas: list[str] = []
            suite_lue = None
            tests = juge["sortie_test"]
            phrase_test = "le test de l'étape."
        else:
            attendus = profil.messages_attendus(projet.apres)
            rouge, sortie_rouge = None, ""
            for suite in juge["suites"][:3]:
                s = godot.tester_gdunit(projet.chemin, ["res://" + suite])
                if not profil.test_reussi(s.code, s.texte, attendus):
                    rouge, sortie_rouge = suite, s.texte
                    break
            if rouge is None:
                return None, "aucune suite n'échoue sans le bloc : les tests ne jugent pas ces lignes"
            projet.remettre()
            if rouge not in juge["passe"]:
                juge["passe"][rouge] = boucle.suite_passe(projet, rouge, attendus)
            if juge["passe"][rouge] is not True:
                return None, f"la suite ne passe pas sur l'état de l'étape ({juge['passe'][rouge]})"
            suite_texte = projet.apres[rouge]
            cas = boucle.cas_rouges(suite_texte, sortie_rouge, rouge)
            tests = godot.tester_gdunit(projet.chemin, ["res://" + rouge], ignorer=boucle.ecartes(suite_texte, cas, rouge))
            phrase, suite_lue = f"Les tests de `res://{rouge}` la vérifient.", rouge
            vu = {"suite": rouge, "rouge_sans_bloc": True, "vert_avec": True, "cas_rouges": cas}
            phrase_test = boucle.phrase_cas(suite_texte, cas)
        analyse = godot.verifier_script(projet.chemin, "res://" + rel)
    finally:
        projet.remettre()
    sorties = [(analyse, "analyse"), (tests, "test")]
    lire = boucle.lecture(sorties, "ces lignes", cas, suite_lue)
    if lire is None:
        return None, "la sortie de vérification ne passe pas la lecture"
    bloc = "\n".join(lignes[debut:fin])
    n = fin - debut
    tete = (f"Projet Godot 4.7.2. Dans `res://{rel}`, il manque {n} ligne{'s' if n > 1 else ''} à `{f.nom}`, à la place "
            f"de `# À écrire.` : écris-{'les' if n > 1 else 'la'} d'après le contrat (`##`) et le reste de la fonction. "
            f"{phrase}")
    ecrire = [f"**Écrire.** Les lignes qui manquent à `{f.nom}` :", f"```gdscript\n{bloc}\n```"]
    u = cf.usages("\n" + bloc, original)
    api = ["", "**Vérifier l'API.** Les appels de Godot employés, relus dans `extension_api.json` (4.7.2) :"] + u if u else []
    tester = ["", "**Tester.** J'analyse le script, puis je lance " + phrase_test]
    preuve = {"etape": f"{projet.ville}-{projet.n:03d}", "fichier": rel, "fonction": f.nom,
              "lignes": [debut + 1, fin], "analyse_sans_bloc": True, **vu,
              "commande_analyse": analyse.commande, "commande_test": tests.commande}
    demande = f"{tete} Ce que le script déclare et que la fonction emploie :\n```gdscript\n{contexte(original, f, debut, fin)}```"
    return boucle.paire(FAMILLE, sujet, f"verif_{f.nom}_{debut + 1}", demande, ecrire, api, tester, sorties, lire,
                        preuve, cf.sans_convention("\n" + bloc, projet.apres, original))


def generer(cours: str = "kart", par_etape: int = 60, graine: int = 1, etapes: list[int] | None = None,
            donnees: Path | None = None, journal: Callable[[str], None] = print) -> dict[str, Any]:
    """`par_etape` blocs tirés par étape (graine fixe), chaque bloc une seule fois dans le cours (clé sans numéro
    d'étape, `format.commun` ; règle 7.7)."""
    from usine.cours.base import assembler, chemins, creation, etat, sessions
    from usine.paires.execution import _sujet, suites_pour
    chemins.configurer(cours=cours)
    batiments = cours == "batiments_proceduraux"
    sortie = fmt.dossier(FAMILLE, donnees)
    paires: list[dict[str, Any]] = []
    rejets: list[str] = []
    rng = random.Random(graine)
    vues: set[tuple[str, str, str]] = set()
    for ville in assembler.ordre_lignes():
        for n in etapes or list(assembler.etapes_du_cours()):
            _, apres = creation.etats(ville, n)
            dispo = []
            for rel in sorted(apres):
                if not rel.endswith(".gd") or rel.startswith(("7_tests/", "addons/")):
                    continue
                if batiments and not rel.startswith(maillage.GENERATEURS):
                    continue
                if not batiments and not suites_pour(apres, rel):
                    continue
                lignes = apres[rel].split("\n")
                for f in cf.candidates(apres, rel):
                    for debut, fin in blocs(lignes, f):
                        cle = (fmt.commun(rel), fmt.commun(cf.texte_fonction(lignes, f)), str(debut - f.ligne_debut))
                        if cle not in vues:
                            dispo.append((rel, f, debut, fin, cle))
            if not dispo:
                continue
            rng.shuffle(dispo)
            projet = sessions.Projet(ville, n, apres)
            passe: dict[str, bool] = {}
            juge_batiment: dict[str, Any] = {}
            if batiments:
                test = creation.TEST.format(nom=etat.nom(ville, n))
                scenes = maillage.scenes_du_test(apres.get(test, ""))
                reference = maillage.empreintes(projet, scenes) if scenes else None
                t = projet.lancer("test")
                if (reference is None or maillage.empreintes(projet, scenes) != reference or t.code != 0
                        or "SCRIPT ERROR" in t.texte):
                    rejets.append(f"{ville}-{n:03d} : référence absente, non déterministe ou test qui échoue")
                    continue
                juge_batiment = {"scenes": scenes, "reference": reference, "sortie_test": t, "test": test}
            gardees = essais = 0
            for rel, f, debut, fin, cle in dispo:
                if gardees >= par_etape or essais >= par_etape * 2:
                    break
                essais += 1
                juge = juge_batiment or {"suites": suites_pour(apres, rel), "passe": passe}
                q, raison = paire(projet, rel, f, debut, fin, juge, _sujet(ville, n, rel))
                if not q:
                    rejets.append(f"{ville}-{n:03d} {rel} {f.nom} l.{debut + 1} : {raison}")
                    continue
                paires.extend(q if isinstance(q, list) else [q])
                vues.add(cle)
                gardees += 1
            journal(f"{ville}-{n:03d} : {gardees}/{essais} paires")
    fmt.ecrire(paires, sortie / f"paires_{cours}.jsonl")
    bilan: dict[str, Any] = {"famille": FAMILLE, "cours": cours, "paires": len(paires), "rejets": rejets,
                             "par_sujet": {}, "par_palier": {},
                             "jetons_max": max((p["jetons"] for p in paires), default=0),
                             "jetons_moyens": round(sum(p["jetons"] for p in paires) / max(len(paires), 1))}
    for p in paires:
        bilan["par_sujet"][p["sujet"]] = bilan["par_sujet"].get(p["sujet"], 0) + 1
        bilan["par_palier"][p["preuve"]["palier"]] = bilan["par_palier"].get(p["preuve"]["palier"], 0) + 1
    (sortie / f"bilan_{cours}.json").write_text(json.dumps(bilan, indent=1, ensure_ascii=False), encoding="utf-8")
    return bilan
