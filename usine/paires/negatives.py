"""Paires négatives « symbole absent » (décision 24 de laurent, 2026-11-18 : des paires négatives, un symbole
inexistant et la bonne façon de faire).

Une ligne vérifiée d'un cours emploie un membre d'une classe de Godot dont le type est connu : un accès statique
(`Input.is_action_pressed`, `Vector3.UP`), une variable du fichier typée d'un type intégré (`var offset: Vector3`, puis
`offset.length()`), ou un membre de la classe dont hérite le script, écrit sans receveur (`velocity`,
`move_and_slide()`). Sur une variable typée d'une classe d'objet (`var body: Node3D`), Godot 4.7.2 ne signale rien à
l'analyse (un script pourrait ajouter le membre) : ces lignes sont laissées de côté.
Le membre est remplacé par un nom qui n'existe pas dans cette classe ni dans ses parents (API 4.7.2), de trois sortes,
celles qu'un modèle commet :

- `godot3` : le nom de Godot 3 de ce membre (`renames_map_3_to_4.cpp`, Godot 4.7.2), absent de la 4.7.2 ;
- `voisin` : un membre d'une classe voisine (2D et 3D, corps cinématique et corps rigide, Vector2 et Vector3…) qui
  partage un mot avec le bon, mais que la classe n'a pas (`linear_velocity` sur un CharacterBody3D) ;
- `invente` : un nom plausible venu d'autres moteurs ou langages (`is_action_held`, `magnitude`, `push`), absent.

La paire passe par la même machine que la famille « compilation » : Godot 4.7.2 analyse le script ; elle n'est
gardée que si Godot signale exactement cette ligne et rien d'autre, et si la ligne juste repasse l'analyse. La
réponse lit l'erreur, dit d'après l'API 4.7.2 que le membre n'existe pas (et où il existe, s'il existe ailleurs), donne
le membre juste avec sa signature et la première phrase de sa référence, corrige, et relance la commande.

    python -m usine.paires negatives [--cours kart] [--par-etape N] [--graine G] [--etapes 1,2]
"""

from __future__ import annotations

import json
import random
import re
from functools import lru_cache
from pathlib import Path
from typing import Any, Callable

from usine.paires import format as fmt

FAMILLE = "symbole_absent"
GENRE = "symbole_absent"
PLAFOND = 1024
SORTES = ("godot3", "voisin", "invente")

# Classes voisines : celles qu'un modèle confond (même rôle, autre dimension ou autre physique).
VOISINS: dict[str, tuple[str, ...]] = {
    "CharacterBody3D": ("RigidBody3D", "CharacterBody2D"), "RigidBody3D": ("CharacterBody3D", "RigidBody2D"),
    "CharacterBody2D": ("RigidBody2D", "CharacterBody3D"), "RigidBody2D": ("CharacterBody2D", "RigidBody3D"),
    "Area3D": ("Area2D", "RigidBody3D"), "Area2D": ("Area3D",), "Camera3D": ("Camera2D",), "Camera2D": ("Camera3D",),
    "Node3D": ("Node2D", "Control"), "Node2D": ("Node3D", "Control"), "Control": ("Node2D",),
    "Vector3": ("Vector2", "Basis"), "Vector2": ("Vector3",), "Transform3D": ("Transform2D", "Basis"),
    "Sprite3D": ("Sprite2D", "AnimatedSprite3D"), "Sprite2D": ("Sprite3D", "AnimatedSprite2D"),
    "AnimationPlayer": ("AnimationTree", "Tween"), "Tween": ("AnimationPlayer", "Tweener"),
    "RayCast3D": ("RayCast2D", "ShapeCast3D"), "RayCast2D": ("RayCast3D",), "Label": ("RichTextLabel", "Label3D"),
    "Timer": ("SceneTreeTimer",), "AudioStreamPlayer": ("AudioStreamPlayer3D",),
    "AudioStreamPlayer3D": ("AudioStreamPlayer",), "MeshInstance3D": ("MultiMeshInstance3D", "Sprite3D"),
    "Array": ("PackedStringArray", "Dictionary"), "Dictionary": ("Array",), "String": ("StringName", "Array"),
    "Input": ("InputEvent", "InputMap"), "Color": ("Vector3",), "Basis": ("Transform3D", "Quaternion"),
}
# Noms venus d'autres moteurs ou langages : un mot du bon nom → le mot qu'un modèle met à sa place.
SYNONYMES: dict[str, str] = {
    "pressed": "held", "released": "up", "normalized": "normalize", "length": "magnitude", "distance_to": "distance",
    "queue_free": "destroy", "add_child": "add_node", "get_children": "get_child_nodes", "instantiate": "spawn",
    "emit": "fire", "global_position": "world_position", "look_at": "look_towards", "move_toward": "move_towards",
    "is_on_floor": "is_grounded", "get_tree": "get_scene_tree", "size": "length", "append": "push", "has": "contains",
    "erase": "remove", "keys": "get_keys", "lerp": "interpolate", "clamp": "clamped", "angle_to": "angle_between",
    "set_process": "enable_process", "get_node": "find_node_by_path", "start": "begin", "wait_time": "duration",
    "text": "caption", "visible": "is_visible", "modulate": "tint", "play": "play_animation", "stop": "halt",
    "is_empty": "is_blank", "dot": "dot_product", "cross": "cross_product", "rotated": "rotate_by",
    "position": "location", "rotation": "orientation", "scale": "scaling", "velocity": "speed",
}
STATIQUE = re.compile(r"(?<![\w.$%])([A-Z][A-Za-z0-9_]*)\.([a-z_A-Z][A-Za-z0-9_]*)\b")
VAR_TYPEE = re.compile(r"\b(?:var|const)\s+(\w+)\s*:\s*([A-Z]\w*)\b|\b(\w+)\s*:\s*([A-Z]\w*)\s*[,)=]")
RECEVEUR = re.compile(r"(?<![\w.$%])([a-z_]\w*)\.([a-zA-Z_]\w*)\b")
EXTENDS = re.compile(r"^extends\s+([A-Z]\w*)\s*$", re.M)
DECLARE = re.compile(r"\b(?:func|var|const|signal|enum|class)\s+([A-Za-z_]\w*)")
NU = re.compile(r"(?<![\w.$%&^\"'])([a-z_][a-z0-9_]*)\b(?!\s*:(?!=))")


# Table des renommages lue par sorte de membre : un nom de Godot 3 ne vaut que pour la même sorte (`empty()` →
# `is_empty()` est une méthode ; `rect_size` → `size` est une propriété de Control, pas `Array.size()`).
TABLES_PAR_GENRE = {"méthode": "gdscript_function_renames", "propriété": "gdscript_properties_renames",
                    "signal": "gdscript_signals_renames", "constante": "enum_renames"}
# Préfixes de Godot 3 propres à une famille de classes.
PREFIXES_GODOT3 = {"rect_": ("Control",)}
# Noms de Godot 3 propres à une famille de classes (`extents` : les formes rectangulaires et les boîtes).
# Un renommage vers un nom que beaucoup de classes déclarent (`position`, `size`, `is_empty`) ne dit pas de quelle classe
# il venait : il n'est retenu que s'il figure ici, avec les classes de Godot 3 qu'il concernait (« intégrés » : Array,
# Dictionary, String et les tableaux compacts, qui avaient `empty()`).
NOMS_GODOT3 = {"extents": ("Shape2D", "Shape3D", "VisibleOnScreenNotifier3D", "ReflectionProbe", "GPUParticlesCollision3D"),
               "translation": ("Node3D",), "global_translation": ("Node3D",), "empty": ("intégrés",)}
DECLARANTS_MAX = 3


@lru_cache(maxsize=4)
def _renoms_inverses(genre: str) -> dict[str, list[str]]:
    """Nom de Godot 4 → noms de Godot 3 de la même sorte de membre, absents de la 4.7.2 (retenus par le filtre)."""
    from usine.paires.symboles import Filtre, _source_godot, lire_renommages
    absents = Filtre.charger().godot3
    table = _source_godot() / "editor/project_upgrade/renames_map_3_to_4.cpp"
    inverses: dict[str, list[str]] = {}
    for ancien, neuf in lire_renommages(table, (TABLES_PAR_GENRE[genre],)).items():
        if ancien in absents:
            inverses.setdefault(neuf, []).append(ancien)
    return inverses


@lru_cache(maxsize=None)
def _declarants(nom: str) -> int:
    """Le nombre de classes et de types intégrés qui déclarent eux-mêmes ce membre."""
    from usine.cours.base import api
    a = api._api()
    return sum(1 for c in list(a["classes"]) + list(a["builtins"]) if nom in _propres(c))


def _herite(classe: str, parent: str) -> bool:
    from usine.cours.base import api
    return parent in api._chaine(classe)


def _mots(nom: str) -> set[str]:
    return {m for m in nom.split("_") if m and m not in ("get", "set", "is", "has", "can")}


def _prefixe(nom: str) -> str:
    tete = nom.split("_", 1)[0]
    return tete if tete in ("get", "set", "is", "has", "can") else ""


def _genre(classe: str, nom: str) -> str:
    """« méthode », « signal », « propriété » ou « constante », d'après la signature de l'API."""
    from usine.cours.base import api
    r = api.membre(classe, nom)
    if r is None:
        return ""
    sig = r[0]
    if sig.startswith("signal "):
        return "signal"
    if "(" in sig:
        return "méthode"
    if ": " in sig:
        return "propriété"
    return "constante"


def _propres(classe: str) -> set[str]:
    """Les membres déclarés par la classe elle-même (ni ses parents)."""
    from usine.cours.base import api
    a = api._api()
    info = a["classes"].get(classe) or a["builtins"].get(classe) or {}
    noms: set[str] = set()
    for cle in ("methods", "properties", "members", "signals", "constants"):
        noms |= {m["name"] for m in info.get(cle) or []}
    return noms


def faux_noms(classe: str, membre: str, interdits: set[str]) -> list[tuple[str, str, str | None]]:
    """(faux nom, sorte, classe où il existe) : absents de `classe` et de ses parents, et des noms du fichier."""
    from usine.cours.base import api
    if api.membre(classe, membre) is None:
        return []
    sortie: list[tuple[str, str, str | None]] = []

    def garder(faux: str, sorte: str, ou: str | None) -> None:
        if faux != membre and faux not in interdits and api.membre(classe, faux) is None \
                and re.fullmatch(r"[A-Za-z_]\w*", faux) and all(f != faux for f, _, _ in sortie):
            sortie.append((faux, sorte, ou))

    genre = _genre(classe, membre)
    for ancien in sorted(_renoms_inverses(genre).get(membre, []) if genre in TABLES_PAR_GENRE else []):
        prefixe = next((cs for p, cs in PREFIXES_GODOT3.items() if ancien.startswith(p)), None)
        if prefixe is not None:
            permis = any(_herite(classe, c) for c in prefixe)
        elif ancien in NOMS_GODOT3:
            permis = any(_herite(classe, c) or (c == "intégrés" and classe in api._api()["builtins"])
                         for c in NOMS_GODOT3[ancien])
        else:
            permis = _declarants(membre) <= DECLARANTS_MAX
        if permis:
            garder(ancien, "godot3", None)
    mots = _mots(membre)
    for voisine in VOISINS.get(classe, ()):
        if not api.classe_existe(voisine):
            continue
        for autre in sorted(_propres(voisine)):
            communs = mots & _mots(autre)
            # Même sorte de membre, même préfixe (get_, set_, is_…), au moins la moitié des mots en commun, et l'un
            # des deux noms contient l'autre : `velocity` → `linear_velocity`, `inverse` → `affine_inverse` ; pas
            # `global_basis` → `get_global_rect`.
            contient = re.search(rf"(^|_){re.escape(membre)}(_|$)", autre) or re.search(rf"(^|_){re.escape(autre)}(_|$)", membre)
            if communs and len(communs) * 2 >= len(mots | _mots(autre)) and contient and not autre.startswith("_") \
                    and _prefixe(autre) == _prefixe(membre) and api.membre(voisine, autre) \
                    and _genre(voisine, autre) == genre:
                garder(autre, "voisin", voisine)
    for juste, faux in SYNONYMES.items():
        if membre == juste:
            garder(faux, "invente", None)
        elif re.search(rf"(^|_){juste}(_|$)", membre):
            garder(re.sub(rf"(^|_){juste}(_|$)", rf"\g<1>{faux}\g<2>", membre, count=1), "invente", None)
    return sortie


def candidates(rel: str, texte: str, rng: random.Random) -> list[Any]:
    """Une mutation au plus par ligne, la sorte tirée parmi celles qui existent pour ce membre."""
    from usine.cours.base import api
    from usine.cours.base.mutations import Mutation
    if not rel.endswith(".gd"):
        return []
    interdits = set(DECLARE.findall(texte))
    types: dict[str, str] = {}
    for a, b, c, d in VAR_TYPEE.findall(texte):
        nom, t = (a, b) if a else (c, d)
        if api.classe_existe(t):
            types.setdefault(nom, t)
    m = EXTENDS.search(texte)
    base = m.group(1) if m and api.classe_existe(m.group(1)) else None
    sortie = []
    for n, ligne in enumerate(texte.split("\n"), start=1):
        if ligne.lstrip().startswith(("#", "func ", "static func ", "@", "class_name", "extends", "signal ", "const ")):
            continue
        code = ligne.split("#", 1)[0]
        if '"' in code or "'" in code:
            # Les chaînes compliquent le remplacement sûr : la ligne est laissée de côté.
            continue
        acces: list[tuple[str, str, str, int, int]] = []    # (classe, membre, forme, début, fin du membre)
        for x in STATIQUE.finditer(code):
            if api.classe_existe(x.group(1)):
                acces.append((x.group(1), x.group(2), "statique", x.start(2), x.end(2)))
        for x in RECEVEUR.finditer(code):
            # Sur une variable typée d'une classe d'objet (`_visual: Node3D`), Godot 4.7.2 ne signale pas un membre
            # absent à l'analyse : un script pourrait l'ajouter (mesuré le 2026-11-19 sur le kart, étape 6). Seuls les
            # types intégrés (Vector3, Array, String…), qu'aucun script n'étend, le font.
            if types.get(x.group(1)) in api._api()["builtins"]:
                acces.append((types[x.group(1)], x.group(2), f"variable `{x.group(1)}`", x.start(2), x.end(2)))
        if base:
            for x in NU.finditer(code):
                nom = x.group(1)
                if nom in interdits or nom in types or nom in ("self", "super", "not", "and", "or", "in", "if",
                                                                "else", "elif", "for", "while", "return", "var",
                                                                "true", "false", "null", "pass", "is", "as", "match"):
                    continue
                if api.membre(base, nom) and not api.utilitaire(nom):
                    acces.append((base, nom, "hérité", x.start(1), x.end(1)))
        rng.shuffle(acces)
        for classe, membre, forme, debut, fin in acces:
            faux = faux_noms(classe, membre, interdits)
            if not faux:
                continue
            sorte = rng.choice(sorted({s for _, s, _ in faux}))
            nom, sorte, ou = rng.choice([f for f in faux if f[1] == sorte])
            apres = ligne[:debut] + nom + ligne[fin:]
            sortie.append(Mutation(GENRE, rel, n, ligne, apres,
                                   {"classe": classe, "juste": membre, "faux": nom, "sorte": sorte, "ou": ou,
                                    "forme": forme}))
            break
    return sortie


def explication(m: Any) -> list[str]:
    """« Chercher » : ce que dit l'API 4.7.2 du nom fautif et du nom juste (signatures et référence relues)."""
    from usine.cours.base import api, preuves
    d = m.detail
    classe, juste, faux = d["classe"], d["juste"], d["faux"]
    sig, origine = api.membre(classe, juste)
    if d["forme"] == "hérité":
        lieu = f"Le script hérite de `{classe}`, qui n'a pas de membre `{faux}`"
    elif d["forme"] == "statique":
        lieu = f"`{classe}` n'a pas de membre `{faux}`"
    else:
        lieu = f"La {d['forme']} est un `{classe}`, qui n'a pas de membre `{faux}`"
    lignes = [lieu + " dans l'API de Godot 4.7.2, ni dans ses classes parentes."]
    if d["sorte"] == "godot3":
        table = preuves.renommage_de(faux)
        lignes[0] += f" `{faux}` est le nom de Godot 3 ; le nom actuel est `{juste}`."
        if table:
            lignes.append(f"- {preuves.SOURCE_RENOMS} : `{table[0]}`.")
    elif d["sorte"] == "voisin":
        ailleurs = api.membre(d["ou"], faux)
        lignes[0] += (f" `{faux}` appartient à `{d['ou']}`" + (f" (`{ailleurs[0]}`)" if ailleurs else "")
                      + f", pas à `{classe}`.")
    else:
        partout = not any(api.membre(c, faux) for c in api._api()["classes"]) and not any(
            api.membre(c, faux) for c in api._api()["builtins"])
        if partout:
            lignes[0] += f" Aucune classe de Godot 4.7.2 n'a de `{faux}` : c'est un nom d'un autre moteur ou d'un autre langage."
    description = api.description_membre(origine, juste)
    lignes.append(f"- Ce que `{classe}` offre pour cela : `{sig}`" + (f" — « {description} »" if description else "."))
    return lignes


def motif(m: Any) -> str:
    return rf"\b{re.escape(m.detail['faux'])}\b"


def generer(cours: str = "kart", par_etape: int = 8, graine: int = 1, etapes: list[int] | None = None,
            donnees: Path | None = None, journal: Callable[[str], None] = print) -> dict[str, Any]:
    """`par_etape` fautes par étape, les sortes à tour de rôle (graine fixe) ; une faute gardée ne revient pas."""
    from usine.cours.base import assembler, chemins, creation, sessions
    from usine.paires.compilation import fichiers_a_fauter, paire
    from usine.paires.execution import _sujet as sujet_fichier
    chemins.configurer(cours=cours)
    sortie = fmt.dossier(FAMILLE, donnees)
    rng = random.Random(graine)
    paires: list[dict[str, Any]] = []
    rejets: list[str] = []
    vues: set[tuple[str, str]] = set()
    for ville in assembler.ordre_lignes():
        for n in etapes or list(assembler.etapes_du_cours()):
            _, apres = creation.etats(ville, n)
            dispo = [x for rel in fichiers_a_fauter(apres, "compilation") for x in candidates(rel, apres[rel], rng)
                     if (fmt.commun(x.avant), x.detail["faux"]) not in vues]
            if not dispo:
                continue
            par_sorte: dict[str, list[Any]] = {}
            for x in dispo:
                par_sorte.setdefault(x.detail["sorte"], []).append(x)
            choisies: list[Any] = []
            while len(choisies) < par_etape and any(par_sorte.values()):
                for s in SORTES:
                    if par_sorte.get(s) and len(choisies) < par_etape:
                        choisies.append(par_sorte[s].pop(rng.randrange(len(par_sorte[s]))))
            projet = sessions.Projet(ville, n, apres)
            gardees = 0
            for x in choisies:
                p, raison = paire(projet, x, sujet_fichier(ville, n, x.fichier), FAMILLE)
                if p is None:
                    rejets.append(f"{ville}-{n:03d} {x.fichier}:{x.ligne} {x.detail['sorte']} {x.detail['faux']} : {raison}")
                    continue
                p["preuve"].update({k: x.detail[k] for k in ("classe", "juste", "faux", "sorte", "ou")})
                paires.append(p)
                vues.add((fmt.commun(x.avant), x.detail["faux"]))
                gardees += 1
            journal(f"{ville}-{n:03d} : {gardees}/{len(choisies)} paires")
    retenues = [p for p in paires if p["jetons"] <= PLAFOND]
    fmt.ecrire(retenues, sortie / f"paires_{cours}.jsonl")
    bilan: dict[str, Any] = {"famille": FAMILLE, "cours": cours, "paires": len(retenues),
                             "trop_longues": len(paires) - len(retenues), "rejets": rejets, "par_sorte": {},
                             "par_sujet": {}, "jetons_max": max((p["jetons"] for p in retenues), default=0)}
    for p in retenues:
        bilan["par_sorte"][p["preuve"]["sorte"]] = bilan["par_sorte"].get(p["preuve"]["sorte"], 0) + 1
        bilan["par_sujet"][p["sujet"]] = bilan["par_sujet"].get(p["sujet"], 0) + 1
    (sortie / f"bilan_{cours}.json").write_text(json.dumps(bilan, indent=1, ensure_ascii=False), encoding="utf-8")
    return bilan
