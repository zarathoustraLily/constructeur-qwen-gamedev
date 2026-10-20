"""Observation (O1) : un bug de gameplay injecté dans un jeu observable devient une tâche « corriger en observant ».

Sources : celles qui ont une description de partie (usine/observation/jeux/<jeu>.json, champ
`observation` de usine/generateurs/sources.py).

1. Le projet source (la référence) est lu (texte + socle) et importé une fois dans une copie de
   travail ; son monde de vérité est écrit ; ses séquences ne doivent casser aucune règle.
2. Candidats : les bugs modèles de la description (`bugs_modeles` : remplacement exact, avec le
   symptôme qu'on en attend), puis des mutants des scripts de gameplay (`fichiers_bugs`, opérateurs
   de l'usine, un par ligne et au plus `mutants_max`, tirage à graine fixe).
3. Chaque candidat est joué dans la copie (fichier muté, puis restauré) : il est gardé s'il casse au
   moins une règle de partie. La vérité est connue par construction : le bug et la ligne d'origine.
   Écartés : « jeu_casse » (la partie ne va pas au bout : c'est une tâche K3, pas O1) et
   « invisible_en_partie » (aucune séquence ne le montre).
4. Tâche : depart = projet muté ; reference = fichier d'origine ; tests_caches/observation/ = la
   description et le monde de vérité ; juge = import, check_script, load_scene, puis l'étape
   observation ; patch plafonné (`patch_max_lignes`). Le portillon confirme ensuite.
"""

from __future__ import annotations

import json
import tempfile
from pathlib import Path
from typing import Any

from usine.generateurs.commun import Production, echantillon, ecrire_projet, ecrire_tache, ident, lire_projet
from usine.generateurs.mutation import tirer_un_par_ligne
from usine.generateurs.operateurs import mutants_fichier
from usine.juge import godot as juges
from usine.juge.projet import preparer_copie
from usine.observation import partie

ORIGINE = "generateur:observation"
COMPETENCE = "O1"
GENERATEUR = "observation"


def consigne(desc: dict[str, Any]) -> str:
    sequences = ", ".join(desc["sequences"])
    return (f"Le jeu se comporte mal quand on y joue, sans qu'on sache encore pourquoi. Observe des parties avec "
            f"l'outil play_sequence (séquences : {sequences}) : il dit, image par image, quelles règles de partie "
            "cassent (gravité, hauteur, sous le sol, traversée d'obstacle, enfouissement dans le sol, caméra) et "
            "montre le parcours. Trouve la cause dans le projet et corrige-la par un changement minimal, sans "
            "toucher au reste du jeu. Le juge rejoue ces séquences : toutes les règles doivent tenir.")


def candidats(projet: dict[str, str], desc: dict[str, Any], graine: int) -> list[dict[str, Any]]:
    """Bugs modèles, puis mutants des scripts de gameplay : [{id, fichier, ligne, operateur, avant, apres}]."""
    liste = []
    for b in desc.get("bugs_modeles", []):
        texte = projet.get(b["fichier"], "")
        if texte.count(b["avant"]) != 1:
            raise ValueError(f"bug modèle « {b['nom']} » : le texte d'origine n'apparaît pas une seule fois "
                             f"dans {b['fichier']} (description de jeu à corriger)")
        ligne = texte[: texte.index(b["avant"])].count("\n") + 1
        liste.append({"id": ident("modele", b["nom"]), "nom": b["nom"], "fichier": b["fichier"], "ligne": ligne,
                      "operateur": "modele", "mute": texte.replace(b["avant"], b["apres"]),
                      "avant": b["avant"].strip(), "apres": b["apres"].strip(), "symptome": b.get("symptome")})
    mutants = []
    for rel in desc.get("fichiers_bugs", []):
        mutants += mutants_fichier(rel, projet[rel])
    for m in echantillon(tirer_un_par_ligne(mutants, graine), desc.get("mutants_max"), f"o1:{graine}"):
        liste.append({"id": ident(Path(m.fichier).stem, m.ligne, m.operateur, m.occurrence), "nom": m.id,
                      "fichier": m.fichier, "ligne": m.ligne, "operateur": m.operateur,
                      "mute": m.appliquer(projet[m.fichier]), "avant": m.avant.strip(),
                      "apres": None if m.apres is None else m.apres.strip(), "symptome": None})
    return liste


def generer(source: Path, sortie: Path, nom_source: str, jeu: str, graine: int = 0,
            plafond: int | None = None, afficher=None) -> Production:
    prod = Production()
    config = partie.config_jeu(jeu)
    desc = partie.lire_config(config)
    regles, sequences = desc["regles"], list(desc["sequences"])
    projet = lire_projet(Path(source), nom_source)
    liste = candidats(projet, desc, graine)
    with tempfile.TemporaryDirectory(prefix="usine_o1_") as tmp:
        copie = preparer_copie(ecrire_projet(projet, Path(tmp) / "src"), Path(tmp) / "copie")
        imp = juges.importer(copie)
        if not imp["ok"]:
            raise RuntimeError(f"{nom_source} : import en échec : " + "; ".join(e["message"] for e in imp["erreurs"]))
        monde = Path(tmp) / "monde_verite.tscn"
        partie.ecrire_monde(copie, config, monde)
        reference = partie.lancer(copie, config, sequences, monde)
        fautes = {s: partie.cassees(partie.evaluer(t, regles)) for s, t in reference.items()}
        if any(fautes.values()):
            raise RuntimeError(f"{nom_source} : la référence casse des règles ({fautes}) : seuils de {config.name} "
                               "à régler sur le jeu intact")
        materiel = {"observation/config.json": config.read_text(encoding="utf-8"),
                    "observation/monde_verite.tscn": monde.read_text(encoding="utf-8")}
        for c in liste:
            if plafond is not None and len(prod.taches) >= plafond:
                break
            cible = copie / c["fichier"]
            origine = projet[c["fichier"]]
            cible.write_text(c["mute"], encoding="utf-8", newline="\n")
            try:
                traces = partie.lancer(copie, config, sequences, monde)
            except partie.ErreurObservation as e:
                prod.ecarter(GENERATEUR, c["id"], "jeu_casse", str(e).splitlines()[0][:200])
                continue
            finally:
                cible.write_text(origine, encoding="utf-8", newline="\n")
            cassees = {s: partie.cassees(partie.evaluer(t, regles)) for s, t in traces.items()}
            if not any(cassees.values()):
                prod.ecarter(GENERATEUR, c["id"], "invisible_en_partie", c["nom"])
                continue
            tache = {"id": f"o1_{nom_source}_{c['id']}", "competence": COMPETENCE, "consigne": consigne(desc),
                     "consigne_a_ecrire": None, "origine": ORIGINE,
                     "juge": {"etapes": ["import", "check_script", "load_scene"],
                              "patch_max_lignes": int(desc.get("patch_max_lignes", 4))},
                     "observation": {"jeu": jeu, "sequences": sequences},
                     "bug": {"fichier": c["fichier"], "ligne": c["ligne"], "operateur": c["operateur"],
                             "avant": c["avant"], "apres": c["apres"], "symptome": c["symptome"],
                             "regles_cassees": {s: r for s, r in cassees.items() if r}}}
            depart = dict(projet)
            depart[c["fichier"]] = c["mute"]
            prod.taches.append(ecrire_tache(sortie, tache, depart, {c["fichier"]: origine}, materiel))
            if afficher:
                afficher(f"   {tache['id']} : {json.dumps(tache['bug']['regles_cassees'], ensure_ascii=False)}")
    return prod
