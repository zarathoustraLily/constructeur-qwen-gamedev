"""Ce qui change d'un cours à l'autre dans la base : bâtiments procéduraux (le premier cours) ou cours « de jeu »
(le kart, le roguelike : usine/cours/jeu.py).

Demande de laurent du 2026-10-22 (« oui vas y ») : la même base, création et débogage à parts égales en jetons de
réponse, au format d'OpenCode, pour les deux cours de jeu. Différences avec les bâtiments, toutes relevées sur Godot
4.7.2 chez laurent :
- les tests sont des suites GdUnit4 (`extends GdUnitTestSuite`) que l'étape crée ou modifie ; on lance seulement
  celles-là, comme `7_tests/lancer_tests.bat` (sans `-d --remote-debug` : les suites passent sans débogueur, assertions
  sur `push_error` comprises, et la sortie n'a plus ses deux lignes ERROR de débogueur injoignable) ;
- `--check-only` ne connaît pas les autoloads (« Identifier not found: GameFlow » sur un script juste) : un script qui
  en emploie un n'est pas analysé seul, les tests le chargent avec tout le projet ;
- l'image : la scène principale (ou la scène qui emploie le shader), 60 images en Compatibilité, fenêtre hors de
  l'écran (choix de laurent pour les rendus) ; un shader fautif s'y signale (« SHADER ERROR »), comme au rendu des
  bâtiments ;
- on enseigne le code et les scènes et ressources texte de taille raisonnable ; les très gros fichiers (collisions,
  données VoxelGI, GridMap) sont donnés tels quels, comme l'outillage des bâtiments ;
- l'import de l'éditeur sans fenêtre peut afficher une erreur de son moteur de rendu factice
  (`servers/rendering/dummy/`), sans lien avec le projet : relevée au premier import du kart, avant toute
  modification (usine/cours/verifier.py). Elle reste dans la sortie (règle 5.1) ; la réponse la reconnaît ;
- en Compatibilité, Godot avertit que des réglages du projet faits pour Forward+ ne s'y appliquent pas (kart :
  « SDFGI is only available when using the Forward+ renderer. », flou de profondeur, traînées de particules ; relevé
  le 2026-10-22 sur le kart) : ce ne sont pas des erreurs de shader ; la réponse les lit et le dit.
"""

from __future__ import annotations

import re

from usine.cours.base import chemins

RESSOURCES = (".tscn", ".tres", ".godot")
# Au-delà, une scène ou une ressource est donnée, pas enseignée : une ligne plus longue (tableau de cellules d'une
# GridMap, forme de collision), ou plus de texte ajouté que n'en tient raisonnablement un exemple.
LIGNE_MAX = 1000
AJOUT_MAX = 12000
SUITE = re.compile(r"^extends\s+GdUnitTestSuite\b", re.M)
GDUNIT = "res://addons/gdUnit4/bin/GdUnitCmdTool.gd"
POSITION_HORS_ECRAN = "-10000,-10000"
IMAGES_RENDU = 60
# Erreurs du moteur, pas du projet : (message, lieu dans la ligne « at: » qui suit).
BENIGNES = [(re.compile(r'^ERROR: Parameter "material" is null\.$'),
             re.compile(r"^\s*at: material_get_instance_shader_parameters \(servers/rendering/dummy/")),
            (re.compile(r"^WARNING: .+ only available when using the Forward\+ (?:or Mobile )?renderer\.$"),
             re.compile(r"^\s*at: \w+ \((?:servers/rendering|drivers/gles3)/"))]
FORWARD = re.compile(r"^WARNING: (.+?) (?:is|are) only available when using the (Forward\+(?: or Mobile)?) renderer\.$")


def jeu() -> bool:
    return chemins.actuels().jeu


# --------------------------------------------------------------------------------------------- ce qu'on enseigne
def enseignables() -> tuple[str, ...]:
    """Les extensions des fichiers dont l'exemple écrit les changements."""
    from usine.cours.base.etat import CODE
    return CODE + RESSOURCES if jeu() else CODE


def raisonnable(avant: str | None, apres: str | None) -> bool:
    """Une scène ou une ressource assez courte pour être écrite dans un exemple."""
    if apres is None:
        return True
    anciennes = set((avant or "").split("\n"))
    ajout = sum(len(l) + 1 for l in apres.split("\n") if l not in anciennes)
    return ajout <= AJOUT_MAX and max((len(l) for l in apres.split("\n")), default=0) <= LIGNE_MAX


# --------------------------------------------------------------------------------------------- les tests
def suites(fichiers: dict[str, str], parmi: set[str] | None = None) -> list[str]:
    """Les suites GdUnit4 de `fichiers` (chemins relatifs), seulement celles de `parmi` s'il est donné."""
    return sorted(rel for rel, t in fichiers.items() if rel.startswith("7_tests/") and rel.endswith(".gd")
                  and (parmi is None or rel in parmi) and SUITE.search(t))


def arguments_gdunit(suites_res: list[str], ignorer: list[str] | None = None) -> list[str]:
    """Comme `7_tests/lancer_tests.bat`, sans le débogueur : ces suites seulement. `ignorer` : des cas écartés,
    « suite:cas » (option `-i` de GdUnit4 6.2.1, qui n'a pas d'option pour lancer un seul cas)."""
    # « -rc 1 » : un seul rapport, réécrit à chaque passage. Avec l'historique par défaut, GdUnit4 finit par
    # supprimer ses anciens rapports, et sous Windows la suppression échoue (« ERROR: Delete .godot/rapports_tests/
    # report_1/css/breadcrumb.css failed », relevé le 2026-10-22 en relançant les tests dans le même projet).
    args = ["--headless", "--path", ".", "--fixed-fps", "60", "-s", GDUNIT, "--ignoreHeadlessMode", "-c", "-rc", "1",
            "-rd", ".godot/rapports_tests"]
    for res in suites_res:
        args += ["-a", res]
    for cas in ignorer or []:
        args += ["-i", cas]
    return args + ["++", "cadence_fixe"]


RESUME = re.compile(r"^Overall Summary: (\d+) test cases \| (\d+) errors \| (\d+) failures \|")
CAS = re.compile(r"^\s*res://(\S+) > (\w+) (PASSED|FAILED)\b")


def resume_gdunit(texte: str) -> tuple[int, int, int] | None:
    """(cas, erreurs, échecs) de la ligne « Overall Summary », ou None."""
    m = next((RESUME.match(l.strip()) for l in texte.splitlines() if RESUME.match(l.strip())), None)
    return (int(m[1]), int(m[2]), int(m[3])) if m else None


def cas_passes(texte: str) -> list[str]:
    """Les cas qui passent, « suite > test », dans l'ordre de la sortie (sans leur durée, qui varie)."""
    return [f"{m[1]} > {m[2]}" for l in texte.splitlines() if (m := CAS.match(l)) and m[3] == "PASSED"]


ATTENDU = re.compile(r'\.is_push_(error|warning)\(\s*"((?:[^"\\]|\\.)*)"')


def messages_attendus(fichiers: dict[str, str]) -> set[str]:
    """Les lignes que les suites provoquent exprès : « ERROR: <message> » pour `is_push_error("<message>")`,
    « WARNING: <message> » pour `is_push_warning("<message>")`."""
    sortie = set()
    for rel, texte in fichiers.items():
        if rel.startswith("7_tests/") and rel.endswith(".gd"):
            for genre, message in ATTENDU.findall(texte):
                sortie.add(("ERROR: " if genre == "error" else "WARNING: ") + message.replace('\\"', '"'))
    return sortie


def erreurs_inattendues(texte: str, attendus: set[str] | frozenset[str] = frozenset()) -> list[str]:
    """Les lignes ERROR ou WARNING d'une sortie de GdUnit4 qu'aucun cas n'attendait. Un cas qui vérifie une erreur
    (`assert_error(…).is_push_error(…)`) la provoque exprès : sa pile d'appels passe par GdUnitGodotErrorAssertImpl,
    ou, quand elle part d'une coroutine, son message est celui que la suite attend (`attendus`, messages_attendus).
    Les autres viennent du jeu pendant les tests, et GdUnit4 ne fait échouer un cas que sur ses assertions."""
    lignes = texte.splitlines()
    benignes = lignes_benignes(texte)       # le moteur de rendu factice parle aussi pendant les tests sans fenêtre
    sortie = []
    for i, l in enumerate(lignes):
        if i in benignes or l in attendus or not re.match(r"^(ERROR|USER ERROR|WARNING|USER WARNING): ", l):
            continue
        pile = []
        for suite in lignes[i + 1:]:
            if not suite.startswith((" ", "\t")):
                break
            pile.append(suite)
        if not any("GdUnitGodotErrorAssertImpl" in p for p in pile):
            sortie.append(l)
    return sortie


def test_reussi(code: int, texte: str, attendus: set[str] | frozenset[str] = frozenset()) -> bool:
    r = resume_gdunit(texte)
    return (code == 0 and r is not None and r[0] > 0 and r[1] == 0 and r[2] == 0 and "SCRIPT ERROR" not in texte
            and not erreurs_inattendues(texte, attendus))


def phrase_cas(nom: str) -> str:
    """« test_la_premiere_carte_a_le_focus » → « la premiere carte a le focus » : le nom du test dit sa règle."""
    return nom.removeprefix("test_").replace("_", " ")


# --------------------------------------------------------------------------------------------- l'import
def lignes_benignes(texte: str) -> set[int]:
    """Les numéros des lignes d'une erreur du moteur sans lien avec le projet (message et « at: »)."""
    lignes = texte.splitlines()
    sortie: set[int] = set()
    for i, l in enumerate(lignes[:-1]):
        for message, lieu in BENIGNES:
            if message.match(l) and lieu.match(lignes[i + 1]):
                sortie |= {i, i + 1}
    return sortie


def erreurs_projet(texte: str) -> list[str]:
    """Les lignes d'erreur ou d'avertissement qui concernent le projet."""
    benignes = lignes_benignes(texte)
    return [l for i, l in enumerate(texte.splitlines())
            if i not in benignes and re.search(r"\b(ERROR|WARNING)\b", l)]


def import_propre(texte: str) -> bool:
    if not jeu():
        return not texte.strip()
    return not erreurs_projet(texte)


def lecture_import(texte: str) -> str:
    """Ce que la réponse dit d'un import sans erreur du projet."""
    if not jeu() or not lignes_benignes(texte):
        return "L'import est propre."
    return ("L'import ne signale aucune erreur du projet. La seule ligne ERROR (« Parameter \"material\" is null », "
            "à `material_get_instance_shader_parameters`) vient de `servers/rendering/dummy/` : le moteur de rendu "
            "factice de l'éditeur sans fenêtre, pas le projet.")


# --------------------------------------------------------------------------------------------- l'analyse
def autoloads(fichiers: dict[str, str]) -> list[str]:
    noms: list[str] = []
    dans = False
    for ligne in fichiers.get("project.godot", "").splitlines():
        s = ligne.strip()
        if s.startswith("["):
            dans = s == "[autoload]"
        elif dans and "=" in s and not s.startswith(";"):
            noms.append(s.split("=", 1)[0].strip())
    return noms


def autoloads_employes(texte: str, noms: list[str]) -> list[str]:
    """Les autoloads qu'un script emploie (hors commentaires et chaînes : « push_error("GameFlow.start : …") » n'emploie
    pas l'autoload)."""
    code = re.sub(r'"(?:[^"\\\n]|\\.)*"', '""', "\n".join(l.split("#", 1)[0] for l in texte.split("\n")))
    return [n for n in noms if re.search(rf"\b{re.escape(n)}\b", code)]


CHEMIN_RES = re.compile(r"res://([^\"'\s)\]]+)")
CLASSE = re.compile(r"^class_name\s+(\w+)", re.M)


def charges(fichiers: dict[str, str], rel: str) -> set[str]:
    """Ce que Godot charge pour compiler `rel`, de proche en proche : les chemins res:// (preload, scènes,
    ressources) et les scripts des classes globales nommées dans le code."""
    classes = {m[1]: f for f, t in fichiers.items() if f.endswith(".gd") and (m := CLASSE.search(t))}
    vus: set[str] = set()
    a_voir = [rel]
    while a_voir:
        courant = a_voir.pop()
        if courant in vus or courant not in fichiers:
            continue
        vus.add(courant)
        texte = fichiers[courant]
        a_voir += [c for c in CHEMIN_RES.findall(texte) if c.endswith((".gd", ".tscn", ".tres"))]
        if courant.endswith(".gd"):
            code = "\n".join(l.split("#", 1)[0] for l in texte.split("\n"))
            a_voir += [f for nom, f in classes.items() if re.search(rf"\b{nom}\b", code)]
    return vus


def analysables(scripts: list[str], fichiers: dict[str, str]) -> tuple[list[str], dict[str, list[str]]]:
    """(scripts que `--check-only` peut analyser seuls, {script: autoloads qu'il emploie} pour les autres). Un script
    qui charge, même de loin, un script qui emploie un autoload (une suite qui précharge `boot.tscn`, dont le script
    emploie `GameFlow`) échoue lui aussi sous `--check-only` (relevé sur le roguelike, étape 14)."""
    if not jeu():
        return scripts, {}
    noms = autoloads(fichiers)
    employant = {f: e for f, t in fichiers.items() if f.endswith(".gd") and (e := autoloads_employes(t, noms))}
    seuls, autres = [], {}
    for rel in scripts:
        employes = sorted({n for f in charges(fichiers, rel) if f in employant for n in employant[f]})
        if employes:
            autres[rel] = employes
        else:
            seuls.append(rel)
    return seuls, autres


def phrase_autoloads(autres: dict[str, list[str]]) -> str:
    if not autres:
        return ""
    noms = sorted({n for v in autres.values() for n in v})
    scripts = ", ".join(f"`res://{rel}`" for rel in autres)
    return (f"{scripts} {'emploie' if len(autres) == 1 else 'emploient'}, directement ou par ce que "
            + ("ce script charge, " if len(autres) == 1 else "ces scripts chargent, ")
            + ("l'autoload " if len(noms) == 1 else "les autoloads ") + ", ".join(f"`{n}`" for n in noms)
            + " : `--check-only` ne charge pas les autoloads et répondrait « Identifier not found » sur un script "
              "juste. Les tests, qui chargent tout le projet, " + ("le" if len(autres) == 1 else "les") + " vérifient.")


# --------------------------------------------------------------------------------------------- le rendu
EXT_RES = re.compile(r'\[ext_resource [^\]]*path="res://([^"]+)"')
MAIN = re.compile(r'^run/main_scene="res://([^"]+)"', re.M)


def dependances(fichiers: dict[str, str], rel: str, vus: set[str] | None = None) -> set[str]:
    """Les fichiers qu'une scène ou une ressource charge, de proche en proche (ext_resource)."""
    vus = set() if vus is None else vus
    if rel in vus:
        return vus
    vus.add(rel)
    for cible in EXT_RES.findall(fichiers.get(rel, "")):
        if cible.endswith((".tscn", ".tres")):
            dependances(fichiers, cible, vus)
        else:
            vus.add(cible)
    return vus


def scene_de_rendu(fichiers: dict[str, str], shaders: list[str]) -> str | None:
    """La scène à lancer pour compiler ces shaders : la scène principale si elle les charge, sinon la plus petite
    scène qui les charge ; None si c'est la scène principale (rien à préciser)."""
    m = MAIN.search(fichiers.get("project.godot", ""))
    principale = m[1] if m else None
    if principale and set(shaders) <= dependances(fichiers, principale):
        return None
    candidates = [(len(dependances(fichiers, rel)), rel) for rel in fichiers
                  if rel.endswith(".tscn") and not rel.startswith("7_tests/") and set(shaders) & dependances(fichiers, rel)]
    if not candidates:
        return None
    return "res://" + min(candidates)[1]


def arguments_rendu(scene: str | None) -> list[str]:
    args = ["--path", ".", "--rendering-method", "gl_compatibility", "--rendering-driver", "opengl3",
            "--audio-driver", "Dummy", "--resolution", "960x540", "--position", POSITION_HORS_ECRAN,
            "--quit-after", str(IMAGES_RENDU)]
    return args + ([scene] if scene else [])


def rendu_propre(code: int, texte: str) -> bool:
    return code == 0 and not erreurs_projet(texte)


def note_rendu(texte: str) -> str:
    """Ce que la réponse dit des avertissements « Forward+ seulement » d'un rendu en Compatibilité, s'il y en a."""
    vus = [m[1] for l in texte.splitlines() if (m := FORWARD.match(l))]
    if not vus:
        return ""
    return ("Les avertissements disent seulement que des réglages du projet faits pour Forward+ ne s'appliquent pas "
            "en Compatibilité (" + " ; ".join(f"« {v} »" for v in dict.fromkeys(vus)) + ") : Godot les ignore dans "
            "ce mode, ce ne sont pas des erreurs de shader.")
