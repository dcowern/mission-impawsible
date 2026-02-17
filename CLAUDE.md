# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Mission Impawsible is a first-person adventure game built with **Godot 4.x** (currently 4.6) and **GDScript**. The player controls a cat with magical abilities in a 16km × 16km open world. The full PRD is in `MISSION-IMPAWSIBLE-PRD.md` — read the relevant phase section before implementing any feature.

## Build & Run Commands

```bash
# Open in Godot editor
godot --path .

# Validate GDScript syntax
godot --check-only --script res://path/to/script.gd

# Import resources (required before first test run or after adding new assets)
godot --headless --import --quit

# Run all tests (GUT)
godot --headless --path . -s res://addons/gut/gut_cmdln.gd \
  -gdir=res://tests -ginclude_subdirs -gexit

# Run a single test file
godot --headless --path . -s res://addons/gut/gut_cmdln.gd \
  -gtest=res://tests/unit/test_game_state.gd -gexit

# Run tests matching a pattern
godot --headless --path . -s res://addons/gut/gut_cmdln.gd \
  -gdir=res://tests -ginclude_subdirs -gprefix=test_ -gexit
```

## Architecture

### Framework: COGITO v1.1.5+
The game is built on top of the COGITO first-person immersive sim framework. **Always extend or customize COGITO's existing systems rather than replacing them.** COGITO provides: player controller, component-based interactions, inventory, save/load with scene persistency, menus, and attribute system.

### Plugin Stack
- **Terrain3D** — GPU-driven procedural terrain (C++ GDExtension)
- **Sky3D** — Day/night cycle and atmosphere
- **Foliage3D** — Terrain-based vegetation
- **Spatial Gardener** — Manual vegetation painting
- **Dialogue Manager 3** — Branching dialogue
- **BehaviourToolkit** — NPC AI (FSM + behavior trees)
- **GUT** — Testing framework
- **Boujie Water Shader** — Ocean/water rendering

### Autoload Singletons
- **SignalBus** (`autoloads/signal_bus.gd`) — Global event bus for cross-system communication
- **GameState** (`autoloads/game_state.gd`) — Tuna coins, ability levels, quest flags
- **DebugLog** (`autoloads/debug_logger.gd`) — Debug logging utility

### Key Directories
- `addons/` — All plugins (COGITO, Terrain3D, GUT, etc.)
- `autoloads/` — Global singletons (signal_bus, game_state, debug_logger)
- `scenes/player/abilities/` — Five magic ability scripts
- `scenes/npcs/` — NPC base classes and instances
- `dialogue/` — Dialogue Manager script files
- `resources/` — Item, ability, and quest resource definitions
- `tests/unit/` and `tests/integration/` — GUT test files

## Mandatory Development Standards

### Debug Output
Every gameplay function MUST include `print("[DEBUG] ...")` output. Log function name, variable values, outcomes, state transitions, and failures. Use `DebugLog.log("Context", "message")` for convenience.

### Testing Workflow
Every feature must follow this loop:
1. Implement the feature
2. Run syntax check: `godot --check-only --script <file>`
3. Write tests in `tests/`
4. Run tests headless and verify `[DEBUG]` output and pass/fail
5. If tests fail: read output, identify root cause, fix — do NOT guess at fixes

### Asset Licensing
- All assets must be open-source or Creative Commons (CC0, CC-BY 4.0, MIT, Apache 2.0)
- **No** CC-BY-NC, CC-BY-SA, or CC-BY-ND
- Every imported asset must be recorded in `ATTRIBUTION.md` immediately — not later
- Preserve LICENSE files in `addons/<plugin>/`

### Placeholders
- Prefix with `PH_` and use ugly colors: magenta (#FF00FF) for characters, cyan (#00FFFF) for props, yellow (#FFFF00) for VFX
- Every placeholder gets an entry in `TO_RESOLVE.md`

## GDScript Style
- Static typing everywhere: `var speed: float = 6.0`
- `@onready` for node refs, `@export` for inspector-tunable values
- Prefix private members with `_`
- Signal names are past tense: `signal coin_collected`
- Class names PascalCase, file names snake_case
- Add `class_name` if the script will be referenced elsewhere

## Lore (Canonical — Do Not Modify)
The player is a cat with "gem blood." Five magic disciplines: Fire, Ice, Woodland, Dragon Taming, Creature Speak. Currency: Tuna Coins (start with 2, spent to level up powers). Main quest: find the lost gem. See PRD Section 2 for the exact canonical text that must be used verbatim in-game.
