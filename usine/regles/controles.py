"""Contrôles mécaniques des règles d'architecture, fichier par fichier (expressions régulières).

Portées :
- jeu : scripts de 0_autoload à 4_ui (ni 7_tests, ni addons) ;
- logique : scripts de 1_core et 3_entities, sauf la présentation (<nom>_view.gd, 3_entities/effects/)
  et l'adaptateur d'entrées (<nom>_input.gd) ;
- équilibrage (DAT-01) : la logique de 2_sequence et de 3_entities.
"""

from __future__ import annotations

import re
from typing import Any, Iterator

from usine.retour.verification import nettoyer
from usine.structure.regles import dossier_de

VISUELS = ("Sprite2D", "Sprite3D", "AnimatedSprite2D", "AnimatedSprite3D", "AudioStreamPlayer",
           "AudioStreamPlayer2D", "AudioStreamPlayer3D", "GPUParticles2D", "GPUParticles3D",
           "CPUParticles2D", "CPUParticles3D")
_VISUEL = re.compile(r"\b(" + "|".join(VISUELS) + r")\b")
_INPUT = re.compile(r"\bInput\s*\.")
_FUNC_ENTREE = re.compile(r"^func\s+(_input|_unhandled_input|_unhandled_key_input)\s*\(", re.M)
_PROCESS = re.compile(r"^func\s+_process\s*\(", re.M)
_PRIORITE = re.compile(r"\bprocess(?:_physics)?_priority\s*=\s*-?\s*\d")
_HASARD = re.compile(r"(?<![\w.])(randf|randi|randf_range|randi_range|randfn)\s*\(|\.(pick_random|shuffle)\s*\(")
_RACINE = re.compile(r"""(?:\^|\$|get_node(?:_or_null)?\s*\(\s*\^?)?["']/root\b""")
_REMONTE = re.compile(r"""(?:\bget_node(?:_or_null)?\s*\(\s*\^?|\$|\^)["']\.\./""")
_NOMBRE = re.compile(r"(?<![\w.])(\d+\.\d*(?:e-?\d+)?|\.\d+|\d+(?:e-?\d+)?)(?![\w.])")
NOMBRES_PERMIS = {"0", "1", "0.0", "1.0", "0.", "1."}
_GODOT3 = [
    (re.compile(r"\byield\s*\("), "yield → await"),
    (re.compile(r"^\s*(?:onready|export)\b(?!_)", re.M), "onready / export sans @ → @onready / @export"),
    (re.compile(r"^\s*tool\s*$", re.M), "tool → @tool"),
    (re.compile(r"\bKinematicBody(?:2D)?\b"), "KinematicBody → CharacterBody2D / CharacterBody3D"),
    (re.compile(r"\.instance\s*\(\s*\)"), "instance() → instantiate()"),
]
_CONNECT_CHAINE = re.compile(r"""\bconnect\s*\(\s*["']""")
_DECL_SANS_TYPE = re.compile(r"^\s*(?:@\w+(?:\([^)\n]*\))?\s+)*(?:static\s+)?(var|const)\s+(\w+)\s*=(?!=)", re.M)
_COLLECTION = re.compile(r"(?::|->)\s*(Array|Dictionary)\b(?!\s*\[)")
_LITTERAL_NU = re.compile(r":=\s*(\[|\{)")
_FUNC = re.compile(r"\bfunc\b\s*(\w*)\s*\(")
_CLASS_NAME = re.compile(r"^class_name\s+(\w+)", re.M)
_NOMS = [
    (re.compile(r"^(?:static\s+)?func\s+(\w+)", re.M), re.compile(r"^_?[a-z][a-z0-9_]*$"), "fonction", "snake_case"),
    (re.compile(r"^\s*(?:@\w+(?:\([^)\n]*\))?\s+)*(?:static\s+)?var\s+(\w+)", re.M), re.compile(r"^_?[a-z][a-z0-9_]*$"),
     "variable", "snake_case"),
    (re.compile(r"^signal\s+(\w+)", re.M), re.compile(r"^[a-z][a-z0-9_]*$"), "signal", "snake_case"),
    (re.compile(r"^enum\s+(\w+)", re.M), re.compile(r"^[A-Z][A-Za-z0-9]*$"), "enum", "PascalCase"),
    (re.compile(r"^class_name\s+(\w+)", re.M), re.compile(r"^[A-Z][A-Za-z0-9]*$"), "classe", "PascalCase"),
    (re.compile(r"^class\s+(\w+)", re.M), re.compile(r"^_?[A-Z][A-Za-z0-9]*$"), "classe interne", "PascalCase"),
]
_CONST = re.compile(r"^(?:static\s+)?const\s+(\w+)[^=\n]*=\s*(.*)$", re.M)
_NOEUD_TSCN = re.compile(r'^\[node name="([^"]+)"', re.M)
_RESOURCE = re.compile(r"^extends\s+Resource\b", re.M)
_CLASSE_INTERNE_RES = re.compile(r"^\s*class\s+\w+\s+extends\s+Resource\b", re.M)


def _ligne(texte: str, pos: int) -> int:
    return texte.count("\n", 0, pos) + 1


def sans_commentaires(texte: str) -> str:
    """Retire les commentaires mais garde le contenu des chaînes (pour les chemins de nœuds)."""
    sortie = []
    for brut in texte.splitlines(keepends=True):
        coupe = len(brut)
        dans = None
        for i, c in enumerate(brut):
            if dans:
                if c == dans and brut[i - 1] != "\\":
                    dans = None
            elif c in "\"'":
                dans = c
            elif c == "#":
                coupe = i
                break
        sortie.append(brut[:coupe] + ("\n" if brut.endswith("\n") and coupe < len(brut) else ""))
    return "".join(sortie)


def est_presentation(res: str) -> bool:
    return res.endswith("_view.gd") or "/effects/" in res


def est_logique(res: str) -> bool:
    return dossier_de(res) in ("1_core", "3_entities") and not est_presentation(res) and not res.endswith("_input.gd")


def est_jeu(res: str) -> bool:
    return dossier_de(res) in ("0_autoload", "1_core", "2_sequence", "3_entities", "4_ui")


def _err(res: str, regle: str, ligne: int | None, message: str) -> dict[str, Any]:
    return {"fichier": res, "ligne": ligne, "categorie": "regle", "regle": regle, "message": f"{regle} : {message}"}


def _arguments(texte: str, ouvrante: int) -> tuple[list[str], int]:
    """Arguments (au premier niveau) de l'appel dont la parenthèse ouvrante est à `ouvrante`."""
    profondeur, debut, args = 0, ouvrante + 1, []
    for i in range(ouvrante, len(texte)):
        c = texte[i]
        if c in "([{":
            profondeur += 1
        elif c in ")]}":
            profondeur -= 1
            if profondeur == 0:
                dernier = texte[debut:i].strip()
                if dernier or args:
                    args.append(dernier)
                return args, i
        elif c == "," and profondeur == 1:
            args.append(texte[debut:i].strip())
            debut = i + 1
    return args, len(texte)


def controler_script(res: str, texte: str) -> Iterator[dict[str, Any]]:
    """Toutes les violations mécaniques d'un script .gd du projet."""
    net = nettoyer(texte)
    code = sans_commentaires(texte)
    logique, jeu = est_logique(res), est_jeu(res)

    for m in _GODOT3:
        for x in m[0].finditer(net):
            yield _err(res, "COD-04", _ligne(net, x.start()), f"syntaxe Godot 3 : {m[1]}")
    for x in _CONNECT_CHAINE.finditer(code):
        yield _err(res, "COD-04", _ligne(code, x.start()), "connexion par chaîne : écrire signal.connect(callable)")

    # COD-02 : déclarations typées.
    for x in _DECL_SANS_TYPE.finditer(net):
        yield _err(res, "COD-02", _ligne(net, x.start()), f"{x.group(1)} {x.group(2)} sans type : « : Type = » ou « := »")
    for x in _COLLECTION.finditer(net):
        yield _err(res, "COD-02", _ligne(net, x.start()), f"{x.group(1)} non typé : {x.group(1)}[Type]")
    for x in _LITTERAL_NU.finditer(net):
        yield _err(res, "COD-02", _ligne(net, x.start()), "littéral sans type (:= [] ou := {}) : déclarer le type")
    for x in _FUNC.finditer(net):
        args, fin = _arguments(net, x.end() - 1)
        nom = x.group(1) or "func anonyme"
        for a in args:
            if a and ":" not in a.split("=", 1)[0]:
                yield _err(res, "COD-02", _ligne(net, x.start()), f"paramètre « {a.split('=')[0].strip()} » de {nom} sans type")
        if not re.match(r"\s*->", net[fin + 1:fin + 40]):
            yield _err(res, "COD-02", _ligne(net, x.start()), f"{nom} sans type de retour (-> void, -> int…)")

    # COD-01 : nommage.
    for motif, attendu, quoi, forme in _NOMS:
        for x in motif.finditer(net):
            if not attendu.match(x.group(1)):
                yield _err(res, "COD-01", _ligne(net, x.start()), f"{quoi} {x.group(1)} : {forme} attendu")
    for x in _CONST.finditer(net):
        nom, valeur = x.group(1), x.group(2)
        alias = re.match(r"\s*(?:pre)?load\s*\(", valeur) and re.match(r"^[A-Z][A-Za-z0-9]*$", nom)
        if not alias and not re.match(r"^_?[A-Z][A-Z0-9_]*$", nom):
            yield _err(res, "COD-01", _ligne(net, x.start()), f"constante {nom} : CONSTANT_CASE attendu")

    # DAT-02 : Resources typées.
    if _RESOURCE.search(net):
        if not _CLASS_NAME.search(net):
            yield _err(res, "DAT-02", 1, "Resource sans class_name : elle n'apparaît pas dans l'inspecteur")
        if dossier_de(res) != "1_core":
            yield _err(res, "DAT-02", 1, "classe de données hors de 1_core : la classe dans 1_core, ses .tres dans 5_data")
    for x in _CLASSE_INTERNE_RES.finditer(net):
        yield _err(res, "DAT-02", _ligne(net, x.start()), "classe interne comme Resource : Godot ne la sérialise pas")

    if not jeu:
        return
    # ARC-06 : dépendances injectées.
    for x in _RACINE.finditer(code):
        yield _err(res, "ARC-06", _ligne(code, x.start()), "chemin /root/ écrit en dur : la dépendance doit être fournie "
                                                          "par le parent (@export, setup() ou signal)")
    for x in _REMONTE.finditer(code):
        yield _err(res, "ARC-06", _ligne(code, x.start()), "chemin remontant ../ écrit en dur : le parent fournit la "
                                                          "dépendance, l'enfant signale vers le haut")
    # SIM-02 : priorités nommées.
    for x in _PRIORITE.finditer(net):
        yield _err(res, "SIM-02", _ligne(net, x.start()), "priorité écrite en nombre : prendre une valeur de ProcessOrder")
    # SIM-08 : create_timer s'arrête en pause.
    for x in re.finditer(r"\bcreate_timer\s*\(", net):
        args, _ = _arguments(net, x.end() - 1)
        if len(args) < 2 or args[1].strip() == "true":
            yield _err(res, "SIM-08", _ligne(net, x.start()), "create_timer() continue pendant la pause : "
                                                            "create_timer(durée, false), ou un décompte dans la logique")
    if logique:
        for x in _VISUEL.finditer(net):
            yield _err(res, "ARC-03", _ligne(net, x.start()), f"{x.group(1)} dans un script de simulation : "
                                                            "la présentation va dans <nom>_view.gd")
        for x in _INPUT.finditer(net):
            yield _err(res, "ARC-04", _ligne(net, x.start()), "Input lu dans la logique : un script <nom>_input.gd "
                                                            "lit les touches et donne des commandes")
        for x in _FUNC_ENTREE.finditer(net):
            yield _err(res, "ARC-04", _ligne(net, x.start()), f"{x.group(1)}() dans la logique : passer par <nom>_input.gd")
        for x in _PROCESS.finditer(net):
            yield _err(res, "SIM-01", _ligne(net, x.start()), "_process dans la logique : le gameplay tourne dans "
                                                            "_physics_process")
        for x in _HASARD.finditer(net):
            yield _err(res, "SIM-09", _ligne(net, x.start()), f"{x.group(1) or x.group(2)}() dans la logique : un "
                                                            "RandomNumberGenerator reçu en dépendance")
    if dossier_de(res) in ("2_sequence", "3_entities") and not est_presentation(res) and not res.endswith("_input.gd"):
        priorites = {_ligne(net, x.start()) for x in _PRIORITE.finditer(net)}  # déjà comptées par SIM-02
        for x in _NOMBRE.finditer(net):
            if x.group(1) not in NOMBRES_PERMIS and _ligne(net, x.start()) not in priorites:
                yield _err(res, "DAT-01", _ligne(net, x.start()), f"nombre {x.group(1)} écrit dans le code : sa valeur "
                                                                "vit dans un .tres de 5_data")


def controler_scene(res: str, texte: str) -> Iterator[dict[str, Any]]:
    """Nœuds en PascalCase (COD-01) et priorités nommées (SIM-02) dans une scène .tscn."""
    for x in _NOEUD_TSCN.finditer(texte):
        if not re.match(r"^[A-Z][A-Za-z0-9]*$", x.group(1)):
            yield _err(res, "COD-01", _ligne(texte, x.start()), f"nœud {x.group(1)} : PascalCase attendu")
    for x in re.finditer(r"^process(?:_physics)?_priority\s*=", texte, re.M):
        yield _err(res, "SIM-02", _ligne(texte, x.start()), "priorité posée dans la scène : la donner en code avec "
                                                          "ProcessOrder")


def controler_projet_godot(texte: str) -> Iterator[dict[str, Any]]:
    if not re.search(r"^gdscript/warnings/untyped_declaration\s*=\s*2\s*$", texte, re.M):
        yield _err("res://project.godot", "COD-02", None, "UNTYPED_DECLARATION n'est pas en erreur : "
                                                         "[debug] gdscript/warnings/untyped_declaration=2")
