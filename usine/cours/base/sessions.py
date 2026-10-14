"""Sessions de débogage, à une ou plusieurs erreurs, en plusieurs tours.

Godot montre les erreurs par vagues : une faute de syntaxe cache le reste de l'analyse du script ; les shaders ne se
compilent qu'au rendu ; certaines fautes n'apparaissent qu'à l'exécution du test. On corrige ce que Godot montre, on
relance, on voit la suite. Chaque sortie (Godot, grep) arrive dans un tour « user » : la réponse ne l'invente jamais.
Toutes les sorties sont réelles : chaque commande a été lancée sur le projet dans l'état où la session l'a mis."""
from __future__ import annotations

import os
import random
import re
import shutil
from collections import OrderedDict

from usine.cours.base import composer, creation, debogage, etat, godot, jetons, mutations, textes
from usine.cours.base.chemins import actuels
from usine.cours.base.etat import CODE
from usine.processus import executer

CAUSES = {"godot3_annotation": "syntaxe de Godot 3", "godot3_nom": "nom de Godot 3",
          "godot3_shader": "nom de Godot 3 dans un shader", "non_type": "déclaration sans type",
          "type": "type entier pour une valeur décimale", "appel": "appel à une fonction qui n’existe pas",
          "shader_litteral": "entier là où le shader attend un float"}
AT = re.compile(r"^\s*at: .*\(res://([^():]+):(\d+)\)\s*$")
MESSAGE = re.compile(r"^(SCRIPT ERROR|SHADER ERROR|ERROR|USER ERROR|SCRIPT WARNING|WARNING): ")
NOMS_PHASE = {"analyse": "analyse du script", "rendu": "rendu en Compatibilité", "test": "test de l'étape",
              "grep": "recherche des mêmes fautes"}


class SessionInvalide(Exception):
    """La session ne peut pas aller au bout : `a_ecarter` sont les erreurs à ne plus proposer."""

    def __init__(self, raison: str, a_ecarter: list[mutations.Mutation]):
        super().__init__(raison)
        self.raison = raison
        self.a_ecarter = a_ecarter


def quoi(m: mutations.Mutation) -> tuple[str, int]:
    return m.fichier, m.ligne


# --------------------------------------------------------------------------------------------- le projet
class Projet:
    """Un projet Godot matérialisé une fois par étape ; chaque session y pose ses erreurs puis les corrige."""

    def __init__(self, ville: str, n: int, apres: dict[str, str]):
        self.ville, self.n, self.apres = ville, n, apres
        self.chemin = godot.materialiser(dict(apres), f"sess_{ville}_{n:03d}")
        godot.importer(self.chemin)
        self.code = {k: v for k, v in apres.items() if k.endswith(CODE)}
        self.png = actuels().rendus / f"sess_{ville}_{n:03d}.png"

    def ecrire(self, rel: str, texte: str) -> None:
        self.code[rel] = texte
        with open(os.path.join(self.chemin, rel), "w", encoding="utf-8", newline="") as h:
            h.write(texte)

    def remettre(self) -> None:
        for rel, t in list(self.code.items()):
            if t != self.apres[rel]:
                self.ecrire(rel, self.apres[rel])

    def poser(self, m: mutations.Mutation, fautive: bool) -> None:
        lignes = self.code[m.fichier].split("\n")
        assert lignes[m.ligne - 1] == (m.avant if fautive else m.apres), (m, fautive)
        lignes[m.ligne - 1] = m.apres if fautive else m.avant
        self.ecrire(m.fichier, "\n".join(lignes))

    def propre_partout(self) -> bool:
        return all(t == self.apres[rel] for rel, t in self.code.items())

    def lancer(self, phase: str, cible: str | None = None) -> godot.Sortie:
        if phase == "analyse":
            return godot.verifier_script(self.chemin, "res://" + cible)
        if phase == "rendu":
            return godot.rendre(self.chemin, self.png)
        if phase == "test":
            return godot.tester(self.chemin, "res://" + creation.TEST.format(nom=etat.nom(self.ville, self.n)))
        raise ValueError(phase)

    def grep(self, motif: str, globs: list[str]) -> godot.Sortie:
        """Une vraie recherche par grep (sous Windows : celui de Git for Windows, dans le PATH)."""
        grep = shutil.which("grep")
        if grep is None:
            raise RuntimeError("grep introuvable : la recherche finale des sessions lance le vrai grep "
                               "(sous Windows, ajouter le dossier usr\\bin de Git for Windows au PATH)")
        args = [grep, "-rnE", motif] + [f"--include={g}" for g in globs] + ["--exclude-dir=.godot", "."]
        res = executer(args, cwd=self.chemin, delai_s=60)
        commande = f"grep -rnE '{motif}' " + " ".join(f"--include='{g}'" for g in globs) + " --exclude-dir=.godot ."
        return godot.Sortie(commande, res.sortie.strip(), res.code if res.code is not None else -1)


# --------------------------------------------------------------------------------------------- lire les sorties
def erreurs(texte: str) -> "OrderedDict[tuple[str, int], str]":
    """(fichier, ligne) → message, dans l'ordre de la sortie ; seules les lignes « at: » qui citent un fichier
    du projet comptent (pas la pile d'appels)."""
    vus: "OrderedDict[tuple[str, int], str]" = OrderedDict()
    dernier = None
    for l in texte.splitlines():
        if MESSAGE.match(l):
            dernier = l.strip()
            continue
        m = AT.match(l)
        if m and dernier:
            vus.setdefault((m[1], int(m[2])), dernier)
            dernier = None
    return vus


def propre(phase: str, s: godot.Sortie) -> bool:
    if phase == "analyse":
        return not s.texte.strip()
    if phase == "rendu":
        return not any("ERROR" in l for l in s.texte.splitlines()) and godot.image_enregistree(s) is not None
    if phase == "test":
        return s.code == 0 and " 0 échec" in s.texte and "SCRIPT ERROR" not in s.texte and "ÉCHEC" not in s.texte
    return not s.texte.strip()


def lignes_ok(s: godot.Sortie) -> list[str]:
    return [l for l in s.texte.splitlines() if l.startswith("ok")]


# --------------------------------------------------------------------------------------------- écrire les tours
def bloc_sortie(s: godot.Sortie, phase: str) -> str:
    """La sortie d'une commande, avec son code de sortie : c'est tout ce que la réponse suivante peut savoir."""
    if phase == "grep":
        corps = s.texte.strip() or "(aucun résultat)"
    else:
        corps = debogage.compacter(s.texte).strip() or creation.SANS_ERREUR
    return f"```\n$ {s.commande}\n{corps}\n(code de sortie : {s.code})\n```"


def passages(projet: Projet, liees: list[mutations.Mutation], rayon: int = 6) -> str:
    """Le code autour de chaque ligne signalée, tel qu'il est dans le projet à ce moment-là."""
    par_fichier: "OrderedDict[str, list[list[int]]]" = OrderedDict()
    for m in liees:
        par_fichier.setdefault(m.fichier, []).append([m.ligne - rayon, m.ligne + rayon])
    morceaux = []
    for rel, plages in par_fichier.items():
        lignes = projet.code[rel].split("\n")
        plages.sort()
        fusion: list[list[int]] = []
        for a, b in plages:
            a, b = max(1, a), min(len(lignes), b)
            if fusion and a <= fusion[-1][1] + 1:
                fusion[-1][1] = max(fusion[-1][1], b)
            else:
                fusion.append([a, b])
        for a, b in fusion:
            extrait = "\n".join(f"{i:>4}  {lignes[i - 1]}" for i in range(a, b + 1))
            morceaux.append(f"`res://{rel}`, lignes {a} à {b} :\n```{composer.langage(rel)}\n{extrait}\n```")
    tete = "Le passage concerné, " if len(morceaux) == 1 else "Les passages concernés :\n\n"
    if len(morceaux) == 1:
        return tete + morceaux[0]
    return tete + "\n\n".join(morceaux)


def tour_sortie(projet: Projet, phase: str, s: godot.Sortie, liees: list[mutations.Mutation]) -> str:
    texte = bloc_sortie(s, phase)
    if liees:
        texte += "\n\n" + passages(projet, liees)
    return texte


def _chercher(liees: list[mutations.Mutation]) -> list[str]:
    r = ["**Chercher.**"]
    if len(liees) == 1:
        return r + debogage.explication(liees[0])
    for m in liees:
        lignes = debogage.explication(m)
        tete = lignes[0]
        if len(tete) > 1 and tete[0].isupper() and tete[1].islower():
            tete = tete[0].lower() + tete[1:]
        r.append(f"- Ligne {m.ligne} de `{os.path.basename(m.fichier)}` : " + tete)
        r += ["  " + l for l in lignes[1:]]
    return r


def _corriger(liees: list[mutations.Mutation]) -> list[str]:
    r = ["**Corriger.** " + ("Une seule ligne change :" if len(liees) == 1 else f"{len(liees)} lignes changent :")]
    for m in sorted(liees, key=lambda m: (m.fichier, m.ligne)):
        lang = composer.langage(m.fichier)
        r += [f"Dans `res://{m.fichier}`, ligne {m.ligne}, je remplace :", f"```{lang}\n{m.apres}\n```",
              "par :", f"```{lang}\n{m.avant}\n```"]
    return r


def tour_correction(projet: Projet, phase: str, s: godot.Sortie, vus: dict, liees: list[mutations.Mutation],
                    commande: str) -> str:
    r = []
    if len(liees) == 1:
        m = liees[0]
        r.append(f"**Lire l'erreur.** Godot signale, dans `res://{m.fichier}` ligne {m.ligne} : « {vus[quoi(m)]} »")
    else:
        r.append(f"**Lire les erreurs.** Godot signale {len(liees)} erreurs :")
        r += [f"- `res://{m.fichier}` ligne {m.ligne} : « {vus[quoi(m)]} »" for m in liees]
    notes = []
    if phase == "analyse" and any(m.genre == "godot3_annotation" for m in liees):
        notes.append("C'est une faute de syntaxe : tant qu'elle est là, Godot n'analyse pas le reste du script. D'autres "
                     "erreurs peuvent se montrer une fois celle-ci corrigée.")
    if phase == "test" and s.code == 0:
        fonctions = list(OrderedDict.fromkeys(re.findall(r"^\s*at: (\w+) \(res://", s.texte, re.M)))
        notes.append("Le test se termine pourtant avec le code 0 : l'erreur arrive à l'exécution, "
                     + (f"la fonction `{fonctions[0]}` s'arrête" if len(fonctions) == 1 else
                        "chaque fonction touchée s'arrête") +
                     " à la ligne fautive, et tout ce qu'elle devait faire après n'est pas fait. Une sortie « ok » ne "
                     "suffit pas : il faut lire chaque ligne.")
    if phase == "rendu":
        for m in liees:
            note = debogage.lecture_extrait_shader(debogage.compacter(s.texte), "res://" + m.fichier, m.ligne, m.apres,
                                                   projet.code[m.fichier]).strip()
            if note:
                notes.append(note)
    if notes:
        if len(liees) == 1:
            r[0] += " " + " ".join(notes)
        else:
            r += [""] + notes
    r += [""] + _chercher(liees) + [""] + _corriger(liees)
    r += ["", "**Tester.** Je relance la même commande :", f"```\n$ {commande}\n```"]
    return "\n".join(r)


# --------------------------------------------------------------------------------------------- une session
def motifs_utiles(projet: Projet, muts: list[mutations.Mutation]) -> list[tuple[str, str]]:
    """(motif, genre) des fautes de la session qu'une recherche peut retrouver, et qui ne trouvent rien dans le code
    juste : sinon la recherche signalerait du code correct."""
    sortie = []
    for m in muts:
        motif = debogage.motif_faute(m)
        if not motif or any(motif == x for x, _ in sortie):
            continue
        shader = m.genre == "godot3_shader"
        juste = sum(len(re.findall(motif, t, re.M)) for rel, t in projet.apres.items()
                    if rel.endswith((".gdshader", ".gdshaderinc") if shader else ".gd"))
        if juste == 0:
            sortie.append((motif, m.genre))
    return sortie


def jouer(projet: Projet, muts: list[mutations.Mutation], desc: str, titre: str) -> dict:
    """Pose les erreurs, puis déroule la session : lancer, lire, corriger, relancer. Rend l'exemple."""
    projet.remettre()
    for m in muts:
        projet.poser(m, True)
    restantes = list(muts)
    gd = sorted({m.fichier for m in muts if m.fichier.endswith(".gd")})
    shaders = sorted({m.fichier for m in muts if not m.fichier.endswith(".gd")})
    phases: list[tuple[str, str | None]] = [("analyse", f) for f in gd] + ([("rendu", None)] if shaders else []) + [("test", None)]
    traces: list[dict] = []
    vues: list[str] = []

    def lancer(i: int) -> godot.Sortie:
        s = projet.lancer(*phases[i])
        traces.append({"commande": s.commande, "sortie": s.texte, "code": s.code})
        return s

    def lier(phase: str, s: godot.Sortie) -> tuple[dict, list[mutations.Mutation]]:
        vus = erreurs(s.texte)
        liees = [m for m in restantes if quoi(m) in vus]
        inconnues = [k for k in vus if not any(quoi(m) == k for m in restantes)]
        if inconnues:
            raise SessionInvalide(f"erreur imprévue {inconnues[:2]} ({phase})", [])
        if not propre(phase, s) and not liees:
            raise SessionInvalide(f"sortie en échec sans erreur reconnue ({phase}) : {s.texte[-300:]!r}", [])
        liees.sort(key=lambda m: list(vus).index(quoi(m)))
        return vus, liees

    # Premier tour : la première commande qui échoue.
    i = 0
    s = lancer(0)
    passees = []
    while propre(phases[i][0], s):
        passees.append(phases[i][0])
        i += 1
        if i == len(phases):
            raise SessionInvalide("aucune commande ne voit les erreurs", list(restantes))
        s = lancer(i)
    vus, liees = lier(phases[i][0], s)
    fichiers = [f"`res://{f}`" for f in gd + shaders]
    intro = {"analyse": "L'analyse du script (avertissements traités en erreurs) donne :",
             "rendu": "Au rendu (Compatibilité), Godot affiche :", "test": "Le test de l'étape donne :"}[phases[i][0]]
    morceaux_deja = (["l'analyse du script passe"] if "analyse" in passees else []) + \
        (["le rendu ne signale rien"] if "rendu" in passees else [])
    deja = (", ".join(morceaux_deja) + ". ").capitalize() if morceaux_deja else ""
    premier = (f"Projet Godot 4.7.2 : {desc}. Je travaille à l'étape {projet.n:03d} ({titre}). J'ai modifié "
               + (" et ".join(fichiers) if len(fichiers) <= 2 else ", ".join(fichiers[:-1]) + " et " + fichiers[-1]) + ".\n\n"
               + deja + intro + "\n" + tour_sortie(projet, phases[i][0], s, liees) + "\n\n"
               "Corrige jusqu'à ce que tout passe : l'analyse du script, le rendu si un shader a changé, et le test de l'étape.")
    messages = [{"role": "system", "content": textes.SYSTEME}, {"role": "user", "content": premier}]
    premier_test_en_echec: godot.Sortie | None = s if phases[i][0] == "test" else None
    corriges: list[mutations.Mutation] = []
    lancees = {"analyse": 0, "rendu": 0, "test": 0, "grep": 0}
    lancees[phases[i][0]] += 1
    for p in passees:
        lancees[p] += 1

    while True:
        phase = phases[i][0]
        if not propre(phase, s):
            vues += [phase] * len(liees)
            messages.append({"role": "assistant", "content": tour_correction(projet, phase, s, vus, liees, s.commande)})
            for m in liees:
                projet.poser(m, False)
                restantes.remove(m)
                corriges.append(m)
            s = lancer(i)
            lancees[phase] += 1
            vus, liees = lier(phase, s)
            messages.append({"role": "user", "content": tour_sortie(projet, phase, s, liees)})
            continue
        # La commande passe : on va à la suivante.
        if i + 1 < len(phases):
            suivante = phases[i + 1][0]
            if suivante == "analyse":
                texte = f"Ce script passe l'analyse. Je lance celle de `res://{phases[i + 1][1]}` :"
            elif suivante == "rendu":
                texte = ("L'analyse du script passe. " if phase == "analyse" else "") + (
                    "Un shader a changé lui aussi, et un shader ne se compile qu'au rendu : je lance une image en "
                    "Compatibilité :")
            else:
                texte = ({"analyse": "L'analyse du script passe.", "rendu": "Le rendu ne signale plus d'erreur."}[phase]
                         + " Je lance le test de l'étape, pour vérifier que tout se construit :")
            i += 1
            s = lancer(i)
            lancees[suivante] += 1
            vus, liees = lier(suivante, s)
            if suivante == "test" and not propre("test", s) and premier_test_en_echec is None:
                premier_test_en_echec = s
            messages.append({"role": "assistant", "content": texte + f"\n```\n$ {s.commande}\n```"})
            messages.append({"role": "user", "content": tour_sortie(projet, suivante, s, liees)})
            continue
        break
    test_final = s

    # Les mêmes fautes ailleurs : une recherche, réelle elle aussi.
    motifs = motifs_utiles(projet, muts)
    recherche = None
    if motifs:
        motif = "|".join(m for m, _ in motifs)
        globs = []
        if any(g != "godot3_shader" for _, g in motifs):
            globs.append("*.gd")
        if any(g == "godot3_shader" for _, g in motifs):
            globs += ["*.gdshader", "*.gdshaderinc"]
        nb = len(lignes_ok(test_final))
        intro_grep = (f"Le test passe : {nb} ligne{'s' if nb > 1 else ''} « ok », aucune « SCRIPT ERROR ». Je cherche "
                      "encore les mêmes fautes ailleurs dans le projet, au cas où une ligne que le test n'exécute pas en "
                      "contiendrait une :")
        g = projet.grep(motif, globs)
        traces.append({"commande": g.commande, "sortie": g.texte, "code": g.code})
        lancees["grep"] += 1
        messages.append({"role": "assistant", "content": intro_grep + f"\n```\n$ {g.commande}\n```"})
        messages.append({"role": "user", "content": bloc_sortie(g, "grep")})
        if g.texte.strip():
            trouvees = []
            for l in g.texte.splitlines():
                mm = re.match(r"^\./([^:]+):(\d+):", l)
                cible = next((m for m in restantes if mm and quoi(m) == (mm[1], int(mm[2]))), None)
                if cible is None:
                    raise SessionInvalide(f"la recherche trouve du code juste : {l[:120]}", [])
                trouvees.append(cible)
            vues += ["recherche"] * len(trouvees)
            r = [f"**Lire.** La recherche trouve encore {len(trouvees)} ligne{'s' if len(trouvees) > 1 else ''} fautive"
                 f"{'s' if len(trouvees) > 1 else ''}. Godot ne les a signalées ni à l'analyse ni pendant le test : le "
                 "test n'exécute pas ces lignes, et l'analyse ne pouvait pas savoir que l'appel est faux.", ""]
            r += _chercher(trouvees) + [""] + _corriger(trouvees)
            r += ["", "**Tester.** Je relance la recherche, puis l'analyse du script :", f"```\n$ {g.commande}\n```"]
            messages.append({"role": "assistant", "content": "\n".join(r)})
            for m in trouvees:
                projet.poser(m, False)
                restantes.remove(m)
                corriges.append(m)
            g2 = projet.grep(motif, globs)
            traces.append({"commande": g2.commande, "sortie": g2.texte, "code": g2.code})
            lancees["grep"] += 1
            if g2.texte.strip():
                raise SessionInvalide("la recherche trouve encore quelque chose après correction", [])
            messages.append({"role": "user", "content": bloc_sortie(g2, "grep")})
            fichier = trouvees[0].fichier
            a = projet.lancer("analyse", fichier)
            traces.append({"commande": a.commande, "sortie": a.texte, "code": a.code})
            lancees["analyse"] += 1
            if not propre("analyse", a):
                raise SessionInvalide("l'analyse échoue après les corrections de la recherche", [])
            messages.append({"role": "assistant", "content": f"La recherche ne trouve plus rien. L'analyse du script :\n```\n$ {a.commande}\n```"})
            messages.append({"role": "user", "content": bloc_sortie(a, "analyse")})
        recherche = True

    if restantes:
        raise SessionInvalide("des erreurs restent invisibles pour Godot", list(restantes))
    if not projet.propre_partout():
        raise SessionInvalide("le projet ne revient pas à l'état juste", [])

    # Dernier tour : vérifier, compte rendu.
    nb = len(lignes_ok(test_final))
    passees_fin = [x for x in ["l'analyse du script" if gd else None, "le rendu en Compatibilité" if shaders else None,
                               f"le test de l'étape ({nb} ligne{'s' if nb > 1 else ''} « ok », aucune « SCRIPT ERROR »)"] if x]
    liste = passees_fin[0] if len(passees_fin) == 1 else ", ".join(passees_fin[:-1]) + " et " + passees_fin[-1]
    r = [f"**Vérifier.** Tout passe : {liste}."
         + ((" La recherche ne trouve plus cette faute ailleurs." if len(corriges) == 1 else
             " La recherche ne trouve plus aucune de ces fautes.") if recherche else "")]
    if premier_test_en_echec is not None:
        avant_ok, apres_ok = lignes_ok(premier_test_en_echec), lignes_ok(test_final)
        changes = [(a, b) for a, b in zip(avant_ok, apres_ok) if a != b]
        if changes:
            r += ["Le test montrait déjà le dégât, sans échouer : une fois corrigé, ces lignes changent :"]
            r += [f"- « {re.sub(r'^ok\s+', '', a)} » devient « {re.sub(r'^ok\s+', '', b)} »." for a, b in changes]
    par_fichier: "OrderedDict[str, list[mutations.Mutation]]" = OrderedDict()
    for m in sorted(corriges, key=lambda m: (m.fichier, m.ligne)):
        par_fichier.setdefault(m.fichier, []).append(m)
    r += ["", "**Compte rendu**",
          "- " + ("Fichier modifié : " if len(par_fichier) == 1 else "Fichiers modifiés : ")
          + ", ".join(f"`res://{f}` (ligne{'s' if len(ms) > 1 else ''} {', '.join(str(m.ligne) for m in ms)})"
                      for f, ms in par_fichier.items()) + "."]
    if len(corriges) == 1:
        r.append(f"- Cause : {CAUSES[corriges[0].genre]}.")
    else:
        r.append(f"- Erreurs corrigées : {len(corriges)} — " + " ; ".join(
            f"ligne {m.ligne} de `{os.path.basename(m.fichier)}`, {CAUSES[m.genre]}" for m in corriges) + ".")
    r.append("- Commandes lancées : " + ", ".join(
        f"{NOMS_PHASE[p]} ({k} fois)" if k > 1 else NOMS_PHASE[p] for p, k in lancees.items() if k) + ".")
    r.append("- Problèmes non résolus : aucun.")
    messages.append({"role": "assistant", "content": "\n".join(r)})
    return {"messages": messages, "genres": [m.genre for m in muts], "nb_erreurs": len(muts),
            "preuves": {"ok": True, "commandes": traces, "vues": vues,
                        "mutations": [{"fichier": m.fichier, "ligne": m.ligne, "genre": m.genre, "avant": m.avant,
                                       "apres": m.apres} for m in muts]}}


# --------------------------------------------------------------------------------------------- choisir les erreurs
def candidats(apres: dict[str, str], tous: list[etat.Morceau]) -> tuple[list, list]:
    """(sur les lignes nouvelles de l'étape, sur les autres lignes des fichiers qu'elle touche)."""
    nouvelles: dict[str, set[int]] = {}
    for m in tous:
        nouvelles.setdefault(m.fichier, set()).update(range(m.n1 + 1, m.n2 + 1))
    neufs, autres = [], []
    for rel, lignes in nouvelles.items():
        if rel.startswith("7_tests/") or not rel.endswith(CODE) or rel not in apres:
            continue
        toutes = set(range(1, len(apres[rel].split("\n")) + 1))
        tout = mutations.candidates(rel, apres[rel], toutes)
        if rel.endswith(".gd"):
            tout += mutations.appels_internes(rel, apres[rel], toutes)
        for c in tout:
            (neufs if c.ligne in lignes else autres).append(c)
    return neufs, autres


def tirer(hasard: random.Random, dispo: list, lignes_prises: set, exclus_fichiers: set) -> list:
    """Une combinaison : un script (2 à 4 erreurs de genres variés, une seule faute de syntaxe au plus) et, s'il y
    en a, un shader rendu dans la scène (0 à 2 erreurs)."""
    libres = [c for c in dispo if (c.fichier, c.ligne) not in lignes_prises and c.fichier not in exclus_fichiers]
    par_fichier: dict[str, list] = {}
    for c in libres:
        par_fichier.setdefault(c.fichier, []).append(c)
    scripts = [f for f, cs in par_fichier.items() if f.endswith(".gd") and len({c.ligne for c in cs}) >= 2]
    shaders = [f for f, cs in par_fichier.items() if not f.endswith(".gd")]
    if not scripts:
        return []
    f = hasard.choice(sorted(scripts))
    k_gd = hasard.choice([2, 3, 3, 4])
    genres = sorted({c.genre for c in par_fichier[f]})
    hasard.shuffle(genres)
    choisis: list = []
    lignes: set = set()
    syntaxe = 0
    tours = 0
    while len(choisis) < k_gd and tours < 40:
        tours += 1
        g = genres[len(choisis) % len(genres)]
        if g == "godot3_annotation" and syntaxe:
            g = next((x for x in genres if x != "godot3_annotation"), None)
            if g is None:
                break
        pris = [c for c in par_fichier[f] if c.genre == g and c.ligne not in lignes]
        if not pris:
            genres = [x for x in genres if x != g] or genres
            if not any(c.ligne not in lignes for c in par_fichier[f]):
                break
            continue
        c = hasard.choice(pris)
        choisis.append(c)
        lignes.add(c.ligne)
        syntaxe += c.genre == "godot3_annotation"
    k_sh = hasard.choice([0, 1, 1, 2]) if shaders else 0
    if k_sh:
        sf = hasard.choice(sorted(shaders))
        pris = list(par_fichier[sf])
        hasard.shuffle(pris)
        vus_l: set = set()
        for c in pris:
            if c.ligne not in vus_l and len(vus_l) < k_sh:
                choisis.append(c)
                vus_l.add(c.ligne)
    return choisis


def tokens_reponse(messages: list[dict]) -> int:
    return jetons.compter_messages(messages)[1]
