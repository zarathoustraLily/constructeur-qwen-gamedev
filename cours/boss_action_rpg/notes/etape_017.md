# Gardien du Comptoir · étape {STEP} · {TITLE}

**Piste : {TRACK}.** laurent, en jouant : « dès qu'un fantôme touche je suis mort » ; « ça serait bien qu'il y ait une
traîne derrière les fantômes ».

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Mesurer avant de changer

Un héros immobile, les spectres appelés, le golem figé : chaque coup reçu est tracé avec son image et sa source. Le
résultat :
- un spectre fait 18 dégâts par plongée, une seule fois par plongée (la zone de coup frappe une fois par allumage) ;
- le héros a déjà un répit de 0,6 s après chaque coup ;
- mais les trois spectres plongent chacun à leur heure, sans s'attendre : un coup toutes les 1,2 s environ. Le héros
  meurt en 7 s, en six coups (images 211 à 639).

Ce n'est donc pas un coup qui tue : c'est une rafale qu'on ne voit pas venir.

### 2. Chacun son tour

`SpectreCall`, qui appelle les spectres, leur donne aussi **le tour de plonger** (`claim_dive`) :
- un seul spectre annonce ou plonge à la fois ;
- après une plongée, le tour ne se libère qu'après `dive_gap` (2 s) ;
- jamais pendant un coup du Gardien (son état `Attack`) : le héros n'a pas à esquiver deux attaques à la fois.

Le spectre qui a fini sa planée demande le tour (`Spectre.may_dive`). Tant qu'on ne le lui donne pas, il continue de
planer. Le tour se libère dès que le plongeur n'annonce plus et ne plonge plus, même s'il a été abattu entre-temps.

Les dégâts d'une plongée passent de 18 à 10. Même mesure, même héros immobile : un coup toutes les 184 à 185 images
(3,1 s), et il lui reste 30 points après 25 s, au lieu de mourir en 7 s.

### 3. La traîne

`SpectreTrail` est une bande de lumière faite des dernières positions du bas du linceul (une par image, gardées
`trail_time`, 0,6 s). Elle est refaite à chaque image dans un `ImmediateMesh`, comme la traînée du marteau du Gardien,
sans objet créé en combat. Elle est :
- **hors de la hiérarchie des positions** (`top_level`) : ses points sont dans le monde, elle ne suit pas le spectre ;
- **tournée vers la caméra** : le bord de la bande est perpendiculaire à la traîne et au regard
  (`Viewport.get_camera_3d`) ;
- large à sa tête (`trail_width`, 0,9 m), effilée et effacée au bout ; immobile, le spectre n'a presque pas de traîne,
  en plongée elle s'étire sur plusieurs mètres.

Son shader (`spectre_trail.gdshader`) la découpe en volutes qui défilent. Il lui donne l'éclat du spectre, qui monte
quand il annonce sa plongée.

### 4. Ce que l'image a appris

- **Des coins nets à la tête de la traîne** : la bande commençait à pleine lumière. Elle s'allume maintenant sur les
  premiers 15 % de sa longueur.
- **Des pans immenses quand un spectre frôle la caméra** : leur cercle de 6 m autour du héros passe par la place de la
  caméra. Mesuré : un spectre passe à 2 m d'elle. Le spectre et sa traîne s'effacent maintenant entre 3 m et 0,8 m de
  la caméra (`-VERTEX.z` dans `fragment()` : la distance du pixel devant la caméra).
- **Trop discrète** : plus longue (0,45 → 0,6 s), plus large (0,8 → 0,9 m), plus vive (0,55 → 0,8).

Images en Forward+ et en Compatibilité.

### 5. Les tests

- Un seul spectre annonce ou plonge à la fois, sur 12 s de combat, et l'écart entre deux plongées tient.
- Pas de plongée pendant un coup du Gardien ; à sa récupération, le tour se donne, à un seul spectre.
- Un héros immobile tient 10 s face aux spectres : entre 1 et 3 coups, espacés de plus de `dive_gap`.
- La traîne s'étire derrière un spectre qui file (à peu près vitesse × durée), se résorbe quand il s'arrête et
  disparaît quand il se dissipe.
- Chaque traîne a son propre matériau, avec l'éclat de son spectre.

Avec les cas des étapes précédentes : 225 cas verts. La mesure du combat sans fenêtre reste à 0 allocation (0,50 ms par
image en médiane, contre 0,47 à l'étape 14 ; trois instances de plus, les traînes).
