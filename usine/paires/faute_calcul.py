"""Famille de paires « une valeur fausse → la ligne de calcul » (demande de laurent du 2026-11-01 : « fait un maximum de
paires sur le sujet que qwen apprennen a code des fluide sous godot »).

La famille `execution` pose des fautes de nœuds : un simulateur n'en a presque pas. Ses bogues sont numériques : un signe, une
case décalée, un facteur oublié, un axe ou un champ inversé, une borne à l'envers, une ligne manquante. Le script se charge,
le shader compile, le calcul tourne : seul un test voit que le résultat est faux, et il ne dit pas où.

Le code vérifié d'un cours (`.gd` et shaders de calcul `.glsl`), étape par étape, reçoit une seule faute. Gardée seulement si :
- le script s'analyse sans rien signaler, ou le shader compile (`7_tests/check_shaders.gd`) : ce n'est pas une erreur de compilation ;
- une suite qui charge ce code échoue sur un cas, avec le message de GdUnit4 ; ce cas, lancé seul, échoue encore ;
- une fois la ligne corrigée, la même commande passe.

Un `.glsl` n'est relu par Godot qu'à l'import : chaque changement de shader est suivi d'un `--import`. Les suites d'un dossier
`gpu` tournent sur le bureau caché (`godot.tester_gdunit`) : aucune fenêtre visible, la souris reste libre.

La demande montre la sortie du cas et la fonction fautive ; la réponse lit le message, cherche dans le contrat de la fonction,
corrige la ligne, relance (sortie non écrite, règle 7.2). Palier 1 si la paire tient en 1 024 jetons, sinon palier 2 avec le plan.

    python -m usine.paires faute_calcul [--cours fluides] [--par-etape N] [--graine G] [--etapes 1,2] [--depuis N]

Une reprise (`--etapes`) ne repose pas les fautes déjà gardées. `--depuis N` ne regarde que les fichiers qui ont changé depuis
l'étape N : les fautes écartées avant n'ont pas été notées, et les réessayer coûterait des heures.
"""

from __future__ import annotations

import json
import random
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable

from usine.paires import boucle
from usine.paires import format as fmt

FAMILLE = "faute_calcul"
PLAFOND_COURT, PLAFOND = 1024, 2048
DOSSIERS = ("1_core/", "2_sequence/")
DELAI_TEST = 90
FONCTION_GD = re.compile(r"^(?:static )?func (\w+)\(")
CHECK_SHADERS = "res://7_tests/check_shaders.gd"
# Une ligne qui n'est qu'un appel : la retirer laisse un code qui se charge. Pas les écritures dans la console, ni l'arrêt.
APPEL_GD = re.compile(r"^\t+(?!push_|print|assert|quit|super|return\b)[\w.]+\(.*\)$")
APPEL_GLSL = re.compile(r"^\t+\w+\(.*\);$")
# Le message d'un cas rouge : « … <TAB>at 'cas' in res://suite.gd:28 ».
LIEU = re.compile(r"\s*at '\w+' in (res://\S+:\d+)\s*$")
ECHEC = re.compile(r"^\s*res://\S+ > (\w+) FAILED\b")
# Sur la carte, une boucle sans fin ou une lecture hors d'un tampon ne donne pas un test rouge : elle peut bloquer le pilote, et c'est
# après des plantages en série dans le pilote que le poste de laurent a fait son écran bleu du 2026-11-01. Aucune faute sur ces lignes.
DANGER_CARTE = re.compile(r"^\s*(?:for|while)\b|\.data\[[^\]]*[-+*][^\]]*\]")
REMPLACE = re.compile(r"Dans `res://(?P<rel>[^`]+)`, ligne \d+, je remplace :\n```\w*\n(?P<fautif>.*?)\n```\npar :\n```\w*\n(?P<juste>.*?)\n```", re.S)
AUTRE_CAS = re.compile(r"^\s*res://\S+ > \w+ (STARTED|PASSED|FAILED)\b|^Statistics:")

# (genre, motif, remplacement). Le remplacement est un gabarit de `re.Match.expand`.
REGLES: tuple[tuple[str, re.Pattern[str], str], ...] = (
    ("signe", re.compile(r"(?<=[\w)\]]) - (?!1(?![\d.]))(?=[\w(])"), " + "),
    ("signe", re.compile(r"(?<=[\w)\]]) \+ (?!1(?![\d.]))(?=[\w(])"), " - "),
    ("signe", re.compile(r"(?<=[(, ])-(?=[a-z_(])"), ""),
    ("decalage", re.compile(r" [-+] 1(?![\d.])"), ""),
    ("facteur", re.compile(r"\b0\.5 \* "), ""),
    ("facteur", re.compile(r" \* 0\.5\b"), ""),
    ("facteur", re.compile(r"\b0\.25\b"), "0.5"),
    ("facteur", re.compile(r" \* delta\b"), ""),
    ("facteur", re.compile(r"\bdelta \* "), ""),
    ("facteur", re.compile(r"\bconstants\.delta \* "), ""),
    ("borne", re.compile(r"\bminf\("), "maxf("),
    ("borne", re.compile(r"\bmaxf\("), "minf("),
    ("borne", re.compile(r"\bmini\("), "maxi("),
    ("borne", re.compile(r"\bmaxi\("), "mini("),
    ("borne", re.compile(r"\bmin\("), "max("),
    ("borne", re.compile(r"\bmax\("), "min("),
    ("comparaison", re.compile(r" > "), " < "),
    ("comparaison", re.compile(r" < "), " > "),
    ("comparaison", re.compile(r" >= "), " < "),
    ("comparaison", re.compile(r" <= "), " > "),
    ("logique", re.compile(r" and "), " or "),
    ("logique", re.compile(r" or "), " and "),
    ("logique", re.compile(r" && "), " || "),
    ("logique", re.compile(r" \|\| "), " && "),
    ("logique", re.compile(r"\bif not "), "if "),
    ("axe", re.compile(r"\.x\b"), ".y"),
    ("axe", re.compile(r"\.y\b"), ".x"),
    ("axe", re.compile(r"\bivec2\(1, 0\)"), "ivec2(0, 1)"),
    ("axe", re.compile(r"\bivec2\(0, 1\)"), "ivec2(1, 0)"),
    ("axe", re.compile(r"\((\w+) ([-+]) 1, (\w+)\)"), r"(\1, \3 \2 1)"),
    ("axe", re.compile(r"\((\w+), (\w+) ([-+]) 1\)"), r"(\1 \3 1, \2)"),
    ("axe", re.compile(r"\bwidth\b"), "height"),
    ("axe", re.compile(r"\bheight\b"), "width"),
    ("champ", re.compile(r"\bu\b"), "v"),
    ("champ", re.compile(r"\bv\b"), "u"),
    ("champ", re.compile(r"\bspeed_x\b"), "speed_y"),
    ("champ", re.compile(r"\bspeed_y\b"), "speed_x"),
    ("champ", re.compile(r"\bforward\b"), "backward"),
    ("champ", re.compile(r"\bbackward\b"), "forward"),
)

# Ce que la lecture dit de la ligne fautive ; `de` : ce qui devrait y être, `vers` : ce qui y est.
DIAGNOSTICS = {
    "signe": "le signe est inversé : `{vers}` à la place de `{de}`",
    "decalage": "la case visée n'est pas la bonne : `{vers}` à la place de `{de}`",
    "facteur": "le facteur n'y est pas : `{vers}` à la place de `{de}`",
    "borne": "la borne est à l'envers : `{vers}` à la place de `{de}`",
    "comparaison": "la comparaison est à l'envers : `{vers}` à la place de `{de}`",
    "logique": "les conditions se combinent mal : `{vers}` à la place de `{de}`",
    "axe": "les deux axes sont mélangés : `{vers}` à la place de `{de}`",
    "champ": "ce n'est pas le bon champ : `{vers}` à la place de `{de}`",
    "oubli": "il manque l'étape `{de}`",
}


@dataclass
class Faute:
    genre: str
    fichier: str
    ligne: int      # 1-based, la ligne fautive, ou celle qui manque
    juste: str      # le passage juste
    fautif: str     # le passage fautif
    texte: str      # le fichier entier avec la faute
    de: str
    vers: str

    def cle(self) -> tuple[str, str, str]:
        return fmt.commun(self.fichier), fmt.commun(self.juste), fmt.commun(self.fautif)


def lignes_de_calcul(rel: str, texte: str) -> list[tuple[int, str]]:
    """(numéro, ligne) des lignes de code d'un corps de fonction : ni commentaire, ni signature, ni texte entre guillemets."""
    sortie = []
    for n, ligne in enumerate(texte.split("\n"), 1):
        code = ligne.strip()
        if not ligne.startswith("\t") or not code or code.startswith(("#", "//", "@")):
            continue
        if '"' in ligne or "->" in ligne or code in ("return", "continue", "break", "pass"):
            continue
        sortie.append((n, ligne))
    return sortie


def _remplacer(lignes: list[str], n: int, nouvelle: str | None) -> str:
    """Le fichier avec la ligne `n` remplacée, ou retirée si `nouvelle` est None."""
    return "\n".join(lignes[:n - 1] + ([] if nouvelle is None else [nouvelle]) + lignes[n:])


def fautes(rel: str, texte: str) -> list[Faute]:
    """Toutes les fautes de calcul qu'on peut poser dans ce fichier, une par occurrence de chaque règle."""
    lignes = texte.split("\n")
    sortie: list[Faute] = []
    for n, ligne in lignes_de_calcul(rel, texte):
        if rel.endswith(".glsl") and DANGER_CARTE.search(ligne):
            continue
        for genre, motif, gabarit in REGLES:
            for m in motif.finditer(ligne):
                nouveau = m.expand(gabarit)
                nouvelle = ligne[:m.start()] + nouveau + ligne[m.end():]
                sortie.append(Faute(genre, rel, n, ligne, nouvelle, _remplacer(lignes, n, nouvelle),
                                    m.group(0).strip() or m.group(0), nouveau.strip() or "rien"))
        appel = APPEL_GLSL if rel.endswith(".glsl") else APPEL_GD
        if appel.match(ligne) and n >= 2:
            precedente = lignes[n - 2]
            sortie.append(Faute("oubli", rel, n, f"{precedente}\n{ligne}", precedente, _remplacer(lignes, n, None),
                                ligne.strip(), "rien"))
    return sortie


def fonction_de(rel: str, texte: str, ligne: int) -> tuple[str, list[str], str] | None:
    """(nom, lignes du contrat, code avec son contrat) de la fonction qui contient la ligne ; None hors d'une fonction."""
    from usine.paires import shader_fonction
    lignes = texte.split("\n")
    if rel.endswith(".glsl"):
        for f in shader_fonction.fonctions(texte):
            if f.ligne < ligne - 1 <= f.fin:
                return f.nom, [l.lstrip("/ ").strip() for l in lignes[f.doc:f.ligne]], "\n".join(lignes[f.doc:f.fin + 1])
        return None
    debut = next((k for k in range(min(ligne - 1, len(lignes) - 1), -1, -1) if FONCTION_GD.match(lignes[k])), None)
    if debut is None:
        return None
    fin = debut
    for k in range(debut + 1, len(lignes)):
        if lignes[k].strip() and not lignes[k].startswith("\t"):
            break
        if lignes[k].strip():
            fin = k
    doc = debut
    while doc > 0 and lignes[doc - 1].startswith("##"):
        doc -= 1
    nom = FONCTION_GD.match(lignes[debut])[1]
    return nom, [l.lstrip("# ").strip() for l in lignes[doc:debut]], "\n".join(lignes[doc:fin + 1])


def suites_de(apres: dict[str, str], rel: str) -> list[str]:
    """Les suites qui jugent ce fichier. Un `.glsl` n'est nommé que par le script qui le charge, ou par une suite directement."""
    from usine.cours.base import profil
    from usine.paires import execution
    if not rel.endswith(".glsl"):
        return execution.suites_pour(apres, rel)
    toutes = set(profil.suites(apres))
    sortie: list[str] = []
    for r, t in sorted(apres.items()):
        if r.endswith(".gd") and f"res://{rel}" in t:
            sortie += [s for s in ([r] if r in toutes else execution.suites_pour(apres, r)) if s not in sortie]
    return sortie


def reproche(texte: str, cas: str) -> tuple[str, str] | None:
    """(ce que GdUnit4 reproche au cas, tel qu'il l'écrit ; suite:ligne) : le premier message après « FAILED »."""
    lignes = texte.splitlines()
    debut = next((i for i, l in enumerate(lignes) if (m := ECHEC.match(l)) and m[1] == cas), None)
    if debut is None:
        return None
    message: list[str] = []
    for l in lignes[debut + 1:]:
        if AUTRE_CAS.match(l):
            return None
        if l.strip() == "Report:":
            continue
        m = LIEU.search(l)
        if m:
            message.append(l[:m.start()].strip())
            return " ".join(x for x in message if x), m[1]
        message.append(l.strip())
    return None


def _importer(projet: Any, f: Faute) -> Any:
    """La sortie de l'import d'un shader, ou None pour un script : Godot n'a rien à relire."""
    from usine.cours.base import godot
    return godot.importer(projet.chemin) if f.fichier.endswith(".glsl") else None


def _se_charge(projet: Any, f: Faute) -> bool:
    """Vrai si la faute laisse le code se charger : ce n'est pas une erreur de compilation."""
    from usine.cours.base import godot, sessions
    if f.fichier.endswith(".glsl"):
        return godot.tester(projet.chemin, CHECK_SHADERS, 60).code == 0
    return sessions.propre("analyse", projet.lancer("analyse", f.fichier))


def rouge(projet: Any, suites: list[str]) -> tuple[Any, str, str, list[str], tuple[str, str]] | None:
    """(sortie du cas seul, suite, cas, cas écartés, reproche) : le premier cas rouge, lancé seul ; None si rien ne voit la faute."""
    from usine.cours.base import godot, profil
    for suite in suites[:3]:
        s = godot.tester_gdunit(projet.chemin, ["res://" + suite], DELAI_TEST)
        if s.code == 0 or profil.resume_gdunit(s.texte) is None:
            continue
        rouges = boucle.cas_rouges(projet.apres[suite], s.texte, suite)
        if not rouges:
            continue
        cas = rouges[0]
        ignorer = boucle.ecartes(projet.apres[suite], [cas], suite)
        seul = godot.tester_gdunit(projet.chemin, ["res://" + suite], DELAI_TEST, ignorer)
        dit = reproche(seul.texte, cas)
        if seul.code != 0 and dit is not None:
            return seul, suite, cas, ignorer, dit
    return None


def reponse(f: Faute, cas: str, dit: tuple[str, str], nom: str, classe: str | None, contrat: list[str]) -> str:
    message, lieu = dit
    lang = "glsl" if f.fichier.endswith(".glsl") else "gdscript"
    qui = f"`{classe}.{nom}`" if classe else f"`{nom}`"
    regle = " ".join(contrat)
    diagnostic = DIAGNOSTICS[f.genre].format(de=f.de, vers=f.vers)
    lignes = [f"**Lire.** Rien ne plante : le calcul tourne, et c'est son résultat qui est faux. Le cas `{cas}` échoue à "
              f"`{lieu}` : « {message} ».", "",
              f"**Chercher.** Le fautif est dans {qui}" + (f", dont le contrat dit : « {regle} »" if regle else "") + ". Je compare "
              f"le code à cette règle, ligne par ligne. Ligne {f.ligne} : {diagnostic}.", "",
              "**Corriger.** Une seule ligne change :", f"Dans `res://{f.fichier}`, ligne {f.ligne}, je remplace :",
              f"```{lang}\n{f.fautif}\n```", "par :", f"```{lang}\n{f.juste}\n```", ""]
    if f.fichier.endswith(".glsl"):
        lignes += ["**Tester.** Godot ne relit un `.glsl` qu'à l'import : je réimporte, puis je relance la même commande, celle de "
                   "la demande.", "```\n$ godot --headless --path . --import\n```"]
    else:
        lignes.append("**Tester.** Je relance la même commande, celle de la demande.")
    return "\n".join(lignes)


def paire(projet: Any, f: Faute, sujet: str) -> tuple[dict[str, Any] | None, str]:
    """La paire de cette faute, ou (None, raison du rejet). Le projet revient à l'état de l'étape."""
    from usine.cours.base import godot, profil
    from usine.paires import execution
    suites = suites_de(projet.apres, f.fichier)
    if not suites:
        return None, "aucune suite ne charge ce fichier"
    trouve = fonction_de(f.fichier, f.texte, f.ligne)
    if trouve is None:
        return None, "hors d'une fonction"
    nom, contrat, code = trouve
    projet.remettre()
    projet.ecrire(f.fichier, f.texte)
    _importer(projet, f)
    remis = False
    try:
        if not _se_charge(projet, f):
            return None, "ne se charge plus : une erreur de compilation, pas de calcul"
        vu = rouge(projet, suites)
        if vu is None:
            return None, "aucune suite ne voit la faute"
        s, suite, cas, ignorer, dit = vu
        projet.remettre()
        importation = _importer(projet, f)
        remis = True
        apres = godot.tester_gdunit(projet.chemin, ["res://" + suite], DELAI_TEST, ignorer)
        if not profil.test_reussi(apres.code, apres.texte, profil.messages_attendus(projet.apres)):
            return None, "le cas ne passe pas une fois la ligne corrigée"
    finally:
        projet.remettre()
        if not remis:
            _importer(projet, f)
    classe = profil.CLASSE.search(projet.apres[f.fichier])
    lang = "glsl" if f.fichier.endswith(".glsl") else "gdscript"
    seul = f", cas `{cas}` seul," if ignorer else ""
    demande = (f"Projet Godot 4.7.2. Les tests de `res://{suite}`{seul} donnent :\n{execution.bloc_court(s)}\n\n"
               f"Le code jugé, dans `res://{f.fichier}` :\n```{lang}\n{code}\n```\n\nCorrige l'erreur.")
    texte = reponse(f, cas, dit, nom, classe[1] if classe else None, contrat)
    preuve = {"outil": "gdunit4", "commande": s.commande, "sortie": s.texte, "code": s.code, "sortie_apres": apres.texte,
              "code_apres": apres.code, "etape": f"{projet.ville}-{projet.n:03d}", "fichier": f.fichier, "ligne": f.ligne,
              "genre": f.genre, "suite": suite, "cas": cas, "fonction": nom}
    if importation is not None:
        preuve.update(commande_import=importation.commande, sortie_import=importation.texte, code_import=importation.code)
    courte = fmt.paire(FAMILLE, sujet, "débogage", demande, texte, dict(preuve, palier=1))
    if courte["jetons"] <= PLAFOND_COURT:
        return courte, ""
    longue = fmt.paire(FAMILLE, sujet, "débogage", demande, texte, dict(preuve, palier=2), systeme=fmt.plan())
    if longue["jetons"] > PLAFOND:
        return None, f"trop longue ({longue['jetons']} jetons)"
    return longue, ""


def _sujet(ville: str, n: int, rel: str) -> str:
    from usine.paires.execution import _sujet as sujet_fichier
    return "shaders" if rel.endswith(".glsl") else sujet_fichier(ville, n, rel)


def deja_gardees(sortie: Path, cours: str) -> set[tuple[str, str, str]]:
    """Les fautes déjà gardées pour ce cours, dans tous ses fichiers de paires. Une génération reprise à une étape ne les repose pas
    (règle 7.7) : la même faute redonnerait une paire presque identique, que le contrôle des doublons exacts ne voit pas, parce que
    les durées de la sortie changent à chaque lancement."""
    vues: set[tuple[str, str, str]] = set()
    for f in sorted(sortie.glob(f"paires_{cours}*.jsonl")):
        for ligne in f.read_text(encoding="utf-8").splitlines():
            m = REMPLACE.search(json.loads(ligne)["messages"][-1]["content"]) if ligne.strip() else None
            if m:
                vues.add((fmt.commun(m["rel"]), fmt.commun(m["juste"]), fmt.commun(m["fautif"])))
    return vues


def generer(cours: str = "fluides", par_etape: int = 60, graine: int = 1, etapes: list[int] | None = None,
            donnees: Path | None = None, journal: Callable[[str], None] = print, depuis: int | None = None) -> dict[str, Any]:
    """`par_etape` fautes essayées par étape, genres à tour de rôle (graine fixe) ; une faute essayée ne revient pas à l'étape suivante."""
    from usine.cours.base import assembler, chemins, creation, sessions
    chemins.configurer(cours=cours)
    sortie = fmt.dossier(FAMILLE, donnees)
    paires: list[dict[str, Any]] = []
    rejets: list[str] = []
    rng = random.Random(graine)
    vues = deja_gardees(sortie, cours) if etapes else set()
    for ville in assembler.ordre_lignes():
        base = creation.etats(ville, depuis)[1] if depuis else {}
        for n in etapes or list(assembler.etapes_du_cours()):
            _, apres = creation.etats(ville, n)
            dispo = [f for rel in sorted(apres) if rel.endswith((".gd", ".glsl")) and rel.startswith(DOSSIERS)
                     and apres[rel] != base.get(rel) for f in fautes(rel, apres[rel]) if f.cle() not in vues]
            if not dispo:
                continue
            par_genre: dict[str, list[Faute]] = {}
            for f in dispo:
                par_genre.setdefault(f.genre, []).append(f)
            for liste in par_genre.values():
                rng.shuffle(liste)
            choisies: list[Faute] = []
            while len(choisies) < par_etape and any(par_genre.values()):
                for g in sorted(par_genre):
                    if par_genre[g] and len(choisies) < par_etape:
                        choisies.append(par_genre[g].pop())
            projet = sessions.Projet(ville, n, apres, espace="faute")
            gardees = 0
            for f in choisies:
                vues.add(f.cle())
                p, raison = paire(projet, f, _sujet(ville, n, f.fichier))
                if p is None:
                    rejets.append(f"{ville}-{n:03d} {f.fichier}:{f.ligne} {f.genre} : {raison}")
                    continue
                paires.append(p)
                gardees += 1
            journal(f"{ville}-{n:03d} : {gardees}/{len(choisies)} paires, {len(dispo)} fautes possibles")
            fmt.ecrire(paires, sortie / f"paires_{cours}.jsonl")
    bilan: dict[str, Any] = {"famille": FAMILLE, "cours": cours, "paires": len(paires), "rejets": rejets, "par_genre": {},
                             "par_sujet": {}, "par_palier": {}, "jetons_max": max((p["jetons"] for p in paires), default=0),
                             "jetons_moyens": round(sum(p["jetons"] for p in paires) / max(len(paires), 1))}
    for p in paires:
        for cle, val in (("par_genre", p["preuve"]["genre"]), ("par_sujet", p["sujet"]), ("par_palier", p["preuve"]["palier"])):
            bilan[cle][val] = bilan[cle].get(val, 0) + 1
    (sortie / f"bilan_{cours}.json").write_text(json.dumps(bilan, indent=1, ensure_ascii=False), encoding="utf-8")
    return bilan
