"""Les fautes de plomberie posées dans un petit projet sain (`plomberie_projet`), tirées des échecs relevés par laurent
le 2026-11-18 sur un projet écrit par un modèle : autoload sans guillemets ou non enregistré, `class_name` manquant,
nœud ou scène absents, signal non branché, fonction qui ne fait rien, caméra absente, `config_version` inventé…

Chaque faute est un seul remplacement de texte, unique dans son fichier : `juste` → `faux`. La correction est
l'inverse (`edit` d'OpenCode : `oldString` = `faux`, `newString` = `juste`). `cause` est l'explication juste, écrite
d'après le projet et l'API ; `symptome` est ce que verrait le joueur ou le développeur ; `intention`, quand la faute est
un oubli, est la demande de création qui y mène (« ajoute X »). `reimport` : la correction change un nom de classe, le
cache des classes de Godot doit être refait (`--import`) avant de relancer.
"""

from __future__ import annotations

from dataclasses import dataclass

from usine.paires.plomberie_projet import Theme, chemins, fichiers


@dataclass
class Faute:
    genre: str
    fichier: str
    juste: str
    faux: str
    cause: str
    symptome: str
    intention: str | None = None
    reimport: bool = False
    # Les fautes des autres petits projets (plomberie_kits) le disent elles-mêmes.
    silence: bool = False
    ferme: bool = False

    @property
    def projet_ferme(self) -> bool:
        """Godot n'ouvre pas le projet : les tests n'y tournent pas (GdUnit4 attend alors jusqu'au délai, mesuré le
        2026-11-19 : 300 s avec `config_version=6`)."""
        return self.ferme or self.genre in ("autoload_guillemets", "config_version")

    @property
    def silencieuse(self) -> bool:
        """Aucune erreur au lancement : seuls les tests de comportement la voient."""
        return self.silence or self.genre in ("signal_non_branche", "corps_mort", "setup_oublie")

    def poser(self, f: dict[str, str]) -> dict[str, str]:
        texte = f[self.fichier]
        assert texte.count(self.juste) == 1, (self.genre, self.fichier)
        sortie = dict(f)
        sortie[self.fichier] = texte.replace(self.juste, self.faux, 1)
        assert sortie[self.fichier].count(self.faux) == 1, (self.genre, "faux non unique")
        return sortie


def fautes(th: Theme) -> list[Faute]:
    c = chemins(th)
    f = fichiers(th)
    t = th
    ligne_auto = f'{t.autoload}="*res://{c["autoload"]}"'
    connexion = f"\t\tenemy.defeated.connect({t.autoload}.add_score)\n"
    noeud = ('[node name="Health" type="Node" parent="."]\nunique_name_in_owner = true\nscript = ExtResource("3_health")\n')
    sortie: list[Faute] = [
        Faute("autoload_guillemets", c["projet"], ligne_auto, f'{t.autoload}=*res://{c["autoload"]}',
              f"Dans `project.godot`, la valeur d'un autoload est une chaîne : `{t.autoload}=\"*res://{c['autoload']}\"`. "
              "Sans guillemets, Godot ne sait pas lire la ligne et refuse d'ouvrir tout le projet ; l'étoile (« * ») "
              "reste à l'intérieur des guillemets : elle dit que l'autoload est une instance de nœud, ajoutée à l'arbre.",
              "Godot refuse d'ouvrir le projet."),
        Faute("autoload_absent", c["projet"], "[autoload]\n\n" + ligne_auto + "\n", "[autoload]\n\n",
              f"Le niveau et ses tests appellent `{t.autoload}`, mais `{t.autoload}` n'est enregistré nulle part : "
              f"`res://{c['autoload']}` existe, la section `[autoload]` de `project.godot` ne le déclare pas. Un "
              "autoload n'est un nom global que s'il y est déclaré, la valeur entre guillemets, avec l'étoile.",
              "le jeu ne démarre plus : le script du niveau refuse de se charger.",
              f"Le script `res://{c['autoload']}` tient le score de la partie. Enregistre-le comme autoload "
              f"`{t.autoload}`, pour que le niveau puisse y ajouter les points."),
        Faute("class_name_absent", c["composant"], f"class_name {t.composant} extends Node", "extends Node",
              f"`{t.composant}` est employé comme type (`res://{c['ennemi']}`, les tests), mais "
              f"`res://{c['composant']}` ne déclare plus de `class_name` : le nom n'existe pour Godot que si un script "
              f"le déclare par `class_name {t.composant}`. Après l'ajout, le cache des classes se refait par un import.",
              "plusieurs scripts refusent de se charger, alors qu'ils n'ont pas changé.",
              f"Le script `res://{c['composant']}` doit pouvoir servir de type ailleurs, sous le nom `{t.composant}`.",
              reimport=True),
        Faute("noeud_absent", c["ennemi_scene"], 'stats = ExtResource("2_stats")\n\n' + noeud,
              'stats = ExtResource("2_stats")\n',
              f"`res://{c['ennemi']}` cherche son nœud de vie par `%Health`, mais la scène "
              f"`res://{c['ennemi_scene']}` n'a plus de nœud `Health` : `_health` vaut `null`, et chaque appel sur lui "
              "échoue à l'exécution. Le nœud se déclare dans la scène, avec son script et son nom unique.",
              "les ennemis n'encaissent plus rien et la sortie se remplit d'erreurs.",
              f"La scène `res://{c['ennemi_scene']}` doit avoir son nœud de vie : un `Node` nommé `Health`, du script "
              f"`res://{c['composant']}`, accessible par `%Health`."),
        Faute("nom_unique_absent", c["ennemi_scene"], noeud, noeud.replace("unique_name_in_owner = true\n", ""),
              f"`%Health` ne trouve qu'un nœud marqué comme nom unique de la scène (« Access as Unique Name ») ; le "
              f"nœud `Health` de `res://{c['ennemi_scene']}` ne l'est plus : `unique_name_in_owner = true` manque, "
              "`_health` vaut `null`.",
              "les ennemis n'encaissent plus rien et la sortie se remplit d'erreurs."),
        Faute("scene_absente", c["niveau"], f'preload("res://{c["ennemi_scene"]}")',
              f'preload("res://3_entities/enemies/{t.dossier}/{t.dossier}_scene.tscn")',
              f"`preload` charge le fichier à l'analyse du script : `res://3_entities/enemies/{t.dossier}/"
              f"{t.dossier}_scene.tscn` n'existe pas, la scène de l'ennemi est `res://{c['ennemi_scene']}`.",
              "le niveau ne se charge plus."),
        Faute("ressource_absente", c["ennemi_scene"], f'path="res://{c["donnees"]}"',
              f'path="res://5_data/{t.dossier}.tres"',
              f"La scène de l'ennemi référence ses réglages par un chemin qui n'existe pas (`res://5_data/{t.dossier}"
              f".tres`) : ils sont dans `res://{c['donnees']}`. Sans eux, `stats` vaut `null` au `_ready`.",
              "les ennemis apparaissent sans vie et la sortie se remplit d'erreurs."),
        Faute("signal_non_branche", c["niveau"], "\t\tadd_child(enemy)\n" + connexion, "\t\tadd_child(enemy)\n",
              f"Un ennemi vaincu émet `defeated`, mais le niveau ne branche plus ce signal à `{t.autoload}.add_score` : "
              "personne ne l'écoute, le score ne bouge pas. Aucune erreur ne le dit : seul un test de comportement le "
              "voit.",
              "le score reste à zéro quand on tue un ennemi.",
              f"Quand un ennemi est vaincu, ses points doivent s'ajouter au score de la partie (`{t.autoload}.add_score`)."),
        Faute("corps_mort", c["composant"], "if amount <= 0.0 or current <= 0.0:", "if amount >= 0.0 or current <= 0.0:",
              f"`take_damage` sort tout de suite pour tout coup positif : la garde teste `amount >= 0.0` au lieu de "
              "`amount <= 0.0` (un coup nul ou négatif). La fonction se compile et ne fait rien : aucune erreur, seuls "
              "les tests le voient.",
              "les ennemis ne meurent jamais, quoi qu'on leur fasse."),
        Faute("config_version", c["projet"], "config_version=5", "config_version=6",
              "`config_version` est le format du fichier `project.godot` : Godot 4.7.2 attend 5. Une autre valeur "
              "n'est pas une option : Godot refuse d'ouvrir le projet.",
              "Godot refuse d'ouvrir le projet."),
        Faute("scene_principale", c["projet"], f'run/main_scene="res://{c["niveau_scene"]}"',
              f'run/main_scene="res://2_sequence/main.tscn"',
              f"`run/main_scene` désigne `res://2_sequence/main.tscn`, qui n'existe pas : la scène de départ est "
              f"`res://{c['niveau_scene']}`.",
              "le jeu ne démarre pas."),
        Faute("reglages_non_assignes", c["ennemi_scene"], 'script = ExtResource("1_enemy")\nstats = ExtResource("2_stats")\n',
              'script = ExtResource("1_enemy")\n',
              f"La scène de l'ennemi n'assigne plus ses réglages : `stats` reste `null`, et `_ready` lit "
              f"`stats.max_health` sur rien. Le principe 4 du plan : l'objet reçoit ce dont il a besoin, ici par la "
              "propriété exportée `stats`.",
              "les ennemis apparaissent cassés et la sortie se remplit d'erreurs.",
              f"L'ennemi doit recevoir ses réglages de `res://{c['donnees']}` par sa propriété `stats`."),
        Faute("signal_inconnu", c["ennemi"], "_health.died.connect(_on_died)", "_health.dead.connect(_on_died)",
              f"`{t.composant}` déclare le signal `died`, pas `dead` : le script de l'ennemi ne se charge plus.",
              "les ennemis ne se chargent plus."),
        Faute("setup_oublie", c["ennemi"], "func _ready() -> void:\n\t_health.setup(stats.max_health)\n",
              "func _ready() -> void:\n",
              f"L'ennemi ne donne plus sa vie de départ à son composant : `_health.current` reste à 0, et "
              "`take_damage` ne fait rien sur un acteur déjà à zéro. Aucune erreur : seuls les tests le voient.",
              "les ennemis ne meurent jamais et ne rapportent rien.",
              f"Au `_ready`, l'ennemi doit donner à son composant de vie la vie de départ de ses réglages "
              f"(`stats.max_health`)."),
    ]
    for x in sortie:
        x.poser(f)
    return sortie
