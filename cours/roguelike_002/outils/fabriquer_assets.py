"""Fabrique les assets fictifs des menus du cours « roguelike_002 » (plan du cours, §2 : des assets faits par le code,
que les vrais remplaceront par la donnée seule). Même graine, mêmes fichiers.

Sorties, dans le jeu source (clé `roguelike_002` de [sources]), sous `6_assets/jeu/` :
- `studio/logo.png` : la marque fictive du studio (un anneau et trois barres, blanc sur fond transparent) ;
- `menu/fond.png` : un ciel d'étoiles et une nébuleuse, plus large que l'écran (l'image qui glisse) ;
- `menu/planete.png` : une planète à bandes, sur fond transparent (un calque du motion design).

    python cours/roguelike_002/outils/fabriquer_assets.py [--source <dossier>]
"""

from __future__ import annotations

import argparse
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

SOURCE_DEFAUT = Path(r"D:\GODOT\PROJETS_DEMOS\PROJET_ROGUELIKE_002_COURS")
GRAINE = 2002


def logo(chemin: Path) -> None:
    cote = 512
    img = Image.new("RGBA", (cote, cote), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = cote // 2
    d.ellipse((c - 200, c - 200, c + 200, c + 200), outline=(255, 255, 255, 255), width=28)
    for k, hauteur in enumerate((120, 200, 150)):
        x = c - 90 + k * 70
        d.rounded_rectangle((x, c + 80 - hauteur, x + 44, c + 80), radius=10, fill=(255, 255, 255, 255))
    chemin.parent.mkdir(parents=True, exist_ok=True)
    img.save(chemin)


def fond(chemin: Path, rng: random.Random) -> None:
    largeur, hauteur = 2560, 1440
    img = Image.new("RGB", (largeur, hauteur), (6, 8, 20))
    d = ImageDraw.Draw(img)
    for y in range(hauteur):  # dégradé vertical : bleu nuit en haut, violet sombre en bas
        t = y / (hauteur - 1)
        d.line((0, y, largeur, y), fill=(int(6 + 24 * t), int(8 + 4 * t), int(20 + 30 * t)))
    nebuleuse = Image.new("RGBA", (largeur, hauteur), (0, 0, 0, 0))
    dn = ImageDraw.Draw(nebuleuse)
    for _ in range(40):
        x, y = rng.uniform(0, largeur), rng.uniform(hauteur * 0.2, hauteur * 0.8)
        r = rng.uniform(80, 260)
        teinte = rng.choice(((90, 40, 160), (40, 90, 170), (150, 50, 110)))
        dn.ellipse((x - r, y - r * 0.6, x + r, y + r * 0.6), fill=(*teinte, 34))
    img = Image.alpha_composite(img.convert("RGBA"), nebuleuse.filter(ImageFilter.GaussianBlur(60)))
    d = ImageDraw.Draw(img)
    for _ in range(1400):
        x, y = rng.uniform(0, largeur), rng.uniform(0, hauteur)
        r = rng.choice((0.6, 0.8, 1.0, 1.0, 1.4, 2.0))
        v = rng.randint(150, 255)
        d.ellipse((x - r, y - r, x + r, y + r), fill=(v, v, min(255, v + 20), 255))
    chemin.parent.mkdir(parents=True, exist_ok=True)
    img.convert("RGB").save(chemin)


def planete(chemin: Path) -> None:
    cote = 1024
    grand = Image.new("RGBA", (cote, cote), (0, 0, 0, 0))
    d = ImageDraw.Draw(grand)
    c, r = cote // 2, 440
    for y in range(c - r, c + r):
        demi = math.sqrt(max(r * r - (y - c) ** 2, 0))
        bande = 0.5 + 0.5 * math.sin((y - c) / r * 9.0)
        couleur = (int(70 + 80 * bande), int(110 + 50 * bande), int(150 + 60 * bande), 255)
        d.line((c - demi, y, c + demi, y), fill=couleur)
    ombre = Image.new("L", (cote, cote), 0)
    ImageDraw.Draw(ombre).ellipse((c - r + 160, c - r + 60, c + r + 260, c + r + 160), fill=170)
    sombre = Image.new("RGBA", (cote, cote), (5, 5, 15, 255))
    masque = Image.new("L", (cote, cote), 0)
    ImageDraw.Draw(masque).ellipse((c - r, c - r, c + r, c + r), fill=255)
    grand = Image.composite(sombre, grand, Image.composite(ombre.filter(ImageFilter.GaussianBlur(40)),
                                                            Image.new("L", (cote, cote), 0), masque))
    grand.putalpha(masque)
    chemin.parent.mkdir(parents=True, exist_ok=True)
    grand.save(chemin)


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--source", type=Path, default=SOURCE_DEFAUT)
    a = p.parse_args()
    racine = a.source / "6_assets" / "jeu"
    logo(racine / "studio" / "logo.png")
    fond(racine / "menu" / "fond.png", random.Random(GRAINE))
    planete(racine / "menu" / "planete.png")
    for f in sorted(racine.rglob("*.png")):
        print(f.relative_to(a.source), f.stat().st_size)


if __name__ == "__main__":
    main()
