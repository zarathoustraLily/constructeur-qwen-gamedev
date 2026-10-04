"""Vecteurs sqlite-vec, en option et désactivés par défaut.

Le calcul se fait plus tard sur la machine, par l'API `/v1/embeddings` du llama-server local
(aucun appel externe, règle 9). Tant que la table `vecteurs` n'existe pas, `search_docs` reste
en plein texte seul. sqlite-vec n'est pas dans requirements.txt : l'installer seulement si l'on
active cette option (`pip install sqlite-vec`, wheel à ajouter au wheelhouse).

    python -m usine.rag vecteurs [--url http://127.0.0.1:8080/v1] [--lot 32]
"""

from __future__ import annotations

import json
import sqlite3
import struct
import urllib.request
from pathlib import Path
from typing import Callable, Sequence

Plongeur = Callable[[list[str]], list[list[float]]]


def disponible() -> bool:
    try:
        import sqlite_vec  # noqa: F401
    except ImportError:
        return False
    return True


def _charger(con: sqlite3.Connection) -> None:
    import sqlite_vec
    con.enable_load_extension(True)
    sqlite_vec.load(con)
    con.enable_load_extension(False)


def _blob(v: Sequence[float]) -> bytes:
    return struct.pack(f"{len(v)}f", *v)


def plongeur_llama(url: str, modele: str = "qwen", delai_s: float = 120) -> Plongeur:
    """Plongements par le llama-server local (`--embeddings` requis au lancement)."""
    def plonger(textes: list[str]) -> list[list[float]]:
        corps = json.dumps({"model": modele, "input": textes}).encode("utf-8")
        req = urllib.request.Request(url.rstrip("/") + "/embeddings", data=corps,
                                     headers={"Content-Type": "application/json"})
        with urllib.request.urlopen(req, timeout=delai_s) as r:
            donnees = json.loads(r.read())["data"]
        return [d["embedding"] for d in sorted(donnees, key=lambda d: d["index"])]
    return plonger


def calculer(base: Path, plonger: Plongeur, lot: int = 32) -> int:
    """Ajoute la table `vecteurs` (vec0) à l'index ; renvoie le nombre de fragments plongés."""
    con = sqlite3.connect(base)
    try:
        _charger(con)
        lignes = con.execute("SELECT id, titre, texte FROM fragments ORDER BY id").fetchall()
        con.execute("DROP TABLE IF EXISTS vecteurs")
        dim = None
        for i in range(0, len(lignes), lot):
            paquet = lignes[i:i + lot]
            vecs = plonger([f"{t}\n{x}" for _, t, x in paquet])
            if dim is None:
                dim = len(vecs[0])
                con.execute(f"CREATE VIRTUAL TABLE vecteurs USING vec0(embedding float[{dim}] distance_metric=cosine)")
            con.executemany("INSERT INTO vecteurs(rowid, embedding) VALUES (?, ?)",
                            [(fid, _blob(v)) for (fid, _, _), v in zip(paquet, vecs)])
        con.execute("INSERT OR REPLACE INTO meta VALUES ('vecteurs', ?)", (str(dim or 0),))
        con.commit()
        return len(lignes)
    finally:
        con.close()


def voisins(con: sqlite3.Connection, vecteur: Sequence[float], n: int) -> list[int]:
    """Ids des n fragments les plus proches (la connexion doit avoir sqlite-vec chargé)."""
    return [r[0] for r in con.execute("SELECT rowid FROM vecteurs WHERE embedding MATCH ? AND k = ? ORDER BY distance",
                                      (_blob(vecteur), n))]


def a_des_vecteurs(con: sqlite3.Connection) -> bool:
    return con.execute("SELECT 1 FROM sqlite_master WHERE name='vecteurs'").fetchone() is not None
