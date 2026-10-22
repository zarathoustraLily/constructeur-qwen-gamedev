extends GdUnitTestSessionHook
## Crochet de fin de session de GdUnit4, enregistré dans project.godot ([gdunit4] hooks/session_hooks). Un son qui
## joue encore quand le jeu quitte fuit (« ObjectDB instances were leaked at exit », « resources still in use at
## exit ») : après la dernière suite, quelle qu'elle soit, on laisse au serveur audio, qui tourne en temps réel, le
## temps de relâcher les sons des nœuds libérés (comme l'autoload de capture de l'usine).


func _init() -> void:
	super("Silence audio", "Laisse le serveur audio relâcher les sons avant la sortie.")


## Rien à préparer avant les suites.
func startup(_session: GdUnitTestSession) -> GdUnitResult:
	return GdUnitResult.success()


## Après les suites : trois attentes de 30 ms de temps réel, chacune suivie d'une image.
func shutdown(_session: GdUnitTestSession) -> GdUnitResult:
	for _wait: int in 3:
		OS.delay_msec(30)
		await (Engine.get_main_loop() as SceneTree).process_frame
	return GdUnitResult.success()
