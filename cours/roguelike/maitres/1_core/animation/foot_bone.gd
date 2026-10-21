class_name FootBone extends BoneAttachment3D
## L'os d'un pied. L'animation de course émet son signal footstep quand le pied touche le sol : une piste de
## méthode de Running_B.res appelle emit_signal("footstep") sur ce nœud. La scène y branche le son du pas.

## Émis quand le pied touche le sol. C'est l'animation qui l'émet : l'avertissement « signal jamais employé »
## ne vaut pas ici.
@warning_ignore("unused_signal")
signal footstep
