"""Lecture des notes d'étape : points « Ce qu'on a fait, dans l'ordre », extraits de code, sources."""
from __future__ import annotations

import re
from dataclasses import dataclass, field

from usine.cours.base import chemins
BLOC = re.compile(r"```(\w*)\n(.*?)```", re.S)
INLINE = re.compile(r"`([^`\n]+)`")
IDENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")


@dataclass
class Point:
    numero: int
    titre: str
    texte: str                      # texte complet du point, extraits compris
    extraits: list[tuple[str, str]] = field(default_factory=list)   # (langage, code)

    def identifiants(self) -> set[str]:
        """Noms cités entre accents graves, et noms des extraits : ce dont le point parle."""
        noms: set[str] = set()
        for brut in INLINE.findall(self.texte):
            noms |= {m for m in IDENT.findall(brut) if len(m) > 2}
        for _, code in self.extraits:
            noms |= {m for m in IDENT.findall(code) if len(m) > 3 and ("_" in m or m[0].isupper())}
        return noms


@dataclass
class Note:
    ville: str
    etape: int
    titre: str
    piste: str
    intro: str
    points: list[Point]
    retenir: str
    essayer: str
    sources: str
    brut: str


def lire(ville: str, etape: int) -> Note:
    chemin = chemins.actuels().cours / "notes" / ville / f"etape_{etape:03d}.md"
    brut = chemin.read_text(encoding="utf-8")
    brut = re.sub(r"\{(TWIN|FILES_TABLE)\}", "", brut)
    titre = brut.split("\n", 1)[0].lstrip("# ").strip()
    m = re.search(r"\*\*Piste : ([^*]+)\.\*\*\s*(.*?)\n## ", brut, re.S)
    piste, intro = (m.group(1).strip(), m.group(2).strip()) if m else ("", "")
    sections = re.split(r"\n## ", "\n" + brut)
    par_titre = {s.split("\n", 1)[0].strip(): s.split("\n", 1)[1] if "\n" in s else "" for s in sections[1:]}
    fait = next((v for k, v in par_titre.items() if k.startswith("Ce qu")), "")
    points: list[Point] = []
    for bloc in re.split(r"\n### ", "\n" + fait)[1:]:
        tete, _, corps = bloc.partition("\n")
        mt = re.match(r"(\d+)\.\s*(.*)", tete.strip())
        numero, t = (int(mt.group(1)), mt.group(2)) if mt else (len(points) + 1, tete.strip())
        p = Point(numero, t.strip(), corps.strip())
        p.extraits = [(lang, code) for lang, code in BLOC.findall(corps)]
        points.append(p)
    trouve = lambda debut: next((v.strip() for k, v in par_titre.items() if k.startswith(debut)), "")  # noqa: E731
    return Note(ville, etape, titre, piste, intro, points, trouve("Ce qu'il faut retenir"), trouve("À essayer"),
                trouve("Sources"), brut)


def deplier(texte: str) -> str:
    """Recoud les lignes coupées à 100 caractères : paragraphes et puces sur une seule ligne,
    blocs de code et tableaux laissés tels quels."""
    sortie: list[str] = []
    dans_code = False
    for ligne in texte.split("\n"):
        if ligne.startswith("```"):
            dans_code = not dans_code
            sortie.append(ligne)
            continue
        if dans_code or ligne.startswith("|"):
            sortie.append(ligne)
            continue
        if not ligne.strip():
            sortie.append("")
            continue
        nouvelle_puce = bool(re.match(r"^\s*(- |\d+\. )", ligne))
        suite = sortie and sortie[-1].strip() and not sortie[-1].startswith(("```", "|")) and not nouvelle_puce
        if suite and not re.match(r"^#", ligne):
            sortie[-1] = sortie[-1].rstrip() + " " + ligne.strip()
        else:
            sortie.append(ligne.rstrip())
    return "\n".join(sortie)


def puces(texte: str) -> list[str]:
    return [l[2:].strip() for l in deplier(texte).split("\n") if l.startswith("- ")]
