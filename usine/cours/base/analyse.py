"""Exemples d'analyse tirés des sessions de débogage vérifiées (décision 3 : 40/40/20 ; étape A2 du suivi).

Une session de débogage lance Godot, lit sa sortie réelle et le code autour de la faute, cherche la cause, puis
corrige. Son exemple d'analyse reprend ce début tel quel (mêmes commandes, mêmes sorties, même lecture), sur une
demande d'analyse — « dis-moi ce qui ne va pas, sans rien modifier » — et finit par le diagnostic : la cause
(« Chercher », le texte de la session) et les lignes à changer, données en texte au lieu d'être éditées. Rien n'est
relancé : tout vient de la session, qui a vérifié que ces changements font disparaître ces erreurs-là. Une faute de
syntaxe peut en cacher d'autres : la session le dit déjà dans « Lire » ; l'analyse finit en demandant de relancer.
"""

from __future__ import annotations

import copy
import re
from pathlib import PureWindowsPath

from usine.cours.base import composer, etat, jetons, opencode

CORRIGER_OC = " Corrige ce qui ne va pas."
ANALYSER_OC = " Dis-moi ce qui ne va pas et ce qu'il faudrait changer, sans rien modifier."
CORRIGER_NEUTRE = re.compile(r"Corrige jusqu'à ce que tout passe : [^\n]*$")
ANALYSER_NEUTRE = "Dis-moi ce qui ne va pas et ce qu'il faudrait changer, sans rien modifier."
FIN = "Je n'ai rien modifié. Après ce changement, relancer la même commande pour vérifier."


class PasDAnalyse(Exception):
    """La session n'a pas la forme attendue (lire, puis éditer) : pas d'exemple d'analyse."""


def _a_changer(editions: list[tuple[str, str, str]]) -> str:
    """editions : (chemin res://, texte fautif, texte juste)."""
    tete = "**À changer.** " + ("Une seule ligne :" if len(editions) == 1 else f"{len(editions)} passages :")
    blocs = [tete]
    for res, faux, juste in editions:
        langue = composer.langage(res.removeprefix("res://"))
        blocs += [f"Dans `{res}`, remplacer :", f"```{langue}\n{faux}\n```", "par :", f"```{langue}\n{juste}\n```"]
    return "\n".join(blocs)


def _version_opencode(e: dict, dossier: str) -> tuple[dict, list[tuple[str, str, str]]]:
    oc = e["opencode"]
    ms = oc["messages"]
    k_edit = next((k for k, m in enumerate(ms) if m["role"] == "assistant"
                   and any(tc["function"]["name"] == "edit" for tc in m.get("tool_calls") or [])), None)
    if k_edit is None or k_edit < 3 or ms[k_edit - 1]["role"] != "tool" \
            or not ms[k_edit - 1]["content"].startswith("Read file "):
        raise PasDAnalyse(f"{e['id']} : pas de lecture juste avant la première édition")
    if CORRIGER_OC not in ms[1]["content"]:
        raise PasDAnalyse(f"{e['id']} : demande de correction introuvable")
    editions = []
    k = k_edit
    while k < len(ms) and ms[k]["role"] == "assistant" and ms[k].get("tool_calls") \
            and all(tc["function"]["name"] == "edit" for tc in ms[k]["tool_calls"]):
        for tc in ms[k]["tool_calls"]:
            a = tc["function"]["arguments"]
            rel = PureWindowsPath(a["path"]).relative_to(PureWindowsPath(dossier)).as_posix()
            editions.append((f"res://{rel}", a["oldString"], a["newString"]))
        k += 2  # l'appel, puis son retour
    texte = ms[k_edit]["content"]
    if "\n\n**Corriger.**" not in texte:
        raise PasDAnalyse(f"{e['id']} : « Corriger » introuvable")
    chercher = texte.split("\n\n**Corriger.**")[0]
    messages = copy.deepcopy(ms[:k_edit])
    messages[1]["content"] = messages[1]["content"].replace(CORRIGER_OC, ANALYSER_OC)
    messages.append({"role": "assistant", "content": f"{chercher}\n\n{_a_changer(editions)}\n\n{FIN}"})
    nouveau = {"messages": messages, "tools": oc["tools"]}
    nouveau["jetons"], nouveau["jetons_reponse"] = opencode.compter(jetons.tokenizer(), messages, oc["tools"])
    return nouveau, editions


def _version_neutre(e: dict) -> list[dict]:
    ms = e["messages"]
    if not CORRIGER_NEUTRE.search(ms[1]["content"]) or "\n\n**Corriger.**" not in ms[2]["content"]:
        raise PasDAnalyse(f"{e['id']} : forme neutre inattendue")
    debut, corriger = ms[2]["content"].split("\n\n**Corriger.**", 1)
    corriger = corriger.split("\n\n**Tester.**")[0]
    corriger = re.sub(r", je remplace :$", ", remplacer :", corriger, flags=re.M)
    return [dict(ms[0]), {"role": "user", "content": CORRIGER_NEUTRE.sub(ANALYSER_NEUTRE, ms[1]["content"])},
            {"role": "assistant", "content": f"{debut}\n\n**À changer.**{corriger}\n\n{FIN}"}]


def depuis_session(e: dict, h: opencode.Harnais) -> dict:
    """L'exemple d'analyse d'une session de débogage ; PasDAnalyse si sa forme ne s'y prête pas."""
    if e["type"] != "debogage":
        raise PasDAnalyse(f"{e['id']} : pas une session de débogage")
    oc, editions = _version_opencode(e, h.dossier(etat.nom(e["ville"], e["etape"])))
    return {"id": e["id"].replace("-debogage-", "-analyse-"),
            "ville": e["ville"], "etape": e["etape"], "type": "analyse", "messages": _version_neutre(e),
            "opencode": oc, "genres": e["genres"], "nb_erreurs": e["nb_erreurs"],
            "preuves": {"ok": e["preuves"]["ok"], "tiree_de": e["id"], "editions": len(editions),
                        "mutations": e["preuves"]["mutations"], "vues": [], "commandes": []}}


def deriver(exemples: list[dict], h: opencode.Harnais) -> tuple[list[dict], list[str]]:
    """Un exemple d'analyse par session de débogage qui s'y prête ; rend aussi les sessions écartées et pourquoi."""
    analyses, ecartees = [], []
    for e in exemples:
        if e["type"] != "debogage":
            continue
        try:
            analyses.append(depuis_session(e, h))
        except PasDAnalyse as exc:
            ecartees.append(str(exc))
    return analyses, ecartees
