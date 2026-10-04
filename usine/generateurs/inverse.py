"""Inverse (F1) : tirer des paramètres au hasard, les mesurer en frames, demander de les retrouver.

1. Tirage reproductible (graine) de paramètres du héros sur une grille : vitesse de marche,
   vitesse et durée du dash (= durée des i-frames), recharge.
2. Mesure par le moteur, en physique déterministe (gabarits.FONCTION_MESURE_HERO : pas fixe,
   move_and_collide) : distance de marche sur 30 images, images de dash, images
   d'invulnérabilité, images avant de pouvoir redasher, distance du dash.
3. Tâche : « retrouver des réglages qui donnent ces mesures ». depart = projet d'origine ;
   reference = hero.gd avec les valeurs tirées ; test caché = mêmes mesures sur le candidat
   (frames exactes, distances à 0,5 px). Plusieurs réglages peuvent convenir : le juge vérifie
   les mesures, pas les valeurs.
"""

from __future__ import annotations

import json
import random
import re
from pathlib import Path
from typing import Any

from usine.generateurs import gabarits
from usine.generateurs.commun import Production, ecrire_tache, executer_gd, ident, lire_projet, nom_source

ORIGINE = "generateur:inverse"
SCRIPT_HERO = "scripts/hero.gd"
SCENE_HERO = "res://scenes/hero.tscn"
# paramètre → (minimum, maximum, pas, décimales)
GRILLE = {
    "speed": (100.0, 320.0, 10.0, 1),
    "dash_speed": (300.0, 900.0, 20.0, 1),
    "dash_duration": (0.05, 0.40, 0.01, 2),
    "dash_cooldown": (0.20, 1.50, 0.05, 2),
}

FONCTION_LOT = '''

func mesurer_lot(scene: String, lots) -> Array:
	var resultats: Array = []
	for reglages in lots:
		resultats.append(mesurer_hero(scene, reglages))
	return resultats
'''


def tirer(rng: random.Random) -> dict[str, float]:
    valeurs = {}
    for nom, (mini, maxi, pas, dec) in GRILLE.items():
        n = int(round((maxi - mini) / pas))
        valeurs[nom] = round(mini + pas * rng.randint(0, n), dec)
    return valeurs


def appliquer(texte: str, valeurs: dict[str, float]) -> str:
    for nom, v in valeurs.items():
        motif = re.compile(rf"^(@export var {nom}: float = )[0-9.]+$", re.M)
        if len(motif.findall(texte)) != 1:
            raise ValueError(f"déclaration de {nom} introuvable ou multiple dans {SCRIPT_HERO}")
        texte = motif.sub(lambda m: m.group(1) + f"{v:.{GRILLE[nom][3]}f}", texte)
    return texte


def consigne(m: dict[str, Any]) -> str:
    return ("Régler le héros (les @export speed, dash_speed, dash_duration et dash_cooldown de "
            f"res://{SCRIPT_HERO}) pour obtenir ces mesures, à {60} images par seconde : "
            f"en marchant 30 images vers la droite, il parcourt {m['marche_30_images_px']:g} px ; "
            f"un dash dure {m['images_dash']} images et couvre {m['dash_px']:g} px ; "
            f"il est invulnérable pendant {m['images_invulnerable']} images ; "
            f"il peut redasher {m['images_avant_redash']} images après le début du dash. "
            "Ne modifier que ces valeurs.")


def generer(source: Path, sortie: Path, graine: int, nombre: int = 40) -> Production:
    prod = Production()
    projet = lire_projet(source)
    rng = random.Random(f"inverse:{graine}")
    tirages: list[dict[str, float]] = []
    vus = set()
    essais = 0
    while len(tirages) < nombre and essais < nombre * 20:
        essais += 1
        t = tirer(rng)
        cle = tuple(sorted(t.items()))
        if cle not in vus:
            vus.add(cle)
            tirages.append(t)
    lots = [{}] + tirages
    script = gabarits.script_mesure(gabarits.FONCTION_MESURE_HERO + FONCTION_LOT)
    mesures, sortie_godot = executer_gd(projet, script, ["mesurer_lot", SCENE_HERO, json.dumps(lots)])
    if not mesures or len(mesures[0]) != len(lots):
        prod.ecarter("inverse", "lot", "mesure_impossible", sortie_godot[-400:])
        return prod
    origine, resultats = mesures[0][0], mesures[0][1:]
    vues_mesures = set()
    for valeurs, m in zip(tirages, resultats):
        id_ = ident("f1", nom_source(source), "hero", *(f"{k}{str(v).replace('.', 'p')}" for k, v in valeurs.items()))
        cle_mesure = json.dumps(m, sort_keys=True)
        if m == origine:
            prod.ecarter("inverse", id_, "cible_identique_au_depart")
            continue
        if cle_mesure in vues_mesures:
            prod.ecarter("inverse", id_, "mesures_deja_tirees")
            continue
        vues_mesures.add(cle_mesure)
        tache = {"id": id_, "competence": "F1", "consigne": consigne(m), "consigne_a_ecrire": None,
                 "origine": ORIGINE,
                 "generateur": {"nom": "inverse", "source": nom_source(source), "graine": graine, "valeurs": valeurs}}
        tests = {"test_f1_mesures.gd": gabarits.test_f1(),
                 "mesure_f1.json": json.dumps(m, ensure_ascii=False, sort_keys=True, indent=1) + "\n"}
        prod.taches.append(ecrire_tache(sortie, tache, dict(projet),
                                        {SCRIPT_HERO: appliquer(projet[SCRIPT_HERO], valeurs)}, tests))
    return prod
