"""Voir l'éditeur Godot tel qu'on le voit : la fenêtre entière, et ce qu'elle montre (outil voir_editeur).

Étape A9 du suivi : laurent veut que Qwen sache « où est quoi et quoi faire » dans l'interface de Godot. On ouvre
l'éditeur 4.7.2 sur une copie du projet, avec un plugin (`gd/editeur_plugin.gd`) qui ouvre la scène, sélectionne
un nœud, déplie l'Inspecteur jusqu'à une propriété, rend la fenêtre entière et écrit sa vérité : zones (Scène,
Système de fichiers, Inspecteur, vue 3D…), lignes de l'arbre de scène avec leur place, propriétés visibles de
l'Inspecteur avec la valeur affichée, place des nœuds 3D dans la vue de l'éditeur.

Précautions, mesurées le 2026-10-27 sur la machine de laurent :
- l'éditeur ne suit pas `--position` (il se centre, ou s'agrandit au premier lancement) : on le lance réduit, sans
  focus (`executer(reduit=True)`), et le plugin le pose hors de l'écran avant la première image ;
- une boîte de dialogue de l'éditeur (erreur de plugin…) est une fenêtre à part, posée sur l'écran : c'est arrivé
  une fois, laurent l'a vue. D'où le mode fenêtre unique dans les réglages (les boîtes restent dans la fenêtre hors
  de l'écran) et un contrôle sans fenêtre avant d'ouvrir l'éditeur : si le plugin ne se charge pas, rien ne s'ouvre ;
- l'éditeur range ses réglages dans le profil de l'utilisateur : on emploie une copie de Godot en mode autonome
  (fichier `._sc_` à côté de l'exécutable, réglages dans `editor_data/`), dans le dossier de données ;
- les autres plugins de la copie sont désactivés : `godot-ai` y ouvrirait ses ports, déjà pris par celui de laurent.
"""

from __future__ import annotations

import json
import re
import shutil
import tempfile
import time
from pathlib import Path
from typing import Any

from usine import config as cfg
from usine.processus import executer
from usine.retour.capture import IGNORES

PLUGIN = Path(__file__).parent / "gd" / "editeur_plugin.gd"
DOSSIER_PLUGIN = "addons/usine_editeur"
PLUGIN_CFG = ('[plugin]\n\nname="usine_editeur"\ndescription="Voir l\'éditeur (usine)"\nauthor="usine"\nversion="1.0"\n'
              'script="editeur_plugin.gd"\n')
POSITION_HORS_ECRAN = "-6000,-6000"


COUCHES = 20  # cases d'une grille de couches (Cull Mask, Layers)


# ------------------------------------------------------------------ lire la vérité du plugin

def place(rect: list[int], fenetre: list[int]) -> str:
    """Où est un rectangle dans la fenêtre, en mots."""
    cx, cy = (rect[0] + rect[2] / 2) / fenetre[0], (rect[1] + rect[3] / 2) / fenetre[1]
    horizontal = "à gauche" if cx < 1 / 3 else ("à droite" if cx > 2 / 3 else "au centre")
    vertical = "en haut" if cy < 0.4 else ("en bas" if cy > 0.6 else "")
    if horizontal == "au centre" and not vertical:
        return "au centre"
    return f"{vertical} {horizontal}".strip()


def libelle(p: dict[str, Any]) -> str:
    return f"{p['groupe']} > {p['libelle']}" if p.get("groupe") else p["libelle"]


def grille(p: dict[str, Any]) -> bool:
    """Une propriété de couches (Cull Mask, Layers…) : une grille de cases dessinée par l'éditeur, sans texte à lire."""
    return not p["affiche"] and p["valeur"].isdigit() and p["propriete"].endswith(("mask", "layers", "layer"))


def _couches(numeros: list[str]) -> str:
    return f"couche{'s' if len(numeros) > 1 else ''} {', '.join(numeros)}"


def affiche(p: dict[str, Any]) -> str:
    """La valeur telle que l'Inspecteur la montre ; une grille de couches se décrit d'après la valeur (l'éditeur
    n'en montre que 10 cases à la fois)."""
    if grille(p):
        v = int(p["valeur"])
        cochees = [str(i + 1) for i in range(COUCHES) if v >> i & 1]
        decochees = [str(i + 1) for i in range(COUCHES) if not v >> i & 1]
        if not decochees:
            return f"couches 1 à {COUCHES} cochées"
        if not cochees:
            return "aucune couche cochée"
        if len(cochees) < len(decochees):  # dire le plus court
            return f"seule{'s' if len(cochees) > 1 else ''} la {_couches(cochees)} cochée{'s' if len(cochees) > 1 else ''}"
        return f"{_couches(decochees)} décochée{'s' if len(decochees) > 1 else ''}"
    return " ".join(p["affiche"]) if p["affiche"] else p["valeur"]


def godot_editeur(godot: Path | None = None, donnees: Path | None = None) -> Path:
    """L'exécutable de l'éditeur, copié en mode autonome dans le dossier de données (réglages à part)."""
    console = Path(godot) if godot else cfg.chemin_godot()
    source = console.with_name(console.name.replace("_console", ""))
    dossier = Path(donnees or cfg.dossier_donnees()) / "editeur_godot"
    cible = dossier / source.name
    if not cible.is_file() or cible.stat().st_size != source.stat().st_size:
        dossier.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, cible)
    (dossier / "._sc_").touch()
    _fenetre_unique(dossier / "editor_data")
    return cible


REGLAGES_FENETRE = {"interface/editor/display/single_window_mode": "true", "interface/multi_window/enable": "false"}


def _fenetre_unique(editor_data: Path) -> None:
    """Réglages de la copie autonome : une seule fenêtre, sans sous-fenêtres. Godot complète le reste du fichier."""
    editor_data.mkdir(parents=True, exist_ok=True)
    reglages = editor_data / f"editor_settings-{'.'.join(cfg.version_godot().split('.')[:2])}.tres"
    texte = (reglages.read_text(encoding="utf-8") if reglages.is_file()
             else '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n')
    for cle, valeur in REGLAGES_FENETRE.items():
        ligne = f"{cle} = {valeur}"
        if re.search(rf"^{re.escape(cle)} = ", texte, re.M):
            texte = re.sub(rf"^{re.escape(cle)} = .*$", ligne, texte, flags=re.M)
        else:
            texte = texte.rstrip("\n") + "\n" + ligne + "\n"
    reglages.write_text(texte, encoding="utf-8", newline="\n")


def _poser(copie: Path) -> None:
    """Le plugin dans la copie, seul plugin d'éditeur actif."""
    dossier = copie / DOSSIER_PLUGIN
    dossier.mkdir(parents=True, exist_ok=True)
    shutil.copy2(PLUGIN, dossier / PLUGIN.name)
    (dossier / "plugin.cfg").write_text(PLUGIN_CFG, encoding="utf-8", newline="\n")
    projet_godot = copie / "project.godot"
    texte = projet_godot.read_text(encoding="utf-8")
    ligne = f'enabled=PackedStringArray("res://{DOSSIER_PLUGIN}/plugin.cfg")'
    if re.search(r"^\[editor_plugins\]", texte, re.M):
        texte = re.sub(r"^\[editor_plugins\]\s*\n(?:enabled=.*\n)?", f"[editor_plugins]\n\n{ligne}\n", texte,
                       count=1, flags=re.M)
    else:
        texte = texte.rstrip("\n") + f"\n\n[editor_plugins]\n\n{ligne}\n"
    projet_godot.write_text(texte, encoding="utf-8", newline="\n")


def voir_editeur(projet: Path, scene: str, selection: str | None = None, propriete: str | None = None,
                 releves: list[tuple[str, str]] | None = None, reduite: tuple[int, int] | None = None,
                 ecran: str | None = None, taille: tuple[int, int] = (1920, 1080), sortie: Path | None = None,
                 godot: Path | None = None, delai_s: float = 90) -> dict[str, Any]:
    """{ok, image (PNG de la fenêtre), donnees (vérité du plugin), erreurs, duree_s, erreur?}.
    `selection` : chemin du nœud depuis la racine de la scène (« . » pour la racine). `releves` : d'autres
    (chemin, propriété), lues dans l'Inspecteur après l'image, telles qu'il les affiche. `reduite` : une copie
    de l'image à cette taille (Lanczos, par Godot), rendue sous `image_reduite`."""
    from usine.observation.visuel import erreurs_sortie
    sortie = (Path(sortie) if sortie else Path(tempfile.gettempdir()) / "usine_editeur").resolve()  # l'éditeur a son dossier courant
    sortie.mkdir(parents=True, exist_ok=True)
    base = sortie / f"editeur_{time.strftime('%Y%m%d_%H%M%S')}_{time.perf_counter_ns() % 1000000}"
    exe = godot_editeur(godot)
    with tempfile.TemporaryDirectory(prefix="usine_editeur_") as tmp:
        copie = Path(tmp) / "projet"
        shutil.copytree(projet, copie, ignore=IGNORES)
        _poser(copie)
        # Sans fenêtre d'abord : l'éditeur importe la copie et charge le plugin ; s'il échoue, on s'arrête là.
        controle = executer([exe, "--headless", "--editor", "--quit-after", "120", "--path", copie], delai_s=delai_s)
        refus = [l for l in erreurs_sortie(controle.sortie) if "usine_editeur" in l or "Parse Error" in l]
        if refus or controle.expire:
            return {"ok": False, "image": None, "donnees": {}, "erreurs": erreurs_sortie(controle.sortie),
                    "erreur": "le plugin ne se charge pas, éditeur non ouvert" if refus else "délai dépassé (contrôle)"}
        commande = [exe, "--editor", "--path", copie, "--",
                    f"--editeur-sortie={base}", f"--editeur-scene={scene}", *([f"--editeur-ecran={ecran}"] if ecran else []),
                    f"--editeur-taille={taille[0]}x{taille[1]}", f"--editeur-position={POSITION_HORS_ECRAN}",
                    *([f"--editeur-selection={selection}"] if selection else []),
                    *([f"--editeur-propriete={propriete}"] if propriete else []),
                    *([f"--editeur-reduite={reduite[0]}x{reduite[1]}"] if reduite else []),
                    *([f"--editeur-releves={';'.join(f'{c}:{p}' for c, p in releves)}"] if releves else [])]
        res = executer(commande, delai_s=delai_s, reduit=True)
    png, js = Path(str(base) + ".png"), Path(str(base) + ".json")
    if not js.is_file():
        lignes = [l for l in res.sortie.splitlines() if "ERROR" in l][:5]
        return {"ok": False, "image": None, "donnees": {}, "erreurs": erreurs_sortie(res.sortie),
                "erreur": ("délai dépassé" if res.expire else "aucune vérité écrite") +
                          (" : " + " | ".join(lignes) if lignes else "")}
    donnees = json.loads(js.read_text(encoding="utf-8"))
    petite = Path(str(base) + "_reduite.png")
    return {"ok": not donnees.get("erreurs"), "image": str(png) if png.is_file() else None,
            "image_reduite": str(petite) if petite.is_file() else None, "donnees": donnees,
            "erreurs": erreurs_sortie(res.sortie), "duree_s": res.duree_s}


def boutons_de_lancement(d: dict[str, Any]) -> list[dict[str, Any]]:
    """Les icônes de lancement, en haut à droite, dans l'ordre. Un bouton de l'Inspecteur remonté par le défilement
    a une place au-dessus de la fenêtre (y < 0) : il n'est pas à l'écran."""
    fen = d["fenetre"]
    return [b for b in d["haut"] if b["bulle"] and not b["texte"] and 0 <= b["rect"][1] < 0.05 * fen[1]
            and b["rect"][0] + b["rect"][2] / 2 > 0.75 * fen[0]]


def texte(d: dict[str, Any]) -> str:
    """Ce que montre l'éditeur, en mots : zones, arbre de scène, Inspecteur, vue 3D, lancement (sortie de l'outil)."""
    fen = d["fenetre"]
    lignes = [f"Éditeur Godot ({d['langue']}), fenêtre {fen[0]} × {fen[1]}, scène {d['scene']}."]
    zones = [f"{z['titre']} {place(z['rect'], fen)}" for cle, z in d["zones"].items()
             if z["visible"] and z["titre"] and cle != "vue_3d"]
    onglets = [b["texte"] for b in d.get("bas", []) if b.get("onglet")]
    lignes.append("Zones : " + " ; ".join(zones) + (f" ; panneau du bas (onglets {', '.join(onglets)})"
                                                     if onglets else "") + ".")
    arbre = []
    for l in d["arbre"]:
        marques = [l["type"]] + (["sélectionné"] if l["selectionne"] else []) + ([] if l["visible"] else ["caché"])
        profondeur = 0 if l["chemin"] == "." else l["chemin"].count("/") + 1
        arbre.append(f"{l['rang'] + 1}. {'  ' * profondeur}{l['texte']} [{', '.join(marques)}]")
    lignes.append("Arbre de la scène (dock Scène) :\n" + "\n".join(arbre))
    ins = d["inspecteur"]
    vues = [f"{libelle(p)} : {affiche(p)}" for p in ins["proprietes"] if p["entiere"]]
    if ins["objet"]:
        lignes.append(f"Inspecteur : {ins['objet']} ({ins['classe']}) ; propriétés visibles : " + " ; ".join(vues))
    noeuds = d["vue_3d"]["noeuds"]
    if noeuds:
        nom = lambda v: v["chemin"].split("/")[-1] if v["chemin"] != "." else d["arbre"][0]["texte"]  # noqa: E731
        lignes.append("Vue 3D (caméra de l'éditeur, pas celle du jeu) : dans la vue : "
                      + ", ".join(nom(v) for v in noeuds if v["dans_la_vue"]) + " ; hors de la vue : "
                      + (", ".join(nom(v) for v in noeuds if not v["dans_la_vue"]) or "aucun") + ".")
    lancement = boutons_de_lancement(d)
    if lancement:
        lignes.append(f"Lancement ({place(lancement[0]['rect'], fen)}) : "
                      + " ; ".join(f"{k}. « {b['bulle']} »" for k, b in enumerate(lancement, 1)) + ".")
    if d.get("erreurs"):
        lignes.append("Erreurs de l'outil : " + " | ".join(d["erreurs"]))
    return "\n".join(lignes)
