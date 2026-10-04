"""describe_project : vue compacte, stable et déterministe d'un projet Godot pour un LLM.

Même projet → mêmes octets (fichiers triés, aucun horodatage). La vue donne l'arbre de
chaque scène avec un id lisible par nœud, les scripts avec leurs signatures, les signaux,
les connexions et les autoloads. Les id servent de cibles au langage d'édition
(EDITS_GODOT.md) :

    id de nœud   = <alias de scène>:<chemin du nœud>   (racine : <alias de scène>)
    alias        = nom du fichier sans .tscn ; chemin res:// sans extension en cas de doublon
    ressource interne d'un nœud = <id de nœud>#<propriété>   (ex. coin:CollisionShape2D#shape)
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

from usine.projet.gdscript import arguments_json
from usine.projet.index import Projet
from usine.scene.spec import parcourir, scene_read
from usine.scene.texte import ecrire_valeur, type_cle


def alias_scenes(scenes: list[str]) -> dict[str, str]:
    """res:// → alias lisible et unique."""
    def court(res: str) -> str:
        return res.rsplit("/", 1)[-1].rsplit(".", 1)[0]

    comptes: dict[str, int] = {}
    for r in scenes:
        comptes[court(r)] = comptes.get(court(r), 0) + 1
    return {r: court(r) if comptes[court(r)] == 1 else r[len("res://"):].rsplit(".", 1)[0] for r in scenes}


def id_noeud(alias: str, chemin: str) -> str:
    return alias if chemin == "." else f"{alias}:{chemin}"


def _resume_valeur(v: Any, internes: dict[str, dict]) -> str:
    """Valeur courte pour la vue : les ressources internes montrent leur type et leurs propriétés."""
    if isinstance(v, dict) and len(v) == 1:
        k = type_cle(v)
        if k == "SubResource":
            r = internes.get(v[k], {})
            props = ", ".join(f"{c}={_resume_valeur(x, internes)}" for c, x in r.get("proprietes", {}).items())
            return f"{r.get('type', '?')}({props})"
        if k == "ExtResource":
            return v[k]
    texte = ecrire_valeur(v).replace("\n", " ")
    return texte if len(texte) <= 60 else texte[:57] + "..."


def table_ids(projet: Projet) -> dict[str, dict[str, str]]:
    """id → {"scene": res://…, "chemin": chemin du nœud dans la scène}."""
    scenes = projet.scenes()
    alias = alias_scenes(scenes)
    table: dict[str, dict[str, str]] = {}
    for res in scenes:
        try:
            spec = scene_read(projet.lire(res) or "", res)
        except Exception:
            continue
        for chemin, _, n in parcourir(spec["racine"]):
            if not n.get("implicite"):
                table[id_noeud(alias[res], chemin)] = {"scene": res, "chemin": chemin}
    return table


def describe_project(racine: Path | Projet) -> dict[str, Any]:
    """Vue du projet : {"texte": vue pour le LLM, "ids": table id → chemin, "scenes", "scripts", "autoloads"}."""
    projet = racine if isinstance(racine, Projet) else Projet(Path(racine))
    scenes = projet.scenes()
    alias = alias_scenes(scenes)
    lignes: list[str] = []
    ids: dict[str, dict[str, str]] = {}

    version = projet.reglages.get("application", {}).get("config/features")
    version_txt = ""
    if isinstance(version, dict) and version.get("PackedStringArray"):
        version_txt = f" (Godot {version['PackedStringArray'][0]})"
    lignes.append(f"PROJET {projet.nom()}{version_txt}")
    if projet.scene_principale():
        lignes.append(f"scène principale : {projet.scene_principale()}")
    autoloads = projet.autoloads()
    if autoloads:
        lignes.append("autoloads : " + ", ".join(f"{k} = {v}" for k, v in autoloads.items()))
    lignes.append("ids : <scène>:<chemin du nœud> ; ressource interne : <id>#<propriété>")

    scenes_json = []
    for res in scenes:
        texte = projet.lire(res) or ""
        try:
            spec = scene_read(texte, res)
        except Exception as exc:  # scène illisible : on la signale sans casser la vue
            lignes.append("")
            lignes.append(f"SCÈNE {alias[res]} = {res}  (illisible : {exc})")
            continue
        internes = {r["nom"]: r for r in spec.get("ressources_internes", [])}
        lignes.append("")
        lignes.append(f"SCÈNE {alias[res]} = {res}")
        noeuds_json = []
        for chemin, _, n in parcourir(spec["racine"]):
            if n.get("implicite"):
                continue
            ident = id_noeud(alias[res], chemin)
            ids[ident] = {"scene": res, "chemin": chemin}
            profondeur = 0 if chemin == "." else chemin.count("/") + 1
            morceaux = [ident]
            if n.get("instance"):
                t_inst, _ = projet.racine_scene(n["instance"])
                morceaux.append(f"instance {n['instance']}" + (f" ({t_inst})" if t_inst else ""))
            else:
                morceaux.append(n.get("type") or "(surcharge)")
            if n.get("script"):
                morceaux.append(f"script {n['script']}")
            if n.get("groupes"):
                morceaux.append("groupes " + ",".join(n["groupes"]))
            props = n.get("proprietes", {})
            if props:
                morceaux.append(" ".join(f"{k}={_resume_valeur(v, internes)}" for k, v in props.items()))
            lignes.append("  " * (profondeur + 1) + "  ".join(morceaux))
            noeuds_json.append({"id": ident, "chemin": chemin, "type": n.get("type"), "instance": n.get("instance"),
                                "script": n.get("script"), "groupes": n.get("groupes", [])})
        connexions = []
        for c in spec.get("connexions", []):
            src = id_noeud(alias[res], c["source"])
            cib = id_noeud(alias[res], c["cible"])
            extra = "".join(f" {k}={ecrire_valeur(c[k])}" for k in ("binds", "unbinds", "flags") if k in c)
            lignes.append(f"  connexion {src}.{c['signal']} → {cib}.{c['methode']}{extra}")
            connexions.append({"source": src, "signal": c["signal"], "cible": cib, "methode": c["methode"]})
        scenes_json.append({"chemin": res, "alias": alias[res], "noeuds": noeuds_json, "connexions": connexions})

    scripts_json = []
    tests = []
    for res in projet.scripts():
        s = projet.script(res)
        if s is None:
            continue
        if "GdUnitTestSuite" == s.extends or res.startswith("res://tests/"):
            nb = sum(1 for f in s.fonctions if f.nom.startswith("test_"))
            tests.append(f"{res} ({nb} tests)")
            continue
        entete = f"SCRIPT {res}"
        if s.class_name:
            entete += f"  class_name {s.class_name}"
        if s.extends:
            entete += f"  extends {s.extends}"
        lignes.append("")
        lignes.append(entete)
        for sig in s.signaux:
            lignes.append(f"  {sig.texte()}")
        for e in s.enums:
            lignes.append(f"  enum {e}")
        for c in s.constantes:
            lignes.append(f"  const {c}")
        for v in s.variables:
            lignes.append(f"  {v.texte()}")
        for f in s.fonctions:
            lignes.append(f"  {f.signature()}")
        scripts_json.append({
            "chemin": res, "class_name": s.class_name, "extends": s.extends,
            "signaux": [{"nom": x.nom, "arguments": arguments_json(x.arguments)} for x in s.signaux],
            "variables": [{"nom": v.nom, "type": v.type, "export": v.exportee} for v in s.variables],
            "fonctions": [{"nom": f.nom, "arguments": arguments_json(f.arguments), "retour": f.retour} for f in s.fonctions],
        })
    ressources = projet.ressources()
    if ressources:
        lignes.append("")
        lignes.append("RESSOURCES")
        for res in ressources:
            lignes.append(f"  {res}  {projet.type_ressource(res) or '?'}")
    if tests:
        lignes.append("")
        lignes.append("TESTS (lecture seule)")
        lignes.extend(f"  {t}" for t in tests)
    return {"texte": "\n".join(lignes) + "\n", "ids": ids, "scenes": scenes_json, "scripts": scripts_json,
            "autoloads": autoloads}
