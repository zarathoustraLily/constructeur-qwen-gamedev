"""Parties observées : jouer des séquences scriptées (gd/jouer_partie.gd), juger leurs règles, les résumer.

Le script Godot ne juge rien : il rend, image par image, des mesures brutes (position, appui, vitesse,
hauteur au-dessus de la surface, pénétration dans les obstacles de référence, enfouissement du bas
visible du corps, caméra). Les règles sont évaluées ici, en Python, sans Godot (testables par pytest) :

  gravite        en l'air depuis 3 images au moins, la vitesse verticale baisse d'au moins `gravite_min` m/s²
  hauteur        l'acteur reste à moins de `hauteur_max` m au-dessus de la surface (sol de référence ou mer)
  sous_le_sol    l'acteur ne passe jamais à plus de `sous_le_sol_max` m sous le sol de référence
  traversee      sa forme de collision n'entre pas de plus de `penetration_max` m dans un obstacle de référence
  enfouissement  le bas visible de la carrosserie ou des roues ne passe pas plus bas que `enfouissement_max`
                 sous le sol de référence (contrôle sur la terre ferme seulement)
  camera         après `camera_debut` images : l'acteur reste dans le champ, la caméra au-dessus du sol
  camera_derriere  après `camera_alignement_debut` images, au-delà de `camera_alignement_vitesse` m/s :
                 la caméra regarde dans le sens de la marche (cosinus ≥ `camera_alignement_min`)

« Référence » : le monde de vérité est écrit à partir du jeu de référence (formes de collision des sols
et des obstacles), puis posé en fantôme sur des calques que le jeu n'utilise pas. Un obstacle dont le
candidat a retiré la collision reste donc visible pour le juge.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any, Iterable

from usine import config as cfg
from usine.processus import executer

RACINE = Path(__file__).resolve().parent
SCRIPT = RACINE / "gd" / "jouer_partie.gd"
JEUX = RACINE / "jeux"
MARQUEUR = "@@USINE_OBSERVATION@@"
FIN = "@@USINE_OBSERVATION_FIN@@"
REGLES = ("gravite", "hauteur", "sous_le_sol", "traversee", "enfouissement", "camera", "camera_derriere")
NOMS = {"gravite": "gravité", "hauteur": "hauteur", "sous_le_sol": "sous le sol", "traversee": "traversée",
        "enfouissement": "enfouissement", "camera": "caméra", "camera_derriere": "caméra derrière"}
IMAGES_PAR_SECONDE = 60


class ErreurObservation(RuntimeError):
    pass


def config_jeu(nom: str) -> Path:
    chemin = JEUX / f"{nom}.json"
    if not chemin.is_file():
        raise ErreurObservation(f"jeu inconnu pour l'observation : {nom} (attendu : {chemin})")
    return chemin


def lire_config(chemin: Path) -> dict[str, Any]:
    return json.loads(Path(chemin).read_text(encoding="utf-8"))


_VERSION: str | None = None


def version_observation() -> str:
    """Empreinte du code qui observe (ce paquet) et du juge commun : entre dans la clé du cache."""
    global _VERSION
    if _VERSION is None:
        from usine.juge.cache import version_juge
        h = hashlib.sha256(version_juge().encode("ascii"))
        for f in sorted((f for f in RACINE.rglob("*") if f.suffix in (".py", ".gd") and f.is_file()),
                        key=lambda f: f.relative_to(RACINE).parts):
            h.update(f"{f.relative_to(RACINE).as_posix()}\n".encode("utf-8"))
            h.update(f.read_bytes().replace(b"\r\n", b"\n"))
        _VERSION = h.hexdigest()[:16]
    return _VERSION


def _godot(projet: Path, arguments: list[str], delai_s: float | None) -> str:
    res = executer([cfg.chemin_godot(), "--headless", "--fixed-fps", "60", "--path", projet, "-s", SCRIPT,
                    "--", *arguments], delai_s=delai_s if delai_s is not None else cfg.delai_juge())
    if FIN not in res.sortie:
        fin = "\n".join(res.sortie.splitlines()[-15:])
        raise ErreurObservation(f"la partie n'est pas allée au bout (code {res.code}"
                                f"{', délai dépassé' if res.expire else ''}) :\n{fin}")
    return res.sortie


def lancer(projet: Path, config: Path, sequences: Iterable[str], monde: Path | None = None,
           delai_s: float | None = None) -> dict[str, dict[str, Any]]:
    """Joue `sequences` sur `projet` (copie importée), chacune sur une partie neuve. Renvoie {séquence: trace}."""
    sequences = list(sequences)
    args = [f"config={Path(config).resolve()}", f"sequences={','.join(sequences)}"]
    if monde is not None:
        args.append(f"monde={Path(monde).resolve()}")
    traces: dict[str, dict[str, Any]] = {}
    for ligne in _godot(Path(projet), args, delai_s).splitlines():
        if ligne.startswith(MARQUEUR):
            t = json.loads(ligne[len(MARQUEUR):])
            if "erreur" in t:
                raise ErreurObservation(f"{t.get('sequence')} : {t['erreur']}")
            traces[t["sequence"]] = t
    manquantes = [s for s in sequences if s not in traces]
    if manquantes:
        raise ErreurObservation(f"séquences sans trace : {manquantes}")
    return traces


def ecrire_monde(projet: Path, config: Path, sortie: Path, delai_s: float | None = None) -> dict[str, Any]:
    """Écrit le monde de vérité du projet ouvert (le jeu de référence) dans `sortie` (.tscn)."""
    sortie = Path(sortie).resolve()
    sortie.parent.mkdir(parents=True, exist_ok=True)
    texte = _godot(Path(projet), [f"config={Path(config).resolve()}", "mode=monde", f"sortie={sortie}"], delai_s)
    for ligne in texte.splitlines():
        if ligne.startswith(MARQUEUR):
            info = json.loads(ligne[len(MARQUEUR):])
            if info.get("code") != 0 or not sortie.is_file():
                raise ErreurObservation(f"monde de vérité non écrit : {info}")
            return info
    raise ErreurObservation("monde de vérité : aucune réponse du script")


# --- Règles ------------------------------------------------------------------------------------------

def _m(v: float) -> str:
    return f"{v:.2f}".replace(".", ",")


def evaluer(trace: dict[str, Any], regles: dict[str, Any]) -> dict[str, dict[str, Any]]:
    """Règles cassées d'une trace : {règle: {fautes, premiere, pire: {image, valeur, message}}}."""
    res: dict[str, dict[str, Any]] = {r: {"fautes": 0, "premiere": None, "pire": None} for r in REGLES}

    def faute(regle: str, image: int, valeur: float, message: str) -> None:
        r = res[regle]
        r["fautes"] += 1
        if r["premiere"] is None:
            r["premiere"] = image
        if r["pire"] is None or valeur > r["pire"]["valeur"]:
            r["pire"] = {"image": image, "valeur": round(valeur, 3), "message": message}

    g_min = float(regles["gravite_min"])
    enf_max = regles["enfouissement_max"]
    en_l_air = 0
    vy_avant: float | None = None
    for e in trace["enregistrements"]:
        i = int(e["i"])
        en_l_air = en_l_air + 1 if e["appui"] == "air" else 0
        if en_l_air >= 3 and vy_avant is not None:
            baisse = (vy_avant - e["vy"]) * IMAGES_PAR_SECONDE
            if baisse < g_min:
                faute("gravite", i, g_min - baisse, f"en l'air depuis {en_l_air} images, la vitesse verticale baisse de "
                                                    f"{_m(baisse)} m/s² (au moins {_m(g_min)} attendus)")
        vy_avant = e["vy"]
        if e["haut"] > regles["hauteur_max"]:
            faute("hauteur", i, e["haut"] - regles["hauteur_max"], f"le kart est à {_m(e['haut'])} m au-dessus de la surface")
        if e.get("sous") is not None and e["sous"] > regles["sous_le_sol_max"]:
            faute("sous_le_sol", i, e["sous"], f"le kart est {_m(e['sous'])} m sous le sol ({e.get('sous_obj')})")
        if e["pen"] > regles["penetration_max"]:
            faute("traversee", i, e["pen"], f"le kart entre de {_m(e['pen'])} m dans {e.get('pen_obj')}")
        for partie_du_corps, seuil in enf_max.items():
            v = e.get("enf_" + partie_du_corps)
            if v is not None and v > seuil:
                faute("enfouissement", i, v, f"{e.get('enf_' + partie_du_corps + '_obj')} ({partie_du_corps}) est "
                                             f"{_m(v)} m sous le sol")
        if i > regles["camera_debut"]:
            if e.get("cam_champ") is False:
                faute("camera", i, 1.0, "le kart sort du champ de la caméra")
            if e.get("cam_sous") is not None and e["cam_sous"] > 0.0:
                faute("camera", i, e["cam_sous"], f"la caméra est {_m(e['cam_sous'])} m sous le sol")
        if (i > regles["camera_alignement_debut"] and e.get("cam_al") is not None
                and e["vh"] > regles["camera_alignement_vitesse"] and e["cam_al"] < regles["camera_alignement_min"]):
            faute("camera_derriere", i, regles["camera_alignement_min"] - e["cam_al"],
                  f"la caméra regarde à contresens de la marche (cosinus {_m(e['cam_al'])})")
    return res


def marges(trace: dict[str, Any]) -> dict[str, Any]:
    """Valeurs extrêmes observées, fautives ou non : montrent que chaque règle mesure quelque chose."""
    enr = trace["enregistrements"]
    en_l_air, air_max = 0, 0
    for e in enr:
        en_l_air = en_l_air + 1 if e["appui"] == "air" else 0
        air_max = max(air_max, en_l_air)

    def extreme(cle: str, fonction=max) -> float | None:
        valeurs = [e[cle] for e in enr if e.get(cle) is not None]
        return fonction(valeurs) if valeurs else None

    return {"images_en_l_air_max": air_max, "hauteur_max": extreme("haut"), "penetration_max": extreme("pen"),
            "enfouissement_carrosserie_max": extreme("enf_carrosserie"), "enfouissement_roues_max": extreme("enf_roues"),
            "sous_le_sol_max": extreme("sous"), "camera_alignement_min": extreme("cam_al", min),
            "images_sur_terre": sum(1 for e in enr if e.get("sol") is not None and e["sol"] > 0.05)}


def cassees(evaluation: dict[str, dict[str, Any]]) -> list[str]:
    return [r for r in REGLES if evaluation[r]["fautes"]]


def ligne_faute(regle: str, r: dict[str, Any]) -> str:
    return (f"{NOMS[regle]} : {r['fautes']} images, dès l'image {r['premiere']} ; "
            f"pire à l'image {r['pire']['image']} : {r['pire']['message']}")


def resume(nom: str, trace: dict[str, Any], evaluation: dict[str, dict[str, Any]], config: dict[str, Any],
           pas_parcours: int = 30) -> str:
    """Ce qu'on voit d'une partie, en texte : règles cassées, puis le parcours de l'acteur."""
    seq = config["sequences"][nom]
    lignes = [f"Séquence « {nom} » ({trace['images']} images à 60 par seconde) : {seq.get('description', '')}"]
    fautives = cassees(evaluation)
    if fautives:
        lignes.append("Règles cassées :")
        lignes += [f"- {ligne_faute(r, evaluation[r])}" for r in fautives]
    else:
        lignes.append("Aucune règle cassée.")
    points = [e for e in trace["enregistrements"] if e["i"] % pas_parcours == 0]
    lignes.append(f"Parcours (image : position x, y, z ; appui ; vitesse), toutes les {pas_parcours} images :")
    lignes.append(" · ".join(f"{e['i']} : ({_m(e['p'][0])} ; {_m(e['p'][1])} ; {_m(e['p'][2])}) {e['appui']} "
                             f"{_m(e['v'])} m/s" for e in points))
    return "\n".join(lignes)
