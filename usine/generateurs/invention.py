"""Invention : l'entrée par laquelle Qwen proposera des tâches (aucun appel LLM ici).

Une proposition est un JSON :

    {
      "format": "usine.invention/1",
      "competence": "K3",                       # une des 13 compétences
      "consigne": "…",                          # texte donné à l'agent
      "base": "reference",                      # projet source connu de l'usine (godot/<base>)
      "depart":    {"remplacements": [{"fichier": "scripts/x.gd", "avant": "…", "apres": "…"}],
                    "ajouts": {"chemin/relatif": "contenu"}, "suppressions": ["chemin"]},
      "reference": {"ajouts": {"chemin/relatif": "contenu"}},   # superposée au départ
      "tests_caches": {"test_xxx.gd": "extends GdUnitTestSuite …"},
      "juge": {"etapes": [...], "patch_max_lignes": N}          # facultatif
    }

Validation déterministe : schéma, chemins sûrs (relatifs, sans « .. »), remplacements trouvés
exactement une fois, tests cachés hors de l'espace de l'agent (jamais dans depart/), suites
GdUnit4, et vocabulaire réel (règle 6) : chaque `extends X` et chaque `type="X"` de scène doit
exister dans extension_api.json ou être un class_name du projet. Puis exclusion des jeux gelés.
Une proposition valide devient une tâche candidate, que le portillon juge comme les autres.
"""

from __future__ import annotations

import re
from pathlib import Path, PurePosixPath
from typing import Any

from usine import config as cfg
from usine.generateurs.commun import ecrire_tache, ident, lire_projet

FORMAT = "usine.invention/1"
COMPETENCES = ("C1", "C2", "S1", "S2", "S3", "K1", "K2", "K3", "K4", "D1", "D2", "F1", "F2")
EXTENSIONS = {".gd", ".tscn", ".tres", ".json", ".txt", ".cfg", ".md"}
ETAPES_VALIDES = {"import", "check_script", "load_scene", "run_tests"}
_EXTENDS = re.compile(r"^extends\s+([A-Za-z_]\w*)\s*$", re.M)
_CLASS_NAME = re.compile(r"^class_name\s+([A-Za-z_]\w*)", re.M)
_TYPE_SCENE = re.compile(r'^\[node [^\]]*\btype="([A-Za-z_]\w*)"', re.M)


class ErreurInvention(ValueError):
    def __init__(self, erreurs: list[str]):
        super().__init__("; ".join(erreurs))
        self.erreurs = erreurs


def _chemin_sur(chemin: Any) -> bool:
    if not isinstance(chemin, str) or not chemin or "\\" in chemin or ":" in chemin:
        return False
    p = PurePosixPath(chemin)
    return not p.is_absolute() and ".." not in p.parts and p.suffix in EXTENSIONS


def _dict_textes(objet: Any, lieu: str, erreurs: list[str]) -> dict[str, str]:
    if objet is None:
        return {}
    if not isinstance(objet, dict) or not all(isinstance(v, str) for v in objet.values()):
        erreurs.append(f"{lieu} : dictionnaire {{chemin: texte}} attendu")
        return {}
    for chemin in objet:
        if not _chemin_sur(chemin):
            erreurs.append(f"{lieu} : chemin refusé {chemin!r} (relatif, sans « .. », extension connue)")
    return objet


def construire(proposition: dict[str, Any], sources: dict[str, Path] | None = None,
               vocab=None) -> tuple[dict[str, Any], dict[str, str], dict[str, str], dict[str, str]]:
    """Valide la proposition ; renvoie (tâche, depart, reference, tests_caches) ou lève ErreurInvention."""
    sources = sources or {"reference": cfg.RACINE / "godot" / "reference"}
    erreurs: list[str] = []
    if not isinstance(proposition, dict):
        raise ErreurInvention(["la proposition doit être un objet JSON"])
    if proposition.get("format") != FORMAT:
        erreurs.append(f"format attendu : {FORMAT}")
    comp = proposition.get("competence")
    if comp not in COMPETENCES:
        erreurs.append(f"compétence inconnue : {comp!r}")
    consigne = proposition.get("consigne")
    if not isinstance(consigne, str) or len(consigne.strip()) < 20:
        erreurs.append("consigne absente ou trop courte (20 caractères au moins)")
    base = proposition.get("base")
    if base not in sources:
        raise ErreurInvention(erreurs + [f"base inconnue : {base!r} (connues : {', '.join(sorted(sources))})"])
    projet = lire_projet(sources[base])
    depart = dict(projet)

    d = proposition.get("depart") or {}
    for k, r in enumerate(d.get("remplacements") or []):
        f, avant, apres = r.get("fichier"), r.get("avant"), r.get("apres")
        if f not in depart or not isinstance(avant, str) or not isinstance(apres, str) or not avant:
            erreurs.append(f"depart.remplacements[{k}] : fichier inconnu ou texte manquant")
            continue
        n = depart[f].count(avant)
        if n != 1:
            erreurs.append(f"depart.remplacements[{k}] : « avant » trouvé {n} fois dans {f} (1 attendu)")
            continue
        depart[f] = depart[f].replace(avant, apres)
    for chemin in d.get("suppressions") or []:
        if chemin not in depart:
            erreurs.append(f"depart.suppressions : {chemin!r} absent de la base")
        depart.pop(chemin, None)
    depart.update(_dict_textes(d.get("ajouts"), "depart.ajouts", erreurs))
    reference = _dict_textes((proposition.get("reference") or {}).get("ajouts"), "reference.ajouts", erreurs)
    tests = _dict_textes(proposition.get("tests_caches"), "tests_caches", erreurs)

    if not reference:
        erreurs.append("reference.ajouts est vide : la solution doit changer au moins un fichier")
    if not tests or not any(PurePosixPath(c).name.startswith("test_") and c.endswith(".gd") for c in tests):
        erreurs.append("tests_caches doit contenir au moins une suite test_*.gd")
    for chemin, texte in tests.items():
        if chemin.endswith(".gd") and "extends GdUnitTestSuite" not in texte:
            erreurs.append(f"tests_caches/{chemin} : une suite GdUnit4 doit hériter de GdUnitTestSuite")
    for chemin in list(d.get("ajouts") or {}) + list(reference):
        if PurePosixPath(chemin).parts[0] == "tests_juge":
            erreurs.append(f"{chemin} : res://tests_juge/ est réservé aux tests cachés (règle 3)")
    juge = proposition.get("juge")
    if juge is not None:
        if not isinstance(juge, dict) or not set(juge) <= {"etapes", "patch_max_lignes"} \
                or not set(juge.get("etapes", [])) <= ETAPES_VALIDES:
            erreurs.append("juge : seuls etapes (import/check_script/load_scene/run_tests) et patch_max_lignes")

    # Règle 6 : vocabulaire réel.
    if vocab is None:
        from usine.vocab import ouvrir
        vocab = ouvrir()
    classes_projet = set()
    for texte in list(depart.values()) + list(reference.values()):
        classes_projet |= set(_CLASS_NAME.findall(texte))
    # Seuls les fichiers que la proposition écrit sont vérifiés : la base est déjà validée.
    proposes = {c: depart[c] for c in depart if depart[c] != projet.get(c)}
    for chemin, texte in sorted({**proposes, **reference, **tests}.items()):
        noms = _EXTENDS.findall(texte) if chemin.endswith(".gd") else _TYPE_SCENE.findall(texte) \
            if chemin.endswith(".tscn") else []
        for nom in noms:
            if nom not in classes_projet and nom != "GdUnitTestSuite" and not vocab.classe_existe(nom):
                erreurs.append(f"{chemin} : classe inconnue de Godot 4.7 et du projet : {nom}")
    if erreurs:
        raise ErreurInvention(erreurs)

    tache = {"id": ident(comp, "inv", base, proposition.get("nom", "")), "competence": comp, "consigne": consigne,
             "origine": "invention", "consigne_a_ecrire": None,
             "generateur": {"nom": "invention", "source": base, "format": FORMAT}}
    if juge:
        tache["juge"] = juge
    return tache, depart, reference, tests


def materialiser(proposition: dict[str, Any], sortie: Path, exclusion=None,
                 sources: dict[str, Path] | None = None, vocab=None) -> Path:
    """Écrit la tâche candidate ; refuse un doublon des jeux gelés (exclusion)."""
    import hashlib
    import json
    tache, depart, reference, tests = construire(proposition, sources, vocab)
    # Id stable dérivé du contenu de la proposition.
    h = hashlib.sha256(json.dumps(proposition, sort_keys=True, ensure_ascii=False).encode("utf-8")).hexdigest()[:10]
    tache["id"] = f"{tache['id']}_{h}"
    dossier = ecrire_tache(sortie, tache, depart, reference, tests)
    if exclusion:
        doublon = exclusion.tache_exclue(dossier)
        if doublon:
            import shutil
            shutil.rmtree(dossier)
            raise ErreurInvention([f"{doublon[0]} : la proposition double la tâche gelée {doublon[1]}"])
    return dossier
