"""Exemples de création : une étape (ou une partie d'étape), en plusieurs tours, sorties de Godot réelles.

Le premier tour « assistant » cherche (API, documentation, sources de métier), code (les changements, fichier par
fichier) et lance la première commande. Chaque sortie de Godot arrive dans le tour « user » suivant, telle quelle,
avec son code de sortie : la réponse ne l'écrit jamais (règle 7.2). Le dernier tour vérifie, corrige s'il le faut,
et rend compte.
"""

from __future__ import annotations

import re
from collections import OrderedDict

from usine.cours.base import composer, etat, godot, jetons, opencode, ordonner, rattacher, sources, textes
from usine.cours.base import notes as notes_mod
from usine.cours.base.chemins import actuels
from usine.cours.base.etat import CODE
from usine.cours.base.notes import puces

TEST = "7_tests/6_assets/Mesh/Procedural/DECORS/Building/test_{nom}.gd"
# L'outillage du cours (visite, caméra, bandeau, réglages de la visite) est donné tel qu'à l'étape : il n'est pas
# enseigné. Les outils communs (maillage, fonctions de shader) sont écrits à Paris, donnés à Tokyo et New York.
OUTILLAGE = ("0_autoload/", "2_sequence/", "3_entities/", "4_ui/", "1_core/camera/", "1_core/data/", "5_data/visit/")
COMMUN = ("1_core/procedural/", "6_assets/Shader/Procedural/procedural_commun")
# Le vrai critère : les jetons de Qwen 3.8, gabarit de chat compris (règle 5.8), de l'exemple au format d'OpenCode.
# 32 768 est la longueur d'entraînement (règle 7.5) ; on garde 1 024 jetons de marge.
LIMITE_JETONS = 32768 - 1024
HARD_JETONS = 32768
# La découpe aux jetons estimés vise un peu sous la limite : l'estimation prend les sorties de l'état final, et le
# test d'une partie intermédiaire (celui de l'étape précédente) peut écrire d'autres lignes.
MARGE = 300

LECTURES = [
    (r"^(\S+\.tscn) : (\d+) triangles$", lambda m: f"la scène `{m[1]}` se construit : {m[2]} triangles."),
    (r"^zonage : (\d+) tour\(s\), marge la plus faible ([\d.\-]+) m$",
     lambda m: f"le règlement est tenu : {m[1]} tour(s), marge la plus faible {m[2].replace('.', ',')} m"
               + (" (positive : la tour reste sous son enveloppe)." if float(m[2]) > 0 else
                  " (nulle : la tour touche son enveloppe sans la dépasser)." if float(m[2]) == 0 else
                  " (négative : la tour dépasse son enveloppe).")),
    (r"^graines : (.*)$", lambda m: f"les graines : {m[1]}."),
]

SANS_ERREUR = "(aucune erreur ni avertissement du projet ; les lignes d'information de Godot, comme sa version, sont omises)"


def lire_ligne_test(ligne: str) -> str:
    corps = re.sub(r"^ok\s+", "", ligne.strip())
    for motif, phrase in LECTURES:
        m = re.match(motif, corps)
        if m:
            return phrase(m)
    return f"« {corps} »"


def bloc_sortie(s: godot.Sortie) -> str:
    """La sortie d'une commande, avec son code de sortie : c'est tout ce que la réponse suivante peut savoir."""
    return f"```\n$ {s.commande}\n{s.texte.strip() or SANS_ERREUR}\n(code de sortie : {s.code})\n```"


def bloc_commande(commande: str) -> str:
    return f"```\n$ {commande}\n```"


def etats(ville: str, n: int) -> tuple[dict[str, str], dict[str, str]]:
    """(avant, après) de l'étape, tous fichiers texte. L'outillage est donné tel qu'à l'étape n ; les outils
    communs aussi, sauf à Paris où ils sont écrits."""
    apres = etat.lire(ville, n)
    avant = etat.lire(ville, n - 1, n) if n > 1 else {}
    figes = OUTILLAGE + (COMMUN if ville != "parisien" else ())
    for rel in list(set(avant) | set(apres)):
        if rel.startswith(figes) or not rel.endswith(CODE):
            if rel in apres:
                avant[rel] = apres[rel]
            else:
                avant.pop(rel, None)
    return avant, apres


def regles(morceaux: list[etat.Morceau]) -> list[str]:
    r = []
    fichiers = {m.fichier for m in morceaux}
    texte = "\n".join(l for m in morceaux for l in m.nouvelles)
    if any(f.startswith("5_data/") for f in fichiers):
        r.append("DAT-01 : les listes et les cotes ajoutées vivent dans `5_data/`, pas dans le script.")
    if "RandomNumberGenerator" in texte or ".seed" in texte:
        r.append("SIM-09 : le hasard passe par un `RandomNumberGenerator` à graine enregistrée, rejouable.")
    if any(f.startswith("7_tests/") for f in fichiers):
        r.append("QA-01 : le test de l'étape est en miroir du script testé, dans `7_tests/`.")
    r.append("COD-02 : tout est typé ; l'analyse passe avec les avertissements traités en erreurs.")
    return r


class EchecPartie(Exception):
    pass


def _premier_tour(note, ville: str, n: int, partie: tuple[int, int], choisis: list[etat.Morceau],
                  propres: list[etat.Morceau], points: list[int], suites: set[int], apres: dict[str, str],
                  etat_debut: dict[str, str], etat_fin: dict[str, str], fichiers_touches: list[str]) -> list[str]:
    """But, fichiers, « Chercher », « Coder » (les changements), puis l'annonce des tests. `choisis` : les morceaux
    de la partie, places de l'étape entière ; `propres` : les mêmes changements, places des états de la partie."""
    titre = note.titre.split("·")[-1].strip()
    # Le code seul, sans les commentaires : un mot-clé dans un commentaire n'appelle pas de citation.
    code_nouveau = "\n".join(l.split("#", 1)[0].split("//", 1)[0] for m in choisis for l in m.nouvelles
                             if not l.strip().startswith(("#", "//", "/*", "*")))
    r = [f"**But** : {titre[0].lower() + titre[1:]}" + (f" (partie {partie[0]} sur {partie[1]})" if partie[1] > 1 else "") + ".",
         "**Fichiers** : " + ", ".join(f"`res://{f}`" + (" (nouveau)" if f not in etat_debut else "")
                                      for f in fichiers_touches) + "."]
    r += ["", "### 1. Chercher", "",
          "Avant d'écrire, je vérifie dans l'API de Godot 4.7.2 chaque classe et chaque membre que je vais employer :"]
    r += composer.verifications_api(apres, choisis) or ["- rien de nouveau : cette partie réemploie des membres déjà vérifiés."]
    cites = sources.doc(n, code_nouveau)
    if cites:
        r += ["", "Dans la documentation de Godot :"] + [f"- *{t}* : « {c} »" for t, c in cites]
    metier = sources.metier(ville, n, puces(note.sources)) if partie[0] == 1 else []
    if metier:
        r += ["", "Sources de métier :"] + [f"- {s}" for s in metier]
    r += ["", "### 2. Coder", "", "Ce que je fais, dans l'ordre :", ""]
    for p in note.points:
        if p.numero in points:
            if p.numero in suites:
                r += [f"**{p.numero}. {p.titre} (suite).** La suite des changements de ce point, commencés dans la "
                      "partie précédente.", ""]
            else:
                r += [f"**{p.numero}. {p.titre}.** " + composer.sans_code(p.texte), ""]
    r += ["Les changements, fichier par fichier :", "", composer.editions(etat_debut, etat_fin, propres), ""]
    r += ["### 3. Tester", "",
          "Chaque commande se lit avant de lancer la suivante. D'abord l'import du projet : il doit s'ouvrir sans "
          "erreur ni avertissement.", bloc_commande("godot --headless --path . --import")]
    return r


def generer(ville: str, n: int, ids: set[int], depuis: set[int], points: list[int], suites: set[int],
            partie: tuple[int, int], avant: dict[str, str], apres: dict[str, str],
            tous: list[etat.Morceau], affect: dict[int, int], note) -> dict:
    derniere = partie[0] == partie[1]
    choisis = [m for m in tous if m.id in ids]
    faits = depuis | ids
    etat_debut = etat.appliquer(avant, apres, depuis, tous)
    etat_fin = apres if derniere else etat.appliquer(avant, apres, faits, tous)
    if derniere:
        fichiers = dict(apres)
    else:
        fichiers = {k: v for k, v in etat.lire(ville, n - 1, n).items() if not k.endswith(CODE)}
        fichiers.update({k: v for k, v in etat_fin.items() if k.endswith(CODE)})
    nom_travail = f"{ville}_{n:03d}_p{partie[0]}"
    projet = godot.materialiser(fichiers, nom_travail)

    # Les commandes, dans l'ordre : import, analyse de chaque script modifié, test de l'étape, rendu.
    imp = godot.importer(projet)
    modifies = sorted({m.fichier for m in choisis if m.fichier.endswith(".gd")})
    analyses = [(rel, godot.verifier_script(projet, "res://" + rel)) for rel in modifies]
    test_rel = TEST.format(nom=etat.nom(ville, n))
    test = godot.tester(projet, "res://" + test_rel, 90 if derniere else 40) if test_rel in fichiers else None
    shaders = sorted({m.fichier for m in choisis if m.fichier.endswith((".gdshader", ".gdshaderinc"))})
    image = actuels().rendus / f"{nom_travail}.png"
    rendu = godot.rendre(projet, image) if shaders else None
    erreurs_rendu = rendu is not None and any("ERROR" in l for l in rendu.texte.splitlines())
    taille_image = godot.image_enregistree(rendu) if rendu is not None else None
    test_ok = test is None or (test.code == 0 and " 0 échec" in test.texte and "SCRIPT ERROR" not in test.texte)
    tout_ok = (not imp.texte.strip() and all(not s.texte.strip() for _, s in analyses) and test_ok
               and not erreurs_rendu and (rendu is None or taille_image is not None))
    if not tout_ok and not derniere:
        raise EchecPartie(f"{ville} {n} partie {partie}: import={imp.texte[:200]!r} "
                          f"analyses={[s.texte[:200] for _, s in analyses if s.texte.strip()]} "
                          f"test={(test.texte[-300:] if test else None)!r}")

    fichiers_touches = list(OrderedDict.fromkeys(
        m.fichier for m in sorted(choisis, key=lambda m: composer.ordre_fichier(m.fichier))))
    # Les changements de la partie entre ses deux états : les places de `choisis` sont celles de l'étape entière,
    # fausses dans l'état intermédiaire d'une partie (consignes d'édition, extraits de code).
    propres = etat.morceaux({k: v for k, v in etat_debut.items() if k.endswith(CODE)},
                            {k: v for k, v in etat_fin.items() if k.endswith(CODE)})
    consigne = composer.consigne(note, ville, etat_debut, propres, [p for p in points if p not in suites] or points,
                                 partie)
    messages = [{"role": "system", "content": textes.SYSTEME}, {"role": "user", "content": consigne},
                {"role": "assistant", "content": "\n".join(_premier_tour(note, ville, n, partie, choisis, propres,
                                                                         points, suites, apres, etat_debut, etat_fin,
                                                                         fichiers_touches))}]

    def tour(sortie: godot.Sortie, suite: str) -> None:
        """La sortie de la commande lancée (tour « user »), puis la réponse qui la lit et lance la suivante."""
        messages.append({"role": "user", "content": bloc_sortie(sortie)})
        messages.append({"role": "assistant", "content": suite})

    lu = "L'import est propre." if not imp.texte.strip() else "L'import signale des erreurs : je les lis avant de continuer."
    if analyses:
        tour(imp, lu + " J'analyse ensuite chaque script modifié, avec les avertissements traités en erreurs (typage "
                       f"compris), en commençant par `res://{analyses[0][0]}` :\n" + bloc_commande(analyses[0][1].commande))
        for k, (rel, s) in enumerate(analyses[1:], 1):
            lu = f"`res://{analyses[k - 1][0]}` passe l'analyse." if not analyses[k - 1][1].texte.strip() else \
                f"`res://{analyses[k - 1][0]}` ne passe pas l'analyse."
            tour(analyses[k - 1][1], f"{lu} Puis `res://{rel}` :\n" + bloc_commande(s.commande))
        derniere_sortie = analyses[-1][1]
        lu = (f"`res://{analyses[-1][0]}` passe l'analyse." if not derniere_sortie.texte.strip() else
              f"`res://{analyses[-1][0]}` ne passe pas l'analyse.")
        if len(analyses) > 1 and all(not s.texte.strip() for _, s in analyses):
            lu = f"`res://{analyses[-1][0]}` passe aussi : tous les scripts modifiés passent l'analyse."
    else:
        derniere_sortie = imp
    suivantes: list[tuple[str, godot.Sortie]] = []
    if test:
        quoi = ("Je lance le test de l'étape, pour vérifier que tout se construit :" if derniere else
                "Je lance le test de l'étape précédente : il garde ce qui marchait déjà.")
        suivantes.append((quoi, test))
    if rendu is not None:
        quoi = ("Un shader a changé, et un shader ne se compile qu'au rendu : je lance une image en Compatibilité "
                "(OpenGL 3) :")
        suivantes.append((quoi, rendu))
    for quoi, s in suivantes:
        tour(derniere_sortie, f"{lu} {quoi}\n" + bloc_commande(s.commande))
        derniere_sortie = s
        if s is test:
            nb = len([l for l in test.texte.splitlines() if l.startswith("ok")])
            lu = (f"Le test passe : {nb} ligne{'s' if nb > 1 else ''} « ok », code de sortie 0, aucune « SCRIPT ERROR »."
                  if test_ok else "Le test ne passe pas.")
    messages.append({"role": "user", "content": bloc_sortie(derniere_sortie)})

    # Dernier tour : vérifier, corriger, rendre compte.
    r = ["### 4. Vérifier", ""]
    if test:
        lignes_ok = [l for l in test.texte.splitlines() if l.startswith("ok")]
        r += ["Ce que confirme la sortie du test :"] + [f"- {lire_ligne_test(l)}" for l in lignes_ok]
    if rendu is not None:
        # Le rendu a sa propre sortie : sa lecture ne se range pas sous celle du test.
        r += ([""] if test else []) + [
            f"Le rendu {'ne signale aucune erreur de shader' if not erreurs_rendu else 'signale des erreurs : voir sa sortie'}"
            + (f", et l'image est enregistrée (`{godot.IMAGE_RENDU}`, {taille_image[0]} × {taille_image[1]}, `erreur=0`)."
               if taille_image else " ; l'image n'a pas été enregistrée.")]
    if not test and rendu is None:
        r += ["L'import et l'analyse sont propres ; cette partie n'a ni test ni shader à rendre."]
    essais = puces(note.essayer)
    if essais and derniere:
        r += ["", "Ce que le test ne voit pas, je le laisse en liste de contrôle, à faire dans l'éditeur :"] + [f"- {e}" for e in essais]
    if not derniere:
        r += ["", "L'étape n'est pas finie : la partie suivante reprend à partir d'ici."]
    r += ["", "### 5. Corriger", ""]
    if tout_ok:
        r += ["Rien à corriger : l'import est propre, chaque script passe l'analyse"
              + (", le test passe sans échec" if test else "")
              + (", et le rendu compile les shaders sans erreur." if rendu is not None else ".")]
    else:
        r += ["À reprendre : voir les sorties."]
    nb_ok = len([l for l in (test.texte.splitlines() if test else []) if l.startswith("ok")])
    r += ["", "**Compte rendu**",
          "- Fichiers créés ou modifiés : " + ", ".join(f"`res://{f}`" for f in fichiers_touches) + ".",
          f"- Tests lancés : import ({'0 erreur' if not imp.texte.strip() else 'erreurs'})"
          + ((f", analyse de {len(analyses)} scripts ({sum(1 for _, s in analyses if not s.texte.strip())} sans erreur)"
              if len(analyses) > 1 else ", analyse de 1 script (" + ("sans erreur" if not analyses[0][1].texte.strip()
                                                                      else "erreurs") + ")") if analyses else "")
          + (f", test ({nb_ok} vérification{'s' if nb_ok > 1 else ''} « ok », code de sortie {test.code})" if test else "")
          + (", rendu en Compatibilité (" + ("0 erreur de shader" if not erreurs_rendu else "erreurs") + ")"
             if rendu is not None else "") + ".",
          "- Problèmes non résolus : " + ("aucun." if tout_ok else "voir « Corriger »."),
          "- Règles concernées : " + " ".join(regles(choisis))]
    messages.append({"role": "assistant", "content": "\n".join(r)})
    sorties = [imp] + [s for _, s in analyses] + ([test] if test else []) + ([rendu] if rendu is not None else [])
    consigne_oc = composer.consigne(note, ville, etat_debut, choisis,
                                    [p for p in points if p not in suites] or points, partie, extraits=False)
    oc = _opencode(f"{ville}-{n:03d}-creation-p{partie[0]}-{partie[1]}", etat.nom(ville, n), consigne_oc, messages,
                   sorties, etat_debut, etat_fin, fichiers_touches, projet)
    return {
        "id": f"{ville}-{n:03d}-creation" + (f"-p{partie[0]}" if partie[1] > 1 else ""),
        "ville": ville, "etape": n, "partie": list(partie), "type": "creation",
        "messages": messages,
        "opencode": oc,
        "preuves": {"import": imp.texte, "analyses": {k: v.texte for k, v in analyses},
                    "test": test.texte if test else None, "test_code": test.code if test else None,
                    "rendu": rendu.texte if rendu else None, "ok": tout_ok,
                    "image": str(image) if rendu is not None else None},
    }


COMMANDE = re.compile(r"\n```\n\$ (.+)\n```\s*$")


def sans_commande(texte: str) -> tuple[str, str]:
    """(texte, commande) d'une réponse qui finit par la commande qu'elle lance."""
    m = COMMANDE.search(texte)
    if not m:
        raise ValueError(f"réponse sans commande finale : {texte[-120:]!r}")
    return texte[:m.start()].rstrip(), m.group(1)


def _opencode(ident: str, nom_projet: str, consigne_oc: str, neutres: list[dict], sorties: list[godot.Sortie],
              etat_debut: dict[str, str], etat_fin: dict[str, str], fichiers_touches: list[str], projet: str) -> dict:
    """La même partie au format d'OpenCode (règle 7.4) : la demande sans extraits de code ; la réponse lit le code
    qu'elle va changer (`read`, par plages), fait chaque changement (`edit`, `write`), lance chaque commande
    (`shell`) ; le texte des réponses est celui de l'exemple neutre, sans les consignes ni les commandes, devenues
    des appels d'outils."""
    c = opencode.Conversation(actuels().harnais(), nom_projet, ident)
    c.utilisateur(consigne_oc)
    premier = neutres[2]["content"]
    tete, reste = premier.split("\n### 1. Chercher", 1)
    chercher_coder, reste = ("### 1. Chercher" + reste).split("Les changements, fichier par fichier :", 1)
    tester, commande = sans_commande("### 3. Tester" + reste.split("### 3. Tester", 1)[1])
    actions: list[tuple] = []
    lectures: list[tuple[str, str, int, int]] = []
    for rel in fichiers_touches:
        if rel not in etat_fin:
            raise ValueError(f"{rel} retiré à cette étape : pas d'outil d'OpenCode pour le montrer")
        if rel not in etat_debut:
            actions.append(("write", rel, etat_fin[rel]))
            continue
        eds = opencode.editions_fichier(etat_debut[rel], etat_fin[rel])
        n_lignes = len(opencode.lignes_fichier(etat_debut[rel]))
        # Des plages assez larges pour qu'on lise le code autour, fusionnées quand elles sont proches.
        lectures += [(rel, etat_debut[rel], a, b)
                     for a, b in opencode.plages_lecture([e.lignes for e in eds], n_lignes, marge=3, ecart=12)]
        actions += [("edit", rel, e.ancien, e.nouveau) for e in eds]
    texte = chercher_coder.rstrip() + "\n\nLes changements, fichier par fichier :"
    if lectures:
        c.lire(tete.rstrip() + "\n\nJe lis d'abord le code actuel, là où l'étape intervient :", lectures)
    else:
        texte = tete.rstrip() + "\n\n" + texte
    for k, action in enumerate(actions):
        if action[0] == "write":
            c.ecrire(texte if k == 0 else "", action[1], action[2], False)
        else:
            c.editer(texte if k == 0 else "", action[1], action[2], action[3])
    if commande != sorties[0].commande:
        raise ValueError(f"commande {commande!r} au lieu de {sorties[0].commande!r}")
    c.shell(tester, commande, sorties[0].brut, sorties[0].code, projet)
    for k, s in zip(range(4, len(neutres) - 1, 2), sorties[1:], strict=True):
        corps, commande = sans_commande(neutres[k]["content"])
        if commande != s.commande:
            raise ValueError(f"commande {commande!r} au lieu de {s.commande!r}")
        c.shell(corps, commande, s.brut, s.code, projet)
    c.repondre(neutres[-1]["content"])
    ex = c.exemple()
    # Rejouées comme OpenCode les applique, les éditions redonnent le code de la partie, exactement.
    appels = [(tc["function"]["name"], tc["function"]["arguments"]) for m in ex["messages"]
              for tc in m.get("tool_calls") or []]
    obtenu = opencode.appliquer({k: v for k, v in etat_debut.items() if k in fichiers_touches}, appels, c.dossier)
    if any(obtenu.get(rel) != etat_fin[rel] for rel in fichiers_touches):
        raise ValueError(f"{ident} : les éditions d'OpenCode ne redonnent pas le code de la partie")
    ex["jetons"], ex["jetons_reponse"] = opencode.compter(jetons.tokenizer(), ex["messages"], ex["tools"])
    return ex


def muets(note, tous: list[etat.Morceau], affect: dict[int, int]) -> set[int]:
    """Les morceaux du test rattachés à un point qui ne parle pas du test : `rattacher` les donne par défaut au
    dernier point, qu'une partie annoncerait alors à tort (parisien 002 : « Le fichier commun… » pour une partie qui
    n'y touche pas)."""
    titres = {p.numero: p.titre.lower() for p in note.points}
    return {m.id for m in tous if m.fichier.startswith("7_tests/") and "test" not in titres.get(affect.get(m.id), "")}


def points_des_parties(note, parties: list[list[int]], affect: dict[int, int],
                       silencieux: set[int] = frozenset()) -> list[tuple[list[int], set[int]]]:
    """Pour chaque partie : les points à expliquer, et ceux qui sont une suite d'une partie précédente. Un morceau
    `silencieux` (voir `muets`) n'annonce son point que si sa partie n'en a pas d'autre."""
    def annonces(p: list[int]) -> set[int]:
        return {affect[i] for i in p if i not in silencieux} or {affect[i] for i in p}

    avec_code = {x for p in parties for x in annonces(p)}
    sans_code = [p.numero for p in note.points if p.numero not in avec_code]
    vus: set[int] = set()
    sortie = []
    for k, p in enumerate(parties):
        pts = sorted(annonces(p))
        # Un point sans code va avec la partie qui contient le point suivant ; à défaut, la première.
        for s in sans_code:
            suivant = next((q.numero for q in note.points if q.numero > s and q.numero in avec_code), None)
            if (suivant is not None and suivant in pts and suivant not in vus) or (suivant is None and k == 0):
                pts.append(s)
        pts = sorted(set(pts))
        suites = {x for x in pts if x in vus}
        vus |= set(pts)
        sortie.append((pts, suites))
    return sortie


def sorties_types(ville: str, n: int, apres: dict[str, str], tous: list[etat.Morceau]) -> dict[str, tuple[str, int, str]]:
    """Les sorties de Godot sur l'état final de l'étape : les sorties types de l'estimation (`godot.simulation`). La
    dernière partie de chaque découpe repasse par cet état : ses sorties sont alors déjà gardées."""
    projet = godot.materialiser(dict(apres), f"{ville}_{n:03d}_final")
    types = {"import": godot.sortie_type(godot.importer(projet), projet)}
    scripts = sorted({m.fichier for m in tous if m.fichier.endswith(".gd")})
    if scripts:
        types["analyse"] = godot.sortie_type(godot.verifier_script(projet, "res://" + scripts[0]), projet)
    test_rel = TEST.format(nom=etat.nom(ville, n))
    if test_rel in apres:
        types["test"] = godot.sortie_type(godot.tester(projet, "res://" + test_rel, 90), projet)
    if any(m.fichier.endswith((".gdshader", ".gdshaderinc")) for m in tous):
        types["rendu"] = godot.sortie_type(godot.rendre(projet), projet)
    return types


def _estimer(ville: str, n: int, parties: list[list[int]], types: dict, avant: dict[str, str],
             apres: dict[str, str], tous: list[etat.Morceau], affect: dict[int, int], note) -> list[int] | None:
    """Les jetons de chaque partie d'une découpe, sans lancer Godot : chaque commande rend la sortie de son genre sur
    l'état final. Le test d'une partie intermédiaire est celui de l'étape précédente, qui vérifie moins de choses :
    l'estimation ne sous-estime pas. None si elle échoue (une sortie type qui manque)."""
    pts = points_des_parties(note, parties, affect, muets(note, tous, affect))
    totaux = []
    with godot.simulation(types):
        for i in range(len(parties)):
            depuis = {x for p in parties[:i] for x in p}
            try:
                e = generer(ville, n, set(parties[i]), depuis, pts[i][0], pts[i][1], (i + 1, len(parties)),
                            avant, apres, tous, affect, note)
            except (EchecPartie, KeyError):
                return None
            totaux.append(e["opencode"]["jetons"])
    return totaux


def _glouton(ville: str, n: int, groupes: list[list[int]], types: dict, avant: dict[str, str],
             apres: dict[str, str], tous: list[etat.Morceau], affect: dict[int, int], note,
             limite: int) -> list[list[int]] | None:
    """Découpe aux jetons estimés : chaque partie prend, dans l'ordre, autant de groupes qu'elle peut sans dépasser
    `limite` (dichotomie : les jetons croissent avec les groupes ajoutés). None si un groupe seul la dépasse."""
    parties: list[list[int]] = []
    total = len(groupes)
    silencieux = muets(note, tous, affect)

    def jetons(debut: int, fin: int) -> int:
        """Les jetons de la partie suivante si elle prend les groupes [debut, fin)."""
        essai = parties + [[v for g in groupes[debut:fin] for v in g]]
        if fin < total:
            essai.append([v for g in groupes[fin:] for v in g])
        pts = points_des_parties(note, essai, affect, silencieux)
        i = len(parties)
        with godot.simulation(types):
            e = generer(ville, n, set(essai[i]), {x for p in parties for x in p}, pts[i][0], pts[i][1],
                        (i + 1, len(essai)), avant, apres, tous, affect, note)
        return e["opencode"]["jetons"]

    debut = 0
    while debut < total:
        bas, haut = debut + 1, total
        if jetons(debut, bas) > limite:
            return None
        while bas < haut:
            milieu = (bas + haut + 1) // 2
            if jetons(debut, milieu) <= limite:
                bas = milieu
            else:
                haut = milieu - 1
        parties.append([v for g in groupes[debut:bas] for v in g])
        debut = bas
    return parties


def _decouper(ville: str, n: int, parties: list[list[int]], avant: dict[str, str], apres: dict[str, str],
              tous: list[etat.Morceau], affect: dict[int, int], note, journal) -> list[dict]:
    """Les exemples d'une découpe, Godot lancé. Une partie qui ne se compile pas rejoint la suivante."""
    parties = [list(p) for p in parties]
    sortie: list[dict] = []
    i = 0
    while i < len(parties):
        depuis = {x for p in parties[:i] for x in p}
        pts = points_des_parties(note, parties, affect, muets(note, tous, affect))
        try:
            e = generer(ville, n, set(parties[i]), depuis, pts[i][0], pts[i][1], (i + 1, len(parties)),
                        avant, apres, tous, affect, note)
        except EchecPartie as exc:
            journal(f"  {ville} {n:03d} : partie {i + 1} refusée, fusion avec la suivante : {str(exc)[:300]}")
            parties[i] = parties[i] + parties[i + 1]
            parties.pop(i + 1)
            # Le nombre de parties change : chaque partie le dit (« partie 1 sur 3 »), on les refait toutes.
            # Godot ne repasse pas sur les états déjà vus (sorties gardées).
            sortie, i = [], 0
            continue
        sortie.append(e)
        i += 1
    for j, e in enumerate(sortie, 1):
        e["partie"] = [j, len(sortie)]
        e["id"] = f"{ville}-{n:03d}-creation" + (f"-p{j}" if len(sortie) > 1 else "")
    for e in sortie:
        # Les jetons qui comptent sont ceux de l'exemple au format d'OpenCode, celui de l'entraînement.
        e["preuves"]["jetons"], e["preuves"]["jetons_reponse"] = e["opencode"]["jetons"], e["opencode"]["jetons_reponse"]
    return sortie


def exemples(ville: str, n: int, journal=print) -> list[dict]:
    """Les exemples de création de l'étape : un seul si l'étape tient sous la limite de jetons, sinon une suite de
    parties qui se compilent chacune. Chaque découpe est d'abord estimée sans Godot ; Godot ne tourne que sur une
    découpe dont l'estimation tient. L'ordre des essais : l'étape entière, la découpe aux jetons estimés (le moins
    de parties possible : le prompt d'OpenCode et ses outils, 13 400 jetons, reviennent dans chacune), puis les
    découpes à un budget de caractères."""
    note = notes_mod.lire(ville, n)
    avant, apres = etats(ville, n)
    tous = rattacher.decouper(etat.morceaux(avant, apres))
    affect = rattacher.rattacher(note, tous, apres)
    textes_points = {p.numero: len(p.texte) for p in note.points}
    groupes = ordonner.ordre(tous, affect, avant, composer.ordre_fichier, apres)
    types = sorties_types(ville, n, apres, tous)
    meilleur: list[dict] = []
    trop_longues: list[tuple[int, list[list[int]]]] = []
    vues: set = set()

    def decoupes():
        yield [[v for g in groupes for v in g]]
        try:
            gloutonne = _glouton(ville, n, groupes, types, avant, apres, tous, affect, note, LIMITE_JETONS - MARGE)
        except KeyError:
            gloutonne = None
        if gloutonne:
            yield gloutonne
        for budget in (55000, 45000, 35000, 24000, 16000, 11000, 8000):
            yield ordonner.empaqueter(groupes, tous, affect, textes_points, budget)

    for parties in decoupes():
        cle = tuple(tuple(p) for p in parties)
        if cle in vues:
            continue
        vues.add(cle)
        estimes = _estimer(ville, n, parties, types, avant, apres, tous, affect, note)
        if estimes is not None and max(estimes) > LIMITE_JETONS:
            journal(f"  {ville} {n:03d} : {len(parties)} partie(s), {max(estimes)} jetons estimés au plus : "
                    "trop long, découpe suivante")
            trop_longues.append((max(estimes), parties))
            continue
        sortie = _decouper(ville, n, parties, avant, apres, tous, affect, note, journal)
        if all(e["preuves"]["jetons"] <= LIMITE_JETONS for e in sortie):
            return sortie
        if not meilleur or max(e["preuves"]["jetons"] for e in sortie) < max(e["preuves"]["jetons"] for e in meilleur):
            meilleur = sortie
    if not meilleur and trop_longues:
        # Aucune découpe n'entre : la plus courte est générée, marquée trop longue (l'assemblage la signale).
        meilleur = _decouper(ville, n, min(trop_longues, key=lambda t: t[0])[1], avant, apres, tous, affect, note,
                             journal)
    for e in meilleur:
        e["preuves"]["trop_long"] = e["preuves"]["jetons"] > HARD_JETONS
    return meilleur
