# Shader Warm-Up Tool (réduire les saccades de première compilation des shaders)

Version vérifiée : branche `main` (plugin.cfg 0.1.0, aucune version publiée, mise à jour le 2026-03-02), GDScript
pour l'outil d'éditeur, licence MIT, dépôt `Koisuji02/GodotShaderWarmup` (23 étoiles au 2026-10-22). Plugin activé
sans erreur dans l'éditeur 4.7.2 : `python -m usine.rag.plugins verifier shader_warmup`.

## Ce qu'il résout

La première fois qu'un matériau s'affiche, le moteur compile son shader et ses pipelines : une saccade. La méthode du
dépôt, d'après son README :
1. **dans l'éditeur**, l'outil parcourt des scènes choisies et écrit un manifeste JSON des matériaux qu'elles
   emploient (`res://shader_warmup_manifest.json` par défaut) ;
2. **au lancement du jeu**, une extension C++ (`WarmupManager`, dossier `gdext/` du dépôt) lit le manifeste et
   « touche » ces matériaux sous un budget de temps, image après image, avant qu'on en ait besoin.

Le dépôt fournit aussi un générateur de scènes de stress et des scènes de mesure (`bench/`), avec un rapport.

## Le choisir, ou Godot seul ?

- **Godot seul** : la méthode courante consiste à afficher une fois chaque matériau pendant l'écran de chargement
  (devant la caméra, pendant une image), pour que la compilation ait lieu avant la partie (non mesuré ici).
- **Ce dépôt** : une méthode outillée et mesurée, mais seul l'outil d'éditeur est livré prêt à l'emploi ; la partie
  qui tourne dans le jeu est une extension C++ à compiler soi-même (SCons, MSVC sous Windows).

## Installation

Copier `addons/shader_warmup_tool/` et activer le plugin : un panneau « Shader Warm-Up Manifest » permet d'ajouter
des scènes et de générer le manifeste.

## Pièges

- Sans l'extension C++ compilée, le manifeste ne sert à rien en jeu : c'est la moitié du travail.
- Projet jeune (23 étoiles, aucune version publiée) : à considérer comme un exemple de méthode plus que comme un
  outil installé tel quel.
