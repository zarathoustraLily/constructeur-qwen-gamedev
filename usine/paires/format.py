"""Format commun des paires courtes et compte de leurs jetons (règle 5.8 : tokenizer de Qwen 3.8, jamais une
estimation ; la paire est mise en forme par le gabarit, `enable_thinking: false`, comme à l'entraînement)."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from usine import config as cfg

TYPES = ("création", "débogage", "analyse")
_TOKENIZER = None


def jetons(messages: list[dict[str, str]]) -> int:
    global _TOKENIZER
    from usine.cours.base import jetons as j
    from usine.cours.base.opencode import rendre
    if _TOKENIZER is None:
        _TOKENIZER = j.tokenizer()
    return len(_TOKENIZER.encoder_special(rendre(messages, [])))


def jetons_reponse(messages: list[dict[str, str]]) -> int:
    """Jetons des réponses seules (le partage 40/40/20 se compte en jetons de réponse, règle 7.1)."""
    global _TOKENIZER
    from usine.cours.base import jetons as j
    if _TOKENIZER is None:
        _TOKENIZER = j.tokenizer()
    return sum(len(_TOKENIZER.encoder(m["content"].strip())) for m in messages if m["role"] == "assistant")


def paire(famille: str, sujet: str, type_: str, demande: str, reponse: str, preuve: dict[str, Any],
          systeme: str | None = None, images: list[str] | None = None) -> dict[str, Any]:
    if type_ not in TYPES:
        raise ValueError(f"type inconnu : {type_}")
    messages = ([{"role": "system", "content": systeme}] if systeme else []) + [
        {"role": "user", "content": demande.strip()}, {"role": "assistant", "content": reponse.strip()}]
    return {"famille": famille, "sujet": sujet, "type": type_, "messages": messages, "images": images or [],
            "preuve": preuve, "jetons": jetons(messages), "jetons_reponse": jetons_reponse(messages)}


def dossier(famille: str, donnees: Path | None = None) -> Path:
    d = Path(donnees or cfg.dossier_donnees()) / "paires" / famille
    d.mkdir(parents=True, exist_ok=True)
    return d


def ecrire(paires: list[dict[str, Any]], chemin: Path) -> None:
    chemin.parent.mkdir(parents=True, exist_ok=True)
    with chemin.open("w", encoding="utf-8", newline="\n") as f:
        for p in paires:
            f.write(json.dumps(p, ensure_ascii=False) + "\n")
