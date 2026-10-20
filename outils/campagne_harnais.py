"""Campagne chronométrée de l'agent maison sur une copie d'un projet Godot : le même message est
redonné, session après session, jusqu'à la fin du temps imparti. Sert à comparer à l'œil trois
niveaux d'équipement, avec le même modèle, le même LoRA et le même message.

    py -3.12 outils/campagne_harnais.py <projet source> <dossier de travail> --prompt <fichier>
           [--equipement nu|usine|usine_rag] [--minutes 120] [--journaux <dossier>] [--sans-lora]

Équipement :
  nu         fichiers (list_files, read_file, write_file) et capture_ecran ; ni outil ni consigne de l'usine ;
  usine      en plus, les outils du serveur usine-godot sauf search_docs, et le message système de l'agent ;
  usine_rag  en plus, search_docs (doc Godot 4.7 et démos vérifiées).

Le projet source est copié dans le dossier de travail s'il n'y est pas déjà (jamais modifié
lui-même). Chaque session repart d'un contexte neuf, comme à l'entraînement (40 pas au plus) :
la continuité tient à ce que le modèle écrit dans le projet (plan.md). Quand le modèle dit avoir
fini, une nouvelle session repart aussitôt : la campagne ne s'arrête qu'à la fin du temps. capture_ecran lance le
jeu avec le rendu réel et rend les images au modèle dans un message utilisateur.

Journaux, hors du projet (défaut : <dossier de travail>/../_journaux/<nom>/) :
  journal.txt  les étapes ; sessions/  une session JSONL par session ; captures/  les images ;
  etat.txt  l'avancement ; bilan.json  les compteurs de fin.

Outil d'expérience demandé par laurent (2026-10-09) : le minuteur borne la campagne entière,
pas une session d'usage de Qwen (règle 1).
"""

from __future__ import annotations

import argparse
import base64
import collections
import dataclasses
import json
import shutil
import sys
import time
from pathlib import Path
from typing import Any

RACINE = Path(__file__).resolve().parent.parent
for chemin in (RACINE, RACINE / "outils"):
    if str(chemin) not in sys.path:
        sys.path.insert(0, str(chemin))

from capture_godot import capturer  # noqa: E402
from usine import config as cfg  # noqa: E402
from usine.mesure.client import ErreurAppel, completer  # noqa: E402
from usine.mesure.executer import reglages_depuis_config  # noqa: E402
from usine.rft import agent  # noqa: E402

EQUIPEMENTS = ("nu", "usine", "usine_rag")
MAX_PAS = 40                 # par session, comme à l'entraînement
MAX_CONTEXTE = 90000         # jetons d'entrée au-delà desquels la session est close (AGENTS.md : rester loin de 80 000… 100 000)
MAX_JETONS = 16000           # par réponse, comme la limite de sortie d'OpenCode : à 8 192, la réécriture d'un script
                             # de 23 000 caractères était coupée (campagne du 11 octobre)
TEMPERATURE = 0.7            # comme pour les essais RFT : à 0, deux sessions identiques referaient la même chose
SYSTEME_NU = "Tu es un développeur Godot 4.7 (GDScript typé) qui travaille dans un projet existant, avec des outils."
OUTIL_CAPTURE: dict[str, Any] = {"type": "function", "function": {
    "name": "capture_ecran",
    "description": ("Lance le jeu dans Godot avec le rendu réel pendant quelques secondes, sans appuyer sur aucune "
                    "touche, puis te montre des captures d'écran et les erreurs écrites par le moteur. "
                    "À utiliser pour vérifier à l'œil l'état du jeu et l'effet de tes modifications."),
    "parameters": {"type": "object", "properties": {
        "secondes": {"type": "number", "description": "durée de jeu, de 1 à 20 (défaut 5)"},
        "scene": {"type": "string", "description": "scène à lancer (res://…) ; défaut : la scène principale"}}}}}


def langage_edition() -> str:
    """Champs de chaque opération d'apply_edits, lus dans EDITS_GODOT.md (la référence du langage) : la
    déclaration de l'outil ne les donne pas, et sans fiche de compétence le modèle ne les voit nulle part."""
    lignes = (RACINE / "usine" / "projet" / "EDITS_GODOT.md").read_text(encoding="utf-8").splitlines()
    operations = []
    for ligne in lignes:
        cases = [c.strip() for c in ligne.strip().strip("|").split("|")]
        if len(cases) == 3 and cases[0].startswith("`") and cases[0] != "`op`":
            operations.append(f"- {cases[0].strip('`')} : {cases[1].replace('`', '').replace('**', '')}")
    entete = "Éditions d'apply_edits : une liste d'objets {\"op\": …} avec exactement ces champs (? = facultatif) :"
    exemple = ('Exemple : {"op": "replace_function", "script": "res://scripts/hero.gd", "fonction": "try_dash", '
               '"code": "func try_dash() -> void:\\n\\tpass"}')
    return "\n".join([entete, *operations, exemple])


def garder_eveille() -> None:
    """Empêche la mise en veille de Windows tant que ce processus vit."""
    if sys.platform == "win32":
        import ctypes
        ctypes.windll.kernel32.SetThreadExecutionState(0x80000000 | 0x00000001)   # ES_CONTINUOUS | ES_SYSTEM_REQUIRED


def apercu(texte: Any, maxi: int = 200) -> str:
    ligne = " ".join(str(texte).split())
    return ligne if len(ligne) <= maxi else ligne[:maxi] + " …"


class Campagne:
    def __init__(self, travail: Path, journaux: Path, equipement: str, prompt: str, minutes: float, avec_lora: bool):
        self.travail, self.journaux, self.equipement, self.prompt = travail, journaux, equipement, prompt
        r = reglages_depuis_config(cfg.charger_config())
        self.client = dataclasses.replace(r.client, temperature=TEMPERATURE, max_jetons=MAX_JETONS)
        self.lora = [{"id": i, "scale": 1.0 if avec_lora and i == r.lora_actif else 0.0} for i in r.lora_ids] or None
        self.boite = agent.Boite(travail)
        if equipement == "nu":
            self.outils, self.systeme = json.loads(json.dumps(agent.OUTILS_FICHIERS)), SYSTEME_NU
            self.boite.noms_mcp = set()
        else:
            exclus = () if equipement == "usine_rag" else ("search_docs",)
            self.outils = [d for d in agent.definitions() if d["function"]["name"] not in exclus]
            self.boite.noms_mcp -= set(exclus)
            self.systeme = agent.SYSTEME + "\n\n" + langage_edition()
        self.outils.append(OUTIL_CAPTURE)
        self.debut = time.monotonic()
        self.fin = self.debut + minutes * 60
        self.compte: collections.Counter[str] = collections.Counter()
        self.appels: collections.Counter[str] = collections.Counter()
        self.recherches: list[str] = []
        self.fins: list[str] = []
        (journaux / "sessions").mkdir(parents=True, exist_ok=True)
        (journaux / "captures").mkdir(exist_ok=True)
        self.journal = (journaux / "journal.txt").open("a", encoding="utf-8", newline="\n")

    # --- suivi
    def ecoule(self) -> str:
        s = int(time.monotonic() - self.debut)
        return f"{s // 3600}:{s % 3600 // 60:02d}:{s % 60:02d}"

    def ecrire(self, ligne: str) -> None:
        ligne = f"[{self.ecoule()}] {ligne}"
        print(ligne, flush=True)
        self.journal.write(ligne + "\n")
        self.journal.flush()

    def noter_etat(self, session: int, pas: int) -> None:
        (self.journaux / "etat.txt").write_text(
            f"{self.equipement} | écoulé {self.ecoule()} | session {session}, pas {pas} | "
            f"appels {sum(self.appels.values())} | erreurs d'outil {self.compte['erreurs_outil']} | "
            f"refus {self.compte['refus_outil']} | captures {self.compte['captures']}\n", encoding="utf-8")

    # --- outils
    def capture(self, arguments: dict[str, Any], session: int, pas: int) -> tuple[str, list[tuple[float, Path]]]:
        scene = arguments.get("scene") or None
        gardees, journal = capturer(self.travail, float(arguments.get("secondes") or 5), scene,
                                    self.journaux / "captures", prefixe=f"s{session:03d}_p{pas:02d}")
        self.compte["captures"] += 1
        if not gardees:
            self.compte["captures_sans_image"] += 1
            return "Aucune image : " + journal, []
        instants = ", ".join(f"{t} s" for t, _ in gardees)
        return (f"{len(gardees)} capture(s) jointe(s) dans le message suivant (à t = {instants}).\n"
                f"Journal du moteur (erreurs et avertissements) :\n{journal or '(rien)'}"), gardees

    def executer(self, appel: dict[str, Any], session: int, pas: int) -> tuple[str, list[tuple[float, Path]]]:
        nom = appel["function"]["name"]
        self.appels[nom] += 1
        try:
            arguments = json.loads(appel["function"]["arguments"] or "{}")
            if not isinstance(arguments, dict):
                raise ValueError("objet attendu")
        except (json.JSONDecodeError, ValueError) as exc:
            self.compte["arguments_invalides"] += 1
            return agent.neutraliser_arguments(appel, exc), []
        if nom in ("search_docs", "vocab_lookup"):
            self.recherches.append(f"{nom} {apercu(appel['function']['arguments'], 160)}")
        if nom == "capture_ecran":
            try:
                return self.capture(arguments, session, pas)
            except Exception as exc:
                return f"Erreur : capture impossible : {exc}", []
        if nom == "write_file" and self.ecriture_sans_effet(arguments):
            self.compte["ecritures_sans_changement"] += 1
            return (f"Aucun changement : ce contenu est déjà celui de {arguments.get('chemin')}, rien n'a été écrit. "
                    "Ne l'écris pas de nouveau : vérifie-le ou passe à la suite."), []
        return self.boite.appeler(nom, arguments), []

    def ecriture_sans_effet(self, arguments: dict[str, Any]) -> bool:
        """Vrai si write_file réécrirait exactement le contenu déjà sur le disque."""
        try:
            disque = self.boite.outils.disque(arguments["chemin"])
            if not disque.is_file():
                return False
            with disque.open(encoding="utf-8", newline="") as f:
                return f.read() == arguments.get("contenu")
        except Exception:
            return False

    # --- une session
    def session(self, k: int) -> tuple[str, int]:
        tache = f"Tâche (libre) :\n{self.prompt}\n\nLe projet est ouvert ; ses fichiers :\n" + self.boite.list_files()
        messages: list[dict[str, Any]] = [{"role": "system", "content": self.systeme}, {"role": "user", "content": tache}]
        client = dataclasses.replace(self.client, graine=self.client.graine + k)
        appels_session, fin = 0, "budget"
        fichiers: dict[int, list[str]] = {}                 # rang du message → images jointes
        for pas in range(1, MAX_PAS + 1):
            if time.monotonic() >= self.fin:
                fin = "temps"
                break
            try:
                rep = completer(client, messages, None, self.lora, self.outils)
            except ErreurAppel as exc:
                self.ecrire(f"s{k} p{pas} appel au modèle en échec : {apercu(exc, 300)}")
                self.compte["erreurs_appel"] += 1
                fin = "erreur_appel"
                break
            self.compte["jetons_entree"] += rep.jetons_entree
            self.compte["jetons_sortie"] += rep.jetons_sortie
            self.compte["pas"] += 1
            m = agent.message_assistant(rep)
            messages.append(m)
            if not m.get("tool_calls"):
                self.ecrire(f"s{k} p{pas} [fin de session] {apercu(m['content'], 1500)}")
                fin = "termine"
                break
            images: list[tuple[float, Path]] = []
            for appel in m["tool_calls"]:
                resultat, vues = self.executer(appel, k, pas)
                appels_session += 1
                images += vues
                if resultat.startswith("Erreur"):
                    self.compte["erreurs_outil"] += 1
                elif resultat.startswith('{"ok":false'):    # verdict d'un outil de l'usine : édition ou script refusé
                    self.compte["refus_outil"] += 1
                self.ecrire(f"s{k} p{pas} → {appel['function']['name']}({apercu(appel['function']['arguments'])})")
                self.ecrire(f"         ← {apercu(resultat)}")
                messages.append({"role": "tool", "tool_call_id": appel["id"], "content": resultat})
            if images:
                contenu: list[dict[str, Any]] = [{"type": "text", "text": "Captures d'écran demandées avec capture_ecran : "
                                                  + ", ".join(f"image {i + 1} à {t} s" for i, (t, _) in enumerate(images)) + "."}]
                contenu += [{"type": "image_url", "image_url": {"url": "data:image/png;base64,"
                                                                + base64.b64encode(p.read_bytes()).decode("ascii")}}
                            for _, p in images]
                fichiers[len(messages)] = [str(p) for _, p in images]
                messages.append({"role": "user", "content": contenu})
            self.noter_etat(k, pas)
            if rep.jetons_entree > MAX_CONTEXTE:
                fin = "contexte"
                break
        self.enregistrer(k, messages, fin, fichiers)
        return fin, appels_session

    def enregistrer(self, k: int, messages: list[dict[str, Any]], fin: str, fichiers: dict[int, list[str]]) -> None:
        legers = json.loads(json.dumps(messages))
        for rang, chemins in fichiers.items():              # les images restent dans captures/, pas dans le JSONL
            parties = [x for x in legers[rang]["content"] if x.get("type") == "image_url"]
            for partie, chemin_image in zip(parties, chemins):
                partie["image_url"] = {"url": "fichier:" + chemin_image}
        entete = {"session": k, "equipement": self.equipement, "harnais": "campagne", "lora": self.lora, "fin": fin,
                  "temperature": self.client.temperature, "graine": self.client.graine + k,
                  "tools": [o["function"]["name"] for o in self.outils]}
        (self.journaux / "sessions" / f"session_{k:03d}.jsonl").write_text(
            "".join(json.dumps(l, ensure_ascii=False) + "\n" for l in [entete, *legers]), encoding="utf-8", newline="\n")

    # --- la campagne
    def lancer(self) -> dict[str, Any]:
        self.ecrire(f"===== CAMPAGNE {self.equipement} — {self.travail} — outils : "
                    + ", ".join(o["function"]["name"] for o in self.outils))
        k = 0
        while time.monotonic() < self.fin:                  # jamais d'arrêt avant la fin du temps : on relance
            k += 1
            self.ecrire(f"----- session {k}")
            fin, appels_session = self.session(k)
            self.fins.append(fin)
            self.compte["sessions_sans_appel"] += appels_session == 0
            if fin == "erreur_appel":
                time.sleep(30)                              # llama-server occupé ou arrêté : ne pas boucler à vide
        arret = "temps écoulé"
        bilan = {"equipement": self.equipement, "travail": str(self.travail), "arret": arret, "duree": self.ecoule(),
                 "sessions": k, "fins": dict(collections.Counter(self.fins)), "appels": dict(self.appels.most_common()),
                 **{c: self.compte[c] for c in ("pas", "erreurs_outil", "refus_outil", "ecritures_sans_changement", "arguments_invalides", "erreurs_appel",
                                                "sessions_sans_appel", "captures", "captures_sans_image", "jetons_entree", "jetons_sortie")},
                 "recherches": self.recherches}
        (self.journaux / "bilan.json").write_text(json.dumps(bilan, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        self.ecrire(f"===== FIN ({arret}) : {k} sessions, {sum(self.appels.values())} appels d'outils, "
                    f"{self.compte['erreurs_outil']} erreurs d'outil, {self.compte['captures']} captures")
        self.journal.close()
        return bilan


def main(argv: list[str] | None = None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    p = argparse.ArgumentParser(prog="campagne_harnais.py")
    p.add_argument("source", type=Path)
    p.add_argument("travail", type=Path)
    p.add_argument("--prompt", type=Path, required=True)
    p.add_argument("--equipement", choices=EQUIPEMENTS, default="usine_rag")
    p.add_argument("--minutes", type=float, default=120.0)
    p.add_argument("--journaux", type=Path)
    p.add_argument("--sans-lora", action="store_true")
    a = p.parse_args(argv)

    source, travail = a.source.resolve(), a.travail.resolve()
    if not (source / "project.godot").is_file():
        print(f"pas de project.godot dans {source}", file=sys.stderr)
        return 2
    if not (travail / "project.godot").is_file():
        shutil.copytree(source, travail, ignore=shutil.ignore_patterns("opencode.json*", ".captures"), dirs_exist_ok=True)
    journaux = (a.journaux or travail.parent / "_journaux" / travail.name).resolve()
    garder_eveille()
    Campagne(travail, journaux, a.equipement, a.prompt.read_text(encoding="utf-8").strip(), a.minutes,
             not a.sans_lora).lancer()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
