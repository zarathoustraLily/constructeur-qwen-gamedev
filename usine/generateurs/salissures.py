"""Salissures : tâches « nettoyer » (document de laurent, section 9, usage 2).

On part d'un projet propre (le socle, 0 écart au juge des règles) et on y injecte UNE violation
mécanique dont la bonne réponse est connue : script rangé hors du plan, syntaxe Godot 3, type
retiré, valeur de 5_data recopiée en dur, get_node("/root/..."), create_timer sans false,
priorité écrite en nombre, _physics_process changé en _process, fonction renommée en camelCase.

Chaque salissure est validée avant d'être écrite : le projet sali doit violer la règle visée, et
elle seule ; le projet propre n'en viole aucune. Le portillon vérifie ensuite, avec Godot, que le
départ échoue et que la référence passe (tests du socle copiés en tests cachés).

Tâche produite (compétence K4, refactor) :
    depart/        le projet sali
    reference/     les fichiers propres (superposés au départ) ; `reference_retire` dans tache.json
                   liste les fichiers du départ à retirer (script déplacé)
    tests_caches/  les tests du socle (7_tests/), qui gardent le comportement
    juge.regles_cibles : la règle salie ; le juge exige alors 0 écart au juge des règles.

Déterministe (règle 2) : remplacements textuels, aucun modèle. Une salissure fausse se corrige
ici (règle 5).
"""

from __future__ import annotations

import re
import tempfile
from dataclasses import dataclass, field
from pathlib import Path, PurePosixPath
from typing import Callable, Iterator

from usine import config as cfg
from usine.generateurs.commun import Production, echantillon, ecrire_projet, ecrire_tache, ident, lire_projet

ORIGINE = "generateur:salissure"
COMPETENCE = "K4"
SOCLE = cfg.RACINE / "godot" / "socle_jeu"
CONSIGNE = ("Nettoie ce projet : il ne respecte plus une règle du plan d'organisation (ORGANISATION.md). "
            "check_structure nomme l'écart par l'identifiant de sa règle. Corrige-le sans changer le "
            "comportement du jeu : les tests de 7_tests doivent rester verts, et check_structure ne doit "
            "plus rien signaler.")
AUTOLOADS = ("GameState", "GameFlow", "Trace", "AudioManager")


@dataclass
class Salissure:
    regle: str
    nom: str                  # ce qui a été sali, pour l'id et le rapport
    fichiers: dict[str, str]  # chemin relatif → texte sali (ou nouveau chemin)
    retire: list[str] = field(default_factory=list)  # fichiers propres absents du départ (déplacés)
    ajoute: list[str] = field(default_factory=list)  # fichiers du départ absents du propre


def _scripts(projet: dict[str, str], dossiers: tuple[str, ...]) -> list[str]:
    return [r for r in projet if r.endswith(".gd") and r.split("/", 1)[0] in dossiers]


def _est_vue_ou_entree(rel: str) -> bool:
    return rel.endswith(("_view.gd", "_input.gd")) or "/effects/" in rel


def _commentaire(texte: str, pos: int) -> bool:
    """Vrai si `pos` est dans un commentaire (# hors chaîne, sur la même ligne)."""
    debut = texte.rfind("\n", 0, pos) + 1
    guillemet = ""
    for c in texte[debut:pos]:
        if guillemet:
            guillemet = "" if c == guillemet else guillemet
        elif c in "\"'":
            guillemet = c
        elif c == "#":
            return True
    return False


def _code(motif: str, texte: str, flags: int = re.M) -> Iterator[re.Match[str]]:
    """Les occurrences du motif hors commentaires : on ne salit que du code."""
    return (m for m in re.finditer(motif, texte, flags) if not _commentaire(texte, m.start()))


def _premier(texte: str, motif: str, remplacement: Callable[[re.Match[str]], str] | str,
             flags: int = re.M) -> Iterator[str]:
    """Une version du texte par occurrence du motif, chacune avec cette seule occurrence remplacée."""
    for m in _code(motif, texte, flags):
        neuf = remplacement(m) if callable(remplacement) else m.expand(remplacement)
        yield texte[:m.start()] + neuf + texte[m.end():]


# --- les salissures, une fonction par sorte ; chacune rend des Salissure candidates


def syntaxe_godot3(projet: dict[str, str]) -> Iterator[Salissure]:
    """COD-04 : await → yield, @export/@onready sans @, instantiate() → instance()."""
    for rel in _scripts(projet, ("0_autoload", "1_core", "2_sequence", "3_entities", "4_ui")):
        t = projet[rel]
        variantes = [
            ("yield", r"await (get_tree\(\))\.(\w+)$", lambda m: f'yield({m.group(1)}, "{m.group(2)}")'),
            ("export", r"^@export var ", "export var "),
            ("onready", r"^@onready var ", "onready var "),
            ("instance", r"\.instantiate\(\)", ".instance()"),
        ]
        for sorte, motif, rempl in variantes:
            for k, sale in enumerate(_premier(t, motif, rempl)):
                if k == 0:  # une salissure par sorte et par fichier
                    yield Salissure("COD-04", f"{sorte}_{PurePosixPath(rel).stem}", {rel: sale})


def type_retire(projet: dict[str, str]) -> Iterator[Salissure]:
    """COD-02 : annotation de variable ou type de retour retiré."""
    for rel in _scripts(projet, ("1_core", "2_sequence", "3_entities", "4_ui")):
        t = projet[rel]
        for k, sale in enumerate(_premier(t, r"^((?:var|const) \w+): [\w\[\], ]+ = ", r"\1 = ")):
            if k == 0:
                yield Salissure("COD-02", f"var_{PurePosixPath(rel).stem}", {rel: sale})
        for k, sale in enumerate(_premier(t, r"^(func \w+\([^)]*\)) -> [\w\[\]]+:", r"\1:")):
            if k == 0:
                yield Salissure("COD-02", f"retour_{PurePosixPath(rel).stem}", {rel: sale})


def _valeurs_tres(texte: str) -> dict[str, str]:
    return dict(re.findall(r"^(\w+) = (-?\d+(?:\.\d+)?)$", texte, re.M))


def _donnees_entite(projet: dict[str, str], rel: str) -> dict[str, str]:
    """Valeurs du .tres de 5_data que la scène principale de l'entité de `rel` lui donne."""
    parties = rel.split("/")
    for n in range(len(parties) - 1, 1, -1):
        dossier = "/".join(parties[:n])
        scene = projet.get(f"{dossier}/{parties[n - 1]}.tscn")
        if scene:
            m = re.search(r'path="res://(5_data/[^"]+\.tres)"', scene)
            return _valeurs_tres(projet.get(m.group(1), "")) if m else {}
    return {}


def valeur_en_dur(projet: dict[str, str]) -> Iterator[Salissure]:
    """DAT-01 : une lecture stats.<réglage> remplacée par la valeur de son .tres."""
    for rel in _scripts(projet, ("3_entities",)):
        if _est_vue_ou_entree(rel):
            continue
        valeurs = _donnees_entite(projet, rel)
        t = projet[rel]
        vus: set[str] = set()
        for m in _code(r"\b(?:\w+\.)?stats\.(\w+)\b(?!\s*\()", t):
            v = valeurs.get(m.group(1))
            if v is None or v in ("0", "1", "0.0", "1.0") or m.group(1) in vus:
                continue
            vus.add(m.group(1))
            yield Salissure("DAT-01", f"{m.group(1)}_{PurePosixPath(rel).stem}",
                            {rel: t[:m.start()] + v + t[m.end():]})


def chemin_root(projet: dict[str, str]) -> Iterator[Salissure]:
    """ARC-06 : un autoload atteint par get_node("/root/...") au lieu de son nom."""
    for rel in _scripts(projet, ("2_sequence", "3_entities", "4_ui")):
        t = projet[rel]
        for k, sale in enumerate(_premier(t, rf"\b({'|'.join(AUTOLOADS)})\.", r'get_node("/root/\1").')):
            if k == 0:
                yield Salissure("ARC-06", f"root_{PurePosixPath(rel).stem}", {rel: sale})


def minuterie_sans_pause(projet: dict[str, str]) -> Iterator[Salissure]:
    """SIM-08 : create_timer(durée, false) → create_timer(durée), qui continue en pause."""
    for rel in _scripts(projet, ("1_core", "2_sequence", "3_entities")):
        for k, sale in enumerate(_premier(projet[rel], r"create_timer\(([^,()]+), false\)", r"create_timer(\1)")):
            yield Salissure("SIM-08", f"timer_{PurePosixPath(rel).stem}_{k}", {rel: sale})


def priorite_en_nombre(projet: dict[str, str]) -> Iterator[Salissure]:
    """SIM-02 : process_physics_priority = ProcessOrder.X → sa valeur."""
    ordre = dict(re.findall(r"^const (\w+)\s*(?::\s*int)?\s*:?=\s*(-?\d+)", projet.get("1_core/process_order.gd", ""),
                            re.M))
    for rel in _scripts(projet, ("1_core", "2_sequence", "3_entities")):
        t = projet[rel]
        for m in _code(r"process_physics_priority = ProcessOrder\.(\w+)", t):
            if m.group(1) in ordre:
                yield Salissure("SIM-02", f"priorite_{PurePosixPath(rel).stem}",
                                {rel: t[:m.start()] + f"process_physics_priority = {ordre[m.group(1)]}" + t[m.end():]})


def physique_en_affichage(projet: dict[str, str]) -> Iterator[Salissure]:
    """SIM-01 : le gameplay de _physics_process déplacé dans _process."""
    for rel in _scripts(projet, ("1_core", "3_entities")):
        if _est_vue_ou_entree(rel) or "func _process(" in projet[rel]:
            continue
        for sale in _premier(projet[rel], r"^func _physics_process\(", "func _process("):
            yield Salissure("SIM-01", f"process_{PurePosixPath(rel).stem}", {rel: sale})


def _camel(nom: str) -> str:
    tete, *reste = nom.lstrip("_").split("_")
    return "_" * (len(nom) - len(nom.lstrip("_"))) + tete + "".join(p.capitalize() for p in reste)


def nom_camel(projet: dict[str, str]) -> Iterator[Salissure]:
    """COD-01 : une fonction privée renommée en camelCase (définition et appels du même fichier)."""
    for rel in _scripts(projet, ("1_core", "2_sequence", "3_entities", "4_ui")):
        t = projet[rel]
        for nom in re.findall(r"^func (_[a-z]+_[a-z_]+)\(", t, re.M):
            if nom in ("_physics_process", "_process", "_ready", "_unhandled_input", "_input", "_exit_tree",
                       "_enter_tree", "_notification", "_draw"):
                continue
            if any(re.search(rf"\b{nom}\b", projet[r]) for r in projet if r != rel):
                continue  # appelé d'ailleurs : renommer changerait d'autres fichiers
            yield Salissure("COD-01", f"camel_{nom.strip('_')}",
                            {rel: re.sub(rf"\b{nom}\b", _camel(nom), t)})
            break


def script_deplace(projet: dict[str, str]) -> Iterator[Salissure]:
    """ORG-01 ou DOSSIERS : un script d'entité rangé hors du plan (scripts/) ou dans 5_data/."""
    for rel in _scripts(projet, ("3_entities",)):
        nom = PurePosixPath(rel).name
        for regle, dossier in (("ORG-01", "scripts"), ("DOSSIERS", "5_data/scripts")):
            neuf = f"{dossier}/{nom}"
            if neuf in projet:
                continue
            fichiers = {neuf: projet[rel]}
            for autre, texte in projet.items():
                if autre != rel and f"res://{rel}" in texte:
                    fichiers[autre] = texte.replace(f'res://{rel}"', f'res://{neuf}"')
            yield Salissure(regle, f"deplace_{dossier.split('/')[0]}_{PurePosixPath(rel).stem}", fichiers,
                            retire=[rel], ajoute=[neuf])


SORTES: tuple[Callable[[dict[str, str]], Iterator[Salissure]], ...] = (
    syntaxe_godot3, type_retire, valeur_en_dur, chemin_root, minuterie_sans_pause, priorite_en_nombre,
    physique_en_affichage, nom_camel, script_deplace)


def salir(projet: dict[str, str], s: Salissure) -> dict[str, str]:
    """Le projet sali (fichiers retirés, fichiers salis ou ajoutés)."""
    sale = {r: t for r, t in projet.items() if r not in s.retire}
    sale.update(s.fichiers)
    return sale


def regles_violees(fichiers: dict[str, str]) -> dict[str, int]:
    """Juge des règles sur un projet écrit dans un dossier jetable."""
    from usine.regles import par_regle, verifier_regles
    with tempfile.TemporaryDirectory(prefix="usine_salissure_") as tmp:
        projet = ecrire_projet(fichiers, Path(tmp) / "p")
        return par_regle(verifier_regles(projet))


def candidates(projet: dict[str, str]) -> Iterator[Salissure]:
    for sorte in SORTES:
        yield from sorte(projet)


def generer(sortie: Path, graine: int = 1, plafond: int | None = None, source: Path | None = None) -> Production:
    """Écrit une tâche K4 « nettoyer » par salissure validée (au plus `plafond`, tirées par la graine)."""
    source = Path(source) if source else SOCLE
    prod = Production()
    projet = lire_projet(source)
    propre = regles_violees(projet)
    if propre:
        prod.ecarter("salissure", source.name, "source sale", str(propre))
        return prod
    tests = {r[len("7_tests/"):]: t for r, t in projet.items() if r.startswith("7_tests/")}
    toutes = list(candidates(projet))
    for s in echantillon(toutes, plafond, f"salissure:{graine}"):
        tid = ident("k4_nettoyer", s.regle, s.nom)
        violees = regles_violees(salir(projet, s))
        if set(violees) != {s.regle}:
            prod.ecarter("salissure", tid, "règle visée non isolée", str(violees))
            continue
        depart = salir(projet, s)
        reference = {r: projet[r] for r in s.fichiers if r in projet} | {r: projet[r] for r in s.retire}
        tache = {"id": tid, "competence": COMPETENCE, "consigne": CONSIGNE, "origine": ORIGINE,
                 "source": source.name, "juge": {"regles_cibles": [s.regle]}}
        if s.ajoute:
            tache["reference_retire"] = sorted(s.ajoute)
        prod.taches.append(ecrire_tache(sortie, tache, depart, reference, tests))
    return prod


__all__ = ["CONSIGNE", "SORTES", "Salissure", "candidates", "generer", "regles_violees", "salir"]
