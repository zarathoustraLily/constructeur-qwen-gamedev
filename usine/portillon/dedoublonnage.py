"""Dédoublonnage par empreinte et par fragments de texte (règle 4).

La « réponse » d'une tâche = ce que la référence change par rapport au départ, au niveau des
jetons : chaque zone modifiée de la référence, avec 3 jetons de contexte de part et d'autre.
On compare les réponses, pas les consignes : beaucoup de consignes sont des gabarits presque
identiques (D1, K3), et deux tâches dont la correction est la même sont un doublon même si
leurs consignes diffèrent.

Normalisation : minuscules, mots et nombres comme jetons ; fragments de K jetons consécutifs,
chacun réduit à un hachage de 64 bits. Doublon si la similarité de Jaccard des fragments de
réponse atteint le seuil (même compétence), ou si l'empreinte est identique.

`fragments_texte` sert aussi à exclure les jeux gelés d'un document quelconque
(entraînement, RAG, invention) : voir exclusion.py.
"""

from __future__ import annotations

import difflib
import hashlib
import re
from pathlib import Path

from usine.taches import EXTENSIONS_TEXTE, lire_tache

K_FRAGMENT = 6
_JETON = re.compile(r"[a-zà-ÿ_][a-zà-ÿ0-9_]*|\d+(?:\.\d+)?|[^\sa-zà-ÿ0-9_]", re.I)


def jetons(texte: str) -> list[str]:
    return _JETON.findall(texte.lower())


def fragments_texte(texte: str, k: int = K_FRAGMENT) -> set[str]:
    j = jetons(texte)
    if not j:
        return set()
    if len(j) < k:
        return {_h(" ".join(j))}
    return {_h(" ".join(j[i:i + k])) for i in range(len(j) - k + 1)}


def _h(texte: str) -> str:
    return hashlib.sha256(texte.encode("utf-8")).hexdigest()[:16]


def _lire(chemin: Path) -> list[str]:
    if not chemin.is_file() or chemin.suffix not in EXTENSIONS_TEXTE:
        return []
    return chemin.read_text(encoding="utf-8", errors="replace").splitlines()


def texte_reponse(dossier: Path, contexte: int = 3) -> str:
    """Zones que la référence ajoute, modifie ou retire par rapport au départ, en jetons, avec contexte.

    Une suppression (« >= » devenu « > ») ne laisse aucun jeton dans la référence : on garde alors
    le contexte autour du point retiré, sinon la réponse serait vide et une copie renommée d'une
    tâche gelée passerait l'exclusion.

    Les zones proches fusionnent ; le nom du fichier n'en fait pas partie (la même correction
    dans deux fichiers est la même réponse)."""
    dossier = Path(dossier)
    reference = dossier / "reference"
    zones: list[str] = []
    for f in sorted((p for p in reference.rglob("*") if p.is_file()), key=lambda p: p.relative_to(reference).parts):
        rel = f.relative_to(reference)
        avant = jetons("\n".join(_lire(dossier / "depart" / rel)))
        apres = jetons("\n".join(_lire(f)))
        garde: set[int] = set()
        for op, _, _, j1, j2 in difflib.SequenceMatcher(a=avant, b=apres, autojunk=False).get_opcodes():
            if op != "equal":
                garde |= set(range(max(0, j1 - contexte), min(len(apres), j2 + contexte)))
        zone: list[str] = []
        for k in range(len(apres) + 1):
            if k in garde:
                zone.append(apres[k])
            elif zone:
                zones.append(" ".join(zone))
                zone = []
    return "\n".join(zones)


def signature_tache(dossier: Path) -> dict[str, object]:
    tache = lire_tache(dossier)
    return {"id": tache["id"], "competence": tache["competence"], "empreinte": tache["empreinte"],
            "fragments": sorted(fragments_texte(texte_reponse(dossier))),
            "fragments_consigne": sorted(fragments_texte(tache["consigne"]))}


def jaccard(a: set[str], b: set[str]) -> float:
    if not a or not b:
        return 0.0
    return len(a & b) / len(a | b)


class Index:
    """Index des signatures déjà retenues (par exemple les jeux gelés)."""

    def __init__(self, seuil: float = 0.8):
        self.seuil = seuil
        self.empreintes: dict[str, str] = {}
        self.signatures: list[dict] = []
        self._par_fragment: dict[str, set[int]] = {}

    def ajouter(self, signature: dict) -> None:
        self.empreintes[signature["empreinte"]] = signature["id"]
        k = len(self.signatures)
        self.signatures.append({**signature, "fragments": set(signature["fragments"])})
        for f in signature["fragments"]:
            self._par_fragment.setdefault(f, set()).add(k)

    def doublon(self, signature: dict) -> tuple[str, str] | None:
        """(raison, id du doublon) ou None."""
        if signature["empreinte"] in self.empreintes:
            return "doublon_empreinte", self.empreintes[signature["empreinte"]]
        frag = set(signature["fragments"])
        voisins: set[int] = set()
        for f in frag:
            voisins |= self._par_fragment.get(f, set())
        for k in sorted(voisins):
            autre = self.signatures[k]
            if autre["competence"] == signature["competence"] and jaccard(frag, autre["fragments"]) >= self.seuil:
                return "doublon_fragments", autre["id"]
        return None
