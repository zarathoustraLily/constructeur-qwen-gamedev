"""Les règles d'architecture Godot vérifiées (document de laurent du 2026-10-11, section 5).

Seules les règles confirmées ou corrigées par une source, et les choix que la section 9 marque
comme mécaniques, deviennent des contrôles (règle 2 : aucun LLM). Les autres sont des
jugements : elles sont rappelées à Qwen dans les fiches, jamais jugées.
"""

from __future__ import annotations

# id → (nature, texte court) ; nature : confirmée, corrigée, choix.
REGLES: dict[str, tuple[str, str]] = {
    "ORG-01": ("corrigée", "aucun nouveau dossier à la racine de res:// ; seule exception : addons/"),
    "DOSSIERS": ("confirmée", "chaque dossier ne dépend que de ceux de son tableau ; une entité ne dépend "
                              "d'aucune autre entité ; 5_data et 6_assets ne contiennent aucun code"),
    "ARC-02": ("confirmée", "la simulation décide, la présentation lit l'état ou écoute des signaux"),
    "ARC-03": ("corrigée", "un script de simulation ne référence ni sprite, ni nœud audio, ni particules : "
                           "la présentation va dans un script <nom>_view.gd à côté"),
    "ARC-04": ("confirmée", "les entrées sont des intentions : seul un script <nom>_input.gd lit Input, "
                            "la logique consomme des commandes"),
    "ARC-06": ("corrigée", "une dépendance extérieure à la scène est fournie par le parent (@export typé, "
                           "setup() ou signal) ; ni get_node(\"/root/...\") ni chemin remontant \"../\" ; "
                           "les groupes restent permis"),
    "ARC-07": ("confirmée", "appeler vers le bas, signaler vers le haut"),
    "ARC-08": ("confirmée", "une dépendance obligatoire manquante produit une erreur explicite dès _ready() ou setup()"),
    "ARC-09": ("confirmée", "un autoload seulement s'il est global, persiste entre scènes et ne gère que ses "
                            "données ; les bruitages restent dans la scène qui les émet, l'audio global ne fait "
                            "que la musique et le volume"),
    "DAT-01": ("confirmée", "aucun chiffre d'équilibrage (dégâts, vitesses, durées, portées…) dans un script : "
                            "il vit dans un .tres de 5_data"),
    "DAT-02": ("confirmée", "chaque famille de données a une classe Resource avec class_name dans 1_core ; "
                            "jamais de classe interne comme Resource"),
    "DAT-04": ("confirmée", "définition immuable, état séparé : on n'écrit jamais dans une Resource de "
                            "définition pendant la partie"),
    "DAT-05": ("corrigée", "un .tres chargé est le même objet pour tous ; duplicate() laisse partagées les "
                           "sous-ressources, duplicate_deep() les copie"),
    "DAT-06": ("choix", "chaque définition a un id unique en snake_case, jamais renommé"),
    "DAT-08": ("confirmée", "la sauvegarde contient l'état logique (identifiants, progression, graine) et un "
                            "numéro de version, pas l'arbre de scènes"),
    "SIM-01": ("confirmée", "le gameplay qui dépend du temps tourne dans _physics_process ; _process est "
                            "réservé à l'affichage"),
    "SIM-02": ("corrigée", "quand l'ordre compte, process_physics_priority prend une valeur nommée de "
                           "1_core/process_order.gd, jamais un nombre écrit sur place"),
    "SIM-05": ("confirmée", "les états exclusifs sont une machine à états, pas des booléens"),
    "SIM-06": ("confirmée", "signaux typés, nommés au passé ; signal local d'abord, autoload seulement pour ce "
                            "qui traverse les scènes"),
    "SIM-07": ("confirmée", "une étape critique est un appel direct, jamais une chaîne de signaux"),
    "SIM-08": ("corrigée", "une durée de gameplay s'arrête en pause : nœud Timer, décompte dans la logique, "
                           "ou get_tree().create_timer(durée, false)"),
    "SIM-09": ("corrigée", "un tirage qui compte passe par un RandomNumberGenerator reçu en dépendance ; "
                           "randf(), randi(), pick_random() seulement pour le cosmétique (scripts _view)"),
    "SIM-10": ("corrigée", "le calcul des dégâts et des statuts est une fonction testable sans scène ; la "
                           "détection (Area3D, move_and_slide) reste dans les composants"),
    "COD-01": ("confirmée", "classes et nœuds en PascalCase ; fonctions, variables, signaux et fichiers en "
                            "snake_case ; constantes en CONSTANT_CASE"),
    "COD-02": ("choix", "paramètres, retours, variables, constantes typés ; tableaux et dictionnaires typés ; "
                        "UNTYPED_DECLARATION en erreur dans project.godot"),
    "COD-04": ("corrigée", "syntaxe Godot 4 seulement : await, @export, @onready, CharacterBody, instantiate(), "
                           "signal.connect(callable)"),
    "COD-05": ("confirmée", "pas d'optimisation (pool, threads) sans mesure au profileur"),
    "QA-01": ("choix", "les tests sont dans 7_tests, en miroir du chemin testé"),
    "QA-03": ("choix", "un agent ne modifie que les fichiers nécessaires à sa tâche"),
    "QA-07": ("choix", "un test n'est déclaré réussi que s'il a été exécuté"),
    "QA-08": ("choix", "compte rendu de fin de tâche : fichiers, responsabilités, dépendances, tests, "
                       "problèmes, règles concernées"),
}

# Règles jugées mécaniquement (section 9) ; les autres ne servent qu'à informer.
MECANIQUES = ("ORG-01", "DOSSIERS", "ARC-03", "ARC-04", "ARC-06", "DAT-01", "DAT-02", "SIM-01", "SIM-02",
              "SIM-08", "SIM-09", "COD-01", "COD-02", "COD-04", "QA-01")
SESSION = ("QA-03", "QA-07", "QA-08")


def texte(regle: str) -> str:
    """« SIM-08 : … » pour une fiche ou un retour d'outil."""
    return f"{regle} : {REGLES[regle][1]}"
