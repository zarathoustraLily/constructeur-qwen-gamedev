"""Vérifier avant d'écrire (plan « qualité maximale », point A ; laurent, 2026-11-19 : « reparer les paires deja
existante avec a verificiation systematique de l'exisztence d'une fonction ou la recherche dans le RAG de la fonction
necessaire c'est quand meme la bbase »).

Toute paire dont la réponse écrit un membre de Godot qu'elle n'a pas sous les yeux (absent de la demande et des
retours d'outils qui précèdent) le vérifie d'abord, comme à l'usage dans OpenCode : un appel `execute` du Code Mode,
`tools["usine-godot"].vocab_lookup({ classe, membre })` pour un membre de classe, `search_docs` pour une fonction
globale, puis la vraie sortie de l'outil (celle que rend le serveur MCP de l'usine, `mcp_serveur/outils.py`). La
réponse cite ce que l'outil a rendu, puis écrit.

Le tour s'insère avant la partie de la réponse qui écrit (« **Corriger.** », « **Écrire.** », « **À changer.** ») ;
le reste de la paire ne change pas. Une paire du palier 1 qui ne tient plus en 1 024 jetons passe au palier 2 avec le
plan (section 3) si elle y tient ; sinon elle reste telle quelle (rien n'est tronqué, règle 7.5) et le compte le dit.
Une paire qui vérifie déjà (un appel `vocab_lookup` ou `search_docs`) n'est pas touchée.

C'est une étape du générateur : `format.ecrire` la fait passer à chaque famille (règle 5 : on corrige le générateur,
puis on refabrique).
"""

from __future__ import annotations

import json
import re
from typing import Any

PLAFONDS = {1: 1024, 2: 2048}
PLAFOND_IMAGES = 2040
AU_PLUS = 2
VOCAB = 'return await tools["usine-godot"].vocab_lookup({{ classe: "{classe}", membre: "{membre}" }});'
RAG = 'return await tools["usine-godot"].search_docs({{ requete: "{requete}", n: 1 }});'
MARQUES = ("**Corriger", "**Écrire", "**À changer", "**Remplacer")
TRIVIAUX = {"x", "y", "z", "w", "r", "g", "b", "a", "new"}
COMPTES: dict[str, int] = {}


def _compter(cle: str) -> None:
    COMPTES[cle] = COMPTES.get(cle, 0) + 1


def _deja_verifiee(p: dict[str, Any]) -> bool:
    for m in p["messages"]:
        for tc in m.get("tool_calls") or []:
            arguments = json.dumps(tc["function"].get("arguments"), ensure_ascii=False)
            if "vocab_lookup" in arguments or "search_docs" in arguments:
                return True
    return False


def _visible_avant(p: dict[str, Any], i: int) -> str:
    """Ce que la réponse a sous les yeux avant le message `i` : la demande et les retours d'outils."""
    return "\n".join(m.get("content") or "" for m in p["messages"][:i] if m["role"] in ("user", "tool"))


TYPE_DECL = re.compile(r"\b(\w+)\s*:\s*([A-Z]\w*)\b(?!\s*\()")
CONSTRUIT = re.compile(r"\bvar\s+(\w+)\s*:?=\s*([A-Z]\w*)(?:\.new)?\(")
COMME = re.compile(r"\bvar\s+(\w+)\s*:?=\s*.+?\bas\s+([A-Z]\w*)\s*$", re.M)
APPEL_PROJET = re.compile(r"\bvar\s+(\w+)\s*:=\s*(?:self\.)?(\w+)\(")
RETOUR = re.compile(r"\bfunc\s+(\w+)\([^)]*\)\s*->\s*([A-Z]\w*)\s*:")
EXTENDS = re.compile(r"^(?:class_name\s+\w+\s+)?extends\s+([A-Z]\w*)\s*$", re.M)
ACCES = re.compile(r"(?<![\w$%&^])([A-Za-z_]\w*)\.([A-Za-z_]\w*)\b")
NU = re.compile(r"(?<![\w.$%&^\"'])([a-z_][a-z0-9_]*)\b(?!\s*:(?!=))")
DECLARE = re.compile(r"\b(?:func|var|const|signal|enum|class|for)\s+([A-Za-z_]\w*)|\b(\w+)\s*:\s*[A-Z]\w*")
MOTS = {"self", "super", "not", "and", "or", "in", "if", "else", "elif", "for", "while", "return", "var", "true",
        "false", "null", "pass", "is", "as", "match", "await", "func", "static", "const", "break", "continue", "when"}


def _types(texte: str) -> dict[str, str]:
    """Le type de chaque nom du texte qui en a un connu de l'API : déclaré (`x: T`), construit (`T(…)`, `T.new()`),
    converti (`… as T`), ou rendu par une fonction du projet déclarée `-> T`."""
    from usine.cours.base import api
    vus: dict[str, set[str]] = {}
    declares: set[str] = set()
    retours = dict(RETOUR.findall(texte))
    for motif in (TYPE_DECL, CONSTRUIT, COMME):
        for nom, t in motif.findall(texte):
            declares.add(nom)
            if api.classe_existe(t):
                vus.setdefault(nom, set()).add(t)
    for nom, f in APPEL_PROJET.findall(texte):
        declares.add(nom)
        if api.classe_existe(retours.get(f, "")):
            vus.setdefault(nom, set()).add(retours[f])
    # Un nom qui reçoit plusieurs types (deux fonctions, deux variables homonymes) ou aussi un type du projet n'a pas
    # de type sûr : on ne lui en prête aucun (un `aim: Vector2` ici, `aim := Vector3(…)` là).
    autres = {nom for nom, t in TYPE_DECL.findall(texte) if not api.classe_existe(t)}
    return {nom: next(iter(t)) for nom, t in vus.items() if len(t) == 1 and nom not in autres}


def membres_ecrits(code: str, contexte: str) -> list[tuple[str, str]]:
    """(classe d'origine, membre) des membres de Godot que `code` emploie, et (« @GlobalScope », f) des fonctions
    globales, dans l'ordre où ils apparaissent."""
    from usine.cours.base import api
    from usine.paires.rag import MATHS
    from usine.paires.symboles import _sans_chaines_ni_commentaires
    propre = _sans_chaines_ni_commentaires(code, shader=False)
    tout = contexte + "\n" + code
    types = _types(tout)
    base = next((b for b in EXTENDS.findall(tout) if api.classe_existe(b)), None)
    declares = {a or b for a, b in DECLARE.findall(tout)}
    trouves: list[tuple[int, str, str]] = []
    for x in ACCES.finditer(propre):
        recepteur, membre = x.group(1), x.group(2)
        classe = recepteur if api.classe_existe(recepteur) else types.get(recepteur)
        if classe and membre not in TRIVIAUX:
            r = api.membre(classe, membre)
            if r:
                trouves.append((x.start(2), r[1], membre))
    if base:
        for x in NU.finditer(propre):
            nom = x.group(1)
            if nom in MOTS or nom in declares or nom in types or api.utilitaire(nom):
                continue
            r = api.membre(base, nom)
            if r:
                trouves.append((x.start(1), r[1], nom))
    for x in re.finditer(r"(?<![.\w])([a-z_]\w*)\s*\(", propre):
        nom = x.group(1)
        if nom not in MATHS and nom not in api.BANALES and nom not in declares and api.utilitaire(nom):
            trouves.append((x.start(1), "@GlobalScope", nom))
    sortie: list[tuple[str, str]] = []
    for _, classe, membre in sorted(trouves):
        if (classe, membre) not in sortie:
            sortie.append((classe, membre))
    return sortie


def a_verifier(p: dict[str, Any], i: int) -> list[tuple[str, str]]:
    """(classe ou « @GlobalScope », membre) des membres de Godot que la réponse écrit sans les avoir sous les yeux."""
    from usine.paires.symboles import code_ecrit
    vus_avant = _visible_avant(p, i)
    ecrit = [c for langage, c in code_ecrit({"messages": p["messages"][i:]}) if langage == "gdscript"]
    if not ecrit:
        return []
    # Sous les yeux : employé dans le code déjà montré (blocs de code de la demande, retours d'outils), pas seulement
    # cité dans la prose (« la longueur », un commentaire `## … length …` ne prouvent pas que le membre existe).
    code_vu = "\n".join(re.findall(r"```[\w+-]*\n(.*?)```", vus_avant, re.S)) + "\n" + "\n".join(
        m.get("content") or "" for m in p["messages"][:i] if m["role"] == "tool")
    from usine.paires.symboles import _sans_chaines_ni_commentaires
    code_vu = _sans_chaines_ni_commentaires(code_vu, shader=False)
    neufs = [(c, m) for c, m in membres_ecrits("\n".join(ecrit), vus_avant)
             if not re.search(rf"(?:\.|\b){re.escape(m)}\b(?!\s*:)", code_vu)]
    # Les membres des classes du moteur d'abord, puis les fonctions globales.
    return ([x for x in neufs if x[0] != "@GlobalScope"] + [x for x in neufs if x[0] == "@GlobalScope"])[:AU_PLUS]


def _sortie_outil(classe: str, membre: str) -> tuple[str, str, str] | None:
    """(code de l'appel, vraie sortie, ce qu'elle confirme) ou None si l'outil ne confirme pas le membre."""
    if classe == "@GlobalScope":
        from usine.paires.rag import bloc, ce_que_dit, chercher
        requete = f"@GlobalScope.{membre}"
        sortie = chercher(requete, 1)
        b = bloc(sortie, requete)
        if not b:
            return None
        signature, _ = ce_que_dit(b)
        return RAG.format(requete=requete), sortie, signature or membre
    from mcp_serveur.outils import Outils
    sortie = Outils.vocab_lookup(None, classe, membre)  # n'emploie pas le projet : l'API 4.7.2 seule
    if sortie.startswith("Classe inconnue") or "n'a aucun membre" in sortie:
        return None
    return VOCAB.format(classe=classe, membre=membre), sortie, sortie.split("\n")[0]


def _palier(p: dict[str, Any]) -> int | None:
    from usine.paires import format as fmt
    systeme = p["messages"][0]["role"] == "system"
    if not systeme:
        return 1 if p["jetons"] <= PLAFONDS[1] else None
    if p["messages"][0]["content"] != fmt.plan():
        return None
    return 2 if p["jetons"] <= (PLAFOND_IMAGES if p["images"] else PLAFONDS[2]) else None


VERIFIER = "**Vérifier l'API.**"
LU = "**Lu.** "


def retirer(p: dict[str, Any]) -> dict[str, Any]:
    """La paire sans l'étape ajoutée par `ajouter` (les messages d'avant, sans le plan qu'elle aurait fait ajouter) :
    pour les familles qui la reprennent avec un autre outil (la famille RAG cherche dans la documentation)."""
    msgs = p.get("messages") or []
    i = next((k for k, m in enumerate(msgs) if m["role"] == "assistant" and VERIFIER in (m.get("content") or "")),
             None)
    if i is None:
        return p
    ids = {tc["id"] for tc in msgs[i].get("tool_calls") or []}
    j = i + 1
    while j < len(msgs) and msgs[j]["role"] == "tool" and msgs[j].get("tool_call_id") in ids:
        j += 1
    if j >= len(msgs) or msgs[j]["role"] != "assistant" or not (msgs[j].get("content") or "").startswith(LU):
        return p
    avant = msgs[i]["content"][:msgs[i]["content"].index(VERIFIER)].rstrip()
    reste = msgs[j]["content"].split("\n\n", 1)
    apres = reste[1] if len(reste) > 1 else ""
    suite = dict(msgs[j], content=(avant + "\n\n" if avant else "") + apres)
    messages = msgs[:i] + [suite] + msgs[j + 1:]
    preuve = {k: v for k, v in (p.get("preuve") or {}).items() if k != "verification_api"}
    return dict(p, messages=messages, preuve=preuve)


def ajouter(p: dict[str, Any]) -> dict[str, Any]:
    """La paire avec sa vérification de l'API, ou la paire telle quelle (déjà vérifiée, rien à vérifier, trop
    longue)."""
    from usine.paires import format as fmt
    if "messages" not in p or _deja_verifiee(p):
        return p
    i = next((k for k, m in enumerate(p["messages"]) if m["role"] == "assistant"), None)
    if i is None:
        return p
    from usine.cours.base import chemins
    try:
        chemins.actuels()
    except Exception:  # noqa: BLE001 — une famille hors cours (plomberie) : l'API 4.7.2 est la même pour tous
        chemins.configurer(cours="kart")
    try:
        membres = a_verifier(p, i)
    except Exception:  # noqa: BLE001 — API ou cours non configurés : la paire reste telle quelle, le compte le dit
        _compter("non vérifiable (API ou cours absents)")
        return p
    if not membres:
        _compter("rien à vérifier")
        return p
    appels, retours, confirme = [], [], []
    for k, (classe, membre) in enumerate(membres):
        r = _sortie_outil(classe, membre)
        if r is None:
            _compter("membre non confirmé par l'outil (paire laissée)")
            return p
        code, sortie, ce_qui = r
        ident = f"verif_api_{k}"
        appels.append(fmt.appel(ident, "execute", {"code": code}))
        retours.append({"role": "tool", "tool_call_id": ident, "content": sortie})
        nom = membre if classe == "@GlobalScope" else f"{classe}.{membre}"
        confirme.append(f"`{nom}` existe : `{ce_qui.strip()}`")
    texte = p["messages"][i].get("content") or ""
    coupe = min((texte.find(m) for m in MARQUES if texte.find(m) >= 0), default=-1)
    avant, apres = (texte[:coupe].rstrip(), texte[coupe:]) if coupe >= 0 else ("", texte)
    noms = ", ".join(f"`{m if c == '@GlobalScope' else c + '.' + m}`" for c, m in membres)
    verifier = (avant + "\n\n" if avant else "") + (f"**Vérifier l'API.** Avant d'écrire, je vérifie dans l'API de "
                                                   f"Godot 4.7.2 ce que je vais employer : {noms}.")
    suite = dict(p["messages"][i])
    suite["content"] = "**Lu.** " + " ; ".join(confirme) + ".\n\n" + apres
    messages = p["messages"][:i] + [{"role": "assistant", "content": verifier, "tool_calls": appels}, *retours,
                                    suite] + p["messages"][i + 1:]
    q = dict(p, messages=messages)
    q["jetons"] = fmt.jetons(messages, p["images"])
    q["jetons_reponse"] = fmt.jetons_reponse(messages)
    q["preuve"] = dict(p.get("preuve") or {}, verification_api=[f"{c}.{m}" for c, m in membres])
    n = _palier(q)
    if n is None and messages[0]["role"] != "system":
        avec_plan = [{"role": "system", "content": fmt.plan()}] + messages
        q = dict(q, messages=avec_plan, jetons=fmt.jetons(avec_plan, p["images"]))
        q["jetons_reponse"] = fmt.jetons_reponse(avec_plan)
        n = _palier(q)
        if n == 2:
            _compter("vérifiée, passée au palier 2")
            return q
    if n is None:
        _compter("trop longue avec la vérification (paire laissée)")
        return p
    _compter(f"vérifiée, palier {n}")
    return q
