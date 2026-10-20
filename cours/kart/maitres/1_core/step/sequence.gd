class_name Sequence extends Resource
## Liste ordonnée des étapes du jeu, lue par GameFlow (0_autoload/game_flow.gd).
## Une étape est une scène : un menu, une cinématique ou un niveau, tous traités de la même façon.
## Contrat d'une étape (1_core/step/step.gd) : quand elle a fini, elle émet son signal « terminee »
## et le chef d'orchestre passe à la suivante ; elle ne charge jamais une autre scène elle-même.
## La pause et les menus ouverts par-dessus le jeu ne sont pas des étapes : ils ne font pas
## avancer le déroulé (voir 4_ui/overlays/).

## Chemins des scènes, dans l'ordre du déroulé.
@export var etapes: Array[String] = []
