"""Observation visuelle (O1 par l'image) : un défaut qui ne se voit qu'au rendu, injecté dans une étape du cours
« bâtiments procéduraux », devient une tâche « corriger en observant ».

Demande de laurent du 2026-10-20 : l'observation est primordiale, bâtiments compris ; Qwen regarde l'image.
Sources : les projets d'étape fabriqués du cours (python -m usine.cours fabriquer batiments_proceduraux).

1. Le projet d'étape est copié et importé une fois. Ses vues (la visite de jour, de nuit, sous un soleil rasant)
   sont rendues : ce sont les images de référence. Ses tests doivent passer.
2. Candidats : mutants des shaders (opérateurs de shader), des générateurs de maillage, des palettes et de l'outil
   de maillage commun (opérateurs GDScript qui changent une valeur, un calcul ou un appel), un par ligne, puis
   tirés à tour de rôle par opérateur, à graine fixe, au plus `essais`.
3. Chaque candidat est appliqué dans la copie, puis restauré :
   - une erreur au rendu (le shader ne compile plus, un script plante) l'écarte : « erreur_au_rendu » (c'est du
     débogage par les messages, déjà dans la base du cours) ;
   - si aucune vue ne change sur au moins visuel.PART_VISIBLE de l'image : « invisible » ;
   - si un test de l'étape échoue : « vu_par_les_tests » (une tâche K3, pas O1) ;
   sinon, seul l'œil le voit : c'est une tâche.
4. Tâche : depart = étape mutée ; reference = fichier d'origine ; tests_caches/observation_visuelle/ = les vues,
   leurs images de référence et les tests d'origine de l'étape ; juge = import, check_script, puis l'étape
   observation_visuelle (usine/observation/juge_visuel.py) ; patch plafonné. Le portillon confirme ensuite.

    python -m usine.generateurs.observation_visuelle <dossier des projets> --sortie <dossier>
           [--filtre parisien_etape_005] [--par-projet 4] [--essais 30] [--graine 0]
"""

from __future__ import annotations

import json
import random
import re
import sys
import tempfile
from pathlib import Path
from typing import Any

from usine.generateurs.commun import Production, ecrire_projet, ecrire_tache, ident, lire_projet
from usine.generateurs.mutation import tirer_un_par_ligne
from usine.generateurs.operateurs import SHADERS, Mutant, mutants_fichier
from usine.juge import godot as juges
from usine.juge.projet import preparer_copie
from usine.observation import juge_visuel, visuel

ORIGINE = "generateur:observation_visuelle"
COMPETENCE = "O1"
GENERATEUR = "observation_visuelle"
PATCH_MAX_LIGNES = 2
# Opérateurs GDScript qui changent ce qu'on voit sans casser la compilation : une valeur, un calcul, une
# condition, un appel (une surface ou une face qui n'est plus ajoutée).
OPERATEURS_GD_VISUELS = {"constante_modifiee", "operateur_arithmetique", "comparaison_inversee", "condition_niee",
                         "booleen_inverse", "appel_supprime"}


def consigne() -> str:
    return ("L'immeuble de cette étape ne ressemble pas à ce que décrit sa note (README.md) : un défaut se voit au "
            "rendu, alors que le projet compile et que ses tests passent. Regarde des images de la visite : lance le "
            "projet avec le rendu de compatibilité (--rendering-method gl_compatibility) et, après « -- », "
            "l'option --shot=<fichier.png>, seule pour le jour, avec --night pour la nuit, avec --sun=-12,60 pour un "
            "soleil rasant ; puis ouvre l'image. Trouve la cause dans le projet et corrige-la par un changement "
            "minimal, sans toucher au reste. Le juge rend ces trois vues : elles doivent être celles de l'immeuble "
            "attendu, et les tests de l'étape doivent passer.")


def fichier_cible(rel: str) -> bool:
    """Les fichiers où un défaut se voit au rendu : shaders, générateurs, palettes, outil de maillage commun."""
    if rel.endswith(SHADERS):
        return rel.startswith("6_assets/Shader/")
    return rel.endswith(".gd") and rel.startswith(("6_assets/Mesh/Procedural/", "5_data/DECORS/",
                                                   "1_core/procedural/"))


def candidats(projet: dict[str, str], essais: int, graine: str) -> list[Mutant]:
    """Mutants des fichiers cibles, un par ligne, puis tirés à tour de rôle par opérateur (graine fixe)."""
    mutants: list[Mutant] = []
    for rel in sorted(r for r in projet if fichier_cible(r)):
        ops = None if rel.endswith(SHADERS) else OPERATEURS_GD_VISUELS
        mutants += mutants_fichier(rel, projet[rel], operateurs=ops)
    mutants = tirer_un_par_ligne(mutants, graine)
    par_operateur: dict[str, list[Mutant]] = {}
    for m in mutants:
        par_operateur.setdefault(m.operateur, []).append(m)
    alea = random.Random(f"o1v:{graine}")
    for liste in par_operateur.values():
        alea.shuffle(liste)
    tires: list[Mutant] = []
    noms = sorted(par_operateur)
    while len(tires) < essais and any(par_operateur.values()):
        for nom in noms:
            if par_operateur[nom] and len(tires) < essais:
                tires.append(par_operateur[nom].pop())
    return tires


def court(nom_projet: str) -> str:
    """building_proceduraux_parisien_etape_005 → parisien_005."""
    m = re.search(r"([a-z]+)_etape_(\d+)$", nom_projet)
    return f"{m.group(1)}_{m.group(2)}" if m else ident(nom_projet)


def generer(source: Path, sortie: Path, par_projet: int = 4, essais: int = 30, graine: str = "0",
            afficher=None) -> Production:
    prod = Production()
    source = Path(source)
    nom = court(source.name)
    projet = lire_projet(source, source.name)
    vues = visuel.VUES_COURS
    tests_origine = {rel: t for rel, t in projet.items() if rel.startswith("7_tests/") and rel.endswith(".gd")}
    liste = candidats(projet, essais, f"{graine}:{nom}")
    with tempfile.TemporaryDirectory(prefix="usine_o1v_") as tmp:
        tmp = Path(tmp)
        copie = preparer_copie(ecrire_projet(projet, tmp / "src"), tmp / "copie")
        imp = juges.importer(copie)
        if not imp["ok"]:
            raise RuntimeError(f"{nom} : import en échec : " + "; ".join(e["message"] for e in imp["erreurs"]))
        references = visuel.rendre(copie, vues, tmp / "references")
        casses = {n: r["erreurs"] or ["aucune image"] for n, r in references.items() if r["erreurs"] or not r["image"]}
        if casses:
            raise RuntimeError(f"{nom} : le rendu de référence est en erreur : {casses}")
        if juge_visuel.lancer_tests(copie):
            raise RuntimeError(f"{nom} : les tests de l'étape échouent sur la référence")
        materiel: dict[str, str | bytes] = {"observation_visuelle/vues.json": json.dumps(vues, ensure_ascii=False,
                                                                                         indent=1) + "\n"}
        for n, r in references.items():
            materiel[f"observation_visuelle/{n}.png"] = Path(r["image"]).read_bytes()
        for rel, texte in tests_origine.items():
            materiel[f"observation_visuelle/tests/{rel}"] = texte
        for m in liste:
            if len(prod.taches) >= par_projet:
                break
            cid = ident(Path(m.fichier).stem.replace(source.name, "").strip("_") or Path(m.fichier).stem,
                        m.ligne, m.operateur, m.occurrence)
            cible = copie / m.fichier
            origine = projet[m.fichier]
            mute = m.appliquer(origine)
            cible.write_text(mute, encoding="utf-8", newline="\n")
            try:
                rendus = visuel.rendre(copie, vues, tmp / "candidat")
                erreurs = [l for r in rendus.values() for l in r["erreurs"]]
                if erreurs or not all(r["image"] for r in rendus.values()):
                    prod.ecarter(GENERATEUR, f"{nom}:{cid}", "erreur_au_rendu", (erreurs or ["aucune image"])[0][:200])
                    continue
                comparaisons = {n: visuel.comparer(references[n]["image"], rendus[n]["image"], copie)
                                for n in rendus}
                if not any(visuel.visible(c) for c in comparaisons.values()):
                    parts = ", ".join(f"{n} {c['part']:.4f}" for n, c in comparaisons.items())
                    prod.ecarter(GENERATEUR, f"{nom}:{cid}", "invisible", parts)
                    continue
                if juge_visuel.lancer_tests(copie):
                    prod.ecarter(GENERATEUR, f"{nom}:{cid}", "vu_par_les_tests", m.id)
                    continue
            finally:
                cible.write_text(origine, encoding="utf-8", newline="\n")
            tache = {"id": f"o1v_{nom}_{cid}", "competence": COMPETENCE, "consigne": consigne(),
                     "consigne_a_ecrire": None, "origine": ORIGINE,
                     "juge": {"etapes": ["import", "check_script"], "patch_max_lignes": PATCH_MAX_LIGNES},
                     "observation_visuelle": {"vues": vues, "seuil_pixel": visuel.SEUIL_PIXEL,
                                              "part_identique": visuel.PART_IDENTIQUE},
                     "bug": {"fichier": m.fichier, "ligne": m.ligne, "operateur": m.operateur,
                             "avant": m.avant.strip(), "apres": None if m.apres is None else m.apres.strip(),
                             "ecarts": {n: visuel.decrire(c, n) for n, c in comparaisons.items()},
                             "parts": {n: round(c["part"], 5) for n, c in comparaisons.items()},
                             "projet": source.name}}
            depart = dict(projet)
            depart[m.fichier] = mute
            dossier = ecrire_tache(sortie, tache, depart, {m.fichier: origine}, materiel)
            prod.taches.append(dossier)
            if afficher:
                afficher(f"   {tache['id']} : " + " ; ".join(tache["bug"]["ecarts"].values()))
    return prod


def main(argv: list[str] | None = None) -> int:
    import argparse
    sys.stdout.reconfigure(encoding="utf-8")
    p = argparse.ArgumentParser(prog="python -m usine.generateurs.observation_visuelle",
                                description="Tâches O1 visuelles tirées des étapes du cours « bâtiments procéduraux ».")
    p.add_argument("projets", type=Path, help="dossier des projets d'étape fabriqués")
    p.add_argument("--sortie", type=Path, required=True)
    p.add_argument("--filtre", default="", help="ne garder que les projets dont le nom contient ce texte")
    p.add_argument("--par-projet", type=int, default=4)
    p.add_argument("--essais", type=int, default=30, help="candidats essayés au plus par projet")
    p.add_argument("--graine", default="0")
    a = p.parse_args(argv)
    total = Production()
    for projet in sorted(d for d in a.projets.iterdir() if (d / "project.godot").is_file() and a.filtre in d.name):
        print(f"== {projet.name}", flush=True)
        try:
            prod = generer(projet, a.sortie, a.par_projet, a.essais, a.graine, lambda t: print(t, flush=True))
        except RuntimeError as e:
            print(f"   ÉCARTÉ : {e}", flush=True)
            continue
        raisons: dict[str, int] = {}
        for e in prod.ecartes:
            raisons[e["raison"]] = raisons.get(e["raison"], 0) + 1
        print(f"   {len(prod.taches)} tâche(s) ; écartés : {raisons}", flush=True)
        total.etendre(prod)
    print(f"TOTAL : {len(total.taches)} tâche(s), {len(total.ecartes)} candidat(s) écarté(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
