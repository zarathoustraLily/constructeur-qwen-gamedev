extends Node3D
## Exemple minimal d'Event Audio (dépôt au commit de la branche main, GDScript) : le jeu demande un son par une
## étiquette (« pas+herbe+mouille ») ; la banque répond avec l'événement le plus précis qu'elle connaît, en retirant
## les étiquettes depuis la fin (« pas+herbe », puis « pas »).

const IMAGES: int = 60

var _choisis: PackedStringArray = []
var _emetteurs: Array = []
var _image: int = 0


func _ready() -> void:
	var banque := EAEventBank.new()
	banque.entries = [_evenement("pas"), _evenement("pas+herbe")]
	EventAudio.register_event_bank(banque)
	var source := Node3D.new()
	add_child(source)
	for demande: String in ["pas+herbe+mouille", "pas+pierre"]:
		var emetteur: Variant = EventAudio.play_3d(demande, source)
		_emetteurs.append(emetteur)
		_choisis.append(emetteur.event.trigger_tags if emetteur != null else "aucun")


## Un événement : ses étiquettes, son son (ici 0,1 s de silence) et ses réglages de lecture.
func _evenement(etiquettes: String) -> EAEvent:
	var son := AudioStreamWAV.new()
	son.format = AudioStreamWAV.FORMAT_16_BITS
	son.mix_rate = 22050
	son.data = PackedByteArray()
	son.data.resize(4410)  # 2 205 échantillons de 16 bits : 0,1 s
	var evenement := EAEvent.new()
	evenement.trigger_tags = etiquettes
	evenement.audio_streams = [son]
	evenement.probability_weights = [1.0]
	evenement.playback_settings = EAEventPlaybackSettings.new()
	return evenement


func _physics_process(_delta: float) -> void:
	_image += 1
	if _image < IMAGES:
		return
	set_physics_process(false)  # la suite attend : ne pas repasser ici à l'image suivante
	if _choisis == PackedStringArray(["pas+herbe", "pas"]):
		print("EXEMPLE VERIFIE : « pas+herbe+mouille » → %s ; « pas+pierre » → %s" % [_choisis[0], _choisis[1]])
	else:
		push_error("événements choisis : %s" % _choisis)
	# Un son encore joué à la sortie fuit : l'arrêter, puis laisser le serveur audio le relâcher (temps réel).
	for emetteur: Variant in _emetteurs:
		if emetteur != null:
			EventAudio.stop(emetteur)
	for _attente: int in 3:
		OS.delay_msec(30)
		await get_tree().process_frame
	get_tree().quit()
