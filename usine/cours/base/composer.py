"""Écrit un exemple de création : la demande (prompt) et la réponse qui montre le cheminement."""
from __future__ import annotations

import re
from collections import OrderedDict

from usine.cours.base import api, textes
from usine.cours.base.etat import CODE, Morceau
from usine.cours.base.notes import Note, deplier, puces

LANGAGE = {".gd": "gdscript", ".gdshader": "glsl", ".gdshaderinc": "glsl"}


def langage(rel: str) -> str:
    return LANGAGE["." + rel.rsplit(".", 1)[-1]]


def bloc(rel: str, lignes: list[str]) -> str:
    while lignes and not lignes[0].strip():
        lignes = lignes[1:]
    while lignes and not lignes[-1].strip():
        lignes = lignes[:-1]
    return f"```{langage(rel)}\n" + "\n".join(lignes) + "\n```"


def sans_code(texte: str) -> str:
    texte = re.sub(r"```\w*\n.*?```", "", deplier(texte), flags=re.S)
    return re.sub(r"\n{3,}", "\n\n", texte).strip()


def extraits_actuels(avant: dict[str, str], morceaux: list[Morceau], contexte: int = 1, plafond: int = 9000) -> str:
    """Le code actuel autour de chaque endroit que l'étape touche, avec les numéros de ligne."""
    par_fichier: "OrderedDict[str, list[tuple[int, int]]]" = OrderedDict()
    for m in morceaux:
        if m.fichier not in avant:
            continue
        a, b = max(0, m.a1 - contexte), m.a2 + contexte
        par_fichier.setdefault(m.fichier, []).append((a, b))
    morceaux_texte = []
    total = 0
    for rel, plages in par_fichier.items():
        lignes = avant[rel].split("\n")
        plages.sort()
        fusion: list[list[int]] = []
        for a, b in plages:
            if fusion and a <= fusion[-1][1] + 3:
                fusion[-1][1] = max(fusion[-1][1], b)
            else:
                fusion.append([a, b])
        for a, b in fusion:
            b = min(b, len(lignes))
            # Un extrait fait seulement de lignes vides ne montre rien : on remonte jusqu'à deux lignes de code.
            while a > 0 and sum(1 for i in range(a, b) if lignes[i].strip()) < 2:
                a -= 1
            extrait = "\n".join(f"{i + 1:>4}  {lignes[i]}" for i in range(a, b))
            total += len(extrait)
            if total > plafond:
                morceaux_texte.append(f"`res://{rel}` : (extrait suivant omis, fichier lisible en entier)")
                continue
            fin = " (fin du fichier)" if not any(l.strip() for l in lignes[b:]) else ""
            quelles = f"ligne {b}" if a + 1 == b else f"lignes {a + 1} à {b}"
            morceaux_texte.append(f"`res://{rel}`, {quelles}{fin} :\n```{langage(rel)}\n{extrait}\n```")
    return "\n\n".join(morceaux_texte)


def ancre(avant_lignes: list[str], position: int) -> str | None:
    for i in range(position - 1, -1, -1):
        if avant_lignes[i].strip():
            return avant_lignes[i].strip()
    return None


def ordre_fichier(rel: str) -> tuple[int, str]:
    rang = 0 if rel.startswith("5_data") else 1 if rel.startswith("1_core") else 2 if rel.startswith("2_seq") else \
        3 if "/Mesh/" in rel and not rel.startswith("7_tests") else 4 if "/Shader/" in rel else 5 if rel.startswith("7_tests") else 6
    return rang, rel


def editions(avant: dict[str, str], apres: dict[str, str], morceaux: list[Morceau]) -> str:
    """Les changements, groupés par fichier, sous une forme que n'importe quel outil d'édition sait suivre :
    créer un fichier, remplacer un passage exact, ajouter après une ligne, retirer un passage."""
    sortie = []
    deja: set[str] = set()
    courant = None
    ordonnes = sorted(morceaux, key=lambda m: (ordre_fichier(m.fichier), m.a1, m.n1))
    # Des ajouts au même endroit et qui se suivent dans le nouveau fichier ne font qu'un bloc : sinon « après la
    # ligne X, j'ajoute A » puis « après la ligne X, j'ajoute B » laisserait l'ordre de A et B au hasard.
    groupes: list[list[Morceau]] = []
    for m in ordonnes:
        p = groupes[-1][-1] if groupes else None
        if (p is not None and m.genre == "ajout" and p.genre == "ajout" and p.fichier == m.fichier
                and p.a1 == m.a1 and p.n2 == m.n1):
            groupes[-1].append(m)
        else:
            groupes.append([m])
    for groupe in groupes:
        m = groupe[0]
        rel = m.fichier
        if rel not in avant:
            if rel in deja:
                continue
            deja.add(rel)
            sortie.append(f"Je crée `res://{rel}` :\n" + bloc(rel, apres[rel].split("\n")))
            courant = None
            continue
        if rel != courant:
            sortie.append(f"Dans `res://{rel}` :")
            courant = rel
        lignes = avant[rel].split("\n")
        # Le fichier tel qu'il est quand on arrive à ce changement : les changements du dessus sont faits.
        cur = apres[rel].split("\n")[:m.n1] + lignes[m.a1:]
        nouvelles = [l for g in groupe for l in g.nouvelles]
        if cur[m.n1:m.n1 + (m.a2 - m.a1)] != m.anciennes:      # coordonnées d'une autre version : forme simple
            cur = None
        if m.genre == "ajout":
            sortie.append(_ajout(rel, lignes, cur, m) + "\n" + bloc(rel, nouvelles))
        else:
            sortie.append(_remplacement(rel, cur, m, nouvelles))
    return "\n".join(sortie)


def _sans_bords(lignes: list[str]) -> list[str]:
    i, j = 0, len(lignes)
    while i < j and not lignes[i].strip():
        i += 1
    while j > i and not lignes[j - 1].strip():
        j -= 1
    return lignes[i:j]


def _occurrences(lignes: list[str], motif: list[str]) -> int:
    """Combien de fois ces lignes se suivent, telles quelles, dans le fichier."""
    if not motif:
        return 2
    n = len(motif)
    return sum(1 for s in range(len(lignes) - n + 1) if lignes[s:s + n] == motif)


def _ajout(rel: str, lignes: list[str], cur: list[str] | None, m: Morceau) -> str:
    """L'endroit d'un ajout, désigné sans ambiguïté : une ligne unique du fichier, sinon les lignes qui
    précèdent jusqu'à ce que le passage soit unique."""
    if cur is None:
        a = ancre(lignes, m.a1)
        return f"- après la ligne `{a}`, j'ajoute :" if a else "- au début du fichier, j'ajoute :"
    j = m.n1 - 1
    while j >= 0 and not cur[j].strip():
        j -= 1
    if j < 0:
        return "- au début du fichier, j'ajoute :"
    a = cur[j].strip()
    if sum(1 for l in cur if l.strip() == a) == 1:
        return f"- après la ligne `{a}`, j'ajoute :"
    k = j
    while k > 0 and j - k < 12 and _occurrences(cur, _sans_bords(cur[k:j + 1])) != 1:
        k -= 1
    passage = _sans_bords(cur[k:j + 1])
    if _occurrences(cur, passage) == 1:
        return "- après ces lignes :\n" + bloc(rel, passage) + "\n  j'ajoute :"
    return f"- après la ligne {j + 1} (`{a}`), j'ajoute :"


def _remplacement(rel: str, cur: list[str] | None, m: Morceau, nouvelles: list[str]) -> str:
    """Un passage à remplacer ou à retirer, élargi aux lignes voisines tant qu'il n'est pas unique."""
    if cur is None:
        if m.genre == "retrait":
            return "- je retire :\n" + bloc(rel, m.anciennes)
        return "- je remplace :\n" + bloc(rel, m.anciennes) + "\n  par :\n" + bloc(rel, nouvelles)
    debut, fin = m.n1, m.n1 + (m.a2 - m.a1)
    haut, bas = debut, fin
    for _ in range(12):
        if _occurrences(cur, _sans_bords(cur[haut:bas])) == 1:
            break
        if haut > 0 and (debut - haut < 8 or bas >= len(cur)):
            haut -= 1
        elif bas < len(cur):
            bas += 1
        else:
            break
    ancien = cur[haut:bas]
    nouveau = cur[haut:debut] + nouvelles + cur[fin:bas]
    if not _sans_bords(nouveau):
        return "- je retire :\n" + bloc(rel, ancien)
    return "- je remplace :\n" + bloc(rel, ancien) + "\n  par :\n" + bloc(rel, nouveau)


def consigne(note: Note, ville: str, avant: dict[str, str], morceaux: list[Morceau], points: list[int],
             partie: tuple[int, int] = (1, 1), extraits: bool = True) -> str:
    """La demande de l'étape. Sans `extraits` (format d'OpenCode), le code actuel n'est pas cité : la réponse le lit."""
    projet, _ = textes.VILLES[ville]
    n = note.etape
    titre = note.titre.split("·")[-1].strip()
    lignes = [f"Projet Godot 4.7.2 : {projet}. Les étapes 001 à {n - 1:03d} sont faites ; on fait l'étape {n:03d}." if n > 2
              else f"Projet Godot 4.7.2 : {projet}. L'étape 001 est faite ; on fait l'étape 002." if n == 2
              else f"Projet Godot 4.7.2 : {projet}. On commence le projet : étape 001.",
              "", f"Étape {n:03d} — {titre}."]
    intro = sans_code(note.intro)
    if intro:
        lignes += ["", intro]
    if partie[1] > 1:
        noms = [p.titre for p in note.points if p.numero in points]
        lignes += ["", f"Cette demande est la partie {partie[0]} sur {partie[1]} de l'étape : " + " ; ".join(noms) + "."]
    if note.essayer and partie[0] == partie[1]:
        essais = puces(note.essayer)
        if essais:
            lignes += ["", "À la fin, on doit pouvoir :"] + [f"- {e}" for e in essais]
    fichiers = sorted(k for k in avant if k.endswith(CODE))
    lignes += ["", "Fichiers de code du projet :"] + [f"- `res://{f}`" for f in fichiers]
    cites = extraits_actuels(avant, morceaux) if extraits else ""
    if cites:
        lignes += ["", "Le code actuel, là où l'étape intervient :", "", cites]
    return "\n".join(lignes)


def verifications_api(apres: dict[str, str], morceaux: list[Morceau]) -> list[str]:
    par_fichier: "OrderedDict[str, list[str]]" = OrderedDict()
    for m in morceaux:
        par_fichier.setdefault(m.fichier, []).extend(m.nouvelles)
    vus: "OrderedDict[str, str]" = OrderedDict()
    for rel, nouvelles in par_fichier.items():
        trouves = api.usages_shader(nouvelles) if rel.endswith((".gdshader", ".gdshaderinc")) else \
            api.usages_gdscript(nouvelles, apres.get(rel, ""))
        for sig, desc in trouves:
            vus.setdefault(sig, desc)
    return [_puce_api(s) + (f" — « {d} »" if d else "") for s, d in vus.items()]


def _puce_api(sig: str) -> str:
    """« classe X (hérite de A < B) » : les noms en code, le reste en texte ; une signature : tout en code."""
    m = re.match(r"classe (\w+) \(hérite de (.+)\)$", sig)
    if not m:
        return f"- `{sig}`"
    if m.group(2) == "—":
        return f"- classe `{m.group(1)}`"
    return f"- classe `{m.group(1)}` (hérite de " + " < ".join(f"`{p}`" for p in m.group(2).split(" < ")) + ")"
