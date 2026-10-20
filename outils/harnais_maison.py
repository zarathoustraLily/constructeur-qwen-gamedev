"""Donne une consigne libre à l'agent maison (usine/rft/agent.py) sur un projet Godot, sans le
LoRA puis avec, pour comparer les deux résultats à l'œil.

    py -3.12 outils/harnais_maison.py <dossier du projet> [--consigne "..."] [--variantes sans avec]
                                      [--rag outil|extraits|sans ...] [--competence E|K2|K3]
                                      [--max-pas 40] [--temperature 0.0]

Sans --consigne, elle est demandée au clavier. Le projet d'origine n'est jamais modifié : chaque
essai travaille sur sa propre copie, dans donnees/harnais/<horodatage>_<projet>/lora-<variante>_rag-<mode>/ :
  projet/            la copie, à ouvrir dans Godot
  journal.txt        les étapes (appels d'outils et résultats abrégés)
  session.jsonl      la session complète (en-tête, puis un message par ligne)
  changements.patch  le diff des fichiers texte par rapport au projet d'origine

RAG (--rag, plusieurs modes possibles : chaque variante est alors rejouée par mode) :
  outil     search_docs est proposé au modèle, qui choisit de l'appeler (comme à l'entraînement) ;
  extraits  en plus, les extraits trouvés pour la consigne sont ajoutés à la tâche (mesure « _rag ») ;
  sans      search_docs est retiré.
Le bilan liste les recherches faites (search_docs) et les vérifications de vocabulaire (vocab_lookup).

Le LoRA est choisi par requête (champ `lora`), llama-server restant lancé avec --lora :
[mesure].lora_ids et lora_actif de config.toml. --competence ajoute la fiche de la compétence au
message système, comme à l'entraînement ; par défaut aucune fiche (consigne libre).

Outil de comparaison manuelle : ce n'est pas un orchestrateur autour de Qwen à l'usage (règle 1).
"""

from __future__ import annotations

import argparse
import dataclasses
import difflib
import json
import shutil
import sys
import time
import urllib.request
from pathlib import Path
from typing import Any

RACINE = Path(__file__).resolve().parent.parent
if str(RACINE) not in sys.path:
    sys.path.insert(0, str(RACINE))

from usine import config as cfg  # noqa: E402
from usine.mesure.client import completer  # noqa: E402
from usine.mesure.executer import documentation, reglages_depuis_config  # noqa: E402
from usine.rft import agent  # noqa: E402

VARIANTES = ("sans", "avec")
MODES_RAG = ("outil", "extraits", "sans")
HORS_COPIE = shutil.ignore_patterns("opencode.json*")
HORS_DIFF = ("addons", ".godot")
TEXTES = (".gd", ".tscn", ".tres", ".godot", ".cfg", ".md", ".json", ".txt", ".gdshader", ".csv")


def apercu(texte: str, maxi: int = 220) -> str:
    ligne = " ".join(str(texte).split())
    return ligne if len(ligne) <= maxi else ligne[:maxi] + " …"


def adaptateurs(url: str) -> list[dict[str, Any]]:
    """Adaptateurs chargés par llama-server (GET /lora-adapters, hors du préfixe /v1)."""
    base = url.rstrip("/").removesuffix("/v1")
    with urllib.request.urlopen(f"{base}/lora-adapters", timeout=10) as r:
        return json.loads(r.read().decode("utf-8"))


def suivre(ecrire):
    """Enveloppe `completer` pour écrire chaque étape dès qu'elle arrive."""
    vus, pas = 0, 0

    def appeler(client, messages, schema, lora, outils):
        nonlocal vus, pas
        for m in messages[vus:]:
            if m["role"] == "tool":
                ecrire(f"      ← {apercu(m['content'])}")
        rep = completer(client, messages, schema, lora, outils)
        vus, pas = len(messages) + 1, pas + 1
        m = agent.message_assistant(rep)
        for c in m.get("tool_calls", []):
            ecrire(f"[pas {pas:2d}] → {c['function']['name']}({apercu(c['function']['arguments'])})")
        if not m.get("tool_calls"):
            ecrire(f"[fin, pas {pas}] {apercu(m['content'], 2000)}")
        return rep

    return appeler


def fichiers(racine: Path) -> dict[str, Path]:
    return {p.relative_to(racine).as_posix(): p for p in racine.rglob("*")
            if p.is_file() and p.relative_to(racine).parts[0] not in HORS_DIFF
            and not p.name.startswith("opencode.json") and not p.name.endswith((".uid", ".import"))}


def changements(origine: Path, copie: Path) -> tuple[list[str], str]:
    """(résumé par fichier, diff unifié des fichiers texte) de `copie` par rapport à `origine`."""
    avant, apres = fichiers(origine), fichiers(copie)
    resume, diff = [], []
    for nom in sorted(set(avant) | set(apres)):
        a, b = avant.get(nom), apres.get(nom)
        if a and b and a.read_bytes() == b.read_bytes():
            continue
        resume.append(("ajouté   " if not a else "supprimé " if not b else "modifié  ") + nom)
        if nom.endswith(TEXTES):
            lire = lambda p: p.read_text(encoding="utf-8", errors="replace").splitlines(keepends=True) if p else []  # noqa: E731
            diff += difflib.unified_diff(lire(a), lire(b), f"a/{nom}", f"b/{nom}")
    return resume, "".join(l if l.endswith("\n") else l + "\n" for l in diff)


def recherches(messages: list[dict[str, Any]]) -> dict[str, list[str]]:
    """Arguments des appels à search_docs et vocab_lookup, dans l'ordre de la session."""
    faites: dict[str, list[str]] = {"search_docs": [], "vocab_lookup": []}
    for m in messages:
        for c in m.get("tool_calls", []):
            if c["function"]["name"] in faites:
                faites[c["function"]["name"]].append(apercu(c["function"]["arguments"], 160))
    return faites


def essayer(projet: Path, dossier: Path, variante: str, rag: str, consigne: str, competence: str, r, client) -> dict[str, Any]:
    nom = f"lora-{variante}_rag-{rag}"
    copie = dossier / nom / "projet"
    shutil.copytree(projet, copie, ignore=HORS_COPIE)
    lora = [{"id": i, "scale": 1.0 if variante == "avec" and i == r.lora_actif else 0.0} for i in r.lora_ids]
    journal = (dossier / nom / "journal.txt").open("w", encoding="utf-8", newline="\n")

    def ecrire(ligne: str) -> None:
        print(ligne, flush=True)
        journal.write(ligne + "\n")
        journal.flush()

    ecrire(f"===== LoRA : {variante} | RAG : {rag} — {copie}")
    extraits = documentation(consigne, r) if rag == "extraits" else None
    debut = time.monotonic()
    try:
        messages, outils, fin = agent.resoudre(copie, consigne, competence, client, lora or None, r.max_pas,
                                               appeler=suivre(ecrire), exclure=("search_docs",) if rag == "sans" else (),
                                               documentation=extraits)
    finally:
        journal.close()
    duree = round(time.monotonic() - debut, 1)
    entete = {"consigne": consigne, "competence": competence, "projet": str(projet), "variante": variante,
              "rag": rag, "harnais": "agent", "lora": lora, "fin": fin, "duree_s": duree, "temperature": client.temperature,
              "graine": client.graine, "tools": outils}
    (dossier / nom / "session.jsonl").write_text(
        "".join(json.dumps(l, ensure_ascii=False) + "\n" for l in [entete, *messages]), encoding="utf-8", newline="\n")
    resume, diff = changements(projet, copie)
    (dossier / nom / "changements.patch").write_text(diff, encoding="utf-8", newline="\n")
    appels = sum(len(m.get("tool_calls", [])) for m in messages)
    return {"nom": nom, "fin": fin, "duree_s": duree, "appels": appels, "changements": resume, "copie": copie,
            "recherches": recherches(messages)}


def main(argv: list[str] | None = None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    p = argparse.ArgumentParser(prog="harnais_maison.py")
    p.add_argument("projet", type=Path)
    p.add_argument("--consigne")
    p.add_argument("--variantes", nargs="+", choices=VARIANTES, default=list(VARIANTES))
    p.add_argument("--rag", nargs="+", choices=MODES_RAG, default=["outil"])
    p.add_argument("--competence", default="libre", help="E, K2, K3… : ajoute la fiche au message système")
    p.add_argument("--max-pas", type=int, default=None)
    p.add_argument("--temperature", type=float, default=None)
    p.add_argument("--sortie", type=Path, default=None, help="défaut : donnees/harnais")
    a = p.parse_args(argv)

    projet = a.projet.resolve()
    if not (projet / "project.godot").is_file():
        print(f"pas de project.godot dans {projet}", file=sys.stderr)
        return 2
    r = reglages_depuis_config(cfg.charger_config())
    if a.max_pas:
        r.max_pas = a.max_pas
    client = r.client if a.temperature is None else dataclasses.replace(r.client, temperature=a.temperature)
    if "avec" in a.variantes:
        try:
            charges = {int(x["id"]) for x in adaptateurs(client.url)}
        except OSError as exc:
            print(f"llama-server injoignable ({client.url}) : {exc}", file=sys.stderr)
            return 1
        if r.lora_actif not in charges or r.lora_actif not in r.lora_ids:
            print(f"LoRA {r.lora_actif} non chargé par llama-server (--lora) ou absent de [mesure].lora_ids "
                  f"{r.lora_ids} ; adaptateurs du serveur : {sorted(charges)}", file=sys.stderr)
            return 1
    consigne = a.consigne or input("Consigne : ").strip()
    if not consigne:
        print("consigne vide", file=sys.stderr)
        return 2

    dossier = (a.sortie or cfg.dossier_donnees() / "harnais") / f"{time.strftime('%Y%m%d-%H%M%S')}_{projet.name}"
    bilans = [essayer(projet, dossier, v, rag, consigne, a.competence, r, client)
              for rag in a.rag for v in a.variantes]
    print("\n===== BILAN")
    for b in bilans:
        print(f"{b['nom']} : fin « {b['fin']} », {b['appels']} appels d'outils, {b['duree_s']} s")
        for outil, faites in b["recherches"].items():
            print(f"    {outil} : {len(faites)} appel(s)")
            for f in faites:
                print(f"        {f}")
        for c in b["changements"] or ["(aucun fichier changé)"]:
            print(f"    {c}")
        print(f"    copie à ouvrir dans Godot : {b['copie']}")
    print(f"\nJournaux, sessions et diffs : {dossier}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
