"""Rassemble la base : contrôles, statistiques, fichiers d'entraînement et version lisible.

Entrée : un fichier JSON par étape (exemples de création et sessions de débogage). Sortie, dans
donnees/cours/batiments_proceduraux/base/livraison/ : la base au format chat et au format sharegpt, sa déclaration
pour LLaMA-Factory, un échantillon lisible, les contrôles (controles.json) et le LISEZMOI.
"""

from __future__ import annotations

import collections
import json
import re

from usine.cours.base import chemins, creation, etat, exporter, jetons, lisezmoi, rejouer

LONGUEUR = 32768
NOM = "base_batiments_proceduraux"
ORDRE_VILLES = {"parisien": 0, "tokyoiste": 1, "newyorkais": 2}
RESTES = re.compile(r"\{TWIN\}|\{FILES_TABLE\}|>>> NOUVEAU|<<< FIN DU NOUVEAU|· fichier (modifié|nouveau|inchangé) à cette étape")
# Un bloc de commande demandé à la fin d'une réponse : « ```\n$ commande\n``` ».
DEMANDE = re.compile(r"```\n\$ (.+)\n```\s*$")
BLOC = re.compile(r"```[^\n]*\n(.*?)```", re.S)


def _numero(e: dict) -> int:
    m = re.search(r"-(\d+)$", e["id"])
    return int(m.group(1)) if m else 0


def charger() -> list[dict]:
    exemples = []
    for f in sorted(chemins.actuels().etapes.glob("*.json")):
        exemples += json.loads(f.read_text(encoding="utf-8"))
    exemples.sort(key=lambda e: (ORDRE_VILLES[e["ville"]], e["etape"], 0 if e["type"] == "creation" else 1,
                                 e.get("partie", [0])[0], _numero(e)))
    return exemples


def roles_valides(roles: list[str]) -> bool:
    """system, puis user et assistant en alternance, en finissant par assistant."""
    if len(roles) < 3 or roles[0] != "system" or roles[-1] != "assistant":
        return False
    return all(r == ("user" if k % 2 == 0 else "assistant") for k, r in enumerate(roles[1:]))


def sortie_ecrite(texte: str) -> str | None:
    """Une sortie de commande écrite dans une réponse (règle 7.2) : un bloc qui commence par « $ » et contient autre
    chose que la commande, ou un code de sortie. Rend le début du bloc fautif, ou None."""
    for bloc in BLOC.findall(texte):
        lignes = [l for l in bloc.split("\n") if l.strip()]
        if lignes and lignes[0].startswith("$ ") and len(lignes) > 1:
            return lignes[0][:80]
    return "(code de sortie" if "(code de sortie" in texte else None


def controler(exemples: list[dict]) -> list[str]:
    problemes = []
    vus = set()
    for e in exemples:
        roles = [m["role"] for m in e["messages"]]
        if not roles_valides(roles):
            problemes.append(f"{e['id']} : rôles {roles}")
        if e["jetons"] > LONGUEUR:
            problemes.append(f"{e['id']} : trop long ({e['jetons']} jetons de Qwen, plus que {LONGUEUR})")
        for m in e["messages"]:
            if RESTES.search(m["content"]):
                problemes.append(f"{e['id']} : reste de gabarit dans {m['role']}")
        if not e["preuves"].get("ok"):
            problemes.append(f"{e['id']} : vérifications de Godot non passées")
        for k in range(2, len(e["messages"]), 2):
            texte = e["messages"][k]["content"]
            fautif = sortie_ecrite(texte)
            if fautif:
                problemes.append(f"{e['id']} : la réponse {k} écrit une sortie de commande ({fautif})")
            # Chaque commande demandée à la fin d'une réponse a sa sortie, telle quelle, dans le tour suivant.
            demande = DEMANDE.findall(texte)
            if demande:
                if k + 1 >= len(e["messages"]):
                    problemes.append(f"{e['id']} : la dernière réponse demande une commande sans en recevoir la sortie")
                elif not e["messages"][k + 1]["content"].startswith(f"```\n$ {demande[0]}\n"):
                    problemes.append(f"{e['id']} : le tour {k + 1} ne répond pas à la commande demandée")
            elif k + 1 < len(e["messages"]):
                problemes.append(f"{e['id']} : la réponse {k} ne demande rien, et pourtant un tour suit")
        cle = "\n".join(m["content"] for m in e["messages"][1:])
        if cle in vus:
            problemes.append(f"{e['id']} : exemple en double")
        vus.add(cle)
    for i, n in collections.Counter(e["id"] for e in exemples).items():
        if n > 1:
            problemes.append(f"identifiant en double : {i}")
    return problemes


DECALAGE = re.compile(r"la ligne fautive (?:y porte le numéro (\d+), pas (\d+)|apparaît juste en dessous, sous le "
                      r"numéro (\d+)\. Le numéro sûr est celui de la ligne « at: » : ligne (\d+))")


def verifier_decalages(exemples: list[dict]) -> tuple[int, list[str]]:
    """Chaque fois qu'une réponse relève l'extrait décalé d'un shader : le décalage doit valoir le nombre de
    `#include` au-dessus de la ligne fautive, dans le fichier de l'étape (règle 5.6)."""
    etats: dict = {}
    bons, problemes = 0, []
    for e in exemples:
        if e["type"] != "debogage":
            continue
        texte = "\n".join(m["content"] for m in e["messages"] if m["role"] == "assistant")
        for mm in DECALAGE.finditer(texte):
            montre, ligne = int(mm.group(1) or mm.group(3)), int(mm.group(2) or mm.group(4))
            cle = (e["ville"], e["etape"])
            if cle not in etats:
                etats[cle] = creation.etats(*cle)[1]
            fichiers = [m["fichier"] for m in e["preuves"]["mutations"] if m["ligne"] == ligne and not m["fichier"].endswith(".gd")]
            if not fichiers:
                problemes.append(f"{e['id']} : décalage relevé sans erreur de shader à la ligne {ligne}")
                continue
            inclus = sum(1 for l in etats[cle][fichiers[0]].split("\n")[:ligne - 1] if l.strip().startswith("#include"))
            if montre - ligne == inclus:
                bons += 1
            else:
                problemes.append(f"{e['id']} : décalage de {montre - ligne} ligne(s), {inclus} #include au-dessus")
    return bons, problemes


def statistiques(exemples: list[dict]) -> dict:
    crea = [e for e in exemples if e["type"] == "creation"]
    deb = [e for e in exemples if e["type"] == "debogage"]
    st = {"total": len(exemples), "par_type": dict(collections.Counter(e["type"] for e in exemples)),
          "par_ville": dict(collections.Counter(e["ville"] for e in exemples))}
    st["creations"] = {
        "nombre": len(crea),
        "etapes_en_plusieurs_parties": len({(e["ville"], e["etape"]) for e in crea if e["partie"][1] > 1}),
        "rien_a_corriger": sum(1 for e in crea if e["preuves"].get("ok")),
        "tours_moyens": round(sum(len(e["messages"]) - 1 for e in crea) / max(1, len(crea)), 1),
        "tours_max": max((len(e["messages"]) - 1 for e in crea), default=0),
    }
    st["sessions"] = {
        "nombre": len(deb),
        "erreurs": sum(e["nb_erreurs"] for e in deb),
        "par_nombre_d_erreurs": dict(sorted(collections.Counter(e["nb_erreurs"] for e in deb).items())),
        "tours_moyens": round(sum(len(e["messages"]) - 1 for e in deb) / max(1, len(deb)), 1),
        "tours_max": max((len(e["messages"]) - 1 for e in deb), default=0),
        "genres": dict(collections.Counter(g for e in deb for g in e["genres"]).most_common()),
        "vues": dict(collections.Counter(v for e in deb for v in e["preuves"]["vues"]).most_common()),
        "trouvees_par_la_recherche": sum(1 for e in deb for v in e["preuves"]["vues"] if v == "recherche"),
        "sessions_avec_erreur_d_execution": sum(1 for e in deb if "test" in e["preuves"]["vues"]),
        "sessions_avec_vague_de_syntaxe": sum(1 for e in deb if "godot3_annotation" in e["genres"] and e["nb_erreurs"] > 1),
    }
    tailles = [sum(len(m["content"]) for m in e["messages"]) for e in exemples]
    st["caracteres"] = {"total": sum(tailles), "max": max(tailles), "moyenne": round(sum(tailles) / len(tailles))}
    j = [e["jetons"] for e in exemples]
    plus_long = max(exemples, key=lambda e: e["jetons"])

    def resume(liste: list[dict]) -> dict:
        v = [e["jetons"] for e in liste]
        r = [e["jetons_reponse"] for e in liste]
        return {"nombre": len(v), "total": sum(v), "reponses": sum(r), "moyenne": round(sum(v) / len(v)),
                "reponse_moyenne": round(sum(r) / len(r)), "min": min(v), "max": max(v)}

    st["jetons"] = {
        "tokenizer": "qwen35 (vocabulaire GGUF de llama.cpp, models/ggml-vocab-qwen35.gguf)",
        "gabarit": "<|im_start|>rôle\\ncontenu<|im_end|>\\n par message ; un bloc <think> vide devant chaque réponse, "
                   "compté dans le total mais pas dans la réponse (enable_thinking: false)",
        "total": sum(j), "max": max(j), "moyenne": round(sum(j) / len(j)), "plus_long": plus_long["id"],
        "reponses": sum(e["jetons_reponse"] for e in exemples),
        "caracteres_par_jeton": round(sum(tailles) / sum(j), 2),
        "marge_plus_long": LONGUEUR - max(j),
        "au_dela_de_32768": [e["id"] for e in exemples if e["jetons"] > LONGUEUR],
        "par_type": {"creation": resume(crea), "debogage": resume(deb)},
    }
    jt = st["jetons"]["par_type"]
    st["jetons"]["part_creation_reponses"] = round(
        jt["creation"]["reponses"] / (jt["creation"]["reponses"] + jt["debogage"]["reponses"]), 3)
    st["jetons"]["part_creation_total"] = round(jt["creation"]["total"] / sum(j), 3)
    # L'équilibre étape par étape : jetons de réponse du débogage / ceux de la création (règle 7.1).
    rapports = []
    for v in ORDRE_VILLES:
        for n in range(1, 14):
            c = sum(e["jetons_reponse"] for e in crea if e["ville"] == v and e["etape"] == n)
            d = sum(e["jetons_reponse"] for e in deb if e["ville"] == v and e["etape"] == n)
            if c:
                rapports.append((round(d / c, 2), f"{v}-{n:03d}"))
    rapports.sort()
    st["equilibre_par_etape"] = {"plus_bas": rapports[:3], "plus_haut": rapports[-3:],
                                 "median": rapports[len(rapports) // 2][0] if rapports else None}
    return st


def compter_jetons(exemples: list[dict]) -> dict:
    """Jetons de chaque exemple avec le tokenizer de Qwen 3.5 ; le total aussi avec celui de Qwen 1.5 à 3."""
    totaux = {}
    for e in exemples:
        e["jetons"], e["jetons_reponse"] = jetons.compter_messages(e["messages"])
    totaux["qwen35"] = sum(e["jetons"] for e in exemples)
    autre = chemins.actuels().vocab_qwen2
    if autre is not None and autre.is_file():
        tok = jetons.Tokenizer(str(autre))
        totaux["qwen2"] = sum(jetons.jetons_messages(tok, e["messages"])[0] for e in exemples)
    return totaux


def choisir_echantillon(exemples: list[dict]) -> list[dict]:
    """Deux créations, puis des sessions qui montrent chaque situation : une erreur seule, une vague de syntaxe,
    des shaders au rendu, une erreur à l'exécution du test, une faute trouvée par la recherche."""
    crea = [e for e in exemples if e["type"] == "creation"]
    deb = [e for e in exemples if e["type"] == "debogage"]
    pris: list[dict] = [e for e in crea if e["id"] in ("newyorkais-011-creation", "newyorkais-011-creation-p1")][:1]

    def premier(cond) -> None:
        for e in sorted(deb, key=lambda e: (len(e["messages"]), e["id"])):
            if cond(e) and e not in pris and len(e["messages"]) <= 17:
                pris.append(e)
                return

    premier(lambda e: e["nb_erreurs"] == 1 and e["preuves"]["vues"] == ["analyse"])
    premier(lambda e: "godot3_annotation" in e["genres"] and e["nb_erreurs"] >= 3)
    premier(lambda e: e["preuves"]["vues"].count("rendu") >= 2 and e["nb_erreurs"] >= 3)
    premier(lambda e: "test" in e["preuves"]["vues"] and e["nb_erreurs"] >= 2)
    premier(lambda e: "recherche" in e["preuves"]["vues"])
    pris += [e for e in crea if e["id"] in ("parisien-002-creation", "parisien-002-creation-p1")][:1]
    return pris


def assembler(journal=print) -> dict:
    """Contrôle, compte et écrit la base ; rend les statistiques et les problèmes."""
    ch = chemins.actuels()
    exemples = charger()
    if not exemples:
        raise RuntimeError(f"aucune étape générée dans {ch.etapes} : lancer d'abord « generer »")
    totaux = compter_jetons(exemples)
    problemes = controler(exemples)
    st = statistiques(exemples)
    if "qwen2" in totaux:
        st["jetons"]["total_autre_tokenizer_qwen2"] = totaux["qwen2"]
    # Les consignes d'édition de chaque exemple de création, rejouées à la lettre depuis l'état de départ (règle 5.7).
    bilan = rejouer.rejouer_exemples(exemples, creation.etats, etat.CODE)
    st["consignes_rejouees"] = {k: v for k, v in bilan.items() if k != "details"}
    problemes += bilan["details"]
    # L'extrait décalé des shaders : chaque relevé dans une réponse est confronté au nombre de #include.
    bons, autres = verifier_decalages(exemples)
    st["sessions"]["decalages_shader_verifies"] = bons
    problemes += autres
    for e in exemples:
        e.pop("jetons", None)
        e.pop("jetons_reponse", None)
    ch.livraison.mkdir(parents=True, exist_ok=True)
    fichiers = exporter.ecrire(exemples, ch.livraison, NOM)
    echantillon = choisir_echantillon(exemples)
    exporter.lisible(echantillon, ch.livraison / "echantillon.md", "Base d'entraînement : échantillon lisible")
    st["echantillon"] = [e["id"] for e in echantillon]
    controles = {"statistiques": st, "problemes": problemes}
    (ch.livraison / "controles.json").write_text(json.dumps(controles, ensure_ascii=False, indent=2), encoding="utf-8")
    lisezmoi.ecrire(controles, ch.livraison / "LISEZMOI.md")
    journal(json.dumps(st, ensure_ascii=False, indent=1))
    journal(f"problèmes : {len(problemes)}")
    for p in problemes[:40]:
        journal(f" - {p}")
    journal(f"Fichiers : {', '.join(str(v) for v in fichiers.values())}")
    return controles
