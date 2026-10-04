"""Lecture du reStructuredText de godot-docs, sans dépendance : texte nettoyé et fragments.

Deux sortes de pages :
- référence des classes (`classes/class_*.rst`) : un fragment « vue d'ensemble » (titre,
  héritage, résumé, Description), puis un fragment par membre (méthode, propriété, signal,
  énumération, constante, annotation…), repéré par son ancre `.. _class_<Classe>_<genre>_<nom>:`.
  Les tableaux récapitulatifs sont sautés : `vocab_lookup` les donne mieux et en moins de jetons ;
- guides (`getting_started/`, `tutorials/`) : un fragment par section, découpé par paragraphes
  au-delà de TAILLE_MAX caractères.

Le C# est retiré des onglets de code (`.. code-tab:: csharp`) : Qwen écrit du GDScript.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path

TAILLE_MAX = 1800
RE_SOULIGNE = re.compile(r"^([=\-~^\"'`#*+.:_])\1{2,}\s*$")
RE_ANCRE = re.compile(r"^\.\. _([^:]+):\s*$")
RE_ROLE_CIBLE = re.compile(r":(?:ref|doc|abbr|term|kbd|menuselection|guilabel|code|file|math|"
                           r"button|ui|inputevent|emphasis|strong|literal)?:`([^`<]*?)\s*<[^`>]*>`")
RE_ROLE = re.compile(r":[a-z_\-]+:`([^`]*)`")
RE_LIEN = re.compile(r"`([^`<]+?)\s*<[^`>]+>`__?")
RE_GRAS = re.compile(r"\*\*(.+?)\*\*")
RE_LITTERAL = re.compile(r"``(.+?)``")
RE_ITALIQUE = re.compile(r"(?<![\w*])\*(?!\s)([^*\n]+?)\*(?![\w*])")
RE_SUBST = re.compile(r"\|(virtual|required|const|vararg|constructor|static|operator|bitfield)\|")
DIRECTIVES_GARDEES = {"note", "tip", "warning", "important", "caution", "danger", "attention",
                      "seealso", "code-block", "code", "highlight", "code-tab", "tabs", "tab"}
LANGAGES_RETIRES = {"csharp", "c#", "cpp", "c++"}
GENRES_MEMBRE = {"method": "méthode", "property": "propriété", "signal": "signal", "constant": "constante",
                 "annotation": "annotation", "operator": "opérateur", "constructor": "constructeur",
                 "private_method": "méthode virtuelle"}


@dataclass
class Fragment:
    source: str          # chemin relatif dans godot-docs (posix)
    page: str            # titre de la page
    titre: str           # titre du fragment (« CharacterBody2D.move_and_slide », « Page › Section »)
    texte: str
    genre: str = "guide"  # classe | membre | guide
    classe: str | None = None
    membre: str | None = None
    ancres: list[str] = field(default_factory=list)


def _sans_roles(ligne: str) -> str:
    ligne = RE_ROLE_CIBLE.sub(lambda m: m.group(1).strip(), ligne)
    ligne = RE_ROLE.sub(lambda m: m.group(1), ligne)
    ligne = RE_LIEN.sub(lambda m: m.group(1), ligne)
    ligne = RE_SUBST.sub(lambda m: m.group(1), ligne)
    ligne = RE_GRAS.sub(lambda m: m.group(1), ligne)
    ligne = RE_LITTERAL.sub(lambda m: m.group(1), ligne)
    ligne = RE_ITALIQUE.sub(lambda m: m.group(1), ligne)
    return ligne.replace("🔗", "").replace("\\ ", "").replace("\\", "")


def _indentation(ligne: str) -> int:
    return len(ligne) - len(ligne.lstrip(" "))


def nettoyer(lignes: list[str]) -> str:
    """Retire le balisage rst d'un bloc ; garde le texte et le code GDScript."""
    sortie: list[str] = []
    i = 0
    while i < len(lignes):
        ligne = lignes[i].rstrip()
        brut = ligne.strip()
        if brut.startswith(".. "):
            m = re.match(r"\.\.\s+([\w\-]+)::\s*(.*)$", brut)
            nom = m.group(1) if m else ""
            arg = (m.group(2) if m else "").strip().lower()
            if (nom in ("code-tab", "code-block", "code", "tab") and arg.split(" ")[0] in LANGAGES_RETIRES) \
                    or nom not in DIRECTIVES_GARDEES:
                # Directive sans texte utile (ancre, image, rst-class, toctree, substitution…)
                # ou code dans un autre langage que GDScript : on saute son bloc indenté.
                base = _indentation(lignes[i])
                i += 1
                while i < len(lignes) and (not lignes[i].strip() or _indentation(lignes[i]) > base):
                    i += 1
                continue
            if nom in ("note", "tip", "warning", "important", "caution", "danger", "attention", "seealso") and arg:
                sortie.append(f"{nom.capitalize()} : " + _sans_roles(m.group(2).strip()))
            i += 1
            continue
        if brut.startswith(":") and re.match(r"^:[\w\- ]+:(\s|$)", brut) and not brut.startswith(":ref:"):
            i += 1  # option de directive (:widths:, :github_url:…)
            continue
        if RE_SOULIGNE.match(brut) or re.match(r"^[+|][-=+|]*$", brut):
            i += 1
            continue
        sortie.append(_sans_roles(ligne))
        i += 1
    # Lignes vides en série → une seule ; indentation commune retirée.
    texte = "\n".join(sortie)
    texte = re.sub(r"\n[ \t]*\n(?:[ \t]*\n)+", "\n\n", texte)
    return texte.strip()


def _sections(lignes: list[str]) -> list[tuple[str, int, list[str], list[str]]]:
    """Découpe en sections : (titre, niveau, lignes, ancres juste avant le titre)."""
    niveaux: list[str] = []
    sections: list[tuple[str, int, list[str], list[str]]] = [("", 0, [], [])]
    ancres_en_attente: list[str] = []
    i = 0
    while i < len(lignes):
        ligne = lignes[i]
        suivante = lignes[i + 1] if i + 1 < len(lignes) else ""
        m = RE_ANCRE.match(ligne.strip())
        if m:
            ancres_en_attente.append(m.group(1))
        if ligne.strip() and not ligne.startswith(" ") and RE_SOULIGNE.match(suivante.strip()) \
                and len(suivante.strip()) >= len(ligne.strip()) - 1 and not RE_SOULIGNE.match(ligne.strip()):
            car = suivante.strip()[0]
            if car not in niveaux:
                niveaux.append(car)
            sections.append((_sans_roles(ligne.strip()), niveaux.index(car) + 1, [], ancres_en_attente))
            ancres_en_attente = []
            i += 2
            continue
        if ligne.strip() and not RE_ANCRE.match(ligne.strip()):
            ancres_en_attente = []
        sections[-1][2].append(ligne)
        i += 1
    return sections


def _decouper(texte: str) -> list[str]:
    """Coupe un texte trop long aux lignes vides, en morceaux d'au plus TAILLE_MAX caractères."""
    if len(texte) <= TAILLE_MAX:
        return [texte] if texte else []
    morceaux: list[str] = []
    courant = ""
    for para in texte.split("\n\n"):
        if courant and len(courant) + len(para) + 2 > TAILLE_MAX:
            morceaux.append(courant)
            courant = para
        else:
            courant = f"{courant}\n\n{para}" if courant else para
    if courant:
        morceaux.append(courant)
    return morceaux


def fragments_guide(source: str, lignes: list[str]) -> list[Fragment]:
    sections = _sections(lignes)
    page = next((t for t, n, _, _ in sections if n == 1), "") or Path(source).stem
    fragments: list[Fragment] = []
    chemin: list[str] = []
    for titre, niveau, corps, ancres in sections:
        if niveau:
            chemin = chemin[:niveau - 1] + [titre]
        texte = nettoyer(corps)
        if not texte:
            continue
        titre_frag = " › ".join(chemin) if chemin else page
        for k, morceau in enumerate(_decouper(texte)):
            fragments.append(Fragment(source, page, titre_frag + (f" ({k + 1})" if k else ""), morceau,
                                      ancres=list(ancres) if k == 0 else []))
    return fragments


def fragments_classe(source: str, lignes: list[str]) -> list[Fragment]:
    sections = _sections(lignes)
    classe = next((t for t, n, _, _ in sections if n == 1), Path(source).stem)
    fragments: list[Fragment] = []
    vue: list[str] = []
    for titre, niveau, corps, _ in sections:
        if niveau <= 1:
            vue.extend(corps)
        elif titre == "Description":
            vue.append("Description :")
            vue.extend(corps)
    texte_vue = nettoyer(vue)
    if texte_vue:
        morceaux = _decouper(texte_vue)
        fragments.append(Fragment(source, classe, classe, morceaux[0], "classe", classe, None, [f"class_{classe}"]))
        for k, m in enumerate(morceaux[1:], 2):
            fragments.append(Fragment(source, classe, f"{classe} ({k})", m, "classe", classe))
    # Membres : blocs séparés par « ---- » ou par un titre, chacun ouvert par une ancre.
    for titre, niveau, corps, _ in sections:
        if niveau <= 1 or titre in ("Description", "Tutorials", "Properties", "Methods", "Theme Properties"):
            continue
        blocs: list[list[str]] = [[]]
        for ligne in corps:
            if re.match(r"^-{4,}\s*$", ligne):
                blocs.append([])
            else:
                blocs[-1].append(ligne)
        for bloc in blocs:
            ancres = [m.group(1) for m in (RE_ANCRE.match(l.strip()) for l in bloc) if m]
            if not ancres:
                continue
            nom, genre = _nom_membre(ancres[0], classe)
            if nom is None:
                continue
            texte = nettoyer(bloc)
            if not texte:
                continue
            titre_frag = f"{classe}.{nom}"
            for k, morceau in enumerate(_decouper(f"{genre} de {classe}\n{texte}")):
                fragments.append(Fragment(source, classe, titre_frag + (f" ({k + 1})" if k else ""), morceau,
                                          "membre", classe, nom, ancres if k == 0 else []))
    return fragments


def _nom_membre(ancre: str, classe: str) -> tuple[str | None, str]:
    prefixe = f"class_{classe}_"
    if ancre.startswith(prefixe):
        reste = ancre[len(prefixe):]
        for g in sorted(GENRES_MEMBRE, key=len, reverse=True):
            if reste.startswith(g + "_"):
                return reste[len(g) + 1:], GENRES_MEMBRE[g]
        m = re.match(r"(theme_\w+?)_(.+)$", reste)
        if m:
            return m.group(2), "propriété de thème"
        return None, ""
    if ancre.startswith(f"enum_{classe}_"):
        return ancre[len(f"enum_{classe}_"):], "énumération"
    return None, ""


def lire_page(racine_docs: Path, fichier: Path) -> list[Fragment]:
    source = fichier.relative_to(racine_docs).as_posix()
    lignes = fichier.read_text(encoding="utf-8", errors="replace").splitlines()
    if source.startswith("classes/class_"):
        return fragments_classe(source, lignes)
    return fragments_guide(source, lignes)


DOSSIERS_INDEXES = ("classes", "getting_started", "tutorials")


def pages(racine_docs: Path) -> list[Path]:
    """Pages rst indexées, dans un ordre stable."""
    racine_docs = Path(racine_docs)
    trouvees: list[Path] = []
    for dossier in DOSSIERS_INDEXES:
        if (racine_docs / dossier).is_dir():
            trouvees.extend(p for p in (racine_docs / dossier).rglob("*.rst")
                            if not any(part.startswith(("_", ".")) for part in p.relative_to(racine_docs).parts))
    return sorted(trouvees, key=lambda p: p.relative_to(racine_docs).as_posix())
