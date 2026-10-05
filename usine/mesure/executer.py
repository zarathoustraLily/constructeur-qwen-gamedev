"""Exécution des 4 configurations sur les jeux gelés, et notation de réponses déjà collectées.

  configuration  LoRA  RAG
  base           non   non
  base_rag       non   oui
  lora           oui   non
  lora_rag       oui   oui

Même prompt (reponses.messages), même schéma de sortie, même budget (client.Reglages) pour les
quatre ; seule change la présence des extraits de documentation et l'échelle du LoRA.
Score au premier essai : un seul appel par tâche et par configuration, jamais de relance.

Résultats : JSONL, une ligne par (tour, configuration, tâche), écrite et synchronisée sur disque
dès que la tâche est jugée. Une exécution coupée reprend là où elle s'est arrêtée : une ligne déjà
présente (même tour, configuration, id et empreinte) n'est pas refaite.

Compétences agentiques (K2, K3, E…) : une session de l'agent maison (usine/rft/agent.py, mêmes
outils que le serveur MCP) sur une copie de travail, puis le juge de la tâche. Même budget de pas
pour les quatre configurations ; sans RAG, l'outil search_docs est retiré ; avec RAG, il est
présent et les extraits sont ajoutés à la tâche. La session est gardée à côté des résultats
(<résultats>.sessions/<configuration>/<tâche>.jsonl).
"""

from __future__ import annotations

import json
import os
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Callable, Iterable

from usine.generateurs.invention import COMPETENCES as _COMPETENCES_INVENTION
from usine.mesure import reponses
from usine.mesure.client import ErreurAppel, Reglages, Reponse, completer

COMPETENCES = tuple(_COMPETENCES_INVENTION) + ("E",)
CONFIGURATIONS: dict[str, tuple[bool, bool]] = {
    "base": (False, False), "base_rag": (False, True), "lora": (True, False), "lora_rag": (True, True)}
FRONTIERES = ("frontiere", "frontiere_rag")
MAX_CAR_REPONSE = 20000


@dataclass
class ReglagesMesure:
    client: Reglages = field(default_factory=Reglages)
    lora_ids: list[int] = field(default_factory=lambda: [0])   # adaptateurs chargés par llama-server
    lora_actif: int = 0                                         # celui qu'on mesure
    n_docs: int = 5                                             # extraits du RAG par tâche
    index: Path | None = None                                   # index du RAG (défaut : donnees/rag)
    tour: str = "t0"
    max_pas: int = 40                                           # budget de l'agent (compétences agentiques)


def reglages_depuis_config(config: dict[str, Any] | None = None) -> ReglagesMesure:
    from usine import config as cfg
    config = cfg.charger_config() if config is None else config
    llm, mesure = config.get("llm", {}), config.get("mesure", {})
    client = Reglages(url=llm.get("url", Reglages.url), modele=llm.get("modele", Reglages.modele),
                      cle=llm.get("cle"), max_jetons=int(mesure.get("max_jetons", Reglages.max_jetons)),
                      temperature=float(mesure.get("temperature", Reglages.temperature)),
                      graine=int(mesure.get("graine", Reglages.graine)),
                      delai_s=float(mesure.get("delai_s", Reglages.delai_s)))
    return ReglagesMesure(client=client, lora_ids=[int(i) for i in mesure.get("lora_ids", [0])],
                          lora_actif=int(mesure.get("lora_actif", 0)), n_docs=int(mesure.get("n_docs", 5)),
                          max_pas=int(mesure.get("max_pas", 40)))


def lora_requete(avec_lora: bool, r: ReglagesMesure) -> list[dict[str, Any]] | None:
    """Champ `lora` de la requête : l'adaptateur mesuré à 1, tous les autres à 0 (la base : tous à 0)."""
    if not r.lora_ids:
        if avec_lora:
            raise ValueError("configuration LoRA demandée, mais aucun adaptateur déclaré ([mesure].lora_ids)")
        return None
    if avec_lora and r.lora_actif not in r.lora_ids:
        raise ValueError(f"lora_actif {r.lora_actif} absent de lora_ids {r.lora_ids}")
    return [{"id": i, "scale": 1.0 if avec_lora and i == r.lora_actif else 0.0} for i in r.lora_ids]


def documentation(consigne: str, r: ReglagesMesure) -> str:
    """Extraits du RAG pour la consigne (même fonction que l'outil search_docs)."""
    from usine.rag.index import formater, search_docs
    return formater(search_docs(consigne, n=r.n_docs, base=r.index))


def taches_gelees(geles: Path, competences: Iterable[str] | None = None) -> list[Path]:
    """Tâches d'un dossier de jeux gelés, empreinte vérifiée contre le manifeste s'il existe."""
    from usine.taches import calculer_empreinte, lire_tache, lister_taches
    geles = Path(geles)
    manifeste = geles / "manifeste.json"
    attendues: dict[str, str] = {}
    if manifeste.is_file():
        donnees = json.loads(manifeste.read_text(encoding="utf-8"))
        for comp, entree in donnees.get("competences", {}).items():
            for t in entree.get("taches", []):
                attendues[t["id"]] = t["empreinte"]
    voulues = set(competences) if competences else None
    resultat = []
    for dossier in lister_taches(geles):
        tache = lire_tache(dossier)
        if voulues is not None and tache["competence"] not in voulues:
            continue
        empreinte = calculer_empreinte(dossier, tache)
        if empreinte != tache["empreinte"] or (attendues and attendues.get(tache["id"]) != empreinte):
            raise ValueError(f"tâche gelée modifiée (empreinte) : {dossier}")
        resultat.append(dossier)
    return resultat


def lire_resultats(fichiers: Iterable[Path]) -> list[dict[str, Any]]:
    """Lignes de résultats ; pour une même (tour, configuration, tâche), la dernière l'emporte."""
    lignes: dict[tuple[str, str, str], dict[str, Any]] = {}
    for f in fichiers:
        f = Path(f)
        if not f.is_file():
            continue
        with f.open(encoding="utf-8") as flux:
            for brut in flux:
                brut = brut.strip()
                if not brut:
                    continue
                try:
                    ligne = json.loads(brut)
                except json.JSONDecodeError:
                    continue   # dernière ligne tronquée par une coupure : refaite à la reprise
                lignes[(ligne.get("tour", ""), ligne["configuration"], ligne["tache_id"])] = ligne
    return list(lignes.values())


def ajouter_ligne(fichier: Path, ligne: dict[str, Any]) -> None:
    fichier.parent.mkdir(parents=True, exist_ok=True)
    with fichier.open("a", encoding="utf-8", newline="\n") as f:
        f.write(json.dumps(ligne, ensure_ascii=False, sort_keys=True) + "\n")
        f.flush()
        os.fsync(f.fileno())


def ligne_resultat(tache: dict[str, Any], configuration: str, tour: str, verdict: dict[str, Any],
                   reponse: Reponse | None, texte: str, duree_juge_s: float, modele: str) -> dict[str, Any]:
    premiere = verdict["erreurs"][0] if verdict.get("erreurs") else {}
    return {"tour": tour, "configuration": configuration, "competence": tache["competence"],
            "tache_id": tache["id"], "empreinte": tache["empreinte"], "ok": bool(verdict["ok"]),
            "etape": verdict.get("etape"), "categorie": premiere.get("categorie"),
            "message": (premiere.get("message") or "")[:300], "tests": verdict.get("tests"),
            "duree_appel_s": reponse.duree_s if reponse else None, "duree_juge_s": round(duree_juge_s, 3),
            "jetons_entree": reponse.jetons_entree if reponse else 0,
            "jetons_sortie": reponse.jetons_sortie if reponse else 0,
            "fin": reponse.fin if reponse else None, "modele": modele, "reponse": texte[:MAX_CAR_REPONSE]}


def noter(dossier: Path, tache: dict[str, Any], configuration: str, tour: str, texte: str,
          reponse: Reponse | None, modele: str,
          juger: Callable[[Path, str], dict[str, Any]] = reponses.juger_reponse) -> dict[str, Any]:
    debut = time.monotonic()
    verdict = juger(dossier, texte)
    return ligne_resultat(tache, configuration, tour, verdict, reponse, texte, time.monotonic() - debut, modele)


def executer(geles: Path, sortie: Path, r: ReglagesMesure, configurations: Iterable[str] = tuple(CONFIGURATIONS),
             competences: Iterable[str] | None = None, limite: int | None = None,
             appeler: Callable[..., Reponse] = completer,
             juger: Callable[[Path, str], dict[str, Any]] = reponses.juger_reponse,
             doc: Callable[[str, ReglagesMesure], str] = documentation,
             afficher: Callable[[str], None] = print, agentiques: bool = True,
             juger_projet: Callable[[Path, Path], dict[str, Any]] | None = None) -> dict[str, Any]:
    """Mesure les configurations demandées. Renvoie un bilan (faites, reprises, non mesurées).
    `agentiques=False` : les compétences agentiques sont comptées comme non mesurées."""
    from usine.taches import lire_tache
    configurations = list(configurations)
    inconnues = [c for c in configurations if c not in CONFIGURATIONS]
    if inconnues:
        raise ValueError(f"configurations inconnues : {inconnues}")
    sortie = Path(sortie)
    deja = {(l.get("tour"), l["configuration"], l["tache_id"], l.get("empreinte")) for l in lire_resultats([sortie])}
    par_comp: dict[str, list[Path]] = {}
    for dossier in taches_gelees(geles, competences):
        par_comp.setdefault(lire_tache(dossier)["competence"], []).append(dossier)
    bilan: dict[str, Any] = {"faites": 0, "reprises": 0, "non_mesurees": {}, "durees_appel_s": []}
    for comp in sorted(par_comp):
        dossiers = par_comp[comp][:limite] if limite else par_comp[comp]
        un_appel = comp in reponses.COMPETENCES_UN_APPEL
        if not un_appel and not agentiques:
            bilan["non_mesurees"][comp] = len(dossiers)
            afficher(f"{comp} : {len(dossiers)} tâches non mesurées (agentiques exclues)")
            continue
        schema = reponses.SCHEMAS.get(comp)
        for dossier in dossiers:
            tache = lire_tache(dossier)
            docs: str | None = None
            for conf in configurations:
                if (r.tour, conf, tache["id"], tache["empreinte"]) in deja:
                    bilan["reprises"] += 1
                    continue
                avec_lora, avec_rag = CONFIGURATIONS[conf]
                if avec_rag and docs is None:
                    docs = doc(tache["consigne"], r)
                if not un_appel:
                    ligne = essai_agentique(dossier, tache, conf, r, docs if avec_rag else None, avec_rag,
                                            lora_requete(avec_lora, r), appeler, juger_projet,
                                            sortie.with_name(sortie.name + ".sessions"))
                    bilan["durees_appel_s"].append(ligne["duree_appel_s"])
                    ajouter_ligne(sortie, ligne)
                    bilan["faites"] += 1
                    afficher(f"{conf:9s} {tache['id']:50s} {'OK ' if ligne['ok'] else 'NON'} {ligne['etape']}  "
                             f"session {ligne['duree_appel_s']:.1f} s")
                    continue
                msgs = reponses.messages(dossier / "depart", tache["consigne"], comp, docs if avec_rag else None)
                try:
                    rep: Reponse | None = appeler(r.client, msgs, schema, lora_requete(avec_lora, r))
                    texte = rep.contenu
                except ErreurAppel as exc:
                    rep, texte = None, ""
                    verdict = reponses.verdict_reponse_invalide(f"appel en échec : {exc}", tache["id"])
                    ligne = ligne_resultat(tache, conf, r.tour, verdict, None, "", 0.0, r.client.modele)
                else:
                    ligne = noter(dossier, tache, conf, r.tour, texte, rep, r.client.modele, juger)
                    bilan["durees_appel_s"].append(rep.duree_s)
                ajouter_ligne(sortie, ligne)
                bilan["faites"] += 1
                afficher(f"{conf:9s} {tache['id']:50s} {'OK ' if ligne['ok'] else 'NON'} "
                         f"{ligne['etape']}  appel {ligne['duree_appel_s'] or 0:.1f} s")
    return bilan


def essai_agentique(dossier: Path, tache: dict[str, Any], conf: str, r: ReglagesMesure, docs: str | None,
                    avec_rag: bool, lora: list[dict[str, Any]] | None, appeler: Callable[..., Reponse],
                    juger_projet: Callable[[Path, Path], dict[str, Any]] | None, sessions: Path) -> dict[str, Any]:
    """Une session de l'agent maison sur une copie de depart/, puis le juge de la tâche."""
    import tempfile
    from usine.juge.projet import preparer_copie
    from usine.rft import agent
    from usine.rft.essais import ecrire_session
    from usine.taches import juger_tache
    juger = juger_projet or (lambda d, copie: juger_tache(d, candidat=copie))
    debut = time.monotonic()
    with tempfile.TemporaryDirectory(prefix="usine_mesure_") as tmp:
        copie = preparer_copie(dossier / "depart", Path(tmp) / "projet")
        messages, outils, fin = agent.resoudre(copie, tache["consigne"], tache["competence"], r.client, lora,
                                               r.max_pas, appeler, () if avec_rag else ("search_docs",), docs)
        duree_session = time.monotonic() - debut
        debut_juge = time.monotonic()
        verdict = juger(dossier, copie)
        duree_juge = time.monotonic() - debut_juge
    ecrire_session(Path(sessions) / conf / f"{tache['id']}.jsonl",
                   {"tache_id": tache["id"], "competence": tache["competence"], "empreinte": tache["empreinte"],
                    "verdict_final": {k: verdict.get(k) for k in ("ok", "etape", "erreurs", "tests")},
                    "configuration": conf, "tour": r.tour, "fin": fin, "tools": outils}, messages)
    dernier = next((m.get("content") or "" for m in reversed(messages) if m.get("role") == "assistant"), "")
    ligne = ligne_resultat(tache, conf, r.tour, verdict, Reponse(dernier, round(duree_session, 3), fin=fin),
                           dernier, duree_juge, r.client.modele)
    ligne["pas"] = sum(1 for m in messages if m.get("role") == "assistant")
    return ligne


def juger_reponses(fichier_reponses: Path, geles: Path, sortie: Path,
                   juger: Callable[[Path, str], dict[str, Any]] = reponses.juger_reponse,
                   afficher: Callable[[str], None] = print) -> int:
    """Note des réponses collectées ailleurs (référence frontière) : une ligne de résultat chacune."""
    from usine.taches import lire_tache
    taches = {lire_tache(d)["id"]: d for d in taches_gelees(geles)}
    deja = {(l.get("tour"), l["configuration"], l["tache_id"], l.get("empreinte")) for l in lire_resultats([sortie])}
    n = 0
    with Path(fichier_reponses).open(encoding="utf-8") as flux:
        for brut in flux:
            if not brut.strip():
                continue
            rep = json.loads(brut)
            dossier = taches.get(rep["tache_id"])
            if dossier is None:
                afficher(f"tâche absente des jeux gelés : {rep['tache_id']}")
                continue
            tache = lire_tache(dossier)
            if rep.get("empreinte") != tache["empreinte"]:
                afficher(f"empreinte différente (réponse à une autre version de la tâche) : {rep['tache_id']}")
                continue
            if (rep.get("tour", "t0"), rep["configuration"], tache["id"], tache["empreinte"]) in deja:
                continue
            reponse = Reponse(rep.get("reponse", ""), float(rep.get("duree_appel_s") or 0.0),
                              int(rep.get("jetons_entree", 0)), int(rep.get("jetons_sortie", 0)), rep.get("fin"))
            ligne = noter(dossier, tache, rep["configuration"], rep.get("tour", "t0"), reponse.contenu,
                          reponse, rep.get("modele", ""), juger)
            ajouter_ligne(Path(sortie), ligne)
            n += 1
    return n
