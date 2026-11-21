"""Famille « plomberie de projet » (décision 24 de laurent, 2026-11-18 : « on ajoute il faut que le lora soit solide ») :
un petit projet complet (`plomberie_projet`), une faute de plomberie (`plomberie_fautes`), la preuve par un vrai
lancement sans fenêtre et par les tests de comportement du projet.

Chaque faute est posée sous plusieurs approches (proposition du 2026-11-18, mise en œuvre à la demande de laurent du
2026-11-19 : « nouvelle perspective pour faire comprendre les concepts des anciennes paires ») :

- `sortie` (débogage) : la sortie réelle du lancement, ou des tests pour une faute silencieuse, est donnée ;
- `symptome` (débogage) : seul le symptôme est dit ; la réponse lance d'abord le projet et ses tests ;
- `intention` (création) : la faute est un oubli ; l'état fautif est montré comme l'état actuel, et la demande est le
  changement à faire (« enregistre l'autoload », « ajoute le nœud ») ;
- `analyse` : la sortie est donnée, la réponse dit la cause et le changement à faire, sans rien modifier.

Vérification, pour chaque paire : à l'état fautif, le lancement montre une erreur ou les tests échouent (sorties
réelles de Godot 4.7.2) ; après la correction, telle que la réponse l'écrit, le lancement ne montre rien et tous les
cas passent, sans « SCRIPT ERROR ». Les retours d'outils sont les vraies sorties (règle 7.2) ; la faute n'apparaît
dans une réponse que comme texte à remplacer (règle 7.3). Paires de 2 048 jetons au plus, le plan en message système.

    python -m usine.paires plomberie [--themes N] [--graine G]
"""

from __future__ import annotations

import json
import re
import shutil
from dataclasses import dataclass
from pathlib import Path, PureWindowsPath
from typing import Any, Callable

from usine import config as cfg
from usine.paires import format as fmt

FAMILLE = "plomberie"
PLAFOND = 2048
DOSSIER_WINDOWS = PureWindowsPath(r"D:\GODOT\projet_enseingement\plomberie")
LANCEMENT = ["--headless", "--path", ".", "--quit-after", "60"]
ERREUR = re.compile(r"^(SCRIPT ERROR|ERROR|USER ERROR|WARNING): (.+)$", re.M)
SUJET = "gameplay"


def _slug(texte: str) -> str:
    import unicodedata
    sans = unicodedata.normalize("NFKD", texte).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", "_", sans.lower()).strip("_")


@dataclass
class Kit:
    """Une sorte de petit projet : son thème tiré d'une graine, ses fichiers, ses fautes, ses suites de tests, et la
    suite qui juge chaque faute."""
    nom: str
    theme: Callable[[int], Any]
    fichiers: Callable[[Any], dict[str, str]]
    fautes: Callable[[Any], list[Any]]
    suites: Callable[[Any], list[str]]
    suite_de: Callable[[Any, Any], str]


def _kit_base() -> Kit:
    from usine.paires import plomberie_fautes as pf, plomberie_projet as pp

    def suite_de(th: Any, x: Any) -> str:
        c = pp.chemins(th)
        return c["test_composant"] if x.fichier == c["composant"] and x.silencieuse else c["test_niveau"]
    return Kit("base", pp.theme, pp.fichiers, pf.fautes,
               lambda th: [pp.chemins(th)["test_composant"], pp.chemins(th)["test_niveau"]], suite_de)


def kits() -> dict[str, Kit]:
    from usine.paires import plomberie_kits
    tous = {"base": _kit_base()}
    tous.update(plomberie_kits.kits())
    return tous


class Atelier:
    """Le projet d'un thème, matérialisé une fois ; chaque faute y est posée puis retirée."""

    def __init__(self, graine: int, racine: Path, kit: Kit | None = None):
        from usine.cours.base import godot
        self.kit = kit or _kit_base()
        self.th = self.kit.theme(graine)
        self.sain = self.kit.fichiers(self.th)
        self.chemin = racine / f"plomberie_{self.kit.nom}_{graine:04d}"
        shutil.rmtree(self.chemin, ignore_errors=True)
        self.ecrire(self.sain)
        shutil.copytree(cfg.chemin_gdunit4(), self.chemin / "addons" / "gdUnit4")
        self.godot = godot
        godot.importer(str(self.chemin))
        self.suites = ["res://" + s for s in self.kit.suites(self.th)]
        self.dossier = DOSSIER_WINDOWS / _slug(self.th.projet)

    def ecrire(self, f: dict[str, str]) -> None:
        for rel, texte in f.items():
            chemin = self.chemin / rel
            chemin.parent.mkdir(parents=True, exist_ok=True)
            if not chemin.is_file() or chemin.read_text(encoding="utf-8") != texte:
                chemin.write_text(texte, encoding="utf-8", newline="")

    def lancer(self) -> Any:
        from usine.cours.base.godot import Sortie
        texte, code, brut = self.godot._lancer(LANCEMENT, str(self.chemin), 60)
        return Sortie(self.godot.commande(LANCEMENT), texte, code, brut)

    def tester(self, suites: list[str] | None = None) -> Any:
        return self.godot.tester_gdunit(str(self.chemin), suites or self.suites, delai=120)

    def suite_de(self, x: Any) -> list[str]:
        """La suite qui juge la faute."""
        return ["res://" + self.kit.suite_de(self.th, x)]

    def importer(self) -> Any:
        return self.godot.importer(str(self.chemin))


def _commande(neutre: str) -> str:
    return str(cfg.chemin_godot()) + neutre[len("godot"):]


def _retour(s: Any, tests: bool) -> str:
    from usine.cours.base import debogage, opencode
    from usine.paires.execution import sans_bandeau
    texte = sans_bandeau(s.texte) if tests else s.texte
    corps = debogage.compacter(texte, garder=1, pile=2).strip()
    return opencode.retour_shell(corps + ("\n" if corps else ""), s.code)


def _erreurs(texte: str) -> list[str]:
    return [m.group(0) for m in ERREUR.finditer(texte) if "leaked at exit" not in m.group(0)]


def _echecs(texte: str) -> list[str]:
    return re.findall(r"> (test_\w+) FAILED", texte)


def _propre(lancement: Any, tests: Any | None, attendus: int) -> bool:
    from usine.cours.base import profil
    if _erreurs(lancement.texte):
        return False
    if tests is None:
        return True
    return profil.resume_gdunit(tests.texte) == (attendus, 0, 0) and "SCRIPT ERROR" not in tests.texte


def _montrer(rel: str, texte: str) -> str:
    from usine.paires import plomberie_projet as pp
    langage = "gdscript" if rel.endswith(".gd") else ("ini" if rel == "project.godot" else "")
    contenu = pp.sans_debug(texte) if rel == "project.godot" else texte
    return f"`res://{rel}` :\n```{langage}\n{contenu.rstrip()}\n```"


def _fichiers_montres(at: Atelier, x: Any, etat: dict[str, str], sortie: str) -> list[str]:
    """Le fichier de la faute, et le premier fichier du jeu que la sortie désigne s'il est autre (là où l'erreur se
    montre : le niveau pour un autoload absent), sans les tests ; un seul fichier quand l'erreur est dans celui de la
    faute (chaque fichier montré coûte des jetons que la paire de 2 048 n'a pas)."""
    rels = [x.fichier]
    designes = [r for r in re.findall(r"res://([\w/]+\.(?:gd|tscn))", sortie)
                if r in etat and not r.startswith(("7_tests/", "addons/"))]
    if designes and designes[0] != x.fichier:
        rels.append(designes[0])
    return [_montrer(r, etat[r]) for r in rels]


def _lire_sortie(s: Any, tests: bool) -> str:
    """Ce que dit une sortie : la première erreur, ou les cas qui échouent."""
    erreurs = _erreurs(s.texte)
    if tests and _echecs(s.texte):
        cas = _echecs(s.texte)
        return (f"les tests échouent : {', '.join(f'`{c}`' for c in cas)}"
                + (f" ; la sortie dit aussi « {erreurs[0]} »" if erreurs else " ; aucune erreur de Godot, le "
                   "comportement est faux") + ".")
    if erreurs:
        return f"la première erreur est « {erreurs[0]} »" + (
            f", et {len(erreurs) - 1} autre{'s' if len(erreurs) > 2 else ''} en découle{'nt' if len(erreurs) > 2 else ''}"
            if len(erreurs) > 1 else "") + (". Le code de sortie est 0 malgré l'erreur : seule la lecture de la sortie "
                                            "compte." if s.code == 0 else ".")
    return "aucune erreur."


def _tour_correction(at: Atelier, x: Any, ident: str) -> list[dict[str, Any]]:
    from usine.cours.base import opencode
    chemin = opencode.chemin_windows(str(at.dossier), x.fichier)
    edit = fmt.appel(f"{ident}_edit", "edit", {"path": chemin, "oldString": x.faux, "newString": x.juste})
    return [edit]


def _verifier(at: Atelier, x: Any, ident: str) -> tuple[list[dict[str, Any]], list[tuple[Any, bool]]]:
    """Les appels qui vérifient (import si un nom de classe change, lancement, tests) et leurs sorties réelles."""
    appels: list[dict[str, Any]] = []
    sorties: list[tuple[Any, bool]] = []
    if x.reimport:
        s = at.importer()
        appels.append(fmt.appel(f"{ident}_import", "shell", {"command": _commande(s.commande)}))
        sorties.append((s, False))
    lancement = at.lancer()
    appels.append(fmt.appel(f"{ident}_lancement", "shell", {"command": _commande(lancement.commande)}))
    sorties.append((lancement, False))
    tests = at.tester(at.suite_de(x))
    appels.append(fmt.appel(f"{ident}_tests", "shell", {"command": _commande(tests.commande)}))
    sorties.append((tests, True))
    return appels, sorties


def _retours(appels: list[dict[str, Any]], sorties: list[tuple[Any, bool]]) -> list[dict[str, Any]]:
    return [{"role": "tool", "tool_call_id": a["id"], "content": _retour(s, t)} for a, (s, t) in zip(appels, sorties)]


def _lecture_finale(sorties: list[tuple[Any, bool]], x: Any, rouge: Any, rouge_tests: bool, projet: str,
                    courte: bool = False) -> str:
    """Ce que la vérification a montré, pour cette faute : le fichier corrigé, le symptôme de départ qui a disparu, les
    suites et les cas qui passent (une lecture générique serait la même sur des milliers de paires, règle 7.7).
    `courte` : sans les suites ni les noms des cas, pour une paire qui dépasse le plafond."""
    from usine.cours.base import profil
    tests = next(s for s, t in sorties if t)
    cas, err, ech = profil.resume_gdunit(tests.texte)
    passes = profil.cas_passes(tests.texte)
    suites = sorted({c.split(" > ")[0] for c in passes})
    noms = [c.split(" > ")[1] for c in passes]
    if rouge_tests and _echecs(rouge.texte):
        echecs = _echecs(rouge.texte)
        disparu = ", ".join(f"`{c}`" for c in echecs) + (" passent" if len(echecs) > 1 else " passe") + " maintenant"
    elif _erreurs(rouge.texte):
        disparu = f"« {_erreurs(rouge.texte)[0]} » a disparu"
    else:
        disparu = "le symptôme de départ a disparu"
    morceaux = [f"dans « {projet} », `res://{x.fichier}` corrigé : {disparu}"]
    if x.reimport:
        morceaux.append("l'import a refait le cache des classes")
    morceaux.append("le lancement ne montre plus aucune erreur (sortie vide ; le code 0 seul ne prouverait rien)")
    montres = ", ".join(f"`{n}`" for n in noms[:3]) + (", …" if len(noms) > 3 else "")
    ou = ", ".join(f"`res://{s}`" for s in suites)
    if courte:
        morceaux.append(f"les tests passent : {cas} cas, {err} erreur, {ech} échec, aucune « SCRIPT ERROR »")
    else:
        morceaux.append(f"les tests de {ou} passent : {cas} cas ({montres}), {err} erreur, {ech} échec, "
                        "aucune « SCRIPT ERROR »")
    texte = " ; ".join(morceaux)
    return "**Lire.** " + texte[0].upper() + texte[1:] + ". Vérifié : on n'y retouche plus."


def paires_faute(at: Atelier, x: Any, rouge: tuple[Any, Any | None], vert: list[tuple[Any, bool]],
                 appels_vert: list[dict[str, Any]], ident: str,
                 au_dela: list[dict[str, Any]] | None = None) -> list[dict[str, Any]]:
    """Les paires d'une faute, une par approche, sur les mêmes sorties réelles. Une paire qui dépasse le plafond n'est
    pas jetée : elle va dans `au_dela`, entière et avec sa lecture finale courte (demande de laurent du 2026-11-21 :
    les garder si elles dépassent un peu et que la carte les tient, les modifier sinon)."""
    from usine.cours.base import opencode
    from usine.paires import plomberie_projet as pp
    lancement, tests = rouge
    faux = x.poser(at.sain)
    preuve_tests = x.silencieuse
    montree = tests if preuve_tests else lancement
    sortie_txt = _retour(montree, preuve_tests).rsplit("\n", 1)[0]
    commande = _commande(montree.commande)
    tete = f"Projet Godot 4.7.2 « {at.th.projet} », dans `{at.dossier}`.\n```\n{pp.arbre(faux)}\n```"
    montres = "\n\n".join(_fichiers_montres(at, x, faux, montree.texte))
    edit = _tour_correction(at, x, ident)
    retour_edit = {"role": "tool", "tool_call_id": edit[0]["id"],
                   "content": opencode.EDIT_FAIT.format(chemin=x.fichier)}
    corriger = (f"**Corriger.** Dans `res://{x.fichier}`, je remplace le passage fautif par le bon"
                + (" ; le nom de classe change, je referai le cache des classes par un import avant de relancer."
                   if x.reimport else "."))
    tester = "**Tester.** Je relance le projet sans fenêtre, puis ses tests."
    preuve = {"kit": at.kit.nom, "theme": at.th.graine, "faute": x.genre, "fichier": x.fichier,
              "rouge": {"commande": montree.commande, "sortie": montree.texte},
              "vert": [{"commande": s.commande, "sortie": s.texte, "code": s.code} for s, _ in vert]}
    lu = _lire_sortie(montree, preuve_tests)
    lire = f"**Lire.** {lu[0].upper()}{lu[1:]}"
    chercher = f"**Chercher.** {x.cause}"
    sorties: list[dict[str, Any]] = []
    quoi = "Les tests" if preuve_tests else "Le lancement sans fenêtre"

    def finir(debut: list[dict[str, Any]], type_: str, approche: str) -> None:
        def faire(courte: bool) -> dict[str, Any]:
            tours = debut + [
                {"role": "assistant", "content": tester, "tool_calls": appels_vert}, *_retours(appels_vert, vert),
                {"role": "assistant", "content": _lecture_finale(vert, x, montree, preuve_tests, at.th.projet, courte)}]
            return fmt.paire_tours(FAMILLE, SUJET, type_, tours, dict(preuve, approche=approche), systeme=fmt.plan())
        p = faire(False)
        if p["jetons"] <= PLAFOND:
            sorties.append(p)
        elif au_dela is not None:
            au_dela.append({"entiere": p, "courte": faire(True)})

    # 1. La sortie donnée.
    donne = "donnent" if preuve_tests else "donne"
    demande = f"{tete}\n\n{montres}\n\n{quoi} {donne} :\n```\n{sortie_txt}\n```\n\nCorrige."
    finir([{"role": "user", "content": demande},
           {"role": "assistant", "content": f"{lire}\n\n{chercher}\n\n{corriger}", "tool_calls": edit}, retour_edit],
          "débogage", "sortie")
    # 2. Le symptôme seul : la réponse lance d'abord.
    demande = f"{tete}\n\n{montres}\n\nDepuis ma dernière modification, {x.symptome} Trouve et corrige."
    # Une seule commande d'abord : les tests quand le symptôme est un comportement sans erreur (le lancement, muet, ne
    # dirait rien), le lancement sinon.
    if preuve_tests:
        voir = [fmt.appel(f"{ident}_voir_tests", "shell", {"command": _commande(tests.commande)})]
        vus: list[tuple[Any, bool]] = [(tests, True)]
        regarder = ("**Voir.** Un comportement faux sans message d'erreur ne se voit qu'aux tests de comportement : je "
                    "lance ceux qui le jugent.")
        lire_vu = "**Lire.** " + _lire_sortie(tests, True).capitalize()
    else:
        voir = [fmt.appel(f"{ident}_voir_lancement", "shell", {"command": _commande(lancement.commande)})]
        vus = [(lancement, False)]
        regarder = "**Voir.** Je lance le projet sans fenêtre et je lis ce que Godot en dit."
        lu = _lire_sortie(lancement, False)
        lire_vu = "**Lire.** " + lu[0].upper() + lu[1:]
        if x.projet_ferme:
            lire_vu += " Le projet ne s'ouvre pas : inutile de lancer les tests avant de l'avoir réparé."
    finir([{"role": "user", "content": demande},
           {"role": "assistant", "content": regarder, "tool_calls": voir}, *_retours(voir, vus),
           {"role": "assistant", "content": f"{lire_vu}\n\n{chercher}\n\n{corriger}", "tool_calls": edit}, retour_edit],
          "débogage", "symptome")
    # 3. L'intention : l'oubli devient une demande de création.
    if x.intention:
        ecrire = (f"**Écrire.** {x.intention.rstrip('.')} : dans `res://{x.fichier}`, j'ajoute ce qui manque, à sa place "
                  "dans le projet." + (" Un nom de classe neuf ne se voit qu'après l'import, qui refait le cache des "
                                        "classes." if x.reimport else ""))
        demande = f"{tete}\n\n{montres}\n\n{x.intention}"
        finir([{"role": "user", "content": demande},
               {"role": "assistant", "content": ecrire, "tool_calls": edit}, retour_edit], "création", "intention")
    # 4. L'analyse, sans rien modifier.
    demande = (f"{tete}\n\n{montres}\n\n{quoi} {donne} :\n```\n{sortie_txt}\n```\n\nDis-moi ce qui ne va "
               "pas et ce qu'il faudrait changer, sans rien modifier.")
    changer = (f"**À changer.** Dans `res://{x.fichier}`, remplacer :\n```\n{x.faux.strip(chr(10)) or '(rien)'}\n```\n"
               f"par :\n```\n{x.juste.strip(chr(10))}\n```" + ("\nPuis refaire le cache des classes par un import "
                                                            "(`--import`) avant de relancer." if x.reimport else "")
               + "\nEnsuite, relancer le projet sans fenêtre et ses tests, et lire chaque ligne.")
    p = fmt.paire_tours(FAMILLE, SUJET, "analyse", [{"role": "user", "content": demande},
                                                  {"role": "assistant", "content": f"{lire}\n\n{chercher}\n\n{changer}"}],
                        dict(preuve, approche="analyse"), systeme=fmt.plan())
    if p["jetons"] <= PLAFOND:
        sorties.append(p)
    elif au_dela is not None:
        au_dela.append({"entiere": p, "courte": None})
    return sorties


def _bilan_au_dela(au_dela: list[dict[str, Any]]) -> dict[str, Any]:
    """Combien de paires dépassent le plafond, de combien entières, et combien la lecture courte ramène dessous."""
    entieres = [a["entiere"]["jetons"] for a in au_dela]
    courtes = [a["courte"]["jetons"] for a in au_dela if a["courte"]]
    paliers = (2176, 2304, 2560, 3072)
    return {"paires": len(au_dela),
            "par_type": {t: sum(a["entiere"]["type"] == t for a in au_dela) for t in ("création", "débogage", "analyse")},
            "entieres_au_plus": {str(n): sum(j <= n for j in entieres) for n in paliers},
            "entieres_max": max(entieres, default=0),
            "courtes_sous_plafond": sum(j <= PLAFOND for j in courtes),
            "courtes_au_plus": {str(n): sum(j <= n for j in courtes) for n in paliers}}


def generer(themes: int = 40, graine: int = 1, donnees: Path | None = None,
            journal: Callable[[str], None] = print, kit: str = "base") -> dict[str, Any]:
    k = kits()[kit]
    sortie = fmt.dossier(FAMILLE, donnees)
    racine = sortie / "travail"
    paires: list[dict[str, Any]] = []
    rejets: list[str] = []
    au_dela: list[dict[str, Any]] = []
    for g in range(graine, graine + themes):
        at = Atelier(g, racine, k)
        vert_sain = at.lancer(), at.tester()
        nb = sum(len(re.findall(r"^func test_", at.sain[s], re.M)) for s in k.suites(at.th))
        if not _propre(*vert_sain, nb):
            rejets.append(f"{k.nom} {g} : l'état sain ne passe pas")
            journal(f"{k.nom} {g} : état sain refusé\n{vert_sain[0].texte[:800]}\n{vert_sain[1].texte[-1500:]}")
            continue
        gardees = 0
        for x in k.fautes(at.th):
            ident = f"plomberie_{k.nom}_{g:04d}_{x.genre}"
            at.ecrire(x.poser(at.sain))
            if x.reimport:
                at.importer()
            lancement = at.lancer()
            tests = None if x.projet_ferme else at.tester(at.suite_de(x))
            rouge_vu = bool(_erreurs(lancement.texte)) if not x.silencieuse else bool(tests and _echecs(tests.texte))
            if not rouge_vu:
                rejets.append(f"{ident} : la faute ne se voit pas")
                at.ecrire(at.sain)
                if x.reimport:
                    at.importer()
                continue
            # La correction telle que la réponse l'écrit : le fichier juste, puis les commandes de la réponse.
            at.ecrire(at.sain)
            appels, vert = _verifier(at, x, ident)
            suite = at.suite_de(x)[0][len("res://"):]
            if not _propre(vert[-2][0], vert[-1][0], len(re.findall(r"^func test_", at.sain[suite], re.M))):
                rejets.append(f"{ident} : la correction ne passe pas")
                if x.reimport:
                    at.importer()
                continue
            nouvelles = paires_faute(at, x, (lancement, tests), vert, appels, ident, au_dela)
            paires += nouvelles
            gardees += len(nouvelles)
        journal(f"{k.nom} {g} ({at.th.projet}) : {gardees} paires")
        shutil.rmtree(at.chemin, ignore_errors=True)
    fmt.ecrire(paires, sortie / ("paires_plomberie.jsonl" if kit == "base" else f"paires_plomberie_{kit}.jsonl"))
    # Au-delà du plafond : à part, sous un nom que l'assembleur ne lit pas (`*/paires*.jsonl`), en attendant de savoir
    # si la 5090 tient un `cutoff_len` un peu plus haut.
    from usine.paires import verification
    fmt.ecrire([dict(a["entiere"], courte=verification.ajouter(a["courte"]) if a["courte"] else None) for a in au_dela],
               sortie / ("au_dela_plomberie.jsonl" if kit == "base" else f"au_dela_plomberie_{kit}.jsonl"))
    bilan: dict[str, Any] = {"famille": FAMILLE, "paires": len(paires), "rejets": rejets, "par_type": {},
                             "par_faute": {}, "par_approche": {}, "au_dela": _bilan_au_dela(au_dela),
                             "jetons_max": max((p["jetons"] for p in paires), default=0),
                             "jetons_moyens": round(sum(p["jetons"] for p in paires) / max(len(paires), 1))}
    for p in paires:
        for cle, val in (("par_type", p["type"]), ("par_faute", p["preuve"]["faute"]),
                         ("par_approche", p["preuve"]["approche"])):
            bilan[cle][val] = bilan[cle].get(val, 0) + 1
    (sortie / ("bilan_plomberie.json" if kit == "base" else f"bilan_plomberie_{kit}.json")).write_text(json.dumps(bilan, indent=1, ensure_ascii=False), encoding="utf-8")
    return bilan
