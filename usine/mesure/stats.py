"""Scores au premier essai, intervalles de Wilson à 95 %, règle de victoire, non-régression.

Règle de victoire (CLAUDE.md, « Mesure ») : victoire étroite si, à la fois,
  1. LoRA + RAG dépasse base + RAG au-delà de l'intervalle : borne basse de LoRA + RAG
     strictement au-dessus de la borne haute de base + RAG (des intervalles qui se touchent
     ou se chevauchent ne suffisent pas) ;
  2. LoRA + RAG atteint ou dépasse la référence frontière mesurée avec le même RAG : taux
     de LoRA + RAG ≥ taux de la frontière (comparaison exacte des fractions k/n).
Défaite : LoRA + RAG sous base + RAG au-delà de l'intervalle (le LoRA a fait reculer la
compétence). Égalité : tout le reste, avec le motif (gain non significatif, frontière non
atteinte, frontière non mesurée).

Non-régression entre deux tours : une compétence recule si son nouveau taux est sous l'ancien
au-delà de l'intervalle (borne haute nouvelle < borne basse ancienne). Une baisse dans
l'intervalle est signalée sans bloquer. Une compétence mesurée au tour précédent et absente
du nouveau tour bloque aussi : on ne peut pas affirmer qu'elle n'a pas reculé.
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from fractions import Fraction
from typing import Any

Z_95 = 1.959963984540054   # quantile 97,5 % de la loi normale

VICTOIRE, EGALITE, DEFAITE, NON_MESURE = "victoire", "égalité", "défaite", "non mesuré"


@dataclass(frozen=True)
class Score:
    """k réussites sur n tâches ; taux et intervalle de Wilson [bas, haut]."""
    k: int
    n: int
    bas: float
    haut: float

    @property
    def taux(self) -> float | None:
        return self.k / self.n if self.n else None

    def fraction(self) -> Fraction:
        return Fraction(self.k, self.n)

    def texte(self) -> str:
        """« 48,0 % [34,8 ; 61,5] (24/50) » (virgule décimale française)."""
        if not self.n:
            return "—"
        def pc(x: float) -> str:
            return f"{100 * x:.1f}".replace(".", ",")
        return f"{pc(self.k / self.n)} % [{pc(self.bas)} ; {pc(self.haut)}] ({self.k}/{self.n})"


def wilson(k: int, n: int, z: float = Z_95) -> Score:
    """Intervalle de score de Wilson. n = 0 : intervalle [0 ; 1] (rien n'est connu)."""
    if not isinstance(k, int) or not isinstance(n, int) or n < 0 or not 0 <= k <= n:
        raise ValueError(f"k/n invalide : {k}/{n}")
    if n == 0:
        return Score(0, 0, 0.0, 1.0)
    p = k / n
    z2 = z * z
    centre = (p + z2 / (2 * n)) / (1 + z2 / n)
    demi = z * math.sqrt(p * (1 - p) / n + z2 / (4 * n * n)) / (1 + z2 / n)
    # Bornes exactes aux extrémités (évite 1e-17 au lieu de 0 ou 1 - 1e-16 au lieu de 1).
    bas = 0.0 if k == 0 else max(0.0, centre - demi)
    haut = 1.0 if k == n else min(1.0, centre + demi)
    return Score(k, n, bas, haut)


def verdict(lora_rag: Score | None, base_rag: Score | None,
            frontiere_rag: Score | None = None) -> tuple[str, str]:
    """(verdict, motif) selon la règle de CLAUDE.md. Voir la docstring du module."""
    if lora_rag is None or base_rag is None or not lora_rag.n or not base_rag.n:
        return NON_MESURE, "LoRA + RAG ou base + RAG non mesurée"
    if lora_rag.haut < base_rag.bas:
        return DEFAITE, "LoRA + RAG sous base + RAG au-delà de l'intervalle"
    if not lora_rag.bas > base_rag.haut:
        if lora_rag.bas == base_rag.haut:
            return EGALITE, "intervalles qui se touchent : pas de gain au-delà de l'intervalle"
        return EGALITE, "intervalles qui se chevauchent : pas de gain au-delà de l'intervalle"
    if frontiere_rag is None or not frontiere_rag.n:
        return EGALITE, "gain sur base + RAG, mais frontière non mesurée : victoire non établie"
    if lora_rag.fraction() >= frontiere_rag.fraction():
        return VICTOIRE, "gain sur base + RAG et frontière atteinte"
    return EGALITE, "gain sur base + RAG, mais sous la frontière"


def regression(ancien: dict[str, Score], nouveau: dict[str, Score]) -> list[dict[str, Any]]:
    """Compare deux tours, compétence par compétence. Statut : stable, hausse, baisse, recul, absente, nouvelle."""
    lignes = []
    for comp in sorted(set(ancien) | set(nouveau)):
        a, b = ancien.get(comp), nouveau.get(comp)
        if a is None or not a.n:
            statut = "nouvelle"
        elif b is None or not b.n:
            statut = "absente"
        elif b.haut < a.bas:
            statut = "recul"
        elif b.fraction() < a.fraction():
            statut = "baisse"
        elif b.fraction() > a.fraction():
            statut = "hausse"
        else:
            statut = "stable"
        lignes.append({"competence": comp, "ancien": a, "nouveau": b, "statut": statut,
                       "bloquant": statut in ("recul", "absente")})
    return lignes
