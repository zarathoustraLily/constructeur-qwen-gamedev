"""Index d'un projet Godot et vérifications de vocabulaire (natif + scripts du projet).

`Projet` lit project.godot, repère les scripts, scènes et ressources (hors addons et .godot),
et résout l'héritage des scripts (class_name, chemin res://, classe native).
`Verificateur` répond aux questions du traducteur et de l'applicateur d'éditions :
telle propriété, tel signal, telle méthode existent-ils sur tel nœud ? Avec quelle arité ?
Tout vient de `usine/vocab` (extension_api.json) et des scripts réels : rien n'est inventé.
"""

from __future__ import annotations

import re
from functools import cached_property
from pathlib import Path
from typing import Any

from usine.projet.gdscript import TYPES_INTEGRES, Script, lire_script
from usine.scene.texte import lire_document, type_cle

DOSSIERS_IGNORES = {"addons", ".godot", ".import", ".usine_rapports", "reports", "tests_juge"}

# Propriétés dynamiques (absentes d'extension_api.json) acceptées, rangées avec les natives.
PROPRIETES_DYNAMIQUES_NATIVES = [
    re.compile(r"^theme_override_(colors|constants|fonts|font_sizes|icons|styles)/[A-Za-z_]\w*$"),
    re.compile(r"^surface_material_override/\d+$"),
    re.compile(r"^tracks/\d+/\w+$"),               # Animation
    re.compile(r"^layer_\d+/\w+$"),                # TileMap (ancien format)
    re.compile(r"^libraries$"),                    # AnimationMixer
    re.compile(r"^shader_parameter/\w+$"),         # ShaderMaterial
]
# Propriétés dynamiques rangées après le script (comme Godot).
PROPRIETES_DYNAMIQUES_APRES = [re.compile(r"^metadata/[A-Za-z_][\w/]*$")]

ARITES_CONSTRUCTEURS = {
    "Vector2": (2,), "Vector2i": (2,), "Vector3": (3,), "Vector3i": (3,), "Vector4": (4,), "Vector4i": (4,),
    "Rect2": (4,), "Rect2i": (4,), "Color": (3, 4), "Quaternion": (4,), "Plane": (4,), "AABB": (6,),
    "Transform2D": (6,), "Basis": (9,), "Transform3D": (12,), "Projection": (16,),
}


def res_vers_disque(racine: Path, res: str) -> Path:
    if not res.startswith("res://"):
        raise ValueError(f"chemin res:// attendu : {res!r}")
    return Path(racine) / Path(*res[len("res://"):].split("/")) if res != "res://" else Path(racine)


def disque_vers_res(racine: Path, chemin: Path) -> str:
    return "res://" + Path(chemin).resolve().relative_to(Path(racine).resolve()).as_posix()


def lire_texte(chemin: Path) -> str:
    """Texte UTF-8 sans traduction des fins de ligne (un fichier CRLF reste CRLF)."""
    with open(chemin, encoding="utf-8", newline="") as f:
        return f.read()


def propriete_dynamique(nom: str) -> str | None:
    """'native' ou 'apres' si `nom` est une propriété dynamique reconnue, sinon None."""
    if any(m.match(nom) for m in PROPRIETES_DYNAMIQUES_NATIVES):
        return "native"
    if any(m.match(nom) for m in PROPRIETES_DYNAMIQUES_APRES):
        return "apres"
    return None


class Projet:
    """Vue en lecture d'un projet Godot sur disque."""

    def __init__(self, racine: Path, fichiers: dict[str, str] | None = None):
        self.racine = Path(racine)
        # fichiers : surcharges en mémoire (res:// → texte), pour valider une édition avant écriture.
        self.fichiers = fichiers if fichiers is not None else {}
        self._scripts: dict[str, Script] = {}

    # --- fichiers
    def lire(self, res: str) -> str | None:
        if res in self.fichiers:
            return self.fichiers[res]
        chemin = res_vers_disque(self.racine, res)
        return lire_texte(chemin) if chemin.is_file() else None

    def existe(self, res: str) -> bool:
        return res in self.fichiers or res_vers_disque(self.racine, res).is_file()

    def _lister(self, extension: str) -> list[str]:
        trouves = set()
        for p in self.racine.rglob(f"*{extension}"):
            parties = p.relative_to(self.racine).parts
            if any(x in DOSSIERS_IGNORES for x in parties[:-1]) or not p.is_file():
                continue
            trouves.add(disque_vers_res(self.racine, p))
        trouves |= {r for r in self.fichiers if r.endswith(extension)}
        return sorted(trouves)

    def scripts(self) -> list[str]:
        return self._lister(".gd")

    def scenes(self) -> list[str]:
        return self._lister(".tscn")

    def ressources(self) -> list[str]:
        return self._lister(".tres")

    # --- project.godot
    @cached_property
    def reglages(self) -> dict[str, dict[str, Any]]:
        texte = (self.racine / "project.godot").read_text(encoding="utf-8")
        doc = lire_document(texte)
        resultat: dict[str, dict[str, Any]] = {}
        for s in doc.sections:
            resultat[s.balise] = {e.cle: e.valeur for e in s.proprietes()}
        return resultat

    def nom(self) -> str:
        return str(self.reglages.get("application", {}).get("config/name", self.racine.name))

    def scene_principale(self) -> str | None:
        return self.reglages.get("application", {}).get("run/main_scene")

    def autoloads(self) -> dict[str, str]:
        """Nom → chemin res:// (sans l'astérisque des singletons)."""
        return {k: str(v).lstrip("*") for k, v in self.reglages.get("autoload", {}).items()}

    # --- scripts
    def script(self, res: str) -> Script | None:
        texte = self.lire(res)
        if texte is None:
            return None
        en_cache = self._scripts.get(res)
        if en_cache is None or en_cache.lignes != texte.splitlines(keepends=True):
            en_cache = lire_script(texte, res)
            self._scripts[res] = en_cache
        return en_cache

    def classes(self) -> dict[str, str]:
        """class_name → chemin res:// du script."""
        table: dict[str, str] = {}
        for res in self.scripts():
            s = self.script(res)
            if s and s.class_name:
                table.setdefault(s.class_name, res)
        return table

    def chaine_scripts(self, res: str) -> tuple[list[Script], str | None]:
        """(scripts de `res` jusqu'au premier ancêtre natif, nom de la classe native de base)."""
        chaine: list[Script] = []
        classes = None
        courant: str | None = res
        while courant and courant not in [s.chemin for s in chaine]:
            s = self.script(courant)
            if s is None:
                return chaine, None
            chaine.append(s)
            base = s.extends or "RefCounted"
            if base.startswith("res://"):
                courant = base
                continue
            if classes is None:
                classes = self.classes()
            if base in classes:
                courant = classes[base]
                continue
            return chaine, base
        return chaine, None

    def racine_scene(self, res: str, _vus: tuple[str, ...] = ()) -> tuple[str | None, str | None]:
        """(type natif, script) du nœud racine d'une scène, en suivant les scènes héritées."""
        texte = self.lire(res)
        if texte is None or res in _vus:
            return None, None
        doc = lire_document(texte)
        ext = {s.attribut("id"): s.attribut("path") for s in doc.de_balise("ext_resource")}
        for s in doc.de_balise("node"):
            if s.a_attribut("parent"):
                continue
            script = None
            e = s.propriete("script")
            if e is not None and isinstance(e.valeur, dict) and "ExtResource" in e.valeur:
                script = ext.get(e.valeur["ExtResource"])
            type_ = s.attribut("type")
            instance = s.attribut("instance")
            if type_ is None and isinstance(instance, dict) and "ExtResource" in instance:
                t2, s2 = self.racine_scene(ext.get(instance["ExtResource"], ""), _vus + (res,))
                return t2, script or s2
            return type_, script
        return None, None

    def type_ressource(self, res: str) -> str | None:
        """Type Godot d'une ressource référencée par chemin (pour ext_resource)."""
        if res.endswith(".gd"):
            return "Script"
        if res.endswith((".tscn", ".scn")):
            return "PackedScene"
        if res.endswith(".gdshader"):
            return "Shader"
        if res.endswith((".tres", ".res")):
            texte = self.lire(res)
            if texte:
                doc = lire_document(texte)
                if doc.sections and doc.sections[0].balise == "gd_resource":
                    return doc.sections[0].attribut("type")
            return None
        if res.lower().endswith((".png", ".jpg", ".jpeg", ".webp", ".svg", ".bmp", ".tga")):
            return "Texture2D"
        if res.lower().endswith((".wav", ".ogg", ".mp3")):
            return "AudioStream"
        if res.lower().endswith((".ttf", ".otf", ".woff", ".woff2")):
            return "FontFile"
        return None


class Verificateur:
    """Existence et arité des membres d'un nœud ou d'une ressource : natif (vocab) + scripts."""

    def __init__(self, vocab, projet: Projet | None = None):
        self.vocab = vocab
        self.projet = projet

    # --- classes
    def classe_existe(self, classe: str) -> bool:
        return self.vocab.classe_existe(classe)

    def herite_de(self, classe: str, ancetre: str) -> bool:
        return ancetre in self.vocab.heritage(classe)

    def type_connu(self, type_: str) -> bool:
        """Type d'argument ou de variable : intégré, classe native, class_name du projet, tableau typé."""
        type_ = type_.strip()
        m = re.fullmatch(r"Array\[(.+)\]", type_)
        if m:
            return self.type_connu(m.group(1))
        m = re.fullmatch(r"Dictionary\[(.+),(.+)\]", type_)
        if m:
            return self.type_connu(m.group(1)) and self.type_connu(m.group(2))
        if type_ in TYPES_INTEGRES or self.vocab.classe_existe(type_):
            return True
        return bool(self.projet and type_ in self.projet.classes())

    def _scripts(self, script: str | None) -> tuple[list[Script], str | None]:
        if not script or self.projet is None:
            return [], None
        return self.projet.chaine_scripts(script)

    def base_native(self, type_: str | None, script: str | None) -> str | None:
        if type_:
            return type_
        return self._scripts(script)[1]

    # --- propriétés
    def type_propriete(self, type_: str | None, script: str | None, nom: str) -> tuple[bool, str | None, str]:
        """(existe, type déclaré ou None, 'native' | 'script' | 'apres')."""
        if nom == "script":
            return True, "Script", "script"
        if type_:
            origine = self.vocab.definie_dans(type_, nom, "propriete")
            if origine:
                ligne = self.vocab.db.execute("SELECT type FROM proprietes WHERE classe=? AND nom=?",
                                              (origine, nom)).fetchone()
                return True, (ligne[0] if ligne else None), "native"
        dyn = propriete_dynamique(nom)
        if dyn:
            return True, None, dyn
        chaine, base = self._scripts(script)
        for s in chaine:
            v = s.variable(nom)
            if v is not None:
                return True, v.type, "script"
        if not type_ and base:
            return self.type_propriete(base, None, nom)
        return False, None, ""

    # --- signaux : nombre d'arguments
    def signal_arguments(self, type_: str | None, script: str | None, nom: str) -> int | None:
        for s in self._scripts(script)[0]:
            sig = s.signal(nom)
            if sig is not None:
                return len(sig.arguments)
        base = self.base_native(type_, script)
        if base and self.vocab.existe(base, nom, "signal"):
            origine = self.vocab.definie_dans(base, nom, "signal")
            return self.vocab.db.execute("SELECT nb_args FROM signaux WHERE classe=? AND nom=?",
                                         (origine, nom)).fetchone()[0]
        return None

    # --- méthodes : arité
    def methode_arite(self, type_: str | None, script: str | None, nom: str) -> tuple[int, int | None] | None:
        for s in self._scripts(script)[0]:
            f = s.fonction(nom)
            if f is not None:
                return f.nb_obligatoires, len(f.arguments)
        base = self.base_native(type_, script)
        if base:
            return self.vocab.arite(base, nom)
        return None

    # --- valeurs
    def valeur_compatible(self, type_decl: str | None, valeur: Any, type_ressource=None) -> str | None:
        """None si `valeur` convient au type déclaré, sinon un message. Indulgent si le type est inconnu."""
        if not type_decl or type_decl in ("Variant", "Object"):
            return None
        t = type_decl.strip()
        if t.startswith(("enum::", "bitfield::")):
            t = "int"
        if t.startswith("typedarray::") or t.startswith("Array["):
            t = "Array"
        if t.startswith("typeddictionary::") or t.startswith("Dictionary["):
            t = "Dictionary"
        if t == "bool":
            return None if isinstance(valeur, bool) else f"booléen attendu pour {type_decl}"
        if t == "int":
            return None if isinstance(valeur, int) and not isinstance(valeur, bool) else f"entier attendu pour {type_decl}"
        if t == "float":
            ok = (isinstance(valeur, (int, float)) and not isinstance(valeur, bool)) or (isinstance(valeur, dict) and "float" in valeur)
            return None if ok else f"nombre attendu pour {type_decl}"
        if t == "String":
            return None if isinstance(valeur, str) else f"chaîne attendue pour {type_decl}"
        if t in ("StringName", "NodePath"):
            return None if isinstance(valeur, str) or (isinstance(valeur, dict) and t in valeur) else f"{t} attendu"
        if t == "Array":
            ok = isinstance(valeur, list) or (isinstance(valeur, dict) and len(valeur) == 1 and type_cle(valeur).startswith("Array["))
            return None if ok else f"tableau attendu pour {type_decl}"
        if t == "Dictionary":
            ok = isinstance(valeur, dict) and len(valeur) == 1 and type_cle(valeur).startswith("Dictionary")
            return None if ok else f"dictionnaire attendu pour {type_decl}"
        if t in ARITES_CONSTRUCTEURS or (t.startswith("Packed") and t.endswith("Array")):
            if not (isinstance(valeur, dict) and len(valeur) == 1 and type_cle(valeur) == t):
                return f'{{"{t}": [...]}} attendu'
            if t in ARITES_CONSTRUCTEURS and len(valeur[t]) not in ARITES_CONSTRUCTEURS[t]:
                return f"{t} : {' ou '.join(map(str, ARITES_CONSTRUCTEURS[t]))} composantes attendues"
            return None
        types = [x.strip() for x in t.split(",") if x.strip() and not x.strip().startswith("-")]
        if types and all(self.vocab.classe_existe(x) or (self.projet and x in self.projet.classes()) for x in types):
            if valeur is None:
                return None
            if isinstance(valeur, dict) and len(valeur) == 1 and type_cle(valeur) in ("ExtResource", "SubResource"):
                reel = type_ressource(valeur) if type_ressource else None
                if reel is None or any(self.vocab.classe_existe(reel) and self.herite_de(reel, x) for x in types):
                    return None
                if reel == "PackedScene" and "PackedScene" in types:
                    return None
                return f"{reel} n'hérite pas de {t}"
            return f"ressource attendue pour {type_decl}"
        return None
