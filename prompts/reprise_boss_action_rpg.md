# Prompt de reprise — niveau de boss « Le Gardien du Comptoir » (Godot 4.7.2)

Écrit le 2026-10-28 par l'IA qui a fait les étapes 1 à 7, pour l'IA qui poursuit. Une copie est dans le dépôt de
l'usine : `D:\constructeur-qwen-gamedev\prompts\reprise_boss_action_rpg.md`.

---

## 1. Le prompt (à donner tel quel)

> Tu reprends le niveau de boss d'action RPG de laurent, en Godot 4.7.2, et l'enseignement de sa construction à Qwen.
> Avant toute action, lis dans cet ordre :
> 1. `D:\constructeur-qwen-gamedev\CLAUDE.md` (les « Règles qui priment » l'emportent sur tout ; décision 20 :
>    aucun réentraînement tant que les paires ne sont pas finies) ;
> 2. ce fichier en entier : `D:\GODOT\PROJETS_DEMOS\PROJET_BOSS_ACTION_RPG\SUIVIS_PROGRESSION\PROMPT_REPRISE.md` ;
> 3. `SUIVIS_PROGRESSION\suivi.md` (cases cochées, « Réorientation », « Reprendre ici », « Enseigner la démarche ») ;
> 4. `SUIVIS_PROGRESSION\demarche.md` (chaque étape, ses recherches, ses erreurs) et `conception.md` (le combat voulu) ;
> 5. `D:\constructeur-qwen-gamedev\ETAT.md`, section « Cours boss_action_rpg — 2026-10-28 ».
>
> Puis fais l'étape 9 du cours : **l'interface du genre** (vie, endurance, fioles, surchauffe, nom et barre du boss),
> branchée sur les composants déjà écrits, avec la même méthode que les étapes 1 à 8 :
> maîtres balisés dans `cours/boss_action_rpg/`, tests d'abord, fabrication, import, tests GdUnit4 dont chaque ligne
> est lue, captures du rendu, report dans le dossier du jeu, note d'étape détaillée, pas de démarche ajoutés au journal
> (`cours/boss_action_rpg/demarche.json`), mise à jour de `suivi.md`, `demarche.md` et `ETAT.md`, commit.
> Réponds à laurent en français, court, la réponse d'abord, chaque affirmation sourcée. Tiens le journal à chaque
> étape : laurent l'a demandé trois fois, une autre IA doit pouvoir reprendre à tout moment.

---

## 2. Qui est laurent, ce qu'il veut

- Il construit une « usine » (`D:\constructeur-qwen-gamedev`) qui fabrique des données d'entraînement vérifiées pour
  un LoRA de **Qwen 3.8 27B** qui code en Godot 4.7.2 dans **OpenCode**. Il écrit vite, avec des fautes de frappe :
  lire l'intention (« carboglass » = carboglace, brume au sol).
- **Sa demande (texte exact dans `suivi.md`)** : « tu crées un niveau de jeu professionnel avec un rendu professionnel
  avec Godot 4.7, d'un niveau de BOSS action RPG à la DARK SOULS ! le rendu et la finalisation d'un code propre et
  extrêmement optimisé et performant en 3D ! » ; le héros **tire** sur le golem ; le saloon agrandi pour être
  dramatique ; partir de **ses** sources (`source/`) ; chercher ce qui manque (RAG, web, Mixamo avec son accord) ;
  **documenter comment on cherche et trouve les sources, adapté aux outils d'OpenCode** ; enseigner chaque étape à
  Qwen (cours, paires, sessions) ; tenir le journal.
- **Sa référence visuelle** : https://www.youtube.com/watch?v=fsVcMukmQNU (Dark Souls 1, tous les boss) : décor sombre
  et texturé, brouillard, lumière de torches, boss immenses, interface du genre (vie et endurance en haut à gauche,
  objets en bas à gauche, nom et barre du boss en bas). Il a rejeté la maquette grise : **toujours montrer le rendu
  visé**, une capture à chaque étape (`SendUserFile`).
- **Ses demandes en cours de route** : « le héros très petit » (échelle 4 du décor et du golem) ; brume au sol
  (« carboglace ») ; « tu utilises les sources que j'ai prises » ; « toutes les licences sont open source et gratuites
  tant que ça reste un projet personnel » (donc Lyra et gaspfix **sont utilisés**, malgré la réserve écrite dans
  `inventaire_sources.md`) ; « il t'en manquera, par exemple il n'y a pas d'effets, pas de musique » (à chercher) ;
  « tu ne réentraînes rien tant qu'on n'a pas fini les paires ».
- **Original, jamais une copie** : combat du genre « souls », mais boss, décor et interface à nous (ne pas reproduire
  Dark Souls, ses boss ni son interface à l'identique).

## 3. Règles de travail à ne pas oublier

- Réponses courtes en français, la réponse d'abord ; pas de discussion de PR ni de git (les commits se font sans en
  parler) ; on explique avant de demander une autorisation.
- **Rien sur llama-server, aucun entraînement** (décision 20). Lancer Godot sans fenêtre (`--headless`) pour
  fabriquer, importer, tester fait partie du travail accepté.
- **Fenêtres de rendu hors de l'écran** (`--position -6000,-6000`), jamais sur l'écran de laurent ; **jamais capturer
  sa souris** (`capturer_jeu.gd` la libère dans la même image) ; ne jamais lancer Godot sur un projet en cours de
  fabrication (boîte d'alerte sur son écran).
- Tuer seulement les processus qu'on a lancés. Archives : extraites dans un dossier neuf, rien exécuté.
- **Téléchargements** (musique, sons, Mixamo) : accord de laurent pour chacun (nom, source, taille, licence) ; Mixamo
  demande son compte : c'est lui qui télécharge.
- **Sons TII** (`tii_sci_fi`) : licence « No AI Training » : dans le jeu final seulement (logo TII au générique) ;
  sons muets dans les projets qui produisent les données.
- Vocabulaire Godot : tout membre vérifié (`python -m usine.vocab lookup <Classe> <membre>`) ; documentation par le
  RAG (`python -m usine.rag chercher "<requête>" -n N [--json]`).
- Disque **D: presque plein** (≈ 24 Go libres le 2026-10-28 après l'étape 8) : chaque étape du cours à partir de la 7 recopie ≈ 200 Mo.

## 4. Où sont les choses

| Quoi | Où |
| --- | --- |
| Le jeu (projet Godot, résultat) | `D:\GODOT\PROJETS_DEMOS\PROJET_BOSS_ACTION_RPG\` |
| Archives de laurent (lecture seule) | `…\source\` |
| Extraites et classées | `…\source_extraites\` (golem : `mesh`, `animations`, `textures` ; soldat : `scifitroopermanv3` ; roulades : `sourse` ; `lyra` ; `gaspfix` ; saloon : `salooninterior_unity`, `saloon_interior_low` ; sons : `tii_sci_fi`) |
| Ressources converties pour Godot | `…\6_assets\Environment\Saloon\` (saloon.tscn, Meshes, Materials, Textures, Models) ; `…\6_assets\Characters\Golem\` (golem_model.tscn, golem_animations.tres, Meshes, Skins, Materials, Textures, Animations/Clips) |
| Suivi, démarche, conception, inventaire | `…\SUIVIS_PROGRESSION\` (`suivi.md`, `demarche.md`, `conception.md`, `inventaire_sources.md`, `captures\`) |
| Outils de la chaîne (Python, GDScript) | `…\SUIVIS_PROGRESSION\outils\` (voir § 6) |
| Le cours (maîtres, notes, manifeste) | `D:\constructeur-qwen-gamedev\cours\boss_action_rpg\` |
| Journal de démarche (paires) | `D:\constructeur-qwen-gamedev\cours\boss_action_rpg\demarche.json` |
| Projets fabriqués des étapes | `D:\constructeur-qwen-gamedev\donnees\cours\boss_action_rpg\projets\boss_etape_00N\` |
| Paires générées | `D:\constructeur-qwen-gamedev\donnees\paires\<famille>\` |
| Branche du dépôt | `claude/observation-visuelle` (commits : `c890c7c` étape 7, `cd5be34` démarche, puis l'étape 8) |
| Héros (modèle, animations, reciblage) | `…\6_assets\Characters\Hero\` (hero_model.tscn, hero_animations.tres, Models, Animations/Source et Clips, Retarget, Textures, Materials, Meshes, Skins) |

Godot : `D:\GODOT\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe` (éditeur : sans `_console`).

## 5. État exact (2026-10-28)

Étapes du cours, toutes fabriquées, importées, testées, reportées dans le dossier du jeu :

| N | Étape | Cas verts |
| --- | --- | --- |
| 1 | Socle : réglages stricts (avertissements en erreurs), actions clavier/souris/manette, couches, ordre d'exécution, plan.md | 17 |
| 2 | Héros en maquette grise : déplacement relatif à la caméra | 31 |
| 3 | Caméra à la troisième personne (pivot, SpringArm3D, épaule, visée), verrouillage de cible | 43 |
| 4 | Machine à états du héros (Move, Roll), endurance, mémoire d'appui, roulade à invulnérabilité, sprint | 66 |
| 5 | Tir : visée au centre de l'écran, projectiles à rayon par image en réserve de 32, zones « cibles », surchauffe | 105 |
| 6 | Santé du héros, zone de coup du boss, états Hit, Heal, Dead, trois fioles punissables, recommencement | 122 |
| 7 | Le saloon d'un géant et son gardien : décor Quixel converti de la scène Unity, échelle 4, ambiance (lune, lampes, brouillard, brume au sol), golem animé (25 animations), plancher à y = 0 | 129 |
| 8 | Le héros animé : soldat reciblé (UE4 et UE5 → profil humanoïde), 13 clips, fusil sur l'os de la main, vue `hero_view.gd` (transition par état, course et marche visée, recul du tir sur le haut du corps, durées des états, bouche de l'arme à `skeleton_updated`) | 139 |

Ce qui n'existe pas encore : l'interface, l'IA du golem (il joue
l'attente, ne bouge pas, ne frappe pas), les effets, les sons, la musique, l'optimisation. L'entrée du saloon est
surexposée (plan émissif extérieur, `M_Emissive`, énergie 4) : à régler avec les lumières.

**Ordre accepté par laurent** (« oui vas y ») : décor et golem (fait) → héros animé (fait) → **interface du genre** →
combat du golem (machine à états, attaques sur ses vraies animations, zones de coup, bouclier, points faibles,
phase 2, mort) → effets et sons → optimisation → paires et sessions longues.

## 6. Méthode d'une étape (ce qui a marché, à refaire à l'identique)

1. **Lire** la conception et les sources ; vérifier chaque membre Godot (`usine.vocab lookup`) et chercher dans le
   RAG ce qu'on ne sait pas ; quand la documentation se tait, écrire le plus petit test qui tranche.
2. **Maîtres balisés** (`cours/boss_action_rpg/maitres/…`) : `#@ N`, `#@ N+`, `#@ a-b`, `#@ all` dans les `.gd` ;
   `;@ …` dans les `.tscn`, `.tres`, `project.godot`. Une étape nouvelle ne change pas les précédentes : vérifier par
   `python -c "from usine.cours.jeu import rendre; …"` (comparer le rendu des étapes passées avant et après).
3. **Tests d'abord** (GdUnit4, une règle par cas, la liste des règles en tête de suite).
4. **Manifeste** (`cours/boss_action_rpg/manifeste.py`) : `DERNIERE`, `ETAPES` (titre, piste), `PRETES`, `FICHIERS`
   (chemin : plage de présence). La source est le dossier du jeu (clé `boss_action_rpg` de `[sources]`) : les
   ressources désignées par `res://` (y compris dans les `.res` binaires) sont copiées avec leurs `.import`.
5. **Note d'étape** `cours/boss_action_rpg/notes/etape_00N.md` (jetons `{STEP}`, `{TITLE}`, `{TRACK}`,
   `{FILES_TABLE}`), aussi détaillée que `etape_007.md` : pourquoi maintenant, ce qu'on a cherché, décidé, les erreurs.
6. **Fabriquer, importer, tester** (depuis `D:\constructeur-qwen-gamedev`) :
   ```
   python -m usine.cours fabriquer boss_action_rpg --etapes N
   <godot> --headless --path <projet> --import
   <godot> --headless --path <projet> --fixed-fps 60 -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -c -rc 1 -rd .godot/rapports_tests -a res://7_tests
   ```
   Lire **chaque ligne** (un code 0 peut cacher des `SCRIPT ERROR`). Refabriquer et retester les étapes précédentes.
   Après une refabrication, toujours `--import` avant les tests (sinon `GdUnitTestCIRunner` introuvable).
7. **Mesurer au lieu de deviner** : scénarios joués sans fenêtre (`outils/scenarios/*.gd`, lancés par
   `<godot> --headless --path <projet> --fixed-fps 60 -s <scénario>`) qui affichent rayons, impacts, positions.
8. **Capturer le rendu** : `outils/capturer_jeu.gd` (le jeu par sa caméra), `outils/capturer.gd` (une scène, une
   caméra, vue en plan orthographique), `outils/apercu_arene.gd` (réglages d'ambiance) ; fenêtre hors de l'écran ;
   regarder l'image ; l'envoyer à laurent.
9. **Reporter** dans le dossier du jeu : `python -I SUIVIS_PROGRESSION/outils/reporter.py N` (garde `source`,
   `source_extraites`, `SUIVIS_PROGRESSION`, `.godot`, `6_assets`).
10. **Documenter** : cocher `suivi.md` (preuve à côté), ajouter l'étape à `demarche.md`, ajouter les pas de démarche
    au journal `demarche.json` puis `python -m usine.paires demarche` (aucun pas écarté), mettre à jour `ETAT.md`,
    committer (fin de message : `Co-Authored-By: Claude …` selon le rappel du système).

Outils de `SUIVIS_PROGRESSION\outils\` : `unity_scene_extraire.py`, `unity_scene_vers_json.py`,
`unity_materiaux_vers_json.py`, `unity_extraire_fichiers.py`, `textures_vers_godot.py`, `completer_murs.py`,
`golem_textures.py`, `construire_saloon.gd`, `construire_golem.gd`, `construire_ambiance.gd`, `inspecter_scene.gd`
(décrit une scène importée : nœuds, maillages, squelette, animations), `capturer.gd`, `capturer_jeu.gd`,
`apercu_arene.gd`, `reporter.py`, `refaire_arene.py`, et pour le héros : `recibler_heros.gd`, `heros_textures.py`,
`construire_heros.gd`, `mesurer_clips.gd`, `mesurer_foulee.gd`, `planche_poses.gd`, `capturer_heros.gd` (refait toute la chaîne du décor et du golem avec les paramètres
retenus : échelle 4, décalage `-85.4,4.288,2.49`, lampes 9). Les scripts GDScript lancés par `-s` sont compilés avec
les réglages stricts du projet (typer tout, pas de division entière).

## 7. L'étape 9 : l'interface du genre (ce qu'on sait déjà)

L'étape 8 (le héros animé) est faite : note `cours/boss_action_rpg/notes/etape_008.md`, `demarche.md` étape 12.
Ce qu'elle laisse : le fusil est fait de primitives ; le soin joue le rechargement. Depuis (accord de laurent),
trois paquets CC0 téléchargés dans `source_telecharges/`, extraits dans `source_extraites/` : `ultimate_gun_pack`
(Quaternius : fusils, candidats importés dans `6_assets/Weapons/Candidates/`, planche `captures/etape_008/fusils.png`,
les Bullpup proposés à laurent), `hit_fx_free` et `muzzle_flash_vfx` (Binbun : effets Godot 4, scripts **non typés** :
à reprendre typés, ne pas copier leurs `.import`/`.uid`). Détail : `inventaire_sources.md`, `demarche.md` étape 13.
Geste de soin : Mixamo, compte de laurent (« drink »). Sa chaîne :
`outils/recibler_heros.gd` (cartes d'os UE4/UE5 → `SkeletonProfileHumanoid`, écrites dans les `.import`), `--import`,
`outils/heros_textures.py`, `outils/construire_heros.gd` (→ `6_assets/Characters/Hero/hero_model.tscn`,
`hero_animations.tres`) ; mesures `outils/mesurer_clips.gd`, `outils/mesurer_foulee.gd` ; images
`outils/planche_poses.gd`, `outils/capturer_heros.gd`.

L'étape 9, selon l'ordre accepté : **l'interface du genre**, originale (ne pas copier celle de Dark Souls) : vie et
endurance en haut à gauche, fioles en bas à gauche, surchauffe de l'arme près du réticule, nom et barre du boss en bas.
- Ce qu'elle lit (signaux déjà là) : `HealthComponent.damaged/healed/died` et `ratio()` ; `StaminaComponent.changed`
  et `ratio()` ; `FlaskComponent.changed(charges, maximum)` ; `HeatComponent.changed/overheated/cooled_down` et
  `ratio()`. La santé du golem : son `Health` (1 500).
- Règle du plan : l'interface est une vue (`4_ui/` ou le dossier que le plan prévoit : lire `godot/socle_jeu/AGENTS.md`
  du dépôt) qui écoute, ne décide rien ; ses valeurs (couleurs, durées de la barre « dégâts récents ») dans `5_data`.
- Tests : chaque barre suit son composant ; la barre du boss apparaît au réveil (à décider avec la conception) ;
  captures de l'écran de jeu.

## 8. Le golem ensuite (préparé)

25 animations dans `6_assets\Characters\Golem\golem_animations.tres` : `idle1`-`idle4`, `walkF/B/L/R`, `jogF/B/L/R`,
`turn180`, `attack1`-`attack5`, `gethit1`-`gethit3`, `death1`-`death3`, `dodge`. Marche sur place (le code déplace le
golem). Os d'arme : `weapon_r` (marteau), `weapon_l` (bouclier). Émission éteinte au départ (couleur de braise prête
pour la phase 2 : monter `emission_energy_multiplier` des matériaux). Déjà écrits : `Hitbox` (zone de coup, une fois
par allumage, `take_hit` du héros), `Hurtbox` (multiplicateur : 0 pour un bouclier, plus de 1 pour un point faible),
`HealthComponent`, `StateMachine`. Le golem est à (9, 0, −1), le héros apparaît à (9, 0, −11) (couloir sans meuble ;
les meubles géants font 2 m de large : vérifier toute nouvelle position).

## 9. Enseigner à Qwen (les données)

- **Journal de démarche** : `cours/boss_action_rpg/demarche.json`, un pas par décision réellement prise ; générateur
  `python -m usine.paires demarche` (`usine/paires/demarche.py`) : outil rejoué (RAG, vocabulaire), pas écarté si un
  fragment attendu ou une citation « … » manque à la sortie réelle ; paires au format d'OpenCode (outil `execute` du
  Code Mode : `tools["usine-godot"].search_docs({ requete, n })`, `.vocab_lookup({ classe, membre })`). 10 paires à
  ce jour. À étendre : pas qui lancent Godot (outil `shell`, sortie rejouée sur le projet fabriqué), pas qui lisent
  un fichier, pas « plan » (du prompt à la liste des étapes, vérifiée contre le manifeste), sessions longues.
- **Autres familles à tirer du cours** (`usine/paires/` : `creation`, `bloc`, `test_cas`, `morceaux`, `rag`) : ajouter
  `boss_action_rpg` aux choix `--cours` de `usine/paires/__main__.py` et à `JEUX` de `usine/cours/base/textes.py` si
  nécessaire (le cours « atelier » a servi d'exemple).
- Règles des données (CLAUDE.md, sections 3, 5, 7) : partage 40/40/20 (création, débogage, analyse) en jetons de
  réponse ; palier 1 ≤ 1 024 jetons (sans plan seulement si le plan ne joue aucun rôle), palier 2 ≤ 2 048 avec le
  plan ; une réponse n'écrit jamais une sortie de commande ; vérification déterministe de chaque exemple ; jetons comptés
  avec le tokenizer de Qwen 3.8.

## 10. Pièges déjà rencontrés (ne pas les refaire)

- `before` ou `name` comme nom de variable dans une suite GdUnit : casse la compilation stricte.
- `Vector3`/`Vector2` en float32 : comparer avec une tolérance.
- Un temps décompté image par image n'atteint pas 0 : `is_zero_approx`.
- GodotPhysics3D (moteur par défaut) : une `Area3D` n'a pas signalé un `StaticBody3D` posé dedans ; tester avec les
  mêmes types de corps que le jeu (le héros est un `CharacterBody3D`).
- Sous GdUnit, la scène courante est le lanceur : un rechargement de scène se vérifie par un scénario sans fenêtre.
- Le rayon de visée ignore ce qui est entre la caméra et le héros (`hero.gd`, `aim_point`).
- Mesurer un plancher par des rayons ; vérifier qu'un point d'apparition n'est pas dans un meuble.
- Unity → Godot : maillage Mz · T · Mx, lumière Mz · T · Mz ; le YAML des `MeshCollider` de Quixel est mal indenté ;
  les matériaux se comprennent par leur graphe de shader ; une plaque de mur peut être posée à plat (plafond).
- Les cartes d'émission du golem sont des masques : allumées, elles blanchissent tout.
- Heredoc et antislash : `\n` devient un vrai saut de ligne ; écrire les scripts par l'outil d'écriture de fichiers.
- `cygpath` de la machine est cassé (anaconda) : passer les chemins Windows tels quels.
- Sorties Python avec des caractères accentués ou des flèches : `PYTHONIOENCODING=utf-8`.
- `Skeleton3D.get_bone_global_pose` ne voit pas une pose qu'on vient de poser (`set_bone_pose_rotation`) : composer
  la pose de parent en parent avec `get_bone_pose` (étape 8 : foulées à 0, fusil placé sur la pose de repos).
- La pose du squelette se finit après la physique : ce qui doit suivre un os (la bouche de l'arme) se recale au
  signal `Skeleton3D.skeleton_updated`.
- Le reciblage s'écrit dans le `.import` sous `_subresources` → `nodes` → `"PATH:<chemin du squelette dans la scène
  brute>"` ; effacer les `.md5` de `.godot/imported/` pour que `--import` le refasse.
- Godot 4.7.2 avertit pour un point d'espace de mélange sans nom (`add_blend_point(nœud, pos, -1, &"nom")`).
- Python `write_text` sous Windows écrit des CRLF : écrire des octets (`write_bytes`) dans le dépôt ; et un `\\`
  dans un heredoc passé à Python peut se perdre : éditer les chemins Windows par l'outil d'édition.
