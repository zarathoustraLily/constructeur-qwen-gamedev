"""Conversion de l'adaptateur en GGUF et lanceur llama-server multi-LoRA.

Conversion : convert_lora_to_gguf.py de llama.cpp (chemin dans [entrainement].convertisseur_lora) :
    python convert_lora_to_gguf.py --base <dossier HF de Qwen3.8-27B> --outfile <sortie.gguf>
                                   --outtype f16 <dossier de l'adaptateur>

Lanceur (.bat) : llama-server avec un `--lora` par adaptateur, et :
  - jamais `-ngl` (ce build refuse de démarrer avec) : placement automatique ;
  - raisonnement coupé pour OpenCode : --reasoning off --reasoning-budget 0 --no-prefill-assistant.
Les adaptateurs sont appliqués à l'échelle 1 par défaut (OpenCode ne choisit pas de LoRA) ; la
mesure et les essais fixent l'échelle de chacun par requête (champ `lora`, ids dans l'ordre des
--lora). Option `init_sans_appliquer` : --lora-init-without-apply (tous à 0 par défaut).
"""

from __future__ import annotations

import os
import sys
import tempfile
from pathlib import Path

OPTIONS_OPENCODE = ["--reasoning", "off", "--reasoning-budget", "0", "--no-prefill-assistant"]
INTERDITES = {"-ngl", "--n-gpu-layers", "--gpu-layers"}


def commande_conversion(convertisseur: Path, adaptateur: Path, base_hf: Path, sortie: Path,
                        outtype: str = "f16", python: str = sys.executable) -> list[str]:
    return [python, str(convertisseur), "--base", str(base_hf), "--outfile", str(sortie), "--outtype", outtype,
            str(adaptateur)]


def convertir(convertisseur: Path, adaptateur: Path, base_hf: Path, sortie: Path, outtype: str = "f16",
              delai_s: float = 7200):
    from usine.processus import executer
    for chemin, nom in ((convertisseur, "convertisseur"), (adaptateur, "adaptateur"), (base_hf, "base HF")):
        if not Path(chemin).exists():
            raise FileNotFoundError(f"{nom} introuvable : {chemin}")
    Path(sortie).parent.mkdir(parents=True, exist_ok=True)
    return executer(commande_conversion(convertisseur, adaptateur, base_hf, sortie, outtype), delai_s=delai_s)


def _guillemets(x: str | Path) -> str:
    return f'"{x}"'


def lanceur_bat(serveur: Path, modele: Path, loras: list[Path], port: int = 8080, hote: str = "127.0.0.1",
                options: list[str] | None = None, init_sans_appliquer: bool = False) -> str:
    """Texte du .bat (fins de ligne CRLF). ValueError si une option interdite est demandée."""
    options = list(OPTIONS_OPENCODE if options is None else options)
    for o in options:
        if o.split("=")[0] in INTERDITES:
            raise ValueError(f"option interdite pour ce build de llama-server : {o}")
    args = [_guillemets(serveur), "-m", _guillemets(modele), "--host", hote, "--port", str(port)]
    for lora in loras:
        args += ["--lora", _guillemets(lora)]
    if init_sans_appliquer:
        args.append("--lora-init-without-apply")
    args += options
    lignes = ["@echo off", "chcp 65001 >nul",
              "rem Lanceur llama-server multi-LoRA (usine, session 5). Sans -ngl : placement automatique.",
              "rem Ids des LoRA pour le champ `lora` des requêtes, dans l'ordre des --lora :"]
    lignes += [f"rem   {i} = {Path(l).name}" for i, l in enumerate(loras)]
    lignes += [" ".join(args)]
    return "\r\n".join(lignes) + "\r\n"


def ecrire_lanceur(chemin: Path, *args, **kwargs) -> Path:
    """Écrit le .bat de façon atomique, en octets (CRLF gardés tels quels)."""
    octets = lanceur_bat(*args, **kwargs).encode("utf-8")
    chemin = Path(chemin)
    chemin.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix=f".{chemin.name}.", dir=chemin.parent)
    try:
        with os.fdopen(fd, "wb") as f:
            f.write(octets)
        os.replace(tmp, chemin)
    except BaseException:
        Path(tmp).unlink(missing_ok=True)
        raise
    return chemin
