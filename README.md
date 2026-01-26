# CUBert's Adventure

Every good game dev needs level design practice. 
That's why we're launching CUBert's Adventure: a platformer in a world of connected, self-contained levels made by individual CUDevs members. 
And we want YOU to contribute!

![CUBert_jumping](/.gdignore/readme_images/house.gif) 

We have already made the basic platformer controls in Godot, which can be found here on GitHub: …..........

If you have never used Godot before, now is a great time to learn it! 
Its node-based structure means that everyone can save their level as a single file. 
This flexibility makes it easy to add unique mechanics to your levels and mod our original architecture. 
We're expecting to see Bad Apple, Flappy bird, DOOM 1993 etc...
Or, you can avoid coding altogether and play with Godot's 2D graphics and physics systems to make the best-looking and fun levels (why not do both?).


## The Base Game
 
CUBert's Adventure is an exploration-based 2D platformer. 
There is one goal: collect the Keycap hidden in every level, exploring the creations of our CUDevs members along the way.

![World Map illustration](/.gdignore/readme_images/world_map_demo.png)
 
The world of CUBert's Adventure is split into 16x16 tile levels (and larger multiples). 
When leaving the bounds of a level, CUBert will transition to the neighbouring level in the World Map.
 
### Controls:
- Arrow keys: move
- Z: jump
- X: interact, (hold) view HUD
- Anything else you want to add
 
Currently CUBert has basic jumping physics, hazards, respawn checkpoints, an interaction system, and Keycap collectables. 
These are just to get you started. We want you to add more mechanics in your levels (Trampolines? Melee attacks? A wave dash???). 
These extra mechanics will not be transferred between levels (so if you have a cool one, make multiple levels!).
 
We will collect everyone's levels and upload the full game to itch.io at the end of term.


## Getting started
 
Download the game RIGHT NOW and play around!
 
The 5 demo areas are all placeholders that will not feature in the World Map. 
We want them to demonstrate the mechanics included in the base game that you can use (if you want):
 
- **Hub**: Representative of the starting level at the centre of the final World Map
- **North**: A challenging platforming gauntlet, demonstration of large rooms and the checkpoint system.
- **East**: Basic enemy showcase
- **South**: Godot's 2D lighting and particle effects
- **West**: The interact system and data saving. When this level is exited and re-entered, the game remembers whether the door and elevator have been opened/activated.

 
## Making a Level
 
When you want to create a level, you should reserve its position in the World Map by marking the square(s) on the [Google Sheets Document](https://docs.google.com/spreadsheets/d/1k-DdyBB9TbI8zVZoEIk8JGXsJKSu8uHuFYBxlndbqgU/edit?usp=sharing).
 
Levels should join on from existing levels, and should have entrances/exits in all 4 directions (except for those on edge of the World Map boundary). 
We ask that you reserve only 1 level at a time, and finish it before starting a new one.
 
### What can/can't I change?
 
Each level is an independent scene that will be set as the Main Scene when it is active. 
This is what you should submit to us as your finished level. 
Everything inside the level can be changed however you see fit (art style, mechanics, genre, etc).
 
We ask that every level contains a collectable Keycap to be collected. 
Entrances/exits to the level should include the central 2 tiles of eah 16-tile room boundary.
 
Each level inherits from the script `room_template.gd`, which communicates with autoloaded `RoomManager.tscn` to perform level transitions. 
Feel free to extend this script, but be careful with the level transition logic as you may break your level. 
Each level should also have a Player scene as a child (even if that scene is then immediately deleted), otherwise the transition logic will also break.
Please do not do something like call `RoomManager.queue_free()` in a script in your level as it will break the whole game.
 
Otherwise, go wild.
 
### How do I submit my level?
 
Your level scene, along with any other new scenes, assets, scripts, etc that you used (that aren't already in the Base Game's files) should be put into a folder and sent to the CUDevs committee as a `.zip` file. 
Alternatively, the Base Game can be forked on GitHub if you'd prefer.
 
### Help! I have more questions!!
 
Just ask us on discord or come to our weekly sessions!
 
## Acknowledgements

- *Base game made by Riftwraith & FCP.*
- *Base tileset modified from the [Brackey's platformer pack](https://brackeysgames.itch.io/brackeys-platformer-bundle).*
- *Sounds from OpenGameArt and Freesound.*
