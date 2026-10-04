"""Aller-retour : une scène existante passe en spec (session 2) et devient une tâche S1 ou S2.

S1 : la consigne décrit la scène entière (gabarit déterministe tiré de la spec) ; l'agent rend
     une spec JSON que scene_write écrit en .tscn. depart = projet sans la scène ;
     reference = scene_write(spec) + la spec elle-même (usine_spec/<nom>.json) ;
     test caché = état stocké de la scène (gabarits.FONCTION_ETAT_SCENE), comparé à celui que
     Godot lit sur la référence, sur un plan tiré de la spec (nœuds, propriétés, sous-ressources).
S2 : depart = la scène sans une connexion (une tâche par connexion) ; reference = la scène
     complète ; test caché = la connexion doit être déclarée dans la scène.

`consigne_a_ecrire` est réservé : Qwen y écrira plus tard une consigne en langage naturel.
En attendant, la consigne gabarit fait foi.

Sources : les scènes du projet, plus les scènes générées de la session 2 (usine/scene/exemples.py),
écrites par scene_write dans une copie du projet.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from usine.generateurs import gabarits
from usine.generateurs.commun import (Production, ecrire_tache, executer_gd, ident, lire_projet, nom_source,
                                      scenes_jeu)
from usine.scene.exemples import specs_generees
from usine.scene.spec import parcourir, scene_read, scene_write, valider_spec
from usine.scene.texte import ecrire_valeur

ORIGINE = "generateur:aller_retour"


def _valeur_lisible(v: Any) -> str:
    if isinstance(v, dict) and len(v) == 1:
        (cle, val), = v.items()
        if cle == "ExtResource":
            return f"la ressource {val}"
        if cle == "SubResource":
            return f"la ressource interne « {val} »"
    return ecrire_valeur(v)


def _connexion_lisible(c: dict[str, Any]) -> str:
    texte = f"signal {c['signal']} du nœud {c['source']} → méthode {c['methode']} du nœud {c['cible']}"
    options = [f"{k}={json.dumps(c[k], ensure_ascii=False)}" for k in ("flags", "binds", "unbinds") if k in c]
    return texte + (f" ({', '.join(options)})" if options else "")


def decrire_spec(spec: dict[str, Any]) -> str:
    """Description déterministe et complète d'une scène, à partir de sa spec."""
    lignes = [f"Créer la scène {spec['chemin']}. Rendre une spec de scène JSON (format SPEC_SCENE.md), "
              "que scene_write écrira en .tscn. La scène doit contenir exactement ceci :", "Nœuds (chemin depuis la "
              "racine « . ») :"]
    for chemin, _, n in parcourir(spec["racine"]):
        quoi = f"instance de {n['instance']}" if n.get("instance") else n.get("type", "?")
        ligne = f"- {chemin} : {n['nom']}, {quoi}"
        if n.get("script"):
            ligne += f", script {n['script']}"
        if n.get("groupes"):
            ligne += f", groupes {', '.join(n['groupes'])}"
        props = n.get("proprietes", {})
        if props:
            ligne += " ; " + " ; ".join(f"{k} = {_valeur_lisible(v)}" for k, v in props.items())
        lignes.append(ligne)
    if spec.get("ressources_internes"):
        lignes.append("Ressources internes :")
        for r in spec["ressources_internes"]:
            props = " ; ".join(f"{k} = {_valeur_lisible(v)}" for k, v in r.get("proprietes", {}).items())
            lignes.append(f"- « {r['nom']} » : {r['type']}" + (f" ; {props}" if props else ""))
    if spec.get("connexions"):
        lignes.append("Connexions déclarées dans la scène :")
        lignes += [f"- {_connexion_lisible(c)}" for c in spec["connexions"]]
    return "\n".join(lignes)


def plan_spec(spec: dict[str, Any]) -> dict[str, Any]:
    """Ce que le test compare : pour chaque nœud, ses propriétés ; une sous-ressource se déplie."""
    internes = {r["nom"]: r for r in spec.get("ressources_internes", [])}

    def plan_valeur(v: Any, vus: tuple = ()) -> Any:
        if isinstance(v, dict) and "SubResource" in v and v["SubResource"] in internes and v["SubResource"] not in vus:
            r = internes[v["SubResource"]]
            return {k: plan_valeur(x, vus + (v["SubResource"],)) for k, x in r.get("proprietes", {}).items()}
        return None

    return {"noeuds": {chemin: {k: plan_valeur(v) for k, v in n.get("proprietes", {}).items()}
                       for chemin, _, n in parcourir(spec["racine"])}}


def _sources_scenes(projet: dict[str, str], verif) -> list[tuple[str, dict[str, Any], bool]]:
    """(chemin relatif, spec, la scène existe-t-elle dans le projet source)."""
    resultat = []
    for rel in sorted(scenes_jeu(projet)):
        resultat.append((rel, scene_read(projet[rel], "res://" + rel), True))
    for spec in specs_generees():
        resultat.append((spec["chemin"][len("res://"):], spec, False))
    return resultat


def _verificateur(source: Path):
    from usine.scene.preuve import verificateur
    return verificateur(source)


def generer_s1(source: Path, sortie: Path) -> Production:
    prod = Production()
    projet = lire_projet(source)
    verif = _verificateur(source)
    for rel, spec, existe in _sources_scenes(projet, verif):
        id_ = ident("s1", nom_source(source), Path(rel).stem)
        erreurs = valider_spec(spec, verif)
        if erreurs:
            prod.ecarter("aller_retour", id_, "spec_invalide", erreurs[0]["message"])
            continue
        tscn = scene_write(spec, verif)
        reference_projet = dict(projet)
        reference_projet[rel] = tscn
        plan = plan_spec(spec)
        mesures, sortie_godot = executer_gd(reference_projet, gabarits.script_mesure(gabarits.FONCTION_ETAT_SCENE),
                                            ["etat_scene", "res://" + rel, json.dumps(plan)])
        if not mesures or not mesures[0].get("charge"):
            prod.ecarter("aller_retour", id_, "reference_non_chargeable", sortie_godot[-400:])
            continue
        depart = {k: v for k, v in projet.items() if k != rel}
        tache = {"id": id_, "competence": "S1", "consigne": decrire_spec(spec), "consigne_a_ecrire": None,
                 "origine": ORIGINE,
                 "sortie": {"format": "spec_scene", "chemin": "res://" + rel, "ecrivain": "usine.scene.scene_write"},
                 "generateur": {"nom": "aller_retour", "source": nom_source(source), "scene": rel,
                                "scene_du_projet": existe}}
        reference = {rel: tscn,
                     f"usine_spec/{Path(rel).stem}.json": json.dumps(spec, ensure_ascii=False, indent=1) + "\n"}
        tests = {"test_s1_scene.gd": gabarits.test_s1("res://" + rel),
                 "etat_s1.json": json.dumps({"plan": plan, "etat": mesures[0]}, ensure_ascii=False, sort_keys=True,
                                            indent=1) + "\n"}
        prod.taches.append(ecrire_tache(sortie, tache, depart, reference, tests))
    return prod


def generer_s2(source: Path, sortie: Path) -> Production:
    prod = Production()
    projet = lire_projet(source)
    verif = _verificateur(source)
    for rel, spec, existe in _sources_scenes(projet, verif):
        connexions = spec.get("connexions", [])
        if not connexions:
            continue
        complet = scene_write(spec, verif) if not existe else projet[rel]
        for k, c in enumerate(connexions):
            id_ = ident("s2", nom_source(source), Path(rel).stem, c["signal"], c["methode"])
            sans = dict(spec, connexions=[x for j, x in enumerate(connexions) if j != k])
            depart = dict(projet)
            depart[rel] = scene_write(sans, verif)
            # Une scène du projet ne se réécrit pas : seule la ligne de connexion disparaît.
            if existe:
                lignes = [l for l in complet.split("\n")
                          if not (l.startswith("[connection ") and f'signal="{c["signal"]}"' in l
                                  and f'method="{c["methode"]}"' in l)]
                depart[rel] = "\n".join(lignes).replace("\n\n\n", "\n\n")
            if depart[rel] == complet:
                prod.ecarter("aller_retour", id_, "connexion_introuvable")
                continue
            options = [f"{o}={json.dumps(c[o], ensure_ascii=False)}" for o in ("flags", "binds", "unbinds") if o in c]
            consigne = (f"Règle : quand le nœud {c['source']} de res://{rel} émet {c['signal']}, "
                        f"le nœud {c['cible']} doit réagir avec sa méthode existante {c['methode']}"
                        + (f" (options de connexion : {', '.join(options)})" if options else "")
                        + ". Ajouter la connexion dans la scène, sans modifier les scripts.")
            tache = {"id": id_, "competence": "S2", "consigne": consigne, "consigne_a_ecrire": None,
                     "origine": ORIGINE,
                     "generateur": {"nom": "aller_retour", "source": nom_source(source), "scene": rel,
                                    "connexion": c}}
            attendue = json.dumps([[c["source"], c["signal"], c["cible"], c["methode"]]], ensure_ascii=False)
            tests = {"test_s2_connexions.gd": gabarits.GABARIT_TEST_S2.format(scene="res://" + rel,
                                                                               attendues=attendue)}
            prod.taches.append(ecrire_tache(sortie, tache, depart, {rel: complet}, tests))
    return prod
