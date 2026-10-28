"""Famille de paires « écrire une fonction d'un générateur de bâtiment d'après son contrat » (création ; procédural,
étape D1 du suivi, demande de laurent du 2026-10-28 : « il faut que tu reconstruises cette part »).

Le cours des bâtiments procéduraux n'a pas de tests GdUnit : son test d'étape compte des triangles et ne juge aucune
fonction. Le juge est ici l'empreinte des maillages : chaque scène que le test de l'étape vérifie est construite sans
fenêtre (Godot sans rendu garde les sommets : `surface_get_arrays`, vérifié le 2026-10-28), et ses surfaces, ses
transformations et ses lots instanciés passent dans un SHA-256 (`EMPREINTE`). Une fonction documentée (`##`) d'un
générateur (`6_assets/Mesh/Procedural/`, `1_core/procedural/`) est gardée seulement si :
- le script au corps vidé passe l'analyse (avertissements en erreurs) et change l'empreinte d'au moins une scène :
  le maillage dépend vraiment de la fonction ;
- avec la fonction d'origine, l'empreinte redevient celle de la référence, et le test de l'étape passe.

La demande et la réponse suivent la famille `creation_fonction` (`creation.py`) : le contrat, ce que la fonction
emploie, la fonction écrite, la signature réelle des appels de Godot, puis l'analyse et le test de l'étape (leur
sortie n'est pas écrite, règle 7.2). Palier 1 sans le plan quand il n'y joue aucun rôle (section 3), sinon palier 2.

    python -m usine.paires maillage [--par-etape N] [--etapes 1,2]
"""

from __future__ import annotations

import json
import os
import random
import re
from pathlib import Path
from typing import Any, Callable

from usine.paires import boucle
from usine.paires import creation as cf
from usine.paires import format as fmt

FAMILLE = "creation_maillage"
GENERATEURS = ("6_assets/Mesh/Procedural/", "1_core/procedural/")
JUGE = "empreinte_usine.gd"
# Le juge vit dans le projet le temps de juger ; typé comme le socle l'exige (avertissements en erreurs, règle 5.3).
SCRIPT_JUGE = """extends SceneTree
## Empreinte des maillages des scènes de l'étape (juge de l'usine, famille creation_maillage).

const SCENES: PackedStringArray = [{scenes}]


func _init() -> void:
	for path: String in SCENES:
		var instance: Node = (load(path) as PackedScene).instantiate()
		root.add_child(instance)
		await process_frame
		var ctx: HashingContext = HashingContext.new()
		ctx.start(HashingContext.HASH_SHA256)
		var pending: Array[Node] = [instance]
		while not pending.is_empty():
			var current: Node = pending.pop_back()
			if current.is_queued_for_deletion():
				continue
			pending.append_array(current.get_children(true))
			if current is MeshInstance3D and (current as MeshInstance3D).mesh != null:
				var mesh: Mesh = (current as MeshInstance3D).mesh
				ctx.update(var_to_bytes((current as Node3D).transform))
				for surface: int in range(mesh.get_surface_count()):
					ctx.update(var_to_bytes(mesh.surface_get_arrays(surface)))
			elif current is MultiMeshInstance3D and (current as MultiMeshInstance3D).multimesh != null:
				ctx.update(var_to_bytes((current as Node3D).transform))
				ctx.update(var_to_bytes((current as MultiMeshInstance3D).multimesh.buffer))
		print("EMPREINTE ", path, " ", ctx.finish().hex_encode())
		root.remove_child(instance)
		instance.queue_free()
		await process_frame
	quit(0)
"""
EMPREINTE = re.compile(r"^EMPREINTE (\S+) ([0-9a-f]{64})$", re.M)


def scenes_du_test(texte_test: str) -> list[str]:
    """Les scènes que le test de l'étape vérifie (sa constante `SCENES`)."""
    m = re.search(r"const SCENES[^\[]*\[(.*?)\]", texte_test, re.S)
    return re.findall(r'"(res://[^"]+\.tscn)"', m[1]) if m else []


def empreintes(projet: Any, scenes: list[str]) -> dict[str, str] | None:
    """Scène → SHA-256 de ses maillages, ou None si une scène ne se construit pas."""
    from usine.cours.base import godot
    chemin = os.path.join(projet.chemin, JUGE)
    with open(chemin, "w", encoding="utf-8", newline="") as h:
        h.write(SCRIPT_JUGE.format(scenes=", ".join(f'"{s}"' for s in scenes)))
    try:
        s = godot.tester(projet.chemin, "res://" + JUGE, delai=180)
    finally:
        os.remove(chemin)
    trouvees = dict(EMPREINTE.findall(s.texte))
    if s.code != 0 or set(trouvees) != set(scenes) or "SCRIPT ERROR" in s.texte:
        return None
    return trouvees


def paire(projet: Any, rel: str, f: Any, test: str, scenes: list[str], reference: dict[str, str],
          sujet: str) -> tuple[dict[str, Any] | None, str]:
    from usine.cours.base import godot, sessions
    original = projet.apres[rel]
    projet.remettre()
    try:
        masque_ok = None
        for vide in cf.masque(original, f):
            projet.ecrire(rel, vide)
            if sessions.propre("analyse", projet.lancer("analyse", rel)):
                masque_ok = vide
                break
        if masque_ok is None:
            return None, "le script au corps vidé ne passe pas l'analyse"
        sans = empreintes(projet, scenes)
        if sans == reference:
            return None, "le maillage ne change pas sans le corps : rien ne juge cette fonction"
        projet.remettre()
        avec = empreintes(projet, scenes)
        if avec != reference:
            return None, "avec la fonction d'origine, le maillage diffère de la référence (non déterministe ?)"
        analyse = godot.verifier_script(projet.chemin, "res://" + rel)
        t = projet.lancer("test")
        if t.code != 0 or "SCRIPT ERROR" in t.texte:
            return None, "le test de l'étape ne passe pas avec la fonction d'origine"
    finally:
        projet.remettre()
    fonction = cf.texte_fonction(original.split("\n"), f)
    tete = (f"Projet Godot 4.7.2. Dans `res://{rel}`, écris le corps de `{f.nom}` d'après son contrat (les commentaires "
            f"`##`). Le test de l'étape, `res://{test}`, construit le bâtiment et le vérifie.")
    ecrire = [f"**Écrire.** `{f.nom}`, d'après son contrat :", f"```gdscript\n{fonction}\n```"]
    u = cf.usages(fonction, original)
    api = ["", "**Vérifier l'API.** Les appels de Godot employés, relus dans `extension_api.json` (4.7.2) :"] + u if u else []
    tester = ["", "**Tester.** J'analyse le script, puis je lance le test de l'étape."]
    # La boucle de vérification (boucle.py) : les vraies sorties de l'analyse et du test de l'étape, puis leur lecture.
    sorties = [(analyse, "analyse"), (t, "test")]
    lire = boucle.lecture(sorties, f"`{f.nom}`", [], None)
    if lire is None:
        return None, "la sortie de vérification ne passe pas la lecture"
    preuve = {"etape": f"{projet.ville}-{projet.n:03d}", "fichier": rel, "fonction": f.nom, "test": test,
              "scenes": scenes, "empreinte_reference": reference, "empreinte_sans_corps": sans,
              "masque_compile": True, "maillage_change_sans_corps": True, "maillage_identique_avec": True,
              "commande_analyse": analyse.commande, "sortie_analyse": analyse.texte,
              "commande_test": t.commande, "code_test": t.code}
    ailleurs = cf.employes_ailleurs(original, f, projet.apres)
    ailleurs = f"\n\nCe que la fonction emploie d'autres scripts du projet :\n{ailleurs}" if ailleurs else ""
    demande = (f"{tete} Ce que le script déclare et que la fonction emploie :\n```gdscript\n"
               f"{cf.contexte_minimal(original, f)}```{ailleurs}")
    return boucle.paire(FAMILLE, sujet, f"verif_{f.nom}", demande, ecrire, api, tester, sorties, lire, preuve,
                        cf.sans_convention(fonction, projet.apres, original))


def generer(par_etape: int = 30, graine: int = 1, etapes: list[int] | None = None, donnees: Path | None = None,
            journal: Callable[[str], None] = print) -> dict[str, Any]:
    """`par_etape` fonctions tirées par étape et par ville (graine fixe), chaque fonction une seule fois dans le
    cours (clé sans numéro d'étape, `format.commun` ; règle 7.7)."""
    from usine.cours.base import assembler, chemins, creation, etat, sessions
    from usine.paires.execution import _sujet
    chemins.configurer(cours="batiments_proceduraux")
    sortie = fmt.dossier(FAMILLE, donnees)
    paires: list[dict[str, Any]] = []
    rejets: list[str] = []
    rng = random.Random(graine)
    vues: set[tuple[str, str]] = set()
    for ville in assembler.ordre_lignes():
        for n in etapes or list(assembler.etapes_du_cours()):
            _, apres = creation.etats(ville, n)
            test = creation.TEST.format(nom=etat.nom(ville, n))
            scenes = scenes_du_test(apres.get(test, ""))
            dispo = []
            for rel in sorted(apres):
                if not rel.endswith(".gd") or not rel.startswith(GENERATEURS):
                    continue
                lignes = apres[rel].split("\n")
                for f in cf.candidates(apres, rel):
                    cle = (fmt.commun(rel), fmt.commun(cf.texte_fonction(lignes, f)))
                    if cle not in vues:
                        dispo.append((rel, f, cle))
            if not dispo or not scenes:
                continue
            rng.shuffle(dispo)
            projet = sessions.Projet(ville, n, apres)
            reference = empreintes(projet, scenes)
            if reference is None or empreintes(projet, scenes) != reference:
                rejets.append(f"{ville}-{n:03d} : empreinte de référence absente ou non déterministe")
                continue
            gardees = essais = 0
            for rel, f, cle in dispo:
                if gardees >= par_etape or essais >= par_etape * 3:
                    break
                essais += 1
                p, raison = paire(projet, rel, f, test, scenes, reference, _sujet(ville, n, rel))
                if not p:
                    rejets.append(f"{ville}-{n:03d} {rel} {f.nom} : {raison}")
                    continue
                paires.extend(p if isinstance(p, list) else [p])
                vues.add(cle)
                gardees += 1
            journal(f"{ville}-{n:03d} : {gardees}/{essais} paires")
    retenues = [p for p in paires if p["jetons"] <= cf.PLAFOND]
    fmt.ecrire(retenues, sortie / "paires_batiments_proceduraux.jsonl")
    bilan: dict[str, Any] = {"famille": FAMILLE, "cours": "batiments_proceduraux", "paires": len(retenues),
                             "trop_longues": len(paires) - len(retenues), "rejets": rejets, "par_sujet": {},
                             "par_palier": {},
                             "jetons_max": max((p["jetons"] for p in retenues), default=0),
                             "jetons_moyens": round(sum(p["jetons"] for p in retenues) / max(len(retenues), 1))}
    for p in retenues:
        bilan["par_sujet"][p["sujet"]] = bilan["par_sujet"].get(p["sujet"], 0) + 1
        bilan["par_palier"][p["preuve"]["palier"]] = bilan["par_palier"].get(p["preuve"]["palier"], 0) + 1
    (sortie / "bilan_batiments_proceduraux.json").write_text(json.dumps(bilan, indent=1, ensure_ascii=False),
                                                             encoding="utf-8")
    return bilan
