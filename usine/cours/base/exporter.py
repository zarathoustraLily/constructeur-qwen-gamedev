"""Écrit la base : JSONL au format chat (messages), version sharegpt pour LLaMA-Factory, et une version lisible."""
from __future__ import annotations

import json
import os


def competence(e: dict) -> str:
    return "K2" if e["type"] == "creation" else "K3"


def sujet(e: dict) -> str:
    texte = "\n".join(m["content"] for m in e["messages"] if m["role"] == "assistant")
    return "shaders" if texte.count(".gdshader") > texte.count(".gd`") else "procédural"


def ligne_chat(e: dict) -> dict:
    return {"messages": e["messages"], "tache_id": e["id"], "competence": competence(e), "sujet": sujet(e),
            "type": e["type"], "ville": e["ville"], "etape": e["etape"]}


def ligne_sharegpt(e: dict) -> dict:
    systeme = "\n\n".join(m["content"] for m in e["messages"] if m["role"] == "system")
    tours = [{"from": "human" if m["role"] == "user" else "gpt", "value": m["content"]}
             for m in e["messages"] if m["role"] in ("user", "assistant")]
    return {"conversations": tours, "system": systeme, "tache_id": e["id"]}


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
    info = {nom: {"file_name": f"{nom}_sharegpt.jsonl", "formatting": "sharegpt",
                  "columns": {"messages": "conversations", "system": "system"},
                  "tags": {"role_tag": "from", "content_tag": "value", "user_tag": "human", "assistant_tag": "gpt"}}}
    with open(chemins["info"], "w", encoding="utf-8", newline="\n") as f:
        f.write(json.dumps(info, ensure_ascii=False, indent=2) + "\n")
    return chemins


def lisible(exemples: list[dict], chemin: str, titre: str) -> str:
    morceaux = [f"# {titre}", "", f"{len(exemples)} exemples. Le message système est le même pour tous ; il est donné une fois.", "",
                "## Message système", "", "````text", exemples[0]["messages"][0]["content"], "````", ""]
    for e in exemples:
        tours = e["messages"][1:]
        if e["type"] == "creation":
            titre_ex = f"création, {len(tours)} tours" if len(tours) > 2 else "création"
        else:
            nb = e.get("nb_erreurs", 1)
            titre_ex = f"session de débogage, {nb} erreur{'s' if nb > 1 else ''}, {len(tours)} tours"
        morceaux += [f"## {e['id']} ({titre_ex})", ""]
        if len(tours) == 2:
            morceaux += ["### Prompt (user)", "", tours[0]["content"], "", "### Réponse (assistant)", "",
                         tours[1]["content"], ""]
        else:
            for k, m in enumerate(tours, 1):
                qui = "user : sortie ou demande" if m["role"] == "user" else "assistant"
                morceaux += [f"### Tour {k} ({qui})", "", m["content"], ""]
        morceaux += ["---", ""]
    with open(chemin, "w", encoding="utf-8", newline="\n") as h:
        h.write("\n".join(morceaux))
    return chemin
