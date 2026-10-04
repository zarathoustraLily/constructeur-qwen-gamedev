"""extension_api.json → SQLite.

Le vocabulaire est la seule source de vérité sur les noms Godot (règle 6) :
classes, héritage, méthodes avec arguments, signaux avec arguments, propriétés,
énumérations et constantes. Les types intégrés (Vector2…) et la portée globale
(`@GlobalScope` : énumérations, constantes, fonctions utilitaires, singletons) y sont aussi.
"""

from __future__ import annotations

import json
import shutil
import sqlite3
import tempfile
from pathlib import Path
from typing import Any

from usine import config as cfg
from usine.processus import executer

PORTEE_GLOBALE = "@GlobalScope"

SCHEMA = """
CREATE TABLE meta (cle TEXT PRIMARY KEY, valeur TEXT);
CREATE TABLE classes (
    nom TEXT PRIMARY KEY, parent TEXT, genre TEXT NOT NULL,
    api_type TEXT, instanciable INTEGER, refcounted INTEGER);
CREATE TABLE methodes (
    classe TEXT, nom TEXT, retour TEXT, statique INTEGER, virtuelle INTEGER,
    constante INTEGER, vararg INTEGER, nb_args INTEGER, nb_args_obligatoires INTEGER,
    PRIMARY KEY (classe, nom));
CREATE TABLE arguments (
    classe TEXT, methode TEXT, position INTEGER, nom TEXT, type TEXT, defaut TEXT,
    PRIMARY KEY (classe, methode, position));
CREATE TABLE signaux (classe TEXT, nom TEXT, nb_args INTEGER, PRIMARY KEY (classe, nom));
CREATE TABLE signal_arguments (
    classe TEXT, signal TEXT, position INTEGER, nom TEXT, type TEXT,
    PRIMARY KEY (classe, signal, position));
CREATE TABLE proprietes (
    classe TEXT, nom TEXT, type TEXT, setter TEXT, getter TEXT, PRIMARY KEY (classe, nom));
CREATE TABLE enums (classe TEXT, nom TEXT, bitfield INTEGER, PRIMARY KEY (classe, nom));
CREATE TABLE enum_valeurs (
    classe TEXT, enum TEXT, nom TEXT, valeur INTEGER, PRIMARY KEY (classe, enum, nom));
CREATE TABLE constantes (classe TEXT, nom TEXT, type TEXT, valeur TEXT, PRIMARY KEY (classe, nom));
CREATE INDEX idx_enum_valeurs_nom ON enum_valeurs (classe, nom);
"""


def dossier_vocab(config: dict[str, Any] | None = None) -> Path:
    return cfg.dossier_donnees(config) / "vocab"


def chemin_base(config: dict[str, Any] | None = None) -> Path:
    return dossier_vocab(config) / f"godot_{cfg.version_godot(config)}.sqlite"


def chemin_json(config: dict[str, Any] | None = None) -> Path:
    return dossier_vocab(config) / f"extension_api_{cfg.version_godot(config)}.json"


def extraire_api(destination: Path, godot: Path | None = None) -> Path:
    """Lance `godot --headless --dump-extension-api` et copie le JSON produit."""
    godot = godot or cfg.chemin_godot()
    with tempfile.TemporaryDirectory(prefix="usine_vocab_") as tmp:
        res = executer([godot, "--headless", "--dump-extension-api"], cwd=Path(tmp), delai_s=120)
        produit = Path(tmp) / "extension_api.json"
        if res.code != 0 or not produit.is_file():
            raise RuntimeError(f"échec de --dump-extension-api (code {res.code}) :\n{res.sortie[-2000:]}")
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(produit, destination)
    return destination


def _args(liste: list[dict] | None) -> list[dict]:
    return list(liste or [])


def _inserer_methode(db: sqlite3.Connection, classe: str, m: dict, retour: str | None) -> None:
    args = _args(m.get("arguments"))
    obligatoires = sum(1 for a in args if "default_value" not in a)
    db.execute(
        "INSERT OR REPLACE INTO methodes VALUES (?,?,?,?,?,?,?,?,?)",
        (
            classe, m["name"], retour,
            int(m.get("is_static", False)), int(m.get("is_virtual", False)),
            int(m.get("is_const", False)), int(m.get("is_vararg", False)),
            len(args), obligatoires,
        ),
    )
    for i, a in enumerate(args):
        db.execute(
            "INSERT OR REPLACE INTO arguments VALUES (?,?,?,?,?,?)",
            (classe, m["name"], i, a["name"], a.get("type"), a.get("default_value")),
        )


def _inserer_enums(db: sqlite3.Connection, classe: str, enums: list[dict] | None) -> None:
    for e in enums or []:
        db.execute("INSERT OR REPLACE INTO enums VALUES (?,?,?)", (classe, e["name"], int(e.get("is_bitfield", False))))
        for v in e.get("values", []):
            db.execute("INSERT OR REPLACE INTO enum_valeurs VALUES (?,?,?,?)", (classe, e["name"], v["name"], v["value"]))


def charger(api: dict[str, Any], base: Path) -> Path:
    """Écrit la base SQLite à partir du contenu d'extension_api.json (remplacement atomique)."""
    base.parent.mkdir(parents=True, exist_ok=True)
    tmp = base.with_suffix(".tmp")
    tmp.unlink(missing_ok=True)
    db = sqlite3.connect(tmp)
    try:
        db.executescript(SCHEMA)
        entete = api.get("header", {})
        for cle in ("version_major", "version_minor", "version_patch", "version_status", "version_full_name"):
            db.execute("INSERT INTO meta VALUES (?,?)", (cle, str(entete.get(cle, ""))))
        version = ".".join(str(entete.get(k, "?")) for k in ("version_major", "version_minor", "version_patch"))
        db.execute("INSERT INTO meta VALUES ('version', ?)", (version,))

        for c in api.get("classes", []):
            db.execute(
                "INSERT INTO classes VALUES (?,?,?,?,?,?)",
                (c["name"], c.get("inherits"), "classe", c.get("api_type"),
                 int(c.get("is_instantiable", False)), int(c.get("is_refcounted", False))),
            )
            for m in c.get("methods", []):
                _inserer_methode(db, c["name"], m, (m.get("return_value") or {}).get("type"))
            for s in c.get("signals", []):
                args = _args(s.get("arguments"))
                db.execute("INSERT OR REPLACE INTO signaux VALUES (?,?,?)", (c["name"], s["name"], len(args)))
                for i, a in enumerate(args):
                    db.execute("INSERT OR REPLACE INTO signal_arguments VALUES (?,?,?,?,?)",
                               (c["name"], s["name"], i, a["name"], a.get("type")))
            for p in c.get("properties", []):
                db.execute("INSERT OR REPLACE INTO proprietes VALUES (?,?,?,?,?)",
                           (c["name"], p["name"], p.get("type"), p.get("setter"), p.get("getter")))
            for k in c.get("constants", []):
                db.execute("INSERT OR REPLACE INTO constantes VALUES (?,?,?,?)",
                           (c["name"], k["name"], "int", str(k.get("value"))))
            _inserer_enums(db, c["name"], c.get("enums"))

        for b in api.get("builtin_classes", []):
            db.execute("INSERT OR REPLACE INTO classes VALUES (?,?,?,?,?,?)", (b["name"], None, "builtin", "core", 1, 0))
            for m in b.get("methods", []):
                _inserer_methode(db, b["name"], m, m.get("return_type"))
            for p in b.get("members", []):
                db.execute("INSERT OR REPLACE INTO proprietes VALUES (?,?,?,?,?)", (b["name"], p["name"], p.get("type"), None, None))
            for k in b.get("constants", []):
                db.execute("INSERT OR REPLACE INTO constantes VALUES (?,?,?,?)", (b["name"], k["name"], k.get("type"), str(k.get("value"))))
            _inserer_enums(db, b["name"], b.get("enums"))

        db.execute("INSERT INTO classes VALUES (?,?,?,?,?,?)", (PORTEE_GLOBALE, None, "global", "core", 0, 0))
        _inserer_enums(db, PORTEE_GLOBALE, api.get("global_enums"))
        for k in api.get("global_constants", []):
            db.execute("INSERT OR REPLACE INTO constantes VALUES (?,?,?,?)", (PORTEE_GLOBALE, k["name"], "int", str(k.get("value"))))
        for f in api.get("utility_functions", []):
            _inserer_methode(db, PORTEE_GLOBALE, f, f.get("return_type"))
        for s in api.get("singletons", []):
            db.execute("INSERT OR REPLACE INTO proprietes VALUES (?,?,?,?,?)", (PORTEE_GLOBALE, s["name"], s.get("type"), None, None))
        db.commit()
    finally:
        db.close()
    tmp.replace(base)
    return base


def construire(json_api: Path | None = None, config: dict[str, Any] | None = None) -> Path:
    """Construit la base du vocabulaire ; extrait l'API depuis Godot si aucun JSON n'est fourni."""
    config = cfg.charger_config() if config is None else config
    if json_api is None:
        json_api = chemin_json(config)
        if not json_api.is_file():
            extraire_api(json_api, cfg.chemin_godot(config))
    with Path(json_api).open(encoding="utf-8") as f:
        api = json.load(f)
    return charger(api, chemin_base(config))
