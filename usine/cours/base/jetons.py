"""Jetons de Qwen, relus dans un fichier GGUF de llama.cpp (règle 5.8 : jamais une estimation).

Le fichier est soit le GGUF du modèle lui-même (seul son en-tête est lu), soit un GGUF « vocabulaire seul » qui en
est extrait, comme les models/ggml-vocab-*.gguf de llama.cpp. Le tokenizer de Qwen 3.8 (248 320 jetons, 247 587
fusions, pré-découpage qwen35) n'est pas celui du vocabulaire de test models/ggml-vocab-qwen35.gguf de llama.cpp
(151 936 jetons) : seul le premier compte juste pour Qwen 3.8.

Le pré-découpage et les fusions BPE sont ceux de llama.cpp (src/llama-vocab.cpp) ; sur les chaînes de test de
llama.cpp (models/ggml-vocab-qwen35.gguf.inp et .out), ce tokenizer redonne exactement les jetons de référence.
Les jetons spéciaux (types CONTROL et USER_DEFINED : <|im_start|>, <think>, <tool_call>…) sont reconnus dans le
texte, comme le fait llama.cpp quand il analyse les jetons spéciaux et comme le fait le tokenizer de transformers.

    python -m usine.cours.base.jetons <vocab.gguf> verifier
    python -m usine.cours.base.jetons <vocab.gguf> compter <fichier.jsonl> [sortie.json]
    python -m usine.cours.base.jetons <vocab.gguf> croiser <llama-tokenize> <fichier.jsonl>
"""
import json
import re
import struct
import sys
import unicodedata

# ---------------------------------------------------------------- lecture GGUF
_SCAL = {0: "<B", 1: "<b", 2: "<H", 3: "<h", 4: "<I", 5: "<i", 6: "<f", 7: "<?", 10: "<Q", 11: "<q", 12: "<d"}


def lire_gguf(chemin):
    """Les métadonnées d'un GGUF, lues en continu : les tenseurs qui suivent ne sont pas lus (un GGUF de modèle de
    17 Go se lit comme un fichier de vocabulaire)."""
    with open(chemin, "rb") as f:
        def lire(fmt):
            return struct.unpack(fmt, f.read(struct.calcsize(fmt)))[0]

        def chaine():
            return f.read(lire("<Q")).decode("utf-8", errors="replace")

        def valeur(t):
            if t == 8:
                return chaine()
            if t == 9:
                sous, n = lire("<I"), lire("<Q")
                if sous in _SCAL:       # tableau de scalaires : lu d'un bloc
                    taille = struct.calcsize(_SCAL[sous])
                    return list(struct.unpack("<" + str(n) + _SCAL[sous][1:], f.read(n * taille)))
                return [valeur(sous) for _ in range(n)]
            return lire(_SCAL[t])

        assert f.read(4) == b"GGUF", "pas un fichier GGUF"
        lire("<I")  # version
        lire("<Q")  # nombre de tenseurs
        n_kv = lire("<Q")
        meta = {}
        for _ in range(n_kv):
            cle = chaine()
            meta[cle] = valeur(lire("<I"))
        return meta


# ---------------------------------------------------------------- pré-découpage
def _plages(pred):
    morceaux, debut = [], None
    for cp in range(0x110000):
        if 0xD800 <= cp <= 0xDFFF:
            ok = False
        else:
            ok = pred(unicodedata.category(chr(cp)))
        if ok and debut is None:
            debut = cp
        if not ok and debut is not None:
            morceaux.append((debut, cp - 1))
            debut = None
    if debut is not None:
        morceaux.append((debut, 0x10FFFF))

    def esc(cp):
        return "\\U%08x" % cp

    return "".join(esc(a) if a == b else esc(a) + "-" + esc(b) for a, b in morceaux)


L = _plages(lambda c: c.startswith("L"))
N = _plages(lambda c: c.startswith("N"))
M = _plages(lambda c: c.startswith("M"))

MOTIFS = {
    # llama.cpp, src/llama-vocab.cpp : LLAMA_VOCAB_PRE_TYPE_QWEN2 (Qwen 1.5 à Qwen 3)
    "qwen2": r"(?i:'s|'t|'re|'ve|'m|'ll|'d)|[^\r\n{L}{N}]?[{L}]+|[{N}]| ?[^\s{L}{N}]+[\r\n]*|\s*[\r\n]+|\s+(?!\S)|\s+",
    # llama.cpp, src/llama-vocab.cpp : LLAMA_VOCAB_PRE_TYPE_QWEN35 (Qwen 3.5)
    "qwen35": r"(?i:'s|'t|'re|'ve|'m|'ll|'d)|[^\r\n{L}{N}]?[{L}{M}]+|[{N}]| ?[^\s{L}{M}{N}]+[\r\n]*|\s*[\r\n]+|\s+(?!\S)|\s+",
}


def motif(nom):
    return re.compile(MOTIFS[nom].replace("{L}", L).replace("{N}", N).replace("{M}", M))


# ---------------------------------------------------------------- BPE
def _octets_vers_unicode():
    bs = list(range(ord("!"), ord("~") + 1)) + list(range(ord("¡"), ord("¬") + 1)) + list(range(ord("®"), ord("ÿ") + 1))
    cs = bs[:]
    n = 0
    for b in range(256):
        if b not in bs:
            bs.append(b)
            cs.append(256 + n)
            n += 1
    return {b: chr(c) for b, c in zip(bs, cs)}


class Tokenizer:
    def __init__(self, chemin_gguf):
        meta = lire_gguf(chemin_gguf)
        self.pre = meta.get("tokenizer.ggml.pre")
        self.jetons = meta["tokenizer.ggml.tokens"]
        self.types = meta.get("tokenizer.ggml.token_type", [])
        self.ids = {t: i for i, t in enumerate(self.jetons)}
        self.rangs = {}
        for r, m in enumerate(meta["tokenizer.ggml.merges"]):
            a, b = m.split(" ", 1)
            self.rangs[(a, b)] = r
        if self.pre not in MOTIFS:
            raise ValueError(f"pré-découpage « {self.pre} » inconnu : seuls {sorted(MOTIFS)} (llama.cpp)")
        self.motif = motif(self.pre)
        self.o2u = _octets_vers_unicode()
        self.cache = {}
        self.gabarit = meta.get("tokenizer.chat_template")
        # jetons spéciaux (type 3 = CONTROL, 4 = USER_DEFINED) : un seul jeton chacun
        self.speciaux = {t: i for i, t in enumerate(self.jetons)
                         if i < len(self.types) and self.types[i] in (3, 4) and t.startswith("<")}
        self._coupe = re.compile("(" + "|".join(re.escape(s) for s in sorted(self.speciaux, key=len, reverse=True))
                                 + ")") if self.speciaux else None

    def _bpe(self, mot):
        if mot in self.cache:
            return self.cache[mot]
        parts = list(mot)
        while len(parts) > 1:
            meilleur, rang = None, None
            for i in range(len(parts) - 1):
                r = self.rangs.get((parts[i], parts[i + 1]))
                if r is not None and (rang is None or r < rang):
                    meilleur, rang = i, r
            if meilleur is None:
                break
            parts = parts[:meilleur] + [parts[meilleur] + parts[meilleur + 1]] + parts[meilleur + 2:]
        ids = [self.ids[p] for p in parts]
        self.cache[mot] = ids
        return ids

    def encoder(self, texte):
        """Le texte seul, sans reconnaître les jetons spéciaux (comme les chaînes de test de llama.cpp)."""
        sortie = []
        for m in self.motif.finditer(texte):
            mot = "".join(self.o2u[b] for b in m.group(0).encode("utf-8"))
            sortie.extend(self._bpe(mot))
        return sortie

    def encoder_special(self, texte):
        """Le texte d'une conversation mise en forme : chaque jeton spécial écrit en clair (<|im_start|>, <think>,
        <tool_call>…) compte pour un seul jeton, le reste est découpé normalement."""
        if self._coupe is None:
            return self.encoder(texte)
        sortie = []
        for k, morceau in enumerate(self._coupe.split(texte)):
            if k % 2:
                sortie.append(self.speciaux[morceau])
            elif morceau:
                sortie.extend(self.encoder(morceau))
        return sortie


def verifier(tok, base):
    with open(base + ".inp", encoding="utf-8") as f:
        textes = f.read().split("\n__ggml_vocab_test__\n")[:-1]
    with open(base + ".out", encoding="utf-8") as f:
        attendus = [[int(x) for x in ligne.split()] for ligne in f.read().split("\n")[: len(textes)]]
    bons = 0
    for t, a in zip(textes, attendus):
        obtenu = tok.encoder(t)
        if obtenu == a:
            bons += 1
        else:
            print("ÉCART :", repr(t)[:80], "attendu", a[:12], "obtenu", obtenu[:12])
    print(f"{tok.pre} : {bons}/{len(textes)} chaînes de test identiques à la sortie de référence")
    return bons == len(textes)


_TOKENIZER = None


def tokenizer():
    """Le tokenizer de Qwen 3.8 lu dans `[entrainement].vocab_qwen` (chargé une fois)."""
    global _TOKENIZER
    if _TOKENIZER is None:
        from usine.cours.base import chemins
        _TOKENIZER = Tokenizer(str(chemins.actuels().vocab_qwen))
    return _TOKENIZER


def compter(tok, chemin, sortie=None):
    """Compte chaque ligne d'une base au format chat (`messages` et `tools`, comme base_batiments_proceduraux.jsonl)
    telle que le gabarit de chat de Qwen 3.8 la présente (`opencode.compter`)."""
    from usine.cours.base import opencode
    lignes = []
    with open(chemin, encoding="utf-8") as f:
        for brut in f:
            ex = json.loads(brut)
            total, reponse = opencode.compter(tok, ex["messages"], ex.get("tools") or [])
            lignes.append({"tache_id": ex.get("tache_id"), "type": ex.get("type"), "jetons": total,
                           "jetons_reponse": reponse})
    tot = sum(x["jetons"] for x in lignes)
    res = {
        "tokenizer": tok.pre,
        "exemples": len(lignes),
        "jetons_total": tot,
        "jetons_max": max(x["jetons"] for x in lignes),
        "jetons_moyenne": round(tot / len(lignes)),
        "jetons_reponses": sum(x["jetons_reponse"] for x in lignes),
        "plus_long": max(lignes, key=lambda x: x["jetons"]),
        "au_dessus_de_32768": [x["tache_id"] for x in lignes if x["jetons"] > 32768],
        "detail": lignes,
    }
    if sortie:
        with open(sortie, "w", encoding="utf-8") as f:
            json.dump(res, f, ensure_ascii=False, indent=1)
    print(json.dumps({k: v for k, v in res.items() if k != "detail"}, ensure_ascii=False, indent=1))
    return res


def croiser(tok, vocab, outil, chemin):
    """Les jetons de chaque exemple d'une base au format chat, découpé par ce tokenizer puis par `llama-tokenize` de
    llama.cpp sur le même GGUF (jetons spéciaux reconnus, sans BOS ni traitement des échappements) : les suites de
    jetons doivent être identiques, pas seulement leurs longueurs."""
    import subprocess

    from usine.cours.base import opencode
    identiques, total, ecarts = 0, 0, []
    with open(chemin, encoding="utf-8") as f:
        for brut in f:
            ex = json.loads(brut)
            texte = opencode.rendre(ex["messages"], ex.get("tools") or [])
            # Par l'entrée standard, lue telle quelle (un ancien `-f` retirait le dernier retour à la ligne).
            res = subprocess.run([outil, "-m", vocab, "--stdin", "--ids", "--no-bos", "--no-escape", "--log-disable"],
                                 input=texte.encode("utf-8"), capture_output=True)
            attendu = json.loads(res.stdout.decode("utf-8").strip().splitlines()[-1])
            obtenu = tok.encoder_special(texte)
            total += 1
            if obtenu == attendu:
                identiques += 1
            else:
                ecarts.append((ex.get("tache_id"), len(attendu), len(obtenu)))
    print(f"{identiques}/{total} exemples identiques jeton pour jeton à llama-tokenize")
    for tache, a, o in ecarts[:10]:
        print(f"  ÉCART {tache} : llama.cpp {a} jetons, ce tokenizer {o}")
    return identiques == total


if __name__ == "__main__":
    tok = Tokenizer(sys.argv[1])
    print("pré-découpage :", tok.pre, "| jetons :", len(tok.jetons), "| fusions :", len(tok.rangs))
    if sys.argv[2] == "verifier":
        verifier(tok, sys.argv[1])
    elif sys.argv[2] == "croiser":
        sys.exit(0 if croiser(tok, sys.argv[1], sys.argv[3], sys.argv[4]) else 1)
    else:
        compter(tok, sys.argv[3], sys.argv[4] if len(sys.argv) > 4 else None)
