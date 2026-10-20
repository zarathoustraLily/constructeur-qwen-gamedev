"""Découpe une grande étape en parties qui se compilent chacune : les morceaux sont rangés pour que toute
déclaration arrive avant son premier emploi, puis empaquetés jusqu'à une taille donnée."""
from __future__ import annotations

import heapq
import re
import sys

from usine.cours.base.etat import CODE, Morceau

# La forme des shaders d'abord : « const int ROOM_OFFICE = 0; » prise pour le `const NOM` de GDScript donnait le nom
# « int » (newyorkais 010 : une constante nouvelle du fichier inclus, employée avant d'exister).
DECL = re.compile(r"^(?:uniform|varying|const)\s+(?:\w+\s+)*?\w+\s+(\w+)\s*[;=:\[]"
                  r"|^(?:@\w+(?:\((?:[^()\"]|\"[^\"]*\")*\))?\s+)*(?:static\s+)?(?:var|const|func|class|enum|signal)\s+(\w+)"
                  r"|^(?:float|int|vec2|vec3|vec4|bool|mat3|mat4|void)\s+(\w+)\s*\(")
MOT = re.compile(r"[A-Za-z_]\w*")
INCLUDE = re.compile(r'^\s*#include\s+"res://([^"]+)"')
LOCALE = re.compile(r"^\s+(?:const\s+)?(?:float|int|uint|vec2|vec3|vec4|ivec2|ivec3|bool|mat3|mat4)\s+(\w+)\s*[=;]"
                    r"|^\s+(?:var|const)\s+(\w+)|^\s*for\s+(\w+)")
FONCTION = re.compile(r"^(?:static\s+)?func\s+(\w+)|^(?:float|int|vec2|vec3|vec4|bool|mat3|mat4|void)\s+(\w+)\s*\(")


def locales(lignes: list[str]) -> set[str]:
    noms = set()
    for l in lignes:
        m = LOCALE.match(l)
        if m:
            noms.add(next(g for g in m.groups() if g))
    return noms


def fonctions_par_ligne(texte: str) -> list[str]:
    """Pour chaque ligne du fichier, la fonction de premier niveau qui la contient (ou « »)."""
    courante = ""
    sortie = []
    for l in texte.split("\n"):
        m = FONCTION.match(l)
        if m:
            courante = next(g for g in m.groups() if g)
        elif l and not l[0].isspace() and not l.startswith(("#", "//", "}", "@", "##")):
            courante = ""
        sortie.append(courante)
    return sortie


AVERTI = re.compile(r"^(?:@\w+(?:\((?:[^()\"]|\"[^\"]*\")*\))?\s+)*(?:(?:static\s+)?var\s+(_\w+)|signal\s+(\w+))")


def _variable_ou_signal(ligne: str) -> str | None:
    """Le nom d'une variable membre privée (« var _x ») ou d'un signal déclaré sur cette ligne."""
    m = AVERTI.match(ligne)
    return (m.group(1) or m.group(2)) if m else None


def signatures(texte: str) -> dict[str, tuple[int, int, str]]:
    """Chaque déclaration de premier niveau : (sa première ligne, la ligne qui suit sa signature, la signature).
    Une signature continue sur les lignes suivantes tant que ses parenthèses ne sont pas refermées."""
    lignes = texte.split("\n")
    sortie: dict[str, tuple[int, int, str]] = {}
    for i, l in enumerate(lignes):
        m = DECL.match(l)
        if not m:
            continue
        j, sig, ouvertes = i, l.strip(), l.count("(") - l.count(")")
        while ouvertes > 0 and j + 1 < len(lignes):
            j += 1
            sig += " " + lignes[j].strip()
            ouvertes += lignes[j].count("(") - lignes[j].count(")")
        sortie[next(g for g in m.groups() if g)] = (i, j + 1, sig)
    return sortie


def declarations(lignes: list[str]) -> set[str]:
    noms = set()
    for l in lignes:
        m = DECL.match(l)
        if m:
            noms.add(next(g for g in m.groups() if g))
    return noms


IGNORES = {"int", "float", "bool", "void", "fragment", "vertex", "light", "start", "process", "_ready", "_process"}


def emplois(lignes: list[str]) -> set[str]:
    mots = set()
    for l in lignes:
        code = l.split("#", 1)[0] if not l.lstrip().startswith("//") else ""
        code = code.split("//", 1)[0]
        mots |= set(MOT.findall(code))
    return mots - IGNORES


def emplois_pointes(lignes: list[str]) -> set[str]:
    """Les membres appelés à travers un objet (« x.nom ») : seuls ceux-là atteignent un autre script."""
    mots = set()
    for l in lignes:
        code = l.split("#", 1)[0].split("//", 1)[0]
        mots |= set(re.findall(r"\.([A-Za-z_]\w*)", code))
    return mots - IGNORES


def _tarjan(noeuds: list[int], aretes: dict[int, set[int]]) -> list[list[int]]:
    index, bas, pile, sur_pile, comps = {}, {}, [], set(), []
    compteur = [0]

    def visiter(v: int) -> None:
        index[v] = bas[v] = compteur[0]
        compteur[0] += 1
        pile.append(v)
        sur_pile.add(v)
        for w in aretes.get(v, ()):
            if w not in index:
                visiter(w)
                bas[v] = min(bas[v], bas[w])
            elif w in sur_pile:
                bas[v] = min(bas[v], index[w])
        if bas[v] == index[v]:
            comp = []
            while True:
                w = pile.pop()
                sur_pile.discard(w)
                comp.append(w)
                if w == v:
                    break
            comps.append(comp)

    sys.setrecursionlimit(10000)
    for v in noeuds:
        if v not in index:
            visiter(v)
    return comps


def ordre(tous: list[Morceau], affect: dict[int, int], avant: dict[str, str], rang_fichier,
          apres: dict[str, str] | None = None) -> list[list[int]]:
    """Groupes de morceaux (composantes) dans un ordre où chaque déclaration précède ses emplois."""
    deja = {rel: declarations(t.split("\n")) for rel, t in avant.items() if rel.endswith(CODE)}
    nouveaux = {m.id: declarations(m.nouvelles) - deja.get(m.fichier, set()) - IGNORES for m in tous}
    employes = {m.id: emplois(m.nouvelles) for m in tous}
    pointes = {m.id: emplois_pointes(m.nouvelles) for m in tous}
    shader = lambda rel: rel.endswith((".gdshader", ".gdshaderinc"))  # noqa: E731

    def atteint(a: Morceau, b: Morceau) -> set[str]:
        """Les noms nouveaux de b qu'emploie a, selon la portée : même fichier, membre pointé d'un autre
        script, ou fonction d'un fichier d'inclusion de shader."""
        if a.fichier == b.fichier:
            return nouveaux[b.id] & employes[a.id]
        if shader(a.fichier) and b.fichier.endswith(".gdshaderinc"):
            return nouveaux[b.id] & employes[a.id]
        if not shader(a.fichier) and not shader(b.fichier):
            return nouveaux[b.id] & pointes[a.id]
        return set()
    locs = {m.id: locales(m.nouvelles) for m in tous}
    # Ce qui avertit quand rien ne s'en sert (avertissement traité en erreur) : une variable membre privée
    # (UNUSED_PRIVATE_CLASS_VARIABLE) et un signal jamais émis (UNUSED_SIGNAL). Une fonction privée, non.
    avertis = {m.id: {x for l in m.nouvelles for x in [_variable_ou_signal(l)] if x} for m in tous}
    fonction: dict[int, str] = {}
    for m in tous:
        if apres and m.fichier in apres:
            par_ligne = fonctions_par_ligne(apres[m.fichier])
            # La première ligne de code du morceau : un commentaire de tête documente la fonction qui suit, il
            # n'appartient pas à celle qui précède.
            k = next((i for i, l in enumerate(m.nouvelles)
                      if l.strip() and not l.lstrip().startswith(("#", "//", "/*", "*"))), 0)
            fonction[m.id] = par_ligne[min(m.n1 + k, len(par_ligne) - 1)] if par_ligne else ""
        else:
            fonction[m.id] = ""
    dep: dict[int, set[int]] = {m.id: set() for m in tous}
    # Les variables locales qu'un morceau retire (déclarées dans ses anciennes lignes, plus dans les nouvelles).
    retirees = {m.id: locales(m.anciennes) - locs[m.id] for m in tous}
    for a in tous:
        for b in tous:
            meme_fonction = a.id != b.id and a.fichier == b.fichier and fonction[a.id] and fonction[a.id] == fonction[b.id]
            if meme_fonction and locs[b.id] & employes[a.id]:
                dep[a.id].add(b.id)
                dep[b.id].add(a.id)
            # Une locale retirée ici (newyorkais 007 : la boucle `for side` et son `var street` refaites plus bas) :
            # le morceau qui la redéclare, et ceux dont les anciennes lignes l'emploient encore, vont avec, sinon
            # l'état intermédiaire emploie une variable qui n'existe plus.
            if meme_fonction and retirees[a.id] & (locs[b.id] | emplois(b.anciennes)):
                dep[a.id].add(b.id)
                dep[b.id].add(a.id)
            # Une déclaration déplacée dans le fichier (retirée ici, ajoutée là) : les deux morceaux vont ensemble,
            # sinon la fonction existerait deux fois, ou plus du tout.
            if a.id != b.id and a.fichier == b.fichier and \
                    (declarations(a.nouvelles) - declarations(a.anciennes)) & (declarations(b.anciennes) - declarations(b.nouvelles)):
                dep[a.id].add(b.id)
                dep[b.id].add(a.id)
            communs = atteint(a, b)
            if a.id != b.id and communs:
                dep[a.id].add(b.id)
                # Une variable privée ou un signal déclarés sans emploi font un avertissement (traité en erreur) :
                # la déclaration et son premier emploi vont ensemble.
                if communs & avertis[b.id] and a.fichier == b.fichier:
                    dep[b.id].add(a.id)
    # Les morceaux d'un même fichier gardent leur ordre quand ils s'insèrent au même endroit.
    par_place: dict[tuple[str, int], list[Morceau]] = {}
    for m in tous:
        par_place.setdefault((m.fichier, m.a1), []).append(m)
    for liste in par_place.values():
        liste.sort(key=lambda m: m.n1)
        for x, y in zip(liste, liste[1:]):
            dep[y.id].add(x.id)
    # Signature changée : la définition et tous ses appels vont ensemble. Les signatures vraiment changées : leur
    # texte, lignes de suite comprises, diffère entre l'ancien et le nouveau fichier.
    sig_avant = {rel: signatures(t) for rel, t in avant.items() if rel.endswith(CODE)}
    sig_apres = {rel: signatures(t) for rel, t in (apres or {}).items() if rel.endswith(CODE)}
    signatures_changees: dict[str, set[str]] = {}
    for rel in {m.fichier for m in tous}:
        vieux, neuf = sig_avant.get(rel, {}), sig_apres.get(rel, {})
        signatures_changees[rel] = {x for x in vieux if x not in neuf or vieux[x][2] != neuf[x][2]}

    def touche(debut: int, fin: int, plage: tuple[int, int, str]) -> bool:
        """Les lignes [debut, fin) du morceau (ou son point d'insertion) tombent dans la signature."""
        return debut < plage[1] and plage[0] < fin if debut < fin else plage[0] < debut < plage[1]

    for b in tous:
        # Un morceau change une signature s'il touche ses lignes : la première, ou une ligne de suite (newyorkais
        # 010 : `room_view` gagne deux paramètres sur la deuxième ligne de sa signature).
        vieux, neuf = sig_avant.get(b.fichier, {}), sig_apres.get(b.fichier, {})
        changees = {x for x in signatures_changees.get(b.fichier, set())
                    if (x in vieux and touche(b.a1, b.a2, vieux[x])) or (x in neuf and touche(b.n1, b.n2, neuf[x]))}
        if not changees:
            continue
        for a in tous:
            # Même portée que `atteint` : un `x.rect` de GDScript n'appelle pas la fonction `rect` d'un shader.
            if a.fichier == b.fichier or (shader(a.fichier) and b.fichier.endswith(".gdshaderinc")):
                vus = employes[a.id] | emplois(a.anciennes)
            elif not shader(a.fichier) and not shader(b.fichier):
                vus = pointes[a.id] | emplois_pointes(a.anciennes)
            else:
                continue
            if a.id != b.id and changees & vus:
                dep[a.id].add(b.id)
                dep[b.id].add(a.id)
    # Un `#include` ajouté à un shader y amène les déclarations du fichier inclus : celles que le shader déclarait
    # lui-même en partent dans la même partie, sinon elles existent deux fois (newyorkais 007 : la pièce derrière la
    # vitre passe du shader des fenêtres à un fichier partagé avec le mur-rideau).
    for i in tous:
        if not shader(i.fichier):
            continue
        inclus = {m.group(1) for l in i.nouvelles if (m := INCLUDE.match(l))} - \
            {m.group(1) for l in i.anciennes if (m := INCLUDE.match(l))}
        for rel in inclus:
            amenees = declarations((apres or {}).get(rel, "").split("\n"))
            for r in tous:
                if r.id != i.id and r.fichier == i.fichier and declarations(r.anciennes) & amenees:
                    dep[i.id].add(r.id)
                    dep[r.id].add(i.id)
    # Un fichier nouveau doit exister avant qu'on le charge (preload, load, chemin dans une chaîne).
    nouveaux_fichiers: dict[str, list[int]] = {}
    for m in tous:
        if m.fichier not in avant:
            nouveaux_fichiers.setdefault(m.fichier, []).append(m.id)
    for rel, ids in nouveaux_fichiers.items():
        base = rel.rsplit("/", 1)[-1]
        for a in tous:
            if a.fichier != rel and any(base in l for l in a.nouvelles):
                dep[a.id] |= set(ids)
    # Une variable nouvelle de l'étape : le morceau qui lui donne sa valeur passe avant ceux qui s'en servent
    # (sinon « Cannot call method … on a null value » à l'exécution).
    affectations = {m.id: {x for l in m.nouvelles for x in re.findall(r"^\s*([A-Za-z_]\w*)\s*=[^=]", l)} for m in tous}
    for a in tous:
        for b in tous:
            if a.id == b.id or a.fichier != b.fichier:
                continue
            communs = affectations[b.id] & employes[a.id] & {x for m in tous if m.fichier == a.fichier for x in nouveaux[m.id]}
            if communs and not (affectations[a.id] & communs):
                dep[a.id].add(b.id)
    for b in tous:
        for l in b.nouvelles:
            mf = re.match(r"^(?:static\s+)?func\s+(\w+)\s*\(([^)]*)\)", l)
            if not mf:
                continue
            params = {p.split(":")[0].split("=")[0].strip() for p in mf.group(2).split(",") if p.strip()}
            for a in tous:
                if a.id != b.id and a.fichier == b.fichier and fonction.get(a.id) == mf.group(1) and params & employes[a.id]:
                    dep[a.id].add(b.id)
                    dep[b.id].add(a.id)
    comps = _tarjan([m.id for m in tous], dep)
    par_id = {m.id: m for m in tous}
    comp_de = {v: i for i, c in enumerate(comps) for v in c}
    # Tri topologique des composantes, priorité : point de la note, fichier, place.
    entrants = {i: set() for i in range(len(comps))}
    for a, bs in dep.items():
        for b in bs:
            if comp_de[a] != comp_de[b]:
                entrants[comp_de[a]].add(comp_de[b])
    cle = {i: (min(affect[v] for v in c), min(rang_fichier(par_id[v].fichier) for v in c), min(par_id[v].n1 for v in c))
           for i, c in enumerate(comps)}
    prets = [(cle[i], i) for i, e in entrants.items() if not e]
    heapq.heapify(prets)
    fait: set[int] = set()
    sortie: list[list[int]] = []
    restants = {i: set(e) for i, e in entrants.items()}
    while prets:
        _, i = heapq.heappop(prets)
        if i in fait:
            continue
        fait.add(i)
        sortie.append(sorted(comps[i], key=lambda v: (rang_fichier(par_id[v].fichier), par_id[v].a1, par_id[v].n1)))
        for j, e in restants.items():
            if i in e:
                e.discard(i)
                if not e and j not in fait:
                    heapq.heappush(prets, (cle[j], j))
    assert len(fait) == len(comps)
    return sortie


def empaqueter(groupes: list[list[int]], tous: list[Morceau], affect: dict[int, int], textes_points: dict[int, int],
               budget: int) -> list[list[int]]:
    par_id = {m.id: m for m in tous}
    parties: list[list[int]] = [[]]
    taille = 0
    points_vus: set[int] = set()
    for g in groupes:
        t = sum(sum(len(l) + 1 for l in par_id[v].nouvelles + par_id[v].anciennes) for v in g)
        t += sum(textes_points.get(affect[v], 0) for v in {affect[v]: v for v in g}.values() if affect[v] not in points_vus)
        if parties[-1] and taille + t > budget:
            parties.append([])
            taille = 0
        parties[-1] += g
        taille += t
        points_vus |= {affect[v] for v in g}
    parties = [p for p in parties if p]
    # Une dernière partie minuscule rejoint la précédente.
    def taille_de(p: list[int]) -> int:
        return sum(sum(len(l) + 1 for l in par_id[v].nouvelles + par_id[v].anciennes) for v in p)
    # Pas `parties[-2] += parties.pop()` : la cible est lue avant le pop, puis réécrite un rang trop haut (l'avant-
    # dernière partie était perdue, la dernière en double).
    while len(parties) > 1 and taille_de(parties[-1]) < 2500:
        derniere = parties.pop()
        parties[-1] += derniere
    return parties
