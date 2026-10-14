"""Ce que les sessions de débogage disent d'une erreur : sortie de Godot compactée, lecture de l'extrait d'un
shader, explication sourcée de chaque sorte d'erreur, motif pour chercher la même faute ailleurs."""

from __future__ import annotations

import re

from usine.cours.base import api, mutations, preuves


def compacter(texte: str, garder: int = 2, pile: int = 3) -> str:
    """Une erreur répétée à chaque construction : on garde les premières (pile d'appels raccourcie),
    puis on dit combien de fois elle revient. Les autres lignes restent telles quelles."""
    blocs: list[list[str]] = []
    for l in texte.splitlines():
        if l.startswith(("SCRIPT ERROR", "ERROR", "SHADER ERROR", "WARNING", "ok", "ÉCHEC", "--res://")) or not blocs:
            blocs.append([l])
        else:
            blocs[-1].append(l)
    sortie: list[str] = []
    vus: dict[str, int] = {}
    for b in blocs:
        cle = "\n".join(b[:2])
        vus[cle] = vus.get(cle, 0) + 1
        if vus[cle] > garder:
            continue
        if any("backtrace" in l for l in b):
            i = next(i for i, l in enumerate(b) if "backtrace" in l)
            reste = b[i + 1:]
            b = b[:i + 1] + reste[:pile] + (["              [...]"] if len(reste) > pile else [])
        sortie += b
    extra = sum(n - garder for n in vus.values() if n > garder)
    if extra:
        sortie.append(f"[… les mêmes erreurs reviennent encore {extra} fois dans la sortie]")
    return "\n".join(sortie)

def lecture_extrait_shader(texte: str, res: str, ligne: int, faute: str, fichier: str = "") -> str:
    """Godot montre le code du shader autour d'une flèche « E ». Quand ce code est décalé par rapport au
    fichier (on le constate dans la sortie elle-même), on le dit : le numéro sûr est celui de « at: ».
    Essai fait avec Godot 4.7.2 (Compatibilité) : le même shader fautif, sans `#include`, a sa flèche sur la
    bonne ligne ; avec un `#include` au-dessus, le code affiché glisse d'une ligne, « at: » reste juste."""
    inclus = sum(1 for l in fichier.split("\n")[:ligne - 1] if l.strip().startswith("#include"))
    cause = (" Ce décalage vient du `#include` placé plus haut dans le shader." if inclus == 1 else
             f" Ce décalage vient des {inclus} `#include` placés plus haut dans le shader : chacun décale l'extrait "
             "d'une ligne." if inclus > 1 else "")
    morceaux = re.split(r"^--(res://\S+?)--$", texte, flags=re.M)
    for i in range(1, len(morceaux) - 1, 2):
        if morceaux[i] != res:
            continue
        fleche, montree = None, None
        for l in morceaux[i + 1].splitlines():
            m = re.match(r"^(E)?\s*(\d+)\s?(?:\||->)(.*)$", l)
            if not m:
                continue
            if m.group(1):
                fleche = int(m.group(2))
            if faute.strip() and m.group(3).strip() == faute.strip() and montree is None:
                montree = int(m.group(2))
        if montree is None or montree == ligne:
            return ""
        if fleche == ligne and montree == ligne + 1:
            return (f" Attention à l'extrait de code que Godot affiche : la flèche `E` porte bien le numéro {ligne}, mais le "
                    f"code à côté d'elle est décalé d'une ligne ; la ligne fautive apparaît juste en dessous, sous le numéro "
                    f"{montree}. Le numéro sûr est celui de la ligne « at: » : ligne {ligne} du fichier." + cause)
        return (f" Attention à l'extrait de code que Godot affiche : la ligne fautive y porte le numéro {montree}, pas "
                f"{ligne}. Le numéro sûr est celui de la ligne « at: » : ligne {ligne} du fichier." + cause)
    return ""

def explication(m: mutations.Mutation) -> list[str]:
    d = m.detail
    if m.genre == "godot3_annotation":
        doc = preuves.DOC_EXPORT if d["mot"] == "export" else preuves.DOC_ONREADY
        return [f"En Godot 4, `{d['mot']}` est une annotation : elle s'écrit `@{d['mot']}`. La forme sans `@` est celle de "
                "Godot 3 ; Godot 4.7.2 ne la reconnaît plus, et tout le script refuse de se charger.",
                "- " + preuves.citation(doc)]
    if m.genre in ("godot3_nom", "godot3_shader"):
        lignes = []
        table = preuves.renommage_de(d["ancien"])
        if m.genre == "godot3_nom" and d.get("sorte") == "méthode":
            absent = all(api.membre(c, d["ancien"]) is None for c in ("RandomNumberGenerator", "Object", "Node", "Array", "String", "ShaderMaterial", "PackedScene"))
            sig = next((api.membre(c, d["neuf"])[0] for c in ("RandomNumberGenerator", "Array", "String", "ShaderMaterial", "PackedScene")
                        if api.membre(c, d["neuf"])), None) or api.utilitaire(d["neuf"])
            lignes.append(f"`{d['ancien']}` n'existe pas dans l'API de Godot 4.7.2" + (" (aucune classe ne l'a)" if absent else "")
                          + f" ; le nom actuel est `{d['neuf']}`" + (f" : `{sig}`." if sig else "."))
        elif m.genre == "godot3_nom":
            existe = api.classe_existe(d["ancien"])
            lignes.append(f"`{d['ancien']}` " + ("existe encore, mais n'est pas la classe voulue" if existe else
                                                    "n'est plus une classe de Godot 4.7.2")
                          + f" ; la classe s'appelle `{d['neuf']}` : « {api.description_classe(d['neuf'])} »")
        else:
            lignes.append(f"`{d['ancien']}` est le nom de Godot 3 ; dans un shader de Godot 4, c'est `{d['neuf']}`.")
        if table:
            lignes.append(f"- {preuves.SOURCE_RENOMS} : `{table[0]}`"
                          + (f" (pour un `float`, Godot 4 a aussi `{d['neuf']}`)" if table[1] != d["neuf"] else "") + ".")
        if d["ancien"] == "hint_color":
            lignes.append("- *Upgrading from Godot 3 to Godot 4* (documentation de Godot) : « `hint_color` is now `source_color`. »")
        return lignes
    if m.genre == "non_type":
        return [f"La variable `{d['nom']}` n'a pas de type. Le projet traite l'avertissement `UNTYPED_DECLARATION` comme une "
                "erreur : toute déclaration doit dire son type.",
                "- " + preuves.citation(preuves.DOC_UNTYPED)]
    if m.genre == "type":
        return [f"`{d['nom']}` est déclarée `int`, mais reçoit une valeur `float` : la partie décimale serait perdue. Le projet "
                "traite cet avertissement (`NARROWING_CONVERSION`) comme une erreur. La valeur doit rester un `float`."]
    if m.genre == "appel":
        return [f"Le script n'a aucune fonction `{d['ancien']}` : celle qui existe s'appelle `{d['neuf']}`. C'est une faute de nom, "
                "pas un problème d'API de Godot."]
    if m.genre == "shader_litteral":
        return [f"`{d['entier']}` est un entier ; l'opération attend un `float`. Le langage des shaders de Godot ne convertit pas "
                f"de lui-même : il faut écrire `{d['litteral']}`.",
                "- " + preuves.citation(preuves.DOC_CAST)]
    return []

def motif_faute(m: mutations.Mutation) -> str | None:
    d = m.detail
    if m.genre == "godot3_annotation":
        return r"^\s*(export|onready)\s+var\b"
    if m.genre == "godot3_nom":
        return rf"\b{d['ancien']}\(" if d.get("sorte") == "méthode" else rf"\b{d['ancien']}\b"
    if m.genre == "godot3_shader":
        return rf"\b{d['ancien']}\b"
    if m.genre == "non_type":
        return r"^\s*var \w+ = "
    if m.genre == "appel":
        return rf"\b{d['ancien']}\("
    return None


GENRES = ["godot3_nom", "godot3_annotation", "godot3_shader", "shader_litteral", "type", "appel", "non_type"]
