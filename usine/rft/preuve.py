"""Preuve de la session 5 (cloud) : un mini-tour complet contre un faux serveur juste à 60 %.

- Tâches : les 2 tâches D1 modèles (godot/taches_modeles) et 3 tâches F1 tirées par le
  générateur inverse sur godot/reference (vérité terrain dans tache.json).
- Faux serveur OpenAI-compatible : pour la tâche t et la graine g de la requête, il répond juste
  si sha256("t:g") mod 100 < 60, sinon il répond faux (ligne décalée pour D1, vitesse fausse pour
  F1). Le vrai juge (Godot, GdUnit4) note chaque essai.
- Coupure simulée au milieu du tour (exception après k appels), puis reprise.
Contrôles : solutions gardées = tâches dont au moins un essai est juste (calcul indépendant du
serveur) ; aucun essai refait en double à la reprise ; JSONL valides ; configurations relues.
"""

from __future__ import annotations

import hashlib
import json
import shutil
import tempfile
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any, Callable

from usine import config as cfg
from usine.mesure.client import Reglages, completer
from usine.rft import export
from usine.rft.essais import ReglagesRft
from usine.rft.tour import lire_registre, tour

TAUX_JUSTE = 60


def juste(tache_id: str, graine: int) -> bool:
    return int(hashlib.sha256(f"{tache_id}:{graine}".encode("utf-8")).hexdigest(), 16) % 100 < TAUX_JUSTE


class ServeurJuste60(ThreadingHTTPServer):
    """`reperes` : (texte qui identifie la tâche dans le prompt, id, réponse juste, réponse fausse)."""
    daemon_threads = True

    def __init__(self, reperes: list[tuple[str, str, dict[str, Any], dict[str, Any]]]):
        self.reperes = reperes
        self.appels = 0
        serveur = self

        class Gestion(BaseHTTPRequestHandler):
            def do_POST(self):  # noqa: N802
                corps = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
                texte = corps["messages"][-1]["content"]
                trouves = [r for r in serveur.reperes if r[0] in texte]
                if len(trouves) != 1:
                    contenu = "{}"
                else:
                    _, tid, bonne, fausse = trouves[0]
                    contenu = json.dumps(bonne if juste(tid, int(corps.get("seed", 0))) else fausse)
                serveur.appels += 1
                donnees = json.dumps({"choices": [{"message": {"role": "assistant", "content": contenu},
                                                   "finish_reason": "stop"}],
                                      "usage": {"prompt_tokens": 1, "completion_tokens": 1}}).encode("utf-8")
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(donnees)))
                self.end_headers()
                self.wfile.write(donnees)

            def log_message(self, *args):
                pass

        super().__init__(("127.0.0.1", 0), Gestion)
        threading.Thread(target=self.serve_forever, daemon=True).start()

    @property
    def url(self) -> str:
        return f"http://127.0.0.1:{self.server_address[1]}/v1"


class Coupure(Exception):
    pass


def preparer_taches(racine: Path, n_f1: int = 3) -> list[tuple[str, str, dict[str, Any], dict[str, Any]]]:
    """Copie les D1 modèles et génère n_f1 tâches F1 ; renvoie les repères du faux serveur."""
    from usine.generateurs import inverse
    reperes = []
    for d in sorted((cfg.RACINE / "godot" / "taches_modeles" / "D1").iterdir()):
        shutil.copytree(d, racine / "D1" / d.name)
        bonne = json.loads((d / "reference" / "reponse.json").read_text(encoding="utf-8"))
        reperes.append((f"{bonne['fichier']}:{bonne['ligne']}", d.name, bonne, {**bonne, "ligne": bonne["ligne"] + 1}))
    prod = inverse.generer(cfg.RACINE / "godot" / "reference", racine, graine=5, nombre=n_f1)
    for d in prod.taches:
        tache = json.loads((d / "tache.json").read_text(encoding="utf-8"))
        bonne = dict(tache["generateur"]["valeurs"])
        reperes.append((tache["consigne"], tache["id"], bonne, {**bonne, "speed": bonne["speed"] + 50.0}))
    return reperes


def verifier_export(dossier: Path) -> list[str]:
    """Problèmes de l'export (liste vide si tout est valide)."""
    problemes = []
    for f in (dossier / "sft.jsonl", dossier / "llamafactory" / f"{export.NOM_JEU}.jsonl"):
        for i, ligne in enumerate(f.read_text(encoding="utf-8").splitlines()):
            e = json.loads(ligne)
            if "messages" in e:
                if e["messages"][-1]["role"] != "assistant" or any(
                        m["role"] not in ("system", "user", "assistant", "tool") for m in e["messages"]):
                    problemes.append(f"{f.name}:{i + 1} : rôles invalides")
                json.loads(e["tools"])
            else:
                for k, tour_ in enumerate(e["conversations"]):
                    if tour_["from"] not in (("human", "observation") if k % 2 == 0 else ("gpt", "function_call")):
                        problemes.append(f"{f.name}:{i + 1} : alternance rompue au tour {k}")
                if e["conversations"][-1]["from"] not in ("gpt", "function_call"):
                    problemes.append(f"{f.name}:{i + 1} : ne finit pas par l'assistant")
    info = json.loads((dossier / "llamafactory" / "dataset_info.json").read_text(encoding="utf-8"))
    if export.NOM_JEU not in info:
        problemes.append("dataset_info.json : jeu absent")
    c = export.lire_yaml_plat((dossier / "llamafactory" / "qwen38_qlora_r16.yaml").read_text(encoding="utf-8"))
    if tuple(c) != export.CLES_LLAMAFACTORY or c["packing"] or c["neat_packing"] or c["lora_rank"] != 16:
        problemes.append("configuration LLaMA-Factory inattendue")
    u = json.loads((dossier / "unsloth" / "config_unsloth.json").read_text(encoding="utf-8"))
    if u["packing"] or u["rang"] != 16:
        problemes.append("configuration Unsloth inattendue")
    compile((dossier / "unsloth" / "entrainer_unsloth.py").read_text(encoding="utf-8"), "entrainer_unsloth.py", "exec")
    return problemes


def executer_preuve(dossier: Path, n_essais: int = 3, couper_apres: int = 7, graine: int = 4,
                    afficher: Callable[[str], None] = print) -> dict[str, Any]:
    from usine.taches import lister_taches
    taches_dir = dossier / "taches"
    reperes = preparer_taches(taches_dir)
    taches = lister_taches(taches_dir)
    serveur = ServeurJuste60(reperes)
    try:
        # graine 4 : 8 essais justes sur 15 (53 %) et deux tâches jamais réussies (elles passent au tour suivant)
        r = ReglagesRft(client=Reglages(url=serveur.url), n_essais=n_essais, temperature=0.7, graine=graine)
        sortie = dossier / "tour"
        appels = {"n": 0}

        def appeler_coupe(*args, **kwargs):
            appels["n"] += 1
            if appels["n"] > couper_apres:
                raise Coupure()
            return completer(*args, **kwargs)

        try:
            tour(taches, sortie, r, appeler=appeler_coupe, afficher=afficher)
        except Coupure:
            afficher(f"-- coupure simulée après {couper_apres} appels")
        avant = lire_registre(sortie / "registre.csv")
        appels_avant = serveur.appels
        bilan = tour(taches, sortie, r, afficher=afficher)
        appels_reprise = serveur.appels - appels_avant
    finally:
        serveur.shutdown()
        serveur.server_close()
    registre = lire_registre(sortie / "registre.csv")
    attendus = sorted(tid for _, tid, _, _ in reperes if any(juste(tid, r.graine + n) for n in range(n_essais)))
    retenus = [l["tache_id"] for l in lire_registre(sortie / "retenus.csv")]
    taches_avant = len({l["tache_id"] for l in avant})
    controles = {
        "solutions gardées = tâches avec au moins un essai juste": sorted(retenus) == attendus,
        "chaque essai noté juste par le juge l'est par le serveur": all(
            (l["ok"] == "True") == juste(l["tache_id"], r.graine + int(l["essai"])) for l in registre),
        "registre complet, sans doublon": len(registre) == len(taches) * n_essais
        and len({(l["tache_id"], l["essai"]) for l in registre}) == len(registre),
        "reprise : seuls les essais manquants sont refaits": appels_reprise == (len(taches) - taches_avant) * n_essais,
        "export : JSONL et configurations valides": verifier_export(sortie / "export") == [],
        "export : une session par solution gardée": bilan["export"]["exportees"] == len(attendus),
        "tâches jamais réussies → a_refaire.txt": (sortie / "a_refaire.txt").read_text(encoding="utf-8").split()
        == sorted(tid for _, tid, _, _ in reperes if tid not in attendus),
    }
    return {"taches": len(taches), "essais_par_tache": n_essais, "taches_finies_avant_coupure": taches_avant,
            "appels_a_la_reprise": appels_reprise, "retenus": retenus, "attendus": attendus,
            "a_refaire": (sortie / "a_refaire.txt").read_text(encoding="utf-8").split(),
            "export": bilan["export"], "controles": controles}


def preuve(dossier: Path | None = None) -> int:
    with tempfile.TemporaryDirectory(prefix="usine_preuve_rft_") as tmp:
        res = executer_preuve(Path(dossier) if dossier else Path(tmp))
    print(f"\n{res['taches']} tâches × {res['essais_par_tache']} essais ; coupure après "
          f"{res['taches_finies_avant_coupure']} tâches finies ; {res['appels_a_la_reprise']} appels à la reprise")
    print(f"Retenues : {len(res['retenus'])} (attendu : {len(res['attendus'])}) ; à refaire : {res['a_refaire']}")
    print(f"Export : {res['export']}")
    for nom, ok in res["controles"].items():
        print(f"{'OK   ' if ok else 'ÉCHEC'} {nom}")
    tout = all(res["controles"].values())
    print("CONFORME" if tout else "NON CONFORME")
    return 0 if tout else 1
