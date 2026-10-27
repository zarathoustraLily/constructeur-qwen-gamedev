"""Rassemble la base : contrôles, statistiques, fichiers d'entraînement et version lisible.

Entrée : un fichier JSON par étape (exemples de création et sessions de débogage, chacun au format neutre et au
format d'OpenCode). La base livrée est celle au format d'OpenCode (décision 14, règle 7.4). Sortie, dans
donnees/cours/<cours>/base/livraison/ : la base au format chat et au format sharegpt, sa déclaration pour
LLaMA-Factory, un échantillon lisible, les contrôles (controles.json) et le LISEZMOI.
"""

from __future__ import annotations

import collections
import json
import re

from usine.cours.base import analyse, chemins, creation, etat, exporter, jetons, lisezmoi, opencode, profil, rejouer

LONGUEUR = 32768
# Décision 3 (2026-10-22, « ok modifie en 40/40/20 ») : parts des jetons de réponse, étape par étape (règle 7.1).
CIBLE = {"creation": 0.4, "debogage": 0.4, "analyse": 0.2}
TYPES = tuple(CIBLE)
ORDRE_VILLES = {"parisien": 0, "tokyoiste": 1, "newyorkais": 2}
RESTES = re.compile(r"\{TWIN\}|\{FILES_TABLE\}|\{STEP\}|\{TITLE\}|\{TRACK\}|\{NAME\}|>>> NOUVEAU|<<< FIN DU NOUVEAU"
                    r"|· fichier (modifié|nouveau|inchangé) à cette étape")


def nom_base() -> str:
    """base_batiments_proceduraux, base_kart, base_roguelike."""
    return f"base_{chemins.actuels().nom_cours}"


def ordre_lignes() -> dict[str, int]:
    """Les villes des bâtiments, ou la seule suite d'étapes d'un cours de jeu (son préfixe)."""
    ch = chemins.actuels()
    return {ch.manifeste["PREFIXE"]: 0} if ch.jeu else ORDRE_VILLES


def etapes_du_cours() -> range:
    ch = chemins.actuels()
    return range(1, (ch.manifeste["DERNIERE"] if ch.jeu else 13) + 1)
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
    ordre = ordre_lignes()
    exemples.sort(key=lambda e: (ordre[e["ville"]], e["etape"], 0 if e["type"] == "creation" else 1,
                                 e.get("partie", [0])[0], _numero(e)))
    for e in exemples:
        if "opencode" not in e:
            raise RuntimeError(f"{e['id']} : pas de version au format d'OpenCode (étape générée avant ce format : "
                               "relancer « generer --refaire »)")
        # Les jetons qui comptent : ceux de l'exemple au format d'OpenCode, celui de l'entraînement.
        e["jetons"], e["jetons_reponse"] = e["opencode"]["jetons"], e["opencode"]["jetons_reponse"]
    return exemples


def ajouter_analyses(exemples: list[dict], h: opencode.Harnais) -> tuple[list[dict], list[str]]:
    """Les exemples d'analyse tirés des sessions de débogage (analyse.py), comptés comme les autres."""
    analyses, ecartees = analyse.deriver(exemples, h)
    for a in analyses:
        a["jetons"], a["jetons_reponse"] = a["opencode"]["jetons"], a["opencode"]["jetons_reponse"]
    return exemples + analyses, ecartees


def _rapprocher(liste: list[dict], cible: float) -> list[dict]:
    """Retire des exemples, le plus long d'abord, tant que la somme des jetons de réponse s'en rapproche de la cible.
    Une somme sous la cible garde tout : rien ne s'invente (règle 7.7 : d'une base volumineuse, on garde une part)."""
    gardes = sorted(liste, key=lambda e: (-e["jetons_reponse"], e["id"]))
    somme = sum(e["jetons_reponse"] for e in gardes)
    k = 0
    while k < len(gardes):
        apres = somme - gardes[k]["jetons_reponse"]
        if abs(apres - cible) < abs(somme - cible):
            somme = apres
            gardes.pop(k)
        else:
            k += 1
    return gardes


def equilibrer(exemples: list[dict]) -> tuple[list[dict], list[str]]:
    """Étape par étape, la création reste entière (ses parties se suivent) ; débogage et analyse sont choisis pour
    peser, en jetons de réponse, création × 40/40 et création × 20/40. Rend les exemples gardés et les écartés."""
    par_etape: dict = {}
    for e in exemples:
        par_etape.setdefault((e["ville"], e["etape"]), []).append(e)
    gardes, ecartes = [], []
    for cle in sorted(par_etape, key=lambda c: (ordre_lignes()[c[0]], c[1])):
        liste = par_etape[cle]
        c = sum(e["jetons_reponse"] for e in liste if e["type"] == "creation")
        pris = [e for e in liste if e["type"] == "creation"]
        for t in ("debogage", "analyse"):
            choix = [e for e in liste if e["type"] == t]
            retenus = _rapprocher(choix, c * CIBLE[t] / CIBLE["creation"]) if c else choix
            pris += retenus
            ecartes += [e["id"] for e in choix if e not in retenus]
        gardes += [e for e in liste if e in pris]
    return gardes, ecartes


def parts(liste: list[dict]) -> dict[str, float]:
    total = sum(e["jetons_reponse"] for e in liste) or 1
    return {t: round(sum(e["jetons_reponse"] for e in liste if e["type"] == t) / total, 3) for t in TYPES}


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


RETOURS = re.compile(r"(?s)^(Read file .+, lines \d+-\d+\n.*|Edited \S.* \(1 replacement\)|Created file successfully: \S.*"
                     r"|Wrote file successfully: \S.*|No matches found|.*\nCommand exited with code -?\d+\.)$")


def controler_opencode(exemples: list[dict], h: opencode.Harnais, tok) -> list[str]:
    """Le format d'OpenCode : chaque appel a son retour, dans l'ordre ; outils et arguments conformes aux définitions
    d'OpenCode ; Godot lancé par son chemin complet ; retours aux formes relevées chez laurent ; aucune réponse n'écrit
    de sortie (règle 7.2) ; jetons recomptés ; le format sharegpt redonne le texte du gabarit, jeton pour jeton."""
    problemes = []
    schemas = {o["function"]["name"]: o["function"]["parameters"] for o in h.outils}
    for e in exemples:
        oc = e["opencode"]
        ms = oc["messages"]
        nom = e["id"]
        if ms[0]["role"] != "system" or ms[0]["content"] == h.systeme or "running in OpenCode" not in ms[0]["content"]:
            problemes.append(f"{nom} : prompt système d'OpenCode absent ou non adapté au projet")
        attente: list[str] = []
        for k, m in enumerate(ms[1:], 1):
            if m["role"] == "tool":
                if not attente or m["tool_call_id"] != attente[0]:
                    problemes.append(f"{nom} : retour d'outil {k} sans appel en attente")
                else:
                    attente.pop(0)
                if not RETOURS.match(m["content"]):
                    problemes.append(f"{nom} : retour d'outil {k} d'une forme non relevée : {m['content'][:60]!r}")
                continue
            if attente:
                problemes.append(f"{nom} : message {k} avant le retour de tous les appels")
                attente = []
            if m["role"] == "assistant":
                fautif = sortie_ecrite(m["content"])
                if fautif:
                    problemes.append(f"{nom} : la réponse {k} écrit une sortie de commande ({fautif})")
                for tc in m.get("tool_calls") or []:
                    outil, args = tc["function"]["name"], tc["function"]["arguments"]
                    schema = schemas.get(outil)
                    if schema is None:
                        problemes.append(f"{nom} : outil inconnu d'OpenCode : {outil}")
                        continue
                    if set(schema.get("required", [])) - set(args) or set(args) - set(schema["properties"]):
                        problemes.append(f"{nom} : arguments de {outil} hors de sa définition : {sorted(args)}")
                    if outil == "shell" and not args["command"].startswith(h.godot + " "):
                        problemes.append(f"{nom} : commande sans le chemin complet de Godot : {args['command'][:60]}")
                    attente.append(tc["id"])
            elif m["role"] != "user":
                problemes.append(f"{nom} : rôle inattendu {m['role']}")
        if attente or ms[-1]["role"] != "assistant" or ms[-1].get("tool_calls"):
            problemes.append(f"{nom} : la conversation ne finit pas sur une réponse sans appel")
        non_lus = passages_non_lus(e)
        if non_lus:
            problemes.append(f"{nom} : {len(non_lus)} ligne(s) citée(s) par edit sans avoir été lues : {non_lus[0][:60]!r}")
        if opencode.compter(tok, ms, oc["tools"]) != (oc["jetons"], oc["jetons_reponse"]):
            problemes.append(f"{nom} : jetons recomptés différents")
        if oc["jetons"] > LONGUEUR:
            problemes.append(f"{nom} : trop long ({oc['jetons']} jetons de Qwen 3.8, plus que {LONGUEUR})")
        if opencode.rendre_sharegpt(opencode.vers_sharegpt(ms, oc["tools"])) != opencode.rendre(ms, oc["tools"]):
            problemes.append(f"{nom} : le format sharegpt ne redonne pas le texte du gabarit")
    return problemes


LIGNE_LUE = re.compile(r"^\d+: (.*)$")


def passages_non_lus(e: dict) -> list[str]:
    """Les lignes d'un `oldString` que la réponse n'a pas vues avant de les citer : ni lues (`read`), ni écrites par
    elle (`edit`, `write`), ni données dans la demande."""
    vues: set[str] = set()
    manque = []
    for m in e["opencode"]["messages"][1:]:
        if m["role"] == "user":
            vues.update(m["content"].split("\n"))
        elif m["role"] == "tool" and m["content"].startswith("Read file "):
            vues.update(mm.group(1) for l in m["content"].split("\n")[1:] if (mm := LIGNE_LUE.match(l)))
        for tc in m.get("tool_calls") or []:
            args = tc["function"]["arguments"]
            if tc["function"]["name"] == "edit":
                manque += [l for l in args["oldString"].split("\n") if l.strip() and l not in vues]
                vues.update(args["newString"].split("\n"))
            elif tc["function"]["name"] == "write":
                vues.update(args["content"].split("\n"))
    return manque


def _appels(e: dict) -> list[tuple[str, dict]]:
    return [(tc["function"]["name"], tc["function"]["arguments"]) for m in e["opencode"]["messages"]
            for tc in m.get("tool_calls") or []]


def rejouer_opencode(exemples: list[dict], h: opencode.Harnais) -> dict:
    """Les appels `edit` et `write`, rejoués comme OpenCode (passage unique exigé) : les parties de création d'une
    étape, l'une après l'autre depuis son départ, redonnent son code ; chaque session redonne le code juste depuis
    le code fautif. Exactement, lignes vides comprises."""
    bilan = {"etapes": 0, "sessions": 0, "differences": 0, "details": []}
    par_etape: dict = {}
    for e in exemples:
        par_etape.setdefault((e["ville"], e["etape"]), []).append(e)
    for (ville, n), liste in sorted(par_etape.items()):
        avant, apres = creation.etats(ville, n)
        dossier = h.dossier(etat.nom(ville, n))
        enseignes = profil.enseignables()
        fichiers = {k: v for k, v in avant.items() if k.endswith(enseignes)}
        try:
            for e in sorted((x for x in liste if x["type"] == "creation"), key=lambda x: x["partie"][0]):
                fichiers = opencode.appliquer(fichiers, _appels(e), dossier)
            ecarts = [rel for rel, t in apres.items() if rel.endswith(enseignes) and fichiers.get(rel) != t]
        except ValueError as exc:
            ecarts = [str(exc)]
        bilan["etapes"] += 1
        bilan["differences"] += len(ecarts)
        bilan["details"] += [f"{ville} {n:03d} (création) : {x}" for x in ecarts]
        for e in (x for x in liste if x["type"] == "debogage"):
            depart: dict[str, str] = {}
            for m in e["preuves"]["mutations"]:
                lignes = depart.get(m["fichier"], apres[m["fichier"]]).split("\n")
                lignes[m["ligne"] - 1] = m["apres"]
                depart[m["fichier"]] = "\n".join(lignes)
            try:
                obtenu = opencode.appliquer(depart, _appels(e), dossier)
                ecarts = [rel for rel in depart if obtenu[rel] != apres[rel]]
            except ValueError as exc:
                ecarts = [str(exc)]
            bilan["sessions"] += 1
            bilan["differences"] += len(ecarts)
            bilan["details"] += [f"{e['id']} : {x}" for x in ecarts]
    return bilan


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
    ana = [e for e in exemples if e["type"] == "analyse"]
    st = {"total": len(exemples), "par_type": dict(collections.Counter(e["type"] for e in exemples)),
          "par_ville": dict(collections.Counter(e["ville"] for e in exemples))}
    st["creations"] = {
        "nombre": len(crea),
        "etapes_en_plusieurs_parties": len({(e["ville"], e["etape"]) for e in crea if e["partie"][1] > 1}),
        "rien_a_corriger": sum(1 for e in crea if e["preuves"].get("ok")),
        "tours_moyens": round(sum(len(e["opencode"]["messages"]) - 1 for e in crea) / max(1, len(crea)), 1),
        "tours_max": max((len(e["opencode"]["messages"]) - 1 for e in crea), default=0),
    }
    st["sessions"] = {
        "nombre": len(deb),
        "erreurs": sum(e["nb_erreurs"] for e in deb),
        "par_nombre_d_erreurs": dict(sorted(collections.Counter(e["nb_erreurs"] for e in deb).items())),
        "tours_moyens": round(sum(len(e["opencode"]["messages"]) - 1 for e in deb) / max(1, len(deb)), 1),
        "tours_max": max((len(e["opencode"]["messages"]) - 1 for e in deb), default=0),
        "genres": dict(collections.Counter(g for e in deb for g in e["genres"]).most_common()),
        "vues": dict(collections.Counter(v for e in deb for v in e["preuves"]["vues"]).most_common()),
        "trouvees_par_la_recherche": sum(1 for e in deb for v in e["preuves"]["vues"] if v == "recherche"),
        "sessions_avec_erreur_d_execution": sum(1 for e in deb if "test" in e["preuves"]["vues"]),
        "sessions_avec_vague_de_syntaxe": sum(1 for e in deb if "godot3_annotation" in e["genres"] and e["nb_erreurs"] > 1),
    }
    tailles = [len(opencode.rendre(e["opencode"]["messages"], e["opencode"]["tools"])) for e in exemples]
    st["caracteres"] = {"total": sum(tailles), "max": max(tailles), "moyenne": round(sum(tailles) / len(tailles))}
    st["appels_d_outils"] = dict(collections.Counter(
        tc["function"]["name"] for e in exemples for m in e["opencode"]["messages"]
        for tc in m.get("tool_calls") or []).most_common())
    j = [e["jetons"] for e in exemples]
    plus_long = max(exemples, key=lambda e: e["jetons"])

    def resume(liste: list[dict]) -> dict:
        v = [e["jetons"] for e in liste]
        r = [e["jetons_reponse"] for e in liste]
        return {"nombre": len(v), "total": sum(v), "reponses": sum(r), "moyenne": round(sum(v) / len(v)),
                "reponse_moyenne": round(sum(r) / len(r)), "min": min(v), "max": max(v)}

    tok = jetons.tokenizer()
    st["jetons"] = {
        "tokenizer": f"pré-découpage {tok.pre}, {lisezmoi.nb(len(tok.jetons))} jetons, "
                     f"{lisezmoi.nb(len(tok.rangs))} fusions ; fichier {chemins.actuels().vocab_qwen.name}",
        "gabarit": "celui du GGUF de Qwen 3.8 : outils dans le message système, appels <tool_call><function=…>, "
                   "retours <tool_response> dans un tour user ; un bloc <think> vide devant chaque réponse, compté "
                   "dans le total mais pas dans la réponse (enable_thinking: false)",
        "prompt_et_outils": len(tok.encoder_special(opencode.rendre(exemples[0]["opencode"]["messages"][:1],
                                                                    exemples[0]["opencode"]["tools"]))),
        "total": sum(j), "max": max(j), "moyenne": round(sum(j) / len(j)), "plus_long": plus_long["id"],
        "reponses": sum(e["jetons_reponse"] for e in exemples),
        "caracteres_par_jeton": round(sum(tailles) / sum(j), 2),
        "marge_plus_long": LONGUEUR - max(j),
        "au_dela_de_32768": [e["id"] for e in exemples if e["jetons"] > LONGUEUR],
        "par_type": {"creation": resume(crea), "debogage": resume(deb), **({"analyse": resume(ana)} if ana else {})},
    }
    jt = st["jetons"]["par_type"]
    st["jetons"]["part_creation_reponses"] = round(jt["creation"]["reponses"] / st["jetons"]["reponses"], 3)
    # Les trois parts (décision 3), sur toute la base puis étape par étape, et leur écart à la cible.
    st["jetons"]["parts_reponses"] = parts(exemples)
    st["jetons"]["cible"] = CIBLE
    par_etape = {}
    for v in ordre_lignes():
        for n in etapes_du_cours():
            liste = [e for e in exemples if e["ville"] == v and e["etape"] == n]
            if liste:
                par_etape[f"{v}-{n:03d}"] = parts(liste)
    st["parts_par_etape"] = {
        "min": {t: min(p[t] for p in par_etape.values()) for t in TYPES},
        "max": {t: max(p[t] for p in par_etape.values()) for t in TYPES},
        "ecart_max_points": round(100 * max(abs(p[t] - CIBLE[t]) for p in par_etape.values() for t in TYPES), 1),
        "etapes": par_etape}
    st["jetons"]["part_creation_total"] = round(jt["creation"]["total"] / sum(j), 3)
    # L'équilibre étape par étape : jetons de réponse du débogage / ceux de la création (règle 7.1).
    rapports = []
    for v in ordre_lignes():
        for n in etapes_du_cours():
            c = sum(e["jetons_reponse"] for e in crea if e["ville"] == v and e["etape"] == n)
            d = sum(e["jetons_reponse"] for e in deb if e["ville"] == v and e["etape"] == n)
            if c:
                rapports.append((round(d / c, 2), f"{v}-{n:03d}"))
    rapports.sort()
    st["equilibre_par_etape"] = {"plus_bas": rapports[:3], "plus_haut": rapports[-3:],
                                 "median": rapports[len(rapports) // 2][0] if rapports else None}
    return st


def choisir_echantillon(exemples: list[dict]) -> list[dict]:
    """Deux créations, puis des sessions qui montrent chaque situation : une erreur seule, une vague de syntaxe,
    des shaders au rendu, une erreur à l'exécution du test, une faute trouvée par la recherche."""
    crea = [e for e in exemples if e["type"] == "creation"]
    deb = [e for e in exemples if e["type"] == "debogage"]
    pris: list[dict] = [e for e in crea if e["id"] in ("newyorkais-011-creation", "newyorkais-011-creation-p1")][:1]
    if not pris and crea:
        # Cours de jeu : la première partie d'une étape du milieu du cours.
        milieu = sorted({e["etape"] for e in crea})[len({e["etape"] for e in crea}) // 2]
        pris = [e for e in crea if e["etape"] == milieu][:1]

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
    pris += sorted((e for e in exemples if e["type"] == "analyse"), key=lambda e: (len(e["messages"]), e["id"]))[:1]
    return pris


def assembler(journal=print) -> dict:
    """Contrôle, compte et écrit la base ; rend les statistiques et les problèmes."""
    ch = chemins.actuels()
    exemples = charger()
    if not exemples:
        raise RuntimeError(f"aucune étape générée dans {ch.etapes} : lancer d'abord « generer »")
    h = ch.harnais()
    # Analyse (décision 3, 40/40/20) : tirée des sessions de débogage, puis chaque étape équilibrée.
    exemples, non_tirees = ajouter_analyses(exemples, h)
    exemples, ecartes = equilibrer(exemples)
    problemes = controler(exemples)
    problemes += controler_opencode(exemples, h, jetons.tokenizer())
    st = statistiques(exemples)
    st["analyses"] = {"sessions_sans_analyse": non_tirees, "ecartes_a_l_equilibrage": len(ecartes),
                      "ecartes": ecartes}
    # Les consignes d'édition du format neutre, rejouées à la lettre depuis l'état de départ (règle 5.7)…
    bilan = rejouer.rejouer_exemples(exemples, creation.etats, profil.enseignables())
    st["consignes_rejouees"] = {k: v for k, v in bilan.items() if k != "details"}
    problemes += bilan["details"]
    # … et les appels edit et write du format d'OpenCode, rejoués comme OpenCode les applique.
    bilan_oc = rejouer_opencode(exemples, h)
    st["editions_opencode_rejouees"] = {k: v for k, v in bilan_oc.items() if k != "details"}
    problemes += bilan_oc["details"]
    # L'extrait décalé des shaders : chaque relevé dans une réponse est confronté au nombre de #include.
    bons, autres = verifier_decalages(exemples)
    st["sessions"]["decalages_shader_verifies"] = bons
    problemes += autres
    for e in exemples:
        e.pop("jetons", None)
        e.pop("jetons_reponse", None)
    ch.livraison.mkdir(parents=True, exist_ok=True)
    fichiers = exporter.ecrire(exemples, ch.livraison, nom_base())
    echantillon = choisir_echantillon(exemples)
    exporter.lisible(echantillon, ch.livraison / "echantillon.md", "Base d'entraînement : échantillon lisible (format d'OpenCode)")
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
