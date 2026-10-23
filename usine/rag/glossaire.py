"""Demandes en français, documentation en anglais : glossaire déterministe des termes du jeu vidéo et de Godot.

La documentation de Godot et les démos sont en anglais ; laurent écrit en français. Avant la recherche plein texte,
chaque mot de la demande est remplacé par un groupe : le mot lui-même, ses traductions anglaises et, quand il y en a,
les classes Godot qui le portent. Les mots vides (articles, prépositions) sont retirés. Aucun modèle : une table.

    groupes("aller vers la cible en évitant les obstacles")
    → [["aller", "go", "move"], ["vers", "toward"], ["cible", "target"], ["evitant", "avoid", "avoidance"],
       ["obstacles", "obstacle", "NavigationObstacle3D", "avoidance"]]
"""

from __future__ import annotations

import re
import unicodedata

# Mots vides du français (et quelques mots de consigne sans contenu) : ils ne cherchent rien dans une doc anglaise.
VIDES = set("""
a à au aux avec ce ces cet cette ci comme comment dans de des du elle elles en entre est et être faire fait
il ils je la le les leur leurs lui ma mais me mes moi mon ne nos notre nous on ou où par pas peut plus pour
qu que quel quelle quelles quels qui sa sans se ses si son sont sur ta te tes toi ton tous tout toute toutes
tu un une vos votre vous y ça cela celui celle ceux sous chez donc alors puis quand dont ainsi aussi bien très
écrire ecrire créer creer ajouter mettre utiliser faut veux voudrais doit doivent
""".split())

# Expressions de plusieurs mots, cherchées avant les mots seuls (forme sans accents, en minuscules).
EXPRESSIONS = {
    "machine a etats": ["state machine", "StateMachine", "AnimationNodeStateMachine"],
    "machine d etats": ["state machine", "StateMachine"],
    "arbre de comportement": ["behavior tree", "BehaviorTree"],
    "point de vue": ["camera", "viewpoint"],
    "a la troisieme personne": ["third person", "SpringArm3D"],
    "troisieme personne": ["third person", "SpringArm3D"],
    "premiere personne": ["first person"],
    "barre de vie": ["health bar", "ProgressBar"],
    "points de vie": ["health", "hit points"],
    "ecran de chargement": ["loading screen", "ResourceLoader"],
    "chargement en arriere plan": ["load_threaded_request", "ResourceLoader"],
    "fondu au noir": ["fade", "Tween"],
    "zone morte": ["deadzone", "dead zone"],
    "retour haptique": ["vibration", "start_joy_vibration"],
    "maillage procedural": ["procedural mesh", "SurfaceTool", "ArrayMesh"],
    "generation procedurale": ["procedural generation", "noise", "FastNoiseLite"],
    "nuage de points": ["point cloud"],
    "couche de collision": ["collision layer", "collision_layer"],
    "masque de collision": ["collision mask", "collision_mask"],
    "lancer de rayon": ["raycast", "RayCast3D", "intersect_ray"],
    "pas de temps fixe": ["physics_process", "fixed timestep"],
    "boucle de jeu": ["game loop", "_process"],
    "gestion de la memoire": ["memory", "free", "queue_free", "RefCounted"],
    "fuite de memoire": ["memory leak", "leaked", "orphan"],
    "temps reel": ["real time"],
    "ombre portee": ["shadow", "shadow_enabled"],
    "post traitement": ["post processing", "Environment", "CompositorEffect"],
    "plein ecran": ["fullscreen", "window_set_mode"],
    "menu pause": ["pause menu", "process_mode"],
    "mise en pause": ["pause", "paused", "process_mode"],
    "sauvegarde de partie": ["save game", "FileAccess", "ConfigFile"],
    "boite de dialogue": ["dialog", "AcceptDialog"],
    "barre de progression": ["progress bar", "ProgressBar"],
    "texte a l ecran": ["label", "Label"],
    "suivi de chemin": ["path follow", "PathFollow3D"],
    "recherche de chemin": ["pathfinding", "NavigationAgent3D", "AStar3D"],
    "carte de navigation": ["navigation map", "NavigationServer3D", "NavigationRegion3D"],
    "secousse de camera": ["camera shake", "shake", "trauma"],
    "systeme de particules": ["particles", "GPUParticles3D", "CPUParticles3D"],
    "nuanceur": ["shader"],
}

# Mots seuls (forme sans accents, en minuscules, singulier) : traductions et classes Godot.
MOTS = {
    # jeu, entités
    "joueur": ["player"], "ennemi": ["enemy", "mob"], "boss": ["boss"], "personnage": ["character", "CharacterBody3D"],
    "cible": ["target"], "arme": ["weapon"], "projectile": ["projectile", "bullet"], "balle": ["bullet", "ball"],
    "tir": ["shoot", "fire"], "tirer": ["shoot", "fire"], "degat": ["damage"], "degats": ["damage"],
    "vie": ["health", "life"], "sante": ["health"], "soin": ["heal"], "mort": ["death", "die"], "mourir": ["die"],
    "score": ["score"], "niveau": ["level"], "vague": ["wave"], "objet": ["item", "object"],
    "inventaire": ["inventory", "item"], "boutique": ["shop", "store"], "piece": ["coin"], "quete": ["quest"],
    "dialogue": ["dialogue", "dialog"], "competence": ["ability", "skill"], "amelioration": ["upgrade"],
    "kart": ["kart", "vehicle", "VehicleBody3D"], "voiture": ["car", "vehicle", "VehicleBody3D"],
    "roue": ["wheel", "VehicleWheel3D"], "course": ["race", "run"], "circuit": ["track", "race"],
    "tour": ["lap", "turn", "tower"], "batiment": ["building"], "immeuble": ["building"], "facade": ["facade"],
    "fenetre": ["window"], "porte": ["door"], "toit": ["roof"], "mur": ["wall"], "sol": ["floor", "ground"],
    "plafond": ["ceiling"], "escalier": ["stairs"], "rue": ["street", "road"], "route": ["road"],
    "terrain": ["terrain", "heightmap"], "eau": ["water"], "herbe": ["grass"], "arbre": ["tree"],
    "rocher": ["rock"], "nuage": ["cloud"], "ciel": ["sky", "Sky"], "vent": ["wind"], "poisson": ["fish"],
    # mouvement, physique
    "deplacement": ["movement", "move"], "deplacer": ["move"], "bouger": ["move"], "aller": ["go", "move"],
    "vers": ["toward"], "marcher": ["walk"], "courir": ["run"], "sauter": ["jump"], "saut": ["jump"],
    "esquive": ["dodge", "dash"], "dash": ["dash"], "tomber": ["fall"], "chute": ["fall"],
    "vitesse": ["velocity", "speed"], "acceleration": ["acceleration"], "freinage": ["brake"], "frein": ["brake"],
    "gravite": ["gravity"], "friction": ["friction"], "rebond": ["bounce"], "glisser": ["slide"],
    "physique": ["physics"], "collision": ["collision", "CollisionShape3D"], "forme": ["shape", "Shape3D"],
    "corps": ["body", "PhysicsBody3D"], "zone": ["area", "Area3D"], "rayon": ["ray", "raycast", "RayCast3D", "radius"],
    "obstacle": ["obstacle", "NavigationObstacle3D", "avoidance"], "eviter": ["avoid", "avoidance"],
    "evitant": ["avoid", "avoidance"], "evitement": ["avoidance"], "navigation": ["navigation", "NavigationAgent3D"],
    "chemin": ["path", "Path3D"], "poursuite": ["chase", "pursue", "follow"], "poursuivre": ["chase", "follow"],
    "suivre": ["follow"], "fuir": ["flee"], "patrouille": ["patrol"], "errer": ["wander"], "errance": ["wander"],
    "rotation": ["rotation", "rotate"], "tourner": ["rotate", "turn"], "orientation": ["orientation", "basis"],
    "regarder": ["look_at", "look"], "direction": ["direction"], "position": ["position"], "distance": ["distance"],
    "interpolation": ["interpolation", "lerp"], "lissage": ["smoothing", "lerp"], "ressort": ["spring", "SpringArm3D"],
    "recul": ["knockback", "recoil"], "impact": ["impact", "hit"], "touche": ["hit", "key"],
    # entrées
    "manette": ["joypad", "gamepad", "controller", "joystick"], "clavier": ["keyboard", "InputEventKey"],
    "souris": ["mouse", "InputEventMouse"], "entree": ["input", "Input"], "commande": ["input", "command", "action"],
    "action": ["action", "InputMap"], "bouton": ["button", "Button"], "stick": ["stick", "joy_axis"],
    "vibration": ["vibration", "rumble", "start_joy_vibration"], "remappage": ["remap", "InputMap"],
    "tactile": ["touch", "InputEventScreenTouch"],
    # caméra, rendu
    "camera": ["camera", "Camera3D", "Camera2D"], "ecran": ["screen", "viewport"], "rendu": ["rendering", "render"],
    "lumiere": ["light", "Light3D", "DirectionalLight3D"], "eclairage": ["lighting", "light"],
    "ombre": ["shadow"], "soleil": ["sun", "DirectionalLight3D"], "nuit": ["night"], "jour": ["day"],
    "brouillard": ["fog"], "reflet": ["reflection"], "transparence": ["transparency", "alpha"],
    "couleur": ["color", "Color"], "materiau": ["material", "StandardMaterial3D"], "texture": ["texture", "Texture2D"],
    "maillage": ["mesh", "Mesh", "MeshInstance3D"], "modele": ["model", "mesh"], "sommet": ["vertex"],
    "triangle": ["triangle"], "normale": ["normal"], "uv": ["uv"], "shader": ["shader", "Shader"],
    "effet": ["effect"], "particule": ["particles", "GPUParticles3D"], "trainee": ["trail"],
    "explosion": ["explosion"], "fumee": ["smoke"], "feu": ["fire"], "etincelle": ["spark"],
    "contour": ["outline"], "dissolution": ["dissolve"], "flou": ["blur"], "lueur": ["glow"],
    "animation": ["animation", "AnimationPlayer", "AnimationTree"], "sprite": ["sprite", "Sprite2D"],
    "tuile": ["tile", "TileMapLayer"], "carte": ["map"], "2d": ["2d"], "3d": ["3d"],
    "visibilite": ["visibility", "visible"], "lod": ["lod"], "instance": ["instance", "MultiMeshInstance3D"],
    # interface, audio
    "interface": ["ui", "Control"], "menu": ["menu"], "hud": ["hud"], "texte": ["text", "Label"],
    "police": ["font"], "theme": ["theme", "Theme"], "focus": ["focus", "grab_focus"], "jauge": ["gauge", "ProgressBar"],
    "son": ["sound", "audio", "AudioStreamPlayer"], "musique": ["music", "AudioStreamPlayer"],
    "audio": ["audio", "AudioServer"], "volume": ["volume", "volume_db"], "bus": ["bus", "AudioServer"],
    # structure, code
    "scene": ["scene", "PackedScene"], "noeud": ["node", "Node"], "enfant": ["child"], "parent": ["parent"],
    "signal": ["signal"], "etat": ["state"], "transition": ["transition"],
    "minuterie": ["timer", "Timer"], "minuteur": ["timer", "Timer"], "delai": ["delay", "timer"],
    "temps": ["time", "delta"], "image": ["frame", "image"], "seconde": ["second"],
    "ressource": ["resource", "Resource"], "donnee": ["data"], "reglage": ["setting", "settings"],
    "parametre": ["parameter", "setting"], "sauvegarde": ["save"], "sauvegarder": ["save"], "charger": ["load"],
    "chargement": ["loading", "load"], "fichier": ["file", "FileAccess"], "dossier": ["directory", "DirAccess"],
    "singleton": ["singleton", "autoload"], "autoload": ["autoload", "singleton"], "global": ["global", "autoload"],
    "test": ["test"], "tests": ["test"], "erreur": ["error"], "bug": ["bug", "error"], "plugin": ["plugin", "EditorPlugin"],
    "outil": ["tool"], "editeur": ["editor"], "procedural": ["procedural"], "bruit": ["noise", "FastNoiseLite"],
    "aleatoire": ["random", "RandomNumberGenerator"], "graine": ["seed"], "hasard": ["random"],
    "generer": ["generate"], "generation": ["generation", "generate"], "grille": ["grid"],
    "optimisation": ["optimization", "performance"], "performance": ["performance"], "memoire": ["memory"],
    "allocation": ["allocation"], "pool": ["pool"], "liberer": ["free", "queue_free"], "fuite": ["leak"],
    "pause": ["pause"], "fondu": ["fade"], "progression": ["progress"],
    "secousse": ["shake"], "tremblement": ["shake"], "ralenti": ["slow motion", "time_scale"],
}


def sans_accents(mot: str) -> str:
    return "".join(c for c in unicodedata.normalize("NFD", mot) if unicodedata.category(c) != "Mn")


def _forme(mot: str) -> str:
    """Forme de recherche dans la table : minuscules, sans accents, singulier simple."""
    m = sans_accents(mot.lower())
    if m in MOTS:
        return m
    for fin in ("s", "x"):
        if m.endswith(fin) and m[:-1] in MOTS:
            return m[:-1]
    return m


def groupes(requete: str) -> list[list[str]]:
    """Un groupe par notion de la demande : le mot (ou l'expression), puis ses équivalents anglais et Godot."""
    mots = re.findall(r"[\w@]+", requete)
    normes = [sans_accents(w.lower()) for w in mots]
    resultat: list[list[str]] = []
    i = 0
    while i < len(mots):
        pris = False
        for taille in (4, 3, 2):
            expr = " ".join(normes[i:i + taille])
            if len(normes[i:i + taille]) == taille and expr in EXPRESSIONS:
                resultat.append([" ".join(mots[i:i + taille]), *EXPRESSIONS[expr]])
                i += taille
                pris = True
                break
        if pris:
            continue
        w, n = mots[i], normes[i]
        i += 1
        if n in VIDES or len(w) < 2:
            continue
        equivalents = MOTS.get(_forme(w), [])
        resultat.append([w, *[e for e in equivalents if e.lower() != w.lower()]])
    return resultat
