# Plan — éditeur de niveaux du roguelike

Une case par étape ; on coche une étape quand ses tests sont verts et qu'on l'a vue tourner. On ne passe pas à la
suivante avant. L'éditeur vit dans le projet du jeu (dossiers `1_core/editor`, `2_sequence/editor`, `4_ui/editor`) et
lit les mêmes données que lui (`1_core/data`, `5_data`).

#@ 1
- [ ] 1. Socle : nomenclature, réglages stricts, ordre d'exécution, la coquille qui s'ouvre
#@ 2+
- [x] 1. Socle : nomenclature, réglages stricts, ordre d'exécution, la coquille qui s'ouvre
#@ 1
- [ ] 2. La salle en données : tableaux compacts, validation, enregistrement atomique, aller-retour
#@ 2+
- [x] 2. La salle en données : tableaux compacts, validation, enregistrement atomique, aller-retour
#@ 1-2
- [ ] 3. Le document en mémoire : choses par identifiant stable, sélection, annulation
- [ ] 4. Le catalogue des assets : planche, région, taille en jeu, ancre, recherche
- [ ] 5. Les actions annulables : déplacer, tourner, échelle, dupliquer, supprimer, calque, profondeur
- [ ] 6. La vue de dessus : zoom, déplacement, écran et monde, sprites, ordre de dessin
- [ ] 7. Le cadre bleu : poignées d'échelle et de rotation, glisser, sélection au rectangle, profondeur
- [ ] 8. Les panneaux : palette, inspecteur, hiérarchie, raccourcis
- [ ] 9. L'orchestration : ouvrir, enregistrer après validation, messages
- [ ] 10. Les collisions : polygones infranchissables
- [ ] 11. Les apparitions et les rencontres : départ du héros, points par rôle, choix des ennemis
- [ ] 12. Les effets placés
- [ ] 13. Les paramètres du jeu : définitions de 5_data
- [ ] 14. Les animations : état vers clip, vitesses
- [ ] 15. Le banc d'essai : modèles, clips, effets
- [ ] 16. Les salles du projet : liste, nouvelle salle
- [ ] 17. Les versions : git local
- [ ] 18. La salle dans le jeu
#@ all
