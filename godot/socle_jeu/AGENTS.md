# EN PERMANENCE
Tu es développeur de jeux sous Godot 4, en GDScript typé.
Rangement (détail et exemples à imiter : ORGANISATION.md) :
- 0_autoload/ : ce qui dirige le jeu (game_flow, game_state, event_bus, audio_manager, trace, capture)
- 1_core/ : les mécanismes sans contenu de jeu (state_machine/, components/, step/, data/)
- 2_sequence/ : le déroulé (sequence.tres, cinematics/, menus/, levels/)
- 3_entities/ : les acteurs, scène + script + states/ ensemble (player/, enemies/<type>/, boss/, projectiles/, effects/)
- 4_ui/ : hud/, overlays/
- 5_data/ : les réglages en ressources .tres, aucun code
- 6_assets/ : modèles, textures, audio, shaders, polices, aucun code
- 7_tests/ : en miroir des dossiers ci-dessus
Qui connaît qui : 1_core ne référence aucun autre dossier. 0_autoload s'appuie sur 1_core et lit 2_sequence. 2_sequence assemble 3_entities et 4_ui. 3_entities utilise 1_core et 5_data.
Conventions : @export var (jamais export var), signaux typés, class_name pour les types, réglages dans des .tres, une machine à états pour les comportements, un composant par responsabilité, un test par comportement.
Modèle pour un ennemi : 5_data/enemies/<type>.tres (réglages), 3_entities/enemies/<type>/<type>.tscn et <type>.gd, states/ (ses états), posé dans 2_sequence/levels/<niveau>/.

# AVANT CHAQUE ÉTAPE (obligatoire)
1. Ouvre plan.md. Si l'étape d'où vient la demande a un sous-plan, prends la première sous-étape non cochée. Sinon, écris ce sous-plan en étapes courtes (une entité, un état, un écran), puis prends la première.
2. Écris en trois lignes : le but, le type d'action, les fichiers visés selon le rangement. Puis appelle prepare_action avec ces trois lignes et les besoins cochés dans sa liste : il rend l'exemple à imiter et une fiche par besoin.
3. Liste les classes, méthodes et signaux Godot nécessaires, avec leurs noms exacts.
4. Cherche chacun avec l'outil de recherche dans la doc, 5 recherches au plus par sous-étape. Recopie la signature trouvée avant d'écrire. Ne conclus jamais qu'une classe n'existe pas sans l'avoir cherchée.

# APRÈS CHAQUE ACTION (obligatoire)
- Après chaque script : lance les tests (ou la scène s'il n'y a pas de test) et lis le résultat avant d'écrire à nouveau.
- Avant de réécrire un fichier : dis ce qui change. Si rien ne change, n'écris pas.
- Après une erreur du moteur : cherche dans la doc le membre en cause avant de corriger.
- Après chaque capture (capture_frames) : écris un verdict en trois lignes : ce que tu vois, si c'est lisible, ce qui cloche.
- Sous-étape finie et tests verts : coche-la dans plan.md, en une seule écriture.
