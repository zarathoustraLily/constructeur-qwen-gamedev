"""Preuve de l'aller-retour .tscn → spec → .tscn, avec un contrôle indépendant par Godot.

Pour chaque scène :
- normalisé identique : normaliser_tscn(original) == normaliser_tscn(réécrit) ;
- point fixe          : réécrire la réécriture redonne les mêmes octets (pour une scène
                        générée par scene_write : dès la première relecture) ;
- Godot identique     : le SceneState que Godot charge est le même avant et après
                        (gd/etat_scene.gd ; ne dépend pas de notre lecteur).
Les 5 scènes générées (exemples.py) sont validées, écrites dans une copie du projet de
référence, chargées par le juge load_scene, puis passent le même aller-retour.
"""

from __future__ import annotations

import json
import tempfile
from pathlib import Path
from typing import Any

from usine import config as cfg
from usine.juge import godot as juges
from usine.juge.projet import preparer_copie
from usine.processus import executer
from usine.projet.index import Projet, Verificateur, disque_vers_res, res_vers_disque
from usine.scene.exemples import specs_generees
from usine.scene.spec import normaliser_tscn, scene_read, scene_write, valider_spec

SCRIPT_ETAT = Path(__file__).resolve().parent / "gd" / "etat_scene.gd"
MARQUEUR_ETAT = "@@ETAT_SCENE@@"


def verificateur(projet: Path) -> Verificateur:
    from usine.vocab import ouvrir
    return Verificateur(ouvrir(), Projet(projet))


def aller_retour(texte: str, res: str, verif: Verificateur | None = None) -> dict[str, Any]:
    spec = scene_read(texte, res)
    ecrit = scene_write(spec, verif)
    reecrit = scene_write(scene_read(ecrit, res), verif)
    return {"scene": res, "ecrit": ecrit, "normalise_identique": normaliser_tscn(texte) == normaliser_tscn(ecrit),
            "point_fixe": ecrit == reecrit, "octets_identiques": ecrit == texte}


def etats_godot(projet: Path, scenes: list[str], godot: Path | None = None) -> dict[str, Any]:
    """SceneState de chaque scène tel que Godot le charge (res:// → description JSON)."""
    res = executer([godot or cfg.chemin_godot(), "--headless", "--path", projet, "-s", SCRIPT_ETAT, "--", *scenes],
                   delai_s=cfg.delai_juge())
    etats = {}
    for ligne in res.sortie.splitlines():
        if ligne.startswith(MARQUEUR_ETAT):
            d = json.loads(ligne[len(MARQUEUR_ETAT):])
            etats[d["chemin"]] = d
    return etats


def preuve(projet_ref: Path, avec_godot: bool = True, afficher=print, avec_generees: bool = True) -> int:
    projet_ref = Path(projet_ref)
    echecs = 0
    lignes = [f"{'scène':44} {'normalisé':10} {'point fixe':11} {'Godot':6} {'load_scene':10}"]
    with tempfile.TemporaryDirectory(prefix="usine_scene_") as tmp:
        copie = preparer_copie(projet_ref, Path(tmp) / "projet")
        verif = verificateur(copie)

        # 1. Scènes générées : validation, écriture dans la copie.
        generees = []
        for spec in (specs_generees() if avec_generees else []):
            erreurs = valider_spec(spec, verif)
            if erreurs:
                for e in erreurs:
                    afficher(f"ERREUR spec {spec['chemin']} : {e['message']}")
                echecs += 1
                continue
            chemin = res_vers_disque(copie, spec["chemin"])
            chemin.parent.mkdir(parents=True, exist_ok=True)
            chemin.write_text(scene_write(spec, verif), encoding="utf-8", newline="\n")
            generees.append(spec["chemin"])

        scenes = sorted(disque_vers_res(copie, p) for p in copie.rglob("*.tscn")
                        if "addons" not in p.relative_to(copie).parts and ".godot" not in p.relative_to(copie).parts)
        resultats = {}
        for res in scenes:
            texte = res_vers_disque(copie, res).read_text(encoding="utf-8")
            resultats[res] = aller_retour(texte, res, verif)

        etat_avant, etat_apres, chargements = {}, {}, {}
        if avec_godot:
            juges.importer(copie)
            etat_avant = etats_godot(copie, scenes)
            for res in generees:
                chargements[res] = juges.load_scene(res_vers_disque(copie, res), copie)["ok"]
            # Remplace chaque scène par sa réécriture, puis relit avec Godot.
            for res, r in resultats.items():
                res_vers_disque(copie, res).write_text(r["ecrit"], encoding="utf-8", newline="\n")
            etat_apres = etats_godot(copie, scenes)

        for res in scenes:
            r = resultats[res]
            if res in generees:
                r["point_fixe"] = r["point_fixe"] and r["octets_identiques"]
            godot_ok = None
            if avec_godot:
                godot_ok = res in etat_avant and "erreur" not in etat_avant[res] and etat_avant[res] == etat_apres.get(res)
            charge = chargements.get(res)
            ok = r["normalise_identique"] and r["point_fixe"] and godot_ok is not False and charge is not False
            echecs += not ok
            oui = lambda b: "—" if b is None else ("oui" if b else "NON")
            lignes.append(f"{res:44} {oui(r['normalise_identique']):10} {oui(r['point_fixe']):11} "
                          f"{oui(godot_ok):6} {oui(charge):10}")
    for ligne in lignes:
        afficher(ligne)
    afficher("")
    afficher(f"{len(scenes) - min(echecs, len(scenes))}/{len(scenes)} scènes conformes ({len(generees)} générées)")
    return 0 if echecs == 0 else 1
