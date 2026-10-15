"""Écrit la base au format d'OpenCode (règle 7.4) : JSONL au format chat (messages et outils, pour Unsloth ou tout
entraîneur qui applique le gabarit de Qwen 3.8), version sharegpt pour LLaMA-Factory (appels d'outils écrits dans
la réponse comme le gabarit les écrit), et une version lisible."""
from __future__ import annotations

import json
import os

from usine.cours.base import opencode


def competence(e: dict) -> str:
    return "K2" if e["type"] == "creation" else "K3"


def sujet(e: dict) -> str:
    texte = "\n".join(m["content"] for m in e["messages"] if m["role"] == "assistant")
    return "shaders" if texte.count(".gdshader") > texte.count(".gd`") else "procédural"


def ligne_chat(e: dict) -> dict:
    oc = e["opencode"]
    return {"messages": oc["messages"], "tools": oc["tools"], "tache_id": e["id"], "competence": competence(e),
            "sujet": sujet(e), "type": e["type"], "ville": e["ville"], "etape": e["etape"]}


def ligne_sharegpt(e: dict) -> dict:
    oc = e["opencode"]
    ligne = opencode.vers_sharegpt(oc["messages"], oc["tools"])
    ligne["tache_id"] = e["id"]
    return ligne


def ecrire(exemples: list[dict], dossier: str, nom: str) -> dict[str, str]:
    os.makedirs(dossier, exist_ok=True)
    chemins = {
        "chat": os.path.join(dossier, f"{nom}.jsonl"),
        "sharegpt": os.path.join(dossier, f"{nom}_sharegpt.jsonl"),
        "info": os.path.join(dossier, "dataset_info.json"),
    }
    with open(chemins["chat"], "w", encoding="utf-8", newline="\n") as f:
        for e in exemples:
            f.write(json.dumps(ligne_chat(e), ensure_ascii=False) + "\n")
    with open(chemins["sharegpt"], "w", encoding="utf-8", newline="\n") as f:
        for e in exemples:
            f.write(json.dumps(ligne_sharegpt(e), ensure_ascii=False) + "\n")
    # Pas de colonne « tools » : les définitions d'outils sont déjà dans le message système, telles que le gabarit
    # de Qwen 3.8 les écrit, et les appels dans les réponses.
    info = {nom: {"file_name": f"{nom}_sharegpt.jsonl", "formatting": "sharegpt",
                  "columns": {"messages": "conversations", "system": "system"},
                  "tags": {"role_tag": "from", "content_tag": "value", "user_tag": "human", "assistant_tag": "gpt"}}}
    with open(chemins["info"], "w", encoding="utf-8", newline="\n") as f:
        f.write(json.dumps(info, ensure_ascii=False, indent=2) + "\n")
    return chemins


def lisible(exemples: list[dict], chemin: str, titre: str, lignes_prompt: int = 40) -> str:
    """Les exemples tels que le modèle les voit : chaque réponse avec ses appels d'outils écrits comme le gabarit
    les écrit, chaque retour d'outil. Le prompt système d'OpenCode, commun à tous, n'est montré qu'en tête."""
    systeme = exemples[0]["opencode"]["messages"][0]["content"].split("\n")
    outils = [o["function"]["name"] for o in exemples[0]["opencode"]["tools"]]
    morceaux = [f"# {titre}", "", f"{len(exemples)} exemples, au format d'OpenCode.", "",
                f"## Prompt système d'OpenCode ({len(systeme)} lignes ; les {lignes_prompt} premières)", "",
                "Seules changent, d'un exemple à l'autre, les lignes d'environnement (dossier de travail, identifiant "
                "de session).", "", "````text", "\n".join(systeme[:lignes_prompt]), "````", "",
                "## Outils d'OpenCode", "", ", ".join(f"`{o}`" for o in outils) + ".", ""]
    for e in exemples:
        ms = e["opencode"]["messages"][1:]
        if e["type"] == "creation":
            titre_ex = f"création, {len(ms)} messages"
        else:
            nb = e.get("nb_erreurs", 1)
            titre_ex = f"session de débogage, {nb} erreur{'s' if nb > 1 else ''}, {len(ms)} messages"
        morceaux += [f"## {e['id']} ({titre_ex})", ""]
        for k, m in enumerate(ms, 1):
            if m["role"] == "user":
                morceaux += [f"### {k}. user", "", m["content"], ""]
            elif m["role"] == "assistant":
                morceaux += [f"### {k}. assistant", "", "````text", opencode.reponse_rendue(m), "````", ""]
            else:
                morceaux += [f"### {k}. retour d'outil", "", "````text", m["content"], "````", ""]
        morceaux += ["---", ""]
    with open(chemin, "w", encoding="utf-8", newline="\n") as h:
        h.write("\n".join(morceaux))
    return chemin
