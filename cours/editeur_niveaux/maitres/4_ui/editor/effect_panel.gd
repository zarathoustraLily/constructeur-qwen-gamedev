class_name EffectPanel
extends VBoxContainer
## Le panneau des effets, en mode « Effets » : la liste des effets du jeu (`5_data/effets/`), chacun avec sa couleur.
## L'effet choisi est celui que Ctrl+clic place dans la salle ; sous la liste, ses réglages (débit, durée de vie, taille,
## additif). Les réglages se modifient à l'étape des paramètres du jeu.

## L'effet `effect_id` vient d'être choisi pour être placé.
signal effect_chosen(effect_id: StringName)

## Le côté de la pastille de couleur d'un effet, en pixels.
const SWATCH_SIZE: int = 16

var _effects: Array[FxDef] = []
var _list: ItemList = ItemList.new()
var _details: Label = Label.new()


## Remplit la liste avec les effets `effects`.
func setup(effects: Array[FxDef]) -> void:
	_effects = effects
	var title: Label = Label.new()
	title.text = "Effets"
	add_child(title)
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for effect: FxDef in effects:
		var swatch: Image = Image.create_empty(SWATCH_SIZE, SWATCH_SIZE, false, Image.FORMAT_RGBA8)
		swatch.fill(effect.color)
		_list.add_item(effect.display_name, ImageTexture.create_from_image(swatch))
	_list.item_selected.connect(choose)
	add_child(_list)
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_details)


## Choisit l'effet de la ligne `index`.
func choose(index: int) -> void:
	if index < 0 or index >= _effects.size():
		return
	var effect: FxDef = _effects[index]
	_list.select(index)
	_details.text = "%d particules/s, vie %.1f s, taille %.2f m%s" % [roundi(effect.rate), effect.lifetime_s,
			effect.size_m, ", additif" if effect.additive else ""]
	effect_chosen.emit(effect.id)


## Le texte des réglages de l'effet choisi.
func details() -> String:
	return _details.text
