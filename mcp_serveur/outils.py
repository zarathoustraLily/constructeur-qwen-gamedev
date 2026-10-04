"""Les 9 outils exposés à OpenCode, en fonctions Python simples (testables sans MCP).

Chaque outil travaille sur UN projet Godot, fixé au lancement du serveur (`--projet`, par
défaut le dossier courant). Les chemins se donnent en `res://…` ou relatifs au projet ;
rien ne sort du projet.

Toute écriture (scene_write, apply_edits) suit la règle 7 : copie de travail jugée, puis
remplacement atomique seulement si le juge passe. Les juges (check_script, load_scene,
run_tests) tournent aussi sur une copie jetable : le projet de l'utilisateur ne change pas.
"""

from __future__ import annotations

import json
import tempfile
from pathlib import Path
from typing import Any

MAX_ERREURS = 20


class ErreurOutil(ValueError):
    """Argument refusé (chemin hors du projet, fichier absent…)."""


def _compact(objet: Any) -> str:
    return json.dumps(objet, ensure_ascii=False, separators=(",", ":"))


def _verdict_court(v: dict[str, Any]) -> dict[str, Any]:
    """Verdict au format commun, sans le journal brut ; erreurs plafonnées."""
    court = {k: v[k] for k in ("ok", "etape", "duree_s", "erreurs", "tests") if k in v}
    if "duree_s" in court:
        court["duree_s"] = round(float(court["duree_s"]), 1)
    for k in ("applique", "fichiers", "fichier"):
        if k in v:
            court[k] = v[k]
    erreurs = court.get("erreurs") or []
    if len(erreurs) > MAX_ERREURS:
        court["erreurs"] = erreurs[:MAX_ERREURS] + [{"message": f"… {len(erreurs) - MAX_ERREURS} erreurs de plus"}]
    return court


class Outils:
    def __init__(self, projet: Path, godot: Path | None = None):
        self.projet = Path(projet).resolve()
        if not (self.projet / "project.godot").is_file():
            raise ErreurOutil(f"pas de project.godot dans {self.projet}")
        self.godot = godot

    # --- chemins
    def res(self, chemin: str) -> str:
        """Normalise en res:// et refuse ce qui sort du projet."""
        from usine.projet.index import res_vers_disque
        chemin = (chemin or "").strip().replace("\\", "/")
        if not chemin.startswith("res://"):
            while chemin.startswith("./"):
                chemin = chemin[2:]
            chemin = "res://" + chemin.lstrip("/")
        disque = res_vers_disque(self.projet, chemin).resolve()
        if disque != self.projet and self.projet not in disque.parents:
            raise ErreurOutil(f"chemin hors du projet : {chemin}")
        return chemin

    def disque(self, chemin: str) -> Path:
        from usine.projet.index import res_vers_disque
        return res_vers_disque(self.projet, self.res(chemin))

    # --- vocabulaire et documentation
    def vocab_lookup(self, classe: str, membre: str | None = None) -> str:
        from usine.vocab import ouvrir
        vocab = ouvrir()
        if not vocab.classe_existe(classe):
            return f"Classe inconnue de Godot {vocab.version()} : {classe}"
        if membre:
            lignes = []
            for genre, liste in (("méthode", vocab.methodes(classe)), ("propriété", vocab.proprietes(classe)),
                                 ("signal", vocab.signaux(classe)), ("constante", vocab.constantes(classe)),
                                 ("énumération", vocab.enums(classe))):
                for m in liste:
                    if m["nom"] == membre:
                        lignes.append(f"{genre} [{m['origine']}] " + _signature(m))
            for e in vocab.enums(classe):
                for v in e["valeurs"]:
                    if v["nom"] == membre:
                        lignes.append(f"valeur d'énumération [{e['origine']}] {e['nom']}.{v['nom']} = {v['valeur']}")
            return "\n".join(lignes) if lignes else f"{classe} n'a aucun membre {membre} (héritage compris)."
        d = vocab.decrire(classe)
        propres = lambda liste: [m for m in liste if m["origine"] == classe]  # noqa: E731
        lignes = [f"{classe} (Godot {d['version']}) : " + " < ".join(d["heritage"])]
        for titre, cle in (("signaux", "signaux"), ("propriétés", "proprietes"), ("méthodes", "methodes"),
                           ("énumérations", "enums"), ("constantes", "constantes")):
            elements = propres(d[cle])
            if elements:
                lignes.append(f"{titre} ({len(elements)}) : " + "; ".join(_signature(m) for m in elements))
        herites = sum(len(d[c]) - len(propres(d[c])) for c in ("signaux", "proprietes", "methodes"))
        lignes.append(f"+ {herites} membres hérités : vocab_lookup(classe, membre) pour en vérifier un.")
        return "\n".join(lignes)

    def search_docs(self, requete: str, n: int = 5) -> str:
        from usine.rag.index import formater, search_docs
        try:
            return formater(search_docs(requete, max(1, min(int(n), 10))))
        except FileNotFoundError as exc:
            return f"Documentation indisponible : {exc}"

    # --- scènes
    def scene_read(self, chemin: str) -> str:
        from usine.projet.index import lire_texte
        from usine.scene.spec import scene_read
        res = self.res(chemin)
        fichier = self.disque(res)
        if not fichier.is_file():
            raise ErreurOutil(f"scène absente : {res}")
        return _compact(scene_read(lire_texte(fichier), res))

    def scene_write(self, chemin: str, spec: dict[str, Any]) -> str:
        from usine.juge import godot as juges
        from usine.juge.projet import preparer_copie
        from usine.projet.editions import _remplacer_atomiquement
        from usine.projet.index import Projet, Verificateur, lire_texte, res_vers_disque
        from usine.scene.spec import ErreurSpec, scene_write, valider_spec
        from usine.vocab import ouvrir

        res = self.res(chemin)
        if not res.endswith(".tscn"):
            raise ErreurOutil(f"une scène .tscn est attendue : {res}")
        spec = dict(spec)
        spec["chemin"] = res
        verif = Verificateur(ouvrir(), Projet(self.projet))
        verdict: dict[str, Any] = {"ok": False, "applique": False, "etape": "validation", "duree_s": 0.0,
                                   "erreurs": [], "fichier": res}
        try:
            erreurs = valider_spec(spec, verif)
            texte = None if erreurs else scene_write(spec, verif)
        except ErreurSpec as exc:
            erreurs = [{"fichier": res, "ligne": None, "categorie": "valeur_invalide", "message": str(exc)}]
        if erreurs:
            verdict["erreurs"] = erreurs
            return _compact(_verdict_court(verdict))
        fichier = self.disque(res)
        avant = lire_texte(fichier) if fichier.is_file() else None
        with tempfile.TemporaryDirectory(prefix="usine_scene_") as tmp:
            copie = preparer_copie(self.projet, Path(tmp) / "projet")
            cible = res_vers_disque(copie, res)
            cible.parent.mkdir(parents=True, exist_ok=True)
            with cible.open("w", encoding="utf-8", newline="") as f:
                f.write(texte)
            jugement = juges.load_scene(cible, copie, self.godot)
        verdict.update({k: jugement[k] for k in ("etape", "duree_s", "erreurs")})
        if jugement["ok"]:
            _remplacer_atomiquement(self.projet, {res: texte}, {res: avant})
            verdict["ok"] = verdict["applique"] = True
        return _compact(_verdict_court(verdict))

    # --- projet
    def describe_project(self) -> str:
        from usine.projet.decrire import describe_project
        return describe_project(self.projet)["texte"]

    def apply_edits(self, edits: list[dict[str, Any]]) -> str:
        from usine.projet.editions import apply_edits
        return _compact(_verdict_court(apply_edits(self.projet, list(edits), godot=self.godot)))

    # --- juges (sur une copie jetable)
    def _sur_copie(self, action) -> dict[str, Any]:
        from usine.juge.projet import preparer_copie
        with tempfile.TemporaryDirectory(prefix="usine_mcp_") as tmp:
            return action(preparer_copie(self.projet, Path(tmp) / "projet"))

    def check_script(self, chemin: str) -> str:
        from usine.juge import godot as juges
        res = self.res(chemin)
        if not self.disque(res).is_file():
            raise ErreurOutil(f"script absent : {res}")
        return _compact(_verdict_court(self._sur_copie(lambda c: juges.check_script(res, c, self.godot))))

    def load_scene(self, chemin: str) -> str:
        from usine.juge import godot as juges
        res = self.res(chemin)
        if not self.disque(res).is_file():
            raise ErreurOutil(f"scène absente : {res}")
        return _compact(_verdict_court(self._sur_copie(lambda c: juges.load_scene(res, c, self.godot))))

    def run_tests(self, filtre: str | None = None) -> str:
        from usine.juge import godot as juges
        cible = self.res(filtre) if filtre else "res://tests"
        if not self.disque(cible).exists():
            raise ErreurOutil(f"tests absents : {cible}")
        return _compact(_verdict_court(self._sur_copie(lambda c: juges.run_tests(c, cible, self.godot))))


def _signature(m: dict[str, Any]) -> str:
    if "valeurs" in m:
        return m["nom"] + "{" + ",".join(v["nom"] for v in m["valeurs"]) + "}"
    if "valeur" in m:
        return f"{m['nom']}={m['valeur']}"
    if "arguments" in m:
        args = ", ".join(f"{a['nom']}: {a['type']}" + (f"={a['defaut']}" if a.get("defaut") not in (None, "") else "")
                         for a in m["arguments"])
        retour = f" -> {m['retour']}" if m.get("retour") else ""
        return f"{m['nom']}({args}{', ...' if m.get('vararg') else ''}){retour}"
    return f"{m['nom']}: {m['type']}"
