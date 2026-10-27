"""Format commun des paires courtes et compte de leurs jetons (règle 5.8 : tokenizer de Qwen 3.8, jamais une
estimation ; la paire est mise en forme par le gabarit, `enable_thinking: false`, comme à l'entraînement)."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from usine import config as cfg

TYPES = ("création", "débogage", "analyse")
_TOKENIZER = None


FACTEUR_IMAGE = 32  # pixels par jeton d'image : patch 16 × fusion 2 (preprocessor_config.json de Qwen 3.8)
MARQUE_IMAGE = "<image>"  # place d'une image dans le texte, comme LLaMA-Factory l'attend


def jetons_image(largeur: int, hauteur: int) -> int:
    """Jetons d'une image : côtés arrondis au multiple de 32 le plus proche. 640 × 360 → 20 × 11 = 220, la valeur
    mesurée par LLaMA-Factory à l'essai de mémoire (ETAT)."""
    cote = lambda x: max(FACTEUR_IMAGE, round(x / FACTEUR_IMAGE) * FACTEUR_IMAGE) // FACTEUR_IMAGE  # noqa: E731
    return cote(largeur) * cote(hauteur)


def jetons(messages: list[dict[str, str]], images: list[str] | None = None) -> int:
    """Chaque marque d'image devient <|vision_start|><|vision_end|> autour de ses jetons d'image. Sur la paire de
    l'essai de mémoire (5 images en 640 × 360), ce compte donne 1 998 jetons, LLaMA-Factory 1 999 : garder une
    marge sous le plafond pour les paires avec images."""
    global _TOKENIZER
    from usine.cours.base import jetons as j
    from usine.cours.base.opencode import rendre
    if _TOKENIZER is None:
        _TOKENIZER = j.tokenizer()
    texte = rendre(messages, []).replace(MARQUE_IMAGE, "<|vision_start|><|vision_end|>")
    total = len(_TOKENIZER.encoder_special(texte))
    return total + sum(jetons_image(*taille_png(Path(chemin))) for chemin in images or [])


def taille_png(chemin: Path) -> tuple[int, int]:
    """Largeur et hauteur lues dans l'en-tête IHDR du PNG."""
    tete = chemin.read_bytes()[:24]
    if tete[:8] != b"\x89PNG\r\n\x1a\n" or tete[12:16] != b"IHDR":
        raise ValueError(f"pas un PNG : {chemin}")
    return int.from_bytes(tete[16:20], "big"), int.from_bytes(tete[20:24], "big")


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
    # Chaque message rogné : le gabarit de Qwen 3.8 le fait (|trim), LLaMA-Factory (qwen3_5) non (étape A4).
    messages = ([{"role": "system", "content": systeme.strip()}] if systeme else []) + [
        {"role": "user", "content": demande.strip()}, {"role": "assistant", "content": reponse.strip()}]
    return {"famille": famille, "sujet": sujet, "type": type_, "messages": messages, "images": images or [],
            "preuve": preuve, "jetons": jetons(messages, images), "jetons_reponse": jetons_reponse(messages)}


def vers_llamafactory(p: dict[str, Any]) -> dict[str, Any]:
    """La paire au format sharegpt de LLaMA-Factory, comme les bases des cours (`opencode.vers_sharegpt` : chaque
    message rogné, rendu identique à celui du gabarit) ; ses images dans la colonne « images »."""
    from usine.cours.base import opencode
    ligne = opencode.vers_sharegpt(p["messages"], [])
    if p["images"]:
        ligne["images"] = list(p["images"])
    return ligne


def plan() -> str:
    """Le bloc permanent du socle (section 3 : le plan des données), message système des paires de 2 048 jetons."""
    texte = (cfg.RACINE / "godot" / "socle_jeu" / "AGENTS.md").read_text(encoding="utf-8")
    return texte[:texte.index("# AVANT CHAQUE ÉTAPE")].strip()


def dossier(famille: str, donnees: Path | None = None) -> Path:
    d = Path(donnees or cfg.dossier_donnees()) / "paires" / famille
    d.mkdir(parents=True, exist_ok=True)
    return d


def ecrire(paires: list[dict[str, Any]], chemin: Path) -> None:
    chemin.parent.mkdir(parents=True, exist_ok=True)
    with chemin.open("w", encoding="utf-8", newline="\n") as f:
        for p in paires:
            f.write(json.dumps(p, ensure_ascii=False) + "\n")
