"""apply_edits : applique une liste d'éditions à un projet Godot, tout ou rien (EDITS_GODOT.md).

Déroulé :
1. Les éditions sont validées et appliquées une à une **en mémoire** (vocabulaire réel,
   scripts du projet, id de describe_project). Au premier édit refusé, rien n'est écrit.
2. Les fichiers modifiés sont écrits dans une **copie de travail** du projet, que le juge
   commun évalue (import → check_script → load_scene → run_tests).
3. Si le juge passe, chaque fichier modifié du projet est remplacé par `os.replace`
   (atomique par fichier), après vérification que personne ne l'a changé entre-temps ;
   en cas d'échec au milieu, les fichiers déjà remplacés sont restaurés. Sinon la copie
   est jetée et le projet n'est pas touché.

Les fichiers sont édités en place : seules les lignes ou sections visées changent, le reste
garde son ordre et ses octets.
"""

from __future__ import annotations

import os
import re
import tempfile
import time
from pathlib import Path
from typing import Any, Callable

from usine.juge.projet import ETAPES, juger_sur_place, preparer_copie
from usine.projet.decrire import alias_scenes
from usine.projet.gdscript import _FUNC, lire_script, reindenter, unite_indentation
from usine.projet.index import Projet, Verificateur, lire_texte, res_vers_disque
from usine.scene.spec import CARACTERES_INTERDITS_NOM, h5, id_interne
from usine.scene.texte import (Document, Entree, Section, echapper, ecrire_valeur, format_attribut, lire_document,
                               references, type_cle)

OPERATIONS = ("add_node", "del_node", "set_property", "attach_script", "connect", "disconnect",
              "add_signal", "add_function", "replace_function", "set_resource_value")
BALISES_COMPACTES = {"ext_resource", "connection", "editable"}
_IDENTIFIANT = re.compile(r"^[A-Za-z_]\w*$")


class ErreurEdit(Exception):
    def __init__(self, message: str, categorie: str = "valeur_invalide", fichier: str | None = None):
        super().__init__(message)
        self.message = message
        self.categorie = categorie
        self.fichier = fichier


# --------------------------------------------------------------------------- mise en page des sections

def inserer_section(doc: Document, index: int, section: Section) -> None:
    """Insère `section` à la position `index` en gardant la mise en page de Godot :
    blocs compacts (ext_resource, connection, editable) sans ligne vide entre eux,
    une ligne vide entre les autres sections, pas de ligne vide finale."""
    fl = doc.fin_ligne()
    precedente = doc.sections[index - 1] if index > 0 else None
    suivante_existe = index < len(doc.sections)
    if precedente is not None and section.balise in BALISES_COMPACTES and precedente.balise == section.balise:
        section.fixer_lignes_finales(precedente.lignes_finales(), fl)
        precedente.fixer_lignes_finales(0, fl)
    else:
        if precedente is not None and precedente.lignes_finales() == 0:
            precedente.fixer_lignes_finales(1, fl)
        section.fixer_lignes_finales(1 if suivante_existe else 0, fl)
    doc.sections.insert(index, section)


def retirer_section(doc: Document, section: Section) -> None:
    fl = doc.fin_ligne()
    index = doc.index(section)
    precedente = doc.sections[index - 1] if index > 0 else None
    derniere = index == len(doc.sections) - 1
    if precedente is not None:
        if section.balise in BALISES_COMPACTES and precedente.balise == section.balise:
            precedente.fixer_lignes_finales(section.lignes_finales(), fl)
        elif derniere:
            precedente.fixer_lignes_finales(0, fl)
    del doc.sections[index]


def nouvelle_section(balise: str, attributs: list[tuple[str, str]], fl: str = "\n") -> Section:
    entete = "[" + " ".join([balise] + [format_attribut(k, b) for k, b in attributs]) + "]" + fl
    return Section(balise, list(attributs), entete)


def chemin_section(section: Section) -> str:
    parent = section.attribut("parent")
    if parent is None:
        return "."
    nom = section.attribut("name")
    return nom if parent == "." else f"{parent}/{nom}"


def _sous(chemin: str, ancetre: str) -> bool:
    if ancetre == ".":
        return True
    return chemin == ancetre or chemin.startswith(ancetre + "/")


# --------------------------------------------------------------------------- espace de travail en mémoire

class Espace:
    """État en mémoire : textes modifiés par-dessus le projet sur disque."""

    def __init__(self, racine: Path, verif_vocab):
        self.racine = Path(racine)
        self.fichiers: dict[str, str] = {}
        self.projet = Projet(self.racine, self.fichiers)
        self.verif = Verificateur(verif_vocab, self.projet)
        self.alias = alias_scenes(self.projet.scenes())
        self.par_alias = {a: r for r, a in self.alias.items()}
        self.originaux: dict[str, str | None] = {}

    # --- fichiers
    def texte(self, res: str) -> str:
        t = self.projet.lire(res)
        if t is None:
            raise ErreurEdit(f"fichier introuvable : {res}", "id_inconnu", res)
        return t

    def ecrire(self, res: str, texte: str) -> None:
        if res not in self.originaux:
            self.originaux[res] = self.projet.lire(res) if self.projet.existe(res) else None
        self.fichiers[res] = texte

    def document(self, res: str) -> Document:
        return lire_document(self.texte(res))

    def enregistrer(self, res: str, doc: Document) -> None:
        mettre_a_jour_load_steps(doc)
        self.ecrire(res, doc.texte())

    # --- nœuds
    def noeud(self, ident: Any) -> tuple[str, str, Document, Section]:
        """id lisible → (scène res://, chemin du nœud, document, section)."""
        if not isinstance(ident, str) or not ident:
            raise ErreurEdit(f"id de nœud attendu, reçu {ident!r}", "id_inconnu")
        alias, _, chemin = ident.partition(":")
        chemin = chemin or "."
        res = self.par_alias.get(alias)
        if res is None:
            raise ErreurEdit(f"id inconnu : {ident!r} (scène {alias!r} inconnue)", "id_inconnu")
        doc = self.document(res)
        for s in doc.de_balise("node"):
            if chemin_section(s) == chemin:
                return res, chemin, doc, s
        raise ErreurEdit(f"id inconnu : {ident!r} (aucun nœud {chemin!r} dans {res})", "id_inconnu", res)

    def info_noeud(self, doc: Document, section: Section) -> tuple[str | None, str | None]:
        """(type natif, script) d'un nœud, en suivant l'instance éventuelle."""
        ext = ext_par_id(doc)
        script = None
        e = section.propriete("script")
        if e is not None and isinstance(e.valeur, dict) and "ExtResource" in e.valeur:
            script = ext.get(e.valeur["ExtResource"])
        type_ = section.attribut("type")
        instance = section.attribut("instance")
        if type_ is None and isinstance(instance, dict) and "ExtResource" in instance:
            t_inst, s_inst = self.projet.racine_scene(ext.get(instance["ExtResource"], ""))
            return t_inst, script or s_inst
        return type_, script


# --------------------------------------------------------------------------- ressources d'un document

def ext_par_id(doc: Document) -> dict[str, str]:
    return {s.attribut("id"): s.attribut("path") for s in doc.de_balise("ext_resource")}


def mettre_a_jour_load_steps(doc: Document) -> None:
    """Si l'en-tête porte load_steps (format antérieur à 4.7), il suit le nombre de ressources."""
    if doc.sections and doc.sections[0].a_attribut("load_steps"):
        n = len(doc.de_balise("ext_resource")) + len(doc.de_balise("sub_resource")) + 1
        if doc.sections[0].attribut("load_steps") != n:
            doc.sections[0].definir_attribut("load_steps", n)


def assurer_externe(doc: Document, chemin: str, type_: str) -> str:
    """id de l'ext_resource de `chemin`, créée au besoin (id dérivé du chemin)."""
    for s in doc.de_balise("ext_resource"):
        if s.attribut("path") == chemin:
            return s.attribut("id")
    pris = {s.attribut("id") for s in doc.de_balise("ext_resource")}
    rang = len(pris) + 1
    while f"{rang}_{h5(chemin)}" in pris:
        rang += 1
    ident = f"{rang}_{h5(chemin)}"
    section = nouvelle_section("ext_resource", [("type", echapper(type_)), ("path", echapper(chemin)), ("id", echapper(ident))],
                               doc.fin_ligne())
    exts = doc.de_balise("ext_resource")
    index = doc.index(exts[-1]) + 1 if exts else 1
    inserer_section(doc, index, section)
    return ident


def creer_interne(doc: Document, res_scene: str, etiquette: str, type_: str, proprietes_brutes: list[tuple[str, str]]) -> str:
    pris = {s.attribut("id") for s in doc.de_balise("sub_resource")}
    ident, n = id_interne(type_, res_scene, etiquette), 2
    while ident in pris:
        ident, n = id_interne(type_, res_scene, f"{etiquette}~{n}"), n + 1
    fl = doc.fin_ligne()
    section = nouvelle_section("sub_resource", [("type", echapper(type_)), ("id", echapper(ident))], fl)
    for cle, brut in proprietes_brutes:
        section.entrees.append(Entree(f"{cle} = {brut}{fl}", cle, brut))
    subs = doc.de_balise("sub_resource")
    if subs:
        index = doc.index(subs[-1]) + 1
    else:
        exts = doc.de_balise("ext_resource")
        index = doc.index(exts[-1]) + 1 if exts else 1
    inserer_section(doc, index, section)
    return ident


def nettoyer_ressources(doc: Document) -> None:
    """Retire les sub_resource puis ext_resource que plus rien ne référence."""
    motif = re.compile(r'(ExtResource|SubResource)\("([^"]*)"\)')
    while True:
        refs: set[tuple[str, str]] = set()
        for s in doc.sections:
            refs |= set(motif.findall(s.texte()))
        orphelines = [s for s in doc.de_balise("sub_resource") if ("SubResource", s.attribut("id")) not in refs]
        orphelines += [s for s in doc.de_balise("ext_resource") if ("ExtResource", s.attribut("id")) not in refs]
        if not orphelines:
            return
        for s in orphelines:
            retirer_section(doc, s)


# --------------------------------------------------------------------------- valeurs

def _type_ressource_edit(espace: Espace) -> Callable[[dict], str | None]:
    def type_ressource(v: dict) -> str | None:
        k = type_cle(v)
        x = v[k]
        if k == "SubResource" and isinstance(x, dict):
            return x.get("type")
        if k == "ExtResource" and isinstance(x, str):
            return espace.projet.type_ressource(x)
        return None
    return type_ressource


def verifier_valeur(espace: Espace, lieu: str, cle: str, type_decl: str | None, v: Any) -> None:
    """Refuse une valeur mal formée ou incompatible avec le type déclaré (ErreurEdit)."""
    for chemin in references(v, "ExtResource"):
        if not isinstance(chemin, str) or not chemin.startswith("res://"):
            raise ErreurEdit(f"{cle} : ExtResource attend un chemin res:// ({chemin!r})", "valeur_invalide", lieu)
        if not espace.projet.existe(chemin):
            raise ErreurEdit(f"{cle} : ressource absente du projet : {chemin}", "missing_resource", lieu)
        if espace.projet.type_ressource(chemin) is None:
            raise ErreurEdit(f"{cle} : type de ressource inconnu pour {chemin}", "valeur_invalide", lieu)
    for interne in references(v, "SubResource"):
        if not isinstance(interne, dict) or not isinstance(interne.get("type"), str):
            raise ErreurEdit(f'{cle} : SubResource attend {{"type": …, "proprietes": {{…}}}}', "valeur_invalide", lieu)
        t = interne["type"]
        if not espace.verif.classe_existe(t) or not espace.verif.herite_de(t, "Resource"):
            raise ErreurEdit(f"{cle} : type de ressource inconnu : {t!r}", "vocab_inconnu", lieu)
        for k2, v2 in (interne.get("proprietes") or {}).items():
            existe, td2, _ = espace.verif.type_propriete(t, None, k2)
            if not existe:
                raise ErreurEdit(f"{cle} : propriété inconnue {k2!r} pour {t}", "vocab_inconnu", lieu)
            verifier_valeur(espace, lieu, f"{cle}.{k2}", td2, v2)
    try:
        ecrire_valeur(_sans_internes(v))
    except (ValueError, TypeError) as exc:
        raise ErreurEdit(f"{cle} : valeur non codable ({exc})", "valeur_invalide", lieu) from exc
    message = espace.verif.valeur_compatible(type_decl, v, _type_ressource_edit(espace))
    if message:
        raise ErreurEdit(f"{cle} : {message}", "valeur_invalide", lieu)


def _sans_internes(v: Any) -> Any:
    """Remplace les SubResource en ligne par un id factice (pour tester l'écriture)."""
    if isinstance(v, list):
        return [_sans_internes(e) for e in v]
    if isinstance(v, dict) and len(v) == 1:
        k = type_cle(v)
        if k == "SubResource" and isinstance(v[k], dict):
            return {"SubResource": "x"}
        if k == "Dictionary" or k.startswith(("Dictionary[", "Array[")):
            return {k: _sans_internes(v[k])}
    return v


def coercer(type_decl: str | None, v: Any) -> Any:
    if type_decl == "float" and isinstance(v, int) and not isinstance(v, bool):
        return float(v)
    return v


def valeur_fichier(espace: Espace, doc: Document, res_scene: str, etiquette: str, v: Any) -> str:
    """Texte Godot d'une valeur d'édition : chemins → ExtResource("id"), ressources en ligne → sub_resource."""
    def convertir(x: Any, chemin: str) -> Any:
        if isinstance(x, list):
            return [convertir(e, f"{chemin}[{i}]") for i, e in enumerate(x)]
        if isinstance(x, dict) and len(x) == 1:
            k = type_cle(x)
            if k == "ExtResource":
                return {k: assurer_externe(doc, x[k], espace.projet.type_ressource(x[k]) or "Resource")}
            if k == "SubResource" and isinstance(x[k], dict):
                t = x[k]["type"]
                props = []
                for k2, v2 in (x[k].get("proprietes") or {}).items():
                    _, td2, _ = espace.verif.type_propriete(t, None, k2)
                    props.append((k2, ecrire_valeur(convertir(coercer(td2, v2), f"{chemin}/{k2}"))))
                return {k: creer_interne(doc, res_scene, chemin, t, props)}
            if k == "Dictionary" or k.startswith(("Dictionary[", "Array[")):
                return {k: convertir(x[k], chemin)}
        return x
    return ecrire_valeur(convertir(v, etiquette))


# --------------------------------------------------------------------------- placement des propriétés

def _rang_propriete(espace: Espace, type_: str | None, cle: str) -> str:
    if cle.startswith("metadata/"):
        return "apres"
    if type_:
        existe, _, genre = espace.verif.type_propriete(type_, None, cle)
        if existe and genre == "native":
            return "native"
    return "apres"


def poser_propriete(espace: Espace, section: Section, type_: str | None, cle: str, brut: str, fl: str) -> None:
    """Remplace la ligne, ou l'insère à sa place : natives avant `script`, le reste en fin."""
    if section.propriete(cle) is not None:
        section.definir_propriete(cle, brut, fin_ligne=fl)
        return
    if cle == "script":
        premiere_apres = next((e.cle for e in section.proprietes() if _rang_propriete(espace, type_, e.cle) == "apres"), None)
        section.definir_propriete(cle, brut, avant=premiere_apres, fin_ligne=fl)
        return
    if _rang_propriete(espace, type_, cle) == "native" and section.propriete("script") is not None:
        section.definir_propriete(cle, brut, avant="script", fin_ligne=fl)
        return
    section.definir_propriete(cle, brut, fin_ligne=fl)


def _verifier_propriete_noeud(espace: Espace, lieu: str, type_: str | None, script: str | None, cle: str, v: Any) -> str | None:
    if not isinstance(cle, str) or not cle:
        raise ErreurEdit("nom de propriété attendu", "valeur_invalide", lieu)
    if cle == "script":
        raise ErreurEdit("le script se pose avec attach_script, pas set_property", "valeur_invalide", lieu)
    existe, type_decl, _ = espace.verif.type_propriete(type_, script, cle)
    if not existe:
        raise ErreurEdit(f"propriété inconnue {cle!r} pour {type_ or '?'}" + (f" + {script}" if script else ""),
                         "vocab_inconnu", lieu)
    verifier_valeur(espace, lieu, cle, type_decl, v)
    return type_decl


def _verifier_script(espace: Espace, lieu: str, script: Any, type_noeud: str | None) -> None:
    if not isinstance(script, str) or not script.startswith("res://") or not script.endswith(".gd"):
        raise ErreurEdit(f"script : chemin res://….gd attendu ({script!r})", "valeur_invalide", lieu)
    if not espace.projet.existe(script):
        raise ErreurEdit(f"script introuvable : {script}", "id_inconnu", lieu)
    _, base = espace.projet.chaine_scripts(script)
    if base is None:
        raise ErreurEdit(f"impossible de résoudre la classe de base de {script}", "type_error", lieu)
    if type_noeud and espace.verif.classe_existe(base) and not espace.verif.herite_de(type_noeud, base):
        raise ErreurEdit(f"{script} étend {base}, incompatible avec un nœud {type_noeud}", "type_error", lieu)


# --------------------------------------------------------------------------- opérations sur les scènes

def op_add_node(espace: Espace, e: dict) -> None:
    res, chemin_parent, doc, s_parent = espace.noeud(e.get("parent"))
    nom = e.get("nom")
    if not isinstance(nom, str) or not nom or set(nom) & CARACTERES_INTERDITS_NOM:
        raise ErreurEdit(f"nom de nœud invalide : {nom!r}", "invalid_node_path", res)
    chemin = nom if chemin_parent == "." else f"{chemin_parent}/{nom}"
    if any(chemin_section(s) == chemin for s in doc.de_balise("node")):
        raise ErreurEdit(f"{chemin_parent} a déjà un enfant {nom!r}", "invalid_node_path", res)
    type_, instance, script = e.get("type"), e.get("instance"), e.get("script")
    if bool(type_) == bool(instance):
        raise ErreurEdit("add_node : donner soit « type », soit « instance »", "valeur_invalide", res)
    type_eff, script_eff = type_, script
    if type_:
        if not espace.verif.classe_existe(type_):
            raise ErreurEdit(f"type de nœud inconnu : {type_!r}", "vocab_inconnu", res)
        if not espace.verif.herite_de(type_, "Node"):
            raise ErreurEdit(f"{type_} n'est pas un Node", "vocab_inconnu", res)
    else:
        if not isinstance(instance, str) or not instance.endswith(".tscn") or not espace.projet.existe(instance):
            raise ErreurEdit(f"scène à instancier introuvable : {instance!r}", "id_inconnu", res)
        if instance == res:
            raise ErreurEdit("une scène ne peut pas s'instancier elle-même", "valeur_invalide", res)
        type_eff, s_inst = espace.projet.racine_scene(instance)
        script_eff = script or s_inst
    if script:
        _verifier_script(espace, res, script, type_eff)
    groupes = e.get("groupes", [])
    if not isinstance(groupes, list) or not all(isinstance(g, str) and g for g in groupes):
        raise ErreurEdit("groupes : liste de chaînes attendue", "valeur_invalide", res)
    proprietes = e.get("proprietes") or {}
    if not isinstance(proprietes, dict):
        raise ErreurEdit("proprietes : objet attendu", "valeur_invalide", res)
    types_decl = {k: _verifier_propriete_noeud(espace, res, type_eff, script_eff, k, v) for k, v in proprietes.items()}

    fl = doc.fin_ligne()
    attributs = [("name", echapper(nom))]
    if type_:
        attributs.append(("type", echapper(type_)))
    attributs.append(("parent", echapper(chemin_parent)))
    if groupes:
        attributs.append(("groups", ecrire_valeur(groupes)))
    if instance:
        attributs.append(("instance", f"ExtResource({echapper(assurer_externe(doc, instance, 'PackedScene'))})"))
    section = nouvelle_section("node", attributs, fl)
    for k, v in proprietes.items():
        brut = valeur_fichier(espace, doc, res, f"{chemin}:{k}", coercer(types_decl[k], v))
        poser_propriete(espace, section, type_eff, k, brut, fl)
    if script:
        brut = f"ExtResource({echapper(assurer_externe(doc, script, 'Script'))})"
        poser_propriete(espace, section, type_eff, "script", brut, fl)
    # Après le dernier descendant du parent (l'ordre du fichier reste préfixe).
    noeuds = doc.de_balise("node")
    dernier = s_parent
    for s in noeuds[noeuds.index(s_parent) + 1:]:
        if chemin_parent == "." or _sous(chemin_section(s), chemin_parent):
            dernier = s
        else:
            break
    inserer_section(doc, doc.index(dernier) + 1, section)
    espace.enregistrer(res, doc)


def op_del_node(espace: Espace, e: dict) -> None:
    res, chemin, doc, _ = espace.noeud(e.get("noeud"))
    if chemin == ".":
        raise ErreurEdit("on ne supprime pas la racine d'une scène", "valeur_invalide", res)
    for s in list(doc.sections):
        if s.balise == "node" and _sous(chemin_section(s), chemin):
            retirer_section(doc, s)
        elif s.balise == "connection" and (_sous(s.attribut("from"), chemin) or _sous(s.attribut("to"), chemin)):
            retirer_section(doc, s)
        elif s.balise == "editable" and _sous(s.attribut("path"), chemin):
            retirer_section(doc, s)
    nettoyer_ressources(doc)
    espace.enregistrer(res, doc)


def op_set_property(espace: Espace, e: dict) -> None:
    res, chemin, doc, section = espace.noeud(e.get("noeud"))
    if "valeur" not in e:
        raise ErreurEdit("set_property : champ « valeur » manquant", "valeur_invalide", res)
    type_, script = espace.info_noeud(doc, section)
    cle = e.get("propriete")
    type_decl = _verifier_propriete_noeud(espace, res, type_, script, cle, e["valeur"])
    brut = valeur_fichier(espace, doc, res, f"{chemin}:{cle}", coercer(type_decl, e["valeur"]))
    poser_propriete(espace, section, type_, cle, brut, doc.fin_ligne())
    nettoyer_ressources(doc)
    espace.enregistrer(res, doc)


def op_attach_script(espace: Espace, e: dict) -> None:
    res, _, doc, section = espace.noeud(e.get("noeud"))
    script = e.get("script")
    contenu = e.get("contenu")
    if contenu is not None:
        if not isinstance(script, str) or not script.startswith("res://") or not script.endswith(".gd"):
            raise ErreurEdit(f"script : chemin res://….gd attendu ({script!r})", "valeur_invalide", res)
        if espace.projet.existe(script):
            raise ErreurEdit(f"{script} existe déjà : retirer « contenu » pour l'attacher tel quel", "valeur_invalide", script)
        if not isinstance(contenu, str) or not contenu.strip():
            raise ErreurEdit("contenu : texte GDScript attendu", "valeur_invalide", script)
        espace.ecrire(script, contenu if contenu.endswith("\n") else contenu + "\n")
    type_, _ = espace.info_noeud(doc, section)
    _verifier_script(espace, res, script, type_)
    brut = f"ExtResource({echapper(assurer_externe(doc, script, 'Script'))})"
    poser_propriete(espace, section, type_, "script", brut, doc.fin_ligne())
    nettoyer_ressources(doc)
    espace.enregistrer(res, doc)


def _connexion(espace: Espace, e: dict) -> tuple[str, Document, str, str]:
    res_s, chemin_s, doc, s_src = espace.noeud(e.get("source"))
    res_c, chemin_c, _, s_cib = espace.noeud(e.get("cible"))
    if res_s != res_c:
        raise ErreurEdit("source et cible doivent être dans la même scène", "invalid_node_path", res_s)
    for cle in ("signal", "methode"):
        if not isinstance(e.get(cle), str) or not _IDENTIFIANT.match(e[cle]):
            raise ErreurEdit(f"{cle} : identifiant attendu ({e.get(cle)!r})", "valeur_invalide", res_s)
    return res_s, doc, chemin_s, chemin_c


def _trouver_connexion(doc: Document, signal: str, source: str, cible: str, methode: str) -> Section | None:
    for s in doc.de_balise("connection"):
        if (s.attribut("signal"), s.attribut("from"), s.attribut("to"), s.attribut("method")) == (signal, source, cible, methode):
            return s
    return None


def op_connect(espace: Espace, e: dict) -> None:
    res, doc, source, cible = _connexion(espace, e)
    s_src = next(s for s in doc.de_balise("node") if chemin_section(s) == source)
    s_cib = next(s for s in doc.de_balise("node") if chemin_section(s) == cible)
    t_src, sc_src = espace.info_noeud(doc, s_src)
    t_cib, sc_cib = espace.info_noeud(doc, s_cib)
    nb = espace.verif.signal_arguments(t_src, sc_src, e["signal"])
    if nb is None:
        raise ErreurEdit(f"signal inconnu {e['signal']!r} sur {e['source']} ({t_src})", "signal_missing", res)
    arite = espace.verif.methode_arite(t_cib, sc_cib, e["methode"])
    if arite is None:
        raise ErreurEdit(f"méthode inconnue {e['methode']!r} sur {e['cible']} ({t_cib})", "vocab_inconnu", res)
    binds = e.get("binds", [])
    unbinds = e.get("unbinds", 0)
    if not isinstance(binds, list) or not isinstance(unbinds, int) or isinstance(unbinds, bool) or unbinds < 0:
        raise ErreurEdit("binds : liste ; unbinds : entier ≥ 0", "valeur_invalide", res)
    n_args = nb - unbinds + len(binds)
    mini, maxi = arite
    if n_args < 0 or n_args < mini or (maxi is not None and n_args > maxi):
        raise ErreurEdit(f"arité : {e['signal']} fournit {n_args} argument(s), {e['methode']} en attend {mini}"
                         + ("" if maxi == mini else f" à {maxi if maxi is not None else '∞'}"), "type_error", res)
    if _trouver_connexion(doc, e["signal"], source, cible, e["methode"]):
        raise ErreurEdit("cette connexion existe déjà", "valeur_invalide", res)
    attributs = [("signal", echapper(e["signal"])), ("from", echapper(source)), ("to", echapper(cible)),
                 ("method", echapper(e["methode"]))]
    if "flags" in e:
        if not isinstance(e["flags"], int) or isinstance(e["flags"], bool):
            raise ErreurEdit("flags : entier attendu", "valeur_invalide", res)
        attributs.append(("flags", str(e["flags"])))
    if unbinds:
        attributs.append(("unbinds", str(unbinds)))
    if binds:
        verifier_valeur(espace, res, "binds", None, binds)
        attributs.append(("binds", ecrire_valeur(binds)))
    section = nouvelle_section("connection", attributs, doc.fin_ligne())
    conns = doc.de_balise("connection")
    if conns:
        index = doc.index(conns[-1]) + 1
    else:
        index = doc.index(doc.de_balise("node")[-1]) + 1
    inserer_section(doc, index, section)
    espace.enregistrer(res, doc)


def op_disconnect(espace: Espace, e: dict) -> None:
    res, doc, source, cible = _connexion(espace, e)
    s = _trouver_connexion(doc, e["signal"], source, cible, e["methode"])
    if s is None:
        raise ErreurEdit(f"connexion introuvable : {e['source']}.{e['signal']} → {e['cible']}.{e['methode']}", "id_inconnu", res)
    retirer_section(doc, s)
    espace.enregistrer(res, doc)


# --------------------------------------------------------------------------- opérations sur les scripts

def _script(espace: Espace, e: dict):
    res = e.get("script")
    if not isinstance(res, str) or not res.startswith("res://") or not res.endswith(".gd"):
        raise ErreurEdit(f"script : chemin res://….gd attendu ({res!r})", "id_inconnu")
    if not espace.projet.existe(res):
        raise ErreurEdit(f"script introuvable : {res}", "id_inconnu", res)
    return res, espace.projet.script(res)


def _fin_ligne_script(lignes: list[str]) -> str:
    return "\r\n" if lignes and lignes[0].endswith("\r\n") else "\n"


def op_add_signal(espace: Espace, e: dict) -> None:
    res, s = _script(espace, e)
    nom = e.get("signal")
    if not isinstance(nom, str) or not _IDENTIFIANT.match(nom):
        raise ErreurEdit(f"nom de signal invalide : {nom!r}", "valeur_invalide", res)
    chaine, base = espace.projet.chaine_scripts(res)
    if any(x.signal(nom) for x in chaine) or (base and espace.verif.vocab.existe(base, nom, "signal")):
        raise ErreurEdit(f"le signal {nom!r} existe déjà (script ou classe {base})", "valeur_invalide", res)
    morceaux = []
    for a in e.get("arguments", []):
        if isinstance(a, str):
            a_nom, _, a_type = (x.strip() for x in a.partition(":"))
        elif isinstance(a, dict):
            a_nom, a_type = a.get("nom", ""), (a.get("type") or "")
        else:
            raise ErreurEdit("arguments : liste de {nom, type} attendue", "valeur_invalide", res)
        if not _IDENTIFIANT.match(a_nom or ""):
            raise ErreurEdit(f"nom d'argument invalide : {a_nom!r}", "valeur_invalide", res)
        if a_type and not espace.verif.type_connu(a_type):
            raise ErreurEdit(f"type inconnu : {a_type!r}", "vocab_inconnu", res)
        morceaux.append(a_nom + (f": {a_type}" if a_type else ""))
    lignes = list(s.lignes)
    fl = _fin_ligne_script(lignes)
    ligne = f"signal {nom}" + (f"({', '.join(morceaux)})" if morceaux else "") + fl
    if s.signaux:
        position = s.signaux[-1].ligne + 1
        lignes.insert(position, ligne)
    else:
        position = s.fin_entete
        insertion = [fl, ligne] if position > 0 else [ligne]
        if position < len(lignes) and lignes[position].strip():
            insertion.append(fl)
        lignes[position:position] = insertion
    espace.ecrire(res, "".join(lignes))


def _code_fonction(code: Any, lieu: str) -> tuple[str, str]:
    if not isinstance(code, str) or not code.strip():
        raise ErreurEdit("code : texte GDScript attendu", "valeur_invalide", lieu)
    premiere = next(l for l in code.replace("\r\n", "\n").split("\n") if l.strip())
    m = _FUNC.match(premiere.strip())
    if not m:
        raise ErreurEdit("code : doit commencer par « func nom(...) »", "valeur_invalide", lieu)
    analyse = lire_script(code.strip("\n") + "\n")
    if len(analyse.fonctions) != 1:
        raise ErreurEdit("code : une seule fonction de premier niveau attendue", "valeur_invalide", lieu)
    return m.group(2), code


def op_add_function(espace: Espace, e: dict) -> None:
    res, s = _script(espace, e)
    nom, code = _code_fonction(e.get("code"), res)
    if s.fonction(nom):
        raise ErreurEdit(f"la fonction {nom!r} existe déjà dans {res} (replace_function)", "valeur_invalide", res)
    lignes = list(s.lignes)
    fl = _fin_ligne_script(lignes)
    if lignes and not lignes[-1].endswith(("\n", "\r")):
        lignes[-1] += fl
    vides = 0
    for l in reversed(lignes):
        if l.strip():
            break
        vides += 1
    lignes.extend([fl] * max(0, 2 - vides) if lignes else [])
    nouvelles = [l.replace("\n", fl) for l in reindenter(code, unite_indentation(s.lignes), 0)]
    espace.ecrire(res, "".join(lignes + nouvelles))


def op_replace_function(espace: Espace, e: dict) -> None:
    res, s = _script(espace, e)
    nom = e.get("fonction")
    f = s.fonction(nom) if isinstance(nom, str) else None
    if f is None:
        raise ErreurEdit(f"fonction inconnue {nom!r} dans {res}", "id_inconnu", res)
    unite = unite_indentation(s.lignes)
    lignes = list(s.lignes)
    fl = _fin_ligne_script(lignes)
    if "code" in e:
        nom_code, code = _code_fonction(e["code"], res)
        if nom_code != nom:
            raise ErreurEdit(f"code : la fonction s'appelle {nom_code!r}, {nom!r} attendu", "valeur_invalide", res)
        nouvelles = [l.replace("\n", fl) for l in reindenter(code, unite, 0)]
        lignes[f.ligne_debut:f.ligne_fin] = nouvelles
    else:
        corps = e.get("corps")
        if not isinstance(corps, str) or not corps.strip():
            raise ErreurEdit("replace_function : « corps » (ou « code ») attendu", "valeur_invalide", res)
        nouvelles = [l.replace("\n", fl) for l in reindenter(corps, unite, 1)]
        if f.une_ligne:
            ligne = lignes[f.ligne_debut]
            texte_sig = ligne.rstrip("\r\n")
            # Le « : » de la signature est le premier après la parenthèse fermante.
            coupure = texte_sig.index(":", texte_sig.rindex(")"))
            lignes[f.ligne_debut:f.ligne_debut + 1] = [texte_sig[:coupure + 1] + fl] + nouvelles
        else:
            lignes[f.ligne_corps:f.ligne_fin] = nouvelles
    espace.ecrire(res, "".join(lignes))


# --------------------------------------------------------------------------- ressources

def op_set_resource_value(espace: Espace, e: dict) -> None:
    cible = e.get("ressource")
    cle = e.get("propriete")
    if "valeur" not in e or not isinstance(cle, str) or not cle:
        raise ErreurEdit("set_resource_value : « propriete » et « valeur » attendus", "valeur_invalide")
    if not isinstance(cible, str) or not cible:
        raise ErreurEdit("ressource : chemin res://….tres ou <id de nœud>#<propriété> attendu", "id_inconnu")
    if "#" in cible:
        ident, _, prop_noeud = cible.partition("#")
        res, chemin, doc, section = espace.noeud(ident)
        entree = section.propriete(prop_noeud)
        valeur = entree.valeur if entree is not None else None
        if isinstance(valeur, dict) and len(valeur) == 1 and type_cle(valeur) == "ExtResource":
            cible = ext_par_id(doc).get(valeur["ExtResource"], "")
        elif isinstance(valeur, dict) and len(valeur) == 1 and type_cle(valeur) == "SubResource":
            sub = next((s for s in doc.de_balise("sub_resource") if s.attribut("id") == valeur["SubResource"]), None)
            if sub is None:
                raise ErreurEdit(f"ressource interne introuvable pour {e['ressource']!r}", "id_inconnu", res)
            type_ = sub.attribut("type")
            existe, type_decl, _ = espace.verif.type_propriete(type_, None, cle)
            if not existe:
                raise ErreurEdit(f"propriété inconnue {cle!r} pour {type_}", "vocab_inconnu", res)
            verifier_valeur(espace, res, cle, type_decl, e["valeur"])
            brut = valeur_fichier(espace, doc, res, f"{chemin}:{prop_noeud}/{cle}", coercer(type_decl, e["valeur"]))
            sub.definir_propriete(cle, brut, fin_ligne=doc.fin_ligne())
            nettoyer_ressources(doc)
            espace.enregistrer(res, doc)
            return
        else:
            raise ErreurEdit(f"{e['ressource']!r} ne désigne pas une ressource (propriété absente ou non ressource)",
                             "id_inconnu", res)
    if not cible.startswith("res://") or not cible.endswith(".tres"):
        raise ErreurEdit(f"ressource : fichier .tres attendu ({cible!r})", "id_inconnu")
    doc = espace.document(cible)
    if not doc.sections or doc.sections[0].balise != "gd_resource":
        raise ErreurEdit(f"{cible} n'est pas une ressource texte", "valeur_invalide", cible)
    section = next((s for s in doc.sections if s.balise == "resource"), None)
    if section is None:
        raise ErreurEdit(f"{cible} : section [resource] absente", "valeur_invalide", cible)
    type_ = doc.sections[0].attribut("type")
    script = None
    entree = section.propriete("script")
    if entree is not None and isinstance(entree.valeur, dict) and "ExtResource" in entree.valeur:
        script = ext_par_id(doc).get(entree.valeur["ExtResource"])
    if cle == "script":
        raise ErreurEdit("on ne change pas le script d'une ressource ici", "valeur_invalide", cible)
    existe, type_decl, _ = espace.verif.type_propriete(type_, script, cle)
    if not existe:
        raise ErreurEdit(f"propriété inconnue {cle!r} pour {type_}" + (f" + {script}" if script else ""), "vocab_inconnu", cible)
    verifier_valeur(espace, cible, cle, type_decl, e["valeur"])
    brut = valeur_fichier(espace, doc, cible, f"resource/{cle}", coercer(type_decl, e["valeur"]))
    if section.propriete(cle) is None and section.propriete("script") is not None and _rang_propriete(espace, type_, cle) == "native":
        section.definir_propriete(cle, brut, avant="script", fin_ligne=doc.fin_ligne())
    else:
        section.definir_propriete(cle, brut, fin_ligne=doc.fin_ligne())
    nettoyer_ressources(doc)
    espace.enregistrer(cible, doc)


APPLICATEURS: dict[str, Callable[[Espace, dict], None]] = {
    "add_node": op_add_node, "del_node": op_del_node, "set_property": op_set_property,
    "attach_script": op_attach_script, "connect": op_connect, "disconnect": op_disconnect,
    "add_signal": op_add_signal, "add_function": op_add_function, "replace_function": op_replace_function,
    "set_resource_value": op_set_resource_value,
}


# --------------------------------------------------------------------------- validation + application

def preparer_edits(projet: Path, edits: list[dict], vocab=None) -> tuple[Espace, list[dict[str, Any]]]:
    """Applique les éditions en mémoire. Renvoie (espace, erreurs) ; erreurs vide si tout est accepté."""
    if vocab is None:
        from usine.vocab import ouvrir
        vocab = ouvrir()
    espace = Espace(Path(projet), vocab)
    if isinstance(edits, dict) and "edits" in edits:
        edits = edits["edits"]
    if not isinstance(edits, list):
        return espace, [{"edit": None, "op": None, "fichier": None, "ligne": None, "categorie": "valeur_invalide",
                         "message": "liste d'éditions attendue"}]
    for n, e in enumerate(edits):
        op = e.get("op") if isinstance(e, dict) else None
        try:
            if op not in APPLICATEURS:
                raise ErreurEdit(f"opération inconnue : {op!r} (attendu : {', '.join(OPERATIONS)})", "valeur_invalide")
            APPLICATEURS[op](espace, e)
        except ErreurEdit as exc:
            return espace, [{"edit": n, "op": op, "fichier": exc.fichier, "ligne": None, "categorie": exc.categorie,
                             "message": f"édit {n} ({op}) refusé : {exc.message}"
                                        + (" ; éditions suivantes non examinées" if n + 1 < len(edits) else "")}]
    return espace, []


def _a_des_tests(copie: Path) -> bool:
    dossier = copie / "tests"
    return dossier.is_dir() and any(dossier.rglob("*.gd"))


def _remplacer_atomiquement(racine: Path, nouveaux: dict[str, str], attendus: dict[str, str | None]) -> None:
    """Écrit chaque fichier par un fichier temporaire voisin puis os.replace ; restaure en cas d'échec."""
    chemins = {res: res_vers_disque(racine, res) for res in nouveaux}
    for res, chemin in chemins.items():
        actuel = lire_texte(chemin) if chemin.is_file() else None
        if actuel != attendus[res]:
            raise RuntimeError(f"{res} a changé pendant l'édition : rien n'est remplacé")
    temporaires: dict[str, Path] = {}
    faits: list[str] = []
    try:
        for res, chemin in chemins.items():
            chemin.parent.mkdir(parents=True, exist_ok=True)
            fd, tmp = tempfile.mkstemp(prefix=f".{chemin.name}.", suffix=".usine_nouveau", dir=chemin.parent)
            with os.fdopen(fd, "w", encoding="utf-8", newline="") as f:
                f.write(nouveaux[res])
            temporaires[res] = Path(tmp)
        for res, chemin in chemins.items():
            os.replace(temporaires[res], chemin)
            del temporaires[res]
            faits.append(res)
    except BaseException:
        for res in faits:
            ancien = attendus[res]
            chemin = chemins[res]
            if ancien is None:
                chemin.unlink(missing_ok=True)
            else:
                fd, tmp = tempfile.mkstemp(prefix=f".{chemin.name}.", suffix=".usine_restaure", dir=chemin.parent)
                with os.fdopen(fd, "w", encoding="utf-8", newline="") as f:
                    f.write(ancien)
                os.replace(tmp, chemin)
        raise
    finally:
        for tmp in temporaires.values():
            tmp.unlink(missing_ok=True)


def apply_edits(projet: Path, edits: list[dict], etapes=ETAPES, vocab=None, godot: Path | None = None) -> dict[str, Any]:
    """Applique `edits` à `projet`, tout ou rien. Renvoie un verdict étendu :

    {"ok", "applique", "etape", "duree_s", "erreurs", "tests", "fichiers"}
    - refus d'un édit : etape="validation", rien n'est écrit ;
    - juge en échec : etape = celle du juge, la copie de travail est jetée ;
    - succès : applique=True, `fichiers` liste les fichiers remplacés.
    """
    debut = time.monotonic()
    projet = Path(projet)
    verdict: dict[str, Any] = {"ok": False, "applique": False, "etape": "validation", "duree_s": 0.0,
                               "erreurs": [], "tests": {"total": 0, "passes": 0, "echecs": []}, "fichiers": []}
    espace, erreurs = preparer_edits(projet, edits, vocab)
    if erreurs:
        verdict["erreurs"] = erreurs
        verdict["duree_s"] = round(time.monotonic() - debut, 3)
        return verdict
    modifies = {res: t for res, t in espace.fichiers.items() if t != espace.originaux.get(res)}
    verdict["fichiers"] = sorted(modifies)
    with tempfile.TemporaryDirectory(prefix="usine_edits_") as tmp:
        copie = preparer_copie(projet, Path(tmp) / "projet")
        for res, texte in modifies.items():
            chemin = res_vers_disque(copie, res)
            chemin.parent.mkdir(parents=True, exist_ok=True)
            with chemin.open("w", encoding="utf-8", newline="") as f:
                f.write(texte)
        etapes = [x for x in etapes if x != "run_tests" or _a_des_tests(copie)]
        if etapes:
            jugement = juger_sur_place(copie, etapes=etapes, godot=godot)
            verdict.update({k: jugement[k] for k in ("etape", "erreurs", "tests")})
            if not jugement["ok"]:
                verdict["duree_s"] = round(time.monotonic() - debut, 3)
                return verdict
        else:
            verdict["etape"] = "aucune"
    try:
        _remplacer_atomiquement(projet, modifies, {res: espace.originaux.get(res) for res in modifies})
    except (OSError, RuntimeError) as exc:
        verdict["etape"] = "ecriture"
        verdict["erreurs"] = [{"fichier": None, "ligne": None, "categorie": "autre", "message": str(exc)}]
        verdict["duree_s"] = round(time.monotonic() - debut, 3)
        return verdict
    verdict["ok"] = True
    verdict["applique"] = True
    verdict["duree_s"] = round(time.monotonic() - debut, 3)
    return verdict
