"""Compétences en un appel : schéma de la réponse, contexte montré au modèle, application au projet.

Un essai en un appel = une seule réponse JSON, contrainte par le schéma de sa compétence. Un
traducteur déterministe l'applique à une copie de depart/, puis le juge de la tâche note le
projet obtenu, comme pour un candidat agentique. Les mêmes schémas et le même contexte servent
aux quatre configurations, à la référence frontière et, plus tard, aux essais de la session 5.

  D1  {"categorie", "fichier", "ligne"}          → res://reponse.json
  F1  {"speed", "dash_speed", "dash_duration",   → valeurs des @export de res://scripts/hero.gd
       "dash_cooldown"}
  K1  {"chemin", "script"}                       → le script écrit à son chemin
  S1  {"chemin", "spec"}                         → scene_write(spec) écrit le .tscn (spec validée)
  S2  {"editions": [...]}                        → apply_edits en mémoire (preparer_edits), fichiers écrits

Une réponse illisible ou refusée par le traducteur donne un verdict en échec à l'étape « reponse »,
sans lancer Godot.
"""

from __future__ import annotations

import json
import math
import re
import shutil
import tempfile
from pathlib import Path, PurePosixPath
from typing import Any

from usine.generateurs.gabarits import CATEGORIES_D1
from usine.generateurs.inverse import GRILLE, SCRIPT_HERO
from usine.juge.projet import IGNORES_COPIE
from usine.juge.verdict import erreur, nouveau_verdict
from usine.mesure.client import extraire_json

ETAPE_REPONSE = "reponse"
COMPETENCES_UN_APPEL = ("D1", "F1", "K1", "S1", "S2")
MAX_CAR_FICHIER = 12000
MAX_CAR_CONTEXTE = 40000


class ReponseInvalide(ValueError):
    pass


def _objet(proprietes: dict[str, Any]) -> dict[str, Any]:
    return {"type": "object", "properties": proprietes, "required": list(proprietes), "additionalProperties": False}


SCHEMAS: dict[str, dict[str, Any]] = {
    "D1": _objet({"categorie": {"type": "string", "enum": list(CATEGORIES_D1)},
                  "fichier": {"type": "string"}, "ligne": {"type": "integer"}}),
    "F1": _objet({nom: {"type": "number"} for nom in GRILLE}),
    "K1": _objet({"chemin": {"type": "string"}, "script": {"type": "string"}}),
    "S1": _objet({"chemin": {"type": "string"}, "spec": {"type": "object"}}),
    "S2": _objet({"editions": {"type": "array", "items": {
        "type": "object", "properties": {"op": {"type": "string"}}, "required": ["op"]}}}),
}

FORMATS: dict[str, str] = {
    "D1": ('Réponds par {"categorie": "...", "fichier": "res://...", "ligne": N} : la catégorie de '
           "l'erreur à l'origine du problème et la ligne du script du projet qui la provoque (pas celle "
           "d'un addon). Catégories : " + ", ".join(CATEGORIES_D1) + "."),
    "F1": ("Réponds par les quatre valeurs des @export du héros : "
           + ", ".join(f'"{nom}"' for nom in GRILLE) + " (nombres, en secondes pour les durées). "
           "Distance = vitesse × images / 60 ; durée = images / 60."),
    "K1": ('Réponds par {"chemin": "res://....gd", "script": "..."} : le script complet, avec chaque '
           "déclaration exacte de l'interface et des corps minimaux (pass, ou return d'une valeur du bon type)."),
    "S1": ('Réponds par {"chemin": "res://....tscn", "spec": {...}} : la spec JSON de la scène '
           '(racine {nom, type, script?, proprietes?, enfants?}, ressources_internes, ressources_externes ; '
           'valeurs typées {"Vector2": [x, y]}, {"Color": [r, g, b, a]}, {"ExtResource": "res://…"}, '
           '{"SubResource": "nom"}). Elle sera écrite en .tscn par l\'écrivain déterministe.'),
    "S2": ('Réponds par {"editions": [{"op": "connect", "source": "<id>", "signal": "...", "cible": "<id>", '
           '"methode": "..."}]} : les éditions à appliquer, avec les ids de nœuds de la description du projet.'),
}

SYSTEME = ("Tu es un développeur Godot 4.7 (GDScript typé). Tu reçois une tâche et les fichiers utiles du "
           "projet. Tu réponds en une seule fois, uniquement par un objet JSON, sans texte autour.")

_RES = re.compile(r"res://[A-Za-z0-9_./-]+")


def _chemin_sur(projet: Path, res: Any, extension: str | None = None) -> Path:
    if not isinstance(res, str) or not res.startswith("res://"):
        raise ReponseInvalide(f"chemin res:// attendu : {res!r}")
    rel = PurePosixPath(res[len("res://"):])
    if not rel.parts or rel.is_absolute() or ".." in rel.parts or rel.parts[0] in ("addons", ".godot"):
        raise ReponseInvalide(f"chemin hors du projet ou réservé : {res}")
    if extension and rel.suffix != extension:
        raise ReponseInvalide(f"extension {extension} attendue : {res}")
    return Path(projet, *rel.parts)


def _ecrire(chemin: Path, texte: str) -> None:
    chemin.parent.mkdir(parents=True, exist_ok=True)
    with chemin.open("w", encoding="utf-8", newline="") as f:
        f.write(texte)


def _lire(chemin: Path) -> str:
    with chemin.open(encoding="utf-8", newline="") as f:
        return f.read()


def contexte(depart: Path, consigne: str, competence: str) -> str:
    """Fichiers montrés au modèle : liste des fichiers du projet, puis le contenu des fichiers
    cités par la consigne (et par journal.txt pour D1), lignes numérotées pour les scripts.
    S2 reçoit aussi la description du projet (ids des nœuds)."""
    depart = Path(depart)
    fichiers = sorted((p.relative_to(depart).as_posix() for p in depart.rglob("*")
                       if p.is_file() and p.relative_to(depart).parts[0] not in ("addons", ".godot")
                       and not p.name.endswith((".uid", ".import"))), key=lambda s: s.split("/"))
    blocs = ["Fichiers du projet :\n" + "\n".join(f"res://{f}" for f in fichiers)]
    cites: list[str] = []
    textes = [consigne]
    journal = depart / "journal.txt"
    if competence == "D1" and journal.is_file():
        texte = _lire(journal)[:MAX_CAR_FICHIER]
        blocs.append(f"=== journal.txt ===\n{texte}")
        textes.append(texte)
    for t in textes:
        for res in _RES.findall(t):
            res = res.rstrip(".")
            if res not in cites:
                cites.append(res)
    for res in cites:
        chemin = Path(depart, *PurePosixPath(res[len("res://"):]).parts)
        if not chemin.is_file() or chemin.suffix not in (".gd", ".tscn", ".tres", ".json", ".cfg", ".godot"):
            continue
        texte = _lire(chemin)[:MAX_CAR_FICHIER]
        if chemin.suffix == ".gd":
            texte = "\n".join(f"{i:4d}| {ligne}" for i, ligne in enumerate(texte.split("\n"), 1))
        blocs.append(f"=== {res} ===\n{texte}")
    if competence == "S2":
        from usine.projet.decrire import describe_project
        blocs.append("Description du projet (ids des nœuds) :\n" + describe_project(depart)["texte"])
    total = "\n\n".join(blocs)
    return total if len(total) <= MAX_CAR_CONTEXTE else total[:MAX_CAR_CONTEXTE] + "\n[…contexte tronqué]"


def messages(depart: Path, consigne: str, competence: str, documentation: str | None = None) -> list[dict[str, str]]:
    """Même prompt pour toutes les configurations ; `documentation` = résultats du RAG (ou None)."""
    utilisateur = [f"Tâche ({competence}) :\n{consigne}", contexte(depart, consigne, competence)]
    if documentation:
        utilisateur.append("Documentation Godot 4.7 (extraits trouvés pour cette tâche) :\n" + documentation)
    utilisateur.append(FORMATS[competence])
    return [{"role": "system", "content": SYSTEME}, {"role": "user", "content": "\n\n".join(utilisateur)}]


def _nombre(v: Any, nom: str) -> float:
    if isinstance(v, bool) or not isinstance(v, (int, float)) or not math.isfinite(v):
        raise ReponseInvalide(f"{nom} : nombre attendu ({v!r})")
    return float(v)


def appliquer(competence: str, reponse: Any, projet: Path) -> list[str]:
    """Applique la réponse au projet (copie de travail). Renvoie les fichiers écrits (res://)."""
    projet = Path(projet)
    if not isinstance(reponse, dict):
        raise ReponseInvalide("objet JSON attendu")
    if competence == "D1":
        cat, fichier, ligne = reponse.get("categorie"), reponse.get("fichier"), reponse.get("ligne")
        if not isinstance(cat, str) or not isinstance(fichier, str) or isinstance(ligne, bool) or not isinstance(ligne, int):
            raise ReponseInvalide("D1 : categorie (texte), fichier (texte) et ligne (entier) attendus")
        _ecrire(projet / "reponse.json",
                json.dumps({"categorie": cat, "fichier": fichier, "ligne": ligne}, ensure_ascii=False) + "\n")
        return ["res://reponse.json"]
    if competence == "F1":
        chemin = projet / SCRIPT_HERO
        texte = _lire(chemin)
        for nom in GRILLE:
            v = _nombre(reponse.get(nom), nom)
            motif = re.compile(rf"^(@export var {nom}: float = )-?[0-9.e+-]+$", re.M)
            if len(motif.findall(texte)) != 1:
                raise ReponseInvalide(f"déclaration de {nom} introuvable ou multiple dans res://{SCRIPT_HERO}")
            texte = motif.sub(lambda m: m.group(1) + repr(v), texte)
        _ecrire(chemin, texte)
        return [f"res://{SCRIPT_HERO}"]
    if competence == "K1":
        chemin = _chemin_sur(projet, reponse.get("chemin"), ".gd")
        script = reponse.get("script")
        if not isinstance(script, str) or not script.strip():
            raise ReponseInvalide("K1 : script vide")
        _ecrire(chemin, script if script.endswith("\n") else script + "\n")
        return [reponse["chemin"]]
    if competence == "S1":
        from usine.scene.preuve import verificateur
        from usine.scene.spec import ErreurSpec, scene_write, valider_spec
        chemin = _chemin_sur(projet, reponse.get("chemin"), ".tscn")
        spec = reponse.get("spec")
        if not isinstance(spec, dict):
            raise ReponseInvalide("S1 : spec (objet) attendue")
        verif = verificateur(projet)
        refus = valider_spec(spec, verif)
        if refus:
            raise ReponseInvalide("spec refusée : " + "; ".join(str(e.get("message", e)) for e in refus[:3]))
        try:
            texte = scene_write(spec, verif)
        except (ErreurSpec, KeyError, TypeError, ValueError, AttributeError) as exc:
            raise ReponseInvalide(f"spec refusée : {exc}") from exc
        _ecrire(chemin, texte)
        return [reponse["chemin"]]
    if competence == "S2":
        from usine.projet.editions import preparer_edits
        from usine.projet.index import res_vers_disque
        editions = reponse.get("editions")
        if not isinstance(editions, list) or not editions:
            raise ReponseInvalide("S2 : liste d'éditions non vide attendue")
        espace, refus = preparer_edits(projet, editions)
        if refus:
            raise ReponseInvalide("éditions refusées : " + "; ".join(str(e.get("message")) for e in refus[:3]))
        ecrits = []
        for res, texte in sorted(espace.fichiers.items()):
            if texte != espace.originaux.get(res):
                _ecrire(res_vers_disque(projet, res), texte)
                ecrits.append(res)
        return ecrits
    raise ReponseInvalide(f"compétence sans traducteur en un appel : {competence}")


def verdict_reponse_invalide(message: str, tache_id: str) -> dict[str, Any]:
    v = nouveau_verdict(ETAPE_REPONSE)
    v["erreurs"].append(erreur(message, categorie="autre"))
    v["tache_id"] = tache_id
    return v


def juger_reponse(dossier: Path, texte: str) -> dict[str, Any]:
    """Applique la réponse brute du modèle à une copie de depart/ et juge le projet obtenu."""
    from usine.taches import juger_tache, lire_tache
    dossier = Path(dossier)
    tache = lire_tache(dossier)
    try:
        reponse = extraire_json(texte)
    except ValueError as exc:
        return verdict_reponse_invalide(str(exc), tache["id"])
    with tempfile.TemporaryDirectory(prefix="usine_mesure_") as tmp:
        copie = Path(tmp) / "candidat"
        shutil.copytree(dossier / "depart", copie, ignore=IGNORES_COPIE)
        try:
            appliquer(tache["competence"], reponse, copie)
        except ReponseInvalide as exc:
            return verdict_reponse_invalide(str(exc), tache["id"])
        except Exception as exc:  # noqa: BLE001 — une réponse du modèle ne doit jamais arrêter un tour
            return verdict_reponse_invalide(f"réponse inapplicable ({type(exc).__name__} : {exc})", tache["id"])
        return juger_tache(dossier, candidat=copie)
