class_name AssetSearch
extends RefCounted
## La recherche de la palette, sans réseau ni index externe : chaque mot de la requête doit se trouver dans
## l'identifiant, les mots de recherche ou la catégorie de l'asset (un « et » entre les mots). Majuscules et accents ne
## comptent pas : « Tôle » trouve `sol_tole`. Les résultats viennent dans cet ordre : identifiant exact, identifiant qui
## commence par la requête, puis les autres ; à rang égal, par ordre alphabétique.

## Les lettres accentuées et leur lettre de base.
const ACCENTS: Dictionary[String, String] = {
	"à": "a", "â": "a", "ä": "a", "é": "e", "è": "e", "ê": "e", "ë": "e", "î": "i", "ï": "i", "ô": "o", "ö": "o",
	"ù": "u", "û": "u", "ü": "u", "ç": "c",
}

# Les assets indexés, en tableaux parallèles : l'identifiant, sa clé normalisée, et tout le texte où chercher.
var _ids: Array[StringName] = []
var _keys: PackedStringArray = PackedStringArray()
var _texts: PackedStringArray = PackedStringArray()


## Indexe les assets de `catalog`.
func setup(catalog: AssetCatalogDef) -> void:
	_ids.clear()
	_keys = PackedStringArray()
	_texts = PackedStringArray()
	for asset: AssetDef in catalog.assets:
		var words: PackedStringArray = PackedStringArray([normalize(String(asset.id)), normalize(String(asset.category))])
		for tag: String in asset.tags:
			words.append(normalize(tag))
		_ids.append(asset.id)
		_keys.append(normalize(String(asset.id)))
		_texts.append(" ".join(words))


## Les identifiants des assets qui répondent à `query`, du meilleur au moins bon ; tous si la requête est vide.
func search(query: String) -> Array[StringName]:
	var words: PackedStringArray = normalize(query).split(" ", false)
	var joined: String = " ".join(words)
	var found: Array[int] = []
	var ranks: Array[int] = []
	for index: int in _ids.size():
		var matches: bool = true
		for word: String in words:
			if not _texts[index].contains(word):
				matches = false
				break
		if matches:
			found.append(index)
			ranks.append(0 if _keys[index] == joined else (1 if _keys[index].begins_with(joined) else 2))
	var order: Array[int] = []
	order.assign(range(found.size()))
	order.sort_custom(func(a: int, b: int) -> bool:
		return ranks[a] < ranks[b] or (ranks[a] == ranks[b] and _keys[found[a]] < _keys[found[b]]))
	var result: Array[StringName] = []
	for position_in_found: int in order:
		result.append(_ids[found[position_in_found]])
	return result


## `text` en minuscules, sans accents, les tirets bas changés en espaces.
static func normalize(text: String) -> String:
	var result: String = text.to_lower()
	for letter: String in ACCENTS:
		result = result.replace(letter, ACCENTS[letter])
	return result.replace("_", " ").strip_edges()
