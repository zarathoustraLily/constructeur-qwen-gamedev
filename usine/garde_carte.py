"""Les garde-fous de la carte graphique, au passage obligé des Godot qui s'en servent (`bureau_cache.py`).

Le 2026-11-01, un écran bleu (0x10E) a redémarré le PC de laurent : le pilote NVIDIA a refusé de mapper de la mémoire vidéo
pour un Godot (vidage lu avec WinDbg), pendant que Godot plantait en boucle dans ce pilote (20 fois en 12 minutes) et que
ComfyUI rechargeait ses modèles sur la même carte. Accord de laurent du même jour pour ces garde-fous : « Oui, fais-le ».

- Un seul Godot à la fois sur la carte, toutes familles confondues : un verrou que le système rend si le processus meurt.
- Aucun lancement sur la 5090 tant que ComfyUI tourne. Les shaders de calcul (Vulkan) passent sur la carte Intel, qui ne
  porte pas l'écran et ne partage rien avec lui : 135 cas verts sur l'étape 17 des fluides, en 50 s, comme sur la 5090.
- Trois plantages en dix minutes : plus aucun lancement, jusqu'à `python usine/bureau_cache.py --rearmer`, avec son accord.

Les deux premiers font attendre son tour (`CODE_OCCUPEE`), le dernier arrête la famille (`CarteRefusee`). `bureau_cache.py`
rend la main aussitôt : l'attente se fait dans `executer_carte`, hors du délai du lancement.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import tempfile
import time
from pathlib import Path

from usine.processus import Resultat, executer

CODE_OCCUPEE = 7501  # loin des codes de Godot et de GdUnit4 : seul `bureau_cache.py` les rend
CODE_REFUSEE = 7502
PLANTAGES_MAX = 3
FENETRE_S = 600
ATTENTE_S = 20
# Un code à partir de là n'est pas un `quit()` : c'est une exception du système, comme 0xC0000005 (violation d'accès).
PLANTAGE = 0x80000000
CARTE_INTEGREE = ["--gpu-index", "1"]  # « Using Device #1: Intel - Intel(R) Graphics » sur le poste de laurent
COMFYUI = re.compile("comfyui", re.I)
PROCESSUS = ["powershell", "-NoProfile", "-NonInteractive", "-Command",
             "Get-CimInstance Win32_Process -Filter \"Name like 'python%' or Name like 'comfyui%'\" "
             "| ForEach-Object { $_.ExecutablePath; $_.CommandLine }"]

_VERROU = None  # gardé ouvert : le verrou tient autant que ce processus


class CarteRefusee(BaseException):
    """La carte est arrêtée après des plantages en série. Hors d'`Exception` : `volume.lancer` et `generer._travailleur`
    notent une famille ou une étape en échec et passent à la suivante, alors que celle-ci doit tout arrêter."""


def _fichier(extension: str) -> Path:
    return Path(tempfile.gettempdir()) / f"usine_carte.{extension}"


def _lire() -> dict:
    try:
        return json.loads(_fichier("json").read_text(encoding="utf-8"))
    except (OSError, ValueError):  # absent, ou rempli de zéros par un arrêt brutal de la machine
        return {}


def _ecrire(etat: dict) -> None:
    provisoire = _fichier("json.tmp")
    provisoire.write_text(json.dumps(etat, ensure_ascii=False), encoding="utf-8")
    os.replace(provisoire, _fichier("json"))


def est_plantage(code: int) -> bool:
    return code >= PLANTAGE


def noter_fin(code: int, maintenant: float | None = None) -> bool:
    """Compte un plantage, et arrête la carte au troisième en dix minutes. L'arrêt tient jusqu'au réarmement."""
    if not est_plantage(code):
        return False
    maintenant = time.time() if maintenant is None else maintenant
    etat = _lire()
    etat["plantages"] = [t for t in etat.get("plantages", []) if maintenant - t < FENETRE_S] + [maintenant]
    if len(etat["plantages"]) >= PLANTAGES_MAX:
        etat["arret"] = (f"carte arrêtée : {len(etat['plantages'])} plantages de Godot en {FENETRE_S // 60} minutes. "
                         "Comprendre pourquoi, puis, avec l'accord de laurent : python usine/bureau_cache.py --rearmer")
    _ecrire(etat)
    return True


def rearmer() -> None:
    _fichier("json").unlink(missing_ok=True)


def comfyui_tourne() -> bool:
    """Vrai aussi si on ne peut pas le savoir : dans le doute, la carte attend."""
    try:
        r = subprocess.run(PROCESSUS, capture_output=True, text=True, errors="replace", timeout=60,
                           creationflags=subprocess.CREATE_NO_WINDOW)
    except (OSError, subprocess.SubprocessError):
        return True
    return r.returncode != 0 or COMFYUI.search(r.stdout) is not None


def _prendre_verrou() -> bool:
    global _VERROU
    if _VERROU is not None:
        return True
    import msvcrt  # Windows seulement, comme `bureau_cache.py`
    fichier = _fichier("verrou").open("a+b")
    fichier.seek(0)
    try:
        msvcrt.locking(fichier.fileno(), msvcrt.LK_NBLCK, 1)
    except OSError:
        fichier.close()
        return False
    _VERROU = fichier
    return True


def vers_carte_integree(commande: list[str]) -> list[str] | None:
    """La commande sur la carte Intel, ou None si elle n'y va pas : Vulkan se choisit une carte, OpenGL reste sur celle de
    l'écran, et un `--gpu-index` donné à la main passe avant."""
    if ("--rendering-driver", "vulkan") not in zip(commande, commande[1:]) or "--gpu-index" in commande:
        return None
    return [commande[0], *CARTE_INTEGREE, *commande[1:]]


def entrer(sur_la_5090: bool = True) -> tuple[int, str] | None:
    """None si ce processus a la carte ; sinon (code de sortie, raison)."""
    if not _prendre_verrou():
        return CODE_OCCUPEE, "carte occupée : un autre Godot s'en sert"
    arret = _lire().get("arret")
    if arret:
        return CODE_REFUSEE, arret
    if sur_la_5090 and comfyui_tourne():
        return CODE_OCCUPEE, "carte occupée : ComfyUI tourne"
    return None


def executer_carte(commande: list[str | Path], **options) -> Resultat:
    """`executer` pour une commande qui passe par `bureau_cache.py` : attend son tour hors du délai, et arrête la famille
    si la carte est refusée."""
    attente = ""
    while True:
        r = executer(commande, **options)
        if r.code == CODE_REFUSEE:
            raise CarteRefusee(r.sortie.strip())
        if r.code != CODE_OCCUPEE:
            return r
        if r.sortie != attente:
            attente = r.sortie
            print(f"{attente.strip()} : j'attends", flush=True)
        time.sleep(ATTENTE_S)
