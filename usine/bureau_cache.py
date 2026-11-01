"""Lance une commande sur un bureau Windows caché : sa fenêtre existe et se dessine, mais personne ne la voit, et elle ne
prend ni le focus ni la souris du bureau de laurent (2026-11-01 : « j'ai besoin de pouvoir utiliser mon pc et de ne pas
avoir la souris mobilisee a chaque essai godot »). C'est l'équivalent de xvfb-run sous Linux (`prefixe_ecran`).

Sa sortie est celle de la commande, son code de sortie aussi. Pendant qu'elle tourne, la zone de la souris est surveillée :
si elle change, elle est remise comme elle était, et l'incident est noté dans `bureau_cache.log` du dossier temporaire.

Tout Godot qui se sert de la carte passe par ici : les garde-fous de `garde_carte.py` décident s'il part.

    python usine/bureau_cache.py <programme> [arguments…]
    python usine/bureau_cache.py --rearmer     (après un arrêt de la carte, avec l'accord de laurent)
"""

from __future__ import annotations

import ctypes
import os
import subprocess
import sys
import tempfile
import time
from ctypes import wintypes as w
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))  # lancé comme un script, depuis le dossier d'un projet
from usine import garde_carte  # noqa: E402

BUREAU = "usine_rendu"
ACCES = 0x000F01FF  # tous les droits sur le bureau
SANS_CONSOLE = 0x08000000  # CREATE_NO_WINDOW
FLUX = 0x00000100  # STARTF_USESTDHANDLES
HERITABLE = 0x00000001  # HANDLE_FLAG_INHERIT
SURVEILLANCE_MS = 50
# Le crochet de capture d'OBS Studio (`graphics-hook64.dll`) entre dans chaque application Vulkan, et fait planter l'ouverture d'un
# appareil local dans le pilote : mesuré le 2026-11-01, 3 plantages sur 3 à la première carte d'une suite complète, 0 sans lui. Il
# se retire pour ce seul processus, par la variable que sa couche prévoit : ni OBS ni le système ne sont touchés.
SANS_CROCHET_OBS = "DISABLE_VULKAN_OBS_CAPTURE"


class Debut(ctypes.Structure):
    _fields_ = [("cb", w.DWORD), ("lpReserved", w.LPWSTR), ("lpDesktop", w.LPWSTR), ("lpTitle", w.LPWSTR),
                ("dwX", w.DWORD), ("dwY", w.DWORD), ("dwXSize", w.DWORD), ("dwYSize", w.DWORD),
                ("dwXCountChars", w.DWORD), ("dwYCountChars", w.DWORD), ("dwFillAttribute", w.DWORD),
                ("dwFlags", w.DWORD), ("wShowWindow", w.WORD), ("cbReserved2", w.WORD), ("lpReserved2", ctypes.c_void_p),
                ("hStdInput", w.HANDLE), ("hStdOutput", w.HANDLE), ("hStdError", w.HANDLE)]


class Processus(ctypes.Structure):
    _fields_ = [("hProcess", w.HANDLE), ("hThread", w.HANDLE), ("dwProcessId", w.DWORD), ("dwThreadId", w.DWORD)]


def noter(texte: str) -> None:
    with (Path(tempfile.gettempdir()) / "bureau_cache.log").open("a", encoding="utf-8") as f:
        f.write(f"{time.strftime('%H:%M:%S')} {texte}\n")


def main(commande: list[str]) -> int:
    if commande == ["--rearmer"]:
        garde_carte.rearmer()
        print("carte réarmée", flush=True)
        return 0
    integree = garde_carte.vers_carte_integree(commande)
    refus = garde_carte.entrer(sur_la_5090=integree is None)
    if refus:
        print(refus[1], flush=True)
        return refus[0]
    commande = integree or commande
    os.environ[SANS_CROCHET_OBS] = "1"
    kernel = ctypes.WinDLL("kernel32", use_last_error=True)
    user = ctypes.WinDLL("user32", use_last_error=True)
    user.CreateDesktopW.restype = w.HANDLE
    user.CreateDesktopW.argtypes = [w.LPCWSTR, w.LPCWSTR, ctypes.c_void_p, w.DWORD, w.DWORD, ctypes.c_void_p]
    user.GetClipCursor.argtypes = [ctypes.POINTER(w.RECT)]
    user.ClipCursor.argtypes = [ctypes.POINTER(w.RECT)]
    kernel.GetStdHandle.restype = w.HANDLE
    kernel.GetStdHandle.argtypes = [w.DWORD]
    kernel.SetHandleInformation.argtypes = [w.HANDLE, w.DWORD, w.DWORD]
    kernel.WaitForSingleObject.argtypes = [w.HANDLE, w.DWORD]
    kernel.WaitForSingleObject.restype = w.DWORD
    kernel.GetExitCodeProcess.argtypes = [w.HANDLE, ctypes.POINTER(w.DWORD)]
    bureau = user.CreateDesktopW(BUREAU, None, None, 0, ACCES, None)
    if not bureau:
        raise ctypes.WinError(ctypes.get_last_error())
    sortie = kernel.GetStdHandle(-11)
    erreur = kernel.GetStdHandle(-12)
    for flux in (sortie, erreur):
        kernel.SetHandleInformation(flux, HERITABLE, HERITABLE)
    debut = Debut()
    debut.cb = ctypes.sizeof(Debut)
    debut.lpDesktop = BUREAU
    debut.dwFlags = FLUX
    debut.hStdOutput, debut.hStdError = sortie, erreur
    infos = Processus()
    ligne = ctypes.create_unicode_buffer(subprocess.list2cmdline(commande))
    if not kernel.CreateProcessW(None, ligne, None, None, True, SANS_CONSOLE, None, os.getcwd(), ctypes.byref(debut), ctypes.byref(infos)):
        raise ctypes.WinError(ctypes.get_last_error())
    zone, actuelle = w.RECT(), w.RECT()
    user.GetClipCursor(ctypes.byref(zone))
    while kernel.WaitForSingleObject(infos.hProcess, SURVEILLANCE_MS) != 0:
        user.GetClipCursor(ctypes.byref(actuelle))
        if bytes(actuelle) != bytes(zone):
            noter(f"zone de la souris changée : {actuelle.left},{actuelle.top} à {actuelle.right},{actuelle.bottom} ; remise")
            user.ClipCursor(ctypes.byref(zone))
    code = w.DWORD()
    kernel.GetExitCodeProcess(infos.hProcess, ctypes.byref(code))
    limite = garde_carte.PLANTAGES_MAX if integree is None else garde_carte.PLANTAGES_MAX_INTEGREE
    if garde_carte.noter_fin(code.value, limite=limite):
        noter(f"Godot a planté sur la carte : code {code.value:#x}")
    return code.value


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
