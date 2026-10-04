"""Porte des tests GUT vers GdUnit4 (préparation d'un projet source, une fois).

    python outils/porter_gut.py <dossier_tests_gut> <dossier_sortie>

Traduction déterministe, assertion par assertion (le message éventuel devient
`override_failure_message`) :

    extends GutTest               → extends GdUnitTestSuite
    assert_eq(a, b)               → assert_that(a).is_equal(b)
    assert_ne(a, b)               → assert_that(a).is_not_equal(b)
    assert_true(x) / assert_false → assert_bool(x).is_true() / .is_false()
    assert_null / assert_not_null → assert_that(x).is_null() / .is_not_null()
    assert_almost_eq(a, b, e)     → assert_float(float(a)).is_equal_approx(float(b), float(e))
    assert_gt / assert_lt         → assert_float(float(a)).is_greater / is_less(float(b))
    assert_between(x, lo, hi)     → assert_float(float(x)).is_between(float(lo), float(hi))

Toute autre construction propre à GUT (watch_signals, double, before_each…) arrête le portage
avec la ligne fautive : elle se porte à la main, puis le fichier porté est relu.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

NON_GERES = re.compile(r"\b(watch_signals|assert_signal\w*|double|partial_double|stub|simulate|before_each|after_each|"
                       r"before_all|after_all|autofree|autoqfree|add_child_autofree|add_child_autoqfree|gut\.|"
                       r"pending|pass_test|fail_test|wait_frames|wait_seconds)\b")
APPEL = re.compile(r"\b(assert_eq|assert_ne|assert_true|assert_false|assert_null|assert_not_null|assert_almost_eq|"
                   r"assert_gt|assert_lt|assert_between)\(")


def _fin_appel(texte: str, debut: int) -> int:
    """Indice de la parenthèse fermante de l'appel qui s'ouvre à `debut` (chaînes respectées)."""
    profondeur, i, chaine = 0, debut, None
    while i < len(texte):
        c = texte[i]
        if chaine:
            if c == "\\":
                i += 2
                continue
            if c == chaine:
                chaine = None
        elif c in "\"'":
            chaine = c
        elif c in "([{":
            profondeur += 1
        elif c in ")]}":
            profondeur -= 1
            if profondeur == 0:
                return i
        i += 1
    raise ValueError("parenthèse non fermée")


def _arguments(texte: str) -> list[str]:
    """Arguments de premier niveau, séparés par les virgules hors parenthèses et chaînes."""
    args, courant, profondeur, chaine, i = [], "", 0, None, 0
    while i < len(texte):
        c = texte[i]
        if chaine:
            courant += c
            if c == "\\" and i + 1 < len(texte):
                courant += texte[i + 1]
                i += 2
                continue
            if c == chaine:
                chaine = None
        elif c in "\"'":
            chaine = c
            courant += c
        elif c in "([{":
            profondeur += 1
            courant += c
        elif c in ")]}":
            profondeur -= 1
            courant += c
        elif c == "," and profondeur == 0:
            args.append(courant.strip())
            courant = ""
        else:
            courant += c
        i += 1
    if courant.strip():
        args.append(courant.strip())
    return args


def _traduire(nom: str, args: list[str]) -> str:
    def avec_message(assertion: str, attendus: int) -> str:
        """Le message GUT éventuel passe avant la vérification : assert_x(v).override_failure_message(m).is_…"""
        if len(args) <= attendus:
            return assertion
        appel, verification = assertion.split(").is_", 1)
        return f"{appel}).override_failure_message({args[attendus]}).is_{verification}"

    f = lambda x: f"float({x})"  # noqa: E731
    if nom == "assert_eq":
        return avec_message(f"assert_that({args[0]}).is_equal({args[1]})", 2)
    if nom == "assert_ne":
        return avec_message(f"assert_that({args[0]}).is_not_equal({args[1]})", 2)
    if nom == "assert_true":
        return avec_message(f"assert_bool({args[0]}).is_true()", 1)
    if nom == "assert_false":
        return avec_message(f"assert_bool({args[0]}).is_false()", 1)
    if nom == "assert_null":
        return avec_message(f"assert_that({args[0]}).is_null()", 1)
    if nom == "assert_not_null":
        return avec_message(f"assert_that({args[0]}).is_not_null()", 1)
    if nom == "assert_almost_eq":
        return avec_message(f"assert_float({f(args[0])}).is_equal_approx({f(args[1])}, {f(args[2])})", 3)
    if nom == "assert_gt":
        return avec_message(f"assert_float({f(args[0])}).is_greater({f(args[1])})", 2)
    if nom == "assert_lt":
        return avec_message(f"assert_float({f(args[0])}).is_less({f(args[1])})", 2)
    if nom == "assert_between":
        return avec_message(f"assert_float({f(args[0])}).is_between({f(args[1])}, {f(args[2])})", 3)
    raise ValueError(nom)


def _sans_commentaires(texte: str) -> str:
    return "\n".join(l.split("#", 1)[0] if not l.lstrip().startswith("#") else "" for l in texte.split("\n"))


def porter(texte: str, nom_fichier: str = "") -> str:
    for n, ligne in enumerate(_sans_commentaires(texte).split("\n"), 1):
        m = NON_GERES.search(ligne)
        if m and not re.search(r"[\"'].*" + re.escape(m.group(0)) + r".*[\"']", ligne):
            raise ValueError(f"{nom_fichier}:{n} : construction GUT non gérée « {m.group(0)} » (à porter à la main)")
    texte = re.sub(r"^extends GutTest\b", "extends GdUnitTestSuite", texte, flags=re.M)
    sortie, i = [], 0
    while True:
        m = APPEL.search(texte, i)
        if not m:
            sortie.append(texte[i:])
            break
        # Ignorer les occurrences dans un commentaire.
        debut_ligne = texte.rfind("\n", 0, m.start()) + 1
        if "#" in texte[debut_ligne:m.start()]:
            sortie.append(texte[i:m.end()])
            i = m.end()
            continue
        fin = _fin_appel(texte, m.end() - 1)
        sortie.append(texte[i:m.start()])
        sortie.append(_traduire(m.group(1), _arguments(texte[m.end():fin])))
        i = fin + 1
    return "".join(sortie)


def main(argv: list[str]) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    if len(argv) != 2:
        print(__doc__)
        return 2
    source, sortie = Path(argv[0]), Path(argv[1])
    erreurs = 0
    for f in sorted(source.glob("test_*.gd")):
        try:
            porte = porter(f.read_text(encoding="utf-8"), f.name)
        except ValueError as e:
            print(f"À PORTER À LA MAIN : {e}")
            erreurs += 1
            continue
        (sortie / f.name).parent.mkdir(parents=True, exist_ok=True)
        (sortie / f.name).write_text(porte, encoding="utf-8", newline="\n")
        print(f"porté : {f.name}")
    return 1 if erreurs else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
