"""Famille de paires « erreur à l'exécution → correction » (étape B3 du suivi).

Une faute qui passe l'analyse du script (`--check-only` strict : rien à signaler) mais casse à l'exécution, posée dans
le code vérifié des cours de jeu (kart, roguelike) :

- `chemin_noeud` : le chemin d'un `$…` ou d'un `get_node("…")` ne mène à aucun nœud de la scène (parent oublié, nom
  écrit avec une minuscule, nom du type à la place du nom du nœud) ; Godot écrit « Node not found », la variable
  reste `null` et les lignes qui l'emploient plantent ensuite ;
- `type_noeud` : une variable `@onready` déclare un type qui n'est pas celui du nœud de la scène (2D pour 3D,
  `RichTextLabel` pour `Label`…) ; l'affectation échoue et la variable reste vide.

La suite GdUnit4 qui charge le script montre la panne. La leçon : la ligne qui plante n'est pas celle à corriger ;
la pile d'appels de GDScript donne la ligne d'origine, la scène donne le bon chemin ou le bon type.

Une paire n'est gardée que si l'analyse est propre avec la faute, si la première erreur de la sortie vient de la
ligne fautive, et si la même suite passe une fois la ligne corrigée. Demande : la sortie réelle de la suite, le
passage du script, le nœud cherché dans sa scène (vrai `grep`). Réponse : « Lire », « Chercher », « Corriger », puis
la commande à relancer (sa sortie n'est pas écrite, règle 7.2).

Palier de 2 048 jetons, avec le plan en message système (décision 19.1) : la vraie sortie d'une suite, le passage et
la scène pèsent 1 300 à 2 000 jetons à eux seuls (essai du kart, 2026-10-27), aucune ne tenait sous 1 024.

    python -m usine.paires execution [--cours kart] [--par-etape N] [--graine G] [--etapes 1,2]
"""

from __future__ import annotations

import json
import random
import re
import shutil
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable

from usine.paires import format as fmt

PLAFOND = 2048
GENRES = ("chemin_noeud", "type_noeud")
RAYON = 3  # lignes de code montrées autour de chaque ligne citée

NOEUD = re.compile(r'^\[node name="([^"]+)"([^\]]*)\]')
REF = re.compile(r'\$"([^"]+)"|\$([A-Za-z_][\w/]*)|get_node\("([^"]+)"\)')
ONREADY_TYPE = re.compile(r'^(\s*@onready var (\w+): )(\w+)( = )(\$"[^"]+"|\$[A-Za-z_][\w/]*|get_node\("[^"]+"\))\s*$')
VARIABLE = re.compile(r"^\s*(?:@onready\s+)?var (\w+)\b")
PILE_0 = re.compile(r"^\s*\[0\] (\S+) \(res://([^():]+):(\d+)\)\s*$")
AT_MOTEUR = re.compile(r"^\s*at: \S+ \(([^()]+\.(?:cpp|h)):\d+\)\s*$")

# Types qu'un modèle confond (2D et 3D, nœuds voisins) ; la confusion n'est gardée que si le faux type n'est pas dans
# la lignée du vrai (sinon l'affectation passe) : vérifié dans extension_api.json, puis par l'exécution.
CONFUSIONS = {
    "Node3D": "Node2D", "Node2D": "Node3D", "Control": "Node2D", "MeshInstance3D": "Sprite3D",
    "Sprite3D": "MeshInstance3D", "Sprite2D": "TextureRect", "TextureRect": "Sprite2D", "Label": "RichTextLabel",
    "RichTextLabel": "Label", "Button": "TextureButton", "TextureButton": "Button", "ProgressBar": "TextureProgressBar",
    "TextureProgressBar": "ProgressBar", "RayCast3D": "ShapeCast3D", "ShapeCast3D": "RayCast3D",
    "GPUParticles3D": "CPUParticles3D", "CPUParticles3D": "GPUParticles3D", "GPUParticles2D": "CPUParticles2D",
    "CPUParticles2D": "GPUParticles2D", "Area3D": "Area2D", "Area2D": "Area3D", "CharacterBody3D": "CharacterBody2D",
    "CharacterBody2D": "CharacterBody3D", "RigidBody3D": "RigidBody2D", "StaticBody3D": "StaticBody2D",
    "Camera3D": "Camera2D", "Camera2D": "Camera3D", "AnimationPlayer": "AnimationTree",
    "AnimationTree": "AnimationPlayer", "AnimatedSprite2D": "Sprite2D", "AudioStreamPlayer3D": "AudioStreamPlayer",
    "AudioStreamPlayer": "AudioStreamPlayer2D", "AudioStreamPlayer2D": "AudioStreamPlayer3D", "Marker3D": "Marker2D",
    "Marker2D": "Marker3D", "OmniLight3D": "SpotLight3D", "SpotLight3D": "OmniLight3D",
    "DirectionalLight3D": "OmniLight3D", "VBoxContainer": "HBoxContainer", "HBoxContainer": "VBoxContainer",
    "PanelContainer": "Panel", "Panel": "PanelContainer", "CollisionShape3D": "CollisionShape2D",
    "MultiMeshInstance3D": "MeshInstance3D", "Path3D": "Path2D", "PathFollow3D": "PathFollow2D",
    "NavigationAgent3D": "NavigationAgent2D", "Line2D": "Polygon2D", "ColorRect": "TextureRect",
    "LineEdit": "TextEdit", "TextEdit": "LineEdit", "CheckBox": "CheckButton", "CheckButton": "CheckBox",
    "HSlider": "VSlider", "VSlider": "HSlider", "ItemList": "Tree", "Tree": "ItemList",
    "GridContainer": "VBoxContainer", "MarginContainer": "PanelContainer", "Timer": "AnimationPlayer",
    "Decal": "MeshInstance3D", "VisibleOnScreenNotifier3D": "VisibleOnScreenNotifier2D",
}


# --------------------------------------------------------------------------------------------- les scènes
@dataclass
class Noeud:
    nom: str
    type: str
    chemin: str         # depuis la racine de la scène ; "" pour la racine
    ligne: int          # ligne de son en-tête `[node …]` dans le fichier
    entete: str
    script: str | None  # chemin relatif du script porté, s'il y en a un
    instance: bool


def _attribut(entete: str, nom: str) -> str | None:
    m = re.search(rf'\b{nom}="([^"]*)"', entete)
    return m[1] if m else None


def noeuds(texte: str) -> list[Noeud]:
    """Les nœuds d'un `.tscn`, avec le script de chacun."""
    scripts: dict[str, str] = {}
    sortie: list[Noeud] = []
    courant: Noeud | None = None
    for i, l in enumerate(texte.split("\n"), 1):
        if l.startswith("[ext_resource") and 'type="Script"' in l:
            chemin, ident = _attribut(l, "path"), _attribut(l, "id")
            if chemin and ident and chemin.startswith("res://"):
                scripts[ident] = chemin[len("res://"):]
            continue
        m = NOEUD.match(l)
        if m:
            parent = _attribut(m[2], "parent")
            chemin = "" if parent is None else (m[1] if parent == "." else f"{parent}/{m[1]}")
            courant = Noeud(m[1], _attribut(m[2], "type") or "", chemin, i, l, None, "instance=" in m[2])
            sortie.append(courant)
        elif l.startswith("["):
            courant = None
        elif courant is not None:
            s = re.match(r'^script = ExtResource\("([^"]+)"\)', l)
            if s:
                courant.script = scripts.get(s[1])
    return sortie


def relatif(porteur: Noeud, cible: Noeud) -> str | None:
    """Le chemin de `cible` vu depuis `porteur`, s'il en descend."""
    if porteur.chemin == "":
        return cible.chemin or None
    prefixe = porteur.chemin + "/"
    return cible.chemin[len(prefixe):] if cible.chemin.startswith(prefixe) else None


def scenes_du_script(apres: dict[str, str], rel: str) -> list[tuple[str, Noeud, list[Noeud]]]:
    """(scène, nœud qui porte le script, nœuds de la scène) pour chaque scène qui attache `rel`."""
    sortie = []
    for srel, t in sorted(apres.items()):
        if not srel.endswith(".tscn") or f'"res://{rel}"' not in t:
            continue
        ns = noeuds(t)
        sortie += [(srel, n, ns) for n in ns if n.script == rel and not n.instance]
    return sortie


# --------------------------------------------------------------------------------------------- les fautes
def _ecrire_chemin(ref: re.Match, chemin: str) -> str:
    if ref[1] is not None:
        return f'$"{chemin}"'
    if ref[2] is not None:
        return f"${chemin}"
    return f'get_node("{chemin}")'


def _plat(nom: str) -> str:
    return nom.replace("_", "").lower()


def designe(cible: Noeud, scene: list[Noeud], variable: str | None) -> bool:
    """Le nœud se retrouve sans ambiguïté parmi ceux de son type : il est le seul de ce type dans la scène, ou la
    variable porte son nom (`water_ripples` pour `WaterRipples`)."""
    meme_type = [n for n in scene if n.type == cible.type]
    return len(meme_type) == 1 or (variable is not None and _plat(variable) == _plat(cible.nom))


def variantes(chemin: str, cible: Noeud, tous: dict[str, Noeud], scene: list[Noeud] | None = None,
              variable: str | None = None) -> list[tuple[str, str]]:
    """(variante, chemin faux) qui ne mènent à aucun nœud ; `tous` : chemin relatif → nœud, depuis le porteur."""
    morceaux = chemin.split("/")
    sortie = []
    if len(morceaux) >= 2:
        sortie.append(("segment", "/".join(morceaux[:-2] + morceaux[-1:])))
    if cible.type and cible.type != morceaux[-1] and re.fullmatch(r"[A-Za-z_]\w*", cible.type) \
            and designe(cible, scene or [cible], variable):
        sortie.append(("nom_par_defaut", "/".join(morceaux[:-1] + [cible.type])))
    if morceaux[-1][:1].isupper():
        sortie.append(("casse", "/".join(morceaux[:-1] + [morceaux[-1][0].lower() + morceaux[-1][1:]])))
    return [(v, f) for v, f in sortie if f not in tous and f != chemin]


def candidates(apres: dict[str, str], rel: str) -> list[Any]:
    """Toutes les fautes d'exécution possibles dans le script `rel`."""
    from usine.cours.base import api, mutations
    texte = apres[rel]
    scenes = scenes_du_script(apres, rel)
    if not scenes:
        return []
    sortie: list[Any] = []
    for i, l in enumerate(texte.split("\n"), 1):
        code = l.split("#", 1)[0]
        if not code.strip():
            continue
        ref = REF.search(code)
        if not ref:
            continue
        chemin = next(g for g in ref.groups() if g is not None)
        if chemin.startswith(("/", "..", "%")) or "%" in chemin:
            continue
        trouve = None
        for srel, porteur, ns in scenes:
            tous = {r: n for n in ns if (r := relatif(porteur, n))}
            if chemin in tous:
                trouve = (srel, porteur, tous)
                break
        if trouve is None:
            continue
        srel, porteur, tous = trouve
        cible = tous[chemin]
        commun = {"chemin": chemin, "scene": srel, "ligne_scene": cible.ligne, "entete": cible.entete,
                  "plusieurs": sum(1 for n in next(ns for s, _, ns in scenes if s == srel) if n.type == cible.type) > 1,
                  "porteur": porteur.nom, "racine": porteur.chemin == "", "nom": cible.nom, "type": cible.type,
                  "variable": (VARIABLE.match(l) or [None, None])[1], "forme": "get_node" if ref[3] else "$"}
        scene = next(ns for s, _, ns in scenes if s == srel)
        for v, faux in variantes(chemin, cible, tous, scene, commun["variable"]):
            fautive = l[:ref.start()] + _ecrire_chemin(ref, faux) + l[ref.end():]
            sortie.append(mutations.Mutation("chemin_noeud", rel, i, l, fautive, dict(commun, faux=faux, variante=v)))
        t = ONREADY_TYPE.match(l)
        if t and t[3] == cible.type:
            faux = CONFUSIONS.get(cible.type)
            if faux and api.classe_existe(faux) and faux not in api._chaine(cible.type):
                fautive = t[1] + faux + t[4] + t[5]
                sortie.append(mutations.Mutation("type_noeud", rel, i, l, fautive,
                                                 dict(commun, faux=faux, lignee=api._chaine(cible.type))))
    return sortie


# --------------------------------------------------------------------------------------------- la sortie
@dataclass
class Erreur:
    message: str
    fichier: str
    ligne: int
    fonction: str
    moteur: str | None  # fichier du moteur de la ligne « at: », quand elle ne cite pas le projet
    pile: str | None    # la ligne « [0] … » de la pile d'appels de GDScript


def _localiser(message: str, suivantes: list[str]) -> Erreur | None:
    """Le lieu d'une erreur : sa ligne « at: » quand elle cite le projet, sinon la ligne [0] de la pile de GDScript."""
    from usine.cours.base import sessions
    moteur = None
    for suite in suivantes:
        if sessions.MESSAGE.match(suite):
            break
        at = sessions.AT.match(suite)
        if at:
            fonction = re.search(r"at: (?:\w+\.)?(\S+) \(", suite)
            return Erreur(message.strip(), at[1], int(at[2]), fonction[1] if fonction else "", None, None)
        m = AT_MOTEUR.match(suite)
        if m:
            moteur = m[1]
        p = PILE_0.match(suite)
        if p:
            return Erreur(message.strip(), p[2], int(p[3]), p[1], moteur, suite.strip())
    return None


def _blocs(texte: str) -> list[tuple[str, list[str]]]:
    """(ligne d'erreur, lignes qui la suivent) pour chaque erreur de la sortie, hors erreurs bénignes du moteur."""
    from usine.cours.base import profil, sessions
    lignes = texte.splitlines()
    benignes = profil.lignes_benignes(texte)
    return [(l, lignes[i + 1:i + 8]) for i, l in enumerate(lignes)
            if i not in benignes and sessions.MESSAGE.match(l) and not l.startswith(("WARNING", "SCRIPT WARNING"))]


def premiere_erreur(texte: str) -> Erreur | None:
    """Le lieu de la première erreur de la sortie (None si elle ne désigne aucune ligne du projet)."""
    blocs = _blocs(texte)
    return _localiser(*blocs[0]) if blocs else None


def consequences(texte: str, m: Any) -> list[tuple[str, int, str]]:
    """Les autres lignes du projet que la sortie accuse, dans l'ordre et une fois chacune : ce que la faute entraîne
    (les extensions, GdUnit4 compris, ne comptent pas)."""
    sortie: dict[tuple[str, int], str] = {}
    for message, suivantes in _blocs(texte):
        e = _localiser(message, suivantes)
        if e and not e.fichier.startswith("addons/") and (e.fichier, e.ligne) != (m.fichier, m.ligne):
            sortie.setdefault((e.fichier, e.ligne), e.message)
    return [(f, n, msg) for (f, n), msg in sortie.items()]


def message_attendu(m: Any, e: Erreur) -> bool:
    d = m.detail
    if m.genre == "chemin_noeud":
        return e.message.startswith("ERROR: Node not found:") and f'"{d["faux"]}"' in e.message
    return f"Trying to assign value of type '{d['type']}' to a variable of type '{d['faux']}'" in e.message


# --------------------------------------------------------------------------------------------- les suites
def suites_pour(apres: dict[str, str], rel: str) -> list[str]:
    """Les suites qui chargent le script : celle du chemin miroir d'abord, puis celles qui nomment sa classe, sa
    scène ou une scène qui l'instancie ; les plus courtes d'abord."""
    from usine.cours.base import profil
    p = Path(rel)
    miroir = f"7_tests/{p.parent.as_posix()}/test_{p.stem}.gd"
    cles = {f"res://{rel}"}
    classe = profil.CLASSE.search(apres[rel])
    if classe:
        cles.add(classe[1])
    scenes = {s for s, _, _ in scenes_du_script(apres, rel)}
    cles |= {f"res://{s}" for s in scenes}
    cles |= {f"res://{s}" for s, t in apres.items() if s.endswith(".tscn") and any(f'"res://{x}"' in t for x in scenes)}
    trouvees = [s for s in profil.suites(apres) if s == miroir or any(k in apres[s] for k in cles)]
    return sorted(trouvees, key=lambda s: (s != miroir, len(apres[s])))


# --------------------------------------------------------------------------------------------- la paire
def _citer(texte: str) -> str:
    return texte if len(texte) <= 110 else texte[:107] + "…"


def lire(m: Any, s: Any, e: Erreur, suite: list[tuple[str, int, str]], mode: str = "tests") -> str:
    d = m.detail
    if s.code != 0:
        r = (f"**Lire l'erreur.** Le test échoue (code de sortie {s.code})." if mode == "tests" else
             f"**Lire l'erreur.** La scène s'arrête sur une erreur (code de sortie {s.code}).")
    elif mode == "tests":
        r = ("**Lire l'erreur.** Le code de sortie est 0, mais la sortie contient une erreur du jeu : GdUnit4 ne fait "
             "échouer un cas que sur ses assertions, il faut lire chaque ligne.")
    else:
        r = ("**Lire l'erreur.** Le code de sortie est 0 : la scène se lance quand même, mais la sortie contient des "
             "erreurs, il faut lire chaque ligne.")
    r += f" La première erreur : « {e.message} »"
    origine = ("l'initialisation des variables `@onready`" if e.fonction == "@implicit_ready" else
               f"la fonction `{e.fonction}`")
    if e.pile:
        r += (f" Sa ligne « at: » désigne le moteur (`{e.moteur}`), pas le projet ; la pile d'appels de GDScript donne "
              f"l'origine : `{e.pile}`, {origine}, ligne {m.ligne}.")
    else:
        r += f" Elle vient de {origine} de `res://{m.fichier}`, ligne {m.ligne}."
    if suite:
        f, n, msg = suite[0]
        ou = f"ligne {n}" if f == m.fichier else f"`res://{f}` ligne {n}"
        if m.genre == "chemin_noeud":
            vide = (f"`{d['variable']}` est restée `null`" if d["variable"] else "l'appel porte sur `null`")
            r += (f" Les erreurs qui suivent ({ou} : « {_citer(msg)} ») en découlent : `get_node` n'a rien trouvé, "
                  f"{vide}.")
        else:
            r += (f" L'affectation a échoué, `{d['variable']}` est restée vide : les erreurs qui suivent ({ou} : "
                  f"« {_citer(msg)} ») en découlent.")
        r += (f" C'est la ligne {m.ligne} qu'il faut corriger, pas la {ou} : y tester la variable cacherait la panne "
              "sans la réparer.")
    return r


def chercher(m: Any) -> list[str]:
    from usine.cours.base import preuves
    d = m.detail
    ou = f"racine de `res://{d['scene']}`" if d["racine"] else f"dans `res://{d['scene']}`"
    noeud = f"(ligne {d['ligne_scene']} : `{d['entete']}`)"
    if m.genre == "type_noeud":
        return ["**Chercher.**",
                f"Dans `res://{d['scene']}`, `{d['nom']}` est un `{d['type']}` {noeud}.",
                f"Lignée de `{d['type']}` dans l'API de Godot 4.7.2 : " + " → ".join(f"`{c}`" for c in d["lignee"])
                + f". `{d['faux']}` n'y est pas : un `{d['type']}` ne peut pas aller dans une variable `{d['faux']}`.",
                f"Le type déclaré doit être celui du nœud : `{d['type']}`."]
    r = ["**Chercher.**",
         ("`$` abrège `get_node`. " if d["forme"] == "$" else "") + preuves.citation_reference(preuves.REF_GET_NODE),
         f"Le chemin se lit depuis le nœud qui porte le script, `{d['porteur']}`, {ou}."]
    v, faux, chemin = d["variante"], d["faux"], d["chemin"]
    if v == "segment":
        parent = chemin.rsplit("/", 1)[0]
        oublie = parent.rsplit("/", 1)[-1]
        r.append(f"Dans cette scène, `{d['nom']}` est sous `{parent}` {noeud} : depuis `{d['porteur']}`, son chemin "
                 f"est `{chemin}`. `{faux}` ne mène à aucun nœud : il manque `{oublie}`.")
    elif v == "casse":
        r.append(f"La scène n'a aucun nœud `{faux.rsplit('/', 1)[-1]}` : le nœud s'appelle `{d['nom']}`, avec une "
                 f"majuscule {noeud}. Le chemin reprend le nom exact : `{chemin}`.")
    else:
        r.append(f"La scène n'a aucun nœud nommé `{d['type']}` : `{d['type']}` est le type du nœud, son nom est "
                 f"`{d['nom']}` {noeud}. Le chemin suit les noms, pas les types : `{chemin}`.")
        if d.get("plusieurs") and d["variable"]:
            r.append(f"Parmi les nœuds de type `{d['type']}`, celui que désigne la variable `{d['variable']}` est "
                     f"`{d['nom']}`.")
    return r


def recherche(m: Any) -> tuple[list[str], str]:
    """(arguments de grep, commande affichée) : chercher dans la scène le nœud que le script voulait. On cherche le
    nom qu'on connaît : celui du chemin (sans tenir compte de la casse quand c'est elle qui est en cause), le type
    quand le chemin donnait un type. Le point tient la place du guillemet : sous Windows, un guillemet dans un
    argument n'arrive pas intact au grep de Git for Windows (mesuré : aucune ligne trouvée, ou code 1536)."""
    d = m.detail
    scene = d["scene"]
    if m.genre == "chemin_noeud" and d["variante"] == "casse":
        motif = f'name=.{d["faux"].rsplit("/", 1)[-1]}.'
        return ["-ni", motif, scene], f"grep -ni '{motif}' {scene}"
    if m.genre == "chemin_noeud" and d["variante"] == "nom_par_defaut":
        motif = f'type=.{d["type"]}.'
        return ["-n", motif, scene], f"grep -n '{motif}' {scene}"
    motif = f'name=.{d["nom"]}.'
    return ["-n", motif, scene], f"grep -n '{motif}' {scene}"


def _grep(projet: Any, m: Any) -> str:
    from usine.processus import executer
    grep = shutil.which("grep")
    if grep is None:
        raise RuntimeError("grep introuvable (sous Windows, ajouter le dossier usr\\bin de Git for Windows au PATH)")
    args, commande = recherche(m)
    res = executer([grep, *args], cwd=projet.chemin, delai_s=60)
    if res.code != 0 or f"{m.detail['ligne_scene']}:" not in res.sortie:
        raise RuntimeError(f"la recherche ne trouve pas le nœud : {commande} → {res.sortie.strip()[:200]}")
    return f"```\n$ {commande}\n{res.sortie.strip()}\n```"


# Le bandeau de GdUnit4, avant la première suite : des lignes d'information (règle 5.1), retirées des paires courtes.
BANDEAU = ("-----", "GdUnit4 Comandline Tool", "Disabled fail fast!", "Set report history count to ",
           "Set write reports to ", "Headless mode is ignored by option ", "Please note that tests that use UI ",
           "Godot 'InputEvents' are not transported ", "have no effect in the test!", "Installing GdUnit4 session ",
           "Session hook '")


# Après le résumé, d'autres lignes d'information : chemins des rapports, durées, nettoyage (règle 5.1). Le résumé
# (« Statistics », « Overall Summary ») et « Exit code » restent.
INFORMATION = ("Executed test suites:", "Executed test cases :", "Total execution time:", " Open XML Report at:",
               "Open HTML Report at:", "Run dispose test resources")


def sans_bandeau(texte: str) -> str:
    lignes = texte.splitlines()
    debut = next((i for i, l in enumerate(lignes) if l.startswith("Run Test Suite:")), 0)
    if all(l.startswith(BANDEAU) for l in lignes[:debut]):
        lignes = lignes[debut:]
    return "\n".join(l for l in lignes if not l.startswith(INFORMATION))


DEBUT_CAS = re.compile(r"^\s*res://\S+ > (\w+) STARTED\b")
CAS_ECARTES_MAX = 5  # au-delà, la commande s'allonge plus que la sortie ne raccourcit


def cas_de_la_premiere_erreur(texte: str) -> tuple[str | None, list[str]]:
    """(cas en cours à la première erreur, tous les autres cas de la suite), lus dans les lignes « STARTED » ; les
    erreurs bénignes du moteur ne comptent pas."""
    from usine.cours.base import profil, sessions
    benignes = profil.lignes_benignes(texte)
    tous: list[str] = []
    cas = None
    for i, l in enumerate(texte.splitlines()):
        d = DEBUT_CAS.match(l)
        if d:
            if d[1] not in tous:
                tous.append(d[1])
            continue
        if cas is None and tous and i not in benignes and sessions.MESSAGE.match(l) \
                and not l.startswith(("WARNING", "SCRIPT WARNING")):
            cas = tous[-1]
    return cas, [c for c in tous if c != cas]


def bloc_court(s: Any) -> str:
    """La sortie d'une suite pour une paire courte : sans le bandeau, chaque erreur répétée montrée une fois, la pile
    d'appels réduite à sa première ligne, celle qui cite le script (les mêmes marques « [...] » que les sessions des
    cours)."""
    from usine.cours.base import debogage
    corps = debogage.compacter(sans_bandeau(s.texte), garder=1, pile=1).strip()
    return f"```\n$ {s.commande}\n{corps}\n(code de sortie : {s.code})\n```"


def _par_les_tests(projet: Any, m: Any, suites: list[str], juste: Callable[[Any], bool]) -> tuple[Any, Any, str, str,
                                                                                                    list[str]] | None:
    """(sortie, erreur, suite, cas, cas écartés) : le cas où l'erreur paraît, lancé seul (les autres écartés par
    `-i`, la sortie reste entière) ; None si aucune suite ne montre la faute."""
    from usine.cours.base import godot
    for suite in suites[:2]:
        s = godot.tester_gdunit(projet.chemin, ["res://" + suite])
        if not juste(premiere_erreur(s.texte)):
            continue
        cas, autres = cas_de_la_premiere_erreur(s.texte)
        if cas is None or len(autres) > CAS_ECARTES_MAX:
            continue
        ignorer = [f"{Path(suite).stem}:{c}" for c in autres]
        s = godot.tester_gdunit(projet.chemin, ["res://" + suite], ignorer=ignorer)
        e = premiere_erreur(s.texte)
        if juste(e):
            return s, e, suite, cas, ignorer
    return None


def _scene_propre(texte: str) -> bool:
    from usine.cours.base import profil
    return not profil.erreurs_projet(texte) and "SCRIPT ERROR" not in texte


def paire(projet: Any, m: Any, suites: list[str], sujet: str) -> tuple[dict[str, Any] | None, str]:
    """La paire d'une faute posée dans le projet de l'étape, ou (None, raison du rejet).

    Deux preuves de la panne, toutes deux réelles : le cas de test où elle paraît, lancé seul, et la scène lancée
    sans fenêtre (le réflexe `load_scene`). La paire montre la sortie des tests quand elle tient sous le plafond, celle
    de la scène sinon (une sortie de GdUnit4 pèse à elle seule 700 à 800 jetons). La correction est vérifiée par les
    deux : la scène se lance sans erreur et le cas passe."""
    from usine.cours.base import godot, profil, sessions
    projet.remettre()
    projet.poser(m, True)
    try:
        analyse = projet.lancer("analyse", m.fichier)
        if not sessions.propre("analyse", analyse):
            return None, "l'analyse du script signale déjà la faute (pas une erreur d'exécution)"
        juste = lambda e: e is not None and (e.fichier, e.ligne) == (m.fichier, m.ligne) and message_attendu(m, e)  # noqa: E731
        tests = _par_les_tests(projet, m, suites, juste)
        if tests is None:
            return None, "aucune suite ne montre la faute à sa ligne, ou trop de cas à écarter"
        s_t, e_t, suite, cas, ignorer = tests
        s_s = godot.lancer_scene(projet.chemin, m.detail["scene"])
        e_s = premiere_erreur(s_s.texte)
        passage = sessions.passages(projet, [m], RAYON)
        recherche_noeud = _grep(projet, m)
        corriger = ["**Corriger.** Une seule ligne change :", f"Dans `res://{m.fichier}`, ligne {m.ligne}, je remplace :",
                    f"```gdscript\n{m.apres}\n```", "par :", f"```gdscript\n{m.avant}\n```"]
        formes = []
        seul = f", cas `{cas}` seul," if ignorer else ""
        formes.append(("tests", s_t, (
            f"Projet Godot 4.7.2. Les tests de `res://{suite}`{seul} donnent :\n{bloc_court(s_t)}\n\n{passage}\n\n"
            f"Le nœud cherché dans sa scène :\n{recherche_noeud}\n\nCorrige l'erreur."),
            "\n".join([lire(m, s_t, e_t, consequences(s_t.texte, m)), ""] + chercher(m) + [""] + corriger
                      + ["", "**Tester.** Je relance la même commande, celle de la demande."])))
        if juste(e_s):
            formes.append(("scene", s_s, (
                f"Projet Godot 4.7.2. La scène `res://{m.detail['scene']}`, lancée sans fenêtre, donne :\n"
                f"{bloc_court(s_s)}\n\n{passage}\n\nLe nœud cherché dans sa scène :\n{recherche_noeud}\n\n"
                "Corrige l'erreur."),
                "\n".join([lire(m, s_s, e_s, consequences(s_s.texte, m), "scene"), ""] + chercher(m) + [""]
                          + corriger + ["", f"**Tester.** Je relance la scène, puis les tests de `res://{suite}` :",
                                        f"```\n$ {s_s.commande}\n```"])))
        projet.poser(m, False)
        apres_t = godot.tester_gdunit(projet.chemin, ["res://" + suite], ignorer=ignorer)
        if not profil.test_reussi(apres_t.code, apres_t.texte, profil.messages_attendus(projet.apres)):
            return None, "le cas ne passe pas une fois la ligne corrigée"
        apres_s = godot.lancer_scene(projet.chemin, m.detail["scene"])
        if not _scene_propre(apres_s.texte):
            formes = [f for f in formes if f[0] == "tests"]  # la scène a d'autres erreurs : elle ne prouve rien
    finally:
        projet.remettre()
    faites = []
    for mode, s, demande, reponse in formes:
        apres = apres_t if mode == "tests" else apres_s
        faites.append(fmt.paire("execution", sujet, "débogage", demande, reponse,
                                {"outil": "gdunit4" if mode == "tests" else "scène", "mode": mode,
                                 "commande": s.commande, "sortie": s.texte, "code": s.code,
                                 "sortie_apres": apres.texte, "code_apres": apres.code,
                                 "tests_apres": apres_t.commande, "etape": f"{projet.ville}-{projet.n:03d}",
                                 "fichier": m.fichier, "ligne": m.ligne, "genre": m.genre,
                                 "variante": m.detail.get("variante"), "scene": m.detail["scene"]},
                                systeme=fmt.plan()))
    tenues = [p for p in faites if p["jetons"] <= PLAFOND]
    return (tenues[0] if tenues else min(faites, key=lambda p: p["jetons"])), ""


# Le sujet d'un fichier (décision 2), lu dans son chemin ; à défaut, celui de l'étape du cours.
SUJETS_CHEMIN = (("4_ui/", "UI"), (".gdshader", "shaders"), ("/effects/", "VFX"), ("particles", "VFX"),
                 ("_input.gd", "contrôle à la manette"), ("audio", "audio"), ("/camera/", "graphisme 3D"),
                 ("procedural", "procédural"), ("/water/", "procédural"), ("/tools/", "procédural"),
                 ("_view.gd", "graphisme 3D"), ("/weather/", "VFX"))


def _sujet(ville: str, n: int, rel: str) -> str:
    for morceau, sujet in SUJETS_CHEMIN:
        if morceau in rel:
            return sujet
    if rel.startswith("3_entities/") or rel.startswith(("0_autoload/", "2_sequence/")):
        return "gameplay"
    from usine.paires.compilation import _sujet as sujet_etape
    return sujet_etape(ville, n, "compilation")


def generer(cours: str = "kart", par_etape: int = 4, graine: int = 1, etapes: list[int] | None = None,
            donnees: Path | None = None, journal: Callable[[str], None] = print) -> dict[str, Any]:
    """`par_etape` fautes tirées par étape, genres et variantes à tour de rôle, une seule par ligne (graine fixe)."""
    from usine.cours.base import assembler, chemins, creation, sessions
    from usine.paires.compilation import fichiers_a_fauter
    chemins.configurer(cours=cours)
    sortie = fmt.dossier("execution", donnees)
    paires: list[dict[str, Any]] = []
    rejets: list[str] = []
    rng = random.Random(graine)
    vues: set[tuple[str, int]] = set()  # une ligne déjà fautée dans une étape précédente ne revient pas (règle 7.7)
    for ville in assembler.ordre_lignes():
        for n in etapes or list(assembler.etapes_du_cours()):
            _, apres = creation.etats(ville, n)
            dispo = [m for rel in fichiers_a_fauter(apres, "compilation") for m in candidates(apres, rel)
                     if (m.fichier, m.avant) not in vues]
            if not dispo:
                continue
            par_genre: dict[str, list[Any]] = {}
            for m in dispo:
                par_genre.setdefault(m.genre if m.genre == "type_noeud" else m.detail["variante"], []).append(m)
            for liste in par_genre.values():
                rng.shuffle(liste)
            choisies: list[Any] = []
            lignes: set[tuple[str, int]] = set()
            while len(choisies) < par_etape and any(par_genre.values()):
                for g in sorted(par_genre):
                    while par_genre[g] and len(choisies) < par_etape:
                        m = par_genre[g].pop()
                        if (m.fichier, m.ligne) not in lignes:
                            choisies.append(m)
                            lignes.add((m.fichier, m.ligne))
                            break
            projet = sessions.Projet(ville, n, apres)
            gardees = 0
            for m in choisies:
                p, raison = paire(projet, m, suites_pour(apres, m.fichier), _sujet(ville, n, m.fichier))
                if p is None:
                    rejets.append(f"{ville}-{n:03d} {m.fichier}:{m.ligne} {m.genre}/{m.detail.get('variante', '')} : "
                                  f"{raison}")
                    continue
                paires.append(p)
                vues.add((m.fichier, m.avant))
                gardees += 1
            journal(f"{ville}-{n:03d} : {gardees}/{len(choisies)} paires")
    trop_longues = [p for p in paires if p["jetons"] > PLAFOND]
    retenues = [p for p in paires if p["jetons"] <= PLAFOND]
    fmt.ecrire(retenues, sortie / f"paires_{cours}.jsonl")
    fmt.ecrire(trop_longues, sortie / f"trop_longues_{cours}.jsonl")  # pour voir ce qui pèse
    bilan: dict[str, Any] = {"famille": "execution", "cours": cours, "paires": len(retenues),
                             "trop_longues": len(trop_longues), "rejets": rejets, "par_genre": {}, "par_mode": {}, "par_sujet": {},
                             "jetons_max": max((p["jetons"] for p in retenues), default=0),
                             "jetons_moyens": round(sum(p["jetons"] for p in retenues) / max(len(retenues), 1))}
    for p in retenues:
        cle = p["preuve"]["genre"] + (f"/{p['preuve']['variante']}" if p["preuve"]["variante"] else "")
        bilan["par_genre"][cle] = bilan["par_genre"].get(cle, 0) + 1
        bilan["par_mode"][p["preuve"]["mode"]] = bilan["par_mode"].get(p["preuve"]["mode"], 0) + 1
        bilan["par_sujet"][p["sujet"]] = bilan["par_sujet"].get(p["sujet"], 0) + 1
    (sortie / f"bilan_{cours}.json").write_text(json.dumps(bilan, indent=1, ensure_ascii=False), encoding="utf-8")
    return bilan
