"""Fabrique un projet Godot par étape d'un cours « de jeu » : un jeu entier construit pas à pas (le kart, le
roguelike), à partir de fichiers maîtres balisés et des ressources du jeu source rangé.

Demande de laurent du 2026-10-20 : « tu restructures le projet de kart en étapes de création, pour qu'il apprenne
à coder le contrôle des manettes du kart, l'herbe, des VFX et des shaders, et tu fais exactement la même chose avec
le jeu roguelike ».

Différences avec les cours de décors (fabriquer.py) :
- les maîtres ont la forme du projet : `maitres/<chemin dans le projet>` (scripts, shaders, shaders de calcul,
  scènes, ressources texte, project.godot) ;
- trois balises, mêmes plages que fabriquer.py (« all », « 4+ », « 4-6 », « 4 ») : « #@ » en GDScript, « //@ »
  dans les shaders (.gdshader, .gdshaderinc, .glsl), « ;@ » dans les fichiers de ressources de Godot (.tscn, .tres,
  project.godot, .cfg), où « ; » ouvre un commentaire ;
- les ressources binaires (modèles, textures, sons) et les extensions viennent du jeu source ([sources] de
  config.toml). On ne copie que ce que l'étape désigne, de proche en proche (chemins res://, identifiants uid://,
  .mtl d'un .obj, fichiers d'un .gltf), avec leurs compagnons (.import, .uid) ;
- une étape qui désigne un maître absent à cette étape est refusée (ErreurEtape) : une balise oubliée ne passe
  pas en silence ; un chemin introuvable dans le jeu source est seulement noté (rapport « introuvables ») ;
- pas de bandeau « NOUVEAU » dans le code : la note de l'étape dit ce qui change.

Manifeste (`cours/<nom>/manifeste.py`) : GENRE = "jeu", PREFIXE (nom des projets), SOURCE (clé de [sources]),
DERNIERE, ETAPES ([{titre, piste}]), FICHIERS ({chemin: plage de présence}), EXTENSIONS ({dossier: plage}).
Règle 5 : une erreur se corrige dans les maîtres, jamais dans un projet fabriqué.
"""

from __future__ import annotations

import re
import shutil
from pathlib import Path
from typing import Any

from usine import config as cfg
from usine.cours.fabriquer import lire_manifeste, plage, remplacer

BALISE = re.compile(r"^\s*(#@|//@|;@)\s*(.+?)\s*$")
TEXTE = (".gd", ".gdshader", ".gdshaderinc", ".glsl", ".tscn", ".tres", ".godot", ".cfg", ".json", ".mtl",
         ".gltf", ".import", ".md", ".txt", ".csv")
COMPAGNONS = (".import", ".uid")
_REF_RES = re.compile(r"res://[^\"'\s)\]]+")
_REF_UID = re.compile(r"uid://[a-z0-9]+")
BINAIRES = (".res", ".scn")
_REF_BINAIRE = re.compile(rb"res://[\w./\-]+\.\w+")


class ErreurEtape(RuntimeError):
    """Une étape ne peut pas être fabriquée : référence à un fichier absent à cette étape, ou introuvable."""


def nom_projet(manifeste: dict[str, Any], etape: int) -> str:
    return f"{manifeste['PREFIXE']}_etape_{etape:03d}"


def presence(manifeste: dict[str, Any], rel: str) -> tuple[int, int]:
    bas, haut, _ = plage(manifeste["FICHIERS"][rel], 1, manifeste["DERNIERE"])
    return bas, haut


def present(manifeste: dict[str, Any], rel: str, etape: int) -> bool:
    bas, haut = presence(manifeste, rel)
    return bas <= etape <= haut


def jetons(manifeste: dict[str, Any], etape: int) -> dict[str, str]:
    info = manifeste["ETAPES"][etape - 1]
    return {"{STEP}": f"{etape:03d}", "{NAME}": nom_projet(manifeste, etape), "{TITLE}": info["titre"],
            "{TRACK}": info["piste"]}


def rendre(texte: str, etape: int, premiere: int, derniere: int) -> str:
    """Le texte d'un maître à une étape : les lignes dont la plage contient l'étape, sans les balises."""
    retenues: list[str] = []
    bas, haut = premiere, derniere
    for ligne in texte.split("\n"):
        m = BALISE.match(ligne)
        if m:
            bas, haut, _ = plage(m.group(2), premiere, derniere)
            continue
        if bas <= etape <= haut:
            retenues.append(ligne)
    sortie = re.sub(r"\n{4,}", "\n\n\n", "\n".join(retenues))
    return sortie.rstrip("\n") + "\n"


def texte_maitre(cours: Path, manifeste: dict[str, Any], rel: str, etape: int) -> str:
    bas, haut = presence(manifeste, rel)
    brut = (Path(cours) / "maitres" / rel).read_text(encoding="utf-8")
    return remplacer(rendre(brut, etape, bas, haut), jetons(manifeste, etape))


def carte_uid(source: Path) -> dict[str, str]:
    """uid://… → chemin relatif, d'après les .uid (scripts, shaders) et les .import (ressources importées) du
    jeu source."""
    carte: dict[str, str] = {}
    for f in Path(source).rglob("*.uid"):
        if ".godot" in f.relative_to(source).parts:
            continue
        carte[f.read_text(encoding="utf-8").strip()] = f.relative_to(source).as_posix()[: -len(".uid")]
    for f in Path(source).rglob("*.import"):
        if ".godot" in f.relative_to(source).parts:
            continue
        m = re.search(r'^uid="(uid://[a-z0-9]+)"', f.read_text(encoding="utf-8", errors="replace"), re.M)
        if m:
            carte[m.group(1)] = f.relative_to(source).as_posix()[: -len(".import")]
    return carte


def _references(rel: str, texte: str, carte: dict[str, str]) -> set[str]:
    """Fichiers que `texte` (le fichier `rel`) désigne, en chemins relatifs du projet."""
    refs = {m.removeprefix("res://") for m in _REF_RES.findall(texte)}
    refs |= {carte[u] for u in _REF_UID.findall(texte) if u in carte}
    dossier = rel.rpartition("/")[0]
    def voisin(nom: str) -> str:
        return f"{dossier}/{nom}" if dossier else nom
    if rel.endswith(".obj"):
        refs |= {voisin(m) for m in re.findall(r"^mtllib\s+(.+?)\s*$", texte, re.M)}
    elif rel.endswith(".mtl"):
        refs |= {voisin(m) for m in re.findall(r"^\s*map_\w+\s+(?:-\S+\s+\S+\s+)*(\S+)\s*$", texte, re.M)}
    elif rel.endswith(".gltf"):
        refs |= {voisin(m) for m in re.findall(r'"uri"\s*:\s*"([^"]+)"', texte) if not m.startswith("data:")}
    # Les fichiers importés du cache (.godot/imported/…) se refont à l'import : on ne les suit pas.
    return {r.rstrip(".,;") for r in refs if not r.startswith(".godot/")}


def _copier(source: Path, racine: Path, rel: str) -> None:
    cible = racine / rel
    cible.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source / rel, cible)
    for ext in COMPAGNONS:
        if (source / (rel + ext)).is_file():
            shutil.copy2(source / (rel + ext), racine / (rel + ext))


def _lisible(chemin: Path) -> str | None:
    if chemin.suffix in BINAIRES:
        # Une ressource binaire de Godot garde en clair le chemin de ses ressources externes (un maillage .res désigne
        # ses matériaux) ; on n'en lit que ces chemins, au motif strict (aucun octet de structure autour).
        return "\n".join(m.decode("ascii") for m in _REF_BINAIRE.findall(chemin.read_bytes()))
    if chemin.suffix not in TEXTE and chemin.suffix != ".obj":
        return None
    try:
        return chemin.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return None


def fabriquer(cours: Path, etape: int, sortie: Path, manifeste: dict[str, Any] | None = None,
              source: Path | None = None) -> dict[str, Any]:
    """Écrit le projet de l'étape dans `sortie/<nom>` (remplacé s'il existe) ; rend son rapport
    {nom, etape, fichiers: [{chemin, etat}], ressources: [chemins copiés]}."""
    cours = Path(cours)
    manifeste = manifeste or lire_manifeste(cours)
    source = Path(source) if source else cfg.chemin_source(manifeste["SOURCE"])
    if source is None or not (source / "project.godot").is_file():
        raise ErreurEtape(f"jeu source « {manifeste['SOURCE']} » introuvable ([sources] de config.toml)")
    nom = nom_projet(manifeste, etape)
    racine = Path(sortie) / nom
    if racine.is_dir():
        shutil.rmtree(racine)
    racine.mkdir(parents=True)
    rapport: dict[str, Any] = {"nom": nom, "etape": etape, "fichiers": [], "ressources": [], "introuvables": []}

    # 1. Les maîtres présents à cette étape, et le compagnon .uid du jeu source (identifiants stables).
    for rel in sorted(manifeste["FICHIERS"]):
        if not present(manifeste, rel, etape):
            continue
        texte = texte_maitre(cours, manifeste, rel, etape)
        (racine / rel).parent.mkdir(parents=True, exist_ok=True)
        (racine / rel).write_text(texte, encoding="utf-8", newline="\n")
        if (source / (rel + ".uid")).is_file():
            shutil.copy2(source / (rel + ".uid"), racine / (rel + ".uid"))
        bas, _ = presence(manifeste, rel)
        if etape == bas:
            etat = "nouveau"
        else:
            etat = "inchangé" if texte == texte_maitre(cours, manifeste, rel, etape - 1) else "modifié"
        rapport["fichiers"].append({"chemin": rel, "etat": etat})

    # 2. Les extensions de cette étape, entières.
    for dossier, spec in manifeste.get("EXTENSIONS", {}).items():
        bas, haut, _ = plage(spec, 1, manifeste["DERNIERE"])
        if bas <= etape <= haut:
            shutil.copytree(source / dossier, racine / dossier, dirs_exist_ok=True)
            rapport["ressources"].append(dossier + "/")

    # 3. Les ressources désignées, de proche en proche.
    carte = carte_uid(source)
    maitres = set(manifeste["FICHIERS"])
    a_voir = [rel for rel in (e["chemin"] for e in rapport["fichiers"])]
    vus: set[str] = set(a_voir)
    while a_voir:
        rel = a_voir.pop()
        texte = _lisible(racine / rel)
        if texte is None:
            continue
        for ref in sorted(_references(rel, texte, carte)):
            if ref in vus or (racine / ref).exists():
                continue
            vus.add(ref)
            if ref in maitres:
                raise ErreurEtape(f"étape {etape} : {rel} désigne {ref}, absent à cette étape "
                                  f"(présent : {manifeste['FICHIERS'][ref]})")
            if not (source / ref).is_file():
                # Un chemin cité sans être chargé (un test qui imagine une séquence) : noté, pas copié. La
                # vérification par Godot dira s'il manque vraiment.
                rapport["introuvables"].append(f"{rel} → {ref}")
                continue
            _copier(source, racine, ref)
            rapport["ressources"].append(ref)
            a_voir.append(ref)
            # Les réglages d'import d'une ressource peuvent désigner d'autres fichiers (matériaux extraits).
            if (racine / (ref + ".import")).is_file():
                a_voir.append(ref + ".import")

    # 4. La note de l'étape, devenue le README.md du projet, avec le tableau de ses fichiers.
    note = cours / "notes" / f"etape_{etape:03d}.md"
    rapport["note"] = note.is_file()
    if note.is_file():
        tableau = ["| Fichier | À cette étape |", "|---|---|"]
        tableau += [f"| `{e['chemin']}` | {e['etat']} |" for e in rapport["fichiers"] if e["etat"] != "inchangé"]
        table = jetons(manifeste, etape)
        table["{FILES_TABLE}"] = "\n".join(tableau)
        (racine / "README.md").write_text(remplacer(note.read_text(encoding="utf-8"), table), encoding="utf-8",
                                          newline="\n")
    return rapport


def etapes_demandees(manifeste: dict[str, Any], etapes: list[int] | None = None) -> list[int]:
    return list(etapes or manifeste.get("PRETES", range(1, manifeste["DERNIERE"] + 1)))


def fabriquer_tout(cours: Path, sortie: Path, etapes: list[int] | None = None,
                   source: Path | None = None) -> list[dict[str, Any]]:
    manifeste = lire_manifeste(cours)
    return [fabriquer(cours, n, sortie, manifeste, source) for n in etapes_demandees(manifeste, etapes)]
