class_name AssetSource extends RefCounted
## Un dossier où chercher des assets, et la catégorie de ce qu'il contient (un dossier de héros, un d'ennemis…).

## Le dossier : un chemin absolu (D:/…), ou res:// et user://.
var folder: String = ""
## La catégorie des assets trouvés dans ce dossier : une de ViewerConfig.CATEGORIES.
var category: String = ""


func _init(p_folder: String = "", p_category: String = "") -> void:
	folder = p_folder
	category = p_category
