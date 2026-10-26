"""Banc de recherche du RAG tiré du jeu de données `arunsrajan/godot-docs-dataset` (Hugging Face, CC BY 3.0).

Chaque ligne du jeu donne une question en anglais, écrite d'après un gabarit (« Explain the `add_child` method of the
Node class in Godot. »), et la page de godot-docs qui y répond, avec son ancre
(`classes/class_node.html#class-node-method-add-child`). Le jeu vient de la branche 4.7 de godot-docs, comme notre
copie. Deux mesures, sans LLM :

- couverture : la page et l'ancre de chaque ligne existent-elles dans notre index ? Un fragment porte une ancre par
  ses étiquettes rst (`class_Node_method_add_child`) et par le titre de sa section, convertis comme le fait docutils
  pour les identifiants HTML (`make_id`) ;
- recherche : parmi les n premiers résultats de `chercher`, la page attendue (« page ») et le fragment de l'ancre
  (« précis »). Une question de vue d'ensemble (sans ancre) n'a que la page.

Les questions restent hors de l'index et de l'entraînement. Le fichier n'est pas versionné :
`donnees/rag/hf_godot_docs/godot_docs_dataset.csv`, téléchargé le 2026-10-26 depuis
https://huggingface.co/datasets/arunsrajan/godot-docs-dataset/resolve/<REVISION>/godot_docs_dataset.csv.

    python -m usine.rag banc-docs [-n 5] [--par-groupe 1000] [--source tout|doc]
"""

from __future__ import annotations

import csv
import hashlib
import json
import re
import unicodedata
from collections import defaultdict
from pathlib import Path
from typing import Any

from usine import config as cfg

REVISION = "341723dec46542e243211d7cf2a1c669d18000b2"
SHA256 = "049f8226c006b865f0cf171791d57e21b2325d8f1013b2cc2260f7227a367925"
GROUPES = ("membre", "classe", "guide")


def chemin(donnees: Path | None = None) -> Path:
    return Path(donnees or cfg.dossier_donnees()) / "rag" / "hf_godot_docs" / "godot_docs_dataset.csv"


def make_id(texte: str) -> str:
    """Identifiant HTML d'une étiquette ou d'un titre, comme `docutils.nodes.make_id`."""
    t = unicodedata.normalize("NFKD", texte).encode("ascii", "ignore").decode("ascii")
    t = re.sub(r"[^a-z0-9]+", "-", " ".join(t.lower().split()))
    return re.sub(r"^[-0-9]+|-+$", "", t)


def groupe(page: str, ancre: str) -> str:
    if page.startswith("classes/"):
        return "membre" if ancre.startswith("class-") else "classe"
    return "guide"


def lignes(fichier: Path | None = None, sha256: str | None = SHA256) -> list[dict[str, str]]:
    """Une ligne par couple (page, ancre) : les réponses longues sont coupées en « (part i/n) », on garde la première."""
    fichier = Path(fichier or chemin())
    if not fichier.is_file():
        raise FileNotFoundError(f"jeu de données absent : {fichier}")
    empreinte = hashlib.sha256(fichier.read_bytes()).hexdigest()
    if sha256 and empreinte != sha256:
        raise ValueError(f"{fichier.name} : SHA-256 {empreinte}, attendu {sha256} (révision {REVISION})")
    csv.field_size_limit(1 << 30)
    vus: set[tuple[str, str]] = set()
    retenues = []
    with fichier.open(encoding="utf-8", newline="") as f:
        for l in csv.DictReader(f):
            page, _, ancre = l["source"].partition("#")
            page = re.sub(r"\.html$", ".rst", page)
            if (page, ancre) in vus:
                continue
            vus.add((page, ancre))
            retenues.append({"question": l["instruction"], "page": page, "ancre": ancre,
                             "categorie": l["category"], "groupe": groupe(page, ancre)})
    return retenues


def echantillon(liste: list[dict[str, str]], par_groupe: int) -> list[dict[str, str]]:
    """Au plus `par_groupe` lignes par groupe, toujours les mêmes : ordre de l'empreinte de « page#ancre »."""
    if par_groupe <= 0:
        return liste
    cle = lambda l: hashlib.sha1(f"{l['page']}#{l['ancre']}".encode()).hexdigest()  # noqa: E731
    pris: list[dict[str, str]] = []
    for g in GROUPES:
        pris += sorted((l for l in liste if l["groupe"] == g), key=cle)[:par_groupe]
    return pris


def ancres_de_l_index(con) -> dict[tuple[str, str], set[str]]:
    """(source, titre) → ancres du fragment : ses étiquettes rst et le titre de sa dernière section, en make_id."""
    table: dict[tuple[str, str], set[str]] = defaultdict(set)
    for source, titre, ancres in con.execute("SELECT source, titre, ancres FROM fragments "
                                             "WHERE genre IN ('classe', 'membre', 'guide')"):
        a = {make_id(x) for x in json.loads(ancres or "[]")}
        a.add(make_id(re.sub(r" \(\d+\)$", "", titre.split(" › ")[-1])))
        table[(source, titre)] |= a
    return table


def mesurer(n: int = 5, par_groupe: int = 1000, source: str = "tout", base: Path | None = None,
            fichier: Path | None = None) -> dict[str, Any]:
    from usine.rag.index import IndexDocs

    tout = lignes(fichier)
    idx = IndexDocs(base)
    try:
        table = ancres_de_l_index(idx.con)
        par_page: dict[str, set[str]] = defaultdict(set)
        for (src, _), a in table.items():
            par_page[src] |= a
        couverture: dict[str, list[int]] = {g: [0, 0, 0] for g in GROUPES}  # pages, ancres, total
        absentes: dict[str, list[str]] = defaultdict(list)
        for l in tout:
            c = couverture[l["groupe"]]
            c[2] += 1
            if l["page"] in par_page:
                c[0] += 1
                if not l["ancre"] or l["ancre"] in par_page[l["page"]]:
                    c[1] += 1
                else:
                    absentes[l["groupe"]].append(f"{l['page']}#{l['ancre']}")
            else:
                absentes[l["groupe"]].append(l["page"])
        recherche: dict[str, list[int]] = {g: [0, 0, 0] for g in GROUPES}  # page, précis, total
        rates: dict[str, list[dict[str, Any]]] = defaultdict(list)
        for l in echantillon(tout, par_groupe):
            if l["page"] not in par_page or (l["ancre"] and l["ancre"] not in par_page[l["page"]]):
                continue  # absente de l'index : comptée par la couverture, pas par la recherche
            res = idx.chercher(l["question"], n, source)
            page = any(r["source"] == l["page"] for r in res)
            precis = page if not l["ancre"] else any(
                r["source"] == l["page"] and l["ancre"] in table.get((r["source"], r["titre"]), ()) for r in res)
            s = recherche[l["groupe"]]
            s[0] += page
            s[1] += precis
            s[2] += 1
            if not precis:
                rates[l["groupe"]].append({"question": l["question"], "attendu": f"{l['page']}#{l['ancre']}",
                                           "obtenus": [r["titre"] for r in res]})
        return {"n": n, "source": source, "revision": REVISION, "lignes": len(tout),
                "couverture": {g: {"pages": c[0], "ancres": c[1], "total": c[2]} for g, c in couverture.items()},
                "recherche": {g: {"page": s[0], "precis": s[1], "total": s[2]} for g, s in recherche.items()},
                "absentes": {g: v[:50] for g, v in absentes.items()}, "rates": dict(rates)}
    finally:
        idx.fermer()
