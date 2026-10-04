"""Preuve de l'aller-retour .tscn → spec → .tscn, avec un contrôle indépendant par Godot.

Deux séries de scènes, chacune dans une copie jetable du projet :

1. **Telles quelles** : les scènes du projet, plus les 5 scènes générées (exemples.py),
   validées puis écrites par scene_write et chargées par le juge load_scene.
2. **Resauvées par Godot** : les mêmes scènes, réécrites par Godot lui-même
   (gd/resauver_scene.gd : chargement puis ResourceSaver.save). C'est le format exact que
   produit l'éditeur ; il éprouve le lecteur sans dépendre de scènes écrites à la main.

Pour chaque scène :
- normalisé : normaliser_tscn(original) == normaliser_tscn(réécrit) ;
- point fixe : réécrire la réécriture redonne les mêmes octets (pour une scène générée par
  scene_write : dès la première relecture) ;
- Godot : le SceneState que Godot charge est le même avant et après réécriture
  (gd/etat_scene.gd ; ne dépend pas de notre lecteur) ;
- load_scene : le juge charge et instancie la scène générée ;
- = Godot : la scène générée par scene_write est identique, octet pour octet, à ce que
  Godot écrit quand il la resauve.
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
from usine.projet.index import Projet, Verificateur, disque_vers_res, lire_texte, res_vers_disque
from usine.scene.exemples import specs_generees
from usine.scene.spec import normaliser_tscn, scene_read, scene_write, valider_spec

DOSSIER_GD = Path(__file__).resolve().parent / "gd"
SCRIPT_ETAT = DOSSIER_GD / "etat_scene.gd"
SCRIPT_RESAUVER = DOSSIER_GD / "resauver_scene.gd"
MARQUEUR_ETAT = "@@ETAT_SCENE@@"
MARQUEUR_RESAUVER = "@@RESAUVER@@"


def verificateur(projet: Path) -> Verificateur:
    from usine.vocab import ouvrir
    return Verificateur(ouvrir(), Projet(projet))


def aller_retour(texte: str, res: str, verif: Verificateur | None = None) -> dict[str, Any]:
    spec = scene_read(texte, res)
    ecrit = scene_write(spec, verif)
    reecrit = scene_write(scene_read(ecrit, res), verif)
    return {"scene": res, "ecrit": ecrit, "normalise_identique": normaliser_tscn(texte) == normaliser_tscn(ecrit),
            "point_fixe": ecrit == reecrit, "octets_identiques": ecrit == texte}


def _lignes_marquees(sortie: str, marqueur: str) -> list[dict[str, Any]]:
    return [json.loads(l[len(marqueur):]) for l in sortie.splitlines() if l.startswith(marqueur)]


def etats_godot(projet: Path, scenes: list[str], godot: Path | None = None) -> dict[str, Any]:
    """SceneState de chaque scène tel que Godot le charge (res:// → description JSON)."""
    res = executer([godot or cfg.chemin_godot(), "--headless", "--path", projet, "-s", SCRIPT_ETAT, "--", *scenes],
                   delai_s=cfg.delai_juge())
    return {d["chemin"]: d for d in _lignes_marquees(res.sortie, MARQUEUR_ETAT)}


def resauver_godot(projet: Path, scenes: list[str], godot: Path | None = None) -> dict[str, int]:
    """Fait réécrire chaque scène par Godot (res:// → code d'erreur Godot, 0 = OK)."""
    res = executer([godot or cfg.chemin_godot(), "--headless", "--path", projet, "-s", SCRIPT_RESAUVER, "--", *scenes],
                   delai_s=cfg.delai_juge())
    return {d["chemin"]: d["code"] for d in _lignes_marquees(res.sortie, MARQUEUR_RESAUVER)}


def _scenes(copie: Path) -> list[str]:
    return sorted(disque_vers_res(copie, p) for p in copie.rglob("*.tscn")
                  if "addons" not in p.relative_to(copie).parts and ".godot" not in p.relative_to(copie).parts)


def _ecrire_generees(copie: Path, verif: Verificateur, avec_generees: bool, afficher) -> tuple[dict[str, str], int]:
    """Valide et écrit les scènes générées dans la copie. Renvoie ({res: texte écrit}, nombre de refus)."""
    generees, refus = {}, 0
    for spec in (specs_generees() if avec_generees else []):
        erreurs = valider_spec(spec, verif)
        if erreurs:
            for e in erreurs:
                afficher(f"ERREUR spec {spec['chemin']} : {e['message']}")
            refus += 1
            continue
        texte = scene_write(spec, verif)
        chemin = res_vers_disque(copie, spec["chemin"])
        chemin.parent.mkdir(parents=True, exist_ok=True)
        chemin.write_text(texte, encoding="utf-8", newline="\n")
        generees[spec["chemin"]] = texte
    return generees, refus


def _controler(copie: Path, scenes: list[str], verif: Verificateur, avec_godot: bool) -> dict[str, dict[str, Any]]:
    """Aller-retour de chaque scène de la copie, puis comparaison Godot avant/après réécriture."""
    resultats = {res: aller_retour(lire_texte(res_vers_disque(copie, res)), res, verif) for res in scenes}
    if avec_godot:
        avant = etats_godot(copie, scenes)
        for res, r in resultats.items():
            res_vers_disque(copie, res).write_text(r["ecrit"], encoding="utf-8", newline="\n")
        apres = etats_godot(copie, scenes)
        for res, r in resultats.items():
            r["godot"] = res in avant and "erreur" not in avant[res] and avant[res] == apres.get(res)
    return resultats


def preuve(projet_ref: Path, avec_godot: bool = True, afficher=print, avec_generees: bool = True) -> int:
    projet_ref = Path(projet_ref)
    echecs = 0
    oui = lambda b: "—" if b is None else ("oui" if b else "NON")
    lignes = [f"{'scène':52} {'normalisé':10} {'point fixe':11} {'Godot':6} {'load_scene':11} {'= Godot':7}"]
    total = 0

    with tempfile.TemporaryDirectory(prefix="usine_scene_") as tmp:
        # 1. Scènes telles quelles (+ générées).
        copie = preparer_copie(projet_ref, Path(tmp) / "telles_quelles")
        verif = verificateur(copie)
        generees, refus = _ecrire_generees(copie, verif, avec_generees, afficher)
        echecs += refus
        scenes = _scenes(copie)
        chargements: dict[str, bool] = {}
        if avec_godot:
            juges.importer(copie)
            for res in generees:
                chargements[res] = juges.load_scene(res_vers_disque(copie, res), copie)["ok"]
        series = [("", _controler(copie, scenes, verif, avec_godot))]

        # 2. Les mêmes, resauvées par Godot.
        egal_godot: dict[str, bool] = {}
        if avec_godot:
            copie_g = preparer_copie(projet_ref, Path(tmp) / "resauvees")
            _ecrire_generees(copie_g, verificateur(copie_g), avec_generees, lambda _m: None)
            juges.importer(copie_g)
            codes = resauver_godot(copie_g, scenes)
            for res in scenes:
                if codes.get(res) != 0:
                    afficher(f"ERREUR Godot n'a pas resauvé {res} (code {codes.get(res)})")
                    echecs += 1
            for res, texte in generees.items():
                egal_godot[res] = lire_texte(res_vers_disque(copie_g, res)) == texte
            series.append((" [resauvée]", _controler(copie_g, scenes, verificateur(copie_g), avec_godot)))

        for suffixe, resultats in series:
            for res in scenes:
                r = resultats[res]
                if res in generees and not suffixe:
                    r["point_fixe"] = r["point_fixe"] and r["octets_identiques"]
                charge = chargements.get(res) if not suffixe else None
                egal = egal_godot.get(res) if not suffixe else None
                verdicts = [r["normalise_identique"], r["point_fixe"], r.get("godot"), charge, egal]
                echecs += any(v is False for v in verdicts)
                total += 1
                lignes.append(f"{res + suffixe:52} {oui(verdicts[0]):10} {oui(verdicts[1]):11} {oui(verdicts[2]):6} "
                              f"{oui(verdicts[3]):11} {oui(verdicts[4]):7}".rstrip())
    for ligne in lignes:
        afficher(ligne)
    afficher("")
    if total > len(scenes):
        afficher("[resauvée] : la même scène après chargement puis ResourceSaver.save par Godot (format de l'éditeur)")
    resauvees = total - len(scenes)
    afficher(f"{max(total - echecs, 0)}/{total} scènes conformes ({len(generees)} générées"
             + (f", {resauvees} resauvées par Godot" if resauvees else "") + ")")
    return 0 if echecs == 0 else 1
