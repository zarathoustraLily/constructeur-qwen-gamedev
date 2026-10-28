"""Famille de paires « écrire une fonction d'après son contrat » (création ; morceaux de jeu, étape D1 du suivi).

Le code vérifié des cours de jeu (kart, roguelike), étape par étape : une fonction documentée (`##` au-dessus de
`func`, c'est le contrat) dont le corps est retiré. La demande montre le script, les autres fonctions réduites à
leur signature et à leur contrat, et la suite de tests qui la vérifie ; la réponse écrit la fonction, cite la
signature réelle de chaque appel de Godot qu'elle emploie (`extension_api.json` de 4.7.2), puis lance l'analyse du
script et les tests (leur sortie n'est pas écrite, règle 7.2).

Gardée seulement si les tests jugent vraiment la fonction : le script au corps vidé (valeur par défaut du type de
retour) passe l'analyse, et la suite échoue ; avec la fonction d'origine, la même suite passe.

Palier de 2 048 jetons, avec le plan en message système : écrire du code dans le projet engage ses principes (données
dans 5_data, ordre d'exécution nommé, dépendances déclarées), le plan y joue un rôle (section 3).

    python -m usine.paires creation [--cours kart] [--par-etape N] [--graine G] [--etapes 1,2]
"""

from __future__ import annotations

import json
import random
import re
from pathlib import Path
from typing import Any, Callable

from usine.paires import boucle
from usine.paires import format as fmt

PLAFOND = 2048
PLAFOND_COURT = 1024
FAMILLE = "creation_fonction"
CORPS_MIN, CORPS_MAX = 2, 25   # lignes de code du corps
USAGES_MAX = 4
TROU = "\t# À écrire."
# Avertissements que le vidage d'un corps fait naître (noms de debug/gdscript/warnings/ de la référence 4.7.2).
IGNORES = ("unused_parameter", "unused_private_class_variable", "unused_signal", "shadowed_variable")


def contrat(lignes: list[str], f: Any) -> list[str]:
    """Les lignes `##` juste au-dessus de `func`."""
    sortie: list[str] = []
    i = f.ligne_debut - 1
    while i >= 0 and lignes[i].lstrip().startswith("##"):
        sortie.insert(0, lignes[i])
        i -= 1
    return sortie


def corps(lignes: list[str], f: Any) -> list[str]:
    return [l for l in lignes[f.ligne_corps:f.ligne_fin] if l.strip() and not l.strip().startswith("#")]


def texte_fonction(lignes: list[str], f: Any) -> str:
    return "\n".join(lignes[f.ligne_debut:f.ligne_fin]).rstrip()


def candidates(apres: dict[str, str], rel: str) -> list[Any]:
    """Les fonctions d'un script qui peuvent devenir une paire : un contrat, un corps de taille raisonnable."""
    from usine.projet.gdscript import lire_script
    s = lire_script(apres[rel], "res://" + rel)
    return [f for f in s.fonctions if not f.une_ligne and contrat(s.lignes, f)
            and CORPS_MIN <= len(corps(s.lignes, f)) <= CORPS_MAX]


def script_a_trou(texte: str, cible: str) -> str:
    """Le script montré : la fonction cible sans corps (`TROU`), les autres réduites à leur signature (corps « … »)."""
    from usine.projet.gdscript import lire_script
    s = lire_script(texte)
    lignes = texte.split("\n")
    for f in sorted(s.fonctions, key=lambda f: -f.ligne_debut):
        if f.une_ligne:
            continue
        remplacement = [TROU] if f.nom == cible else ["\t…"]
        lignes[f.ligne_corps:f.ligne_fin] = remplacement
    return "\n".join(lignes).rstrip() + "\n"


# Les conventions du plan (`godot/socle_jeu/AGENTS.md`) qu'un corps de fonction peut employer : chemins de données,
# ordre d'exécution nommé, dépendances reçues par setup(), journal Trace. Un corps qui n'en emploie aucune (ni aucun
# autoload du projet) enseigne un réflexe où le plan ne joue aucun rôle : palier 1, sans plan (section 3).
CONVENTIONS = re.compile(r"res://|\bProcessOrder\b|\bsetup\(|\bTrace\b|_view\b")


def sans_convention(fonction: str, apres: dict[str, str], texte: str = "") -> bool:
    """Vrai si le corps n'emploie aucune convention du plan : ni `CONVENTIONS`, ni autoload, ni dépendance déclarée
    par `@export` (principe 4 du plan)."""
    from usine.cours.base import profil
    from usine.projet.gdscript import lire_script
    code = "\n".join(l.split("#", 1)[0] for l in fonction.split("\n")[1:])
    exportees = [v.nom for v in lire_script(texte).variables if v.exportee] if texte else []
    return not CONVENTIONS.search(code) and not any(re.search(rf"\b{a}\b", code) for a in profil.autoloads(apres)) \
        and not any(re.search(rf"\b{re.escape(v)}\b", code) for v in exportees)


def classes_du_projet(apres: dict[str, str]) -> dict[str, str]:
    """class_name → script, hors extensions et tests."""
    from usine.cours.base import profil
    sortie = {}
    for rel, t in apres.items():
        if rel.endswith(".gd") and not rel.startswith(("addons/", "7_tests/")):
            m = profil.CLASSE.search(t)
            if m:
                sortie[m[1]] = rel
    return sortie


def employes_ailleurs(texte: str, f: Any, apres: dict[str, str]) -> str:
    """Les déclarations d'autres scripts du projet que le corps emploie par une variable ou un paramètre typés de
    leur classe (`settings.max_speed` : la ligne `var max_speed` de la classe des réglages), avec leur `##`."""
    from usine.projet.gdscript import lire_script
    s = lire_script(texte)
    lignes = texte.split("\n")
    corps_txt = "\n".join(l.split("#", 1)[0] for l in lignes[f.ligne_corps:f.ligne_fin])
    classes = classes_du_projet(apres)
    types = {v.nom: v.type for v in s.variables if v.type} | {a.nom: a.type for a in f.arguments if a.type}
    blocs = []
    for nom, typ in types.items():
        champs = set(re.findall(rf"\b{re.escape(nom)}\.(\w+)", corps_txt))
        if typ not in classes or not champs or classes[typ] not in apres:
            continue
        autre_texte = apres[classes[typ]]
        autre = lire_script(autre_texte)
        autres_lignes = autre_texte.split("\n")
        garder = sorted({k for v in autre.variables if v.nom in champs for k in _doc_et_ligne(autres_lignes, v.ligne)}
                        | {k for g in autre.fonctions if g.nom in champs for k in _doc_et_ligne(autres_lignes, g.ligne_debut)})
        if garder:
            blocs.append(f"`res://{classes[typ]}` ({typ}) :\n```gdscript\n" + "\n".join(autres_lignes[k] for k in garder)
                         + "\n```")
    return "\n\n".join(blocs)


def _doc_et_ligne(lignes: list[str], k: int) -> list[int]:
    """L'indice d'une déclaration et celui des lignes `##` juste au-dessus."""
    debut = k
    while debut > 0 and lignes[debut - 1].lstrip().startswith("##"):
        debut -= 1
    return list(range(debut, k + 1))


def contexte_minimal(texte: str, f: Any) -> str:
    """Ce que la fonction emploie, dans l'ordre du script : `class_name` et `extends`, les variables, constantes,
    énumérations et signaux qu'elle nomme (avec leur `##`), la signature et le contrat des fonctions qu'elle appelle,
    puis son propre contrat et sa signature, corps à écrire."""
    from usine.projet.gdscript import lire_script
    s = lire_script(texte)
    lignes = texte.split("\n")
    corps_txt = "\n".join(l.split("#", 1)[0] for l in lignes[f.ligne_corps:f.ligne_fin])
    nomme = lambda nom: re.search(rf"\b{re.escape(nom)}\b", corps_txt) is not None  # noqa: E731
    garder: set[int] = {k for k in range(s.fin_entete) if lignes[k].startswith(("class_name", "extends", "@tool"))}
    for v in s.variables:
        if nomme(v.nom):
            garder |= set(_doc_et_ligne(lignes, v.ligne))
    for sg in s.signaux:
        if nomme(sg.nom):
            garder |= set(_doc_et_ligne(lignes, sg.ligne))
    for k, l in enumerate(lignes):
        m = re.match(r"^(?:const|enum)\s+(\w+)", l)
        if m and nomme(m[1]):
            fin = k
            while l.startswith("enum") and "}" not in lignes[fin] and fin + 1 < len(lignes):
                fin += 1
            garder |= set(_doc_et_ligne(lignes, k)) | set(range(k, fin + 1))
    blocs: dict[int, list[str]] = {}
    for g in s.fonctions:
        if g.nom == f.nom or (not g.une_ligne and re.search(rf"\b{re.escape(g.nom)}\(", corps_txt)):
            debut = _doc_et_ligne(lignes, g.ligne_debut)[0]
            signature = lignes[g.ligne_debut:g.ligne_corps] if not g.une_ligne else [g.signature() + ":"]
            blocs[debut] = lignes[debut:g.ligne_debut] + signature + [TROU if g.nom == f.nom else "\t…"]
    morceaux: list[tuple[int, list[str]]] = [(k, [lignes[k]]) for k in sorted(garder)] + sorted(blocs.items())
    sortie: list[str] = []
    precedent = None
    for k, contenu in sorted(morceaux, key=lambda x: x[0]):
        if precedent is not None and (k != precedent + 1 or k in blocs):
            sortie.append("")
        sortie += contenu
        precedent = k + len(contenu) - 1 if k not in blocs else 10 ** 9
    return "\n".join(sortie).rstrip() + "\n"


def masque(texte: str, f: Any) -> list[str]:
    """Les versions du script au corps vidé à essayer : telle quelle, puis avec les avertissements que le vidage
    lui-même fait naître ignorés (`IGNORES`, traités en erreur, ils empêcheraient le script de se charger : paramètre
    ou variable de classe que seul ce corps employait). Elles ne servent qu'à vérifier que les tests jugent la
    fonction ; la demande ne les montre pas."""
    from usine.generateurs.masquage import vider_fonction
    vide = vider_fonction(texte, f.nom)
    lignes = vide.split("\n")
    # Après l'en-tête (@tool, class_name, extends) : l'annotation vaut pour la suite du fichier.
    k = 0
    while k < len(lignes) and (not lignes[k].strip() or lignes[k].startswith(("@tool", "@icon", "class_name",
                                                                                "extends", "#"))):
        k += 1
    lignes.insert(k, "@warning_ignore_start(" + ", ".join(f'"{w}"' for w in IGNORES) + ")")
    return [vide, "\n".join(lignes)]


def usages(texte_f: str, script: str) -> list[str]:
    from usine.cours.base import api
    return [f"- `{sig}`" + (f" : {desc}" if desc else "") for sig, desc in
            api.usages_gdscript(texte_f.split("\n")[1:], script)[:USAGES_MAX]]


def paire(projet: Any, rel: str, f: Any, suites: list[str], sujet: str,
          passe: dict[str, Any]) -> tuple[dict[str, Any] | None, str]:
    """La paire d'une fonction de l'étape, ou (None, raison du rejet). `passe` : suite → passe-t-elle sur l'état
    d'origine (gardé d'une fonction à l'autre de la même étape)."""
    from usine.cours.base import godot, profil, sessions
    original = projet.apres[rel]
    attendus = profil.messages_attendus(projet.apres)
    projet.remettre()
    try:
        compile_ok = None
        for vide in masque(original, f):
            projet.ecrire(rel, vide)
            if sessions.propre("analyse", projet.lancer("analyse", rel)):
                compile_ok = vide
                break
        if compile_ok is None:
            return None, "le script au corps vidé ne passe pas l'analyse"
        rouge = None
        sortie_rouge = ""
        for suite in suites[:3]:
            s = godot.tester_gdunit(projet.chemin, ["res://" + suite])
            if not profil.test_reussi(s.code, s.texte, attendus):
                rouge, sortie_rouge = suite, s.texte
                break
        if rouge is None:
            return None, "aucune suite n'échoue sans le corps : les tests ne jugent pas cette fonction"
        projet.remettre()
        if rouge not in passe:
            passe[rouge] = boucle.suite_passe(projet, rouge, attendus)
        if passe[rouge] is not True:
            return None, f"la suite ne passe pas avec la fonction d'origine ({passe[rouge]})"
        analyse = godot.verifier_script(projet.chemin, "res://" + rel)
        # Seulement les cas qui jugent la fonction (ceux qui échouaient sans elle) : les autres écartés par `-i`.
        cas = boucle.cas_rouges(projet.apres[rouge], sortie_rouge, rouge)
        tests = godot.tester_gdunit(projet.chemin, ["res://" + rouge], ignorer=boucle.ecartes(projet.apres[rouge], cas, rouge))
    finally:
        projet.remettre()
    fonction = texte_fonction(original.split("\n"), f)
    tete = (f"Projet Godot 4.7.2. Dans `res://{rel}`, écris le corps de `{f.nom}` d'après son contrat (les commentaires "
            f"`##`). Les tests de `res://{rouge}` le vérifient.")
    ecrire = [f"**Écrire.** `{f.nom}`, d'après son contrat :", f"```gdscript\n{fonction}\n```"]
    u = usages(fonction, original)
    api = ["", "**Vérifier l'API.** Les appels de Godot employés, relus dans `extension_api.json` (4.7.2) :"] + u if u else []
    tester = ["", "**Tester.** J'analyse le script, puis je lance " + boucle.phrase_cas(projet.apres[rouge], cas)]
    # La boucle de vérification (boucle.py) : les vraies sorties, puis leur lecture.
    sorties = [(analyse, "analyse"), (tests, "test")]
    lire = boucle.lecture(sorties, f"`{f.nom}`", cas, rouge)
    if lire is None:
        return None, "la sortie de vérification ne passe pas la lecture"
    preuve = {"etape": f"{projet.ville}-{projet.n:03d}", "fichier": rel, "fonction": f.nom, "suite": rouge,
              "masque_compile": True, "rouge_sans_corps": True, "vert_avec": True, "cas_rouges": cas,
              "commande_analyse": analyse.commande, "sortie_analyse": analyse.texte,
              "commande_tests": tests.commande, "code_tests": tests.code}
    ailleurs = employes_ailleurs(original, f, projet.apres)
    ailleurs = f"\n\nCe que la fonction emploie d'autres scripts du projet :\n{ailleurs}" if ailleurs else ""

    # Palier 1 quand le plan n'y joue aucun rôle (section 3) : le contexte réduit à ce que la fonction emploie. Au
    # palier 2, le script entier (les autres fonctions réduites à leur signature), sauf s'il est trop long.
    minimale = (f"{tete} Ce que le script déclare et que la fonction emploie :\n```gdscript\n"
                f"{contexte_minimal(original, f)}```{ailleurs}")
    entiere = (f"{tete} Le script (les autres fonctions réduites à leur signature) :\n```gdscript\n"
               f"{script_a_trou(original, f.nom)}```{ailleurs}")
    palier_1 = sans_convention(fonction, projet.apres, original)
    for demande_2 in (entiere, minimale):
        qs, raison = boucle.paire(FAMILLE, sujet, f"verif_{f.nom}", minimale, ecrire, api, tester, sorties, lire,
                                  preuve, palier_1, demande_2)
        if any(q["preuve"]["palier"] == 2 for q in qs) or (qs and demande_2 is minimale):
            return qs, ""
    return qs, raison


def generer(cours: str = "kart", par_etape: int = 4, graine: int = 1, etapes: list[int] | None = None,
            donnees: Path | None = None, journal: Callable[[str], None] = print) -> dict[str, Any]:
    """`par_etape` fonctions tirées par étape (graine fixe), chaque fonction une seule fois dans le cours (règle 7.7)."""
    from usine.cours.base import assembler, chemins, creation, sessions
    from usine.paires.compilation import fichiers_a_fauter
    from usine.paires.execution import _sujet, suites_pour
    chemins.configurer(cours=cours)
    sortie = fmt.dossier(FAMILLE, donnees)
    paires: list[dict[str, Any]] = []
    rejets: list[str] = []
    rng = random.Random(graine)
    vues: set[tuple[str, str]] = set()
    for ville in assembler.ordre_lignes():
        for n in etapes or list(assembler.etapes_du_cours()):
            _, apres = creation.etats(ville, n)
            dispo = []
            for rel in fichiers_a_fauter(apres, "compilation"):
                lignes = apres[rel].split("\n")
                for f in candidates(apres, rel):
                    cle = (fmt.commun(rel), fmt.commun(texte_fonction(lignes, f)))
                    if cle not in vues and suites_pour(apres, rel):
                        dispo.append((rel, f, cle))
            if not dispo:
                continue
            rng.shuffle(dispo)
            projet = sessions.Projet(ville, n, apres)
            passe: dict[str, bool] = {}
            gardees = essais = 0
            for rel, f, cle in dispo:
                if gardees >= par_etape or essais >= par_etape * 3:
                    break
                essais += 1
                p, raison = paire(projet, rel, f, suites_pour(apres, rel), _sujet(ville, n, rel), passe)
                if not p:
                    rejets.append(f"{ville}-{n:03d} {rel} {f.nom} : {raison}")
                    continue
                paires.extend(p if isinstance(p, list) else [p])
                vues.add(cle)
                gardees += 1
            journal(f"{ville}-{n:03d} : {gardees}/{essais} paires")
    trop_longues = [p for p in paires if p["jetons"] > PLAFOND]
    retenues = [p for p in paires if p["jetons"] <= PLAFOND]
    fmt.ecrire(retenues, sortie / f"paires_{cours}.jsonl")
    bilan: dict[str, Any] = {"famille": FAMILLE, "cours": cours, "paires": len(retenues),
                             "trop_longues": len(trop_longues), "rejets": rejets, "par_sujet": {},
                             "jetons_max": max((p["jetons"] for p in retenues), default=0),
                             "jetons_moyens": round(sum(p["jetons"] for p in retenues) / max(len(retenues), 1))}
    bilan["par_palier"] = {}
    for p in retenues:
        bilan["par_sujet"][p["sujet"]] = bilan["par_sujet"].get(p["sujet"], 0) + 1
        bilan["par_palier"][p["preuve"]["palier"]] = bilan["par_palier"].get(p["preuve"]["palier"], 0) + 1
    (sortie / f"bilan_{cours}.json").write_text(json.dumps(bilan, indent=1, ensure_ascii=False), encoding="utf-8")
    return bilan
