# Mechanics

### Contents 

1. CUBert mechanics
   - Jumping and gravity
   - Interacting with objects
   - Death and Respawning

2. Object mechanics
   - Collectables
   - Moving platforms
   - Ambient audio

3. Level mechanics
   - Setting up a level
   - Screen transitions
   - Saving data in levels

## Cubert Mechanics

### Movement

CUBert is represented by `Player.tscn`. 
He has 2 scripts: `Player.gd`, where most of the crucial code is kept (stuff that would break level transitions etc if changed), 
and `DefaultPlayer.gd` (which extends `Player.gd`), where all of the platformer movement and logic is kept. 
Feel free to write your own replacement scripts for `DefaultPlayer.gd`.

Platformers have to cheat to be fun. `DefaultPlayer.gd` has both `coyote_time` (the amount of time it is still possible to jump after walking off a ledge) and 
`jump_queue_time` (the time before landing where you can queue up a jump to be executed as soon as you land).

Gravity is applied by the `GravityController` node that is attached to him (it is also attached to the enemies).
This allows us to have all entities in game have the same gravity.

Cubert's maximum jump height is just higher than 2 blocks, but varies depending on how long the jump button is held for.
When the jump button is held, gravity is halved during the ascending part of the jump.

### Interacting with objects

`InteractArea` defines the area around `Player.tscn` where objects that contain an `Interactble` child can be interacted with. 
`Player` stores a single 'focussed' object at once, which is the object that will be interacted with when the interact button is pressed.
The 'focussed' object is the closest valid object inside of `InteractArea`.

`Interactable` emits signals when it starts and stops being focussed. 
These signals should be received by the parent object to display/hide outlines and text to indicate the interactability.
When the interact button is pressed, the focused `Interactable` emits the `interacted` signal.
When setting up a new interactable object, give it an `Interactable` child, 
and remember to connect the signals from the `Interactable` to functions inside the parent object.

### Death and respawing

`Player.tscn` has a `Hurtbox` child, which detects collisions with Bodies and Area2Ds that are on the `Hazards` collision layer. 
When the `Hurtbox` overlaps one of these objects, the player is killed. 
When the Player emits the `death_end` signal, the Level teleports them to the `current_respawn_point` and calls `respawn()` in the Player, 
which plays the waking up animation.

Checkpoints exist in the form of `CheckpointArea.tscn`. 
These are all in the group `checkpoint_areas`, which allows the Level to find them.
When the Player is within a `CheckpointArea`, the safe position underneath the Player is saved inside level to `current_respawn_point`.
`current_respawn_point` is also automatically set to the safe position under the Player when entering a level.


