# Gardien du Comptoir · étape {STEP} · {TITLE}

**Piste : {TRACK}.** laurent : « modifie les attaques ajoutes de VFX etc.. ». Les coups du golem se voient et se
sentent.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait

- **Impact au sol** (signal `slammed`) : une onde de poussière (shader `shockwave.gdshader` sur un plan posé au sol),
  un nuage, des éclats de pierre (salves uniques `GPUParticles3D`, recette `particules_impact` du RAG), et la caméra
  qui tremble, moins fort de loin (`OrbitCamera.shake`, par `h_offset` et `v_offset`).
- **Traînée du marteau** : Godot 4.7 n'a pas de nœud de traînée en 3D (fiche `trainee` du RAG). C'est donc un ruban
  `ImmediateMesh`, refait à chaque image à partir des positions du marteau pendant sa fenêtre de frappe.
- **Étincelles** sur le héros touché, et à chaque impact de tir (`ImpactSparks`, salves préparées d'avance) ; **flash**
  du héros touché (couche `hit_flash.gdshader`, recette `flash_impact` du RAG).
- **Braise de la seconde phase**. Allumer l'émission du matériau de l'armure éclairait toute l'armure, car sa carte est
  grise presque partout. Une couche par-dessus (`ember_lines.gdshader`) n'allume que les lignes claires de cette carte.
  La carte est lue sans `source_color`, avec un seuil bas : vues de loin, les lignes fines se mêlent au noir dans les
  niveaux réduits de la texture.
- **Pièges** :
  - un enfant est prêt avant son parent : les vues prennent la santé et les zones de coup par leur chemin ;
  - les matériaux du golem sont des `ORMMaterial3D`, donc on passe par `BaseMaterial3D`.

Aucun nœud n'est créé en combat. Images en Forward+ et en Compatibilité. 209 cas verts.
