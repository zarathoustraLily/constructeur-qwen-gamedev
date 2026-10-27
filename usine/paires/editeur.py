"""Famille de paires « lire l'éditeur Godot » : où est quoi, quoi faire (étape A9, partie A).

laurent (2026-10-27) : « il ne faut pas oublier les paires avec l'interface godot ! pour qu'il sache ou est qsuoi et
quoi faire ». Chaque paire montre l'éditeur Godot 4.7.2 (fenêtre entière, réduite en 1 280 × 720 : 880 jetons
d'image), rendu par `voir_editeur` sur un cas d'A8, et sa réponse vient de la vérité du plugin :
- analyse : où est la caméra du joueur et où lire ses réglages ; comment lancer la scène et où lire ses messages ;
  quel nœud est sélectionné et ce que montre l'Inspecteur ;
- débogage : un symptôme et l'éditeur ouvert sur le nœud en cause → la valeur fautive telle qu'affichée, la cause,
  quoi changer dans l'éditeur (valeur lue dans l'éditeur sur le niveau sain) et dans le `.tscn`.

Vérité : chaque cas est vérifié deux fois par `voir_scene` (A8 : le symptôme au rendu fautif, rien hors champ au
rendu sain) ; la capture fautive doit afficher une autre valeur que la saine, sinon le cas est rejeté. Les positions
sont dites en mots (zone, rang dans l'arbre), pas en coordonnées : leur forme reste à fixer (ETAT).

    python -m usine.paires editeur [--niveaux N] [--graine G] [--paires P]
"""

from __future__ import annotations

import json
import shutil
import tempfile
from pathlib import Path
from typing import Any, Callable

from usine.paires import camera
from usine.paires import format as fmt
from usine.retour.editeur import (COUCHES, _couches, affiche, boutons_de_lancement, grille, libelle, place,
                                  voir_editeur)

FAMILLE = "lire_editeur"
SUJET = "graphisme 3D"
SCENE = camera.SCENE
REDUITE = (1280, 720)
PLAFOND = 2040  # 2 048 moins une marge : sur l'essai de mémoire, notre compte des images donne un jeton de moins
CAMERA_JEU = "Joueur/Pivot/Camera3D"
# Les défauts où la caméra du jeu ne voit plus le niveau, alors que la vue 3D de l'éditeur le montre toujours.
DEFAUTS_DE_CAMERA = {"inclinaison_absente", "visee_vers_le_haut", "camera_sous_le_sol", "far_trop_court",
                     "near_trop_loin", "champ_trop_etroit", "fov_trop_etroit", "cull_mask_sans_la_couche",
                     "autre_camera_courante"}
# Les réglages de la caméra montrés quand on demande où les lire (dans l'ordre de l'Inspecteur).
REGLAGES_CAMERA = ("cull_mask", "projection", "current", "fov", "size", "near", "far")


def reglages(nom: str, n: camera.Niveau) -> list[tuple[str, str]]:
    """Le nœud et la propriété à montrer pour chaque défaut ; le premier est sélectionné dans l'éditeur."""
    cible = camera._cible(n)
    return {
        "inclinaison_absente": [("Joueur/Pivot", "rotation"), (CAMERA_JEU, "position")],
        "visee_vers_le_haut": [(CAMERA_JEU, "rotation")],
        "camera_sous_le_sol": [("Joueur/Pivot", "position")],
        "far_trop_court": [(CAMERA_JEU, "far")],
        "near_trop_loin": [(CAMERA_JEU, "near")],
        "champ_trop_etroit": [(CAMERA_JEU, "size")],
        "fov_trop_etroit": [(CAMERA_JEU, "fov")],
        "cull_mask_sans_la_couche": [(CAMERA_JEU, "cull_mask")],
        "autre_camera_courante": [("CameraDebug", "current")],
        "modele_couche": [("Joueur/Modele", "rotation")],
        "objet_sous_le_sol": [(cible, "position")],
        "objet_cache": [(cible, "visible")],
        "objet_derriere_la_camera": [(cible, "position")],
    }[nom]


# ------------------------------------------------------------------ lire la vérité du plugin

def _rang(k: int) -> str:
    return "1re" if k == 1 else f"{k}e"


def ligne(d: dict[str, Any], chemin: str) -> dict[str, Any]:
    return next(l for l in d["arbre"] if l["chemin"] == chemin)


def dans_l_arbre(d: dict[str, Any], chemin: str) -> str:
    """« `Camera3D` (11e ligne de l'arbre, sous Niveau > Joueur > Pivot) »."""
    l = ligne(d, chemin)
    racine = d["arbre"][0]["texte"]
    parents = [racine] + ([] if chemin == "." else chemin.split("/")[:-1])
    return f"`{l['texte']}` ({_rang(l['rang'] + 1)} ligne de l'arbre, sous {' > '.join(parents)})"


def changer(fautive: dict[str, Any], saine: dict[str, Any]) -> str:
    """Le geste dans l'Inspecteur pour passer de la valeur affichée fautive à la saine."""
    if grille(saine):
        a, b = int(fautive["valeur"]), int(saine["valeur"])
        cocher = [str(i + 1) for i in range(COUCHES) if b >> i & 1 and not a >> i & 1]
        decocher = [str(i + 1) for i in range(COUCHES) if a >> i & 1 and not b >> i & 1]
        gestes = ([f"cocher {'les' if len(cocher) > 1 else 'la'} {_couches(cocher)}"] if cocher else []) + (
            [f"décocher {'les' if len(decocher) > 1 else 'la'} {_couches(decocher)}"] if decocher else [])
        return f"{' et '.join(gestes)} de {libelle(saine)} ({affiche(saine)})"
    if saine["affiche"] in (["coché"], ["non coché"]):
        return f"{'cocher' if saine['affiche'] == ['coché'] else 'décocher'} {libelle(saine)}"
    return f"mettre {libelle(saine)} à {affiche(saine)}"


def _maj(texte: str) -> str:
    return texte[:1].upper() + texte[1:]


def zone(d: dict[str, Any], cle: str) -> str:
    z = d["zones"][cle]
    return f"le dock {z['titre']} ({place(z['rect'], d['fenetre'])})"


def propriete_vue(d: dict[str, Any], nom: str) -> dict[str, Any] | None:
    return next((p for p in d["inspecteur"]["proprietes"] if p["propriete"] == nom and p["entiere"]), None)


# ------------------------------------------------------------------ paires

def _paire(type_: str, demande: str, reponse: str, image: str, preuve: dict[str, Any]) -> dict[str, Any]:
    # Palier de 2 048 : le plan en message système (section 3 ; l'image seule pèse 880 jetons, la paire dépasse 1 024).
    return fmt.paire(FAMILLE, SUJET, type_, f"{fmt.MARQUE_IMAGE}\n{demande}", reponse, preuve, images=[image],
                     systeme=fmt.plan())


def paire_camera(n: camera.Niveau, r: dict[str, Any], image: str) -> dict[str, Any]:
    """Niveau sain, caméra du jeu sélectionnée : où est-elle, où lire ses réglages."""
    d = r["donnees"]
    noms = [l["texte"] for l in d["arbre"]]
    vus = [p for nom in REGLAGES_CAMERA if (p := propriete_vue(d, nom))]
    reponse = (f"{_maj(zone(d, 'scene'))} montre l'arbre de {SCENE}, {len(noms)} lignes : {', '.join(noms)}. "
               f"La caméra du joueur est {dans_l_arbre(d, CAMERA_JEU)} ; elle est sélectionnée (ligne surlignée).\n"
               f"Ses réglages sont dans {zone(d, 'inspecteur')} : "
               + " ; ".join(f"{libelle(p)} : {affiche(p)}" for p in vus) + ".\n"
               f"La vue 3D, au centre, montre la scène par la caméra de l'éditeur, pas par celle du jeu : pour savoir ce "
               "que voit le joueur, il faut lire les réglages de `Camera3D` ou lancer la scène.")
    return _paire("analyse", f"Voici l'éditeur Godot ouvert sur {SCENE}. Où est la caméra du joueur, et où lire ses "
                  "réglages ?", reponse, image,
                  {"outil": "voir_editeur", "graine": n.graine, "style": n.style, "question": "camera"})


def paire_lancer(n: camera.Niveau, r: dict[str, Any], image: str) -> dict[str, Any] | None:
    """Niveau sain : comment lancer la scène ouverte, où lire ses messages."""
    d = r["donnees"]
    fen = d["fenetre"]
    lancement = boutons_de_lancement(d)
    titre_sortie = d.get("traductions", {}).get("Output")  # « Output » dans la langue de l'éditeur
    sortie = next((b for b in d.get("bas", []) if b.get("onglet") and b["texte"] == titre_sortie), None)
    if len(lancement) < 4 or sortie is None:
        return None
    principale, scene_ouverte = lancement[0], lancement[3]
    reponse = (f"Les boutons de lancement sont {place(principale['rect'], fen)}, {len(lancement)} icônes sans texte ; "
               f"leur bulle d'aide dit ce qu'ils font. Le 4e, « {scene_ouverte['bulle']} », lance la scène ouverte, "
               f"{SCENE} ; le 1er, « {principale['bulle']} », lance la scène principale du projet, ici la même. "
               f"Les messages du jeu (print, erreurs) s'affichent dans le panneau du bas, onglet « {sortie['texte']} ».")
    return _paire("analyse", f"Voici l'éditeur Godot ouvert sur {SCENE}. Comment lancer cette scène pour la tester, "
                  "et où lire ses messages ?", reponse, image,
                  {"outil": "voir_editeur", "graine": n.graine, "style": n.style, "question": "lancer"})


def paire_selection(c: camera.Cas, r: dict[str, Any], image: str) -> dict[str, Any]:
    """Cas fautif : quel nœud est sélectionné, où, et ce que montre l'Inspecteur (lecture seule)."""
    d = r["donnees"]
    chemin = d["selection"]
    l = ligne(d, chemin)
    p = propriete_vue(d, d["propriete"])
    sections = list(dict.fromkeys(x["groupe"] for x in d["inspecteur"]["proprietes"] if x["groupe"]))
    reponse = (f"Dans {zone(d, 'scene')}, le nœud sélectionné (ligne surlignée) est {dans_l_arbre(d, chemin)} ; "
               f"c'est un {l['type']}. {_maj(zone(d, 'inspecteur'))} montre ses propriétés"
               + (f", déroulées sur les sections {', '.join(sections)}" if sections else "")
               + f" ; on y lit {libelle(p)} : {affiche(p)}.")
    return _paire("analyse", f"L'éditeur Godot est ouvert sur {SCENE}. Quel nœud est sélectionné, où est-il, et que "
                  f"montre l'Inspecteur de sa propriété {p['libelle']} ?", reponse, image,
                  {"outil": "voir_editeur", "graine": c.niveau.graine, "style": c.niveau.style,
                   "defaut": c.defaut.nom if c.defaut else None, "question": "selection"})


def paire_debogage(c: camera.Cas, r: dict[str, Any], image: str,
                   sains: dict[tuple[str, str], dict[str, Any]]) -> dict[str, Any]:
    assert c.defaut and c.rendu_fautif and c.edition
    d = r["donnees"]
    regl = reglages(c.defaut.nom, c.niveau)
    fautives = {(d["selection"], d["propriete"]): propriete_vue(d, d["propriete"])}
    fautives |= {(x["chemin"], x["propriete"]): x for x in d["releves"]}
    principal = fautives[regl[0]]
    texte = (f"Dans {zone(d, 'scene')}, le nœud sélectionné est {dans_l_arbre(d, regl[0][0])} ; "
             f"{zone(d, 'inspecteur')} montre {libelle(principal)} : {affiche(principal)}.")
    if not ligne(d, regl[0][0])["visible"]:
        texte += f" Dans l'arbre, l'œil à droite de `{regl[0][0].split('/')[-1]}` est fermé : le nœud est caché."
    corps = next((v for v in d["vue_3d"]["noeuds"] if v["chemin"] == "Joueur/Modele/Corps"), None)
    if c.defaut.nom in DEFAUTS_DE_CAMERA and corps and corps["dans_la_vue"]:
        texte += (" La vue 3D montre bien le niveau, mais c'est la caméra de l'éditeur : elle ne dit rien de ce que voit "
                  "le joueur.")
    texte += f"\nCause : {c.defaut.cause(c.rendu_fautif['donnees'], c.niveau)}.\n"
    if c.defaut.nom == "autre_camera_courante":
        texte += ("Dans l'éditeur : supprimer le nœud `CameraDebug` du dock Scène ; la caméra du joueur redevient "
                  "la caméra courante.\n")
    else:
        etapes = [f"sélectionner `{chemin.split('/')[-1]}` dans le dock Scène, puis dans l'Inspecteur "
                  f"{changer(fautives[(chemin, prop)], sains[(chemin, prop)])}" for chemin, prop in regl]
        texte += "Dans l'éditeur : " + " ; ".join(etapes) + ".\n"
    apres = c.rendu_sain["donnees"]
    texte += (f"Ou dans {SCENE}, remplacer :\n```\n{c.edition[0]}\n```\npar :\n```\n{c.edition[1]}\n```\n"
              f"Puis relancer voir_scene : la caméra doit regarder {camera._direction(apres['camera']['regarde_vers'])} "
              f"et les {len(apres['objets'])} objets être dans son champ.")
    return _paire("débogage", f"{c.defaut.symptome}\nL'éditeur est ouvert sur {SCENE}.", texte, image,
                  {"outil": "voir_editeur", "graine": c.niveau.graine, "style": c.niveau.style,
                   "defaut": c.defaut.nom, "symptome_mesure": True, "correction_mesuree": True})


# ------------------------------------------------------------------ captures et vérification

def _projet(texte: str, dossier: Path) -> Path:
    if dossier.exists():
        shutil.rmtree(dossier)
    dossier.mkdir(parents=True)
    (dossier / "project.godot").write_text(
        f'config_version=5\n\n[application]\n\nconfig/name="Niveau"\nrun/main_scene="{SCENE}"\n'
        'config/features=PackedStringArray("4.7")\n', encoding="utf-8", newline="\n")
    (dossier / "niveau.tscn").write_text(texte, encoding="utf-8", newline="\n")
    return dossier


def _garder(r: dict[str, Any], base: Path) -> str:
    """L'image réduite et la vérité, rangées avec les paires ; rend le chemin de l'image (absolu, comme
    LLaMA-Factory le lit)."""
    shutil.copy2(r["image_reduite"], base.with_suffix(".png"))
    base.with_suffix(".json").write_text(json.dumps(r["donnees"], ensure_ascii=False, indent=1), encoding="utf-8")
    return base.with_suffix(".png").resolve().as_posix()


def montre_le_defaut(c: camera.Cas, r: dict[str, Any], sains: dict[tuple[str, str], dict[str, Any]]) -> bool:
    """La capture fautive affiche une autre valeur que la saine, pour chaque réglage du défaut."""
    d = r["donnees"]
    if d["selection"] != reglages(c.defaut.nom, c.niveau)[0][0]:
        return False
    if c.defaut.nom == "autre_camera_courante":
        p = propriete_vue(d, "current")
        return p is not None and p["valeur"] == "true"
    vues_ = {(d["selection"], d["propriete"]): propriete_vue(d, d["propriete"])}
    vues_ |= {(x["chemin"], x["propriete"]): x for x in d["releves"]}
    return all(vues_.get(k) is not None and k in sains and affiche(vues_[k]) != affiche(sains[k])
               for k in reglages(c.defaut.nom, c.niveau))


def generer(niveaux: int, graine: int = 1, donnees: Path | None = None,
            journal: Callable[[str], None] = print, cible: int | None = None) -> dict[str, Any]:
    """Comme la famille A8 : `niveaux` au plus, arrêt au niveau qui atteint `cible`, niveaux complets."""
    sortie = fmt.dossier(FAMILLE, donnees)
    images = sortie / "images"
    images.mkdir(parents=True, exist_ok=True)
    paires: list[dict[str, Any]] = []
    rejets: list[str] = []
    faits = 0
    with tempfile.TemporaryDirectory(prefix="usine_lire_editeur_") as tmp:
        travail = Path(tmp)
        for g in range(graine, graine + niveaux):
            cas, rej = camera.cas_du_niveau(g, travail)
            rejets += rej
            faits += 1
            if not cas:
                continue
            n = cas[0].niveau
            a_lire = list(dict.fromkeys(
                k for c in cas[1:] for k in reglages(c.defaut.nom, n) if k[0] != "CameraDebug"))
            rs = voir_editeur(_projet(cas[0].sain, travail / "sain"), SCENE, CAMERA_JEU, "far",
                              releves=a_lire, reduite=REDUITE, sortie=travail / "editeur")
            if not rs["ok"]:
                rejets.append(f"graine {g} : capture saine ({rs.get('erreur') or rs['donnees'].get('erreurs')})")
                continue
            sains = {(x["chemin"], x["propriete"]): x for x in rs["donnees"]["releves"]}
            image = _garder(rs, images / f"g{g:03d}_sain")
            paires.append(paire_camera(n, rs, image))
            if (p := paire_lancer(n, rs, image)) is not None:
                paires.append(p)
            retenus = 0
            for c in cas[1:]:
                regl = reglages(c.defaut.nom, n)
                rf = voir_editeur(_projet(c.fautif, travail / "fautif"), SCENE, regl[0][0], regl[0][1],
                                  releves=regl[1:], reduite=REDUITE, sortie=travail / "editeur")
                if not rf["ok"] or not montre_le_defaut(c, rf, sains):
                    rejets.append(f"graine {g}, {c.defaut.nom} : l'éditeur ne montre pas le défaut "
                                  f"({rf.get('erreur') or rf['donnees'].get('erreurs') or 'même valeur affichée'})")
                    continue
                image = _garder(rf, images / f"g{g:03d}_{c.defaut.nom}")
                paires += [paire_selection(c, rf, image), paire_debogage(c, rf, image, sains)]
                retenus += 1
            journal(f"graine {g} : {retenus + 1} captures retenues, {len(cas) - 1 - retenus} cas rejetés")
            if cible is not None and sum(p["jetons"] <= PLAFOND for p in paires) >= cible:
                break
    trop_longues = [p for p in paires if p["jetons"] > PLAFOND]
    retenues = [p for p in paires if p["jetons"] <= PLAFOND]
    fmt.ecrire(retenues, sortie / "paires.jsonl")
    bilan: dict[str, Any] = {
        "niveaux": faits, "graine": graine, "paires": len(retenues), "trop_longues": len(trop_longues),
        "rejets": rejets, "par_type": {t: sum(p["type"] == t for p in retenues) for t in fmt.TYPES},
        "par_question": {}, "jetons_max": max((p["jetons"] for p in paires), default=0),
        "jetons_moyens": round(sum(p["jetons"] for p in paires) / max(len(paires), 1))}
    for p in retenues:
        cle = p["preuve"].get("question") or p["preuve"].get("defaut")
        bilan["par_question"][cle] = bilan["par_question"].get(cle, 0) + 1
    (sortie / "bilan.json").write_text(json.dumps(bilan, indent=1, ensure_ascii=False), encoding="utf-8")
    return bilan
