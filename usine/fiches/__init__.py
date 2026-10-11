"""Fiches par besoin et par situation (béquille, points 3, 4 et 5).

Avant d'agir, Qwen déclare son action : le but, le type d'ajout (un des modèles du plan
d'organisation), les fichiers qu'il compte toucher, et les besoins qu'il coche dans une liste
fermée. `preparer_action` lui rend tout d'un coup : où travailler, la chaîne à imiter (vérifiée
sur le disque), ses fichiers confrontés au plan, et pour chaque besoin sa fiche en cinq rubriques
(à considérer, API avec signatures officielles, exemple tiré du projet, pièges, voisins).

Déterministe (règle 2) : les fiches sont des JSON versionnés dans `donnees/`, chaque nom d'API
est vérifié dans extension_api.json par les tests (règle 6), chaque exemple est extrait d'un vrai
fichier du projet, ou à défaut du socle de l'usine (godot/socle_jeu).
"""

from __future__ import annotations

import json
import re
from functools import lru_cache
from pathlib import Path
from typing import Any

from usine import config as cfg
from usine.regles.catalogue import texte as texte_regle
from usine.retour.verification import Signatures
from usine.structure.regles import DOSSIERS, FICHIERS_RACINE, dossier_de

DONNEES = Path(__file__).resolve().parent / "donnees"
SOCLE = cfg.RACINE / "godot" / "socle_jeu"
LIGNES_EXEMPLE = 40

# Les sept modèles d'intégration d'ORGANISATION.md : fichiers à toucher, dossiers permis, chaîne à imiter.
MODELES: dict[str, dict[str, Any]] = {
    "etat": {
        "titre": "un état d'un acteur",
        "fichiers": ["3_entities/<acteur>/states/<acteur>_<etat>.gd",
                     "un nœud dans la StateMachine de 3_entities/<acteur>/<acteur>.tscn",
                     "7_tests/3_entities/<acteur>/test_<acteur>.gd"],
        "dossiers": {"3_entities", "5_data", "1_core", "7_tests"},
        "chaine": ["res://3_entities/player/states/player_dash.gd", "res://3_entities/player/player.tscn",
                   "res://7_tests/3_entities/player/test_player.gd"],
        "besoins": ["etat"],
    },
    "ennemi": {
        "titre": "un ennemi",
        "fichiers": ["5_data/enemies/<type>.tres", "3_entities/enemies/<type>/<type>.tscn et <type>.gd",
                     "3_entities/enemies/<type>/<type>_view.gd (sprites, sons, effets)",
                     "3_entities/enemies/<type>/states/",
                     "posé dans 2_sequence/levels/<niveau>/<niveau>.tscn, qui lui donne ses dépendances par setup()",
                     "7_tests/3_entities/enemies/<type>/test_<type>.gd"],
        "dossiers": {"5_data", "3_entities", "2_sequence", "6_assets", "7_tests"},
        "chaine": ["res://5_data/enemies/drone.tres", "res://3_entities/enemies/drone/drone.tscn",
                   "res://3_entities/enemies/drone/drone.gd", "res://3_entities/enemies/drone/drone_view.gd",
                   "res://3_entities/enemies/drone/states/drone_chase.gd",
                   "res://2_sequence/levels/level_base/level_base.gd",
                   "res://7_tests/3_entities/enemies/drone/test_drone.gd"],
        "besoins": ["etat", "collision", "donnees"],
    },
    "arme": {
        "titre": "une arme",
        "fichiers": ["5_data/weapons/<arme>.tres (WeaponStats)", "3_entities/projectiles/<projectile>/",
                     "un WeaponComponent dans la scène de l'acteur", "7_tests/1_core/components/test_weapon_component.gd"],
        "dossiers": {"5_data", "3_entities", "6_assets", "7_tests"},
        "chaine": ["res://5_data/weapons/blaster.tres", "res://3_entities/projectiles/bullet/bullet_player.tscn",
                   "res://3_entities/projectiles/bullet/bullet.gd", "res://1_core/components/weapon_component.gd",
                   "res://7_tests/1_core/components/test_weapon_component.gd"],
        "besoins": ["collision", "minuterie", "donnees"],
    },
    "reglage": {
        "titre": "un réglage",
        "fichiers": ["une propriété @export typée dans la classe de 1_core/data/ (et sa ligne dans validate())",
                     "sa valeur dans le .tres de 5_data/", "7_tests/1_core/data/test_definitions.gd"],
        "dossiers": {"1_core", "5_data", "7_tests"},
        "chaine": ["res://1_core/data/actor_stats.gd", "res://5_data/actors/player.tres",
                   "res://1_core/data/game_rules.gd", "res://5_data/game/game_rules.tres"],
        "besoins": ["donnees"],
    },
    "interface": {
        "titre": "un élément d'interface",
        "fichiers": ["4_ui/hud/ ou 4_ui/overlays/<nom>/ (scène + script)",
                     "l'interface écoute un signal d'un autoload (GameState) ou reçoit l'information du niveau",
                     "7_tests/4_ui/<chemin>/test_<nom>.gd"],
        "dossiers": {"4_ui", "0_autoload", "6_assets", "7_tests"},
        "chaine": ["res://4_ui/hud/hud.gd", "res://4_ui/hud/hud.tscn", "res://0_autoload/game_state.gd",
                   "res://7_tests/4_ui/hud/test_hud.gd"],
        "besoins": ["interface"],
    },
    "niveau": {
        "titre": "un niveau",
        "fichiers": ["2_sequence/levels/<niveau>/<niveau>.tscn (hérite de level_base.tscn)",
                     "5_data/levels/<niveau>_budget.tres", "une ligne dans 2_sequence/sequence.tres",
                     "7_tests/2_sequence/levels/<niveau>/test_<niveau>.gd"],
        "dossiers": {"2_sequence", "5_data", "6_assets", "7_tests"},
        "chaine": ["res://2_sequence/levels/level_01/level_01.tscn", "res://2_sequence/levels/level_base/level_base.tscn",
                   "res://5_data/levels/level_01_budget.tres", "res://2_sequence/sequence.tres",
                   "res://7_tests/2_sequence/levels/level_01/test_level_01.gd"],
        "besoins": [],
    },
    "effet_visuel": {
        "titre": "un effet visuel",
        "fichiers": ["3_entities/effects/<effet>/ (scène + script qui se détruit)",
                     "un @export var <effet>: PackedScene sur le niveau, transmis au script _view de l'acteur"],
        "dossiers": {"3_entities", "6_assets", "7_tests"},
        "chaine": ["res://3_entities/effects/impact/impact.tscn", "res://3_entities/effects/impact/impact.gd",
                   "res://3_entities/enemies/drone/drone_view.gd"],
        "besoins": ["effet_visuel"],
    },
}


@lru_cache(maxsize=1)
def charger() -> dict[str, dict[str, Any]]:
    """Toutes les fiches, par identifiant."""
    fiches = {}
    for f in sorted(DONNEES.glob("*.json")):
        fiche = json.loads(f.read_text(encoding="utf-8"))
        fiches[fiche["id"]] = fiche
    return fiches


def ids(genre: str) -> list[str]:
    """La liste fermée des besoins (genre « besoin ») ou des situations (« situation »)."""
    return [i for i, f in charger().items() if f["genre"] == genre]


def _disque(res: str, projet: Path | None) -> Path | None:
    """Le fichier dans le projet, sinon dans le socle de l'usine ; None s'il n'existe nulle part."""
    rel = res.removeprefix("res://")
    for racine in ([Path(projet)] if projet else []) + [SOCLE]:
        if (racine / rel).is_file():
            return racine / rel
    return None


def _bloc_fonction(texte: str, fonction: str) -> str | None:
    lignes = texte.splitlines()
    motif = re.compile(rf"^(?:static\s+)?func\s+{re.escape(fonction)}\s*\(")
    for i, ligne in enumerate(lignes):
        if motif.match(ligne):
            fin = i + 1
            while fin < len(lignes) and (not lignes[fin].strip() or lignes[fin][0] in " \t"):
                fin += 1
            while fin > i + 1 and not lignes[fin - 1].strip():
                fin -= 1
            return "\n".join(lignes[i:fin])
    return None


def _bloc_noeud(texte: str, noeud: str) -> str | None:
    lignes = texte.splitlines()
    for i, ligne in enumerate(lignes):
        if ligne.startswith("[node ") and f'name="{noeud}"' in ligne:
            fin = i + 1
            while fin < len(lignes) and not lignes[fin].startswith("["):
                fin += 1
            return "\n".join(lignes[i:fin]).rstrip()
    return None


def extraire_exemple(exemple: dict[str, str], projet: Path | None = None) -> tuple[str, str] | None:
    """(origine, extrait) : une fonction, un nœud de scène ou le début d'un fichier ; None si introuvable."""
    disque = _disque(exemple["fichier"], projet)
    if disque is None:
        return None
    texte = disque.read_text(encoding="utf-8")
    if "fonction" in exemple:
        bloc = _bloc_fonction(texte, exemple["fonction"])
        cible = f"{exemple['fichier']} : {exemple['fonction']}()"
    elif "noeud" in exemple:
        bloc = _bloc_noeud(texte, exemple["noeud"])
        cible = f"{exemple['fichier']} : nœud {exemple['noeud']}"
    else:
        bloc, cible = texte.rstrip(), exemple["fichier"]
    if bloc is None:
        return None
    lignes = bloc.splitlines()
    if len(lignes) > LIGNES_EXEMPLE:
        bloc = "\n".join(lignes[:LIGNES_EXEMPLE] + [f"# … {len(lignes) - LIGNES_EXEMPLE} lignes de plus"])
    origine = "projet" if projet and disque.is_relative_to(Path(projet)) else "socle de l'usine"
    return f"{cible} ({origine})", bloc


def signature_api(nom: str, signatures: Signatures) -> str | None:
    """« Classe.membre » → signature officielle, ou None si le membre n'existe pas."""
    classe, _, membre = nom.partition(".")
    if not membre:
        return f"classe {classe}" if signatures.vocab.classe_existe(classe) else None
    return signatures.texte(classe, membre)


def rendre_fiche(fiche: dict[str, Any], signatures: Signatures, projet: Path | None = None) -> str:
    """Les cinq rubriques d'une fiche, en texte."""
    sortie = [f"## {fiche['titre']} ({fiche['genre']} « {fiche['id']} »)", "", "À considérer :"]
    sortie += [f"- {x}" for x in fiche["a_considerer"]]
    sortie += ["", "Où travailler :"] + [f"- {x}" for x in fiche["ou_travailler"]]
    sortie += ["", "API (signatures officielles Godot) :"]
    sortie += [f"- {signature_api(n, signatures) or n + ' (absent du vocabulaire : ne pas l’utiliser)'}"
               for n in fiche["api"]]
    for ex in fiche["exemples"][:1] or []:
        extrait = extraire_exemple(ex, projet)
        if extrait:
            sortie += ["", f"Exemple à imiter, {extrait[0]} :", "```", extrait[1], "```"]
    autres = [ex["fichier"] for ex in fiche["exemples"][1:] if _disque(ex["fichier"], projet)]
    if autres:
        sortie += [f"Voir aussi : {', '.join(autres)}"]
    sortie += ["", "Pièges :"] + [f"- {x}" for x in fiche["pieges"]]
    if fiche.get("regles"):
        sortie += ["", "Règles concernées (le juge vérifie celles qui sont mécaniques) :"]
        sortie += [f"- {texte_regle(r)}" for r in fiche["regles"]]
    if fiche["voisins"]:
        sortie += ["", "Voisins (à cocher aussi si concerné) : " + ", ".join(fiche["voisins"])]
    return "\n".join(sortie)


def verifier_fichiers(fichiers: list[str], modele: dict[str, Any] | None, projet: Path) -> list[str]:
    """Chaque fichier déclaré confronté au plan : dossier, nom, dossiers du modèle, test en miroir."""
    remarques = []
    for brut in fichiers:
        res = brut.strip().replace("\\", "/")
        res = res if res.startswith("res://") else "res://" + res.lstrip("./")
        rel = res.removeprefix("res://")
        nom = rel.rsplit("/", 1)[-1]
        etat = "existe, à modifier" if (Path(projet) / rel).is_file() else "nouveau"
        dossier = dossier_de(res)
        if "/" not in rel:
            avis = "à la racine : permis" if nom in FICHIERS_RACINE else "à la racine : interdit, choisir un dossier du plan"
        elif dossier is None:
            avis = f"hors du plan : « {rel.split('/', 1)[0]} » n'est pas un dossier du plan ({', '.join(DOSSIERS)})"
        elif modele and dossier not in modele["dossiers"]:
            avis = f"dans {dossier} ({DOSSIERS[dossier]}) : inhabituel pour {modele['titre']}"
        elif nom.endswith((".gd", ".tscn", ".tres")) and not re.fullmatch(r"[a-z0-9_]+", nom.rsplit(".", 1)[0]):
            avis = "nom hors convention (snake_case attendu)"
        elif nom.endswith(".gd") and dossier in ("5_data", "6_assets"):
            avis = f"script dans {dossier} : ce dossier ne contient aucun code"
        elif nom.endswith(".gd") and dossier == "7_tests" and not (Path(projet) / rel.removeprefix("7_tests/")).parent.is_dir():
            avis = "test hors miroir : 7_tests/<chemin du code testé>/test_<nom>.gd (QA-01)"
        else:
            avis = f"dans le plan ({DOSSIERS[dossier]})"
        remarques.append(f"- {res} : {etat} ; {avis}")
    scripts = [f for f in fichiers if f.endswith(".gd") and "7_tests" not in f]
    if scripts and not any("7_tests" in f for f in fichiers):
        remarques.append("- aucun test déclaré : un test par comportement, dans 7_tests/ au même chemin relatif (QA-01)")
    return remarques


def preparer_action(projet: Path, but: str, type_action: str, fichiers: list[str], besoins: list[str],
                    situations: list[str] | None, vocab) -> str:
    """Réponse à une déclaration d'action : plan, chaîne à imiter, fichiers, fiches cochées."""
    fiches = charger()
    connus_b, connus_s = ids("besoin"), ids("situation")
    inconnus = [b for b in besoins if b not in connus_b] + [s for s in situations or [] if s not in connus_s]
    modele = MODELES.get(type_action)
    sortie = [f"# Action : {but}"]
    if inconnus:
        sortie += ["", f"Inconnus (ignorés) : {', '.join(inconnus)}. Besoins possibles : {', '.join(connus_b)}. "
                       f"Situations possibles : {', '.join(connus_s)}."]
    if modele is None:
        sortie += ["", f"Type d'action « {type_action} » inconnu. Types : {', '.join(MODELES)}, ou « autre »."]
    else:
        sortie += ["", f"Modèle : {modele['titre']}. Fichiers à créer ou modifier :"]
        sortie += [f"- {f}" for f in modele["fichiers"]]
        sortie += ["", "Chaîne à imiter :"]
        for res in modele["chaine"]:
            d = _disque(res, projet)
            ou = "absent" if d is None else ("dans le projet" if d.is_relative_to(Path(projet)) else "dans le socle de l'usine")
            sortie.append(f"- {res} ({ou})")
    if fichiers:
        sortie += ["", "Tes fichiers face au plan (ORGANISATION.md) :"] + verifier_fichiers(fichiers, modele, projet)
    choisis = [b for b in besoins if b in connus_b] + [s for s in situations or [] if s in connus_s]
    suggeres = [b for b in (modele or {}).get("besoins", []) if b not in choisis]
    if suggeres:
        sortie += ["", f"Besoins habituels de ce modèle, non cochés : {', '.join(suggeres)}"]
    signatures = Signatures(vocab)
    for i in dict.fromkeys(choisis):
        sortie += ["", rendre_fiche(fiches[i], signatures, projet)]
    return "\n".join(sortie)


__all__ = ["MODELES", "charger", "ids", "extraire_exemple", "rendre_fiche", "preparer_action", "signature_api"]
