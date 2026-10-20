extends RefCounted
## Données de conception de l'immeuble parisien : les listes où le hasard tire.
## {STATUS}
##
## Ce fichier ne contient aucun mécanisme : seulement des noms, des teintes et des cotes. Il
## vit dans « 5_data », pas à côté du code. On peut allonger une liste ou changer une teinte
## sans ouvrir un seul script de « 6_assets ».
##
## Les scripts le chargent par « preload » et lisent ses constantes :
##     const Palette := preload("res://5_data/…_palette.gd")
##     var name: String = Palette.SHOP_NAMES[0]

# --- Boutiques --------------------------------------------------------------

## Enseignes. Sur un immeuble, les noms sont tirés sans remise : jamais deux fois le même.
const SHOP_NAMES: PackedStringArray = [
	"BOULANGERIE", "CAFÉ", "LIBRAIRIE", "FLEURISTE", "ÉPICERIE", "PHARMACIE", "FROMAGERIE", "TABAC",
	"CORDONNERIE", "PAPETERIE", "CHOCOLATIER", "ANTIQUITÉS", "COIFFEUR", "BOUCHERIE", "CAVISTE", "MERCERIE",
]
## Peintures des devantures de bois.
const SHOP_WOOD_COLORS: Array[Color] = [
	Color(0.07, 0.20, 0.14), Color(0.33, 0.07, 0.08), Color(0.07, 0.12, 0.26), Color(0.06, 0.06, 0.07),
	Color(0.55, 0.38, 0.13), Color(0.27, 0.35, 0.41), Color(0.78, 0.73, 0.60), Color(0.10, 0.28, 0.30),
]
## Toiles des stores.
const AWNING_COLORS: Array[Color] = [
	Color(0.55, 0.08, 0.07), Color(0.10, 0.30, 0.17), Color(0.09, 0.14, 0.32), Color(0.72, 0.52, 0.14),
	Color(0.12, 0.12, 0.13), Color(0.80, 0.76, 0.66),
]
## Cadres des vitrines pleine surface : anthracite, noir, bronze, blanc.
const SHOP_METAL_COLORS: Array[Color] = [
	Color(0.09, 0.09, 0.10), Color(0.03, 0.03, 0.035), Color(0.25, 0.19, 0.12), Color(0.82, 0.82, 0.80),
]
## Bandeaux d'enseigne des vitrines pleine surface.
const SHOP_BAND_COLORS: Array[Color] = [
	Color(0.05, 0.05, 0.06), Color(0.88, 0.87, 0.84), Color(0.55, 0.06, 0.08), Color(0.06, 0.20, 0.34),
]
## Lettres d'enseigne : dorées sur fond sombre, sombres sur fond clair, claires sur bandeau foncé.
const SIGN_GILT: Color = Color(0.86, 0.72, 0.40)
const SIGN_DARK_INK: Color = Color(0.10, 0.09, 0.08)
const SIGN_PALE_INK: Color = Color(0.92, 0.91, 0.88)
#@ 12+

# --- Rue --------------------------------------------------------------------

## Teintes de pierre d'une rue, de la façade ravalée, presque blanche, au calcaire blond,
## puis au gris d'une façade qui n'a pas été nettoyée depuis longtemps.
const STONE_COLORS: Array[Color] = [
	Color(0.95, 0.92, 0.86), Color(0.93, 0.90, 0.85), Color(0.90, 0.85, 0.76), Color(0.88, 0.81, 0.68),
	Color(0.85, 0.76, 0.62), Color(0.82, 0.72, 0.56), Color(0.80, 0.74, 0.64), Color(0.74, 0.70, 0.63),
]
## Peintures des portes d'entrée.
const DOOR_COLORS: Array[Color] = [
	Color(0.05, 0.16, 0.24), Color(0.06, 0.18, 0.12), Color(0.30, 0.07, 0.06), Color(0.12, 0.10, 0.09),
	Color(0.10, 0.14, 0.30), Color(0.20, 0.22, 0.24), Color(0.33, 0.19, 0.09),
]
## Peintures des menuiseries de fenêtre : des blancs et des gris clairs.
const FRAME_COLORS: Array[Color] = [
	Color(0.86, 0.86, 0.83), Color(0.90, 0.89, 0.86), Color(0.80, 0.76, 0.66), Color(0.74, 0.76, 0.74),
]

## Hauteur maximale d'une façade parisienne selon la largeur de la voie, en mètres. Chaque
## ligne : (largeur de voie en dessous de laquelle la ligne s'applique, hauteur de façade).
## Les trois premiers paliers viennent des déclarations royales de 1783-1784 ; le règlement
## de 1859 relève la corniche de 17,54 à 20 m sur les voies de 20 m et plus. Sources : Ville
## de Paris (Commission du Vieux Paris, 2016 ; document sur le secteur sauvegardé du Marais)
## pour le principe et pour 1859 ; Wikipédia, de seconde main, pour les deux premiers paliers.
## Voir la note de l'étape 012.
const FACADE_HEIGHT_LIMITS: Array[Vector2] = [
	Vector2(7.8, 11.7), Vector2(9.75, 14.62), Vector2(20.0, 17.55),
]
## Hauteur maximale de la façade sur une voie de 20 m et plus.
const FACADE_HEIGHT_WIDE_STREET: float = 20.0
## Hauteur minimale d'un étage, fixée sous Haussmann (même source).
const MIN_FLOOR_HEIGHT: float = 2.6
