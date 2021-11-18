# Mario Game (Group Project)

## Description

Implements the classic Super Mario video game using Assembly code, playable via an SNES controller.
In this game, Mario travels through a map in order to reach the palace to save Princess Peach. 
On his way Mario will be faced by several monsters and obstacles. 
The game ends when Mario reaches the castle (win) or all lives are lost (lose).

The game environment is a finite 2D grid and as Mario moves to the right or left. 
New scenes will load to the game as Mario moves forward scene by scene (ie: as Mario reaches the right or left edge of the screen a new scene will load).

## Features:
- Main menu with game selection (start, load, quit, restart) and pop-up menu during gameplay
- Auto-saved game state
- Interaction between Mario and monsters (ability to jump on them and make them disappear), obstacles (ability to jump on blocks and hit coin blocks for rewards), and randomly generated value packs (of lives or coins)
- Real time tracking of lives and score
- Full interaction with an SNES controller by the user (D-Pad, A, and Start buttons)

## Usage:
Must be run through a specific environment with a Raspberry Pi using a JTAG and ARM processor connected to an SNES controller
