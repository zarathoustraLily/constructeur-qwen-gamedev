"""Lancement de processus externes avec délai.

Règle 8 : on ne tue que les processus que nous avons lancés, identifiés par leur PID
(et le groupe ou l'arbre qu'ils ont créé), jamais par motif de ligne de commande.
"""

from __future__ import annotations

import os
import signal
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path


@dataclass
class Resultat:
    code: int | None
    sortie: str
    duree_s: float
    expire: bool = False


def _tuer_arbre(proc: subprocess.Popen) -> None:
    """Tue le processus lancé par nous et ses descendants."""
    if proc.poll() is not None:
        return
    if sys.platform == "win32":
        subprocess.run(
            ["taskkill", "/F", "/T", "/PID", str(proc.pid)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
    else:
        try:
            # Le groupe a été créé par start_new_session : son identifiant est notre PID.
            os.killpg(proc.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass


def executer(commande: list[str | Path], cwd: Path | None = None, delai_s: float = 300) -> Resultat:
    """Exécute une commande, fusionne stdout et stderr, et coupe au-delà du délai."""
    options: dict = {}
    if sys.platform == "win32":
        options["creationflags"] = subprocess.CREATE_NEW_PROCESS_GROUP
    else:
        options["start_new_session"] = True
    debut = time.monotonic()
    proc = subprocess.Popen(
        [str(c) for c in commande],
        cwd=str(cwd) if cwd else None,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        **options,
    )
    expire = False
    try:
        brut, _ = proc.communicate(timeout=delai_s)
    except subprocess.TimeoutExpired:
        expire = True
        _tuer_arbre(proc)
        brut, _ = proc.communicate()
    return Resultat(
        code=None if expire else proc.returncode,
        sortie=brut.decode("utf-8", errors="replace"),
        duree_s=round(time.monotonic() - debut, 3),
        expire=expire,
    )
