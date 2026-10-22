"""États d'un projet d'étape : lecture, noms ramenés à l'étape visée, différences entre deux étapes."""

from __future__ import annotations

import os
import re
import subprocess
import tempfile
from dataclasses import dataclass

from usine.cours.base import chemins
from usine.cours.fabriquer import nom_projet

CODE = (".gd", ".gdshader", ".gdshaderinc")
TEXTE = CODE + (".tscn", ".tres", ".godot", ".md", ".cfg")
BANDEAU = re.compile(r"^\s*(#|//) (>>> NOUVEAU À L'ÉTAPE \d{3}|<<< FIN DU NOUVEAU)\s*$")
ENTETE = re.compile(r"^\s*(##|//) Étape \d{3} · .*$")


def nom(ville: str, etape: int) -> str:
    """Le nom du projet d'une étape. Un cours « de jeu » n'a qu'une suite d'étapes : `ville` y est son préfixe."""
    ch = chemins.actuels()
    if ch.jeu:
        from usine.cours import jeu
        return jeu.nom_projet(ch.manifeste, etape)
    return nom_projet(ville, etape)


def dossier(ville: str, etape: int) -> str:
    return str(chemins.actuels().projets / nom(ville, etape))


def renommer(texte: str, ville: str, de: int, vers: int) -> str:
    """Ramène les noms d'une étape à ceux d'une autre (fichiers, chemins res://). Dans un cours de jeu, le nom et la
    description du projet (`config/name`, `config/description` de project.godot) disent l'étape : ramenés eux aussi,
    ils ne comptent pas comme un changement de l'étape."""
    texte = texte.replace(nom(ville, de), nom(ville, vers))
    ch = chemins.actuels()
    if ch.jeu and de != vers and texte.startswith("; Engine configuration file."):
        etapes = ch.manifeste["ETAPES"]
        texte = re.sub(r'^(config/name="[^"]*étape )\d{3}"', rf'\g<1>{vers:03d}"', texte, flags=re.M)
        texte = texte.replace(f'config/description="{etapes[de - 1]["titre"]}"',
                              f'config/description="{etapes[vers - 1]["titre"]}"')
    return texte


def nettoyer(texte: str) -> str:
    """Retire les bandeaux du cours (« NOUVEAU », en-tête d'étape) : le code reste identique."""
    lignes = texte.split("\n")
    garde = [l for l in lignes if not BANDEAU.match(l) and not ENTETE.match(l)]
    # Une ligne vide laissée en double par un bandeau retiré : on la fusionne.
    sortie: list[str] = []
    for l in garde:
        if l.strip() == "" and sortie and sortie[-1].strip() == "" and len(sortie) > 1:
            continue
        sortie.append(l)
    return "\n".join(sortie)


def lire(ville: str, etape: int, vers: int | None = None, code_seul: bool = False) -> dict[str, str]:
    """Fichiers texte du projet (hors .godot/, .uid, .import), chemins relatifs ramenés à `vers`. Dans un cours
    « de jeu », les extensions (addons/, GdUnit4) ne sont pas lues : elles ne sont pas enseignées, le projet
    matérialisé les reçoit telles quelles (godot.materialiser)."""
    vers = etape if vers is None else vers
    racine = dossier(ville, etape)
    jeu = chemins.actuels().jeu
    fichiers: dict[str, str] = {}
    for dp, dn, fn in os.walk(racine):
        dn[:] = [d for d in dn if d != ".godot" and not (jeu and dp == racine and d == "addons")]
        for f in fn:
            if not f.endswith(CODE if code_seul else TEXTE):
                continue
            chemin = os.path.join(dp, f)
            rel = renommer(os.path.relpath(chemin, racine).replace(os.sep, "/"), ville, etape, vers)
            with open(chemin, encoding="utf-8", newline="") as h:
                contenu = renommer(h.read(), ville, etape, vers)
            fichiers[rel] = nettoyer(contenu) if f.endswith(CODE) else contenu
    return fichiers


@dataclass
class Morceau:
    """Un changement contigu dans un fichier : lignes anciennes [a1, a2) remplacées par nouvelles [n1, n2)."""
    fichier: str
    a1: int
    a2: int
    n1: int
    n2: int
    anciennes: list[str]
    nouvelles: list[str]
    section: int | None = None
    id: int = 0

    @property
    def genre(self) -> str:
        if not self.anciennes:
            return "ajout"
        if not self.nouvelles:
            return "retrait"
        return "remplacement"


def _diff_git(a: list[str], n: list[str]) -> list[tuple[int, int, int, int]]:
    """Morceaux (a1, a2, n1, n2) selon l'algorithme « histogram » de git : des changements plus
    naturels que ceux de difflib (une fonction ajoutée reste d'un seul tenant)."""
    with tempfile.TemporaryDirectory() as tmp:
        fa, fn = os.path.join(tmp, "a"), os.path.join(tmp, "n")
        with open(fa, "w", encoding="utf-8", newline="\n") as h:
            h.write("\n".join(a) + "\n")
        with open(fn, "w", encoding="utf-8", newline="\n") as h:
            h.write("\n".join(n) + "\n")
        p = subprocess.run(["git", "diff", "--no-index", "--histogram", "-U0", "--no-color", fa, fn],
                           capture_output=True, text=True, encoding="utf-8")
    sortie = []
    for m in re.finditer(r"^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@", p.stdout, re.M):
        a0, al = int(m.group(1)), int(m.group(2) if m.group(2) is not None else 1)
        n0, nl = int(m.group(3)), int(m.group(4) if m.group(4) is not None else 1)
        a1 = a0 if al == 0 else a0 - 1
        n1 = n0 if nl == 0 else n0 - 1
        sortie.append((a1, a1 + al, n1, n1 + nl))
    return sortie


def morceaux(avant: dict[str, str], apres: dict[str, str]) -> list[Morceau]:
    """Différences par fichier enseigné (le code ; dans un cours « de jeu », aussi les scènes et ressources texte),
    en morceaux contigus (lignes)."""
    from usine.cours.base.profil import enseignables
    sortie: list[Morceau] = []
    ext = enseignables()
    for rel in sorted(set(avant) | set(apres)):
        if not rel.endswith(ext):
            continue
        a = avant[rel].split("\n") if rel in avant else []
        n = apres[rel].split("\n") if rel in apres else []
        if rel not in avant:
            sortie.append(Morceau(rel, 0, 0, 0, len(n), [], n))
            continue
        for a1, a2, n1, n2 in _diff_git(a, n):
            sortie.append(Morceau(rel, a1, a2, n1, n2, a[a1:a2], n[n1:n2]))
    for i, m in enumerate(sortie):
        m.id = i
    return sortie


def appliquer(avant: dict[str, str], apres: dict[str, str], choisis: set[int], tous: list[Morceau]) -> dict[str, str]:
    """État intermédiaire : chaque morceau choisi prend sa version nouvelle, les autres restent anciens.
    Les morceaux d'un fichier sont repérés par leur place dans l'ancien fichier."""
    etat = dict(avant)
    par_fichier: dict[str, list[Morceau]] = {}
    for m in tous:
        par_fichier.setdefault(m.fichier, []).append(m)
    for rel, liste in par_fichier.items():
        if rel not in avant:
            pris = [m for m in liste if m.id in choisis]
            if not pris:
                etat.pop(rel, None)
            elif len(pris) == len(liste):
                etat[rel] = apres[rel]
            else:
                etat[rel] = "\n".join(l for m in sorted(pris, key=lambda m: m.n1) for l in m.nouvelles)
            continue
        a = avant[rel].split("\n")
        lignes: list[str] = []
        pos = 0
        for m in sorted(liste, key=lambda m: (m.a1, m.n1)):
            if m.a1 > pos:
                lignes += a[pos:m.a1]
                pos = m.a1
            if m.id in choisis:
                lignes += m.nouvelles
            else:
                lignes += a[m.a1:m.a2] if m.a2 > pos else []
            pos = max(pos, m.a2)
        lignes += a[pos:]
        etat[rel] = "\n".join(lignes)
    return etat
