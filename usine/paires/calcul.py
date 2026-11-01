"""Deux familles de paires pour les shaders de calcul (`.glsl`), demande de laurent du 2026-11-01 : « fait un maximum de paires sur
le sujet que qwen apprennen a code des fluide sous godot ».

`creation_calcul` : écrire une fonction d'un shader de calcul d'après son commentaire, ou le fichier entier. Gardée seulement si le
shader compile au corps vidé et si un test le voit, sur la carte : les suites d'un dossier `gpu` tournent sur le bureau caché
(aucune fenêtre visible, la souris reste libre). La demande montre ce que le code emploie (images, constantes, fonctions appelées) ;
la réponse écrit le code, réimporte (Godot ne relit un `.glsl` qu'à l'import), lance les cas qui le jugent et lit leurs vraies sorties.

`compilation_calcul` : une erreur de glslang → la ligne corrigée. Le code vérifié reçoit une seule faute ; `7_tests/check_shaders.gd`
la dit sans carte ni fenêtre. Gardée seulement si elle ne signale que ce shader, à la ligne de la faute ou à la suivante, et si le
shader compile une fois corrigé. glslang compte les lignes à partir de `#version` : son 0:8 est la ligne 9 du fichier.

    python -m usine.paires creation_calcul [--cours fluides] [--par-etape N] [--graine G] [--etapes 1,2]
    python -m usine.paires compilation_calcul [--cours fluides] [--par-etape N] [--graine G] [--etapes 1,2]
"""

from __future__ import annotations

import json
import random
import re
from pathlib import Path
from typing import Any, Callable

from usine.paires import boucle
from usine.paires import faute_calcul as fc
from usine.paires import format as fmt

CREATION = "creation_calcul"
COMPILATION = "compilation_calcul"
GLSL = ".glsl"
DOSSIERS = ("1_core/",)
PLAFOND_COURT = 1024
CORPS_MAX = 40
TROU = "\t// À écrire."
# Une déclaration de premier niveau : une image, ou un bloc de tampon ou de constantes (jusqu'à l'accolade fermante).
DECLARATION = re.compile(r"^layout\(.*\)\s+(?:uniform|restrict|buffer|readonly)\b")
NOM_DECLARE = re.compile(r"\b(\w+)\s*;\s*$")
ERREUR = re.compile(r"^ERROR: 0:(\d+): (.*)$", re.M)
FAUX = re.compile(r"^(res://\S+\.glsl) : ", re.M)

# Une image mal déclarée ne se voit pas à sa déclaration, mais là où on l'emploie : l'erreur tombe loin de la faute.
DECLAREES = ("image_en_ecriture", "image_en_lecture")
# (genre, motif, gabarit, ce que dit le diagnostic). Chaque faute est de celles que glslang refuse.
FAUTES: tuple[tuple[str, re.Pattern[str], str, str], ...] = (
    ("point_virgule", re.compile(r";$"), "", "il manque le point-virgule en fin de ligne : glslang ne s'en aperçoit qu'en lisant la suite"),
    ("cellule_non_signee", re.compile(r"ivec2\(gl_GlobalInvocationID\.xy\)"), "gl_GlobalInvocationID.xy",
     "`gl_GlobalInvocationID` est un `uvec3` : GLSL ne le convertit pas tout seul en `ivec2`, il faut `ivec2(...)`"),
    ("ecriture_flottante", re.compile(r"imageStore\((\w+), (\w+), vec4\((.+)\)\);$"), r"imageStore(\1, \2, \3);",
     "`imageStore` écrit toujours un `vec4`, même dans une image d'un seul canal : il faut `vec4(...)`"),
    ("lecture_vecteur", re.compile(r"(= imageLoad\(\w+, \w+\))\.r;$"), r"\1;",
     "`imageLoad` rend toujours un `vec4` : pour un flottant, il faut lire `.r`"),
    ("image_en_ecriture", re.compile(r"(uniform restrict) readonly (image)"), r"\1 writeonly \2",
     "une image déclarée `writeonly` ne peut pas être lue : `imageLoad` la veut lisible, donc `readonly`"),
    ("image_en_lecture", re.compile(r"(uniform restrict) writeonly (image)"), r"\1 readonly \2",
     "une image déclarée `readonly` ne peut pas être écrite : `imageStore` la veut `writeonly`"),
    ("constante_nue", re.compile(r"\bconstants\.(\w+)"), r"\1", "une constante poussée se lit par le nom de son bloc : `constants.`"),
)


def declarations(texte: str) -> list[tuple[str, str]]:
    """(nom, texte) de chaque déclaration de premier niveau : `layout(...) uniform … nom;`, ou un bloc jusqu'à `} nom;`."""
    lignes = texte.split("\n")
    sortie = []
    k = 0
    while k < len(lignes):
        if DECLARATION.match(lignes[k]):
            debut = k
            bloc = lignes[k].rstrip().endswith("{")
            while k < len(lignes) - 1 and not (lignes[k].startswith("}") if bloc else lignes[k].rstrip().endswith(";")):
                k += 1
            m = NOM_DECLARE.search(lignes[k])
            if m:
                sortie.append((m[1], "\n".join(lignes[debut:k + 1])))
        k += 1
    return sortie


def contexte(texte: str, f: Any, tous: list[Any]) -> str:
    """Ce que la fonction emploie : ses déclarations, le commentaire et la signature de celles qu'elle appelle, puis son propre
    commentaire et sa signature, corps à écrire."""
    lignes = texte.split("\n")
    corps = "\n".join(l.split("//", 1)[0] for l in lignes[f.ligne + 1:f.fin])
    blocs = [d for nom, d in declarations(texte) if re.search(rf"\b{re.escape(nom)}\b", corps)]
    blocs = ["\n".join(blocs)] if blocs else []
    for g in tous:
        if g.nom != f.nom and re.search(rf"\b{re.escape(g.nom)}\s*\(", corps):
            blocs.append("\n".join(lignes[g.doc:g.ligne + 1]) + "\n\t…\n}")
    blocs.append("\n".join(lignes[f.doc:f.ligne + 1]) + f"\n{TROU}\n}}")
    return "\n\n".join(blocs) + "\n"


def tete_du_fichier(texte: str) -> str:
    """Le commentaire d'en-tête du shader : les lignes `//` juste après `#version`."""
    lignes = texte.split("\n")
    debut = next((k for k, l in enumerate(lignes) if l.startswith("#version")), 0) + 1
    while debut < len(lignes) and not lignes[debut].strip():
        debut += 1
    sortie = []
    for l in lignes[debut:]:
        if not l.startswith("//"):
            break
        sortie.append(l.lstrip("/ ").strip())
    return " ".join(sortie)


def lanceur(apres: dict[str, str], rel: str) -> str | None:
    """Les fonctions documentées du script qui charge ce shader, là où il est lancé ; None si aucune."""
    constante = None
    porteur = None
    for r, t in sorted(apres.items()):
        if r.endswith(".gd") and not r.startswith("7_tests/"):
            m = re.search(rf'^const (\w+) := "res://{re.escape(rel)}"', t, re.M)
            if m:
                porteur, constante = r, m[1]
                break
    if porteur is None:
        return None
    texte = apres[porteur]
    passe = re.search(rf"^\s*(_\w+) = ComputePass\.new\(\w+, {constante}\)", texte, re.M)
    if passe is None:
        return None
    morceaux = []
    for k in [m.start() for m in re.finditer(rf"\b{re.escape(passe[1])}\.run\(", texte)]:
        ligne = texte[:k].count("\n") + 1
        trouve = fc.fonction_de(porteur, texte, ligne)
        if trouve and trouve[2] not in morceaux:
            morceaux.append(trouve[2])
    return f"Il est lancé par `res://{porteur}` :\n```gdscript\n" + "\n\n\n".join(morceaux) + "\n```" if morceaux else None


def _rouge(projet: Any, rel: str, vide: str, suites: list[str], attendus: set[str]) -> tuple[str, str] | str:
    """(suite, sortie rouge) une fois le code retiré ; sinon la raison du rejet. Le projet revient à l'état de l'étape."""
    from usine.cours.base import godot, profil
    projet.remettre()
    projet.ecrire(rel, vide)
    godot.importer(projet.chemin)
    try:
        if godot.tester(projet.chemin, fc.CHECK_SHADERS, 60).code != 0:
            return "le shader sans ce code ne compile pas"
        for suite in suites[:3]:
            s = godot.tester_gdunit(projet.chemin, ["res://" + suite], fc.DELAI_TEST)
            if not profil.test_reussi(s.code, s.texte, attendus):
                return suite, s.texte
        return "aucune suite n'échoue sans ce code : les tests ne le jugent pas"
    finally:
        projet.remettre()
        godot.importer(projet.chemin)


def _verifier(projet: Any, rouge: str, sortie_rouge: str, passe: dict[str, Any], attendus: set[str]) -> tuple[Any, Any, list[str]] | str:
    """(sortie de l'import, sortie des cas qui jugent, ces cas) sur l'état de l'étape ; sinon la raison du rejet."""
    from usine.cours.base import godot
    if rouge not in passe:
        passe[rouge] = boucle.suite_passe(projet, rouge, attendus)
    if passe[rouge] is not True:
        return f"la suite ne passe pas avec le code d'origine ({passe[rouge]})"
    cas = boucle.cas_rouges(projet.apres[rouge], sortie_rouge, rouge)
    return godot.importer(projet.chemin), godot.tester_gdunit(projet.chemin, ["res://" + rouge], fc.DELAI_TEST,
                                                              boucle.ecartes(projet.apres[rouge], cas, rouge)), cas


def _lire(tests: Any, quoi: str, cas: list[str], suite: str) -> str | None:
    lire = boucle.lecture([(tests, "test")], quoi, cas, suite)
    return None if lire is None else "**Lire.** Le shader est réimporté. " + lire.removeprefix("**Lire.** ")


def paire_fonction(projet: Any, rel: str, f: Any, tous: list[Any], suites: list[str], passe: dict[str, Any]) -> tuple[list[dict[str, Any]], str]:
    """Les paires d'une fonction de shader, ou ([], raison du rejet)."""
    from usine.cours.base import profil
    from usine.paires import shader_fonction as sf
    texte = projet.apres[rel]
    attendus = profil.messages_attendus(projet.apres)
    vu = _rouge(projet, rel, sf.vider(texte, f), suites, attendus)
    if isinstance(vu, str):
        return [], vu
    rouge, sortie_rouge = vu
    faits = _verifier(projet, rouge, sortie_rouge, passe, attendus)
    if isinstance(faits, str):
        return [], faits
    importation, tests, cas = faits
    lignes = texte.split("\n")
    code = f.texte(lignes)
    lire = _lire(tests, f"`{f.nom}`", cas, rouge)
    if lire is None:
        return [], "la sortie de vérification ne passe pas la lecture"
    demande = (f"Projet Godot 4.7.2. Dans le shader de calcul `res://{rel}`, écris le corps de `{f.nom}` d'après son commentaire. "
               f"Les tests de `res://{rouge}` le vérifient sur la carte. Ce que la fonction emploie :\n"
               f"```glsl\n{contexte(texte, f, tous)}```")
    ecrire = [f"**Écrire.** `{f.nom}`, d'après son commentaire :", f"```glsl\n{code}\n```"]
    tester = ["", "**Tester.** Godot ne relit un `.glsl` qu'à l'import : je réimporte, puis je lance "
              + boucle.phrase_cas(projet.apres[rouge], cas)]
    preuve = {"etape": f"{projet.ville}-{projet.n:03d}", "fichier": rel, "fonction": f.nom, "suite": rouge, "cas_rouges": cas,
              "rouge_sans_corps": True, "vert_avec": True, "commande_tests": tests.commande, "code_tests": tests.code}
    return boucle.paire(CREATION, "shaders", f"calcul_{f.nom}", demande, ecrire, [], tester, [(importation, "analyse"), (tests, "test")],
                        lire, preuve, True)


def paire_fichier(projet: Any, rel: str, suites: list[str], passe: dict[str, Any]) -> tuple[list[dict[str, Any]], str]:
    """Les paires du fichier entier, ou ([], raison du rejet) : le shader lui-même, d'après ce qu'il doit faire et son appel."""
    from usine.cours.base import profil
    from usine.paires import shader_fonction as sf
    texte = projet.apres[rel]
    attendus = profil.messages_attendus(projet.apres)
    principale = next((f for f in sf.fonctions(texte) if f.nom == "main"), None)
    appel = lanceur(projet.apres, rel)
    if principale is None or appel is None:
        return [], "pas de `main` ou pas d'appel dans un script"
    vu = _rouge(projet, rel, sf.vider(texte, principale), suites, attendus)
    if isinstance(vu, str):
        return [], vu
    rouge, sortie_rouge = vu
    faits = _verifier(projet, rouge, sortie_rouge, passe, attendus)
    if isinstance(faits, str):
        return [], faits
    importation, tests, cas = faits
    lire = _lire(tests, f"`{Path(rel).name}`", cas, rouge)
    if lire is None:
        return [], "la sortie de vérification ne passe pas la lecture"
    demande = (f"Projet Godot 4.7.2. Écris le shader de calcul `res://{rel}` : {tete_du_fichier(texte)} Les tests de `res://{rouge}` "
               f"le vérifient sur la carte. {appel}")
    ecrire = [f"**Écrire.** `{Path(rel).name}` :", f"```glsl\n{texte.strip()}\n```"]
    tester = ["", "**Tester.** Godot ne relit un `.glsl` qu'à l'import : je réimporte, puis je lance "
              + boucle.phrase_cas(projet.apres[rouge], cas)]
    preuve = {"etape": f"{projet.ville}-{projet.n:03d}", "fichier": rel, "fonction": None, "suite": rouge, "cas_rouges": cas,
              "rouge_sans_corps": True, "vert_avec": True, "commande_tests": tests.commande, "code_tests": tests.code}
    return boucle.paire(CREATION, "shaders", f"calcul_{Path(rel).stem}", demande, ecrire, [], tester,
                        [(importation, "analyse"), (tests, "test")], lire, preuve, True)


def generer_creation(cours: str = "fluides", par_etape: int = 60, graine: int = 1, etapes: list[int] | None = None,
                     donnees: Path | None = None, journal: Callable[[str], None] = print) -> dict[str, Any]:
    """Chaque fonction, et chaque fichier, une seule fois dans le cours (règle 7.7)."""
    from usine.cours.base import assembler, chemins, creation, sessions
    from usine.paires import shader_fonction as sf
    chemins.configurer(cours=cours)
    sortie = fmt.dossier(CREATION, donnees)
    paires: list[dict[str, Any]] = []
    rejets: list[str] = []
    rng = random.Random(graine)
    vues: set[tuple[str, str]] = set()
    for ville in assembler.ordre_lignes():
        for n in etapes or list(assembler.etapes_du_cours()):
            _, apres = creation.etats(ville, n)
            dispo: list[tuple[str, Any, tuple[str, str]]] = []
            for rel in sorted(r for r in apres if r.endswith(GLSL) and r.startswith(DOSSIERS)):
                texte = apres[rel]
                lignes = texte.split("\n")
                if (fmt.commun(rel), texte) not in vues:
                    dispo.append((rel, None, (fmt.commun(rel), texte)))
                for f in sf.fonctions(texte):
                    cle = (fmt.commun(rel), fmt.commun(f.texte(lignes)))
                    if f.doc < f.ligne and f.fin - f.ligne - 1 <= CORPS_MAX and cle not in vues:
                        dispo.append((rel, f, cle))
            if not dispo:
                continue
            rng.shuffle(dispo)
            projet = sessions.Projet(ville, n, apres, espace="calcul")
            for rel in apres:
                if rel.endswith(GLSL):
                    projet.code[rel] = apres[rel]
            passe: dict[str, Any] = {}
            gardees = 0
            for rel, f, cle in dispo[:par_etape]:
                vues.add(cle)
                suites = fc.suites_de(apres, rel)
                if not suites:
                    rejets.append(f"{ville}-{n:03d} {rel} : aucune suite ne charge ce shader")
                    continue
                if f is None:
                    qs, raison = paire_fichier(projet, rel, suites, passe)
                else:
                    qs, raison = paire_fonction(projet, rel, f, sf.fonctions(apres[rel]), suites, passe)
                if not qs:
                    rejets.append(f"{ville}-{n:03d} {rel} {f.nom if f else '(fichier)'} : {raison}")
                    continue
                paires += qs
                gardees += 1
            journal(f"{ville}-{n:03d} : {gardees}/{min(len(dispo), par_etape)} shaders ou fonctions")
            fmt.ecrire(paires, sortie / f"paires_{cours}.jsonl")
    return _bilan(CREATION, cours, paires, rejets, sortie)


def _bilan(famille: str, cours: str, paires: list[dict[str, Any]], rejets: list[str], sortie: Path) -> dict[str, Any]:
    bilan: dict[str, Any] = {"famille": famille, "cours": cours, "paires": len(paires), "rejets": rejets, "par_palier": {},
                             "jetons_max": max((p["jetons"] for p in paires), default=0),
                             "jetons_moyens": round(sum(p["jetons"] for p in paires) / max(len(paires), 1))}
    for p in paires:
        bilan["par_palier"][p["preuve"]["palier"]] = bilan["par_palier"].get(p["preuve"]["palier"], 0) + 1
    (sortie / f"bilan_{cours}.json").write_text(json.dumps(bilan, indent=1, ensure_ascii=False), encoding="utf-8")
    return bilan


def fautes_compilation(rel: str, texte: str) -> list[fc.Faute]:
    """Toutes les fautes de compilation qu'on peut poser dans ce shader, une par occurrence."""
    lignes = texte.split("\n")
    sortie = []
    for n, ligne in enumerate(lignes, 1):
        code = ligne.strip()
        if not code or code.startswith(("//", "#")):
            continue
        for genre, motif, gabarit, diagnostic in FAUTES:
            if genre == "point_virgule" and not ligne.startswith("\t"):
                continue
            for m in motif.finditer(ligne):
                nouvelle = ligne[:m.start()] + m.expand(gabarit) + ligne[m.end():]
                sortie.append(fc.Faute(genre, rel, n, ligne, nouvelle, fc._remplacer(lignes, n, nouvelle), diagnostic, ""))
    return sortie


def paire_compilation(projet: Any, f: fc.Faute) -> tuple[dict[str, Any] | None, str]:
    """La paire d'une faute de compilation, ou (None, raison du rejet). Le projet revient à l'état de l'étape."""
    from usine.cours.base import godot
    projet.remettre()
    projet.ecrire(f.fichier, f.texte)
    godot.importer(projet.chemin)
    remis = False
    try:
        s = godot.tester(projet.chemin, fc.CHECK_SHADERS, 60)
        faux = FAUX.findall(s.texte)
        erreurs = [(int(m[1]) + 1, m[2].strip()) for m in ERREUR.finditer(s.texte) if "compilation" not in m[2]]
        if s.code == 0 or faux != [f"res://{f.fichier}"] or not erreurs:
            return None, f"Godot ne signale pas ce seul shader ({faux[:2]})"
        ligne, message = erreurs[0]
        if ligne not in (f.ligne, f.ligne + 1) and f.genre not in DECLAREES:
            return None, f"erreur à la ligne {ligne} du fichier et non {f.ligne}"
        projet.remettre()
        godot.importer(projet.chemin)
        remis = True
        apres = godot.tester(projet.chemin, fc.CHECK_SHADERS, 60)
        if apres.code != 0:
            return None, "le shader ne compile pas une fois corrigé"
    finally:
        projet.remettre()
        if not remis:
            godot.importer(projet.chemin)
    trouve = fc.fonction_de(f.fichier, f.texte, ligne if f.genre in DECLAREES else f.ligne)
    tete = "\n".join(l for _, l in declarations(f.texte)) + "\n\n" if f.genre in DECLAREES else ""
    passage = tete + (trouve[2] if trouve else "\n".join(f.texte.split("\n")[:max(f.ligne + 3, 12)]))
    demande = (f"Projet Godot 4.7.2. La vérification des shaders de calcul donne :\n```\n$ {s.commande}\n{s.texte.strip()}\n"
               f"(code de sortie : {s.code})\n```\n\nDans `res://{f.fichier}` :\n```glsl\n{passage}\n```\n\nCorrige l'erreur.")
    reponse = "\n".join([
        f"**Lire.** glslang dit `0:{ligne - 1}` : il compte à partir de `#version`, donc c'est la ligne {ligne} du fichier : « {message} ».", "",
        f"**Chercher.** {'La ligne signalée est juste : c\'est la déclaration qui est fausse. ' if f.genre in DECLAREES else ''}"
        f"Ligne {f.ligne} : {f.de}.", "", "**Corriger.** Une seule ligne change :",
        f"Dans `res://{f.fichier}`, ligne {f.ligne}, je remplace :", f"```glsl\n{f.fautif}\n```", "par :", f"```glsl\n{f.juste}\n```", "",
        "**Tester.** Godot ne relit un `.glsl` qu'à l'import : je réimporte, puis je relance la vérification.",
        f"```\n$ godot --headless --path . --import\n$ {s.commande}\n```"])
    preuve = {"outil": "check_shaders", "commande": s.commande, "sortie": s.texte, "code": s.code, "sortie_apres": apres.texte,
              "code_apres": apres.code, "etape": f"{projet.ville}-{projet.n:03d}", "fichier": f.fichier, "ligne": f.ligne,
              "genre": f.genre, "ligne_signalee": ligne}
    courte = fmt.paire(COMPILATION, "shaders", "débogage", demande, reponse, dict(preuve, palier=1))
    if courte["jetons"] <= PLAFOND_COURT:
        return courte, ""
    longue = fmt.paire(COMPILATION, "shaders", "débogage", demande, reponse, dict(preuve, palier=2), systeme=fmt.plan())
    return (longue, "") if longue["jetons"] <= fc.PLAFOND else (None, f"trop longue ({longue['jetons']} jetons)")


def generer_compilation(cours: str = "fluides", par_etape: int = 60, graine: int = 1, etapes: list[int] | None = None,
                        donnees: Path | None = None, journal: Callable[[str], None] = print) -> dict[str, Any]:
    """`par_etape` fautes par étape, genres à tour de rôle (graine fixe) ; une faute essayée ne revient pas."""
    from usine.cours.base import assembler, chemins, creation, sessions
    chemins.configurer(cours=cours)
    sortie = fmt.dossier(COMPILATION, donnees)
    paires: list[dict[str, Any]] = []
    rejets: list[str] = []
    rng = random.Random(graine)
    vues: set[tuple[str, str, str]] = set()
    for ville in assembler.ordre_lignes():
        for n in etapes or list(assembler.etapes_du_cours()):
            _, apres = creation.etats(ville, n)
            dispo = [f for rel in sorted(r for r in apres if r.endswith(GLSL) and r.startswith(DOSSIERS))
                     for f in fautes_compilation(rel, apres[rel]) if f.cle() not in vues]
            if not dispo:
                continue
            par_genre: dict[str, list[fc.Faute]] = {}
            for f in dispo:
                par_genre.setdefault(f.genre, []).append(f)
            for liste in par_genre.values():
                rng.shuffle(liste)
            choisies: list[fc.Faute] = []
            while len(choisies) < par_etape and any(par_genre.values()):
                for g in sorted(par_genre):
                    if par_genre[g] and len(choisies) < par_etape:
                        choisies.append(par_genre[g].pop())
            projet = sessions.Projet(ville, n, apres, espace="glslang")
            gardees = 0
            for f in choisies:
                vues.add(f.cle())
                p, raison = paire_compilation(projet, f)
                if p is None:
                    rejets.append(f"{ville}-{n:03d} {f.fichier}:{f.ligne} {f.genre} : {raison}")
                    continue
                paires.append(p)
                gardees += 1
            journal(f"{ville}-{n:03d} : {gardees}/{len(choisies)} paires")
            fmt.ecrire(paires, sortie / f"paires_{cours}.jsonl")
    return _bilan(COMPILATION, cours, paires, rejets, sortie)
