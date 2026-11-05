class_name BenchInput
extends Node
## Le clavier et la manette sur le banc d'essai : W A S D ou le stick gauche font marcher le modèle, Espace ou A joue
## l'attaque, H ou B le coup reçu. Les touches viennent des actions du projet (`bench_*`, section `[input]`) : le script
## ne connaît ni une touche ni un bouton, seulement des actions. C'est le seul script du banc qui lit `Input`.

## Vrai quand le banc est montré ; sinon, le script ne lit rien.
var active: bool = false
var _bench: BenchView
var _attack_was_down: bool = false
var _hit_was_down: bool = false


## Commande le banc `bench`.
func setup(bench: BenchView) -> void:
	_bench = bench


func _physics_process(delta: float) -> void:
	if active:
		read_frame(delta)


## Lit les actions pour une image de `delta` secondes, et commande le banc.
func read_frame(delta: float) -> void:
	_bench.step(Input.get_vector(&"bench_left", &"bench_right", &"bench_up", &"bench_down"), delta)
	var attack_down: bool = Input.is_action_pressed(&"bench_attack")
	if attack_down and not _attack_was_down:
		_bench.play_state(&"attack")
	_attack_was_down = attack_down
	var hit_down: bool = Input.is_action_pressed(&"bench_hit")
	if hit_down and not _hit_was_down:
		_bench.play_state(&"hit")
	_hit_was_down = hit_down
