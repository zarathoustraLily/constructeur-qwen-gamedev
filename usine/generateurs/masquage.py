"""Masquage : dans un projet testé, vider le corps d'une méthode (K2) ou tout un script (K1).

Parseur : celui de usine/projet/gdscript.py (déclarations de premier niveau, blocs par
indentation), déjà utilisé par describe_project et apply_edits. gdtoolkit n'est pas employé :
sa grammaire suit Godot 4.x avec retard, il ajouterait une dépendance (lark) à installer
hors-ligne, et le masquage n'a besoin que des bornes de chaque fonction. Le juge Godot reste
l'autorité : un masquage qui ne compile pas est rejeté par le portillon (départ non rouge
pour la bonne raison, ou référence non verte).

K2 : depart = méthode vidée (le commentaire ## au-dessus est gardé : c'est le contrat) ;
     reference = script d'origine ; tests cachés = tests du projet.
K1 : depart = projet sans le script ; consigne = interface à écrire ;
     reference = squelette (mêmes déclarations, corps vides) ;
     test caché = interface lue par réflexion (gabarits.FONCTION_INTERFACE), vérité mesurée par Godot
     sur le squelette de référence.
"""

from __future__ import annotations

import json
from pathlib import Path

from usine.generateurs import gabarits
from usine.generateurs.commun import (Production, ecrire_tache, executer_gd, ident, lire_projet, nom_source,
                                      scripts_jeu, tests_regression)
from usine.projet.gdscript import Fonction, Script, lire_script

ORIGINE = "generateur:masquage"

_DEFAUTS = {None: "pass", "void": "pass", "bool": "return false", "int": "return 0", "float": "return 0.0",
            "String": 'return ""', "StringName": 'return &""', "Vector2": "return Vector2.ZERO",
            "Vector3": "return Vector3.ZERO", "Dictionary": "return {}", "Array": "return []"}


def corps_vide(fonction: Fonction, script: Script) -> str:
    """Instruction minimale qui compile pour le type de retour."""
    retour = fonction.retour
    if retour in _DEFAUTS:
        return _DEFAUTS[retour]
    if retour.startswith("Array["):
        return "return []"
    if retour in script.enums:
        return f"return {retour}.values()[0]"
    return "return null"


def _unite(lignes: list[str]) -> str:
    for l in lignes:
        if l.startswith("\t"):
            return "\t"
        if l.startswith(" "):
            return l[:len(l) - len(l.lstrip(" "))]
    return "\t"


def vider_fonction(texte: str, nom: str) -> str:
    s = lire_script(texte)
    f = s.fonction(nom)
    if f is None or f.une_ligne:
        raise ValueError(f"fonction {nom} absente ou sur une ligne")
    lignes = texte.split("\n")
    unite = _unite(lignes[f.ligne_corps:f.ligne_fin])
    return "\n".join(lignes[:f.ligne_corps] + [unite + corps_vide(f, s)] + lignes[f.ligne_fin:])


def squelette(texte: str) -> str:
    """Le script avec toutes ses fonctions vidées (déclarations et commentaires gardés)."""
    s = lire_script(texte)
    for f in sorted(s.fonctions, key=lambda f: -f.ligne_debut):
        if not f.une_ligne:
            texte = vider_fonction(texte, f.nom)
    return texte


def decrire_interface(texte: str, res: str) -> str:
    """Interface lisible, déterministe : ce que le script doit déclarer."""
    s = lire_script(texte, res)
    lignes = [f"Écrire le script {res} (GDScript, Godot 4.7), avec exactement cette interface ; "
              "les corps des méthodes peuvent rester vides (pass ou valeur par défaut)."]
    if s.class_name:
        lignes.append(f"- class_name {s.class_name}")
    lignes.append(f"- extends {s.extends or 'RefCounted'}")
    for sg in s.signaux:
        lignes.append(f"- {sg.texte()}")
    for k in range(len(s.lignes)):
        brut = s.lignes[k].rstrip("\r\n")
        if brut.startswith(("enum ", "const ")):
            lignes.append(f"- {brut.strip()}")
    for v in s.variables:
        lignes.append(f"- {v.texte()}")
    for f in s.fonctions:
        lignes.append(f"- {f.signature()}")
    return "\n".join(lignes)


def generer_k2(source: Path, sortie: Path) -> Production:
    prod = Production()
    projet = lire_projet(source)
    regression = tests_regression(projet)
    for rel in scripts_jeu(projet):
        s = lire_script(projet[rel], "res://" + rel)
        classe = s.class_name or Path(rel).stem
        for f in s.fonctions:
            id_ = ident("k2", nom_source(source), Path(rel).stem, f.nom)
            if f.une_ligne:
                prod.ecarter("masquage", id_, "fonction_sur_une_ligne")
                continue
            depart = dict(projet)
            depart[rel] = vider_fonction(projet[rel], f.nom)
            if depart[rel] == projet[rel]:
                prod.ecarter("masquage", id_, "masquage_sans_effet")
                continue
            consigne = (
                f"Implémenter le corps de {classe}.{f.nom} dans res://{rel}, en respectant le contrat écrit en "
                "commentaire au-dessus de la méthode s'il existe, et le comportement attendu par les tests de "
                "res://tests/. Tous les tests doivent passer. Ne pas changer la signature : "
                f"{f.signature()}."
            )
            tache = {"id": id_, "competence": "K2", "consigne": consigne, "consigne_a_ecrire": None,
                     "origine": ORIGINE,
                     "generateur": {"nom": "masquage", "source": nom_source(source), "fichier": rel,
                                    "methode": f.nom}}
            prod.taches.append(ecrire_tache(sortie, tache, depart, {rel: projet[rel]}, regression))
    return prod


def generer_k1(source: Path, sortie: Path) -> Production:
    prod = Production()
    projet = lire_projet(source)
    for rel in scripts_jeu(projet):
        id_ = ident("k1", nom_source(source), Path(rel).stem)
        res = "res://" + rel
        sq = squelette(projet[rel])
        if not lire_script(sq).fonctions:
            prod.ecarter("masquage", id_, "script_sans_methode")
            continue
        reference_projet = dict(projet)
        reference_projet[rel] = sq
        mesures, sortie_godot = executer_gd(reference_projet, gabarits.script_mesure(gabarits.FONCTION_INTERFACE),
                                            ["interface_script", res])
        if not mesures or not mesures[0].get("charge"):
            prod.ecarter("masquage", id_, "squelette_non_chargeable", sortie_godot[-400:])
            continue
        depart = {k: v for k, v in projet.items() if k != rel}
        tache = {"id": id_, "competence": "K1", "consigne": decrire_interface(projet[rel], res),
                 "consigne_a_ecrire": None, "origine": ORIGINE,
                 "generateur": {"nom": "masquage", "source": nom_source(source), "fichier": rel}}
        tests = {"test_k1_interface.gd": gabarits.test_k1(res),
                 "interface_k1.json": json.dumps(mesures[0], ensure_ascii=False, sort_keys=True, indent=1) + "\n"}
        prod.taches.append(ecrire_tache(sortie, tache, depart, {rel: sq}, tests))
    return prod
