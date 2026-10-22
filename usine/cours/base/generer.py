"""Génère la base, étape par étape : les exemples de création de l'étape, puis des sessions de débogage jusqu'à ce
que leurs jetons de réponse égalent ceux de la création (décision 3, règle 7.1).

Un fichier JSON par étape dans donnees/cours/<cours>/base/etapes/ : une étape déjà faite n'est pas refaite (reprise
possible). Les projets du cours sont refabriqués d'abord, depuis les maîtres. Un cours « de jeu » (le kart, le
roguelike) n'a qu'une suite d'étapes : elle porte le préfixe de ses projets à la place d'une ville.
"""

from __future__ import annotations

import json
import random
import time
import traceback
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

from usine.cours.base import chemins, creation, debogage, etat, notes, rattacher, sessions, textes
from usine.cours.fabriquer import fabriquer_tout, lire_manifeste

MAX_SESSIONS = 90
MAX_ECHECS = 30
# Le genre d'erreur de la première session tourne d'une étape à l'autre, décalé d'une ville à l'autre.
DECALAGE = {"parisien": 0, "tokyoiste": 2, "newyorkais": 4}


def cle(m) -> tuple:
    return m.fichier, m.ligne, m.genre, m.apres


def prefere(ville: str, n: int) -> str:
    return debogage.GENRES[(n - 1 + DECALAGE.get(ville, 0)) % len(debogage.GENRES)]


def sessions_etape(ville: str, n: int, cible: int, journal=print) -> list[dict]:
    """D'abord une session à une erreur (du genre de l'étape), puis des sessions à plusieurs erreurs, jusqu'à ce que
    les jetons de réponse du débogage atteignent `cible`."""
    note = notes.lire(ville, n)
    titre = note.titre.split("·")[-1].strip()
    desc, _ = textes.projet(ville)
    avant, apres = creation.etats(ville, n)
    tous = rattacher.decouper(etat.morceaux(avant, apres))
    neufs, autres = sessions.candidats(apres, tous)
    projet = sessions.Projet(ville, n, apres, {m.fichier for m in tous})
    hasard = random.Random(f"sessions-{ville}-{n}")
    sortie: list[dict] = []
    acquis = 0
    prises: set = set()          # (fichier, ligne) déjà employées dans une session de l'étape
    ecartees: set = set()        # erreurs que Godot ne voit pas
    exclus: set = set()          # shaders que le rendu de la scène ne compile pas
    echecs = 0

    def garder(ex: dict, muts: list) -> None:
        nonlocal acquis
        ex.update({"id": f"{ville}-{n:03d}-debogage-{len(sortie) + 1}", "ville": ville, "etape": n, "type": "debogage"})
        # Les jetons de l'exemple au format d'OpenCode, celui de l'entraînement (Qwen 3.8, gabarit compris).
        total, reponse = ex["opencode"]["jetons"], ex["opencode"]["jetons_reponse"]
        ex["preuves"]["jetons"], ex["preuves"]["jetons_reponse"] = total, reponse
        acquis += reponse
        sortie.append(ex)
        for m in muts:
            prises.add((m.fichier, m.ligne))
        journal(f"    {ex['id']} : {len(muts)} erreur(s) {[m.genre for m in muts]}, vues {ex['preuves']['vues']}, "
                f"{len(ex['messages'])} messages, {reponse} jetons de réponse ; total {acquis}/{cible}")

    def essayer(muts: list) -> bool:
        nonlocal echecs
        for _ in range(3):
            try:
                ex = sessions.jouer(projet, muts, desc, titre)
            except sessions.SessionInvalide as exc:
                echecs += 1
                journal(f"    session écartée ({len(muts)} erreurs) : {exc.raison[:200]}")
                for m in exc.a_ecarter:
                    ecartees.add(cle(m))
                    if not m.fichier.endswith(".gd"):
                        exclus.add(m.fichier)
                if not exc.a_ecarter:
                    for m in muts:
                        prises.add((m.fichier, m.ligne))
                    return False
                muts = [m for m in muts if cle(m) not in ecartees and m.fichier not in exclus]
                if not muts:
                    return False
                continue
            garder(ex, muts)
            return True
        return False

    # 1. Une session à une erreur : le genre de l'étape d'abord, puis les autres dans l'ordre de GENRES.
    rang = {g: (i - debogage.GENRES.index(prefere(ville, n))) % len(debogage.GENRES)
            for i, g in enumerate(debogage.GENRES)}
    seules = list(neufs)
    hasard.shuffle(seules)
    seules.sort(key=lambda m: rang.get(m.genre, 99))
    for m in seules[:12]:
        if cle(m) in ecartees or m.fichier in exclus:
            continue
        if essayer([m]):
            break
    # 2. Des sessions à plusieurs erreurs, jusqu'à l'équilibre.
    moyenne = 1500
    # Réserves successives : les lignes nouvelles de l'étape, puis les autres lignes de ses fichiers, puis (cours de
    # jeu) les autres fichiers du projet (sessions.candidats_ailleurs).
    reserves = [neufs, neufs + autres]
    if chemins.actuels().jeu:
        reserves.append(neufs + autres + sessions.candidats_ailleurs(apres, {m.fichier for m in tous}))
    niveau = 0
    while len(sortie) < MAX_SESSIONS and echecs < MAX_ECHECS and acquis + moyenne / 2 < cible:
        dispo = [c for c in reserves[niveau] if cle(c) not in ecartees]
        muts = sessions.tirer(hasard, dispo, prises, exclus)
        if len(muts) < 2:
            if niveau + 1 == len(reserves):
                journal("    plus d'erreurs possibles dans les fichiers de l'étape"
                        + (" ni dans le reste du projet" if niveau == 2 else ""))
                break
            niveau += 1
            continue
        if essayer(muts) and len(sortie) > 1:
            moyenne = sum(e["preuves"]["jetons_reponse"] for e in sortie[1:]) / (len(sortie) - 1)
    projet.remettre()
    return sortie


def une_etape(ville: str, n: int, journal=print) -> list[dict]:
    crea = creation.exemples(ville, n, journal)
    cible = sum(e["preuves"]["jetons_reponse"] for e in crea)
    return crea + sessions_etape(ville, n, cible, journal)


def _travailleur(ville: str, n: int, reglages: dict) -> str:
    """Une étape, dans son propre processus : écrit son fichier JSON et rend son journal."""
    chemins.configurer(**reglages)
    ch = chemins.actuels()
    fichier = ch.etapes / f"{ville}_{n:03d}.json"
    lignes: list[str] = []

    def journal(texte: str) -> None:
        lignes.append(texte)

    debut = time.time()
    try:
        exemples = une_etape(ville, n, journal)
    except Exception:  # noqa: BLE001 - l'étape est notée en échec, les autres continuent
        return "\n".join(lignes + [f"{ville} {n:03d} : ÉCHEC", traceback.format_exc()])
    fichier.parent.mkdir(parents=True, exist_ok=True)
    temporaire = fichier.with_suffix(".json.tmp")
    temporaire.write_text(json.dumps(exemples, ensure_ascii=False, indent=1), encoding="utf-8")
    temporaire.replace(fichier)
    crea = [e for e in exemples if e["type"] == "creation"]
    deb = [e for e in exemples if e["type"] == "debogage"]
    lignes.append(f"{ville} {n:03d} : {len(crea)} création(s) ({sum(e['preuves']['jetons_reponse'] for e in crea)} jetons "
                  f"de réponse), {len(deb)} session(s) ({sum(e['preuves']['jetons_reponse'] for e in deb)}), "
                  f"{round(time.time() - debut)} s")
    return "\n".join(lignes)


def generer(villes: list[str] | None = None, etapes: list[int] | None = None, travailleurs: int = 1,
            reglages: dict | None = None, refaire: bool = False, journal=print) -> int:
    """Refabrique les projets du cours, puis génère les étapes demandées qui ne sont pas encore faites."""
    reglages = dict(reglages or {})
    ch = chemins.configurer(**reglages)
    manifeste = lire_manifeste(ch.cours)
    if ch.jeu:
        from usine.cours import jeu
        jeu.fabriquer_tout(ch.cours, ch.projets)
        lignes = {manifeste["PREFIXE"]: list(manifeste.get("PRETES", range(1, manifeste["DERNIERE"] + 1)))}
    else:
        fabriquer_tout(ch.cours, ch.projets)
        lignes = {v: manifeste["VILLES"][v]["pretes"] for v in manifeste["VILLES"]}
    a_faire = []
    for ville in villes or list(lignes):
        for n in etapes or lignes[ville]:
            fichier = ch.etapes / f"{ville}_{n:03d}.json"
            if fichier.is_file() and not refaire:
                journal(f"{ville} {n:03d} : déjà fait")
                continue
            a_faire.append((ville, n))
    echecs = 0
    with ProcessPoolExecutor(max_workers=max(1, travailleurs)) as pool:
        futurs = [pool.submit(_travailleur, ville, n, reglages) for ville, n in a_faire]
        for futur in futurs:
            texte = futur.result()
            echecs += any(ligne.endswith(": ÉCHEC") for ligne in texte.splitlines())
            journal(texte)
    return echecs


def fichiers_etapes() -> list[Path]:
    return sorted(chemins.actuels().etapes.glob("*.json"))
