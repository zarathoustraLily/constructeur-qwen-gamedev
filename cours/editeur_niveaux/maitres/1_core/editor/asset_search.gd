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

var _entries: Array[Dictionary] = []


## Indexe les assets de `catalog`.
func setup(catalog: AssetCatalogDef) -> void:
	_entries.clear()
	for asset: AssetDef in catalog.assets:
		var words: PackedStringArray = PackedStringArray([normalize(String(asset.id)), normalize(String(asset.category))])
		for tag: String in asset.tags:
			words.append(normalize(tag))
		_entries.append({"id": asset.id, "key": normalize(String(asset.id)), "text": " ".join(words)})


## Les identifiants des assets qui répondent à `query`, du meilleur au moins bon ; tous si la requête est vide.
func search(query: String) -> Array[StringName]:
	var words: PackedStringArray = normalize(query).split(" ", false)
	var joined: String = " ".join(words)
	var found: Array[Dictionary] = []
	for entry: Dictionary in _entries:
		var matches: bool = true
		for word: String in words:
			if not String(entry["text"]).contains(word):
				matches = false
				break
		if matches:
			var rank: int = 2
			if entry["key"] == joined:
				rank = 0
			elif String(entry["key"]).begins_with(joined):
				rank = 1
			found.append({"id": entry["id"], "key": entry["key"], "rank": rank})
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["rank"] < b["rank"] or (a["rank"] == b["rank"] and String(a["key"]) < String(b["key"])))
	var result: Array[StringName] = []
	for entry: Dictionary in found:
		result.append(entry["id"])
	return result


## `text` en minuscules, sans accents, les tirets bas changés en espaces.
static func normalize(text: String) -> String:
	var result: String = text.to_lower()
	for letter: String in ACCENTS:
		result = result.replace(letter, ACCENTS[letter])
	return result.replace("_", " ").strip_edges()
