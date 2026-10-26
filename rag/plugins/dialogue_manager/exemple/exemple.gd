extends Node
## Exemple minimal de Dialogue Manager (v4.1.0, GDScript) : un dialogue écrit dans sa syntaxe (titre, réplique,
## choix), lu ligne par ligne par l'autoload DialogueManager, comme le ferait une bulle de dialogue.

const TEXTE: String = """~ start
Marchand: Bonjour, voyageur.
- Qui es-tu ?
	Marchand: Un marchand de potions.
- Au revoir.
=> END
"""


func _ready() -> void:
	# Dans un projet, le dialogue est un fichier .dialogue importé ; ici, il est compilé depuis le texte.
	var dialogue := DialogueManager.create_resource_from_text(TEXTE) as DialogueResource
	var accueil: DialogueLine = await DialogueManager.get_next_dialogue_line(dialogue, "start")
	var choix := accueil.responses[0] as DialogueResponse
	var reponse: DialogueLine = await DialogueManager.get_next_dialogue_line(dialogue, choix.next_id)
	if accueil.character == "Marchand" and accueil.text == "Bonjour, voyageur." and accueil.responses.size() == 2 \
			and reponse.text == "Un marchand de potions.":
		print("EXEMPLE VERIFIE : « %s » ; choix « %s » → « %s »" % [accueil.text, choix.text, reponse.text])
	else:
		push_error("réplique « %s », %d choix, suite « %s »" % [accueil.text, accueil.responses.size(), reponse.text])
	get_tree().quit()
