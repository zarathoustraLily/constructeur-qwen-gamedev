# Signal Lens (voir les connexions de signaux pendant la partie)

Version vérifiée : v1.4.1 (2025-09-16), GDScript, licence MIT, dépôt `yannlemos/signal-lens` (355 étoiles au
2026-10-22). Plugin activé sans erreur dans l'éditeur 4.7.2 : `python -m usine.rag.plugins verifier signal_lens`.

## Ce qu'il résout

Un débogueur visuel des signaux : pendant que le jeu tourne depuis l'éditeur, on donne le chemin d'un nœud (dans
l'arbre distant) et le plugin dessine le graphe de tous les signaux de ce nœud et de leurs connexions, signaux
intégrés ou personnalisés, autoloads compris, et montre leurs émissions (description de son `plugin.cfg`).

## Le choisir, ou Godot seul ?

- **Godot seul** : `get_signal_connection_list()`, `get_incoming_connections()` et l'onglet « Nœud → Signaux » de
  l'éditeur montrent les connexions déclarées dans la scène, pas celles faites par le code pendant la partie.
- **Signal Lens** : quand un signal « ne part pas » ou part vers le mauvais nœud et que les connexions sont faites par
  le code, au lancement ou plus tard.

## Fonctionnement (lu dans le code de la v1.4.1)

- L'autoload `SignalLens` (`res://addons/signal_lens/autoload/signal_lens_autoload.gd`), ajouté à l'activation du
  plugin, parle à l'éditeur par le débogueur (`EngineDebugger.register_message_capture("signal_lens", …)`,
  messages `signal_lens:incoming_node_signal_data` et `signal_lens:incoming_node_signal_emission`).
- Le panneau se trouve dans le débogueur de l'éditeur ; il n'a d'effet que si le jeu est lancé depuis l'éditeur.

## Installation

Copier `signal_lens/` dans `addons/` (l'archive de la version ne contient pas le dossier `addons/`), puis activer
le plugin.

## Pièges

- Outil d'éditeur seulement : sans débogueur attaché (jeu exporté, tests sans fenêtre), il n'a rien à montrer.
- Les connexions dessinées sont celles du moment où on interroge le nœud.
