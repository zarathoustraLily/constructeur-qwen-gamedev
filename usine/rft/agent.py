"""Agent minimal maison : deuxième harness des compétences agentiques (et repli d'OpenCode).

Il sert uniquement à produire des données d'entraînement (session 5) : ce n'est pas un
orchestrateur autour de Qwen à l'usage (règle 1). Qwen y dispose des mêmes outils que dans
OpenCode :
  - les outils du serveur MCP `usine-godot`, avec leurs définitions exactes (lues sur le serveur
    FastMCP) et leur implémentation (mcp_serveur.outils.Outils, sur la copie de travail) ;
  - trois outils de fichiers, l'équivalent des outils intégrés d'OpenCode : list_files,
    read_file, write_file (chemins limités au projet).
La fiche de la compétence (skills/usine-*/SKILL.md) est donnée dans le message système.

Boucle : un appel au modèle, puis chaque appel d'outil demandé ; la session finit quand le modèle
répond sans appel d'outil, ou au bout du budget de pas (même budget pour tous les essais).
"""

from __future__ import annotations

import asyncio
import json
from functools import lru_cache
from pathlib import Path
from typing import Any, Callable

from usine import config as cfg
from usine.mesure.client import ErreurAppel, Reglages, Reponse, completer

MAX_CAR_RESULTAT = 20000
SYSTEME = ("Tu es un développeur Godot 4.7 (GDScript typé) qui travaille dans un projet existant, avec des "
           "outils. Vérifie toute classe, propriété, signal ou méthode avec vocab_lookup avant de l'écrire. "
           "Modifie le projet avec les outils, lance run_tests pour vérifier, puis termine par un court message "
           "sans appel d'outil quand la tâche est faite.")

OUTILS_FICHIERS: list[dict[str, Any]] = [
    {"type": "function", "function": {
        "name": "list_files", "description": "Liste les fichiers du projet (res://), hors addons et .godot.",
        "parameters": {"type": "object", "properties": {}}}},
    {"type": "function", "function": {
        "name": "read_file", "description": "Lit un fichier texte du projet.",
        "parameters": {"type": "object", "properties": {"chemin": {"type": "string"}}, "required": ["chemin"]}}},
    {"type": "function", "function": {
        "name": "write_file", "description": "Écrit (ou remplace) un fichier texte du projet.",
        "parameters": {"type": "object", "properties": {"chemin": {"type": "string"}, "contenu": {"type": "string"}},
                       "required": ["chemin", "contenu"]}}},
]


@lru_cache(maxsize=1)
def definitions_mcp() -> tuple[str, ...]:
    """Définitions des outils du serveur MCP, au format « tools » d'OpenAI (JSON, une par outil)."""
    from mcp_serveur.serveur import creer_serveur
    serveur = creer_serveur(cfg.RACINE / "godot" / "reference")
    outils = asyncio.run(serveur.list_tools())
    return tuple(json.dumps({"type": "function", "function": {
        "name": t.name, "description": t.description or "", "parameters": t.inputSchema}}, ensure_ascii=False)
        for t in sorted(outils, key=lambda t: t.name))


def definitions() -> list[dict[str, Any]]:
    return [json.loads(d) for d in definitions_mcp()] + json.loads(json.dumps(OUTILS_FICHIERS))


def fiche(competence: str) -> str:
    """Texte de la fiche de compétence (sans l'en-tête YAML), ou chaîne vide."""
    for f in sorted((cfg.RACINE / "skills").glob(f"usine-{competence.lower()}-*/SKILL.md")):
        texte = f.read_text(encoding="utf-8")
        if texte.startswith("---"):
            texte = texte.split("---", 2)[-1]
        return texte.strip()
    return ""


class Boite:
    """Exécute les appels d'outils sur un projet (la copie de travail de l'essai)."""

    def __init__(self, projet: Path):
        from mcp_serveur.outils import Outils
        self.projet = Path(projet).resolve()
        self.outils = Outils(self.projet)
        self.noms_mcp = {json.loads(d)["function"]["name"] for d in definitions_mcp()}

    def list_files(self) -> str:
        fichiers = sorted((p.relative_to(self.projet).as_posix() for p in self.projet.rglob("*")
                           if p.is_file() and p.relative_to(self.projet).parts[0] not in ("addons", ".godot")
                           and not p.name.endswith((".uid", ".import"))), key=lambda s: s.split("/"))
        return "\n".join(f"res://{f}" for f in fichiers)

    def read_file(self, chemin: str) -> str:
        disque = self.outils.disque(chemin)
        if not disque.is_file():
            return f"Erreur : fichier absent : {self.outils.res(chemin)}"
        with disque.open(encoding="utf-8", newline="") as f:
            return f.read()

    def write_file(self, chemin: str, contenu: str) -> str:
        res = self.outils.res(chemin)
        if res.startswith(("res://addons/", "res://.godot/")):
            return f"Erreur : chemin réservé : {res}"
        disque = self.outils.disque(chemin)
        disque.parent.mkdir(parents=True, exist_ok=True)
        with disque.open("w", encoding="utf-8", newline="") as f:
            f.write(contenu)
        return f"écrit : {res} ({len(contenu)} caractères)"

    def appeler(self, nom: str, arguments: dict[str, Any]) -> str:
        try:
            if nom in ("list_files", "read_file", "write_file"):
                resultat = getattr(self, nom)(**arguments)
            elif nom in self.noms_mcp:
                resultat = getattr(self.outils, nom)(**arguments)
            else:
                return f"Erreur : outil inconnu : {nom}"
        except TypeError as exc:
            return f"Erreur : arguments invalides pour {nom} : {exc}"
        except Exception as exc:  # l'erreur d'un outil est rendue au modèle, comme dans OpenCode
            return f"Erreur : {exc}"
        texte = resultat if isinstance(resultat, str) else json.dumps(resultat, ensure_ascii=False)
        return texte if len(texte) <= MAX_CAR_RESULTAT else texte[:MAX_CAR_RESULTAT] + "\n[…tronqué]"


def message_assistant(rep: Reponse) -> dict[str, Any]:
    """Message assistant normalisé (format chat OpenAI) : content, et tool_calls s'il y en a."""
    brut = rep.message or {}
    m: dict[str, Any] = {"role": "assistant", "content": brut.get("content") or rep.contenu or ""}
    appels = []
    for n, c in enumerate(brut.get("tool_calls") or []):
        f = c.get("function") or {}
        args = f.get("arguments")
        appels.append({"id": c.get("id") or f"appel_{n}", "type": "function",
                       "function": {"name": f.get("name", ""),
                                    "arguments": args if isinstance(args, str) else json.dumps(args or {}, ensure_ascii=False)}})
    if appels:
        m["tool_calls"] = appels
    return m


def resoudre(projet: Path, consigne: str, competence: str, client: Reglages, lora: list[dict[str, Any]] | None = None,
             max_pas: int = 40, appeler: Callable[..., Reponse] = completer, exclure: tuple[str, ...] = (),
             documentation: str | None = None) -> tuple[list[dict[str, Any]], list[dict[str, Any]], str]:
    """Une session agentique sur `projet`. Renvoie (messages, définitions d'outils, fin)
    avec fin ∈ {"termine", "budget", "erreur_appel"}.
    `exclure` : outils retirés (la mesure sans RAG retire search_docs) ; `documentation` : extraits
    du RAG ajoutés à la tâche (mesure avec RAG)."""
    outils = [d for d in definitions() if d["function"]["name"] not in exclure]
    boite = Boite(projet)
    boite.noms_mcp -= set(exclure)
    systeme = SYSTEME + ("\n\nFiche de la compétence :\n" + fiche(competence) if fiche(competence) else "")
    tache = f"Tâche ({competence}) :\n{consigne}\n\nLe projet est ouvert ; ses fichiers :\n" + boite.list_files()
    if documentation:
        tache += "\n\nDocumentation Godot 4.7 (extraits trouvés pour cette tâche) :\n" + documentation
    messages: list[dict[str, Any]] = [{"role": "system", "content": systeme}, {"role": "user", "content": tache}]
    for _ in range(max_pas):
        try:
            rep = appeler(client, messages, None, lora, outils)
        except ErreurAppel as exc:
            messages.append({"role": "assistant", "content": f"[appel en échec : {exc}]"})
            return messages, outils, "erreur_appel"
        m = message_assistant(rep)
        messages.append(m)
        if not m.get("tool_calls"):
            return messages, outils, "termine"
        for appel in m["tool_calls"]:
            try:
                arguments = json.loads(appel["function"]["arguments"] or "{}")
                if not isinstance(arguments, dict):
                    raise ValueError("objet attendu")
                resultat = boite.appeler(appel["function"]["name"], arguments)
            except (json.JSONDecodeError, ValueError) as exc:
                resultat = f"Erreur : arguments JSON invalides : {exc}"
            messages.append({"role": "tool", "tool_call_id": appel["id"], "content": resultat})
    return messages, outils, "budget"
