"""Familles de paires « erreur de compilation → ligne corrigée » (étape B1) et « erreur de shader → correction »
(étape B2 du suivi).

Le code vérifié des cours de jeu (kart, roguelike), étape par étape, reçoit une seule faute du poseur des cours
(`usine/cours/base/mutations.py`). Scripts (B1) : nom de Godot 3, annotation sans @, déclaration sans type, type
faux, paramètre ou retour sans type, appel à une fonction absente ; Godot 4.7.2 analyse le script (`--check-only`,
avertissements traités en erreurs, typage compris). Shaders (B2) : nom de Godot 3, flottant écrit entier,
déclaration float écrite int ; un shader ne se compile qu'au rendu (règle 5.4) : Godot rend en Compatibilité la plus
petite scène qui le charge, et la ligne « at: » fait foi (règle 5.6).

La paire n'est gardée que si Godot signale exactement cette ligne, et rien d'autre, et si la même commande passe une
fois la ligne corrigée. Demande : la sortie réelle et le passage du code ; réponse : « Lire », « Chercher »
(l'explication sourcée des sessions des cours), « Corriger », puis la commande à relancer (sa sortie n'est pas
écrite, règle 7.2). Paires de 1 024 jetons au plus, sans plan : un réflexe où le plan ne joue aucun rôle (exception
de la section 3).

    python -m usine.paires compilation [--cours kart] [--par-etape N] [--graine G] [--etapes 1,2]
    python -m usine.paires shader [--cours kart] [--par-etape N] [--graine G] [--etapes 1,2]
"""

from __future__ import annotations

import json
import random
from pathlib import Path
from typing import Any, Callable

from usine.paires import format as fmt

PLAFOND = 1024
GENRES = {"compilation": ("godot3_annotation", "godot3_nom", "non_type", "type", "parametre", "retour", "appel"),
          "shader": ("godot3_shader", "shader_type", "shader_litteral")}
SHADERS = (".gdshader", ".gdshaderinc")


def _sujet(ville: str, n: int, famille: str) -> str:
    if famille == "shader":
        return "shaders"
    from usine.cours.base import exporter, notes
    piste = notes.lire(ville, n).piste
    return next((exporter.SUJETS_PISTES.get(p.strip()) for p in piste.split("+")
                 if exporter.SUJETS_PISTES.get(p.strip())), "gameplay")


def candidates(apres: dict[str, str], fichiers: list[str], famille: str = "compilation") -> list[Any]:
    from usine.cours.base import mutations
    sortie = []
    for rel in fichiers:
        texte = apres[rel]
        toutes = set(range(1, len(texte.split("\n")) + 1))
        internes = mutations.appels_internes(rel, texte, toutes) if rel.endswith(".gd") else []
        sortie += [m for m in mutations.candidates(rel, texte, toutes) + internes if m.genre in GENRES[famille]]
    return sortie


def fichiers_a_fauter(apres: dict[str, str], famille: str) -> list[str]:
    from usine.cours.base import profil
    if famille == "shader":
        # Un shader qu'aucune scène ne charge ne se compilerait jamais : il ne peut pas donner de paire.
        return sorted(r for r in apres if r.endswith(SHADERS) and not r.startswith("addons/")
                      and (profil.scene_de_rendu(apres, [r]) is not None or _charge_par_la_principale(apres, r)))
    scripts = sorted(r for r in apres if r.endswith(".gd") and not r.startswith(("addons/", "7_tests/")))
    return profil.analysables(scripts, apres)[0]


def _charge_par_la_principale(apres: dict[str, str], rel: str) -> bool:
    from usine.cours.base import profil
    m = profil.MAIN.search(apres.get("project.godot", ""))
    return bool(m) and rel in profil.dependances(apres, m[1])


def paire(projet: Any, m: Any, sujet: str, famille: str = "compilation") -> tuple[dict[str, Any] | None, str]:
    """La paire d'une faute posée dans le projet de l'étape, ou (None, raison du rejet)."""
    from usine.cours.base import profil, sessions
    shader = famille == "shader"
    phase = "rendu" if shader else "analyse"
    cible = profil.scene_de_rendu(projet.apres, [m.fichier]) if shader else m.fichier
    projet.remettre()
    projet.poser(m, True)
    try:
        s = projet.lancer(phase, cible)
        vus = sessions.erreurs(s.texte)
        if list(vus) != [(m.fichier, m.ligne)]:
            return None, f"Godot signale {list(vus)[:3]} au lieu de la seule ligne {m.ligne}"
        lire, chercher, corriger = sessions.parties_correction(projet, phase, s, vus, [m])
        if shader:
            quoi = (f"Le rendu en Compatibilité{f' de `{cible}`' if cible else ' de la scène principale'}, qui "
                    f"compile `res://{m.fichier}`, donne :")
        else:
            quoi = f"L'analyse de `res://{m.fichier}` (avertissements traités en erreurs, typage compris) donne :"
        demande = f"Projet Godot 4.7.2. {quoi}\n{sessions.tour_sortie(projet, phase, s, [m])}\n\nCorrige l'erreur."
        reponse = "\n".join(lire + [""] + chercher + [""] + corriger
                            + ["", "**Tester.** Je relance la même commande :", f"```\n$ {s.commande}\n```"])
        projet.poser(m, False)
        apres = projet.lancer(phase, cible)
        if not sessions.propre(phase, apres):
            return None, ("le rendu" if shader else "l'analyse") + " ne passe pas une fois la ligne corrigée"
    finally:
        projet.remettre()
    return fmt.paire(famille, sujet, "débogage", demande, reponse,
                     {"outil": "rendu" if shader else "--check-only", "commande": s.commande, "sortie": s.texte,
                      "code": s.code, "sortie_apres": apres.texte, "code_apres": apres.code,
                      "etape": f"{projet.ville}-{projet.n:03d}", "fichier": m.fichier,
                      "ligne": m.ligne, "genre": m.genre}), ""


def generer(cours: str = "kart", par_etape: int = 6, graine: int = 1, etapes: list[int] | None = None,
            donnees: Path | None = None, journal: Callable[[str], None] = print,
            famille: str = "compilation") -> dict[str, Any]:
    """`par_etape` fautes tirées par étape, réparties entre les genres présents (graine fixe)."""
    from usine.cours.base import assembler, chemins, creation, sessions
    chemins.configurer(cours=cours)
    sortie = fmt.dossier(famille, donnees)
    paires: list[dict[str, Any]] = []
    rejets: list[str] = []
    rng = random.Random(graine)
    for ville in assembler.ordre_lignes():
        for n in etapes or list(assembler.etapes_du_cours()):
            _, apres = creation.etats(ville, n)
            dispo = candidates(apres, fichiers_a_fauter(apres, famille), famille)
            if not dispo:
                continue
            # Les genres à tour de rôle, pour qu'aucun ne remplisse l'étape (règle 7.7).
            par_genre: dict[str, list[Any]] = {}
            for m in dispo:
                par_genre.setdefault(m.genre, []).append(m)
            for liste in par_genre.values():
                rng.shuffle(liste)
            choisies: list[Any] = []
            while len(choisies) < par_etape and any(par_genre.values()):
                for g in sorted(par_genre):
                    if par_genre[g] and len(choisies) < par_etape:
                        choisies.append(par_genre[g].pop())
            projet = sessions.Projet(ville, n, apres)
            sujet = _sujet(ville, n, famille)
            gardees = 0
            for m in choisies:
                p, raison = paire(projet, m, sujet, famille)
                if p is None:
                    rejets.append(f"{ville}-{n:03d} {m.fichier}:{m.ligne} {m.genre} : {raison}")
                    continue
                paires.append(p)
                gardees += 1
            journal(f"{ville}-{n:03d} : {gardees}/{len(choisies)} paires")
    trop_longues = [p for p in paires if p["jetons"] > PLAFOND]
    retenues = [p for p in paires if p["jetons"] <= PLAFOND]
    fmt.ecrire(retenues, sortie / f"paires_{cours}.jsonl")
    bilan: dict[str, Any] = {"famille": famille, "cours": cours, "paires": len(retenues),
                             "trop_longues": len(trop_longues), "rejets": rejets, "par_genre": {}, "par_sujet": {},
                             "jetons_max": max((p["jetons"] for p in retenues), default=0),
                             "jetons_moyens": round(sum(p["jetons"] for p in retenues) / max(len(retenues), 1))}
    for p in retenues:
        bilan["par_genre"][p["preuve"]["genre"]] = bilan["par_genre"].get(p["preuve"]["genre"], 0) + 1
        bilan["par_sujet"][p["sujet"]] = bilan["par_sujet"].get(p["sujet"], 0) + 1
    (sortie / f"bilan_{cours}.json").write_text(json.dumps(bilan, indent=1, ensure_ascii=False), encoding="utf-8")
    return bilan
