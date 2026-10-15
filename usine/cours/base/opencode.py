"""Format d'OpenCode 2.0.6, le harnais d'usage (décision 14 de laurent ; règle 7.4 : les outils des données sont ceux
d'OpenCode, texte gardé).

Rien n'est imaginé : chaque forme vient des sessions réelles de laurent (relevé du 2026-10-15).
- Prompt système et définitions des 12 outils : une session capturée par le proxy de l'usine
  (`donnees/sessions/*.jsonl`, étape 16 de VERIFIER_EN_LOCAL.md), lue telle quelle. Seules changent les lignes
  d'environnement : dossier de travail, racine de l'espace de travail, identifiant de session.
- Retours des outils : la base d'OpenCode 2.0.6 de laurent (`opencode.db`) et la même session capturée :
  `shell` rend la sortie puis « Command exited with code N. » (« (no output) » si rien) et tronque au-delà de
  50 ko environ ; `read` rend « Read file <chemin>, lines a-b » puis « n: ligne », et
  « [Output truncated. Continue reading with offset: n] » s'il reste des lignes ; `edit` rend
  « Edited <chemin relatif> (1 replacement) » ; `write` rend « Created file successfully: <chemin relatif> » ou
  « Wrote file successfully: … » ; `grep` rend « No matches found » quand rien ne correspond.
- Godot : lancé par son chemin complet, comme le dit `D:\\GODOT\\AGENTS.md` (aucun `godot` dans le PATH).
- Gabarit de chat : celui du GGUF de Qwen 3.8 de laurent (`tokenizer.chat_template`, version d'Unsloth). Les appels
  d'outils s'y écrivent `<tool_call>\\n<function=nom>\\n<parameter=clé>\\nvaleur\\n</parameter>\\n</function>\\n</tool_call>`,
  les retours dans un tour « user » entre `<tool_response>` et `</tool_response>`. `rendre()` en est la traduction
  en Python, vérifiée par les tests contre le gabarit lui-même (jinja2).

Les sorties de Godot ne sont jamais raccourcies (décision 13 de laurent). On n'en retire que ce que permet la
règle 5.1 : codes de couleur, progression de l'import, avertissements et lignes de pilote propres à la machine.
"""

from __future__ import annotations

import hashlib
import json
import re
from dataclasses import dataclass
from pathlib import Path, PureWindowsPath

from usine.cours.base import etat

OUTILS_ATTENDUS = ("edit", "execute", "glob", "grep", "question", "read", "shell", "skill", "subagent", "webfetch",
                   "websearch", "write")

FIN_SHELL = "Command exited with code {code}."
SANS_SORTIE = "(no output)"
LIMITE_SORTIE = 50 * 1024      # au-delà, OpenCode ne rend qu'un aperçu de la sortie : on n'en fait pas d'exemple
EDIT_FAIT = "Edited {chemin} (1 replacement)"
WRITE_CREE = "Created file successfully: {chemin}"
WRITE_REMPLACE = "Wrote file successfully: {chemin}"
GREP_VIDE = "No matches found"
READ_TETE = "Read file {chemin}, lines {debut}-{fin}"
READ_SUITE = "[Output truncated. Continue reading with offset: {suite}]"

# Les lignes d'environnement du prompt d'OpenCode, une seule fois chacune.
ENV = {
    "session": re.compile(r"(?m)^(  Current conversation session ID: )ses_\w+$"),
    "dossier": re.compile(r"(?m)^(  Working directory: ).*$"),
    "racine": re.compile(r"(?m)^(  Workspace root folder: ).*$"),
}

# Ce que le gabarit de Qwen 3.8 écrit autour des définitions d'outils (copié du gabarit ; vérifié par les tests).
OUTILS_DEBUT = "# Tools\n\nYou have access to the following functions:\n\n<tools>"
OUTILS_FIN = (
    "\n</tools>\n\nIf you choose to call a function ONLY reply in the following format with NO suffix:\n\n<tool_call>\n"
    "<function=example_function_name>\n<parameter=example_parameter_1>\nvalue_1\n</parameter>\n"
    "<parameter=example_parameter_2>\nThis is the value for the second parameter\nthat can span\nmultiple lines\n"
    "</parameter>\n</function>\n</tool_call>\n\n<IMPORTANT>\nReminder:\n- Function calls MUST follow the specified "
    "format: an inner <function=...></function> block must be nested within <tool_call></tool_call> XML tags\n"
    "- Required parameters MUST be specified\n- You may provide optional reasoning for your function call in natural "
    "language BEFORE the function call, but NOT after\n- If there is no function call available, answer the question "
    "like normal with your current knowledge and do not tell the user about function calls\n</IMPORTANT>")
REFLEXION_VIDE = "<think>\n\n</think>\n\n"

# Sorties de Godot : ce que la règle 5.1 permet de retirer (couleurs à part).
COULEURS = re.compile(r"\x1b\[[0-9;]*m")
MACHINE = re.compile(r"V-Sync mode|gl_manager_x11|^OpenGL API|^Vulkan \d|^Using present mode"
                     r"|Failed to load cached shader|_load_from_cache|^\[\s*\d+% \]|^\[ DONE \]")
_ALNUM = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"


class FormatInconnu(Exception):
    """Un retour d'outil dont on n'a pas relevé la forme réelle : on ne l'invente pas."""


def _base62(graine: str, n: int) -> str:
    h = int.from_bytes(hashlib.sha256(graine.encode("utf-8")).digest(), "big")
    s = []
    for _ in range(n):
        h, r = divmod(h, 62)
        s.append(_ALNUM[r])
    return "".join(s)


@dataclass
class Harnais:
    """Le prompt et les outils d'OpenCode, le chemin de Godot et le dossier des projets chez laurent."""
    systeme: str
    outils: list[dict]
    godot: str
    projets: str

    @classmethod
    def charger(cls, session: Path | str, godot: str, projets: str) -> "Harnais":
        lignes = [json.loads(l) for l in Path(session).read_text(encoding="utf-8").splitlines() if l.strip()]
        outils = lignes[0].get("tools") or []
        noms = tuple(sorted(o["function"]["name"] for o in outils))
        if noms != OUTILS_ATTENDUS:
            raise ValueError(f"{session} : outils {noms}, attendu ceux d'OpenCode 2.0.6 {OUTILS_ATTENDUS}")
        systeme = next((m["content"] for m in lignes[1:] if m.get("role") == "system"), None)
        if not systeme or "You are an AI agent running in OpenCode" not in systeme:
            raise ValueError(f"{session} : pas de prompt système d'OpenCode")
        for nom, motif in ENV.items():
            if len(motif.findall(systeme)) != 1:
                raise ValueError(f"{session} : ligne d'environnement « {nom} » introuvable ou répétée")
        if " " in godot:
            raise ValueError("le chemin de Godot contient une espace : la commande devrait le citer")
        return cls(systeme, outils, godot, projets)

    def dossier(self, nom_projet: str) -> str:
        return str(PureWindowsPath(self.projets) / nom_projet)

    def prompt(self, dossier: str, graine: str) -> str:
        p = ENV["session"].sub(lambda m: m.group(1) + "ses_" + hashlib.sha256(graine.encode()).hexdigest()[:12]
                               + _base62(graine, 14), self.systeme)
        p = ENV["dossier"].sub(lambda m: m.group(1) + dossier, p)
        return ENV["racine"].sub(lambda m: m.group(1) + dossier, p)

    def commande(self, neutre: str) -> str:
        """La commande `godot …` des exemples, lancée chez laurent : Godot par son chemin complet."""
        if not neutre.startswith("godot "):
            raise FormatInconnu(f"commande inattendue : {neutre[:60]}")
        return self.godot + neutre[len("godot"):]


def chemin_windows(dossier: str, rel: str) -> str:
    return str(PureWindowsPath(dossier, *rel.split("/")))


# --------------------------------------------------------------------------------------------- retours d'outils
def sortie_godot(brut: str, projet_local: str, dossier: str) -> str:
    """La sortie de Godot telle qu'OpenCode la montrerait : tout, sauf les couleurs, la progression de l'import et
    les lignes propres à la machine qui a produit la base (règle 5.1). Une ligne vidée par le retrait des couleurs
    disparaît avec elles. Le chemin local du projet devient celui du projet chez laurent."""
    gardees = []
    for ligne in brut.replace("\r\n", "\n").split("\n"):
        sans = COULEURS.sub("", ligne).rstrip()
        if MACHINE.search(sans) or (ligne.strip() and not sans.strip()):
            continue
        gardees.append(sans)
    texte = "\n".join(gardees)
    absolu = str(Path(projet_local).resolve())
    return texte.replace(absolu + "/", dossier.replace("\\", "/") + "/").replace(absolu, dossier.replace("\\", "/"))


def retour_shell(sortie: str, code: int) -> str:
    """Le retour de l'outil shell : la sortie telle quelle (son dernier retour à la ligne compris), un retour à la
    ligne, puis le code de sortie ; « (no output) » à la place d'une sortie vide."""
    if len(sortie.encode("utf-8")) > LIMITE_SORTIE:
        raise FormatInconnu(f"sortie de {len(sortie.encode('utf-8'))} octets : OpenCode n'en rendrait qu'un aperçu")
    corps = sortie if sortie.strip() else SANS_SORTIE
    return corps + "\n" + FIN_SHELL.format(code=code)


def lignes_fichier(texte: str) -> list[str]:
    """Les lignes d'un fichier comme `read` les numérote : pas de ligne vide après le dernier retour à la ligne."""
    lignes = texte.split("\n")
    if lignes and lignes[-1] == "" and len(lignes) > 1:
        lignes = lignes[:-1]
    return lignes


def retour_read(chemin: str, texte: str, debut: int, fin: int) -> str:
    """Les lignes debut à fin (1 = première) : « Read file …, lines a-b », « n: ligne », et la suite s'il en reste."""
    lignes = lignes_fichier(texte)
    fin = min(fin, len(lignes))
    corps = [READ_TETE.format(chemin=chemin, debut=debut, fin=fin)]
    corps += [f"{i}: {lignes[i - 1]}" for i in range(debut, fin + 1)]
    if fin < len(lignes):
        corps.append(READ_SUITE.format(suite=fin + 1))
    return "\n".join(corps)


def include_grep(globs: list[str]) -> str:
    extensions = [g.removeprefix("*.") for g in globs]
    return globs[0] if len(globs) == 1 else "*.{" + ",".join(extensions) + "}"


# --------------------------------------------------------------------------------------------- éditions
def _occurrences(texte: str, motif: str) -> int:
    """Combien de fois le passage apparaît, chevauchements compris (un passage doit être unique pour `edit`)."""
    n, i = 0, texte.find(motif)
    while i >= 0:
        n += 1
        i = texte.find(motif, i + 1)
    return n


@dataclass
class Edition:
    ancien: str
    nouveau: str
    lignes: tuple[int, int]     # lignes (1 = première) du passage ancien dans le fichier de départ, pour `read`


def editions_fichier(avant: str, apres: str) -> list[Edition]:
    """Des remplacements exacts qui changent `avant` en `apres` (lignes vides comprises), l'un après l'autre, chacun
    unique dans le fichier au moment où on l'applique : élargis d'une ligne voisine pour un ajout ou un retrait,
    puis tant qu'ils ne sont pas uniques."""
    a, n = avant.split("\n"), apres.split("\n")
    sortie: list[Edition] = []
    for a1, a2, n1, n2 in etat._diff_git(a, n):
        cur = n[:n1] + a[a1:]
        texte = "\n".join(cur)
        debut, fin = n1, n1 + (a2 - a1)
        nouvelles = n[n1:n2]
        haut, bas = debut, fin
        if haut == bas or not nouvelles:
            if haut > 0:
                haut -= 1
            else:
                bas += 1
        while True:
            ancien = "\n".join(cur[haut:bas])
            if ancien.strip() and _occurrences(texte, ancien) == 1:
                break
            if haut > 0 and (debut - haut <= bas - fin or bas >= len(cur)):
                haut -= 1
            elif bas < len(cur):
                bas += 1
            else:
                raise ValueError("aucun passage unique pour cette édition")
        nouveau = "\n".join(cur[haut:debut] + nouvelles + cur[fin:bas])
        # Lignes du passage dans le fichier de départ : celles du dessus sont décalées par les éditions précédentes.
        decalage = a1 - n1
        sortie.append(Edition(ancien, nouveau, (haut + decalage + 1, bas + decalage)))
    texte = avant
    for e in sortie:
        if _occurrences(texte, e.ancien) != 1:
            raise ValueError("édition non unique au moment de l'appliquer")
        texte = texte.replace(e.ancien, e.nouveau, 1)
    if texte != apres:
        raise ValueError("les éditions ne redonnent pas le fichier attendu")
    return sortie


def appliquer(fichiers: dict[str, str], appels: list[tuple[str, dict]], dossier: str) -> dict[str, str]:
    """Rejoue des appels `edit` et `write` comme OpenCode : passage unique exigé. Rend les fichiers obtenus."""
    sortie = dict(fichiers)
    prefixe = str(PureWindowsPath(dossier)) + "\\"
    for nom, args in appels:
        if nom not in ("edit", "write"):
            continue
        if not args["path"].startswith(prefixe):
            raise ValueError(f"{args['path']} hors du projet")
        rel = args["path"][len(prefixe):].replace("\\", "/")
        if nom == "write":
            sortie[rel] = args["content"]
            continue
        texte = sortie.get(rel)
        if texte is None or _occurrences(texte, args["oldString"]) != 1:
            raise ValueError(f"{rel} : oldString absent ou répété")
        sortie[rel] = texte.replace(args["oldString"], args["newString"], 1)
    return sortie


def plages_lecture(plages: list[tuple[int, int]], n_lignes: int, marge: int = 2, ecart: int = 4) -> list[tuple[int, int]]:
    """Les plages à lire (1 = première ligne), élargies d'une marge et fusionnées quand elles se touchent."""
    fusion: list[list[int]] = []
    for a, b in sorted(plages):
        a, b = max(1, a - marge), min(n_lignes, b + marge)
        if fusion and a <= fusion[-1][1] + ecart:
            fusion[-1][1] = max(fusion[-1][1], b)
        else:
            fusion.append([a, b])
    return [(a, b) for a, b in fusion]


# --------------------------------------------------------------------------------------------- la conversation
class Conversation:
    """Une conversation au format chat d'OpenAI, comme OpenCode l'envoie à llama-server : texte de l'assistant, puis
    ses appels d'outils ; chaque retour dans un message « tool ». Les arguments sont des objets (le gabarit de Qwen
    3.8 refuse une chaîne JSON)."""

    def __init__(self, harnais: Harnais, nom_projet: str, ident: str):
        self.h = harnais
        self.ident = ident
        self.dossier = harnais.dossier(nom_projet)
        self.messages: list[dict] = [{"role": "system", "content": harnais.prompt(self.dossier, ident)}]
        self.attente: list[str] = []
        self.n = 0

    def chemin(self, rel: str) -> str:
        return chemin_windows(self.dossier, rel)

    def utilisateur(self, texte: str) -> None:
        assert not self.attente, "des appels attendent leur retour"
        self.messages.append({"role": "user", "content": texte})

    def appeler(self, texte: str, appels: list[tuple[str, dict]]) -> list[str]:
        assert not self.attente and appels
        ids = []
        for _ in appels:
            self.n += 1
            ids.append(_base62(f"{self.ident}#{self.n}", 32))
        self.messages.append({"role": "assistant", "content": texte.strip(),
                              "tool_calls": [{"id": i, "type": "function", "function": {"name": nom, "arguments": args}}
                                             for i, (nom, args) in zip(ids, appels)]})
        self.attente = list(ids)
        return ids

    def retour(self, contenu: str) -> None:
        ident = self.attente.pop(0)
        self.messages.append({"role": "tool", "tool_call_id": ident, "content": contenu})

    def repondre(self, texte: str) -> None:
        assert not self.attente
        self.messages.append({"role": "assistant", "content": texte.strip()})

    # Outils, avec leur retour.
    def shell(self, texte: str, neutre: str, brut: str, code: int, projet_local: str) -> None:
        self.appeler(texte, [("shell", {"command": self.h.commande(neutre)})])
        self.retour(retour_shell(sortie_godot(brut, projet_local, self.dossier), code))

    def lire(self, texte: str, lectures: list[tuple[str, str, int, int]]) -> None:
        """lectures : (rel, texte du fichier, première ligne, dernière ligne), lues ensemble."""
        self.appeler(texte, [("read", {"path": self.chemin(rel), "offset": a, "limit": b - a + 1})
                             for rel, _, a, b in lectures])
        for rel, contenu, a, b in lectures:
            self.retour(retour_read(self.chemin(rel), contenu, a, b))

    def editer(self, texte: str, rel: str, ancien: str, nouveau: str) -> None:
        self.appeler(texte, [("edit", {"path": self.chemin(rel), "oldString": ancien, "newString": nouveau})])
        self.retour(EDIT_FAIT.format(chemin=rel))

    def ecrire(self, texte: str, rel: str, contenu: str, existe: bool) -> None:
        self.appeler(texte, [("write", {"path": self.chemin(rel), "content": contenu})])
        self.retour((WRITE_REMPLACE if existe else WRITE_CREE).format(chemin=rel))

    def chercher(self, texte: str, motif: str, globs: list[str], trouve: str) -> None:
        if trouve.strip():
            raise FormatInconnu("grep avec des correspondances : forme du retour d'OpenCode non reproduite")
        self.appeler(texte, [("grep", {"pattern": motif, "include": include_grep(globs)})])
        self.retour(GREP_VIDE)

    def exemple(self) -> dict:
        assert not self.attente
        assert self.messages[-1]["role"] == "assistant" and not self.messages[-1].get("tool_calls")
        return {"messages": self.messages, "tools": self.h.outils}


# --------------------------------------------------------------------------------------------- gabarit et jetons
def _argument(valeur) -> str:
    return valeur if isinstance(valeur, str) else json.dumps(valeur, ensure_ascii=False)


def reponse_rendue(m: dict) -> str:
    """Ce que le gabarit écrit pour un message assistant après le bloc de réflexion vide : le texte, puis les appels."""
    contenu = (m.get("content") or "").strip()
    morceaux = [contenu]
    for j, tc in enumerate(m.get("tool_calls") or []):
        f = tc.get("function", tc)
        if j == 0:
            morceaux.append(("\n\n" if contenu else "") + "<tool_call>\n<function=" + f["name"] + ">\n")
        else:
            morceaux.append("\n<tool_call>\n<function=" + f["name"] + ">\n")
        for cle, valeur in f["arguments"].items():
            morceaux.append("<parameter=" + cle + ">\n" + _argument(valeur) + "\n</parameter>\n")
        morceaux.append("</function>\n</tool_call>")
    return "".join(morceaux)


def systeme_rendu(messages: list[dict], outils: list[dict]) -> str:
    """Le contenu du message système tel que le gabarit l'écrit : outils, puis prompt (sans les balises)."""
    systeme = "\n".join(c for c in ((m.get("content") or "").strip() for m in _systemes(messages)) if c)
    if not outils:
        return systeme
    return OUTILS_DEBUT + "".join("\n" + json.dumps(o, ensure_ascii=False) for o in outils) + OUTILS_FIN + (
        "\n\n" + systeme if systeme else "")


def _systemes(messages: list[dict]) -> list[dict]:
    k = 0
    while k < len(messages) and messages[k]["role"] in ("system", "developer"):
        k += 1
    return messages[:k]


def rendre(messages: list[dict], outils: list[dict]) -> str:
    """La conversation mise en forme par le gabarit de Qwen 3.8 (enable_thinking: false, sans invite finale)."""
    sortie = []
    nsys = len(_systemes(messages))
    s = systeme_rendu(messages, outils)
    if s:
        sortie.append("<|im_start|>system\n" + s + "<|im_end|>\n")
    for k in range(nsys, len(messages)):
        m = messages[k]
        contenu = (m.get("content") or "").strip()
        if m["role"] == "user":
            sortie.append("<|im_start|>user\n" + contenu + "<|im_end|>\n")
        elif m["role"] == "assistant":
            sortie.append("<|im_start|>assistant\n" + REFLEXION_VIDE + reponse_rendue(m) + "<|im_end|>\n")
        elif m["role"] == "tool":
            if messages[k - 1]["role"] != "tool":
                sortie.append("<|im_start|>user")
            sortie.append("\n<tool_response>\n" + contenu + "\n</tool_response>")
            if k == len(messages) - 1 or messages[k + 1]["role"] != "tool":
                sortie.append("<|im_end|>\n")
        else:
            raise ValueError(f"rôle inattendu : {m['role']}")
    return "".join(sortie)


def vers_sharegpt(messages: list[dict], outils: list[dict]) -> dict:
    """Pour LLaMA-Factory : les appels d'outils écrits dans la réponse comme le gabarit les écrit, les retours dans
    un tour « human ». Un tour function_call de LLaMA-Factory perdrait le texte qui précède l'appel (section 3 des
    règles qui priment) ; ici rien ne se perd et le texte mis en forme est celui du gabarit, jeton pour jeton."""
    tours: list[dict] = []
    nsys = len(_systemes(messages))
    for k in range(nsys, len(messages)):
        m = messages[k]
        contenu = (m.get("content") or "").strip()
        if m["role"] == "user":
            tours.append({"from": "human", "value": contenu})
        elif m["role"] == "assistant":
            tours.append({"from": "gpt", "value": reponse_rendue(m)})
        elif m["role"] == "tool":
            bloc = "<tool_response>\n" + contenu + "\n</tool_response>"
            if messages[k - 1]["role"] == "tool":
                tours[-1]["value"] += "\n" + bloc
            else:
                tours.append({"from": "human", "value": bloc})
    for i, t in enumerate(tours):
        if t["from"] != ("human" if i % 2 == 0 else "gpt"):
            raise ValueError(f"alternance rompue au tour {i}")
    if not tours or tours[-1]["from"] != "gpt":
        raise ValueError("la conversation ne finit pas par une réponse")
    return {"conversations": tours, "system": systeme_rendu(messages, outils)}


def rendre_sharegpt(exemple: dict) -> str:
    """Le texte que LLaMA-Factory produit d'un exemple sharegpt avec le gabarit de Qwen (enable_thinking: false) :
    il doit être celui de `rendre()` sur la conversation d'origine."""
    sortie = ["<|im_start|>system\n" + exemple["system"] + "<|im_end|>\n"] if exemple.get("system") else []
    for t in exemple["conversations"]:
        if t["from"] == "human":
            sortie.append("<|im_start|>user\n" + t["value"] + "<|im_end|>\n")
        else:
            sortie.append("<|im_start|>assistant\n" + REFLEXION_VIDE + t["value"] + "<|im_end|>\n")
    return "".join(sortie)


def compter(tok, messages: list[dict], outils: list[dict]) -> tuple[int, int]:
    """(total, réponse) en jetons de Qwen 3.8 : le total est celui du texte mis en forme ; la réponse, ce sur quoi
    porte la perte, soit chaque réponse mise en forme et son <|im_end|>\\n (le bloc de réflexion vide est dans le
    prompt, enable_thinking: false)."""
    total = len(tok.encoder_special(rendre(messages, outils)))
    reponse = sum(len(tok.encoder_special(reponse_rendue(m) + "<|im_end|>\n"))
                  for m in messages if m["role"] == "assistant")
    return total, reponse
