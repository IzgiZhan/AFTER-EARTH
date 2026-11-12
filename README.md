# AFTER EARTH

**Rebuild Humanity. Create a New Civilization.**

AFTER EARTH is a 2D top-down post-apocalyptic survival, strategy and civilization-building game. The player wakes up alone in a damaged bunker after a nuclear war, restores it step by step, meets other survivors and gradually hands the work over: first to people, then to machines.

Core idea: **Automate it.** You start by doing everything with your own hands, then survivors with professions work for the settlement, and finally robots and production lines do the work for you.

## Current status: playable prototype

Implemented so far:

- Main menu with settings (language: English / Russian, volume, fullscreen)
- Story intro: six illustrated scenes about the war and the bunker
- Three-level bunker: living quarters, supply floor and mine
- Step-by-step tutorial with a guiding arrow
- Five story notes with illustrations (bunker map, tools and weapons, mutants, resources, reactor)
- Tools that unlock the bunker: crowbar, storage key, pickaxe, elevator fuse, lift lever
- Generator that restores power when fuelled with coal
- Survival stats: Health, Energy, Hunger, Thirst, Radiation
- Outside world: resources, ruins, radiation zone, day and night, mutants, knife combat
- Automatic saving and the Continue button
- Sound effects generated in code and menu music

Planned next: hotbar with one item in hand, survivors with professions who can be let into the bunker, a task board, production chains, robots, cities, diplomacy and the six-chapter story campaign. The full design is in `docs/GAME_DESIGN_DOCUMENT.md`.

## Controls

| Key | Action |
|---|---|
| W A S D or arrows | Move |
| E | Interact, read, pick up |
| Space | Attack with the knife |
| F / R | Eat / drink |
| I | Backpack |
| Esc | Save and return to the menu |

## How to run

1. Install Godot 4.7 (standard version) from https://godotengine.org
2. Download this repository (Code → Download ZIP) and unpack it
3. In Godot press Import and select `game/project.godot`
4. Press the Play button

## Project structure

- `game/` : the Godot project (all scripts and scenes)
- `docs/` : game design document
- `README.md` : this file

## Technology

- Engine: Godot 4.7, language: GDScript
- All graphics are drawn by code, no external image files
- Renderer: Compatibility (suitable for web export)

## Credits

- Game concept and development: IzgiZhan
- Music: "Day of Chaos" by Kevin MacLeod (incompetech.com), licensed under Creative Commons Attribution
