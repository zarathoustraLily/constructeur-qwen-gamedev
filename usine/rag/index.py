"""Index SQLite FTS5 de la documentation Godot, recherche exacte d'abord.

Construction hors-ligne depuis une copie locale de godot-docs (`[chemins].docs_godot`) :
chaque fragment passe par `Exclusion.texte_exclu` (jeux gelés, règle 4) ; un fragment qui
reprend une solution gelée n'entre pas dans l'index et il est noté dans la table `exclus`.

Recherche (`search_docs`) :
1. correspondance exacte d'identifiants : `CharacterBody2D` → vue d'ensemble de la classe ;
   `CharacterBody2D.move_and_slide` → ce membre ; `move_and_slide` → les membres de ce nom ;
   dans une phrase, chaque mot qui est une classe ou un membre connu est servi d'abord ;
2. puis plein texte BM25 (titre pondéré), tous les mots d'abord, au moins un ensuite ;
3. vecteurs sqlite-vec en option, désactivés par défaut (voir vecteurs.py).
"""

from __future__ import annotations

import hashlib
import json
import re
import sqlite3
import subprocess
import time
from pathlib import Path
from typing import Any, Iterable

from usine import config as cfg
from usine.rag import vecteurs
from usine.rag.rst import lire_page, pages

NOM_INDEX = "godot_docs.sqlite"
SCHEMA = """
CREATE TABLE meta (cle TEXT PRIMARY KEY, valeur TEXT);
CREATE TABLE fragments (id INTEGER PRIMARY KEY, source TEXT, page TEXT, titre TEXT, texte TEXT,
                        genre TEXT, classe TEXT, membre TEXT, ancres TEXT);
CREATE INDEX fragments_classe ON fragments(classe COLLATE NOCASE, genre);
CREATE INDEX fragments_membre ON fragments(membre COLLATE NOCASE);
CREATE TABLE exclus (source TEXT, titre TEXT, tache_id TEXT);
CREATE VIRTUAL TABLE fts USING fts5(titre, texte, content='fragments', content_rowid='id',
                                    tokenize='porter unicode61');
"""
SOURCES = {"tout": None, "doc": False, "exemples": True}
FILTRES = {None: "", True: "AND f.genre = 'exemple'", False: "AND f.genre != 'exemple'"}
RE_IDENT = re.compile(r"@?[A-Za-z_][A-Za-z0-9_]*")


def chemin_index(donnees: Path | None = None) -> Path:
    return Path(donnees or cfg.dossier_donnees()) / "rag" / NOM_INDEX


def chemin_docs(config: dict[str, Any] | None = None) -> Path | None:
    config = cfg.charger_config() if config is None else config
    valeur = config.get("chemins", {}).get("docs_godot")
    if not valeur or valeur == cfg.A_RENSEIGNER:
        return None
    chemin = Path(valeur).expanduser()
    return chemin if chemin.is_absolute() else cfg.RACINE / chemin


def _empreinte_fichier(chemin: Path) -> str | None:
    return hashlib.sha256(chemin.read_bytes()).hexdigest() if chemin.is_file() else None


def _revision_docs(docs: Path) -> str:
    try:
        r = subprocess.run(["git", "-C", str(docs), "rev-parse", "HEAD"], capture_output=True, text=True, timeout=10)
        return r.stdout.strip() or "inconnue"
    except (OSError, subprocess.SubprocessError):
        return "inconnue"


def construire(docs: Path, sortie: Path | None = None, donnees: Path | None = None,
               exclusion=None, demos: Path | None = None, verification: dict[str, Any] | None = None,
               demos_exclues: Iterable[str] = ()) -> dict[str, Any]:
    """Construit l'index depuis `docs` (copie locale de godot-docs). Remplace l'index existant.

    demos + verification : exemples vérifiés (voir exemples.py) ; `demos_exclues` retire des
    projets entiers (par ex. une démo devenue source de tâches gelées).
    exclusion : une `usine.portillon.exclusion.Exclusion` ; par défaut celle du manifeste de
    `donnees/geles/`. Renvoie un rapport {fragments, pages, exclus, manifeste, duree_s, demos}.
    """
    from usine.rag.exemples import fragments_demos
    from usine.portillon.exclusion import Exclusion
    from usine.portillon.gel import chemin_manifeste

    debut = time.monotonic()
    docs = Path(docs)
    donnees = Path(donnees or cfg.dossier_donnees())
    sortie = Path(sortie or chemin_index(donnees))
    if exclusion is None:
        exclusion = Exclusion.charger(donnees)
    sortie.parent.mkdir(parents=True, exist_ok=True)
    tmp = sortie.with_suffix(".construction")
    tmp.unlink(missing_ok=True)
    liste = pages(docs)
    if not liste:
        raise FileNotFoundError(f"aucune page rst sous {docs} (attendu : une copie du dépôt godot-docs)")
    demos_exclues = sorted(set(demos_exclues))
    compte_demos: dict[str, int] = {}
    fragments_ex = []
    if demos is not None and verification is not None:
        retenus = {k: v for k, v in verification["projets"].items() if k not in demos_exclues}
        fragments_ex, compte_demos = fragments_demos(demos, {**verification, "projets": retenus})
    con = sqlite3.connect(tmp)
    exclus: list[tuple[str, str, str]] = []
    n = 0
    try:
        con.executescript(SCHEMA)
        tous = (f for page in liste for f in lire_page(docs, page))
        for f in [*tous, *fragments_ex]:
            gele = exclusion.texte_exclu(f.texte) if exclusion else None
            if gele:
                exclus.append((f.source, f.titre, gele))
                continue
            con.execute("INSERT INTO fragments(source, page, titre, texte, genre, classe, membre, ancres) "
                        "VALUES (?,?,?,?,?,?,?,?)",
                        (f.source, f.page, f.titre, f.texte, f.genre, f.classe, f.membre, json.dumps(f.ancres)))
            n += 1
        con.executemany("INSERT INTO exclus VALUES (?,?,?)", exclus)
        con.execute("INSERT INTO fts(fts) VALUES ('rebuild')")
        manifeste = _empreinte_fichier(chemin_manifeste(donnees))
        meta = {"docs": str(docs), "revision_docs": _revision_docs(docs), "pages": str(len(liste)),
                "fragments": str(n), "exclus": str(len(exclus)), "manifeste_gel": manifeste or "",
                "taches_gelees": str(len(exclusion.ids) if exclusion else 0),
                "demos_revision": (verification or {}).get("revision", "") if demos is not None else "",
                "demos": json.dumps(compte_demos), "demos_exclues": json.dumps(demos_exclues)}
        con.executemany("INSERT INTO meta VALUES (?,?)", meta.items())
        con.commit()
    finally:
        con.close()
    tmp.replace(sortie)
    return {"index": str(sortie), "pages": len(liste), "fragments": n, "exclus": exclus,
            "manifeste": manifeste, "duree_s": round(time.monotonic() - debut, 1), "demos": compte_demos}


class IndexDocs:
    def __init__(self, base: Path | None = None, plonger=None):
        """plonger : fonction textes → vecteurs (vecteurs.plongeur_llama) ; None = plein texte seul."""
        self.base = Path(base or chemin_index())
        if not self.base.is_file():
            raise FileNotFoundError(f"index de documentation absent : {self.base} "
                                    "(python -m usine.rag construire --docs <copie de godot-docs>)")
        self.con = sqlite3.connect(self.base.resolve().as_uri() + "?mode=ro", uri=True, check_same_thread=False)
        self.con.row_factory = sqlite3.Row
        self.meta = {r["cle"]: r["valeur"] for r in self.con.execute("SELECT cle, valeur FROM meta")}
        self.plonger = None
        if plonger is not None and vecteurs.disponible() and vecteurs.a_des_vecteurs(self.con):
            vecteurs._charger(self.con)
            self.plonger = plonger

    def fermer(self) -> None:
        self.con.close()

    # --- recherche exacte
    def _classes(self, nom: str) -> list[sqlite3.Row]:
        lignes = self.con.execute("SELECT * FROM fragments WHERE genre='classe' AND classe=? COLLATE NOCASE "
                                  "ORDER BY (classe = ?) DESC, id", (nom, nom)).fetchall()
        return lignes[:1]  # vue d'ensemble seulement (la suite sort par le plein texte)

    def _membres(self, nom: str, classes: Iterable[str] = ()) -> list[sqlite3.Row]:
        classes = list(classes)
        if classes:
            marque = ",".join("?" * len(classes))
            return self.con.execute(f"SELECT * FROM fragments WHERE genre='membre' AND membre=? "
                                    f"AND classe IN ({marque}) ORDER BY id", (nom, *classes)).fetchall()
        return self.con.execute("SELECT * FROM fragments WHERE genre='membre' AND membre=? ORDER BY id LIMIT 8",
                                (nom,)).fetchall()

    def _heritage(self, classe: str) -> list[str]:
        """Classe et ancêtres, lus dans la ligne « Inherits: » de la vue d'ensemble."""
        lignes = [classe]
        for r in self._classes(classe):
            m = re.match(r"Inherits:\s*(.+)", r["texte"])
            if m:
                lignes += [c.strip() for c in m.group(1).split("<")]
        return lignes

    def exacts(self, requete: str) -> list[sqlite3.Row]:
        requete = requete.strip()
        m = re.fullmatch(r"(@?[A-Za-z_][A-Za-z0-9_]*)\.([A-Za-z_][A-Za-z0-9_]*)(?:\(\))?", requete)
        if m:  # Classe.membre : le membre (cherché aussi dans les ancêtres), puis la classe
            return self._membres(m.group(2), self._heritage(m.group(1)))[:1] + self._classes(m.group(1))
        mots = RE_IDENT.findall(requete)
        trouves: list[sqlite3.Row] = []
        # Dans une phrase, une classe s'écrit avec sa casse exacte (« input » n'est pas Input).
        classes = [c for c in mots if (r := self._classes(c)) and (len(mots) == 1 or r[0]["classe"] == c)]
        for c in classes:
            trouves += self._classes(c)
        autres = [w for w in mots if w not in classes and ("_" in w or len(mots) == 1)]
        for w in autres:
            if classes:
                ancetres = [a for c in classes for a in self._heritage(c)]
                trouves += self._membres(w, ancetres)[:1]
            else:
                trouves += self._membres(w)
        if classes and autres:  # le membre précis passe devant la vue d'ensemble
            membres = [r for r in trouves if r["genre"] == "membre"]
            trouves = membres + [r for r in trouves if r["genre"] != "membre"]
        return trouves

    # --- plein texte
    def plein_texte(self, requete: str, n: int, tous: bool, exemples: bool | None = None) -> list[sqlite3.Row]:
        mots = [w for w in re.findall(r"[\w@]+", requete) if len(w) > 1]
        if not mots:
            return []
        expr = (" AND " if tous else " OR ").join('"' + w.replace('"', "") + '"' for w in mots)
        return self.con.execute(
            "SELECT f.* FROM fts JOIN fragments f ON f.id = fts.rowid WHERE fts MATCH ? " + FILTRES[exemples] +
            " ORDER BY bm25(fts, 8.0, 1.0), f.id LIMIT ?", (expr, n)).fetchall()

    def chercher(self, requete: str, n: int = 5, source: str = "tout") -> list[dict[str, Any]]:
        """source : "tout" (doc et exemples vérifiés), "doc" ou "exemples".

        En "tout", la moitié des places (arrondie au-dessous) revient d'abord aux exemples
        vérifiés : le code que Qwen reprend vient des démos qui compilent sous Godot 4.7.
        """
        if source not in SOURCES:
            raise ValueError(f"source inconnue : {source!r} (attendu : {', '.join(SOURCES)})")
        vus: set[int] = set()
        resultats: list[dict[str, Any]] = []

        def ajouter(lignes: Iterable[sqlite3.Row], origine: str) -> None:
            for r in lignes:
                if r["id"] not in vus and len(resultats) < n:
                    vus.add(r["id"])
                    resultats.append({"titre": r["titre"], "source": r["source"], "genre": r["genre"],
                                      "classe": r["classe"], "membre": r["membre"], "texte": r["texte"],
                                      "trouve_par": origine})

        exemples = SOURCES[source]
        places_ex = n // 2 if exemples is None and self._a_des_exemples() else 0
        if exemples is not True:
            ajouter(self.exacts(requete)[:n - places_ex], "exact")
        if places_ex:
            limite = len(resultats) + places_ex
            for tous in (True, False):
                for r in self.plein_texte(requete, n * 2, tous, exemples=True):
                    if len(resultats) < limite:
                        ajouter([r], "texte")
        if self.plonger is not None and len(resultats) < n:
            ids = vecteurs.voisins(self.con, self.plonger([requete])[0], n * 3)
            par_id = {r["id"]: r for r in self.con.execute(
                f"SELECT * FROM fragments WHERE id IN ({','.join('?' * len(ids))})", ids)} if ids else {}
            ajouter([par_id[i] for i in ids if i in par_id
                     and (exemples is None or (par_id[i]["genre"] == "exemple") == exemples)], "vecteur")
        for tous in (True, False):
            if len(resultats) < n:
                ajouter(self.plein_texte(requete, n * 2, tous, exemples=False if places_ex else exemples), "texte")
        for tous in (True, False):
            if len(resultats) < n and places_ex:
                ajouter(self.plein_texte(requete, n * 2, tous, exemples=True), "texte")
        return resultats

    def _a_des_exemples(self) -> bool:
        if not hasattr(self, "_exemples"):
            self._exemples = self.con.execute("SELECT 1 FROM fragments WHERE genre='exemple' LIMIT 1").fetchone() is not None
        return self._exemples

    # --- contrôle des jeux gelés
    def verifier_exclusion(self, exclusion, donnees: Path | None = None) -> dict[str, Any]:
        """Relit chaque fragment de l'index contre les jeux gelés actuels."""
        from usine.portillon.gel import chemin_manifeste

        fuites = []
        for r in self.con.execute("SELECT titre, source, texte FROM fragments ORDER BY id"):
            gele = exclusion.texte_exclu(r["texte"]) if exclusion else None
            if gele:
                fuites.append({"titre": r["titre"], "source": r["source"], "tache_id": gele})
        actuel = _empreinte_fichier(chemin_manifeste(Path(donnees or cfg.dossier_donnees()))) or ""
        return {"fragments": int(self.meta.get("fragments", 0)), "taches_gelees": len(exclusion.ids) if exclusion else 0,
                "fuites": fuites, "exclus_a_la_construction": int(self.meta.get("exclus", 0)),
                "manifeste_a_jour": actuel == self.meta.get("manifeste_gel", ""), "manifeste_actuel": actuel}


def formater(resultats: list[dict[str, Any]], max_car: int = 1500) -> str:
    """Texte compact pour le LLM : un bloc par fragment."""
    if not resultats:
        return "Aucun résultat."
    blocs = []
    for r in resultats:
        texte = r["texte"] if len(r["texte"]) <= max_car else r["texte"][:max_car].rstrip() + " […]"
        marque = "  [exemple vérifié : compile sous Godot 4.7]" if r["genre"] == "exemple" else ""
        blocs.append(f"## {r['titre']}  ({r['source']}){marque}\n{texte}")
    return "\n\n".join(blocs)


_INDEX: IndexDocs | None = None


def plongeur_configure(config: dict[str, Any] | None = None):
    """Plongeur du llama-server local si `[rag].vecteurs = true` dans config.toml, sinon None."""
    config = cfg.charger_config() if config is None else config
    if not config.get("rag", {}).get("vecteurs", False):
        return None
    llm = config.get("llm", {})
    return vecteurs.plongeur_llama(llm.get("url", "http://127.0.0.1:8080/v1"), llm.get("modele", "qwen"))


def search_docs(requete: str, n: int = 5, source: str = "tout", base: Path | None = None) -> list[dict[str, Any]]:
    global _INDEX
    if base is not None:
        idx = IndexDocs(base)
        try:
            return idx.chercher(requete, n, source)
        finally:
            idx.fermer()
    if _INDEX is None:
        _INDEX = IndexDocs(plonger=plongeur_configure())
    return _INDEX.chercher(requete, n, source)
