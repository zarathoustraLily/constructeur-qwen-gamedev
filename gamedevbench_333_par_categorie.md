# GameDevBench : les 333 tâches par catégorie

Source : dépôt public waynchi/gamedevbench (branche main), lu le 11 octobre 2026. J'ai lu le fichier task_config.json des 333 tâches (nom et consigne).

## Ce qu'il faut savoir avant de lire
- **Catégories** : ce sont les quatre catégories officielles du benchmark (2D Graphics & Animation, 3D Graphics & Animation, User Interface, Gameplay Logic). D'après l'article, chaque tâche a reçu une seule catégorie, attribuée par GPT-5-mini puis relue par des développeurs.
- **Mais l'étiquette de chaque tâche n'est pas publiée.** Ni le dépôt, ni les fichiers des tâches, ni les résultats ne la donnent. Seules 65 tâches portent des mots-clés libres (« 2d, particles », « physics »…). Le classement ci-dessous est donc le mien, fait avec les définitions du benchmark.
- **Écart avec les pourcentages officiels** : le README annonce 26,7 % de 3D, mais seules 45 tâches sur 333 (13,5 %) mentionnent un élément 3D. Ces pourcentages viennent sans doute de la première version de l'article (132 tâches).
- **Beaucoup de variantes** : les 333 tâches se regroupent en 130 familles. Une famille, c'est la même consigne avec d'autres valeurs (Rain Splash × 22, Star/Gemstone Highlight × 22, Campfire Smoke × 21…). 130, c'est presque les 132 tâches d'origine.

| Catégorie | Tâches (mon classement) | % | % officiel (README) | Familles distinctes |
|---|---|---|---|---|
| 2D Graphics & Animation | 157 | 47.1 | 33.3 | 34 |
| 3D Graphics & Animation | 32 | 9.6 | 26.7 | 17 |
| User Interface | 60 | 18.0 | 20.1 | 21 |
| Gameplay Logic | 84 | 25.2 | 19.8 | 58 |
| Total | 333 | 100 | 100 | 130 |

## 2D Graphics & Animation (157 tâches)

### Rain Splash Subemitters (22)
Tâches : 38, 116, 295, 296, 297, 298, 299, 300, 301, 302, 303, 304, 305, 306, 307, 308, 309, 310, 311, 312, 313, 314
> Finish res://scenes/main.tscn so Rain's GPUParticles2D fills the 1800px-wide sky, emits ~800 drops for 5s with a 10s preprocess, 600-850 initial velocity along (0.1, 1, 0), scale 0.2-1.0, hide-on-contact collisions (base size ≈5), and a visibility rect that covers the whole screen (suppose the scree…
Variantes : Rain Splash - Autumn Shower; Rain Splash - Cloudburst; Rain Splash - Evening Patter; Rain Splash - Fine Spray; Rain Splash - Fog Rain; Rain Splash - Gentle Mist; Rain Splash - Hail Mix; Rain Splash - Heavy Downpour; Rain Splash - Ice Pellets; Rain Splash - Light Drizzle; Rain Splash - Monsoon Wall; Rain Splash - Needle Rain; Rain Splash - Scattered Drops; Rain Splash - Sideways Gale; Rain Splash - Spring Rain; Rain Splash - Storm Sheets; Rain Splash - Thunder Shower; Rain Splash - Tropical Burst; Rain Splash - Warm Rain; Rain Splash - Wind Slanted

### Platformer Star Highlight (22)
Tâches : 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248
> Keep the Level node aligned to the viewport with position (53, 5.5), scale (0.65, 0.65), and rotation 0. Keep Sprite2D using assets/sprites/platformer_coins.jpg with centered set to false. Add a Node2D named StarHighlights under the Level node. Inside StarHighlights, create a semi-transparent Polygo…
Variantes : Platformer Gemstone Highlight Variant L; Platformer Gemstone Highlight Variant M; Platformer Gemstone Highlight Variant N; Platformer Gemstone Highlight Variant O; Platformer Gemstone Highlight Variant P; Platformer Gemstone Highlight Variant Q; Platformer Gemstone Highlight Variant R; Platformer Gemstone Highlight Variant S; Platformer Gemstone Highlight Variant T; Platformer Gemstone Highlight Variant U; Platformer Gemstone Highlight Variant V; Platformer Star Highlight Variant B; Platformer Star Highlight Variant C; Platformer Star Highlight Variant D; Platformer Star Highlight Variant E; Platformer Star Highlight Variant F; Platformer Star Highlight Variant G; Platformer Star Highlight Variant H; Platformer Star Highlight Variant I; Platformer Star Highlight Variant J; Platformer Star Highlight Variant K

### Campfire Smoke Trails (21)
Tâches : 39, 315, 316, 317, 318, 319, 320, 321, 322, 323, 324, 325, 326, 327, 328, 329, 330, 331, 332, 333, 334
> Add a GPUParticles2D named SmokeStylized under Campfire in res://scenes/main.tscn that uses the smokelet texture and emits ~12 particles with lifetime 15s and preprocess 20s. Configure its ParticleProcessMaterial with zero gravtiy, initial velocity direction (0.2, -1, 0), 30-50 initial velocity, -30…
Variantes : Campfire Smoke - Bonfire Billows; Campfire Smoke - Candle Trail; Campfire Smoke - Chimney Smoke; Campfire Smoke - Dying Ember; Campfire Smoke - Exhaust Pipe; Campfire Smoke - Factory Stack; Campfire Smoke - Fast Smoke; Campfire Smoke - Furnace Blast; Campfire Smoke - Incense Curl; Campfire Smoke - Lazy Drift; Campfire Smoke - Narrow Column; Campfire Smoke - Ritual Smoke; Campfire Smoke - Smolder Low; Campfire Smoke - Steam Vent; Campfire Smoke - Thick Plume; Campfire Smoke - Thin Wisps; Campfire Smoke - Torch Flicker; Campfire Smoke - Volcanic Vent; Campfire Smoke - Wide Sway; Campfire Smoke - Wildfire Haze

### Trap Spawning Points (14)
Tâches : 22, 115, 118, 119, 200, 202, 203, 204, 205, 206, 207, 208, 209, 210
> Add a Node2D named SpawningPoints under the Trap node. Inside SpawningPoints, create two Marker2D children named SpawnTop and SpawnBot. Place SpawnTop at position (0, 15) and SpawnBot at position (0, -15). Set SpawnBot's z_index to 1.
Variantes : Trap Spawning Points Rotated Variant; Trap Spawning Points Spike Count Variant; Trap Spawning Points Visual Alignment; Trap Spawning Points Visual Alignment Horizontal; Trap Spawning Points Visual Inverse; Tree Spawning Points Branch Variant; Tree Spawning Points Scale Variant E; Tree Spawning Points Scale Variant F; Tree Spawning Points Scale Variant G; Tree Spawning Points Scale Variant H; Tree Spawning Points Scale Variant I; Tree Spawning Points Scale Variant J

### Build Grid Player Nodes (12)
Tâches : 49, 54, 79, 80, 81, 82, 83, 84, 86, 87, 88, 90
> In scenes/Player.tscn finish the Player Area2D by adding the `Sprite2d` that uses res://assets/sokoban_character.png sliced to 6 hframes and 4 vframes (frame 6), a `CollisionShape2d` with a RectangleShape2D sized Vector2(32, 32), a `RayCast2d` that has collide_with_areas enabled, and an AnimationPla…
Variantes : Assemble Crusader AnimatedSprite; Assemble Crusader AnimatedSprite with Correct Directions; Assemble Crusader AnimatedSprite with Walk for Running; Assemble Crusader Collider placement; Assemble Crusader Sprite Sheet Animation; Assemble Crusader Spritesheet Death Animation Setup; Build Grid Player Nodes Alt; Build Grid Player Nodes Alt II; Build Grid Player Nodes Strict Shuffled; Build Grid Player Nodes with Correct Sprite Frames

### Tilemap Water Data (10)
Tâches : 172, 173, 175, 176, 179, 180, 181, 182, 186, 190
> Update `res://assets/tile_set.tres` so the tile set has a custom data layer named `water`. This layer should be a boolean layer, and it should be set to `true` only for the water tiles in the atlas. All non-water tiles should have `water` to be `false`. Do not change the existing tile map structure …
Variantes : Tilemap Add Terrain Collisions; Tilemap Cloud One-Way Collision; Tilemap Isometric I; Tilemap Isometric II; Tilemap Isometric V; Tilemap New Collision Data; Tilemap Numbers; Tilemap Pipes; Tilemap Waterfall Z Index

### Dust Particles Ambience (9)
Tâches : 114, 192, 193, 194, 195, 196, 197, 198, 199
> In scenes/main.tscn, add a GPUParticles2D node named DustParticles under a Node2D named Visuals. Set its position to (320, 180), z_index to 99, amount to 20, lifetime to 6, and assign assets/sprites/star_particle.png as the texture. Create a ParticleProcessMaterial with box emission (set emission sh…
Variantes : Dust Particles Box Emission; Dust Particles Directed Points Emission; Dust Particles Point Emission; Dust Particles Points Emission; Dust Particles Ring Emission; Dust Particles Sphere Emission; Dust Particles Sphere Surface Emission

### Tilemap Terrain (6)
Tâches : 174, 177, 178, 183, 185, 189
> Update `res://assets/tile_set.tres` to add a new terrain named `Leaves` to the existing terrain set. Then assign that terrain to the leaf tiles in the top-right corner of the atlas. These tiles should belong to terrain set 0, use a new `Leaves` terrain, and have their terrain peering bits configured…
Variantes : Tilemap Add Terrains II; Tilemap Isometric III; Tilemap Isometric IV; Tilemap Plant Data; Tilemap Signs

### Platformer Coin Highlights (6)
Tâches : 216, 217, 218, 219, 220, 221
> Add a Node2D named CoinHighlights under the Level node. Inside CoinHighlights, create six semi-transparent circular Polygon2D nodes named CoinHighlight1 through CoinHighlight6. Place one very tight circle over each yellow star coin in the platformer image so each highlight closely covers its coin wi…
Variantes : Platformer Coin Highlights Variant Q; Platformer Coin Highlights Variant R; Platformer Coin Highlights Variant S; Platformer Coin Highlights Variant T; Platformer Coin Highlights Variant U

### Tree Spawning Points Restore Variant K (5)
Tâches : 211, 212, 213, 214, 215
> Rotate the Sprite2D back to 0 and scale it back to Vector2(0.07473366, 0.08652595). Add a Node2D named SpawningPoints under the Trap node. Inside SpawningPoints, create two Marker2D children named SpawnTop and SpawnBot. Place one marker on the bottom tip of the branch closest to the water surface, a…
Variantes : Tree Spawning Points Restore Variant L; Tree Spawning Points Restore Variant M; Tree Spawning Points Restore Variant N; Tree Spawning Points Restore Variant O

### Platformer Coin Highlights Rotated Variant V (5)
Tâches : 222, 223, 224, 225, 226
> Rotate the Level node to 0.37 radians. Add a Node2D named CoinHighlights under the Level node. Inside CoinHighlights, create six semi-transparent circular Polygon2D nodes named CoinHighlight1 through CoinHighlight6. Place one very tight circle over each yellow star coin in the rotated platformer ima…
Variantes : Platformer Coin Highlights Rotated Variant X; Platformer Coin Highlights Rotated Variant Y; Platformer Coin Highlights Rotated Variant Z; Platformer Coin Highlights Rotated Variant Z_1

### River Raid Missile Projectile (2)
Tâches : 4, 67
> Create a Missile scene with an Area2D root named Missile, set its collision layer to 4 and mask to 26, add a Sprite2D that enables region mode to crop the 4×4 missile sprite from sprites-Sheet.png at region Rect2(69, 0, 4, 4), attach a 4×4 rectangular CollisionShape2D, and include a VisibleOnScreenN…
Variantes : River Raid Missile Projectile (Hard)

### Arena Visuals TileMapLayers (2)
Tâches : 112, 113
> Create a TileSet resource at scenes/arena/tileset.tres using assets/sprites/tiles.png as a TileSetAtlasSource with a 32x32 tile size. In scenes/main.tscn, add three TileMapLayer nodes named Background, Props, and Walls under a Node2D named Visuals, and assign the TileSet to each layer. Paint the Bac…
Variantes : Game Area and Bench TileMapLayers

### River Raid Player Jet Scene
Tâches : 3
> Create a Player scene with a CharacterBody2D root named Player, add an AnimatedSprite2D that autoplay the default animation and includes looping default/left/right jet frames from assets/sprites/sprites-Sheet.png and a non-looping explode sequence from the smoke sprites at assets/sprites/Free Smoke …

### Unsafe Platform Warning Cycle
Tâches : 9
> Clone the SafePlatform scene into an UnsafePlatform that warns players before it drops them. Add an AnimationPlayer with an UnsafeCycle animation that autoplays, keyframe Area2D.modulate through calm white, brighter orange, and a red danger state, and in the same animation toggle Area2D.process_mode…

### Draw Steering Force Gizmos
Tâches : 35
> Use the SteerComponent's _draw function to render the velocity vector in black, the desired velocity in red, a blue connector between them, and circles at both tips so the steering forces are visible during play.

### Additive Sprite Lights
Tâches : 47
> Populate the Lights node with three Sprite2D faux lights aligned with the Left, Center, and Right markers. Name the Sprite2D nodes TorchLeft, TorchCenter, and TorchRight. Each sprite must use the provided glow textures (glow_disc.tres for the two torches on the sides, glow_streak.tres for the center…

### Car Scene Assembly
Tâches : 53
> In scenes/car.tscn, keep the CharacterBody2D named Car as the root and add the following hierarchy: add a Sprite2D child that uses res://assets/spritesheet_vehicles.png, enable region_rect so it crops Rect2(291, 0, 70, 133), and rotate the sprite 90° so the car faces forward. Add a CollisionShape2D …

### Configure RTS Unit Scene with Aura Highlight
Tâches : 57
> Build the reusable Unit scene: root it in a CharacterBody2D on collision layer 2/mask 3, keep it in the 'units' group. Add a Sprite2D child that uses the towerDefense spritesheet texture with region_enabled=true and region_rect=Rect2(960, 640, 64, 64), and apply a ShaderMaterial using the aura.gdsha…

### Safe Platform Length Builder
Tâches : 66
> Turn the SafePlatform scene into a multi-tile platform: Add a hidden Node2D node named `Templates` that holds a Sprite2D using the supplied assets/sprites/tile_0108.tres texture and a matching CollisionShape2D, export length (1–5) and tile_offset_amount on the @tool script, implement setupLength() s…

### CRT Shader Effect Implementation
Tâches : 95
> Implement the CRT screen shader in screen_effect/screen_effect.gdshader. Use a canvas_item shader with render_mode unshaded and skip_vertex_transform. Add constants for curvature (7.0) and vignette_multiplier (2.0), and declare a sampler2D uniform named screen_texture with the screen texture hint an…

### Pixel Art Screen Quad Shader
Tâches : 96
> In scenes/main.tscn, add a MeshInstance2D named ScreenQuad that uses a QuadMesh sized 1280x720 and is positioned at (640, 360). Create a ShaderMaterial for it that uses a new shader at assets/shaders/pixel_art.gdshader. The shader must sample the screen texture with filter_nearest, downsample SCREEN…

### Distortion UV Preview Shader
Tâches : 97
> Create a TextureRect named DistortionPreview under Main and assign the shaderV_icon.png texture. Add a ShaderMaterial that uses a VisualShader with the DistortionUV custom node from addons/shaderV/uv/distortionUV.gd, matching the DistortionUV example constants (wave X 7, wave Y 5, distortion 0.1 on …

### Ninja Lower Run/Stand Animations
Tâches : 98
> Create lower-body animations in AnimationPlayerLower so Anchor/SpriteLower plays a looping run (frames 0-5 at 0.1s per frame) and a stand animation using frame 6 (non-looping, also with step and length 0.1).

### TileMap Physics Layer and Details Layer
Tâches : 102
> In Main.tscn, add a second TileMap layer named Details (keep layer 0 as Base). In the TileSet, enable physics layer 0 with collision layer 2 and add a full-tile collision polygon to the atlas tile at (0,0) so it covers the entire 18x18 tile.

### AnimatedSprite2D Sprite Sheet Slicing
Tâches : 104
> Under a CharacterBody2D, add an AnimatedSprite2D and create SpriteFrames using Add Frames from Sprite Sheet. Set vertical frames to 1 and horizontal frames to 24. Create a default animation by selecting frames 0-3 from the sheet, then add a run animation with six frames from the same sheet. Attach a…

### Track Particles Driven by Tile Type Gradient
Tâches : 108
> In `scenes/world.tscn`, add a TileSet custom data layer named `tile_type` with type int, and assign GradientTexture1D exports named `water_color`, `dirt_color`, and `grass_color` on the World node. In `scripts/world.gd`, add `enum TILE_TYPES { NONE, WATER, DIRT, GRASS }`, export the three GradientTe…

### Player Hurt/Fall/Grounded Animations
Tâches : 109
> In the Player scene, add three AnimationPlayer animations named hurt, fall, and grounded. Set hurt to 0.3s with 0.1s steps, keyframe CharacterSprite and KnifeSprite to frames 70, 71, and 72, and add a method track on the Player (path ".") that calls on_action_complete at 0.3s. Set fall to a looping …

### Rain Splash Subemitters Red
Tâches : 117
> Finish res://scenes/main.tscn to create a blood rain particle effect. Make it so Rain's GPUParticles2D fills the 1800px-wide sky, emits ~800 drops for 5s with a 10s preprocess, 600-850 initial velocity along (0.1, 1, 0), scale 0.2-1.0, hide-on-contact collisions (base size ≈5), and a visibility rect…

### Trap Spawning Points Imitating
Tâches : 120
> In the main scene, add a node named TrapTop by referencing the existing TrapBot's implementation. Keep all other attributes of the new node and its children the same as the original TrapBot, while modifying the position of TrapTop to (0, -32) so it appears above TrapBot, and set the rotation of the …

### TileMap Migration
Tâches : 123
> In Main.tscn, update the deprecated TileMap node under Main by replacing it with the newer TileMapLayer nodes: for each layer in TileMap, add a new TileMapLayer node as the child of TileMap while keeping its tilemap data and z-index. The child node's name should be the same as the original layer's n…

### TileMap Atlas Physics Layer Full Course
Tâches : 125
> In assets/tile_set.tres, set up a physics layer and paint collision shapes for tiles: in the TileSet, enable physics layer 0 with collision layer 2; then, add a full-tile collision polygon to the atlas tile at all solid tiles so it covers the entire 18x18 tile. Solid tiles are defined as tiles in wh…

### Fighter Enemy Sprite Update
Tâches : 169
> Update the basic enemy scene to use a different spritesheet. In `res://scenes/characters/basic_enemy.tscn`, change the enemy sprite texture to `res://assets/art/characters/enemy_boss.png` while keeping the existing node structure and animations. Because the new spritesheet uses different frame locat…

### Trap Spawning Points Centered Variant
Tâches : 201
> Move the Trap node to the center of the viewport at position (320, 180) and scale it up to (4, 4). Add a Node2D named SpawningPoints under the Trap node. Inside SpawningPoints, create two Marker2D children named SpawnTop and SpawnBot. Place SpawnTop at the tip of the upper spike, and SpawnBot at the…


## 3D Graphics & Animation (32 tâches)

### Depth Ripple Geometry Setup (11)
Tâches : 62, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78
> Populate res://scenes/main.tscn so Main contains a water depth visualization scene: add a WorldEnvironment with a procedural sky and glow enabled, a DirectionalLight3D with shadows enabled, a MeshInstance3D named Water that uses a 10x10 PlaneMesh subdivided 20x20 with a ShaderMaterial pointing at re…

### Build the gritty world environment stack (5)
Tâches : 14, 129, 187, 188, 191
> Under Main, configure the WorldEnvironment so its Environment keeps the procedural sky background (background_mode = Sky) with the ProceduralSkyMaterial's sky colors set to Color(0.5216, 0.6706, 0.7922), switches to ACES tone mapping, enables SSR with 128 max steps and 0.51 depth tolerance, enables …
Variantes : Build the gritty world environment skybox; Build the gritty world environment stack i; Build the gritty world environment stack ii; Build the gritty world environment stack iii

### Enable fog and LUT grading (2)
Tâches : 15, 130
> Enable depth fog in the shared WorldEnvironment, tint it to Color(0.5176, 0.5529, 0.6196) with density 0.001 and sky affect 0.147, enable volumetric fog with albedo Color(0.8706, 0.7961, 0.7726), and turn on Adjustments so the color correction slot uses the provided ExtremeLUT.png Texture3D as its l…

### Cultist Limb SkeletonIK
Tâches : 17
> Inside Main/Cultist/CultistBody/CultistRig/Skeleton3D, create four SkeletonIK3D nodes named Hand_R_IK, Hand_L_IK, Foot_R_IK, and Foot_L_IK. Configure their root/tip bones exactly as in the video (upper_arm.R → hand.R, upper_arm.L → hand.L, thigh.R → foot.R, thigh.L → foot.L), enable magnet support, …

### Wire the weapon effects controller
Tâches : 18
> In scenes/main.tscn, finish the arms rig so BarrelEnd has a RayCast3D child that points straight 1000 units forward (facing away from camera), then add a WeaponEffectsController node under ArmsRig that uses scripts/weapon_effects_controller.gd. Assign its Barrel End and Barrel RayCast exports to the…

### Build the muzzle flash effect prefab
Tâches : 19
> Create a layered muzzle flash prefab: edit scenes/effects/muzzle_flash_effect.tscn so the root Node3D uses scripts/generic_effect_handler.gd, targets its Optional Light export at an OmniLight child named MuzzleFlash, and keeps a 0.2 second fade. Add SmokeParticles configured with zero gravity and a …

### Level Camera Menu Hookup
Tâches : 21
> In res://scenes/level.tscn add a Camera3D named LevelCamera that matches the static menu shot (use position roughly -12.22, 15.83, 12.44 and use the rotation basis vectors (0.794097, 0.0, 0.607792), (0.37447, 0.787656, -0.489255), (-0.478731, 0.616115, 0.625475); leave current disabled). Instance re…

### Bonkahe Sunshine Clouds Driver Setup
Tâches : 30
> Under Main, add a SunshineCloudsDriver node that uses addons/SunshineClouds2/SunshineCloudsDriver.gd, enable Update Continuously, and assign res://assets/clouds/tutorial_clouds_settings.tres to its clouds_resource while reusing the WorldEnvironment environment as ambience_sample_environment. Registe…

### Bonkahe Sunshine Clouds Effectors
Tâches : 31
> Reuse the supplied volumetric clouds setup but finish the advanced controls: configure OmniLight3D as the warm point light: (color Color(0.76, 0.374933, 0.1824, 1), energy 11.685, range 20000, positioned at (10743.6, 6693.89, -43458.2)) and add it to SunshineCloudsDriver.tracked_point_lights. Instan…

### Bonkahe GPU Smoke Plume
Tâches : 32
> Complete the unfinished SmokeEmitter under Main: set the GPUParticles3D amount to 32, lifetime to 8 seconds, and draw order to View Depth, then attach a ParticleProcessMaterial that emits from a 1m sphere, keeps direction (0, 1, 0), adds gravity (0, 3, 0), uses 0.5 lifetime randomness, full ±180° an…

### Bonkahe Arcing Chunk Sub-Emitter
Tâches : 33
> Finish the Explosion hierarchy so the ArcingChunks emitter works as wanted: set ArcingChunks to one_shot, lifetime 3s, randomness about 0.7, give it a QuadMesh draw pass and a StandardMaterial3D billboard with bright emission, and drive it with a ParticleProcessMaterial that fires from the default s…

### FPS Arms Prefab Wiring
Tâches : 45
> Add an `ArmsContainer` Node3D under `PlayerBody`, move it to (0, 0.5, 0), and instance `ScenePrefabs/ArmsPrefab.tscn` there as `ArmsMesh`. Configure the `PlayerBody` exports so its animation tree points to the prefab, the playback path stays `parameters/playback`, the idle/aiming/idle_fire/aiming_fi…

### Codex HQX Smooth Borders Shader
Tâches : 100
> Update res://assets/shaders/map3d.gdshader to apply HQX-style border smoothing for the map texture. Add uniforms threshold (0.1), aa_scale (17.6), and base_line_thickness (0.38197), include the diagonal line blending function, and in fragment sample subview_image with texelFetch to compute the smoot…

### Depth Outline Compositor Shader
Tâches : 106
> Implement `res://scripts/outline_effect.gd` and `res://outline.glsl` for a depth-based outline compositor effect. The script must include `@tool`, `extends CompositorEffect`, and `class_name OutlineEffect`. It must use `RenderingServer.get_rendering_device()` and create the compute pipeline with `rd…

### Apply View Model Clip Shader
Tâches : 107
> Implement the view model clip shader swap on the weapon view model node. Add logic that finds MeshInstance3D nodes under the view model, replaces each surface material with a ShaderMaterial that uses res://shaders/weapon_clip_and_fov_shader.gdshader, copies the base material albedo/metallic/roughnes…

### Basic Triplanar Shader on a Sphere
Tâches : 110
> Create a Node3D scene with a MeshInstance3D sphere that uses a SphereMesh and a ShaderMaterial assigned to the SphereMesh material. Write a spatial shader at res://scripts/triplanar_basic.gdshader that projects a single texture along the X, Y, and Z axes using world-space vertex coordinates and norm…

### Axis Textures and Top-Only Grass Triplanar Shader
Tâches : 111
> Create a Node3D root named Main with a MeshInstance3D child named Sphere. Assign a SphereMesh to Sphere.mesh and assign a ShaderMaterial to that SphereMesh. The ShaderMaterial must use a shader at res://scripts/triplanar_axis_blend.gdshader. In that shader, declare uniforms `uniform sampler2D textur…


## User Interface (60 tâches)

### Create Battle Over Panel (15)
Tâches : 93, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163
> Create a battle over UI panel scene and its script. Add res://scenes/ui/battle_over_panel.tscn with a root Panel named BattleOverPanel, set process mode to Always, and stretch it to full rect. Override the panel style with a StyleBoxFlat using rgba(0, 0, 0, 0.34902). Add a centered VBoxContainer wit…
Variantes : Battle Over Panel Expand B; Battle Over Panel Expand C; Battle Over Panel Expand D; Battle Over Panel Expand Fill A; Battle Over Panel Expand Fill B; Battle Over Panel Expand Fill C; Battle Over Panel Fill A; Battle Over Panel Fill B; Battle Over Panel Fill C; Battle Over Panel Shrink Begin A; Battle Over Panel Shrink Begin B; Battle Over Panel Shrink Begin C; Battle Over Panel Shrink Begin D

### River Raid Power HUD (13)
Tâches : 5, 133, 134, 136, 137, 138, 140, 141, 143, 144, 146, 147, 149
> Create a UI scene with a CanvasLayer root named UI. Add a ControlPanelRect ColorRect (with bottom-wide anchor mode and custom minimum height of 58) tinted grey (rgba = (0.6, 0.6, 0.6, 1.0)), place Lives: 3 and Points: 0 labels inside it (with names LivesLabel and PointsLabel), and add PowerMeter and…
Variantes : Alert Dialog Center Preset; Canyon Raid Dashboard; Left Wide HUD A; Left Wide Status Strip; Right Wide HUD A; Right Wide Status Strip; River Raid Power HUD A; Sky Patrol Status Strip; Top Wide HUD A; Top Wide Status Strip; Warning Dialog Center Preset

### Tank UI Signals Exact (6)
Tâches : 256, 257, 258, 259, 260, 261
> Restore the missing gameplay HUD and its signal wiring. Add `res://scenes/game.tscn` with a `game` `Node2D` root that instances child nodes named `World`, `Tank`, and `UI`, add `res://scenes/game.gd`, bind its exported `tank` and `ui` references to the `Tank` and `UI` children, and set `application/…
Variantes : Tank Battle HUD Wiring; Tank Combat HUD Restore; Tank Overlay Signal Repair; Tank Stage HUD Restore; Tank Status Overlay Restore

### River Raid Power HUD B (4)
Tâches : 135, 142, 145, 148
> In scenes/ui.tscn, make UI a CanvasLayer. Add a grey ControlPanelRect ColorRect with the Bottom Wide layout preset so it stays attached to the bottom as its minimum height grows, set its custom minimum height to 58, add LivesLabel with Lives: 3 and PointsLabel with Points: 0, place a centered bottom…
Variantes : Left Wide HUD B; Right Wide HUD B; Top Wide HUD B

### Portrait Balloon Layout (2)
Tâches : 43, 121
> Build the portrait-ready dialogue balloon in `scenes/portrait_balloon.tscn`. Wrap the dialogue content in an `HBoxContainer` with a named TextureRect portrait slot (150×150 min size) before the VBox text column, set the separation to 30 px, and flag the portrait node as unique for scripts. Name the …
Variantes : Portrait Balloon Layout Alt

### Audio Demo Grid UI (2)
Tâches : 58, 89
> Create res://scenes/audio_demo.tscn with a MarginContainer root named "AudioDemo" that fills the screen, uses 20px margins on all sides, and attaches res://scripts/audio_demo.gd exporting sound_dir defaulting to res://assets. Add a CenterContainer with a GridContainer child set to two columns, with …
Variantes : Audio Demo Grid UI Formatting

### Minimap UI frame and markers (2)
Tâches : 59, 131
> Implement the minimap UI frame and markers. Inside Main/CanvasLayer/Minimap, size the Minimap MarginContainer to 200x200 with 5px margins, add a NinePatchRect Frame using panel_woodDetail_blank.png with 64px patch margins, add a sibling MarginContainer named "Content" with 20px margins containing a …
Variantes : Minimap UI Complex

### Minimap marker logic and zoom control (2)
Tâches : 60, 132
> Implement the minimap logic: export a Player reference and a zoom property with a clamped setter, cache the grid and marker prototypes, center the player marker after the first frame, compute grid_scale from the grid size and viewport, duplicate and show markers for every node in the minimap_objects…
Variantes : Minimap marker logic Complex

### Fractal Control UI Panel (2)
Tâches : 99, 126
> In `scenes/UI.tscn`, configure the `UI` Panel to work as a control panel layout. Set `self_modulate` alpha to 200/255, use the left-wide anchor preset with horizontal width 320 extending from the left-side screen edge, and set `grow_vertical` to BOTH. Add a `VBoxContainer` named `Menu` sized (300, 8…
Variantes : Fractal Control UI Panel Original

### Stats UI Overlay
Tâches : 8
> Turn res://scenes/stats_ui.tscn into the StatsUI overlay from the tutorial. Use an HBoxContainer root anchored to the center (about 90×16) with theme res://assets/main_theme.tres and alignment set to Center. Add two child HBoxContainers named Block and Health; set Block's separation override to 0 an…

### Transition Menu Prefab
Tâches : 20
> Create res://scenes/menus.tscn as a Control named Menus that fills the viewport, keeps process mode Always, and uses scripts/menu_handler.gd. Add three hidden panels, all centered with anchors at 0.5: LaunchMenu (offsets: -205, -196 to 205, 196), PauseMenu (offsets: -205, -196 to 205, 45), and Resta…

### Player Damage Signal Bridge
Tâches : 23
> In res://scenes/main.tscn, use the existing Main (Node2D) root and existing Player (CharacterBody2D) node. Add a CanvasLayer named HUD with a Label called DamageLabel that starts at "Total Damage: 0", and connect Player.taken_damage to Main._on_player_taken_damage so the label updates each time Play…

### Trait UI Highlight
Tâches : 36
> Make the trait panel behave like the tutorial's left-column tracker. In res://scenes/trait_ui/trait_ui.tscn keep the existing node hierarchy but complete trait_ui.gd so that exporting trait_data: Trait populates the icon and name label, update(units) counts the number of unique unit names that inclu…

### Cooldown Button UI Shell
Tâches : 56
> Finish scenes/AbilityButton.tscn so the TextureButton named AbilityButton uses res://assets/icons/energy-arrow.png and contains the cooldown UI hierarchy from the KidsCanCode recipe. Add a Sweep TextureProgressBar child that fills the entire button, sets fill_mode to Counter Clockwise, value to 0, a…

### fps_hit_label_overlay
Tâches : 61
> Add a CanvasLayer with a Label to the FPSPlayer so hit information can be displayed, setting the label offsets to left 10, top 15, right 50, bottom 41 and the font size to 16. Keep the node names the same as their class names.

### HUD GameOver Overlay
Tâches : 63
> Populate the HUD CanvasLayer so it shows a top MarginContainer named MarginContainer, with a HBoxContainer child node named HBoxContainer, which then contains two Label named Health and Score, writing "Health: 100" and "Score: 0" repsectively. Then, add a hidden MarginContainer, named GameOver, stre…

### HUD Status Bar
Tâches : 65
> In the HUD CanvasLayer in hud.tscn, create a top MarginContainer anchored to the top of the viewport with 20-pixel margins on left, top, and right. Add an HBoxContainer child, then add two Label children: "Health" displaying "Health: 100" and "Score" displaying "Score: 0" with right alignment (size_…

### LibSM64 ROM Dialog and Connections
Tâches : 94
> Create a new scene at scenes/rom_picker_dialog.tscn with a FileDialog named RomPickerDialog. Set its title to "Pick Super Mario 64 ROM file", size to 335x180, ok_button_text to "Open", file_mode to Open File, access to Filesystem, and filters to include *.n64 and *.z64. Add an AcceptDialog child nam…

### Fractal Panel With Julia Shader Alt
Tâches : 128
> In `scenes/main.tscn`, add a TextureRect named `Panel` under `Main`. Set its anchors to fill the viewport (use the FULL_RECT preset for anchors preset), assign `materials/julia.material` to the `material` property, set `icon.png` as its texture, and edit julia.material to set the `seed` shader param…

### Danger Dialog Center Preset
Tâches : 139
> In scenes/ui.tscn, create a CanvasLayer root named UI and add a hidden DangerDialog CenterContainer using the Center preset. Add a ColorRect named ColorRect inside it with a custom minimum size of 240 by 110, and add a Label named Label inside the ColorRect with the text DANGER.

### Save User Preferences
Tâches : 262
> Restore the menu preference persistence feature. Use `res://assets/reference/game_menu_reference.png` as the visual reference for the settings screen and make the existing `res://scenes/ui/menus/game_menu.tscn` menu match that layout when reopened with saved values applied to its visible controls. A…


## Gameplay Logic (84 tâches)

### card_dragging_state_machine_a (13)
Tâches : 281, 282, 283, 285, 286, 287, 288, 289, 290, 291, 292, 293, 294
> Finish the card dragging mechanic for the alternate harness. The provided `res://scenes/main.tscn` harness keeps three `CardUI` instances under `HUD/CardRow`, and each card should continue using the existing `CardStateMachine`, `CardBaseState`, `CardClickedState`, and `CardDraggingState` nodes from …
Variantes : card_dragging_state_machine_b; card_dragging_state_machine_c; card_dragging_state_machine_d; card_dragging_state_machine_e; card_dragging_state_machine_f; card_dragging_state_machine_g; card_dragging_state_machine_h; card_dragging_state_machine_i; card_dragging_state_machine_j; card_dragging_state_machine_l; card_dragging_state_machine_p; card_dragging_state_machine_q

### Tilemap Chaser Goal Variant A (6)
Tâches : 250, 251, 252, 253, 254, 255
> Restore the chase setup in `res://main.tscn` so the existing `Chaser` `CharacterBody2D` is configured for obstacle-aware movement toward the existing `Goal` `Area2D`. Recreate `res://Chaser.gd`, attach it back to `Chaser`, export a `goal: Node2D`, assign it to `../Goal` so `Chaser.goal` resolves to …
Variantes : Tilemap Bot Checkpoint Variant F; Tilemap Drone Focus Variant C; Tilemap Guard Beacon Variant B; Tilemap Hunter Marker Variant D; Tilemap Seeker Objective Variant E

### detect_range_target_finder (6)
Tâches : 267, 274, 275, 276, 277, 278
> Implement the autobattler combat-targeting setup from the tutorial. In `res://data/units/unit_stats.gd`, define `TARGET = { Team.PLAYER: "enemy_units", Team.ENEMY: "player_units" }` so units can look up the opposing group name from their team. Create `res://custom_nodes/detect_range.gd` as `class_na…
Variantes : task_0274; task_0275; task_0276; task_0277; task_0278

### Implement Bullet Collision Cleanup (2)
Tâches : 12, 68
> Update res://scripts/entities/tank/weapon/bullet.gd so the Bullet has const SPEED = 500, stores its travel direction and firing tank, moves every physics frame by direction.normalized() * SPEED * delta, queues itself when area_entered fires, and on body_entered destroys Crate bodies before calling q…

### Codex Interactable Highlight Resource (2)
Tâches : 24, 122
> Author res://scripts/interactable_item.gd so it extends Node3D with class_name InteractableItem, exports a MeshInstance3D named item_highlight_mesh, hides that mesh in _ready(), and provides gain_focus() / lose_focus() methods that toggle its visibility. Attach the script to the RigidBody3D in res:/…

### ProtoController Freefly Input Map (2)
Tâches : 46, 85
> Instance the ProtoController scene (res://addons/proto_controller/proto_controller.tscn) in Main as Player, leave it above the floor, enable Sprint and Freefly on the inspector, and point all of its input_* fields to custom actions named move_left/right/up/down, jump, sprint, and freefly. Then open …
Variantes : ProtoController Freefly Input Map Controller

### Platform Character Acceleration Lerp (2)
Tâches : 52, 55
> Update scripts/player.gd so the Player exports @export_range(0.0, 1.0) var friction = 0.1 and @export_range(0.0, 1.0) var acceleration = 0.25, cache Input.get_axis("move_left", "move_right") in a dir variable, lerp velocity.x toward dir * speed using acceleration whenever dir != 0, lerp toward 0 usi…
Variantes : Implement Mouse Direction Controller

### Projectile Step Tracker
Tâches : 2
> Make the projectile advance the Shoot Em Up quest by calling QuestManager.progress_quest with the kill step each time it overlaps an enemy, queue_free itself after the hit, and ensure it also removes itself when it travels far off screen (50 pixels).

### Unit AI Debug Label
Tâches : 6
> In res://scenes/battle_unit/battle_unit.tscn add a Label child named FSMDebugLabel above the sprite (offsets -65,-47 to 65,-29) with centered text reading IDLE, then add a UnitAI node that uses res://scenes/battle_unit/ai/unit_ai.gd and wire its exported debug_label to FSMDebugLabel and actor to the…

### CardPile Resource Utilities
Tâches : 7
> Implement res://scripts/card_pile.gd for the Card Pile resource. Register class_name CardPile, export an Array[Card], and declare the card_pile_size_changed(cards_amount) signal. Provide helpers empty(), draw_card(), add_card(), shuffle(), clear(), and _to_string(). draw_card() must pop the front ca…

### Create Pickup Collectible
Tâches : 10
> Build res://scenes/entities/world/pickup.tscn with an Area2D root named Pickup that uses res://scripts/entities/world/pickup.gd, add a Sprite2D using assets/sprites/pickups.png, a CollisionShape2D using an 8×8 RectangleShape2D, and an AudioStreamPlayer on the SFX bus that plays assets/audio/sfx/pick…

### Configure Bullet Scene Signals
Tâches : 11
> Create res://scenes/entities/tank/weapon/bullet.tscn with an Area2D root named Bullet that uses res://scripts/entities/tank/weapon/bullet.gd, set its collision_layer to 16 and collision_mask to 44, add a 3×3 rectangular CollisionShape2D plus a Sprite2D with a texture, and connect both area_entered a…

### Implement FSM Foundations
Tâches : 13
> Implement res://components/state.gd so State._init(new_actor) stores the provided actor reference, and complete res://components/finite_state_machine.gd by declaring a state_changed(new_state) signal plus a change_state(new_state) method that calls exit() on the previous state, enter() on the new st…

### Install the cultist flashlight priority marker
Tâches : 16
> In scenes/cultist_prefab.tscn add a FlashlightPoint instance (point_of_interest.tscn) under ChestMarkerContainer so Main/Cultist exposes a child named FlashlightPoint that belongs to the FlashlightPoints group and has its priority set to High. Leave the existing ChestTarget marker alone; only wire u…

### Codex Interaction Area Pickup
Tâches : 25
> Implement res://scripts/player_interaction_handler.gd so it extends Area3D with class_name PlayerInteractionHandler, defines an item_picked_up(item_data: ItemData) signal, exports item_types: Array[ItemData], tracks nearby_bodies: Array[InteractableItem], listens for the 'interact' input action in _…

### Codex Camera Shake Rig
Tâches : 26
> In scenes/player_body.tscn, restructure PlayerBody so CameraNode contains a CameraActual Node3D with a Camera3D child, assign those nodes to the player_body.gd exports, and implement a noise-based camera shake: expose a FastNoiseLite plus numeric exports for noise_panning_speed (30), max_power (0.15…

### Codex Weapon Recoil Signal
Tâches : 27
> In scenes/weapon_rig.tscn, expose WeaponEffects with BarrelEnd/BarrelRayCast exports plus a camera_shake_power export set to 0.3, declare the on_shot_camera_impulse(Vector3,float) signal in scripts/weapon_effects.gd, and emit it from fire_weapon() using the normalized -BarrelRayCast global forward d…

### Bonkahe Flashlight Priority Points
Tâches : 28
> Create a reusable FlashlightPoint marker scene that uses scripts/flashlight_point.gd to expose a Priority enum (low, medium, high), a has_been_targeted flag, and a reset_target_state() helper, then instance three FlashlightPoint nodes directly under Main in scenes/main.tscn. Place the nodes at (8.36…

### Bonkahe Enemy Spawn Trigger
Tâches : 29
> Attach res://scripts/TriggerVolume.gd to NavigationRegion3D/Triggers/SpawnTrigger1 so its TriggerVolume_BodyEntered handler queue_frees the trigger after the wave fires. Implement res://scripts/EnemySpawnPoint.gd with exports for variables named EnemyPackedScene, AutoSetTarget, and TargetToSet, then…

### Buffer Steering Debug Vectors
Tâches : 34
> Inside the SteerComponent script, capture the current velocity, scaled desired velocity, and steering force in a debug dictionary whenever debugging is enabled, and queue a redraw every frame so the overlay can update.

### Sell Portal Gold Preview
Tâches : 37
> Finish res://scenes/sell_portal/sell_portal.gd so the Area2D behaves like a selling portal. Keep the OutlineHighlighter and FlipSprite nodes wired to the CanvasGroup + Sprite2D, scan the "units" group in _ready() and call setup_unit(unit) to connect each unit's DragAndDrop.dropped and quick_sell_pre…

### Day-Night Cycle Controller
Tâches : 40
> Finish res://scenes/Main.tscn by wiring the provided day-night scripts to the existing SunLight, ClockLabel, and PorchLight. Under Main add a Node named DayNightCycle that runs scripts/day_night/DayNightCycleNode.gd and give it four children: LightColorTransition, SampledObjectRotator, TimeHandler, …

### Pong Scoreboard and Respawn
Tâches : 41
> Add a Scoreboard and Respawn mechanism to the Pong game. Attach a new Pong script named `pong.gd` in scripts directory to the Main scene that tracks left_points and right_points, exposes reset_points(), handle_left_point_up(), handle_right_point_up(), and respawns the Ball via new_ball() after every…

### Pong Camera Spring Shake
Tâches : 42
> Add a Camera2D node centered on the playfield, attach a Camera2D.gd script that stores displacement, velocity, and the SPRING=900, DAMP=18, MULTIPLIER=20 constants, and implement a shake(right_pointed) method that reverses direction based on who scored. Update pong.gd so new_ball() keeps respawning …

### Wire inventory add/clear buttons
Tâches : 44
> Attach inventory.gd to the Inventory PanelContainer so it exports an Array[Item] and caches $MarginContainer/GridContainer, then implement add_item_resource() to locate the first Slot child without slotItemResource, construct a new Item with the icon texture (from res://assets/sprites/item_icon.png)…

### Codex Draggable Decorations
Tâches : 48
> Implement scenes/draggable.tscn as a decoration component that can be dragged. The root Area2D must be named Draggable in the scene, set collision_mask to 2, linear_damp to 20, and attach scripts/draggable.gd. Under it, add Sprite2D named Sprite that uses assets/sprites/star_1.png and is uniformly s…

### Tween Grid Movement
Tâches : 50
> Finish scripts/player.gd by adding var animation_speed = 2.0, a moving flag, and an @onready var ray = $RayCast2d. In _unhandled_input(event) ignore input whenever moving is true, otherwise forward the pressed direction to move(dir). Inside move(dir) set ray.target_position = inputs[dir] * tile_size…

### Platform Character Core Movement
Tâches : 51
> Populate scenes/Player.tscn and scripts/player.gd so Main instantiates a CharacterBody2D named Player with a Sprite2D that uses assets/sprites/tileYellow_02.png and a RectangleShape2D sized 32×68, export speed=1200, jump_speed=-1800, and gravity=4000 on the Player script, increment velocity.y by gra…

### Build the door switch Phantom Camera transition
Tâches : 64
> Register EventController as an autoload that exposes an exit_switch_flipped signal. Build door_switch.tscn so its Area2D contains an AnimatedSprite2D with all switch_button frames from 2 to 0 and animation speed of 9 FPS, a StaticBody2D + CapsuleShape2D floor collider, a second CapsuleShape2D for th…

### Sync Upper and Lower Animations
Tâches : 91
> In scripts/player.gd, connect AnimationPlayerLower.current_animation_changed so AnimationPlayerUpper plays the same animation unless the upper player is currently playing "attack". Also connect AnimationPlayerUpper.animation_finished so when the "attack" animation finishes, the upper player switches…

### Create Music Player Scene
Tâches : 92
> Create a reusable sound player script and a music player scene. Add res://global/sound_player.gd that extends Node with a play(audio: AudioStream, single := false) method that returns early when audio is null, stops all current players when single is true, and plays the first idle AudioStreamPlayer …

### Enemy Navigation Node Setup
Tâches : 101
> Create a CharacterBody2D named Enemy under the main scene root. Add Sprite2D and CollisionShape2D children named Sprite2D and CollisionShape2D, assign the Sprite2D texture to res://assets/sprites/towerDefense_tile245.png, and set the CollisionShape2D shape to CircleShape2D with radius 12. Add a Node…

### NavigationAgent2D Enemy Chase
Tâches : 103
> Under Main, finish the navigation system for Enemy: add a Node2D child named Navigation that contains a NavigationAgent2D node named NavigationAgent2D (path_postprocessing set to Corridor and debug_enabled enabled) and a Timer named Timer (wait_time 0.1, autostart enabled), then connect the Timer ti…

### Create Music and SFX Audio Players
Tâches : 105
> Create `res://default_bus_layout.tres` with Music and SFX buses (set `bus/1/name` to `&"Music"` and `bus/2/name` to `&"SFX"`). Add `res://scenes/audio_player/audio_player.gd` with `play()` and `stop()` methods that operate on child `AudioStreamPlayer` nodes. Create `res://scenes/audio_player/music_p…

### Codex Enemy Hit SFX Plus
Tâches : 124
> In res://scenes/enemy.tscn, add a VariablePitchAudioStreamPlayer child named VariablePitchAudioStreamPlayer with res://assets/sounds/hit_sound.wav and set volume_db to 5.0. Add a new audio bus named `Enemy`, route it to send to `Sounds`, and set the audio bus of the VariablePitchAduioStreamPlayer no…

### Codex Music Bus Autoload Alt
Tâches : 127
> In res://scenes/music_player.tscn, set the MusicPlayer AudioStreamPlayer to use res://assets/sounds/music.ogg, enable autoplay, and set its bus to Music. In project settings, add MusicPlayer as an autoload pointing to res://scenes/music_player.tscn, and configure the audio bus setting so that both M…

### Fighter Player Jump
Tâches : 164
> Add the player's jump action to the existing fighter controls. Update `res://scenes/characters/character.gd` so the player can enter a jump sequence from normal grounded movement, rise off the ground, fall back down, and return to the regular grounded state after landing. Use the existing `on_takeof…

### Fighter Player Jumpkick
Tâches : 165
> Extend the existing jump system with an airborne kick attack. Update `res://scenes/characters/character.gd` so pressing `attack` during the airborne jump phase triggers a dedicated jumpkick state instead of the normal grounded punch, keeps the player in the air until the jump arc finishes, and then …

### Fighter Player Kick
Tâches : 166
> Add a standing kick attack to the existing player controller. Use the current `res://scenes/characters/player.gd` and `res://scenes/characters/character.gd` setup so that pressing `attack` while the player is walking triggers a dedicated `kick` state instead of the normal grounded `punch`, and start…

### Fighter Player Jab
Tâches : 167
> Add a jab attack that replaces the grounded punch only when the player is not moving (in the idle state). Use the current `res://scenes/characters/player.gd` and `res://scenes/characters/character.gd` setup so that pressing `attack` while the player is idle triggers a dedicated `jab` state instead o…

### Fighter Enemy Death
Tâches : 168
> Add a death state and death animation for the basic enemy. Update `res://scenes/characters/character.gd` so that when a character receives lethal damage it does not disappear immediately. Instead, lethal damage should switch the character into a dedicated `dead` state, stop its movement, and keep it…

### Fighter Player Big Strike
Tâches : 170
> Add a spin strike attack that can be triggered during the landing phase of a jump. Update `res://scenes/characters/character.gd` and `res://scenes/characters/player.gd` so the player has a dedicated `strike` state and animation mapping, and pressing `attack` while the player is still in the existing…

### Fighter Player Punch
Tâches : 171
> Add the player's grounded punch attack. Update Character script so pressing `attack` while the player is grounded triggers the existing attack state instead of doing nothing. The punch should work from the normal grounded movement states, including while standing still and while walking. Then update…

### Basic Enemies Boss
Tâches : 184
> Expand the brawler combat setup with the first enemy encounter. Update `res://scenes/characters/character.gd` and `res://scenes/characters/character.tscn` so characters can receive damage through a `DamageReceiver`, play a `hurt` reaction with directional knockback when hit, and be removed after tak…

### Tilemap Navigation Chase
Tâches : 249
> Restore the enemy chase setup in `res://main.tscn` so the existing `Enemy` `CharacterBody2D` is configured for obstacle-aware chasing toward the existing `Target` `Area2D`. Recreate `res://Enemy.gd`, attach it back to `Enemy`, export a `target: Node2D`, assign it to `../Target`, steer with `Navigati…

### task_0263
Tâches : 263
> Implement the hero-versus-goblin aggro targeting setup from the tutorial. In `res://data/units/unit_stats.gd`, define `TARGET = { Team.PLAYER: "goblins", Team.ENEMY: "heroes" }` so units can look up the opposing group name from their team. Create `res://custom_nodes/detect_range.gd` as `class_name D…

### task_0264
Tâches : 264
> Implement the guard patrol intruder tracking setup from the tutorial. In `res://data/units/unit_stats.gd`, define `TARGET = { Team.PLAYER: "intruders", Team.ENEMY: "guards" }` so units can look up the opposing group name from their team. Create `res://custom_nodes/detect_range.gd` as `class_name Det…

### task_0265
Tâches : 265
> Implement the arena bot sensor targeting setup from the tutorial. In `res://data/units/unit_stats.gd`, define `TARGET = { Team.PLAYER: "red_bots", Team.ENEMY: "blue_bots" }` so units can look up the opposing group name from their team. Create `res://custom_nodes/detect_range.gd` as `class_name Detec…

### task_0266
Tâches : 266
> Implement the predator prey awareness targeting setup from the tutorial. In `res://data/units/unit_stats.gd`, define `TARGET = { Team.PLAYER: "prey", Team.ENEMY: "predators" }` so units can look up the opposing group name from their team. Create `res://custom_nodes/detect_range.gd` as `class_name De…

### task_0268
Tâches : 268
> Implement the squad skirmish engagement targeting setup from the tutorial. In `res://data/units/unit_stats.gd`, define `TARGET = { Team.PLAYER: "hostiles", Team.ENEMY: "allies" }` so units can look up the opposing group name from their team. Create `res://custom_nodes/detect_range.gd` as `class_name…

### task_0269
Tâches : 269
> Implement the security drone contact tracking setup from the tutorial. In `res://data/units/unit_stats.gd`, define `TARGET = { Team.PLAYER: "intruders", Team.ENEMY: "security_drones" }` so units can look up the opposing group name from their team. Create `res://custom_nodes/detect_range.gd` as `clas…

### task_0270
Tâches : 270
> Implement the fleet radar target acquisition setup from the tutorial. In `res://data/units/unit_stats.gd`, define `TARGET = { Team.PLAYER: "fleet_b", Team.ENEMY: "fleet_a" }` so units can look up the opposing group name from their team. Create `res://custom_nodes/detect_range.gd` as `class_name Dete…

### task_0271
Tâches : 271
> Implement the mage duel spell targeting setup from the tutorial. In `res://data/units/unit_stats.gd`, define `TARGET = { Team.PLAYER: "warlocks", Team.ENEMY: "wizards" }` so units can look up the opposing group name from their team. Create `res://custom_nodes/detect_range.gd` as `class_name DetectRa…

### task_0272
Tâches : 272
> Implement the factory mech threat scanning setup from the tutorial. In `res://data/units/unit_stats.gd`, define `TARGET = { Team.PLAYER: "saboteurs", Team.ENEMY: "workers" }` so units can look up the opposing group name from their team. Create `res://custom_nodes/detect_range.gd` as `class_name Dete…

### task_0273
Tâches : 273
> Implement the dungeon sentry alert targeting setup from the tutorial. In `res://data/units/unit_stats.gd`, define `TARGET = { Team.PLAYER: "raiders", Team.ENEMY: "sentries" }` so units can look up the opposing group name from their team. Create `res://custom_nodes/detect_range.gd` as `class_name Det…

### task_0279
Tâches : 279
> Implement the hero threat forwarding setup from the tutorial. In `res://data/units/unit_stats.gd`, define `TARGET = { Team.PLAYER: "monsters", Team.ENEMY: "heroes" }` so units can look up the opposing group name from their team. Create `res://custom_nodes/detect_range.gd` as `class_name DetectRange`…

### task_0280
Tâches : 280
> Implement the drone contact forwarding setup from the tutorial. In `res://data/units/unit_stats.gd`, define `TARGET = { Team.PLAYER: "intruders", Team.ENEMY: "security_drones" }` so units can look up the opposing group name from their team. Create `res://custom_nodes/detect_range.gd` as `class_name …

### card_dragging_state_machine
Tâches : 284
> Finish the card dragging mechanic from the tutorial. The provided `res://scenes/main.tscn` harness keeps three `CardUI` instances under `BattleUI/Hand`, and each card should continue using the existing `CardStateMachine`, `CardBaseState`, `CardClickedState`, and `CardDraggingState` nodes from `res:/…
