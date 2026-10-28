"""Famille « réaliser un point de l'étape d'après sa description » (création ; morceaux de jeu point par point,
étape D1 du suivi, décisions 8 et 18.3).

Chaque note de cours (`cours/<cours>/notes/etape_NNN.md`) découpe l'étape en points (`### N. Titre`) : un texte qui
décrit un morceau du jeu. Le code que l'étape ajoute est rattaché à ses points (`usine/cours/base/rattacher.py`,
le même rattachement que les sessions de création des cours). Les points se suivent dans l'ordre de la note : pour le
point p, l'état de départ est l'étape précédente plus les points 1 à p − 1 (code et tests) et les tests du point p ;
l'état d'arrivée y ajoute le code du point p. La demande est le texte du point et le code actuel là où il intervient ;
la réponse écrit les changements, fichier par fichier, sous la forme que `rejouer` sait appliquer (règle 5.7), cite
la signature réelle des appels de Godot employés, puis lance les tests (leur sortie n'est pas écrite, règle 7.2).

Gardée seulement si :
- rejouées sur l'état de départ, les consignes redonnent exactement l'état d'arrivée ;
- au départ, les tests du point (ceux que le point ajoute, sinon ceux que l'étape touche jusque-là) échouent, sans
  faute d'analyse dans le code du jeu ; à l'arrivée, les mêmes tests passent ;
- un point qui touche un shader garde le même juge (les tests) ; son shader est compilé par le rendu de l'état
  de l'étape, déjà vérifié sans erreur par `python -m usine.cours verifier` (règle 5.4), et la réponse demande ce
  rendu en Compatibilité après les tests.

Palier 2, avec le plan : écrire dans le projet engage ses principes (section 3). Plafond 2 048 jetons.

    python -m usine.paires points [--cours kart] [--etapes 1,2]
"""

from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any, Callable

from usine.paires import format as fmt

FAMILLE = "creation_point"
PLAFOND = 2048
SHADERS = (".gdshader", ".gdshaderinc")


def poser(projet: Any, etat_: dict[str, str]) -> None:
    """Le projet de l'étape mis dans l'état donné, pour les fichiers de code et de scène : un fichier absent de l'état
    est retiré du disque."""
    for rel in set(projet.apres) | set(etat_):
        if not rel.endswith((".gd", ".tscn", ".tres", ".gdshader", ".gdshaderinc")):
            continue
        chemin = os.path.join(projet.chemin, rel)
        if rel not in etat_:
            if os.path.exists(chemin):
                os.remove(chemin)
            projet.code.pop(rel, None)
            continue
        sur_le_disque = None
        if os.path.exists(chemin):
            with open(chemin, encoding="utf-8", newline="") as h:
                sur_le_disque = h.read()
        if sur_le_disque != etat_[rel]:
            os.makedirs(os.path.dirname(chemin), exist_ok=True)
            with open(chemin, "w", encoding="utf-8", newline="") as h:
                h.write(etat_[rel])
            projet.code[rel] = etat_[rel]


def remettre(projet: Any) -> None:
    poser(projet, projet.apres)


def faute_d_analyse(texte: str) -> bool:
    """Une faute d'analyse dans le code du jeu (hors des tests) : « Parse Error » dont la ligne « at: » est hors
    de `7_tests/`."""
    lignes = texte.split("\n")
    for i, l in enumerate(lignes):
        if "Parse Error" in l:
            suite = " ".join(lignes[i:i + 3])
            if "res://7_tests/" not in suite:
                return True
    return False


def paire(projet: Any, note: Any, p: Any, sans: dict[str, str], apres: dict[str, str], suites: list[str],
          sujet: str) -> tuple[dict[str, Any] | None, str]:
    """`sans` : l'état de départ du point ; `apres` : l'état d'arrivée (le point fait)."""
    from usine.cours.base import composer, etat, godot, profil, rejouer, textes
    morceaux = [m for m in etat.morceaux(sans, apres) if not m.fichier.startswith("7_tests/")]
    if not morceaux:
        return None, "aucun code rattaché au point"
    consignes = composer.editions(sans, apres, morceaux)
    obtenu, problemes = rejouer.rejouer(sans, consignes)
    if problemes:
        return None, "consignes non rejouables : " + problemes[0]
    ecarts = rejouer.comparer(obtenu, {m.fichier: apres[m.fichier] for m in morceaux}, etat.CODE + (".tscn", ".tres"))
    if ecarts:
        return None, f"consignes rejouées : {ecarts[0]} diffère de l'étape"
    attendus = profil.messages_attendus(apres)
    try:
        poser(projet, apres)
        v = godot.tester_gdunit(projet.chemin, suites)
        if not profil.test_reussi(v.code, v.texte, attendus):
            return None, "les tests du point ne passent pas avec le point"
        poser(projet, sans)
        rouge = godot.tester_gdunit(projet.chemin, suites)
    finally:
        remettre(projet)
    if profil.test_reussi(rouge.code, rouge.texte, attendus):
        return None, "sans le point, les tests passent : ils ne le jugent pas"
    if faute_d_analyse(rouge.texte):
        return None, "sans le point, le code du jeu ne s'analyse plus"
    nom_projet, _ = textes.projet(note.ville)
    titre = note.titre.split("·")[-1].strip()
    demande = "\n".join([
        f"Projet Godot 4.7.2 : {nom_projet}. Étape {note.etape:03d} — {titre}. "
        + (f"Les points 1 à {p.numero - 1} de l'étape sont faits ; " if p.numero > 1 else "")
        + "on fait ce point :", "", f"### {p.titre}", composer.sans_code(p.texte), "",
        "Les tests qui le vérifient : " + ", ".join(f"`{s}`" for s in suites) + ".", "",
        *(["Le code actuel, là où le point intervient :", "", extraits] if (extraits := composer.extraits_actuels(
            sans, morceaux)) else ["Le point ne modifie aucun fichier existant : tout est à créer."])])
    reponse = ["**Écrire.** Les changements, fichier par fichier :", "", consignes]
    api = composer.verifications_api(apres, morceaux)
    if api:
        reponse += ["", "**Vérifier l'API.** Les appels de Godot employés, relus dans `extension_api.json` (4.7.2) :"] + api
    shaders = sorted({m.fichier for m in morceaux if m.fichier.endswith(SHADERS)})
    if shaders:
        rendu = godot.commande(profil.arguments_rendu(profil.scene_de_rendu(apres, shaders)))
        reponse += ["", "**Tester.** Je lance les tests de l'étape, puis le jeu en Compatibilité : un shader ne se "
                    "compile qu'au rendu.", f"```\n$ {rouge.commande}\n$ {rendu}\n```"]
    else:
        reponse += ["", "**Tester.** Je lance les tests de l'étape :", f"```\n$ {rouge.commande}\n```"]
    preuve ={"etape": f"{note.ville}-{note.etape:03d}", "point": p.numero, "titre": p.titre,
              "fichiers": sorted({m.fichier for m in morceaux}), "suites": suites, "rejoue": True,
              "rouge_sans_le_point": True, "vert_avec": True, "code_rouge": rouge.code, "palier": 2,
              "shaders_rendus_par": "usine.cours verifier" if shaders else None}
    q = fmt.paire(FAMILLE, sujet, "création", demande, "\n".join(reponse), preuve, systeme=fmt.plan())
    if q["jetons"] > PLAFOND:
        return None, f"trop longue ({q['jetons']} jetons)"
    return q, ""


def generer(cours: str = "kart", etapes: list[int] | None = None, donnees: Path | None = None,
            journal: Callable[[str], None] = print) -> dict[str, Any]:
    from usine.cours.base import assembler, chemins, creation, etat, notes, profil, rattacher, sessions
    from usine.paires.execution import _sujet
    chemins.configurer(cours=cours)
    sortie = fmt.dossier(FAMILLE, donnees)
    paires: list[dict[str, Any]] = []
    rejets: list[str] = []
    for ville in assembler.ordre_lignes():
        for n in etapes or list(assembler.etapes_du_cours()):
            note = notes.lire(ville, n)
            avant, apres = creation.etats(ville, n)
            tous = rattacher.decouper(etat.morceaux(avant, apres))
            affect = rattacher.rattacher(note, tous, apres)
            par_id = {m.id: m for m in tous}
            # Le code que le rattachement ne donne à aucun point est fait d'emblée.
            fait = {m.id for m in tous if affect.get(m.id) not in {q.numero for q in note.points}}
            projet = None
            gardees = 0
            for p in note.points:
                du_point = {m.id for m in tous if affect.get(m.id) == p.numero}
                code = {i for i in du_point if not par_id[i].fichier.startswith("7_tests/")}
                tests_du_point = du_point - code
                if code:
                    sans = etat.appliquer(avant, apres, fait | tests_du_point, tous)
                    avec = etat.appliquer(avant, apres, fait | du_point, tous)
                    # Les tests du point ; à défaut, ceux que l'étape a touchés jusque-là.
                    touches = ({par_id[i].fichier for i in tests_du_point}
                               or {par_id[i].fichier for i in fait | du_point if par_id[i].fichier.startswith("7_tests/")})
                    suites = ["res://" + s for s in profil.suites(avec, touches)]
                    if not suites:
                        rejets.append(f"{ville}-{n:03d} point {p.numero} : aucune suite de tests jusque-là")
                    else:
                        if projet is None:
                            projet = sessions.Projet(ville, n, apres)
                        fichier = sorted(par_id[i].fichier for i in code)[0]
                        q, raison = paire(projet, note, p, sans, avec, suites, _sujet(ville, n, fichier))
                        if q is None:
                            rejets.append(f"{ville}-{n:03d} point {p.numero} ({p.titre}) : {raison}")
                        else:
                            paires.append(q)
                            gardees += 1
                fait |= du_point
            journal(f"{ville}-{n:03d} : {gardees} paire(s) sur {len(note.points)} points")
    fmt.ecrire(paires, sortie / f"paires_{cours}.jsonl")
    bilan: dict[str, Any] = {"famille": FAMILLE, "cours": cours, "paires": len(paires), "rejets": rejets,
                             "par_sujet": {}, "jetons_max": max((p["jetons"] for p in paires), default=0),
                             "jetons_moyens": round(sum(p["jetons"] for p in paires) / max(len(paires), 1))}
    for p in paires:
        bilan["par_sujet"][p["sujet"]] = bilan["par_sujet"].get(p["sujet"], 0) + 1
    (sortie / f"bilan_{cours}.json").write_text(json.dumps(bilan, indent=1, ensure_ascii=False), encoding="utf-8")
    return bilan
