"""Rattache chaque morceau de code au point de la note qui l'explique."""
from __future__ import annotations

import math
import re

from usine.cours.base.etat import Morceau
from usine.cours.base.notes import IDENT, Note

TETE = re.compile(r"^(static func |func |class |# ---|## ---|// ---|/\*\* ---)")
# Un fichier de code nommé dans une note : « `procedural_commun.gdshaderinc` », « `…_porte.gd` », « `_materiaux.gd` ».
MENTION = re.compile(r"[\w./…-]*[\w…-]\.(?:gdshaderinc|gdshader|gd)\b")


def mentions(texte: str) -> set[str]:
    """Les fins de nom de fichier que cite un texte (sans le chemin ni les points de suspension)."""
    return {m.rsplit("/", 1)[-1].lstrip("…") for m in MENTION.findall(texte)}


def nomme(noms: set[str], rel: str) -> bool:
    base = rel.rsplit("/", 1)[-1]
    return any(base.endswith(x) for x in noms if x)


def _norm(ligne: str) -> str:
    return re.sub(r"\s+", " ", ligne.strip())


def decouper(morceaux: list[Morceau]) -> list[Morceau]:
    """Coupe les ajouts qui contiennent plusieurs fonctions : une fonction par morceau
    (le commentaire qui la précède reste avec elle)."""
    sortie: list[Morceau] = []
    for m in morceaux:
        if m.genre != "ajout" or len(m.nouvelles) < 8:
            sortie.append(m)
            continue
        coupures = [0]
        for i, l in enumerate(m.nouvelles):
            if i > 0 and TETE.match(l):
                debut = i
                while debut > 0 and m.nouvelles[debut - 1].startswith(("##", "#", "//", "/**", " *")) and debut - 1 > coupures[-1]:
                    debut -= 1
                if debut > coupures[-1]:
                    coupures.append(debut)
        coupures.append(len(m.nouvelles))
        if len(coupures) <= 2:
            sortie.append(m)
            continue
        for a, b in zip(coupures, coupures[1:]):
            sortie.append(Morceau(m.fichier, m.a1, m.a1, m.n1 + a, m.n1 + b, [], m.nouvelles[a:b]))
    for i, m in enumerate(sortie):
        m.id = i
    return sortie


def rattacher(note: Note, morceaux: list[Morceau], fichiers: dict[str, str]) -> dict[int, int]:
    """Renvoie {id de morceau: numéro de point}."""
    points = [p for p in note.points]
    if not points:
        return {}
    # Affinité fichier : les fichiers où l'on retrouve les lignes des extraits d'un point.
    lignes_fichier = {rel: {_norm(l) for l in texte.split("\n") if len(_norm(l)) > 6} for rel, texte in fichiers.items()}
    affinite: dict[int, set[str]] = {}
    for p in points:
        lignes = {_norm(l) for _, code in p.extraits for l in code.split("\n") if len(_norm(l)) > 6}
        affinite[p.numero] = {rel for rel, ls in lignes_fichier.items() if len(lignes & ls) >= max(1, len(lignes) // 3)}
    # Poids des noms : un nom cité par beaucoup de points compte peu.
    ids = {p.numero: p.identifiants() for p in points}
    freq: dict[str, int] = {}
    for s in ids.values():
        for n in s:
            freq[n] = freq.get(n, 0) + 1
    poids = lambda n: math.log(1 + len(points) / freq.get(n, 1))  # noqa: E731
    # Un point dont le titre nomme un fichier en parle d'abord (« Le fichier commun `procedural_commun.gdshaderinc` »,
    # parisien 002 : sans extrait, ce point ne recevait aucun morceau de son fichier) ; nommé dans le texte, un peu.
    par_titre = {p.numero: mentions(p.titre) for p in points}
    par_texte = {p.numero: mentions(p.texte) for p in points}
    affect: dict[int, int] = {}
    for m in morceaux:
        nouvelles = {_norm(l) for l in m.nouvelles if len(_norm(l)) > 6}
        noms = {n for l in m.nouvelles + m.anciennes for n in IDENT.findall(l) if len(n) > 3 and ("_" in n or n[0].isupper())}
        candidats = [p for p in points if m.fichier in affinite[p.numero] or nomme(par_titre[p.numero], m.fichier)] \
            or points
        meilleur, score = None, 0.0
        for p in candidats:
            lignes = {_norm(l) for _, code in p.extraits for l in code.split("\n") if len(_norm(l)) > 6}
            s = 10.0 * len(nouvelles & lignes) + sum(poids(n) for n in noms & ids[p.numero])
            if nomme(par_titre[p.numero], m.fichier):
                s += 10.0
            elif nomme(par_texte[p.numero], m.fichier):
                s += 2.0
            if "test" in m.fichier.split("/")[-1] and "test" in p.titre.lower():
                s += 5.0
            if s > score:
                meilleur, score = p.numero, s
        if meilleur is not None and score > 0.5:
            affect[m.id] = meilleur
    for m in morceaux:
        if m.id in affect:
            continue
        voisins = sorted((abs(v.n1 - m.n1), v.id) for v in morceaux if v.fichier == m.fichier and v.id in affect)
        affect[m.id] = affect[voisins[0][1]] if voisins else points[-1].numero
    return affect
