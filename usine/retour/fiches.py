"""Après une erreur du moteur, la fiche du membre Godot en cause.

On lit le message de Godot (« Function "x()" not found in base self », « Nonexistent function 'x'
in base 'Node3D' »…) ; sinon, la ligne désignée par l'erreur. La fiche donne la signature
officielle (extension_api.json), les membres proches si le nom n'existe pas, et l'extrait de la
documentation quand l'index du RAG est présent.
"""

from __future__ import annotations

import difflib
import re
from pathlib import Path
from typing import Any, Callable

from usine.retour.verification import IDENT, IndexProjet, Signatures, nettoyer, verifier_script

MAX_FICHES = 3
MAX_DOC = 600

# (motif, groupe du membre, groupe de la classe ou None pour « self »)
_MOTIFS = [
    (re.compile(rf'Function "({IDENT})\(\)" not found in base self'), 1, None),
    (re.compile(rf'(?:Static function|Function) "({IDENT})\(\)" not found in base "({IDENT})'), 1, 2),
    (re.compile(rf'Cannot find (?:member|property) "({IDENT})" (?:in|on) base "({IDENT})'), 1, 2),
    (re.compile(rf"Nonexistent function '({IDENT})' in base '({IDENT})"), 1, 2),
    (re.compile(rf"Invalid (?:access to property or key|set index|assignment of property or key) '({IDENT})'"
                rf".*?(?:base object of type|base) '({IDENT})"), 1, 2),
    (re.compile(rf'Identifier "({IDENT})" not declared in the current scope'), 1, None),
]


def _doc_index() -> Callable[[str], str | None] | None:
    try:
        from usine.rag.index import IndexDocs
        index = IndexDocs()
    except (FileNotFoundError, ImportError, OSError):
        return None

    def doc(requete: str) -> str | None:
        lignes = index.exacts(requete)
        return lignes[0]["texte"] if lignes else None
    return doc


def _type_self(projet: Path, chemin: str, index: IndexProjet, vocab) -> tuple[str | None, set[str]]:
    script = index.scripts.get(chemin)
    if script is None:
        return None, set()
    noms, natif = index.chaine(script, vocab)
    return natif, noms


def _fiche(vocab, sig: Signatures, classe: str, membre: str, noms_script: set[str],
           doc: Callable[[str], str | None] | None) -> str | None:
    texte = sig.texte(classe, membre)
    if texte is not None:
        corps = f"{texte} (Godot {vocab.version()})"
        cible = texte.split("(")[0].split(":")[0].split(" =")[0]
    else:
        proches = sig.proches(classe, membre)
        proches_script = [n for n in difflib.get_close_matches(membre, sorted(noms_script), n=3, cutoff=0.6)
                          if n != membre]
        if not proches and not proches_script:
            return f"{membre} n'existe pas dans {classe} (Godot {vocab.version()}, héritage compris)."
        corps = (f"{membre} n'existe pas dans {classe} (Godot {vocab.version()}, héritage compris). Proches : "
                 + " ; ".join(proches + [f"{n} (déclaré dans le script)" for n in proches_script]))
        cible = proches[0].split("(")[0].split(":")[0].split(" =")[0] if proches else None
    if doc is not None and cible:
        extrait = doc(cible)
        if extrait:
            extrait = extrait if len(extrait) <= MAX_DOC else extrait[:MAX_DOC].rstrip() + " […]"
            corps += "\nDoc : " + extrait
    return corps


def fiches_pour_erreurs(erreurs: list[dict[str, Any]], projet: Path, vocab,
                        doc: Callable[[str], str | None] | None | bool = True) -> list[dict[str, str]]:
    """Fiches pour les erreurs d'un verdict (au plus MAX_FICHES). `doc=True` : index du RAG s'il existe."""
    if doc is True:
        doc = _doc_index()
    elif doc is False:
        doc = None
    projet = Path(projet)
    index = IndexProjet.lire(projet)
    sig = Signatures(vocab)
    fiches: list[dict[str, str]] = []
    vus: set[tuple[str, str]] = set()

    def ajouter(pour: str, classe: str, membre: str, noms: set[str]) -> None:
        if (classe, membre) in vus or len(fiches) >= MAX_FICHES or not vocab.classe_existe(classe):
            return
        vus.add((classe, membre))
        texte = _fiche(vocab, sig, classe, membre, noms, doc)
        if texte:
            fiches.append({"pour": pour, "fiche": texte})

    for e in erreurs:
        if len(fiches) >= MAX_FICHES:
            break
        message = e.get("message") or ""
        chemin = e.get("fichier") or ""
        ligne = e.get("ligne")
        pour = f"{chemin}:{ligne}" if chemin and ligne else (chemin or message[:80])
        source = None
        if chemin.endswith(".gd") and chemin.startswith("res://"):
            disque = projet / chemin[len("res://"):]
            if disque.is_file():
                source = disque.read_text(encoding="utf-8", errors="replace")
        reconnu = False
        for motif, g_membre, g_classe in _MOTIFS:
            m = motif.search(message)
            if not m:
                continue
            membre = m.group(g_membre)
            classe = m.group(g_classe) if g_classe else None
            noms: set[str] = set()
            if classe is None or classe == "GDScriptNativeClass":
                if classe == "GDScriptNativeClass" and source and ligne:
                    lignes = nettoyer(source).splitlines()
                    mr = re.search(rf"\b({IDENT})\.{re.escape(membre)}\b", lignes[ligne - 1]) if ligne <= len(lignes) else None
                    classe = mr.group(1) if mr else None
                else:
                    classe, noms = _type_self(projet, chemin, index, vocab)
            if classe:
                ajouter(pour, classe, membre, noms)
                reconnu = True
            break
        if reconnu or not (source and ligne):
            continue
        # Sinon : les membres Godot de la ligne désignée (signature et doc)
        rapport = verifier_script(source, chemin, vocab, index, sig)
        for p in rapport["problemes"]:
            if p["ligne"] == ligne and len(fiches) < MAX_FICHES:
                fiches.append({"pour": pour, "fiche": p["message"]})
        lignes = nettoyer(source).splitlines()
        if ligne <= len(lignes):
            for s in rapport["signatures"]:
                classe, reste = s.split(".", 1)
                membre = re.match(IDENT, reste).group(0)
                if re.search(rf"\.{re.escape(membre)}\b", lignes[ligne - 1]):
                    ajouter(pour, classe, membre, set())
    return fiches
