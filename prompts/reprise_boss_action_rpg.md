# Prompt de reprise — niveau de boss « Le Gardien du Comptoir » (Godot 4.7.2)

Commencé le 2026-10-28, mis à jour à chaque étape ; dernière mise à jour le 2026-10-31, après l'étape 19. Une copie est
dans le dépôt de l'usine : `D:\constructeur-qwen-gamedev\prompts\reprise_boss_action_rpg.md`.

---

## 1. Le prompt (à donner tel quel)

> Tu reprends le niveau de boss d'action RPG de laurent (« Le Gardien du Comptoir », Godot 4.7.2) et l'enseignement de
> sa construction à Qwen, là où l'IA précédente s'est arrêtée : les étapes 1 à 19 du cours sont faites, rien n'est
> commencé pour la 20.
>
> Avant toute action, lis dans cet ordre :
> 1. `D:\constructeur-qwen-gamedev\CLAUDE.md` (les « Règles qui priment » l'emportent sur tout ; décision 20 : aucun
>    réentraînement tant que les paires ne sont pas finies) ;
> 2. ce fichier en entier : `D:\GODOT\PROJETS_DEMOS\PROJET_BOSS_ACTION_RPG\SUIVIS_PROGRESSION\PROMPT_REPRISE.md` ;
> 3. dans le même dossier, `conception.md`, puis la fin de `suivi.md` et de `demarche.md` ;
> 4. dans `D:\constructeur-qwen-gamedev\cours\boss_action_rpg\notes\`, `etape_013.md` (les effets qui existent déjà),
>    `etape_017.md` et `etape_018.md` (le niveau de détail attendu d'une note).
>
> Vérifie ensuite l'état réel au lieu de te fier au journal : `git status` et `git log` du dépôt, `nvidia-smi`, les Godot
> ouverts et sur quel projet.
>
> Puis termine, une étape à la fois, avec la méthode du § 6 :
> - **étape 20, les effets et les coups magiques du boss**. laurent : « le boss n'a aucun VFX non plus.. pas de boules de
>   feux, pas d'aura magiques par d'eclaires lances... » ;
> - **étapes 21 et 22, l'optimisation pour un petit PC**. laurent : « il faut que le niveau puisse etre joue sur un petit
>   pc » ;
> - ensuite, demande à laurent s'il veut passer aux paires tirées du cours (§ 9).
>
> À la fin de chaque étape : tests verts et chaque ligne de sortie lue, étapes anciennes vérifiées inchangées, images
> regardées puis montrées à laurent (`SendUserFile`), report dans le jeu, note, pas de démarche, journaux, commit et push.
> Réponds à laurent en français, court, la réponse d'abord, chaque affirmation sourcée. Ne présente jamais une proposition
> comme sa décision ; ce qu'il n'a pas tranché est listé plus bas : ne le tranche pas à sa place. Tiens le journal à chaque
> étape : laurent l'a demandé plusieurs fois, une autre IA doit pouvoir reprendre à tout moment.

---

## Où on s'est arrêté (2026-10-31) — à lire d'abord

**Fait et envoyé** : étapes 1 à 19, branche `claude/observation-visuelle`, arbre git propre. Le jeu est à l'étape 19 :
252 cas verts, 0 ligne d'erreur, dans le cours et dans le jeu.

**Étape 20 : à faire.** Ce qu'il faut en savoir est plus bas.

**Ce que laurent n'a pas validé** : aucun retour sur le saut et la visée (étape 16), ni sur les étapes 17, 18 et 19. Son
dernier message après avoir joué parlait du son, des effets et des spectres. Ces étapes sont vérifiées par les tests et
l'image, pas par lui. Je n'ai jamais entendu un son : ils sont choisis sur leur
nom et leur durée (`5_data/audio/combat_sounds.tres` pour les volumes et les hauteurs). Ne pas écrire « validé ».

### Questions sans réponse (ne pas les trancher)

1. **Rendus quand llama-server tourne** : je lui ai demandé de dire quand la carte serait libre, ou si je pouvais rendre
   quand même ; il a répondu « continue », ce qui ne tranche pas. Ce que je faisais : `nvidia-smi` avant chaque rendu,
   de petits rendus seulement. Le 2026-10-30 : 31,3 Go sur 32, llama-server actif (de 10 à 94 % selon le moment), un rendu de
   contrôle à 893 Mo passé sans erreur. Le 2026-10-31 : 4,8 Go, 4 %, ni llama-server ni Godot ouverts.
2. **Verrouiller le golem tout seul à son réveil** : proposé en réponse à sa question sur la caméra de Dark Souls (elle
   n'est pas automatique : stick droit, verrouillage au clic du stick ; https://darksouls.wiki.fextralife.com/Controls,
   https://darksouls3.wiki.fextralife.com/Controls, https://darksouls2.wikidot.com/controls). Pas de réponse.
3. **Quel petit PC** : la cible de `conception.md` (Iris Xe, Radeon 680M ou GTX 1050, 8 Go) est **proposée**, non
   confirmée. Le test qui fait foi est ce PC lui-même : l'étape 22 dépend de lui.
4. **Mixamo, avec son compte** : un vrai clip de saut (aujourd'hui une foulée de course figée) et le geste « drink » du
   soin (aujourd'hui le rechargement).
5. **Mes choix, déjà signalés comme tels, modifiables** : roulade déplacée sur B / Maj pour libérer Espace ; un spectre à
   la fois, 2 s d'écart, 10 dégâts.

### Ce que l'étape 19 laisse à la suivante

- `VfxBurst` (`1_core/vfx/vfx_burst.gd`) : un effet bref préparé d'avance. Ses enfants `GPUParticles3D` repartent par
  `play()`, sa lueur (`Glow`) et sa lumière (`Light`) s'éteignent sur `duration`, il se cache quand tout est fini. Le groupe
  `vfx_burst` reçoit `light_allowed` de `GraphicsQualityApplier` (`GraphicsQuality.effect_lights`, faux en basse).
- Shaders en `blend_add` dont l'alpha de particule porte l'âge : `muzzle_flash`, `impact_star`, `impact_flash`, et la
  texture de bruit partagée `5_data/vfx/flash_noise.tres`.
- `tracer.gdshader` : un plan qui pivote vers la caméra autour de son axe, sommet par sommet. Il servira pour un éclair
  ou une boule de feu qui file.
- Une image de jeu ne suffit pas à juger un effet : une planche d'images consécutives, `outils/voir.ps1`, de loin et de près.
- Repères de l'étape 19, en tirant sans arrêt, 1280 × 720 : carte 1,763 ms en haute, 0,336 ms en basse, 2 703 et 618 appels
  de dessin, 897 et 381 Mo. Combat sans fenêtre : 63 sons, 126 allocations, 0 pour notre code, 0,58 ms par image.
- Mes choix, à faire valider : le ton orangé des tirs, les durées, les lumières. La note et `suivi.md` le disent.

### Étape 20, les effets et les coups magiques du boss : ce qui compte

- Ses coups sont tous au corps à corps (`5_data/boss/attacks/` : balayage, revers, écrasement, bond). Les boules de feu et
  les éclairs sont donc **de nouvelles attaques**, pas seulement des effets : annonce lisible, zone de coup, réserve
  préparée, tests, sons (nouveaux `SoundCue` dans `CombatSoundSet` ; les sons non retenus sont dans
  `source_extraites/kenney_*`).
- Les spectres ne plongent pas pendant `GolemAttackState` (`SpectreCall.claim_dive`) : une attaque de plus les retient,
  à regarder.
- Déjà là, à ne pas refaire : onde, éclats, tremblement, traînée du marteau, flash, braise de la seconde phase
  (`golem_effects.gd`, `5_data/vfx/`, note `etape_013.md`).

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
  parler) ; on explique avant de demander une autorisation. Tout se fait dans le fil principal, pas de sous-agents.
- Avant un report dans le jeu, regarder les Godot ouverts et sur quel projet (`Get-CimInstance Win32_Process`, colonne
  `CommandLine`). Son projet `F:\REVERSe\RECONSTRUCTION`, qu'il travaille avec OpenCode et llama-server, ne nous
  concerne pas : n'y toucher ni à ses processus.
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
- Disque **D: presque plein** (21 Go libres le 2026-10-31, projets du cours : 4,8 Go) : chaque étape à partir de la 7
  recopie ≈ 200 Mo. Le surveiller.

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
| Branche du dépôt | `claude/observation-visuelle` |
| Héros (modèle, animations, reciblage) | `…\6_assets\Characters\Hero\` (hero_model.tscn, hero_animations.tres, Models, Animations/Source et Clips, Retarget, Textures, Materials, Meshes, Skins) |

Godot : `D:\GODOT\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe` (éditeur : sans `_console`).

## 5. État exact (2026-10-31)

Étapes du cours, toutes fabriquées, importées, testées, reportées dans le dossier du jeu. Cas verts, de l'étape 1 à la 19
(`ETAT.md`) : 17, 31, 43, 66, 105, 122, 129, 141, 161, 162, 183, 199, 209, 213, 216, 220, 225, 240, 252.

| N | Étape |
| --- | --- |
| 1 | Socle : réglages stricts (avertissements en erreurs), actions clavier/souris/manette, couches, ordre d'exécution, plan.md |
| 2 | Héros en maquette grise : déplacement relatif à la caméra |
| 3 | Caméra à la troisième personne (pivot, SpringArm3D, épaule, visée), verrouillage de cible |
| 4 | Machine à états du héros (Move, Roll), endurance, mémoire d'appui, roulade à invulnérabilité, sprint |
| 5 | Tir : projectiles à rayon par image en réserve de 32, zones « cibles », surchauffe |
| 6 | Santé du héros, zone de coup du boss, états Hit, Heal, Dead, trois fioles, recommencement |
| 7 | Le saloon d'un géant et son gardien : décor converti de la scène Unity, échelle 4, ambiance, golem animé |
| 8 | Le héros animé : soldat reciblé, 13 clips, fusil sur l'os de la main, vue `hero_view.gd` |
| 9 | L'interface du genre |
| 10 | La carboglace (brume au sol) |
| 11 | Les spectres, squelettes procéduraux |
| 12 | Le combat du Gardien (attaques, phases, mort) |
| 13 | Les effets des coups |
| 14 | Mesures sans fenêtre, 0 allocation en combat |
| 15 | Deux qualités graphiques, la basse pour un petit PC |
| 16 | Le saut, et un tir qui part là où pointe le canon |
| 17 | Les spectres plongent chacun leur tour, et laissent une traîne |
| 18 | Le son et la musique du combat |
| 19 | Les effets des tirs : éclair de bouche, traçantes, impacts |

**Reste à faire, dans l'ordre annoncé à laurent** (`maitres/plan.md`) : 20 les effets et coups magiques du boss ; 21 ce qui se dessine (distances de visibilité des petits objets, occulteurs) ; 22 le petit PC
lui-même ; puis les paires tirées du cours (§ 9). Noté à l'étape 8 : l'entrée du saloon surexposée (plan émissif
extérieur, `M_Emissive`). Une grande plage blanche reste à gauche des images de l'étape 17 : à regarder, laurent n'en a
pas parlé.

## 6. Méthode d'une étape (ce qui a marché, à refaire à l'identique)

1. **Lire** la conception et les sources ; vérifier chaque membre Godot (`usine.vocab lookup`) et chercher dans le
   RAG ce qu'on ne sait pas ; quand la documentation se tait, écrire le plus petit test qui tranche.
2. **Maîtres balisés** (`cours/boss_action_rpg/maitres/…`) : `#@ N`, `#@ N+`, `#@ a-b`, `#@ all` dans les `.gd` ;
   `;@ …` dans les `.tscn`, `.tres`, `project.godot` ; `//@ …` dans les shaders. Un bloc ajouté se referme sur la balise
   du bloc qui l'englobait (`grep -n "^#@"` avant d'écrire). Une étape nouvelle ne change pas les précédentes :
   vérifier **avant de committer** par `python SUIVIS_PROGRESSION/outils/verifier_etapes.py N` (0 écart). Mes retouches
   de maîtres passaient par un petit script Python écrit avec l'outil d'écriture : `assert texte.count(ancien) == 1`,
   puis `write_bytes` (pas de CRLF).
3. **Tests d'abord** (GdUnit4, une règle par cas, la liste des règles en tête de suite).
4. **Manifeste** (`cours/boss_action_rpg/manifeste.py`) : `DERNIERE`, `ETAPES` (titre, piste), `PRETES`, `FICHIERS`
   (chemin : plage de présence ; les tests nouveaux aussi) ; et la case de l'étape dans `maitres/plan.md`. La source est le dossier du jeu (clé `boss_action_rpg` de `[sources]`) : les
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

## 7. Où en est le cours (2026-10-31)

Étapes 1 à 17 faites et vérifiées (14 : mesures sans fenêtre, 0 allocation en combat, 213 cas ; 15 : deux qualités
graphiques, la basse pour un petit PC, 216 cas ; 16 : le saut et la visée réparée, 220 cas ; 17 : les spectres
plongent chacun leur tour et laissent une traîne, 225 cas ; 18 : le son et la musique, 240 cas). Les dernières : 9, l'interface du genre (161 cas) ; 10, la carboglace (162) ; 11,
les spectres, squelettes procéduraux, à 70 % de la vie du golem (183) ; 12, le combat du Gardien (199) ; 13, les
effets des coups (209). Notes : `cours/boss_action_rpg/notes/etape_009.md` à `etape_013.md` ; `demarche.md` étapes 14
à 18. Effets : `3_entities/boss/golem_effects.gd`, `1_core/combat/impact_sparks.gd`, `6_assets/Shader/VFX/`,
`6_assets/VFX/`, `5_data/vfx/` ; tremblement : `OrbitCamera.shake`.

Le combat (étape 12) : `3_entities/boss/golem.gd` (logique), `states/` (Dormant, Wake, Approach, Attack, Recover,
PhaseShift, Dead), `golem_view.gd` (clips, penché, bouclier jeté), `golem_strike_modifier.gd` (buste penché par-dessus
l'animation), `1_core/data/golem_attack.gd` et `golem_settings.gd`, `5_data/boss/golem.tres` et `attacks/` (balayage,
revers, coup écrasant, bond). Seconde phase à 70 % : `phase_changed(2)`, que `SpectreCall` écoute.

Ce qui reste des sources : le soin joue le rechargement (geste « drink » à prendre sur Mixamo par laurent) ; effets
de Binbun (`hit_fx_free`, `muzzle_flash_vfx`, scripts **non typés** : à reprendre typés, ne pas copier leurs
`.import`/`.uid`). Détail : `inventaire_sources.md`, `demarche.md` étape 13.

**Consigne de laurent (2026-10-29)** : « accentue particulierement le travail et l'entrainnement sur l'optimisation des performances il faut que le niveau puisse etre joue sur un petit pc ». **Suite proposée** : étapes d'optimisation mesurées
avant et après, une par levier : les ombres (15 lumières en font : budget), ce qui se dessine (distances de
visibilité, occulteurs), une qualité basse (échelle 3D, effets d'écran, brume de repli sans brouillard volumétrique),
les textures et la mémoire vidéo ; puis la mesure sur la carte graphique et sur le petit PC lui-même. Outils :
`7_tests/perf/mesurer_combat.gd` (`-- <échauffement> <fenêtre> [--qualite=basse]`, sans fenêtre : allocations, temps,
passes d'ombre) et `7_tests/perf/mesurer_rendu.gd` (fenêtre hors de l'écran : temps de la carte graphique, appels de
dessin, primitives, mémoire vidéo). Fait : étape 15 (qualités).

**Retours de laurent après avoir joué (2026-10-29 et 30)** : saut et visée (**étape 16, faite**) ; spectres qui tuaient
en rafale, et leur traîne (**étape 17, faite**) ; le son et la musique (**étape 18, faite** : `6_assets/Audio/`,
`SoundBoard`, `CombatSounds`, `MusicPlayer` ; le moteur crée 2 objets par son lu, comptés à part) ; les effets des tirs (**étape 19, faite**) ; **prochaine : 20**,
les effets et coups magiques du boss (boules de feu, aura, éclairs annoncés), dans le budget de la qualité basse ; puis l'optimisation reprend : les distances de visibilité des petits objets (bouteilles,
verres, assiettes : des centaines) et des occulteurs (comptoir, murs), puis la mesure sur le petit PC lui-même (le
test qui fait foi). Sa question 7 (la caméra de Dark Souls est-elle automatique ?) : réponse donnée dans le fil, avec
sources (stick droit et verrouillage au clic du stick). Les sons restent à
part : les sons TII sont « No AI Training », jeu final seulement, jamais dans le cours. Puis les paires tirées du
cours.

Outils d'image et de mesure (`SUIVIS_PROGRESSION/outils/`) : `capturer_spectres.gd` ; `mesurer_golem.gd` (clips,
marteau, `-- trajectoires`) ; `trace_golem.gd` (chemin du marteau, dessus et profil) ; `planche_golem.gd` et
`assembler_planche.py` (gestes image par image) ; `jouer_combat.gd` (combat sans joueur, journal des coups) ;
`carte_arene.gd` (carte du sol en caractères) ; `verifier_etapes.py` (étapes anciennes inchangées) ; `voir_saut_tir.gd`,
`voir_traines.gd` (une planche d'images) ; `trace_spectres.gd` (chaque coup reçu par un héros immobile, image et source) ;
`mesurer_sons.gd` (objets créés par la lecture d'un son) ; `voir_tirs.gd` et `voir.ps1` (une rafale rendue hors de l'écran, puis une
planche ; vue du joueur, `pres`, `cote`, `verrou`, `--compat`, `--qualite=basse`) ; `planche.py`, `recadrer.py` ; `tester_etape.ps1` (fabrique,
importe, teste, résume) ; `mesurer_rendu.ps1` (`--tir` : en tirant sans arrêt ; une étape récente peut mesurer une plus ancienne) ;
`textures_tirs.py`.

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
  Code Mode : `tools["usine-godot"].search_docs({ requete, n })`, `.vocab_lookup({ classe, membre })`). 40 paires à
  ce jour. Champs d'un pas : `id`, `etape`, `sujet`, `type` ("analyse"), `situation`, `pensee`, `outil` (`genre` : `vocab`
  avec `classe` et `membre`, ou `rag` avec `requete` et `n`), `attendu` (fragments), `lecture` (ses citations « … » doivent
  être dans la sortie réelle), `decision`. Sujets déjà employés : Gameplay, Graphisme 3D, VFX, Shaders, Optimisation,
  Gestion de la mémoire, Audio, Physique, UI, Procédural, Contrôle à la manette, Plugins et leur usage, Création de
  tests. À étendre : pas qui lancent Godot (outil `shell`, sortie rejouée sur le projet fabriqué), pas qui lisent
  un fichier, pas « plan » (du prompt à la liste des étapes, vérifiée contre le manifeste), sessions longues.
- **Autres familles à tirer du cours** (`usine/paires/` : `creation`, `bloc`, `test_cas`, `morceaux`, `rag`) : ajouter
  `boss_action_rpg` aux choix `--cours` de `usine/paires/__main__.py` et à `JEUX` de `usine/cours/base/textes.py` si
  nécessaire (le cours « atelier » a servi d'exemple).
- Règles des données (CLAUDE.md, sections 3, 5, 7) : partage 40/40/20 (création, débogage, analyse) en jetons de
  réponse ; palier 1 ≤ 1 024 jetons (sans plan seulement si le plan ne joue aucun rôle), palier 2 ≤ 2 048 avec le
  plan ; une réponse n'écrit jamais une sortie de commande ; vérification déterministe de chaque exemple ; jetons comptés
  avec le tokenizer de Qwen 3.8.

## 10. Pièges déjà rencontrés (ne pas les refaire)

- `before`, `name` ou `call` comme nom de variable dans une suite GdUnit : casse la compilation stricte.
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
- `ResourceSaver.save(…, FLAG_CHANGE_PATH)` laisse `resource_path` vide sous Godot 4.7.2 : la scène recopie la
  ressource. Faire `save` puis `take_over_path(chemin)` (`construire_heros.gd`, `_ranger`). **À corriger** dans
  `construire_golem.gd` (golem_model.tscn : 6,7 Mo) et `construire_saloon.gd` (saloon.tscn : 40 Mo), puis refabriquer
  et retester les étapes 7 et 8 ; corriger aussi le pas `e7_enregistrer_chemin` de `demarche.json`.
- `reporter.py` efface tout dossier qu'il ne garde pas : y ajouter chaque nouveau dossier hors du jeu
  (`source_telecharges` ajouté après avoir perdu ses archives, retéléchargées).
- Godot 4.7.2 avertit pour un point d'espace de mélange sans nom (`add_blend_point(nœud, pos, -1, &"nom")`).
- Python `write_text` sous Windows écrit des CRLF : écrire des octets (`write_bytes`) dans le dépôt ; et un `\\`
  dans un heredoc passé à Python peut se perdre : éditer les chemins Windows par l'outil d'édition.
- Dans un `SceneTree` lancé par `-s`, la scène ajoutée dans `_initialize` n'est pas prête (son `_ready` n'a pas eu
  lieu) : agir à la première image ; et la déclarer `current_scene`, sinon `reload_current_scene` échoue.
- Un shader additif n'assombrit rien : un creux (orbite) ne se lit que si son fond est éteint (poids d'éclat à 0).
- Une rotation qui lève un bras qui pend : même signe, effet inverse une fois le bras au-dessus de l'horizontale.
- Bash : `"$W\\$v"` laisse `$v` tel quel (l'antislash échappe le dollar) : écrire les chemins avec `/`.
- Le test de documentation saute les dossiers à `.gdignore` (sinon il lit `SUIVIS_PROGRESSION/` dans le jeu).
- Les clips du golem frappent à sa propre hauteur (4 m) : mesurer le marteau avant de régler un coup ; le penché du
  buste (`GolemStrikeModifier`) le ramène au ras du sol.
- Un signal émis seulement depuis une autre classe (un état) est un avertissement `unused_signal`, donc une erreur :
  l'émettre par une méthode de la classe qui le déclare.
- La capsule du golem (1,6 m) ne passe pas là où passe le héros : vérifier le chemin (`cast_motion`, forme soulevée
  de 0,3 m) avant un coup qui porte le corps ; et ne pas poser le golem dans un scénario sans regarder la carte
  (`outils/carte_arene.gd`) : posé dans un meuble, il ne bouge plus.
- Une zone placée d'avance (pour voir les corps déjà dedans) doit l'être là où sera l'impact, pas là où est le corps.
- `rm -f $W/*.png` est refusé par la sécurité de Claude Code : écrire dans un nouveau dossier plutôt qu'effacer.
- Un enfant est prêt avant son parent : une vue enfant ne lit pas les `@onready` de son parent dans son `_ready`
  (nuls) ; prendre le nœud par son chemin.
- Les matériaux du golem sont des `ORMMaterial3D` : transtyper en `BaseMaterial3D`, pas en `StandardMaterial3D`.
- Allumer l'émission des matériaux du golem blanchit tout (cartes grises) : une couche par-dessus (`ember_lines`)
  n'allume que les lignes claires ; une carte lue comme donnée se déclare sans `source_color`.
- Sous un script lancé par `-s`, les moniteurs `TIME_PROCESS` et `TIME_PHYSICS_PROCESS` restent à 0 : mesurer le
  temps avec `Time.get_ticks_usec`.
- Mesurer les allocations dans un test GdUnit : sans `await` dans la boucle mesurée (un `await` crée un objet).
- `PhysicsRayQueryParameters3D.create` rend une requête neuve à chaque appel : la garder et la réutiliser.
- Le moteur Compatibilité n'a pas les ombres omnidirectionnelles en demi-sphères (une erreur par image) : garder les
  cubes avec lui (`RenderingServer.get_current_rendering_method()`).
- Une brume faite de plans transparents non éclairés brille dans une salle sombre : les éclairer comme le décor.
- Le temps de la carte graphique dépend de ce qui tourne à côté (llama-server) : comparer deux réglages lancés l'un
  après l'autre.
- Un heredoc bash qui contient beaucoup d'apostrophes peut casser (« unexpected EOF ») : écrire le script Python dans un
  fichier par l'outil d'écriture.
- Un bloc ajouté dans un maître (`#@ 16+`) se referme sur la balise du bloc qui l'englobait, pas sur `all` par
  habitude : sinon des lignes apparaissent ou disparaissent aux étapes anciennes. Vérifier avant chaque commit que
  `usine.cours.jeu.rendre(texte, e, 1, n)` donne, pour chaque étape ancienne e, le même texte qu'au commit précédent.
- La caméra regarde le héros d'en haut : le centre de l'écran tombe sur le plancher. Le tir de hanche ne doit pas
  viser par lui.
- Le contrôle « étapes anciennes inchangées » ne compare un maître qu'à partir de l'étape où il apparaît (manifeste) :
  avant, le fichier n'existe pas, et une balise `11-16` y crée de faux écarts.
- Les spectres planent sur un cercle de 6 m autour du héros, qui passe par la place de la caméra : tout effet qui les
  suit doit s'effacer tout près d'elle.
- Lire un son crée deux objets dans le moteur (sa lecture), quelle que soit la voie (`play()`, `play_stream()`) : la
  règle « 0 allocation en combat » vaut pour notre code ; `mesurer_combat.gd` retire 2 par son (`allocations_hors_sons`).
- Un outil lancé par `-s` qui quitte pendant que des sons jouent les fait fuir à la sortie : libérer la scène, attendre
  quelques images de 30 ms (comme `7_tests/1_core/silence_audio.gd`), puis quitter.
- Je ne peux pas écouter les sons : je les choisis sur leur nom et leur durée ; les volumes sont à faire valider à
  l'oreille par laurent.
- Avant un rendu en fenêtre, lire la mémoire de la carte (`nvidia-smi`) : si elle est presque pleine (un autre
  programme), ne pas lancer de rendu.
- `set`, `call` et `seed` comme noms de variable masquent `Object.set`, `Object.call` et la fonction globale `seed` :
  avertissement traité en erreur, le script ne se charge plus. Une seule suite cassée et GdUnit s'arrête (code 105).
- Refabriquer sans `--import` : « Could not find type … » (classes globales nouvelles). Toujours importer après.
- `git status --porcelain` montre un dossier nouveau comme une seule ligne : lister avec `-uall`.
- `instance` est un mot du langage de shaders : `varying flat int instance;` échoue, et les tests restent verts, code 0.
  Le résumé de `tester_etape.ps1` cherche `SHADER ERROR`.
- Une note d'étape écrite après la fabrication manque au projet (son `README.md`), et le report le retire du jeu : fabriquer
  de nouveau après la note.
- `python -I` ne voit pas les paquets installés pour l'utilisateur (Pillow).
- Le tonemap AgX blanchit les orangés très vifs : une lueur trop forte fait une boule de lait.
- Verrouillé sur le Gardien, la caméra descend au ras du plancher : mauvaise vue pour juger un effet.
- Trou du RAG : la ligne « VERTEX […] in view space » des built-ins de `fragment()` ne sort sur aucune de mes requêtes.
  Je l'ai lue dans `D:\sources\godot-docs\tutorials\shaders\shader_reference\spatial_shader.rst` et n'en ai pas fait de pas.
