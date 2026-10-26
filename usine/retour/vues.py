"""Voir la scène 3D comme dans l'éditeur (outil voir_scene) : vue du jeu, vues d'observation et carte.

Leçon d'un vrai débogage (roguelike de laurent, 2026-10-26) : la caméra était à 12 m au-dessus du joueur, sans
rotation, donc tournée vers l'horizon (-Z) ; l'image 3D était vide et le HUD visible. Qwen a cherché du côté de la
fenêtre et du pilote ; il fallait situer la caméra et les objets. Cet outil le fait :

- vue du jeu : ce que voit le joueur, HUD compris ;
- vues d'observation cadrées sur la scène (dessus, côté, face, 3/4), sans dépendre de la caméra du jeu, avec les
  repères de l'éditeur : champ de la caméra du jeu (jaune), boîte de chaque objet (verte dans le champ, rouge hors
  champ), axes X Y Z (rouge, vert, bleu), grille du sol (y = 0), noms des nœuds ;
- carte en texte : caméra (position, direction de visée, projection), chaque objet dans le champ ou non et pourquoi
  (derrière le plan proche, au-delà de far, à gauche, à droite, au-dessus, au-dessous, couche exclue), autres
  caméras, lumières, objets cachés, et une carte vue de dessus en caractères.

Rendu fenêtré hors de l'écran, en Compatibilité, sur une copie du projet (règle 7) ; seul notre processus est arrêté
(règle 8). Le script Godot est `gd/vues_scene.gd`, posé en autoload dans la copie.
"""

from __future__ import annotations

import json
import math
import re
import shutil
import tempfile
import time
from pathlib import Path
from typing import Any, Iterable

from usine import config as cfg
from usine.processus import executer
from usine.retour.capture import IGNORES, _prefixe_ecran

SCRIPT = Path(__file__).resolve().parent / "gd" / "vues_scene.gd"
INJECTE = "res://addons/usine_vues/vues_scene.gd"
VUES = ("jeu", "dessus", "cote", "face", "perspective")
LARGEUR_CARTE, HAUTEUR_CARTE = 60, 26


def _poser(copie: Path) -> None:
    cible = copie / INJECTE.removeprefix("res://")
    cible.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(SCRIPT, cible)
    projet_godot = copie / "project.godot"
    texte = projet_godot.read_text(encoding="utf-8")
    ligne = f'UsineVues="*{INJECTE}"'
    if re.search(r"^\[autoload\]", texte, re.M):
        texte = re.sub(r"^\[autoload\]\s*\n", lambda m: m.group(0) + ligne + "\n", texte, count=1, flags=re.M)
    else:
        texte = texte.rstrip("\n") + f"\n\n[autoload]\n\n{ligne}\n"
    projet_godot.write_text(texte, encoding="utf-8")


def voir(projet: Path, scene: str | None = None, image: int = 60, vues: Iterable[str] = VUES,
         cadrer: str | None = None, taille: tuple[int, int] = (640, 360), collisions: bool = False,
         sortie: Path | None = None, godot: Path | None = None, delai_s: float = 240) -> dict[str, Any]:
    """{ok, image (PNG de la planche), carte (texte), donnees (mesures), erreurs, erreur?}."""
    from usine.juge.godot import importer
    from usine.observation.visuel import POSITION_HORS_ECRAN, erreurs_sortie
    vues = [v for v in vues if v in VUES] or list(VUES)
    sortie = Path(sortie) if sortie else Path(tempfile.gettempdir()) / "usine_vues"
    sortie.mkdir(parents=True, exist_ok=True)
    base = sortie / f"vues_{time.strftime('%Y%m%d_%H%M%S')}_{time.perf_counter_ns() % 1000000}"
    godot = Path(godot) if godot else cfg.chemin_godot()
    with tempfile.TemporaryDirectory(prefix="usine_vues_") as tmp:
        copie = Path(tmp) / "projet"
        shutil.copytree(projet, copie, ignore=IGNORES)
        _poser(copie)
        importer(copie, godot)
        prefixe, options = _prefixe_ecran()
        if "gl_compatibility" not in options:
            options = [*options, "--rendering-method", "gl_compatibility"]
        if not prefixe:
            options = [*options, "--position", POSITION_HORS_ECRAN]
        if collisions:
            options.append("--debug-collisions")
        commande = [*prefixe, godot, "--path", copie, *options, "--fixed-fps", "60", *([scene] if scene else []),
                    "--", f"--vues-sortie={base}", f"--vues-image={max(1, int(image))}",
                    "--vues-liste=" + ",".join(vues), f"--vues-taille={taille[0]}x{taille[1]}",
                    *([f"--vues-cadrer={cadrer}"] if cadrer else [])]
        res = executer(commande, delai_s=delai_s)
    png, js = Path(str(base) + ".png"), Path(str(base) + ".json")
    if not js.is_file():
        lignes = [l for l in res.sortie.splitlines() if "ERROR" in l][:5]
        return {"ok": False, "image": None, "carte": "", "donnees": {}, "erreurs": erreurs_sortie(res.sortie),
                "erreur": ("délai dépassé" if res.expire else "aucune mesure écrite") +
                          (" : " + " | ".join(lignes) if lignes else "")}
    donnees = json.loads(js.read_text(encoding="utf-8"))
    return {"ok": True, "image": str(png) if png.is_file() else None, "carte": carte(donnees, vues),
            "donnees": donnees, "erreurs": erreurs_sortie(res.sortie), "duree_s": res.duree_s}


def _f(v: Iterable[float]) -> str:
    return "(" + ", ".join(f"{x:.2f}".rstrip("0").rstrip(".") if abs(x) >= 0.005 else "0" for x in v) + ")"


def _direction(d: list[float]) -> str:
    """En mots : la direction de visée par rapport au sol (y)."""
    pente = math.degrees(math.asin(max(-1.0, min(1.0, d[1]))))
    if abs(pente) < 5:
        return "à l'horizontale"
    if pente <= -85:
        return "droit vers le bas"
    if pente >= 85:
        return "droit vers le haut"
    return f"{abs(pente):.0f}° vers le {'bas' if pente < 0 else 'haut'}"


def carte(d: dict[str, Any], vues: Iterable[str] = VUES) -> str:
    lignes = [f"Scène {d.get('scene') or '?'}, image {d['image']} ({d['image'] / 60:.2f} s de jeu)."]
    cam = d.get("camera") or {}
    objets = d.get("objets", [])
    if not cam:
        lignes.append("Caméra du jeu : AUCUNE caméra 3D courante (rien ne peut s'afficher en 3D).")
    else:
        proj = (f"orthographique, size {cam['size']:g} m" if cam["projection"] == "orthographique"
                else f"perspective, fov {cam['fov']:g}°")
        lignes.append(f"Caméra du jeu : {cam['chemin']}, position {_f(cam['position'])}, regarde vers "
                      f"{_f(cam['regarde_vers'])} ({_direction(cam['regarde_vers'])}) ; {proj} ; near {cam['near']:g}, "
                      f"far {cam['far']:g}.")
    dedans = [o for o in objets if o.get("dans_le_champ")]
    lignes.append(f"Objets 3D visibles : {len(objets)} ; dans le champ de la caméra : {len(dedans)}.")
    tries = sorted(objets, key=lambda o: -max(o["taille"][0], 0.01) * max(o["taille"][1], 0.01) * max(o["taille"][2], 0.01))
    for o in tries[:25]:
        if o.get("dans_le_champ", True):
            etat = f"dans le champ, à l'écran {tuple(o['ecran'])}" if "ecran" in o else "dans le champ"
        else:
            etat = "HORS CHAMP : " + ", ".join(o.get("hors_champ", []))
        lignes.append(f"  {o['chemin'].removeprefix('/root/')} [{o['type']}] centre {_f(o['centre'])} taille "
                      f"{_f(o['taille'])}" + (f", à {o['distance']:g} m" if "distance" in o else "") + f" : {etat}")
    if len(objets) > 25:
        lignes.append(f"  … {len(objets) - 25} objets plus petits non listés")
    autres = [c for c in d.get("cameras", []) if not c["courante"]]
    if autres:
        lignes.append("Autres caméras (non courantes) : " + " ; ".join(
            f"{c['chemin'].removeprefix('/root/')} en {_f(c['position'])}" for c in autres))
    for l in d.get("lumieres", []):
        lignes.append(f"Lumière {l['chemin'].removeprefix('/root/')} ({l['type']}) : en {_f(l['position'])}, vers "
                      f"{_f(l['vers'])}, énergie {l['energie']:g}" + ("" if l["visible"] else ", CACHÉE"))
    if not d.get("lumieres"):
        lignes.append("Lumières : aucune.")
    if d.get("caches"):
        lignes.append("Objets cachés (visible = false) : " + ", ".join(c.removeprefix("/root/") for c in d["caches"][:15]))
    lignes += ["", carte_texte(d), "", "Vues : " + ", ".join(vues) + " ; repères : jaune = champ de la caméra du jeu, "
               "vert = objet dans le champ, rouge = hors champ, axes X rouge, Y vert, Z bleu, grille à y = 0."]
    return "\n".join(lignes)


def carte_texte(d: dict[str, Any], largeur: int = LARGEUR_CARTE, hauteur: int = HAUTEUR_CARTE) -> str:
    """Vue de dessus en caractères (haut = -Z) : C la caméra, flèche sa visée, lettres des objets (majuscule dans le
    champ, minuscule hors champ), + l'origine."""
    b = d["bornes"]
    cx, cz = b["centre"][0], b["centre"][2]
    demi = max(b["taille"][0] / 2, b["taille"][2] / 2 * largeur / hauteur / 2, 0.5)
    pas = 2 * demi / largeur
    grille = [[" "] * largeur for _ in range(hauteur)]

    def case(x: float, z: float) -> tuple[int, int] | None:
        i = int((x - (cx - demi)) / pas)
        j = int((z - (cz - demi * hauteur * 2 / largeur)) / (pas * 2))
        return (i, j) if 0 <= i < largeur and 0 <= j < hauteur else None

    legende = []
    lettres = "ABDEFGHIJKLMNOPQRSTUVWXYZ"  # C est réservé à la caméra
    tries = sorted(d.get("objets", []), key=lambda o: -o["taille"][0] * o["taille"][2])
    for k, o in enumerate(tries[:len(lettres)]):
        lettre = lettres[k] if o.get("dans_le_champ", True) else lettres[k].lower()
        x0, x1 = o["centre"][0] - o["taille"][0] / 2, o["centre"][0] + o["taille"][0] / 2
        z0, z1 = o["centre"][2] - o["taille"][2] / 2, o["centre"][2] + o["taille"][2] / 2
        n = 0
        cases = [(i, j) for j in range(hauteur) for i in range(largeur)
                 if x0 <= cx - demi + (i + 0.5) * pas <= x1
                 and z0 <= cz - demi * hauteur * 2 / largeur + (j + 0.5) * pas * 2 <= z1]
        grand = len(cases) > 30  # un grand objet en contour, pour laisser voir ce qu'il contient
        bord = {(i, j) for i, j in cases if not grand or (i - 1, j) not in cases or (i + 1, j) not in cases
                or (i, j - 1) not in cases or (i, j + 1) not in cases}
        for i, j in cases:
            if (i, j) in bord and grille[j][i] == " ":
                grille[j][i] = lettre
                n += 1
        if n == 0 and (c := case(o["centre"][0], o["centre"][2])):
            grille[c[1]][c[0]] = lettre
        legende.append(f"{lettre} = {o['nom']} (y de {o['centre'][1] - o['taille'][1] / 2:.1f} à "
                       f"{o['centre'][1] + o['taille'][1] / 2:.1f})")
    if c := case(0.0, 0.0):
        grille[c[1]][c[0]] = "+"
    cam = d.get("camera") or {}
    if cam:
        p, v = cam["position"], cam["regarde_vers"]
        note = f"C = caméra, à y = {p[1]:g}, visée {_direction(v)}"
        if c := case(p[0], p[2]):
            grille[c[1]][c[0]] = "C"
            if abs(v[0]) + abs(v[2]) > 0.1:  # la flèche donne la visée projetée sur le sol
                fleche = (">" if v[0] > 0 else "<") if abs(v[0]) >= abs(v[2]) else ("v" if v[2] > 0 else "^")
                i = c[0] + (1 if fleche == ">" else -1 if fleche == "<" else 0)
                j = c[1] + (1 if fleche == "v" else -1 if fleche == "^" else 0)
                if 0 <= i < largeur and 0 <= j < hauteur:
                    grille[j][i] = fleche
            else:
                note += " (verticale : pas de flèche)"
        else:
            note += " (hors de la carte)"
        legende.insert(0, note)
    cadre = "+" + "-" * largeur + "+"
    corps = ["|" + "".join(l) + "|" for l in grille]
    entete = f"Carte vue de dessus (haut = -Z, droite = +X ; 1 caractère = {pas:.2f} m ; + = origine) :"
    return "\n".join([entete, cadre, *corps, cadre, *legende[:28]])
