"""Famille de paires « chercher dans le RAG, puis employer ce qu'il rend » (étape B6 du suivi ; décisions 18.2 et 19.7).

Une paire « écrire une fonction d'après son contrat » déjà vérifiée par les tests (`creation.py`) devient une paire en
plusieurs tours, comme à l'usage dans OpenCode :
1. la demande (la même) ;
2. la réponse annonce ce qu'elle vérifie et appelle l'outil `execute` du Code Mode, avec le code
   `return await tools["usine-godot"].search_docs({ requete: "Classe.membre", n: … });` (forme relevée par la capture
   d'OpenCode 2.1.4, étape A5) ;
3. la vraie sortie de la recherche (`usine.rag.index.search_docs`, celle que rend le serveur MCP) ;
4. la réponse écrit la fonction, en citant la signature et la première phrase que la documentation vient de rendre,
   puis lance l'analyse et les tests.

La requête vise un membre de Godot que la fonction emploie (signature lue dans `extension_api.json`) ; la paire n'est
gardée que si la page de ce membre est parmi les résultats rendus. Le code de la fonction est celui que les tests ont
jugé : l'usage de ce que le RAG rend est vérifié.

    python -m usine.paires rag
"""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any, Callable

from usine.paires import format as fmt

FAMILLE = "rag"
PLAFONDS = {1: 1024, 2: 2048}
CODE = 'return await tools["usine-godot"].search_docs({{ requete: "{requete}", n: {n} }});'
TRIVIAUX = {"x", "y", "z", "w", "r", "g", "b", "a"}  # composantes d'un vecteur ou d'une couleur : rien à vérifier
TITRE = re.compile(r"^## (\S+)  \(([^)]+)\)$", re.M)


def requetes(fonction: str, script: str) -> list[str]:
    """Les membres de Godot que la fonction emploie, `Classe.membre`, dans l'ordre de leur signature."""
    from usine.cours.base import api
    classes, autres = [], []
    for sig, _ in api.usages_gdscript(fonction.split("\n")[1:], script):
        m = re.match(r"^(?:static )?([A-Z]\w*)\.(\w+)[(:]", sig)
        if not m or m[2] in TRIVIAUX:
            continue
        cle = f"{m[1]}.{m[2]}"
        if cle not in classes + autres:
            (classes if m[1] in api._api()["classes"] else autres).append(cle)
    return classes + autres  # les membres des classes du moteur d'abord : ce qu'on vérifie le plus utilement


def chercher(requete: str, n: int) -> str:
    from usine.rag.index import formater, search_docs
    return formater(search_docs(requete, n, "tout"))


def bloc(sortie: str, requete: str) -> str | None:
    """Le bloc de la page du membre dans la sortie de la recherche, ou None s'il n'y est pas."""
    titres = list(TITRE.finditer(sortie))
    for i, t in enumerate(titres):
        if t[1] == requete:
            fin = titres[i + 1].start() if i + 1 < len(titres) else len(sortie)
            return sortie[t.start():fin].strip()
    return None


def ce_que_dit(b: str) -> tuple[str, str]:
    """(signature, première phrase) d'un bloc de membre : la ligne qui suit « méthode de … » ou « propriété de … »."""
    lignes = [l for l in b.split("\n")[1:] if l.strip()]
    signature = lignes[1].strip() if len(lignes) > 1 else ""
    # Après la signature d'une propriété, ses accesseurs (« - |void| set_… ») : la description vient ensuite.
    texte = next((l for l in lignes[2:] if l.strip() and not l.lstrip().startswith("- ")), "")
    phrase = re.split(r"(?<=\.)\s", texte.strip(), maxsplit=1)[0]
    return signature.replace("|", ""), phrase


def depuis_creation(p: dict[str, Any]) -> tuple[dict[str, Any] | None, str]:
    """La paire RAG tirée d'une paire de création, ou (None, raison)."""
    demande = next(m["content"] for m in p["messages"] if m["role"] == "user")
    reponse = p["messages"][-1]["content"]
    fonction = re.search(r"```gdscript\n(.*?)\n```", reponse, re.S)
    if not fonction:
        return None, "pas de fonction dans la réponse"
    code_f = fonction[1]
    script = re.search(r"```gdscript\n(.*?)```", demande, re.S)
    cibles = requetes(code_f, (script[1] if script else "") + "\n" + code_f)
    if not cibles:
        return None, "la fonction n'emploie aucun membre de Godot"
    nom = p["preuve"]["fonction"]
    tester = reponse[reponse.index("**Tester.**"):]
    for requete in cibles:
        for n in (2, 1):
            sortie = chercher(requete, n)
            b = bloc(sortie, requete)
            if b is None:
                continue
            signature, phrase = ce_que_dit(b)
            if not signature:
                continue
            ident = f"rag_{nom}_{n}"
            tours = [
                {"role": "user", "content": demande},
                {"role": "assistant", "content": f"Avant d'écrire `{nom}`, je vérifie `{requete}` dans la documentation :",
                 "tool_calls": [fmt.appel(ident, "execute", {"code": CODE.format(requete=requete, n=n)})]},
                {"role": "tool", "tool_call_id": ident, "content": sortie},
                {"role": "assistant", "content": "\n".join([
                    f"**D'après la documentation.** `{requete}` : `{signature}`, « {phrase} »",
                    "", f"**Écrire.** `{nom}`, d'après son contrat :", f"```gdscript\n{code_f}\n```", "", tester])},
            ]
            palier = p["preuve"].get("palier", 2)
            systeme = fmt.plan() if palier == 2 else None
            q = fmt.paire_tours(FAMILLE, p["sujet"], "création", tours,
                                dict(p["preuve"], requete=requete, n=n, page_trouvee=True, source="creation_fonction"),
                                systeme=systeme)
            if q["jetons"] <= PLAFONDS[palier]:
                return q, ""
            if palier == 1:
                # Trop long sans le plan : la même au palier 2, plan compris.
                q = fmt.paire_tours(FAMILLE, p["sujet"], "création", tours, dict(q["preuve"], palier=2),
                                    systeme=fmt.plan())
                if q["jetons"] <= PLAFONDS[2]:
                    return q, ""
    return None, "page du membre absente des résultats, ou paire trop longue"


def generer(donnees: Path | None = None, journal: Callable[[str], None] = print) -> dict[str, Any]:
    paires, rejets = [], []
    for fichier in sorted(fmt.dossier("creation_fonction", donnees).glob("paires_*.jsonl")):
        for ligne in fichier.read_text(encoding="utf-8").splitlines():
            p = json.loads(ligne)
            q, raison = depuis_creation(p)
            if q is None:
                rejets.append(f"{p['preuve']['etape']} {p['preuve']['fonction']} : {raison}")
            else:
                paires.append(q)
        journal(f"{fichier.name} : {len(paires)} paires RAG")
    sortie = fmt.dossier(FAMILLE, donnees)
    fmt.ecrire(paires, sortie / "paires.jsonl")
    bilan = {"famille": FAMILLE, "paires": len(paires), "rejets": rejets,
             "par_palier": {}, "jetons_max": max((p["jetons"] for p in paires), default=0)}
    for p in paires:
        k = str(p["preuve"].get("palier", 2))
        bilan["par_palier"][k] = bilan["par_palier"].get(k, 0) + 1
    (sortie / "bilan.json").write_text(json.dumps(bilan, indent=1, ensure_ascii=False), encoding="utf-8")
    return bilan
