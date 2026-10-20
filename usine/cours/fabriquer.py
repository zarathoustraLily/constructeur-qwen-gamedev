"""Fabrique un projet Godot par étape et par ville, à partir des fichiers maîtres balisés d'un cours.

Un maître contient le code de plusieurs étapes. Une ligne « #@ <plage> » (GDScript) ou « //@ <plage> »
(shader) dit à quelles étapes appartiennent les lignes qui suivent, jusqu'à la balise suivante :
    #@ all        toutes les étapes où le fichier existe
    #@ 4+         à partir de l'étape 4
    #@ 4-6        étapes 4 à 6
    #@ 4          étape 4 seulement
    #@ 4+ quiet   pareil, sans bandeau « NOUVEAU »
Les lignes qui apparaissent à l'étape en cours sont encadrées d'un bandeau « NOUVEAU ».

Jetons remplacés dans tous les fichiers texte :
    {STEP}    numéro de l'étape sur trois chiffres
    {NAME}    building_proceduraux_<ville>_etape_<NNN>
    {MESH}    res://6_assets/Mesh/Procedural/DECORS/Building/{NAME}
    {SHADER}  res://6_assets/Shader/Procedural/DECORS/Building/{NAME}
    {DATA}    res://5_data/DECORS/Building/{NAME}
    {STATUS}  état du fichier à cette étape (nouveau, modifié, inchangé)
    {TITLE}   titre de l'étape
    {TRACK}   piste de l'étape (Building, Shader…)
    {STYLE}   nom de la ville (Paris, Tokyo, New York)

Le manifeste du cours (`cours/<nom>/manifeste.py`) dit quels maîtres existent à quelle étape, les scènes et la
visite. Règle 5 : une erreur se corrige dans les maîtres, jamais dans les projets fabriqués.
"""

from __future__ import annotations

import re
import runpy
import shutil
from pathlib import Path
from typing import Any

MESH_REL = "6_assets/Mesh/Procedural/DECORS/Building"
SHADER_REL = "6_assets/Shader/Procedural/DECORS/Building"
DATA_REL = "5_data/DECORS/Building"
# Les réglages de la visite : la scène de visite les donne au script de visite (dépendance déclarée).
REGLAGES_VISITE = "5_data/visit/visit_settings.tres"
BALISE = re.compile(r"^\s*(#@|//@)\s*(.+?)\s*$")
ETATS = {"nouveau": "**nouveau**", "modifié": "**modifié**", "inchangé": "inchangé", "scène": "scène",
         "réglages": "réglages"}


def nom_projet(ville: str, etape: int) -> str:
    return f"building_proceduraux_{ville}_etape_{etape:03d}"


def lire_manifeste(cours: Path) -> dict[str, Any]:
    return runpy.run_path(str(Path(cours) / "manifeste.py"))


def plage(spec: str, premiere: int, derniere: int) -> tuple[int, int, bool]:
    """(début, fin, silencieux) d'une balise."""
    silencieux = False
    if spec.endswith(" quiet"):
        silencieux = True
        spec = spec[: -len(" quiet")].strip()
    if spec == "all":
        return premiere, derniere, True
    if spec.endswith("+"):
        return max(int(spec[:-1]), premiere), derniere, silencieux
    if "-" in spec:
        bas, haut = spec.split("-")
        return int(bas), int(haut), silencieux
    return int(spec), int(spec), silencieux


def points_de_changement(lignes: list[str], premiere: int, derniere: int) -> list[int]:
    """Étapes où le contenu d'un maître change."""
    points = {premiere}
    for ligne in lignes:
        m = BALISE.match(ligne)
        if not m:
            continue
        bas, haut, _ = plage(m.group(2), premiere, derniere)
        points.add(bas)
        if haut < derniere:
            points.add(haut + 1)
    return sorted(points)


def jetons(manifeste: dict[str, Any], ville: str, etape: int, statut: str = "") -> dict[str, str]:
    nom = nom_projet(ville, etape)
    info = manifeste["VILLES"][ville]
    return {
        "{STEP}": f"{etape:03d}",
        "{NAME}": nom,
        "{MESH}": f"res://{MESH_REL}/{nom}",
        "{SHADER}": f"res://{SHADER_REL}/{nom}",
        "{DATA}": f"res://{DATA_REL}/{nom}",
        "{STATUS}": statut,
        "{TITLE}": info["etapes"][etape - 1]["titre"],
        "{TRACK}": info["etapes"][etape - 1]["piste"],
        "{STYLE}": info["nom"],
    }


def remplacer(texte: str, table: dict[str, str]) -> str:
    for cle, valeur in table.items():
        texte = texte.replace(cle, valeur)
    return texte


def rendre(manifeste: dict[str, Any], maitre: Path, ville: str, etape: int, premiere: int,
           derniere: int) -> tuple[str, str, int]:
    """Le texte d'un maître à une étape : (texte, état, étape de la dernière modification)."""
    commentaire = "#" if maitre.suffix == ".gd" else "//"
    lignes = maitre.read_text(encoding="utf-8").split("\n")
    points = points_de_changement(lignes, premiere, derniere)
    dernier_changement = max(p for p in points if p <= etape)

    retenues: list[tuple[str, bool]] = []  # (texte, nouveau)
    bas, haut, silencieux = premiere, derniere, True
    for ligne in lignes:
        m = BALISE.match(ligne)
        if m:
            bas, haut, silencieux = plage(m.group(2), premiere, derniere)
            continue
        if bas <= etape <= haut:
            retenues.append((ligne, (bas == etape) and not silencieux and etape != premiere))

    if etape == premiere:
        etat, statut = "nouveau", f"Étape {etape:03d} · nouveau fichier."
    elif dernier_changement == etape:
        etat, statut = "modifié", f"Étape {etape:03d} · fichier modifié à cette étape : chercher « NOUVEAU »."
    else:
        etat, statut = "inchangé", f"Étape {etape:03d} · fichier inchangé à cette étape."

    # Bandeaux « NOUVEAU » autour des suites de lignes nouvelles.
    sortie: list[str] = []
    i = 0
    while i < len(retenues):
        texte, nouveau = retenues[i]
        if not (nouveau and texte.strip()):
            sortie.append(texte)
            i += 1
            continue
        fin = i
        while fin + 1 < len(retenues) and (retenues[fin + 1][1] or not retenues[fin + 1][0].strip()):
            fin += 1
        while not retenues[fin][0].strip():
            fin -= 1
        # Le bandeau du début prend le retrait de la première ligne du bloc, celui de la fin le retrait de la
        # dernière : un bloc qui finit plus à gauche qu'il ne commence reste lisible.
        retrait = re.match(r"^\s*", texte).group(0)
        retrait_fin = re.match(r"^\s*", retenues[fin][0]).group(0)
        sortie.append(f"{retrait}{commentaire} >>> NOUVEAU À L'ÉTAPE {etape:03d}")
        sortie.extend(t for t, _ in retenues[i:fin + 1])
        sortie.append(f"{retrait_fin}{commentaire} <<< FIN DU NOUVEAU")
        i = fin + 1

    texte = "\n".join(sortie)
    texte = remplacer(texte, jetons(manifeste, ville, etape, statut))
    texte = re.sub(r"\n{4,}", "\n\n\n", texte)
    return texte.rstrip("\n") + "\n", etat, dernier_changement


def ecrire(chemin: Path, texte: str) -> None:
    chemin.parent.mkdir(parents=True, exist_ok=True)
    chemin.write_text(texte, encoding="utf-8", newline="\n")


def scene_de_script(res: str, noeud: str, variables: dict[str, str] | None = None) -> str:
    """Scène minimale : un Node3D qui porte un script, et ses variables si elles diffèrent du défaut."""
    lignes = [
        "[gd_scene load_steps=2 format=3]",
        "",
        f"[ext_resource type=\"Script\" path=\"{res}\" id=\"1\"]",
        "",
        f"[node name=\"{noeud}\" type=\"Node3D\"]",
        "script = ExtResource(\"1\")",
    ]
    for cle, valeur in (variables or {}).items():
        lignes.append(f"{cle} = {valeur}")
    return "\n".join(lignes) + "\n"


def scene_de_visite(manifeste: dict[str, Any], ville: str, etape: int, visite: dict[str, Any]) -> str:
    """Scène de visite : la visite, avec la scène à montrer en enfant. « instances » permet d'en montrer
    plusieurs côte à côte : (suffixe de la scène, nom du nœud, position[, variables])."""
    nom = nom_projet(ville, etape)
    info = manifeste["VILLES"][ville]
    titre = f"{info['nom']} · étape {etape:03d} · {info['etapes'][etape - 1]['titre']}"
    if visite.get("sous_titre"):
        titre += " · " + visite["sous_titre"]
    instances = visite.get("instances") or [(visite.get("scene", ""), visite.get("noeud", "Building"), None)]
    # Une instance peut porter un quatrième élément : ses variables, qui remplacent celles de sa scène.
    instances = [tuple(entree) + ({},) * (4 - len(entree)) for entree in instances]
    montrees: list[str] = []
    for suffixe, _noeud, _position, _variables in instances:
        if suffixe not in montrees:
            montrees.append(suffixe)
    lignes = [
        f"[gd_scene load_steps={3 + len(montrees)} format=3]",
        "",
        "[ext_resource type=\"Script\" path=\"res://2_sequence/step_viewer/step_viewer.gd\" id=\"1\"]",
        f"[ext_resource type=\"Resource\" path=\"res://{REGLAGES_VISITE}\" id=\"2\"]",
    ]
    for rang, suffixe in enumerate(montrees):
        lignes.append(f"[ext_resource type=\"PackedScene\" path=\"res://{MESH_REL}/{nom}{suffixe}.tscn\" "
                      f"id=\"{rang + 3}\"]")
    lignes += [
        "",
        "[node name=\"StepViewer\" type=\"Node3D\"]",
        "script = ExtResource(\"1\")",
        "settings = ExtResource(\"2\")",
        f"title = \"{titre}\"",
    ]
    for cle, valeur in visite.get("reglages", {}).items():
        lignes.append(f"{cle} = {valeur}")
    for suffixe, noeud, position, variables in instances:
        lignes += ["", f"[node name=\"{noeud}\" parent=\".\" instance=ExtResource(\"{montrees.index(suffixe) + 3}\")]"]
        if position:
            lignes.append("transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %g, %g, %g)" % tuple(position))
        for cle, valeur in variables.items():
            lignes.append(f"{cle} = {valeur}")
    return "\n".join(lignes) + "\n"


def fabriquer(cours: Path, ville: str, etape: int, sortie: Path,
              manifeste: dict[str, Any] | None = None) -> dict[str, Any]:
    """Écrit le projet de l'étape dans `sortie/<nom du projet>` (remplacé s'il existe) ; rend son rapport."""
    cours = Path(cours)
    manifeste = manifeste or lire_manifeste(cours)
    info = manifeste["VILLES"][ville]
    nom = nom_projet(ville, etape)
    racine = Path(sortie) / nom
    if racine.is_dir():
        shutil.rmtree(racine)
    rapport: dict[str, Any] = {"ville": ville, "etape": etape, "nom": nom, "fichiers": []}

    # 1. Fichiers maîtres propres à la ville.
    for maitre, destination, premiere, derniere in info["fichiers"]:
        if not (premiere <= etape <= derniere):
            continue
        texte, etat, changement = rendre(manifeste, cours / "maitres" / ville / maitre, ville, etape, premiere,
                                         derniere)
        relatif = remplacer(destination, jetons(manifeste, ville, etape))
        ecrire(racine / relatif, texte)
        rapport["fichiers"].append({"chemin": relatif, "etat": etat, "changement": changement, "maitre": maitre})

    # 2. Fichiers communs à toutes les villes.
    for source, destination, premiere in manifeste["COMMUN"]:
        if etape < premiere or source in info.get("sans_commun", []):
            continue
        chemin_source = cours / "commun" / source
        texte = chemin_source.read_text(encoding="utf-8")
        destination = remplacer(destination, jetons(manifeste, ville, etape))
        if any(BALISE.match(ligne) for ligne in texte.split("\n")):
            texte, etat, changement = rendre(manifeste, chemin_source, ville, etape, premiere, manifeste["DERNIERE"])
        else:
            texte = remplacer(texte, jetons(manifeste, ville, etape))
            etat = "nouveau" if etape == premiere else "inchangé"
            changement = premiere
        ecrire(racine / destination, texte)
        rapport["fichiers"].append({"chemin": destination, "etat": etat, "changement": changement,
                                    "maitre": "commun/" + source})

    # 3. Scènes : l'immeuble, la rue quand elle existe, et la visite. Une scène porte d'ordinaire le script de
    # même nom ; un quatrième élément dit d'en prendre un autre (trois scènes de tours, un seul script).
    for scene in info["scenes"](etape):
        suffixe, noeud, variables = scene[:3]
        suffixe_script = scene[3] if len(scene) > 3 else suffixe
        ecrire(racine / MESH_REL / f"{nom}{suffixe}.tscn",
               scene_de_script(f"res://{MESH_REL}/{nom}{suffixe_script}.gd", noeud, variables))
        rapport["fichiers"].append({"chemin": f"{MESH_REL}/{nom}{suffixe}.tscn", "etat": "scène",
                                    "changement": etape, "maitre": ""})
    visite = info["visite"](etape)
    ecrire(racine / "2_sequence/step_viewer/step_viewer.tscn", scene_de_visite(manifeste, ville, etape, visite))
    # Scènes de visite en plus (l'immeuble seul, quand la scène principale est la rue).
    for nom_autre, autre in visite.get("autres", {}).items():
        ecrire(racine / f"2_sequence/step_viewer/{nom_autre}.tscn", scene_de_visite(manifeste, ville, etape, autre))

    # 4. Réglages du projet ; une ville peut ajouter des lignes à la dernière section du modèle, [rendering].
    projet = remplacer((cours / "commun" / "project.godot.tpl").read_text(encoding="utf-8"),
                       jetons(manifeste, ville, etape))
    en_plus = info["reglages_en_plus"](etape) if "reglages_en_plus" in info else []
    if en_plus:
        projet = projet.rstrip("\n") + "\n" + "\n".join(en_plus) + "\n"
    ecrire(racine / "project.godot", projet)

    # 5. La note de l'étape (README.md, à la racine du projet), avec le tableau de ses fichiers.
    rapport["fichiers"].append({"chemin": "project.godot", "etat": "réglages", "changement": etape, "maitre": "projet"})
    rapport["fichiers"].append({"chemin": "2_sequence/step_viewer/step_viewer.tscn", "etat": "scène",
                                "changement": etape, "maitre": "visite"})
    for nom_autre in visite.get("autres", {}):
        rapport["fichiers"].append({"chemin": f"2_sequence/step_viewer/{nom_autre}.tscn", "etat": "scène",
                                    "changement": etape, "maitre": "visite_autre"})
    note = cours / "notes" / ville / f"etape_{etape:03d}.md"
    rapport["note"] = note.is_file()
    if note.is_file():
        roles = dict(manifeste["ROLES"])
        roles.update(info.get("roles", {}))
        tableau = ["| Dossier | Fichier | Rôle | À cette étape |", "|---|---|---|---|"]
        for entree in sorted(rapport["fichiers"], key=lambda e: e["chemin"]):
            dossier, base = entree["chemin"].rpartition("/")[0], entree["chemin"].rpartition("/")[2]
            if base.endswith(".md"):
                continue
            # Une scène a pour rôle « scene » suivi de son suffixe (« scene_rue », « scene_verre »).
            cle = entree["maitre"].split("/")[-1] if entree["maitre"] else "scene" + base[len(nom):-len(".tscn")]
            role = roles.get(cle, "")
            court = base.replace(nom, "…") if base.startswith(nom + "_") or base.startswith("test_" + nom) else base
            tableau.append(f"| `{dossier + '/' if dossier else './'}` | `{court}` | {role} | {ETATS[entree['etat']]} |")
        table = jetons(manifeste, ville, etape)
        table["{FILES_TABLE}"] = "\n".join(tableau)
        # Note sur le projet jumeau (même étape, autre ville), si elle est écrite.
        jumeau = cours / "notes" / ville / f"jumeau_{etape:03d}.md"
        table["{TWIN}"] = ("\n" + jumeau.read_text(encoding="utf-8").strip("\n") + "\n") if jumeau.is_file() else ""
        # README.md : le seul nom de note que le plan admet à la racine (ORG-01).
        ecrire(racine / "README.md", remplacer(note.read_text(encoding="utf-8"), table))
    return rapport


def etapes_demandees(manifeste: dict[str, Any], villes: list[str] | None = None,
                     etapes: list[int] | None = None) -> list[tuple[str, int]]:
    """(ville, étape) à fabriquer : toutes les étapes prêtes des villes demandées, ou celles nommées."""
    connues = list(manifeste["VILLES"])
    villes = villes or connues
    inconnues = [v for v in villes if v not in connues]
    if inconnues:
        raise ValueError(f"villes inconnues : {inconnues} (connues : {connues})")
    return [(v, n) for v in villes for n in (etapes or manifeste["VILLES"][v]["pretes"])]


def fabriquer_tout(cours: Path, sortie: Path, villes: list[str] | None = None,
                   etapes: list[int] | None = None) -> list[dict[str, Any]]:
    manifeste = lire_manifeste(cours)
    return [fabriquer(cours, v, n, sortie, manifeste) for v, n in etapes_demandees(manifeste, villes, etapes)]
