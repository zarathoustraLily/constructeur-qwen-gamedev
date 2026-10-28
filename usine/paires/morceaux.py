"""Famille de paires « écrire un changement d'un point de l'étape » (création ; procédural, étape D1 du suivi, demande
de laurent du 2026-10-28 : « il faut que tu reconstruises cette part »).

Le cours des bâtiments procéduraux, étape par étape : chaque changement contigu (morceau) qu'une étape apporte à un
générateur (`6_assets/Mesh/Procedural/`, `1_core/procedural/`) est rattaché au point de la note qui le décrit
(`usine/cours/base/rattacher.py`). Un point entier dépasse presque toujours 1 024 jetons (essai du kart) ; un morceau
y tient. La demande donne le texte du point, dit que le reste de l'étape est fait, et montre le code actuel là où le
morceau intervient ; la réponse écrit le changement sous la forme que `rejouer` sait appliquer (règle 5.7), cite la
signature réelle des appels de Godot employés, puis lance l'analyse et le test de l'étape (sortie non écrite, règle 7.2).

Juge des bâtiments : l'empreinte des maillages (`maillage.py`). Juge des cours de jeu (kart, roguelike) : les suites
GdUnit4 qui chargent le script (`execution.suites_pour`). Gardée seulement si :
- rejouée sur l'état sans le morceau, la consigne redonne exactement le fichier de l'étape ;
- sans le morceau, le script passe l'analyse (avertissements en erreurs) et le juge le voit : l'empreinte change (ou
  le bâtiment ne se construit plus), ou une suite échoue ;
- avec lui, c'est l'état de l'étape : empreinte vérifiée deux fois identique et test de l'étape qui passe, ou la
  même suite qui passe.

Palier 1 sans le plan quand il n'y joue aucun rôle (section 3), sinon palier 2 avec le plan.

    python -m usine.paires morceaux [--cours batiments_proceduraux] [--par-etape N] [--etapes 1,2]
"""

from __future__ import annotations

import json
import random
from pathlib import Path
from typing import Any, Callable

from usine.paires import boucle
from usine.paires import creation as cf
from usine.paires import format as fmt
from usine.paires import maillage

FAMILLE = "creation_morceau"
LIGNES_MAX = 25


def paire(projet: Any, note: Any, p: Any, sans: dict[str, str], rel: str, juge: dict[str, Any],
          sujet: str) -> tuple[dict[str, Any] | None, str]:
    """`juge` : {"scenes", "reference", "test", "sortie_test"} (bâtiments) ou {"suites", "passe"} (cours de jeu ;
    `passe` : suite → passe-t-elle sur l'état de l'étape, gardé d'un morceau à l'autre)."""
    from usine.cours.base import composer, etat, godot, profil, rejouer, sessions, textes
    apres = projet.apres
    morceaux = [m for m in etat.morceaux(sans, apres) if m.fichier == rel]
    if not morceaux:
        return None, "aucun changement"
    consignes = composer.editions(sans, apres, morceaux)
    obtenu, problemes = rejouer.rejouer(sans, consignes)
    if problemes:
        return None, "consigne non rejouable : " + problemes[0]
    if rejouer.comparer(obtenu, {rel: apres[rel]}, (".gd",)):
        return None, "consigne rejouée : le fichier diffère de l'étape"
    projet.remettre()
    try:
        projet.ecrire(rel, sans[rel])
        if not sessions.propre("analyse", projet.lancer("analyse", rel)):
            return None, "sans le morceau, le script ne passe pas l'analyse"
        if "scenes" in juge:
            sans_empreinte = maillage.empreintes(projet, juge["scenes"])
            if sans_empreinte == juge["reference"]:
                return None, "le maillage ne change pas sans le morceau : rien ne le juge"
            vu = {"test": juge["test"], "empreinte_reference": juge["reference"],
                  "empreinte_sans_morceau": sans_empreinte, "maillage_change_sans_morceau": True,
                  "maillage_identique_avec": True}
            phrase = f"Le test de l'étape, `res://{juge['test']}`, construit le bâtiment et le vérifie."
            tests, cas, suite_lue, phrase_test = juge["sortie_test"], [], None, "le test de l'étape."
        else:
            attendus = profil.messages_attendus(apres)
            rouge, sortie_rouge = None, ""
            for suite in juge["suites"][:3]:
                s = godot.tester_gdunit(projet.chemin, ["res://" + suite])
                if not profil.test_reussi(s.code, s.texte, attendus):
                    rouge, sortie_rouge = suite, s.texte
                    break
            if rouge is None:
                return None, "aucune suite n'échoue sans le morceau : les tests ne le jugent pas"
            projet.remettre()
            if rouge not in juge["passe"]:
                juge["passe"][rouge] = boucle.suite_passe(projet, rouge, attendus)
            if juge["passe"][rouge] is not True:
                return None, f"la suite ne passe pas sur l'état de l'étape ({juge['passe'][rouge]})"
            suite_texte = apres[rouge]
            cas = boucle.cas_rouges(suite_texte, sortie_rouge, rouge)
            tests = godot.tester_gdunit(projet.chemin, ["res://" + rouge], ignorer=boucle.ecartes(suite_texte, cas, rouge))
            vu = {"suite": rouge, "rouge_sans_morceau": True, "vert_avec": True, "cas_rouges": cas}
            phrase, suite_lue = f"Les tests de `res://{rouge}` le vérifient.", rouge
            phrase_test = boucle.phrase_cas(suite_texte, cas)
        analyse = godot.verifier_script(projet.chemin, "res://" + rel)
    finally:
        projet.remettre()
    sorties = [(analyse, "analyse"), (tests, "test")]
    lire = boucle.lecture(sorties, "ce changement", cas, suite_lue)
    if lire is None:
        return None, "la sortie de vérification ne passe pas la lecture"
    nom_projet, _ = textes.projet(note.ville)
    titre = note.titre.split("·")[-1].strip()
    demande = "\n".join([
        f"Projet Godot 4.7.2 : {nom_projet}. Étape {note.etape:03d} — {titre}. On réalise ce point :", "",
        f"### {p.titre}", composer.sans_code(p.texte), "",
        f"Le reste de l'étape est fait ; il manque un changement dans `res://{rel}`. Le code actuel, là où il intervient :",
        "", composer.extraits_actuels(sans, morceaux), "",
        phrase])
    ecrire = ["**Écrire.** Le changement :", "", consignes]
    v_api = composer.verifications_api(apres, morceaux)
    api = ["", "**Vérifier l'API.** Les appels de Godot employés, relus dans `extension_api.json` (4.7.2) :"] + v_api if v_api else []
    tester = ["", "**Tester.** J'analyse le script, puis je lance " + phrase_test]
    preuve = {"etape": f"{note.ville}-{note.etape:03d}", "point": p.numero, "titre": p.titre, "fichier": rel,
              "rejoue": True, "analyse_sans_morceau": True, **vu,
              "commande_analyse": analyse.commande, "commande_test": tests.commande}
    nouvelles = "\n".join(l for m in morceaux for l in m.nouvelles)
    return boucle.paire(FAMILLE, sujet, f"verif_point_{p.numero}", demande, ecrire, api, tester, sorties, lire, preuve,
                        cf.sans_convention("\n" + nouvelles, apres, apres[rel]))


def generer(cours: str = "batiments_proceduraux", par_etape: int = 40, graine: int = 1,
            etapes: list[int] | None = None, donnees: Path | None = None,
            journal: Callable[[str], None] = print) -> dict[str, Any]:
    """`par_etape` morceaux tirés par étape et par ville (graine fixe), chaque morceau une seule fois dans le cours
    (clé sans numéro d'étape, `format.commun` ; règle 7.7)."""
    from usine.cours.base import assembler, chemins, creation, etat, notes, rattacher, sessions
    from usine.paires.execution import _sujet, suites_pour
    chemins.configurer(cours=cours)
    batiments = cours == "batiments_proceduraux"
    sortie = fmt.dossier(FAMILLE, donnees)
    paires: list[dict[str, Any]] = []
    rejets: list[str] = []
    rng = random.Random(graine)
    vues: set[str] = set()
    for ville in assembler.ordre_lignes():
        for n in etapes or list(assembler.etapes_du_cours()):
            avant, apres = creation.etats(ville, n)
            note = notes.lire(ville, n)
            tous = rattacher.decouper(etat.morceaux(avant, apres))
            affect = rattacher.rattacher(note, tous, apres)
            points = {p.numero: p for p in note.points}
            dispo = []
            for m in tous:
                if (not m.fichier.endswith(".gd") or m.fichier not in avant or affect.get(m.id) not in points
                        or not 0 < len(m.nouvelles) <= LIGNES_MAX
                        or (batiments and not m.fichier.startswith(maillage.GENERATEURS))
                        or (not batiments and (m.fichier.startswith(("7_tests/", "addons/"))
                                               or not suites_pour(apres, m.fichier)))):
                    continue
                cle = "|".join(fmt.commun(x) for x in (m.fichier, "\n".join(m.anciennes), "\n".join(m.nouvelles)))
                if cle not in vues:
                    dispo.append((m, cle))
            if not dispo:
                continue
            rng.shuffle(dispo)
            projet = sessions.Projet(ville, n, apres)
            passe: dict[str, bool] = {}
            if batiments:
                test = creation.TEST.format(nom=etat.nom(ville, n))
                scenes = maillage.scenes_du_test(apres.get(test, ""))
                reference = maillage.empreintes(projet, scenes) if scenes else None
                t = projet.lancer("test")
                if reference is None or maillage.empreintes(projet, scenes) != reference:
                    rejets.append(f"{ville}-{n:03d} : empreinte de référence absente ou non déterministe")
                    continue
                if t.code != 0 or "SCRIPT ERROR" in t.texte:
                    rejets.append(f"{ville}-{n:03d} : le test de l'étape ne passe pas")
                    continue
            ids = {x.id for x in tous}
            gardees = essais = 0
            for m, cle in dispo:
                if gardees >= par_etape or essais >= par_etape * 2:
                    break
                essais += 1
                sans = etat.appliquer(avant, apres, ids - {m.id}, tous)
                p = points[affect[m.id]]
                juge = ({"scenes": scenes, "reference": reference, "test": test, "sortie_test": t}
                        if batiments else {"suites": suites_pour(apres, m.fichier), "passe": passe})
                q, raison = paire(projet, note, p, sans, m.fichier, juge, _sujet(ville, n, m.fichier))
                if q is None:
                    rejets.append(f"{ville}-{n:03d} {m.fichier}:{m.n1 + 1} (point {p.numero}) : {raison}")
                    continue
                paires.append(q)
                vues.add(cle)
                gardees += 1
            journal(f"{ville}-{n:03d} : {gardees}/{essais} paires")
    fmt.ecrire(paires, sortie / f"paires_{cours}.jsonl")
    bilan: dict[str, Any] = {"famille": FAMILLE, "cours": cours, "paires": len(paires),
                             "rejets": rejets, "par_sujet": {}, "par_palier": {},
                             "jetons_max": max((p["jetons"] for p in paires), default=0),
                             "jetons_moyens": round(sum(p["jetons"] for p in paires) / max(len(paires), 1))}
    for p in paires:
        bilan["par_sujet"][p["sujet"]] = bilan["par_sujet"].get(p["sujet"], 0) + 1
        bilan["par_palier"][p["preuve"]["palier"]] = bilan["par_palier"].get(p["preuve"]["palier"], 0) + 1
    (sortie / f"bilan_{cours}.json").write_text(json.dumps(bilan, indent=1, ensure_ascii=False),
                                                             encoding="utf-8")
    return bilan
