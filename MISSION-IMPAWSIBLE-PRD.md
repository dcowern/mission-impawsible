# Mission Impawsible — Product Requirements Document
## Agent-Optimized Implementation Plan for Claude Code

**Version:** 1.0
**Engine:** Godot 4.x (latest stable, currently 4.6)
**Language:** GDScript (primary), with C# only if specific plugin requires it
**Target Platforms:** PC (Windows/Linux/macOS), Mobile (iOS/Android)
**Perspective:** First-Person

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Lore](#2-lore)
3. [Gameplay Specification](#3-gameplay-specification)
4. [Technical Architecture](#4-technical-architecture)
5. [Plugin Stack](#5-plugin-stack)
6. [Open World Specification](#6-open-world-specification)
7. [Asset Reference Catalog](#7-asset-reference-catalog)
8. [Project Structure](#8-project-structure)
9. [Development Standards](#9-development-standards)
10. [Phase 0 — Environment Setup](#phase-0--environment-setup)
11. [Phase 1 — Core Player Controller](#phase-1--core-player-controller)
12. [Phase 2 — World Foundation](#phase-2--world-foundation)
13. [Phase 3 — Game Systems](#phase-3--game-systems)
14. [Phase 4 — Magic & Abilities](#phase-4--magic--abilities)
15. [Phase 5 — NPCs & AI](#phase-5--npcs--ai)
16. [Phase 6 — Quests & Narrative](#phase-6--quests--narrative)
17. [Phase 7 — Mobile & Cross-Platform](#phase-7--mobile--cross-platform)
18. [Phase 8 — Polish & Integration](#phase-8--polish--integration)
19. [Appendix A — Debug Output Standard](#appendix-a--debug-output-standard)
20. [Appendix B — Headless Testing Standard](#appendix-b--headless-testing-standard)
21. [Appendix C — Agent Workflow Reference](#appendix-c--agent-workflow-reference)

---

## 1. Project Overview

Mission Impawsible is a cross-platform Godot adventure game where the player controls a cat with magical gem abilities. The game targets PC and mobile platforms using Godot.

The game is a first-person adventure played from the perspective of a cat navigating a world where magic has been lost. The player explores a massive 16km × 16km open world featuring diverse biomes — from snow-capped alpine peaks and dense forests to sun-baked savannas, river valleys, and ocean coastlines. The player interacts with NPCs and objects, completes quests, and progressively unlocks elemental magic abilities tied to an ancient gem.

The core gameplay loop is: **Explore → Interact → Discover → Power Up → Progress**.

---

## 2. Lore

> **IMPORTANT — This lore text is canonical. Do not modify, paraphrase, or rewrite it. Copy it verbatim into any in-game text, dialogue references, or narrative assets that reference the backstory.**

There used to be cats that had magic abilities: fire, ice, woodland, dragon taming, and speaking with different creatures. Suddenly the Earth began to shake. The Earth stopped spinning and then the cats that had magic had no more magic because the gem that the cats harnessed the magic from had disappeared. Since then no one has had magic - until now. You have the gem blood running through your veins. You have been chosen to find the gem.

You got two tuna coins. You can young use the tuna coins to level up your powers.

### Lore-Derived Design Requirements

From the canonical lore, the following game systems are implied:

- **Five magic disciplines:** Fire, Ice, Woodland, Dragon Taming, Speaking with Creatures
- **Central quest:** Find the lost gem
- **Currency system:** Tuna Coins (player starts with 2)
- **Progression system:** Tuna Coins are spent to level up magic powers
- **World state:** Magic is gone from the world; the player is the exception
- **Player identity:** A cat with "gem blood" — a hereditary magical lineage

---

## 3. Gameplay Specification

### Controls

| Platform | Movement | Look | Jump | Interact | Ability | Menu |
|----------|----------|------|------|----------|---------|------|
| PC (KB+M) | WASD | Mouse | Space | E | LMB / 1-5 keys | Esc / Tab |
| PC (Gamepad) | Left Stick | Right Stick | A/Cross | X/Square | RT/R2 | Start |
| Mobile | Virtual Joystick (left) | Touch Drag (right) | Jump Button | Tap on object | Ability Buttons | Menu Button |

### Camera

- First-person camera attached to cat's head height
- Slight head-bob during movement (configurable, can be disabled in settings)
- Optional: subtle snout/whisker geometry visible at bottom edge of viewport (cosmetic, low priority)
- Mouse sensitivity and invert-Y as player settings
- FOV: default 75, adjustable 60–100

### Player Character

- The player IS a cat — movement speed, jump height, and camera height should reflect a cat's proportions relative to the world
- Base move speed: brisk trot (~6 units/sec, tunable)
- Sprint: ~10 units/sec (costs stamina if stamina system is active)
- Jump height: ~1.5x character height (cats jump high)
- Crouch: reduces camera height, enables stealth (ties into COGITO visibility attribute)
- Fall damage: reduced (cats land on feet — smaller fall damage multiplier than human default)

### Core Interactions

- Raycast-based "look at to interact" system (COGITO default)
- Interaction prompt appears when looking at interactable objects
- Object types: doors, containers, pickups (tuna coins, quest items, consumables), NPCs (talk), readable notes/scrolls, carryable objects
- Inventory system for collected items

---

## 4. Technical Architecture

### Engine & Framework

This project uses **COGITO** (v1.1.5+, MIT license) as the foundational framework. COGITO is a first-person immersive sim template for Godot 4 that provides:

- First-person player controller (sprint, jump, crouch, slide, stairs, ladders)
- Component-based interaction system
- Inventory system (UI + logic, separated)
- Save/load with scene persistency
- Main menu, pause menu, options
- Attribute system (health, stamina, custom attributes)
- Dynamic footstep sounds
- Gamepad support
- Localization support

**COGITO is the spine of the project.** All player-facing systems (controller, inventory, interactions, menus, save/load) should extend or customize COGITO's existing systems rather than replacing them, unless there is a specific technical reason to deviate.

### Scene Architecture

```
Main
├── WorldEnvironment
├── Sky3D (day/night cycle)
├── Terrain3D (procedural terrain)
├── WaterSystems
│   ├── OceanPlane (Boujie Water Shader at Y=0)
│   ├── Rivers (mesh strips with flow shader)
│   └── Lakes (flat water planes in terrain depressions)
├── PlayerScene (COGITO player)
│   ├── CharacterBody3D
│   │   ├── CollisionShape3D
│   │   ├── Camera3D
│   │   │   ├── RayCast3D (interaction)
│   │   │   └── ViewmodelContainer (paw model, ability VFX)
│   │   └── AudioStreamPlayer3D (footsteps)
│   ├── PlayerHUD (COGITO HUD + custom elements)
│   └── InventoryUI
├── NPCManager
│   └── [NPC instances with BehaviourToolkit trees]
├── QuestManager
└── AbilitySystem
    ├── FireAbility
    ├── IceAbility
    ├── WoodlandAbility
    ├── DragonTamingAbility
    └── CreatureSpeakAbility
```

### Signal Architecture

Use Godot signals for loose coupling between systems. Key signal buses:

```gdscript
# Global signal bus — autoload singleton: res://autoloads/signal_bus.gd
signal ability_unlocked(ability_name: String, level: int)
signal ability_used(ability_name: String, target: Node)
signal tuna_coins_changed(old_amount: int, new_amount: int)
signal quest_started(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_objective_updated(quest_id: String, objective_id: String)
signal player_entered_area(area_name: String)
signal npc_interaction_started(npc_id: String)
signal npc_interaction_ended(npc_id: String)
signal day_night_changed(is_day: bool)
signal magic_discipline_discovered(discipline: String)
```

---

## 5. Plugin Stack

Install these addons into `res://addons/`. All are MIT-licensed.

| System | Plugin | Source | Purpose |
|--------|--------|--------|---------|
| **Player Framework** | COGITO v1.1.5+ | [Godot Asset Library #2536](https://godotengine.org/asset-library/asset/2536) | Player controller, inventory, interactions, save/load, menus |
| **Terrain** | Terrain3D v1.0+ | [Godot Asset Library #3134](https://godotengine.org/asset-library/asset/3134) | GPU-driven procedural terrain with sculpting and foliage instancing |
| **Day/Night Sky** | Sky3D | [GitHub: TokisanGames/Sky3D](https://github.com/TokisanGames/Sky3D) | Dynamic day/night cycle, atmosphere, sun/moon |
| **Foliage (terrain)** | Foliage3D | [GitHub: caphindsight/Foliage3D](https://github.com/caphindsight/Foliage3D) | Auto-places vegetation based on Terrain3D texture types |
| **Foliage (non-terrain)** | Spatial Gardener | [Godot Asset Library #2037](https://godotengine.org/asset-library/asset/2037) | Paint plants/props on arbitrary 3D surfaces |
| **Dialogue** | Dialogue Manager 3 | [Godot Asset Library #3654](https://godotengine.org/asset-library/asset/3654) | Branching dialogue with script-like syntax, localization |
| **NPC AI** | BehaviourToolkit | [Godot Asset Library #2333](https://godotengine.org/asset-library/asset/2333) | Finite state machines + behavior trees for NPCs |
| **Testing** | GUT | [GitHub: bitwes/Gut](https://github.com/bitwes/Gut) | Unit/integration testing, CLI headless runner, JUnit XML output |
| **Water (Ocean)** | Boujie Water Shader | [GitHub: Chrisknyfe/boujie_water_shader](https://github.com/Chrisknyfe/boujie_water_shader) | Gerstner wave ocean, shore foam, refraction, infinite mesh LOD |

### Plugin Installation Order

1. COGITO first (it's the project foundation — follow its setup guide)
2. Terrain3D (C++ GDExtension — download the compiled binary for your platform)
3. Sky3D (pure GDScript — drop into addons)
4. GUT (testing — needed immediately for TDD workflow)
5. Boujie Water Shader (needed for Phase 2 ocean/water)
6. Dialogue Manager 3, BehaviourToolkit, Spatial Gardener, Foliage3D (as needed per phase)

---

## 6. Open World Specification

### 6.1 World Scale

The world is **enormous** — a true open world. The player should feel dwarfed by the landscape with vast horizons in every direction.

| Parameter | Value | Notes |
|-----------|-------|-------|
| **Total world size** | 16,384m × 16,384m (~16km × 16km) | Terrain3D supports up to 65.5km; 16km is a strong open-world baseline |
| **Terrain3D region size** | 1024m × 1024m | 16×16 grid of regions = 256 regions total |
| **Active LOD range** | GPU clipmap handles this automatically | Terrain3D's C++ clipmap manages LOD per-frame |
| **Max elevation** | ~2,000m above sea level | For soaring mountain peaks |
| **Sea level** | 0m (water plane sits here) | Ocean, rivers, and lakes reference this |
| **Deepest valley floor** | ~-50m below surrounding terrain | Canyons, riverbeds |

### 6.2 Biome Map

The world is divided into biome regions. Each biome uses a distinct set of terrain textures, vegetation, ambient audio, and lighting mood. Biomes blend at their borders using Terrain3D's texture painting with smooth transitions.

```
                    NORTH
        ┌───────────────────────────┐
        │     ALPINE PEAKS          │
        │   (snow, ice, bare rock)  │
        │         ▲▲▲▲▲             │
        ├─────────┼─────────────────┤
        │ FOOTHILLS│  HIGHLAND       │
        │(pine,   │  MEADOW         │
        │ rocky)  │  (wildflowers)  │
  WEST  ├─────────┼─────────────────┤ EAST
        │DECIDUOUS│  CENTRAL        │
        │ FOREST  │  PLAINS         │
        │(dense   │  (grassland,    │
        │ canopy) │   rolling hills)│
        ├─────────┼─────────────────┤
        │ RIVER   │  SAVANNA /      │
        │ VALLEY  │  ARID SCRUB     │
        │(lush,   │  (dry grass,    │
        │ wet)    │   sparse trees) │
        ├─────────┴─────────────────┤
        │     COASTAL / BEACH       │
        │   (sand, dunes, cliffs)   │
        ├───────────────────────────┤
        │        OCEAN              │
        │   (open water, islands)   │
        └───────────────────────────┘
                    SOUTH
```

### 6.3 Biome Definitions

Each biome specifies its Terrain3D texture layers, vegetation, props, and environmental mood. The coding agent should use these definitions when building and populating each region.

#### Alpine Peaks (North, elevation 1200–2000m)
- **Terrain textures:** Snow, bare rock, rocky cliff faces, ice patches
- **Vegetation:** None above treeline; sparse alpine scrub near edges
- **Props:** Ice formations, cave entrances, wind-scoured stone arches
- **Weather:** Persistent wind particles, occasional snowfall
- **Ambient audio:** Howling wind, distant avalanche rumbles
- **Gameplay:** Dragon Taming abilities relevant here; endgame area

#### Foothills (North-West, elevation 600–1200m)
- **Terrain textures:** Rocky grass, pine needle ground cover, exposed stone, dirt paths
- **Vegetation:** Conifer trees (pine, spruce), boulders, mountain wildflowers
- **Props:** Mining ruins, cliff-side caves, stone cairns
- **Ambient audio:** Mountain streams, hawk cries, wind through pines

#### Highland Meadow (North-East, elevation 400–800m)
- **Terrain textures:** Lush grass, wildflower grass, meadow dirt
- **Vegetation:** Scattered deciduous trees, tall grass, wildflower clusters
- **Props:** Standing stones, ancient shrine (ability upgrade point), shepherd huts
- **Ambient audio:** Birdsong, buzzing insects, gentle breeze

#### Deciduous Forest (West, elevation 100–500m)
- **Terrain textures:** Forest floor (leaves/mulch), mossy ground, dirt path, tree roots
- **Vegetation:** Dense canopy trees (oak, birch), undergrowth, ferns, mushrooms
- **Props:** Fallen logs, hollow trees, old ruins overgrown with vines, fairy rings
- **Ambient audio:** Dense birdsong, rustling canopy, creaking wood
- **Gameplay:** Woodland magic discipline strongest here

#### Central Plains (Center, elevation 50–200m)
- **Terrain textures:** Grassland, dry grass, dirt road, wildflowers
- **Vegetation:** Open grass fields, occasional solitary trees, bushes
- **Props:** Farmstead ruins, wells, stone walls, signposts, the **Starting Village**
- **Ambient audio:** Wind in grass, distant wildlife, pastoral
- **Gameplay:** Player starts here; tutorial area

#### River Valley (South-West, elevation 0–150m)
- **Terrain textures:** Mud, river silt, wet grass, mossy rock
- **Vegetation:** Willows, reeds, lily pads, riverside shrubs
- **Water features:** Major river flowing south to the ocean; tributaries; a waterfall from the foothills
- **Props:** Bridges, fishing spots, riverside camps, beaver dams
- **Ambient audio:** Running water, frogs, dripping
- **Gameplay:** Creature Speech abilities unlock dialogue with river creatures

#### Savanna / Arid Scrub (South-East, elevation 50–200m)
- **Terrain textures:** Dry grass, cracked earth, sandy dirt, sun-baked rock
- **Vegetation:** Sparse dry bushes, acacia-like trees, cacti, tumbleweed
- **Props:** Bleached bones, abandoned caravans, desert shrine
- **Ambient audio:** Hot wind, cicadas, silence punctuated by wildlife

#### Coastal / Beach (South edge, elevation 0–50m)
- **Terrain textures:** Sand, wet sand, beach pebbles, coastal grass, sandstone cliffs
- **Vegetation:** Beach grass, palm trees, driftwood
- **Water features:** Surf zone, tide pools, sea stacks
- **Props:** Shipwrecks, lighthouses, sea caves, fishing docks
- **Ambient audio:** Crashing waves, seagulls, ocean wind

#### Ocean (South, beyond the coast)
- **Water:** Infinite ocean plane using Boujie Water Shader or equivalent Gerstner wave shader
- **Features:** Small islands reachable by ice-bridge (Ice ability), coral reefs visible through clear water
- **Ambient audio:** Deep ocean waves, whale calls in the distance
- **Gameplay:** The Gem may be hidden on a remote ocean island (endgame)

### 6.4 Water Systems

| Water Type | Implementation | Notes |
|---|---|---|
| **Ocean** | Infinite water plane mesh with Gerstner wave shader, placed at Y=0 | Use Boujie Water Shader (MIT) or custom shader. LOD mesh for far distance. |
| **Rivers** | Mesh strips following Bezier curves with flow shader | Use Waterways plugin concepts or hand-placed mesh strips with UV-scrolling flow |
| **Lakes** | Flat water plane meshes placed in terrain depressions | Simpler shader than ocean (calmer), depth-fog for shoreline fade |
| **Waterfalls** | Particle system + mesh with scrolling texture | Place at elevation transitions between foothills and river valley |

### 6.5 Terrain Generation Strategy

The agent should build the world incrementally:

1. **Start with heightmap generation** — use Terrain3D's sculpting API or import a heightmap PNG. The heightmap encodes the biome layout: high values for peaks, low for valleys, flat for plains.
2. **Paint terrain textures per biome** — Terrain3D supports up to 32 texture layers. Each biome region gets its appropriate textures painted onto the terrain.
3. **Place water** — Ocean plane at Y=0, river meshes following valley paths, lakes in depressions.
4. **Populate vegetation** — Use Terrain3D's built-in instancer for grass/groundcover tied to texture types. Use Spatial Gardener or manual placement for trees and large plants.
5. **Scatter props** — Place rocks, ruins, structures. Use MultiMeshInstance3D for repeated small objects (rocks, flowers).
6. **Place gameplay objects** — Tuna coins, NPCs, quest triggers, ability shrines — one per biome.

For the initial implementation, the agent should build the Central Plains (starting area) to full quality first, then expand outward biome by biome.

---

## 7. Asset Reference Catalog

All assets used in this project MUST be open-source or Creative Commons licensed. This section is the authoritative reference for the coding agent when sourcing art, textures, models, and audio.

### 7.1 Licensing Rules

1. **Acceptable licenses:** CC0 (Public Domain), CC-BY 4.0 (attribution required), MIT, Apache 2.0, Unlicense, OGA-BY (OpenGameArt attribution)
2. **Not acceptable:** CC-BY-NC (no commercial), CC-BY-SA (share-alike complicates distribution), CC-BY-ND (no derivatives), any proprietary license
3. **Every imported asset MUST be recorded** in `res://ATTRIBUTION.md` at the moment it is added to the project — not later, not in a batch. Every single asset.
4. **CC0 assets** still get attribution in `ATTRIBUTION.md` as a courtesy and for project tracking, even though legally not required.
5. **CC-BY assets** MUST have attribution both in `ATTRIBUTION.md` and in the in-game credits screen.
6. **Never modify license files** that ship with asset packs. Copy them into the asset's subfolder.

### 7.2 ATTRIBUTION.md Format

The file `res://ATTRIBUTION.md` must follow this exact format for every imported asset:

```markdown
# Mission Impawsible — Asset Attribution

## Terrain Textures

### Grass001 (albedo, normal, roughness, AO)
- **Source:** ambientCG
- **URL:** https://ambientcg.com/view?id=Grass001
- **License:** CC0 1.0 Universal
- **Author:** Lennart Demes
- **Files:** assets/textures/terrain/grass/Grass001_*

### Rock030
- **Source:** Poly Haven
- **URL:** https://polyhaven.com/a/rock_030
- **License:** CC0 1.0 Universal
- **Author:** Poly Haven contributors
- **Files:** assets/textures/terrain/rock/Rock030_*

## 3D Models

### KayKit Forest Nature Pack
- **Source:** Kay Lousberg (itch.io)
- **URL:** https://kaylousberg.itch.io/kaykit-forest
- **License:** CC0 1.0 Universal
- **Author:** Kay Lousberg
- **Files:** assets/models/vegetation/forest/*
- **Notes:** Free tier, 100+ models. Do not resell unmodified.

## Godot Plugins

### COGITO v1.1.5
- **Source:** Philip Drobar (Godot Asset Library)
- **URL:** https://godotengine.org/asset-library/asset/2536
- **License:** MIT
- **Author:** Philip Drobar and contributors
- **Files:** addons/cogito/

[...continue for every asset...]
```

### 7.3 Texture Sources

These are the primary sources for PBR terrain and surface textures. All provide CC0-licensed materials with albedo, normal, roughness, and AO maps ready for Terrain3D.

#### ambientCG (PRIMARY — CC0)
- **URL:** https://ambientcg.com
- **License:** CC0 1.0 Universal (all assets)
- **Format:** PNG, JPG — multiple resolutions up to 8K. Download the 1K or 2K versions for game use.
- **Terrain textures to download:**

| Biome | Recommended Assets | Search Term |
|-------|-------------------|-------------|
| Grassland | Grass001, Grass004, Grass005 | `grass` |
| Forest Floor | Ground037, Ground054, Forrest003 | `forest ground` |
| Dirt / Path | Ground048, Ground022, SoilMud001 | `ground dirt` |
| Rock | Rock020, Rock030, Rock043 | `rock` |
| Cliff | CliffRock001, CliffRock006 | `cliff` |
| Sand | Ground060, Ground033 | `sand` |
| Snow | Snow004, Snow008 | `snow` |
| Mud | Mud002, SoilMud001 | `mud` |
| Gravel | Gravel022, Gravel035 | `gravel` |

#### Poly Haven (SECONDARY — CC0)
- **URL:** https://polyhaven.com/textures
- **License:** CC0 1.0 Universal (all assets)
- **Format:** PNG, EXR — up to 8K. Also provides HDRIs for sky/lighting reference.
- **Terrain category:** https://polyhaven.com/textures/terrain
- **Recommended for:** Rock formations, cliff faces, natural ground surfaces, HDRIs for environment lighting reference

#### CC0-Textures.com (SUPPLEMENTARY — CC0)
- **URL:** https://cc0-textures.com
- **License:** CC0 1.0 Universal
- **Recommended for:** Gap-filling when ambientCG/Poly Haven don't have the exact texture needed

### 7.4 3D Model Sources

#### KayKit by Kay Lousberg (PRIMARY — CC0)
- **URL:** https://kaylousberg.itch.io
- **License:** CC0 1.0 Universal (free tiers of all packs)
- **Format:** FBX, glTF, OBJ — compatible with Godot import pipeline
- **Style:** Low-poly, clean, colorful — good visual consistency across packs
- **Relevant packs (all free tiers):**

| Pack | URL | Contents | Use In |
|------|-----|----------|--------|
| **Forest Nature Pack** | https://kaylousberg.itch.io/kaykit-forest | 100+ trees, bushes, rocks, plants, mushrooms | Forest, foothills, meadow biomes |
| **Medieval Hexagon Pack** | https://kaylousberg.itch.io/kaykit-medieval-hexagon | 200+ buildings, tiles, terrain props | Villages, ruins, structures |
| **Dungeon Remastered** | https://kaylousberg.itch.io/kaykit-dungeon-remastered | Dungeon walls, floors, stairs, furniture | Caves, underground areas, ruins |
| **Adventurers Character Pack** | https://kaylousberg.itch.io/kaykit-adventurers | Rigged characters with animations | NPC base meshes (to be reskinned/adapted) |
| **Resource Bits** | https://kaylousberg.itch.io/resource-bits | 75+ resource items (crystals, ores, gems, wood) | Collectibles, tuna coin placeholder, crafting |
| **Platformer Pack** | https://kaylousberg.itch.io/kaykit-platformer | Platforms, coins, power-ups, environment | Coins, pickups, ability shrine elements |

#### Kenney (SECONDARY — CC0)
- **URL:** https://kenney.nl/assets
- **License:** CC0 1.0 Universal
- **Format:** OBJ, FBX, glTF
- **Style:** Clean, low-poly, modular design
- **Relevant packs:**

| Pack | URL | Contents |
|------|-----|----------|
| **Nature Kit** | https://kenney.nl/assets/nature-kit | 330 nature assets — trees, rocks, plants, terrain pieces, waterfall, tent, fences |
| **Starter Kit FPS** | https://godotengine.org/asset-library/asset/2208 | FPS starter with weapon models, enemies, environment (MIT, Godot-native) |

#### Poly Haven Models (SUPPLEMENTARY — CC0)
- **URL:** https://polyhaven.com/models
- **License:** CC0 1.0 Universal
- **Format:** Blender, FBX, glTF, USD
- **Style:** Photorealistic scans — rocks, plants, debris
- **Recommended for:** Hero rocks and boulders where photorealism matters (near-player focal points)

#### OpenGameArt (SUPPLEMENTARY — Mixed licenses, verify each)
- **URL:** https://opengameart.org
- **License:** VARIES — always check. Filter by CC0 for safety.
- **Recommended for:** Specialized assets not found elsewhere. Always verify license before importing.

### 7.5 Water Shader Sources

| Resource | URL | License | Notes |
|----------|-----|---------|-------|
| **Boujie Water Shader** | https://github.com/Chrisknyfe/boujie_water_shader | MIT | Gerstner waves, infinite ocean mesh, shore foam, refraction. Godot 4.1+. Best option for ocean. |
| **Godot Ocean FFT** | https://github.com/tessarakkt/godot4-oceanfft | MIT | Tessendorf FFT waves + compute shaders + CDLOD. More realistic but heavier. Use if GPU budget allows. |
| **Godot Ocean Shader (Lightweight)** | https://github.com/immaculate-lift-studio/Godot-Ocean-Shader | MIT | Simple, tileable, tested up to 6000×6000m. Good for mobile fallback. |
| **Waterways .NET** | https://github.com/Tshmofen/waterways-net | MIT | Bezier-curve river mesh generation with flow shader. C#/NET required. Evaluate if river mesh generation is needed programmatically. |
| **Water Shader 3D (Godot Shaders)** | https://godotshaders.com/shader/water-shader-3d-godot-4-3/ | MIT | Gerstner waves + caustics + foam. Lightweight. Good for lakes and calm water. |

### 7.6 HDRI / Environment Sources

| Source | URL | License | Use For |
|--------|-----|---------|---------|
| **Poly Haven HDRIs** | https://polyhaven.com/hdris | CC0 | Sky reference, reflection probes, environment lighting. Sky3D replaces the actual sky, but HDRIs are useful for ReflectionProbe baking. |
| **ambientCG HDRIs** | https://ambientcg.com/list?type=HDRI | CC0 | Additional HDRI options |

### 7.7 Audio Sources (for later phases)

| Source | URL | License | Contents |
|--------|-----|---------|----------|
| **Freesound.org** | https://freesound.org | Mixed — filter by CC0 | Massive library. Always verify per-sound license. |
| **Kenney Audio** | https://kenney.nl/assets?t=audio | CC0 | UI sounds, impacts, RPG sounds |
| **OpenGameArt Audio** | https://opengameart.org/art-search-advanced?keys=&field_art_type_tid%5B%5D=12 | Mixed — filter by CC0 | Music, ambient, SFX |

### 7.8 Asset Download & Import Workflow

When the coding agent needs to add an asset to the project, follow this exact workflow:

1. **Identify the asset** from the catalogs above
2. **Verify the license** — open the source page and confirm it's CC0, CC-BY, MIT, or another acceptable license
3. **Download** the asset at an appropriate resolution (1K–2K for terrain textures; low-poly for models)
4. **Place files** in the correct `assets/` subdirectory per the project structure
5. **Add an entry to `ATTRIBUTION.md`** immediately, before doing anything else with the asset
6. **Import into Godot** — for textures, set import flags (repeat, filter); for models, verify orientation and scale
7. **Test** — verify the asset renders correctly in the engine

For programmatic downloading (if the agent has network access):

```bash
# Example: Download a texture set from ambientCG
# Always download from the direct URL, never scrape
curl -L "https://ambientcg.com/get?file=Grass001_1K-JPG.zip" -o /tmp/Grass001.zip
unzip /tmp/Grass001.zip -d assets/textures/terrain/grass/Grass001/
```

If the agent does NOT have network access to these domains, it should:
1. Document what assets are needed and from where
2. Create placeholder materials (solid color with appropriate roughness)
3. Leave `TODO` comments referencing the specific asset and URL to download
4. Add placeholder entries to `ATTRIBUTION.md` marked as `[PLACEHOLDER — download from URL]`
5. Add an entry to `TO_RESOLVE.md` (see Section 7.9)

### 7.9 Placeholder Asset Policy & TO_RESOLVE.md

Not every asset can be sourced from the catalogs above — especially character models (anthropomorphic cats, dogs, dragons, unique NPCs), custom props tied to the lore, and audio that doesn't exist in free libraries. When the agent encounters an asset gap, it should follow this decision tree:

```
Need an asset
    │
    ├── Found in Asset Catalog (Section 7.3–7.7)?
    │       └── YES → Download, import, attribute. Done.
    │
    ├── Not in catalog, but agent can search for one?
    │       └── YES → Search for a CC0/CC-BY asset online.
    │                  If found: import, attribute. Done.
    │                  If not found: fall through to placeholder.
    │
    └── Cannot find a suitable asset?
            └── Create a PLACEHOLDER and log it in TO_RESOLVE.md.
```

#### What Counts as a Placeholder

| Asset Type | Acceptable Placeholder | Visual Indicator |
|---|---|---|
| **Character model** (NPC, creature) | Colored primitive (capsule for humanoid, sphere for creature) with a Label3D showing the intended character name | Bright magenta (#FF00FF) material |
| **Unique prop** (quest item, lore object) | Box or sphere primitive with Label3D | Bright cyan (#00FFFF) material |
| **Texture** | Solid color with appropriate roughness value | Use a color that suggests the intent (green for grass, brown for dirt) |
| **Audio** | Silent AudioStreamPlayer with a print statement: `print("[DEBUG][PLACEHOLDER] Sound: <description>")` | N/A |
| **VFX / Particles** | Simple particle emitter with placeholder color | Bright yellow (#FFFF00) |
| **Animation** | Static pose or simple procedural bob/rotate | N/A |

**Placeholder naming convention:** All placeholder scenes and resources must be prefixed with `PH_` (e.g., `PH_elder_cat.tscn`, `PH_dragon_model.tres`). This makes them easy to find and replace later.

#### TO_RESOLVE.md Format

The file `res://TO_RESOLVE.md` tracks every placeholder and decision point that requires human attention. The agent MUST create this file at project initialization (Phase 0) and update it whenever a placeholder is created or a decision is needed.

```markdown
# Mission Impawsible — Items Requiring Resolution

> This file is maintained by the coding agent. Each entry represents a placeholder,
> missing asset, design decision, or blocker that needs human input.
> 
> **Status key:** 🔴 BLOCKING (can't proceed without this) | 🟡 PLACEHOLDER (functional but needs real asset) | 🔵 DECISION (needs human input on direction)
>
> When you resolve an item, delete it from this file or move it to the ## Resolved section at the bottom.

## Unresolved

### PH-001 — Elder Cat NPC Model 🟡 PLACEHOLDER
- **Phase:** 5
- **Current state:** Magenta capsule with Label3D "Elder Cat"
- **What's needed:** Anthropomorphic cat character model (elderly, wise appearance). Rigged with idle, talk, and gesture animations. glTF/FBX format.
- **Placeholder file:** `res://scenes/npcs/PH_elder_cat.tscn`
- **Suggested sources:** Custom commission, Blender creation, or stylized cat model from itch.io/Sketchfab (check license)
- **Impact if unresolved:** Game is playable but NPCs look like colored pills

### PH-002 — Dragon Creature Model 🟡 PLACEHOLDER
- **Phase:** 5
- **Current state:** Orange sphere with Label3D "Dragon"
- **What's needed:** Dragon model (tameable creature per lore). Rigged with idle, fly, land, tamed animations.
- **Placeholder file:** `res://scenes/npcs/PH_dragon.tscn`
- **Suggested sources:** KayKit doesn't have dragons in free tier. Check Sketchfab CC0, OpenGameArt, or commission.
- **Impact if unresolved:** Dragon Taming ability works mechanically but target is a sphere

### DEC-001 — Art Style Direction 🔵 DECISION
- **Phase:** 2
- **Question:** Should the game use a consistent low-poly style (matching KayKit/Kenney assets) or aim for a more realistic look (using Poly Haven scans)? Mixing styles will look jarring.
- **Options:** (A) Commit to low-poly stylized — use KayKit/Kenney exclusively (B) Commit to realistic — need different asset sources for everything (C) Stylized terrain + low-poly models (common indie approach)
- **Current assumption:** Option C — stylized terrain textures with low-poly KayKit models
- **Impact:** Affects every asset decision going forward

## Resolved

(Move resolved items here with a note on the resolution)
```

#### Rules for the Agent

1. **Every placeholder gets a TO_RESOLVE.md entry.** No exceptions. If you create a `PH_` prefixed file, it gets an entry.
2. **Every design decision you're uncertain about gets a TO_RESOLVE.md entry.** If you're making an assumption that could go either way, log it.
3. **Use the ID format:** `PH-NNN` for placeholders, `DEC-NNN` for decisions, `BLK-NNN` for blockers. Increment sequentially.
4. **Be specific about what's needed.** Don't write "need a model" — write "need a rigged anthropomorphic cat model with idle/walk/talk animations in glTF format, approximately 2000-5000 polys, stylized to match KayKit aesthetic."
5. **Suggest sources or approaches** when you can. If you found something close but it had the wrong license, mention it.
6. **Note the impact.** Help the human prioritize — "game is fully playable but ugly" is different from "this system doesn't work without this asset."
7. **The agent may search for assets on its own.** If you have web access and can't find what you need in the catalog, search itch.io, Sketchfab (filter CC0), OpenGameArt, or other sources. If you find something suitable, import it normally with full attribution. Only fall back to placeholders if the search fails.

---

## 8. Project Structure

```
res://
├── project.godot
├── addons/
│   ├── cogito/                  # COGITO framework
│   ├── terrain_3d/              # Terrain3D GDExtension
│   ├── sky3d/                   # Sky3D day/night
│   ├── dialogue_manager/        # Dialogue Manager 3
│   ├── behaviour_toolkit/       # NPC AI
│   ├── spatial_gardener/        # Non-terrain foliage
│   ├── foliage3d/               # Terrain-based foliage
│   ├── boujie_water_shader/     # Ocean/water Gerstner waves
│   └── gut/                     # GUT test framework
├── autoloads/
│   ├── signal_bus.gd            # Global signal bus
│   ├── game_state.gd            # Global game state (tuna coins, unlocked abilities, flags)
│   └── debug_logger.gd          # Debug output utility (wraps print with [DEBUG] prefix)
├── scenes/
│   ├── main/
│   │   ├── main.tscn            # Root scene
│   │   └── main.gd
│   ├── player/
│   │   ├── player.tscn          # COGITO player (customized)
│   │   ├── player.gd            # Player script extensions
│   │   ├── abilities/
│   │   │   ├── ability_base.gd  # Base class for all abilities
│   │   │   ├── fire_ability.gd
│   │   │   ├── ice_ability.gd
│   │   │   ├── woodland_ability.gd
│   │   │   ├── dragon_taming_ability.gd
│   │   │   └── creature_speak_ability.gd
│   │   └── viewmodel/
│   │       └── paw_viewmodel.tscn
│   ├── world/
│   │   ├── terrain/
│   │   │   ├── world_terrain.tscn
│   │   │   ├── terrain_config.gd
│   │   │   └── terrain_generator.gd   # Procedural heightmap generation tool script
│   │   ├── sky/
│   │   │   └── world_sky.tscn
│   │   ├── water/
│   │   │   ├── ocean.tscn             # Infinite ocean plane with Boujie shader
│   │   │   ├── river_main.tscn        # Main river mesh
│   │   │   └── lake_forest.tscn       # Forest biome lake
│   │   └── areas/
│   │       ├── starting_village.tscn
│   │       ├── ability_shrine.tscn
│   │       └── [future biome detail scenes]
│   ├── npcs/
│   │   ├── npc_base.tscn
│   │   ├── npc_base.gd
│   │   └── [specific NPCs]
│   ├── interactables/
│   │   ├── tuna_coin_pickup.tscn
│   │   ├── quest_item.tscn
│   │   └── [other interactables]
│   └── ui/
│       ├── ability_hud.tscn
│       ├── tuna_coin_display.tscn
│       └── touch_controls.tscn
├── dialogue/
│   ├── npc_elder.dialogue        # Dialogue Manager script files
│   └── [other dialogue files]
├── resources/
│   ├── items/                    # COGITO item resources
│   ├── abilities/                # Ability resource definitions
│   └── quests/                   # Quest resource definitions
├── ATTRIBUTION.md                # REQUIRED — tracks every imported asset, its license, and source
├── TO_RESOLVE.md                 # REQUIRED — tracks placeholders, missing assets, and decisions needing human input
├── assets/
│   ├── models/
│   │   ├── vegetation/           # Trees, bushes, grass meshes, flowers
│   │   │   ├── forest/
│   │   │   ├── desert/
│   │   │   ├── alpine/
│   │   │   └── tropical/
│   │   ├── rocks/                # Rock formations, boulders, cliffs
│   │   ├── structures/           # Ruins, shrines, villages, bridges
│   │   ├── props/                # Barrels, crates, signs, fences, etc.
│   │   └── characters/           # Cat player viewmodel, NPCs, creatures
│   ├── textures/
│   │   ├── terrain/              # PBR terrain textures (albedo, normal, roughness, AO)
│   │   │   ├── grass/
│   │   │   ├── dirt/
│   │   │   ├── rock/
│   │   │   ├── sand/
│   │   │   ├── snow/
│   │   │   ├── mud/
│   │   │   └── cliff/
│   │   ├── water/                # Water normal maps, foam textures
│   │   ├── foliage/              # Leaf/grass billboard textures
│   │   └── skybox/               # HDRI skymaps (if not using Sky3D procedural)
│   ├── audio/
│   │   ├── sfx/
│   │   │   ├── environment/      # Wind, water, birds, rustling
│   │   │   ├── player/           # Footsteps per surface, meow, purr
│   │   │   ├── abilities/        # Fire whoosh, ice crack, nature growth
│   │   │   └── ui/               # Click, coin pickup, menu sounds
│   │   └── music/
│   │       ├── ambient/          # Per-biome ambient tracks
│   │       └── event/            # Combat, discovery, cutscene
│   └── shaders/
│       ├── water/                # Ocean, river, waterfall shaders
│       ├── foliage/              # Wind animation, billboard shaders
│       └── effects/              # Ability VFX, weather particles
└── tests/
    ├── unit/
    │   ├── test_game_state.gd
    │   ├── test_ability_system.gd
    │   ├── test_tuna_coins.gd
    │   └── test_signal_bus.gd
    ├── integration/
    │   ├── test_player_movement.gd
    │   ├── test_interactions.gd
    │   └── test_save_load.gd
    └── debug_test.gd             # Master headless test runner
```

---

## 9. Development Standards

### 9.1 Debug Output (REQUIRED)

All gameplay functions and systems you implement MUST include `print()` debug output prefixed with `[DEBUG]`. This is not optional — it is a core development practice for this project.

#### Rules

1. **Every function that affects gameplay state** (movement, physics, spawning, abilities, AI, etc.) must print key state information using `print("[DEBUG] ...")`.
2. **Include context**: Print the function name, relevant variable values, and outcomes. Examples:
   - `print("[DEBUG] _snap_to_ground: raycast hit at %s, placing player at %s" % [result.position, final_pos])`
   - `print("[DEBUG] _physics_process: is_on_floor=%s vel=%s pos=%s" % [is_on_floor(), velocity, global_position])`
   - `print("[DEBUG] apply_damage: target=%s amount=%d remaining_hp=%d" % [target.name, amount, target.hp])`
3. **Print on state transitions**: When a value changes (e.g., `is_on_floor` goes from false to true), log it.
4. **Print on failures/fallbacks**: If a raycast misses, a node isn't found, or a fallback path is taken, always log it.
5. **Keep debug output concise** but informative — one line per event, not per frame (unless actively debugging a per-frame issue).

#### Debug Logger Utility

Implement `res://autoloads/debug_logger.gd` as a convenience wrapper:

```gdscript
# autoloads/debug_logger.gd
extends Node

var enabled: bool = true
var log_to_file: bool = false
var _log_file: FileAccess = null

func _ready():
    if log_to_file:
        _log_file = FileAccess.open("user://debug_log.txt", FileAccess.WRITE)
        print("[DEBUG] DebugLogger: file logging enabled to user://debug_log.txt")

func log(context: String, message: String) -> void:
    if not enabled:
        return
    var line := "[DEBUG] %s: %s" % [context, message]
    print(line)
    if _log_file:
        _log_file.store_line(line)

func log_state_change(context: String, var_name: String, old_val, new_val) -> void:
    if not enabled:
        return
    if old_val != new_val:
        log(context, "%s changed: %s -> %s" % [var_name, old_val, new_val])

func log_error(context: String, message: String) -> void:
    var line := "[DEBUG][ERROR] %s: %s" % [context, message]
    push_error(line)
    print(line)
    if _log_file:
        _log_file.store_line(line)
```

Register as autoload named `DebugLog`. Usage: `DebugLog.log("PlayerMovement", "jumped, vel.y=%s" % velocity.y)`

### 9.2 Headless Testing (REQUIRED)

You MUST use scripted testing. When implementing features and fixes, you MUST write test scripts that exercise your code. When you are done, you MUST verify it works by running in headless mode and checking the debug output.

#### GUT Test Execution (Primary Method)

```bash
# Import project resources first (required once, or after adding new assets)
godot --headless --import --quit

# Run all tests
godot --headless -d --path . -s res://addons/gut/gut_cmdln.gd \
  -gdir=res://tests -ginclude_subdirs -gexit

# Run a specific test file
godot --headless -d --path . -s res://addons/gut/gut_cmdln.gd \
  -gtest=res://tests/unit/test_game_state.gd -gexit

# Run tests matching a pattern
godot --headless -d --path . -s res://addons/gut/gut_cmdln.gd \
  -gdir=res://tests -ginclude_subdirs -gprefix=test_ -gexit
```

GUT returns exit code 0 on pass, 1 on fail. Output includes pass/fail counts.

#### Syntax Validation (Quick Check)

```bash
# Validate a single script without running
godot --check-only --script res://path/to/script.gd
```

#### What to Check in the Output

- No errors or warnings from Godot
- `[DEBUG]` lines show the expected behavior (correct positions, state transitions, collision hits, etc.)
- Scripted test actions in `debug_test.gd` produce the expected results
- No silent failures (e.g., raycasts returning no hits when they should)

#### When a Test Fails

Do NOT guess at fixes. Read the debug output, identify the root cause from the printed state, and fix the actual problem. The debug output exists so you can diagnose issues directly rather than making assumptions.

#### Test File Template

```gdscript
# tests/unit/test_example.gd
extends GutTest

# Runs before each test
func before_each():
    pass

# Runs after each test
func after_each():
    pass

func test_something_specific():
    # Arrange
    var obj = preload("res://path/to/scene.tscn").instantiate()
    add_child_autofree(obj)  # GUT auto-frees after test

    # Act
    obj.some_method()

    # Assert
    assert_eq(obj.some_value, expected_value, "Description of what should be true")
    assert_true(obj.some_bool, "Should be true because...")
    assert_not_null(obj.some_ref, "Reference should exist")
```

### 9.3 Agent Workflow Protocol

When implementing any feature, follow this exact loop:

```
1. READ the relevant phase section in this PRD
2. READ any referenced plugin documentation
3. IMPLEMENT the feature (create/edit files)
4. RUN syntax check: godot --check-only --script <file>
5. WRITE tests for the feature in tests/
6. RUN tests headless: godot --headless ... -gexit
7. READ test output — check [DEBUG] lines and pass/fail
8. IF tests fail: READ output, identify root cause, fix, go to step 4
9. IF tests pass: move to next feature
```

**Never skip steps 4-8.** Every feature must be validated before moving on.

### 9.4 GDScript Style

- Use static typing everywhere: `var speed: float = 6.0`
- Use `@onready` for node references: `@onready var camera: Camera3D = $Camera3D`
- Use `@export` for inspector-tunable values: `@export var jump_height: float = 3.0`
- Prefix private methods/vars with `_`: `func _calculate_fall_damage() -> float:`
- Signal names are past tense: `signal coin_collected`, `signal ability_activated`
- Class names are PascalCase, file names are snake_case
- Every script begins with `class_name` if it will be referenced elsewhere

### 9.5 Licensing & Attribution (REQUIRED)

All third-party assets, plugins, and libraries MUST be tracked. This is not optional.

1. **Before importing any asset**, verify its license is acceptable (see Section 7.1).
2. **Immediately after adding any file** from an external source, add a complete entry to `res://ATTRIBUTION.md` following the format in Section 7.2.
3. **Never import first, attribute later.** The attribution entry is part of the import action, not a cleanup task.
4. **Plugin licenses:** Every plugin in `addons/` must have its LICENSE file preserved. If one doesn't ship with the plugin, create `addons/<plugin>/LICENSE` containing the license text from the source repository.
5. **Shader code:** If you copy/adapt shader code from Godot Shaders, GitHub, or tutorials, add attribution as a comment at the top of the `.gdshader` file AND in `ATTRIBUTION.md`.
6. **AI-generated assets:** If you use procedural generation to create textures, meshes, or audio, note "Procedurally generated for Mission Impawsible" in the attribution for that asset. No external license applies.
7. **In-game credits screen:** Phase 8 must include a credits/attribution screen accessible from the main menu that lists all CC-BY (and optionally CC0) attributions in a readable format.

---

## Phase 0 — Environment Setup

**Goal:** Bootable Godot project with COGITO and GUT installed, autoloads registered, and a "hello world" headless test passing.

### Tasks

#### 0.1 — Create Godot Project

- Create a new Godot 4.x project named `MissionImpawsible`
- Set up `project.godot` with the following settings:
  - `display/window/size/viewport_width = 1920`
  - `display/window/size/viewport_height = 1080`
  - `display/window/stretch/mode = "canvas_items"`
  - `rendering/renderer/rendering_method = "forward_plus"` (PC) — mobile will override later
  - `input/ui_accept` mapped to Space, Enter, Gamepad A
  - `physics/3d/default_gravity = 9.8`

#### 0.2 — Install COGITO

- Download COGITO from the asset library or GitHub
- Copy `addons/cogito/` into the project
- Enable the plugin in Project Settings → Plugins
- Follow COGITO's setup guide to verify the demo scene runs
- Document any COGITO autoloads that get registered (these are part of the framework)

#### 0.3 — Install GUT

- Download GUT from GitHub: `https://github.com/bitwes/Gut`
- Copy `addons/gut/` into the project
- Enable the plugin
- Create `tests/` directory with `unit/` and `integration/` subdirectories
- Create a `.gutconfig.json` in project root:

```json
{
  "dirs": ["res://tests"],
  "include_subdirs": true,
  "prefix": "test_",
  "suffix": ".gd",
  "log_level": 2,
  "should_exit": true
}
```

#### 0.4 — Create Autoloads

Create these three autoload scripts and register them in `project.godot`:

- `res://autoloads/signal_bus.gd` — Global signal bus (signals listed in Section 4)
- `res://autoloads/game_state.gd` — Holds tuna coins, unlocked abilities, game flags
- `res://autoloads/debug_logger.gd` — Debug logging utility (code in Section 7.1)

```gdscript
# autoloads/signal_bus.gd
extends Node

signal ability_unlocked(ability_name: String, level: int)
signal ability_used(ability_name: String, target: Node)
signal tuna_coins_changed(old_amount: int, new_amount: int)
signal quest_started(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_objective_updated(quest_id: String, objective_id: String)
signal player_entered_area(area_name: String)
signal npc_interaction_started(npc_id: String)
signal npc_interaction_ended(npc_id: String)
signal day_night_changed(is_day: bool)
signal magic_discipline_discovered(discipline: String)
```

```gdscript
# autoloads/game_state.gd
extends Node

const MAGIC_DISCIPLINES := ["fire", "ice", "woodland", "dragon_taming", "creature_speak"]

var tuna_coins: int = 2:  # Player starts with 2 per lore
    set(value):
        var old := tuna_coins
        tuna_coins = max(0, value)
        if old != tuna_coins:
            DebugLog.log_state_change("GameState", "tuna_coins", old, tuna_coins)
            SignalBus.tuna_coins_changed.emit(old, tuna_coins)

# ability_name -> level (0 = locked, 1+ = unlocked levels)
var ability_levels: Dictionary = {}
var quest_flags: Dictionary = {}  # quest_id -> state string
var gem_found: bool = false

func _ready() -> void:
    for discipline in MAGIC_DISCIPLINES:
        ability_levels[discipline] = 0
    DebugLog.log("GameState", "initialized: tuna_coins=%d, disciplines=%s" % [tuna_coins, MAGIC_DISCIPLINES])

func unlock_ability(discipline: String) -> bool:
    if discipline not in MAGIC_DISCIPLINES:
        DebugLog.log_error("GameState", "invalid discipline: %s" % discipline)
        return false
    if tuna_coins <= 0:
        DebugLog.log("GameState", "cannot unlock %s — no tuna coins" % discipline)
        return false
    var current_level: int = ability_levels[discipline]
    tuna_coins -= 1
    ability_levels[discipline] = current_level + 1
    DebugLog.log("GameState", "unlocked %s to level %d (spent 1 tuna coin, remaining: %d)" % [discipline, current_level + 1, tuna_coins])
    SignalBus.ability_unlocked.emit(discipline, current_level + 1)
    return true

func get_ability_level(discipline: String) -> int:
    return ability_levels.get(discipline, 0)

func add_tuna_coins(amount: int) -> void:
    DebugLog.log("GameState", "adding %d tuna coins" % amount)
    tuna_coins += amount

func reset() -> void:
    tuna_coins = 2
    for discipline in MAGIC_DISCIPLINES:
        ability_levels[discipline] = 0
    quest_flags.clear()
    gem_found = false
    DebugLog.log("GameState", "reset to initial state")
```

#### 0.5 — Verify with Tests

Create `tests/unit/test_game_state.gd`:

```gdscript
extends GutTest

func before_each():
    GameState.reset()

func test_initial_tuna_coins():
    assert_eq(GameState.tuna_coins, 2, "Player starts with 2 tuna coins per lore")

func test_unlock_ability_spends_coin():
    GameState.unlock_ability("fire")
    assert_eq(GameState.tuna_coins, 1, "Should have 1 coin after unlocking fire")
    assert_eq(GameState.get_ability_level("fire"), 1, "Fire should be level 1")

func test_unlock_ability_fails_without_coins():
    GameState.tuna_coins = 0
    var result := GameState.unlock_ability("ice")
    assert_false(result, "Should fail to unlock without coins")
    assert_eq(GameState.get_ability_level("ice"), 0, "Ice should still be level 0")

func test_unlock_invalid_discipline_fails():
    var result := GameState.unlock_ability("laser_eyes")
    assert_false(result, "Should reject invalid discipline")
    assert_eq(GameState.tuna_coins, 2, "Coins should be unchanged")

func test_all_five_disciplines_exist():
    var expected := ["fire", "ice", "woodland", "dragon_taming", "creature_speak"]
    for d in expected:
        assert_has(GameState.ability_levels, d, "Discipline %s should exist" % d)

func test_add_tuna_coins():
    GameState.add_tuna_coins(3)
    assert_eq(GameState.tuna_coins, 5, "Should have 2 + 3 = 5 coins")

func test_tuna_coins_cannot_go_negative():
    GameState.tuna_coins = 0
    GameState.tuna_coins = -5
    assert_eq(GameState.tuna_coins, 0, "Coins should not go below 0")
```

#### 0.6 — Create Project Tracking Documents

Create both required tracking documents at project root:

- `res://ATTRIBUTION.md` — Initialize with the header and entries for COGITO and GUT (the first two imported dependencies). Follow the format in Section 7.2.
- `res://TO_RESOLVE.md` — Initialize with the header template from Section 7.9. Add `DEC-001 — Art Style Direction` as the first entry (see Section 7.9 for example).

These files are living documents. Every subsequent phase will add to them.

#### Phase 0 — Acceptance Criteria

```
[ ] Godot project opens without errors
[ ] COGITO plugin enabled and demo scene runs
[ ] GUT plugin enabled
[ ] All three autoloads registered and load without errors
[ ] ATTRIBUTION.md exists with entries for COGITO and GUT
[ ] TO_RESOLVE.md exists with initial art style decision entry
[ ] `godot --headless --import --quit` succeeds
[ ] `godot --headless -d -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit` passes all tests
[ ] [DEBUG] output from GameState visible in test output
```

---

## Phase 1 — Core Player Controller

**Goal:** First-person cat controller walking around a flat test level with COGITO interactions working.

**Depends on:** Phase 0

### Tasks

#### 1.1 — Configure COGITO Player for Cat Proportions

Start from COGITO's default player scene and customize for a cat:

- **Camera height:** ~0.4m (cat eye level, assuming world is human-scaled — cat is small in a big world). If this feels too extreme, use ~1.0m as "anthropomorphic cat" height and adjust later based on art direction.
- **Collision shape:** Capsule, radius ~0.2m, height ~0.5m (or scale proportionally to chosen camera height)
- **Movement speeds (export vars, tunable):**
  - Walk: 4.0 m/s
  - Sprint: 8.0 m/s
  - Crouch: 2.0 m/s
- **Jump velocity:** Calculate for ~1.5x character height jump: `sqrt(2 * gravity * jump_height)`
- **Fall damage multiplier:** 0.3x COGITO default (cats are resilient fallers)
- **Head bob:** Enable, reduce intensity to 60% of default (subtle)
- **Crouch height:** 60% of standing height
- **COGITO attributes to configure:**
  - Health: 100 (default)
  - Stamina: 80 (used for sprinting)
  - Visibility: enable (for future stealth mechanics)

**Debug output required:**
- Log movement state transitions (idle→walking→sprinting→crouching)
- Log jump and land events with velocity
- Log fall damage calculations

#### 1.2 — Create Test Level

Build a simple test environment scene (`res://scenes/test/test_level.tscn`):

- Flat ground plane (50m × 50m)
- A few box meshes at varying heights for jump testing
- A ramp for slope testing
- A COGITO-compatible door
- A COGITO-compatible pickup item (placeholder for tuna coin)
- A COGITO-compatible readable note
- Ambient light + directional light (placeholder, Sky3D replaces later)
- Spawn point marker

This level is for development testing. It persists throughout all phases as a sandbox.

#### 1.3 — Verify COGITO Interaction System

Using the test level, verify these COGITO interactions work:

- Look at door → prompt appears → press E → door opens
- Look at pickup → prompt appears → press E → item goes to inventory
- Look at note → prompt appears → press E → note text displays
- Open inventory (Tab or COGITO's default key) → see collected items
- Pause menu (Esc) → options → resume

**Debug output required:**
- Log every interaction attempt (what was looked at, distance, result)
- Log inventory additions/removals

#### 1.4 — Input Map Setup

Define all input actions in `project.godot` → Input Map:

```
move_forward:    W, Gamepad Left Stick Up
move_backward:   S, Gamepad Left Stick Down
move_left:       A, Gamepad Left Stick Left
move_right:      D, Gamepad Left Stick Right
jump:            Space, Gamepad A/Cross
sprint:          Shift, Gamepad L3
crouch:          Ctrl / C, Gamepad B/Circle
interact:        E, Gamepad X/Square
ability_fire:    1, Gamepad D-Pad Up
ability_ice:     2, Gamepad D-Pad Right
ability_woodland: 3, Gamepad D-Pad Down
ability_dragon:  4, Gamepad D-Pad Left
ability_speak:   5, Gamepad RB/R1
inventory:       Tab, Gamepad Select/Back
pause:           Escape, Gamepad Start
```

#### Phase 1 — Acceptance Criteria

```
[ ] Player spawns in test level at correct cat-height camera
[ ] WASD movement works, speed matches configured values
[ ] Sprint, crouch, jump all function
[ ] COGITO interaction prompts appear on interactable objects
[ ] Door opens, item picks up into inventory, note displays
[ ] Gamepad controls work for all actions
[ ] [DEBUG] output shows movement states, interactions, inventory changes
[ ] All Phase 1 tests pass headless
```

---

## Phase 2 — World Foundation

**Goal:** Massive open world terrain with day/night cycle, water systems, biome texturing, and vegetation. Player walks through a living landscape under a dynamic sky.

**Depends on:** Phase 1

**IMPORTANT:** This phase builds the 16km × 16km open world defined in Section 6. Build the Central Plains first (the starting area), get it fully playable, then expand outward biome by biome. Do NOT try to build all biomes at once.

### Tasks

#### 2.1 — Install & Configure Terrain3D

- Install the Terrain3D GDExtension (download compiled binary matching Godot version and OS)
- Create a Terrain3D node in the main scene
- Initial configuration for the full world:
  - **World size:** 16,384m × 16,384m (16×16 grid of 1024m regions)
  - **Region size:** 1024m × 1024m
  - Collision enabled for CharacterBody3D
  - Configure the texture array with slots for all biome textures (up to 32 layers)

For the initial build, only populate the central 3×3 regions (3072m × 3072m) with detail. Outer regions can be flat or have rough heightmap data — they'll be detailed in later iterations.

**Terrain texture layer plan (assign these slots early so biome painting is consistent):**

| Slot | Texture | Source | Biome |
|------|---------|--------|-------|
| 0 | Grassland (lush) | ambientCG Grass001 | Central Plains, Meadow |
| 1 | Dry grass | ambientCG Grass004 | Plains edges, Savanna |
| 2 | Forest floor | ambientCG Ground037 | Deciduous Forest |
| 3 | Dirt path | ambientCG Ground048 | All biomes (paths) |
| 4 | Rocky ground | ambientCG Rock030 | Foothills, Peaks |
| 5 | Bare rock | ambientCG Rock043 | Alpine Peaks, cliffs |
| 6 | Sand | ambientCG Ground060 | Beach, Desert |
| 7 | Snow | ambientCG Snow004 | Alpine Peaks |
| 8 | Mud / wet ground | ambientCG Mud002 | River Valley |
| 9 | Cliff face | ambientCG CliffRock001 | Cliffs (auto-slope shader) |
| 10 | Pine needle floor | Poly Haven or ambientCG | Foothills conifer areas |
| 11 | Wildflower grass | ambientCG Grass005 | Highland Meadow |
| 12–31 | Reserved | — | Future detail textures |

**Asset attribution:** Add every downloaded texture to `ATTRIBUTION.md` per Section 7.2 before importing.

**Debug output required:**
- Log terrain initialization (world size, region count, texture layer count, collision status)
- Log player terrain height queries if using `get_height()` API

#### 2.2 — Heightmap Generation

Create the world's elevation profile. The heightmap must encode the biome layout from Section 6.3:

- **North:** Highest elevations (1200–2000m) for Alpine Peaks
- **Center:** Moderate, rolling elevations (50–200m) for Central Plains
- **South:** Low elevations trending to sea level for Coast/Ocean
- **West:** Medium-high for Forest, valleys with rivers
- **East:** Moderate, drier terrain for Savanna/Scrub

Approach options (choose one):
1. **Programmatic generation** via GDScript using Terrain3D's sculpting API — use layered FastNoiseLite with different scales per biome region
2. **Import a heightmap PNG** — create a 16384×16384 (or 8192×8192 scaled up) 16-bit PNG heightmap and import via Terrain3D's heightmap importer
3. **External tool** — generate in World Machine, Gaea, or similar, export as heightmap PNG

The agent should use approach 1 (programmatic) if possible, as it's fully automated and reproducible. Example strategy:

```gdscript
# Pseudocode for programmatic heightmap
# Run once as a tool script to generate the world, then save the Terrain3D data

func generate_world():
    var noise_base = FastNoiseLite.new()
    noise_base.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    noise_base.frequency = 0.0003  # Large-scale features
    
    var noise_detail = FastNoiseLite.new()
    noise_detail.frequency = 0.002  # Medium detail
    
    var noise_micro = FastNoiseLite.new()
    noise_micro.frequency = 0.01   # Micro detail
    
    for x in range(-8192, 8192):
        for z in range(-8192, 8192):
            var base_h = noise_base.get_noise_2d(x, z) * 500.0
            var detail_h = noise_detail.get_noise_2d(x, z) * 50.0
            var micro_h = noise_micro.get_noise_2d(x, z) * 5.0
            
            # Biome elevation modifiers based on world position
            var latitude_factor = remap(z, -8192, 8192, 1.0, -0.3)  # North = high, South = low
            var elevation = (base_h + detail_h + micro_h) * max(latitude_factor, 0.0)
            
            terrain.set_height(Vector2(x, z), elevation)
```

**Debug output required:**
- Log heightmap generation progress (percentage complete)
- Log min/max elevation after generation
- Log region activation as player approaches

#### 2.3 — Install & Configure Sky3D

- Install Sky3D into addons
- Add Sky3D node to main scene
- Configure day/night cycle:
  - Day length: 10 minutes real-time = 1 in-game day (tunable via export)
  - Sun/moon rotation
  - Dynamic atmosphere color shifting
  - Connect to `SignalBus.day_night_changed` signal when day/night transitions occur
- Verify Sky3D's DirectionalLight3D drives scene lighting
- **Ensure Sky3D and Terrain3D don't conflict on lighting** — Sky3D should own the DirectionalLight3D; do not add a separate one

**Debug output required:**
- Log time of day transitions (dawn, day, dusk, night)
- Log current game time periodically (every in-game hour)

#### 2.4 — Integrate Player with Terrain

- Replace test level's flat plane with Terrain3D in the main scene
- Verify COGITO player walks on terrain without falling through
- Verify jumping works on terrain slopes
- Verify camera doesn't clip through terrain
- Set player spawn point in the Central Plains biome, above terrain surface
- Test walking across region boundaries (no stutter, no falling through)

**Debug output required:**
- Log spawn position and terrain height at spawn
- Log if player ever falls below terrain (error condition)
- Log region transitions as player crosses region boundaries

#### 2.5 — Water Systems

Implement the world's water in layers:

**2.5.1 — Ocean Plane**
- Place an infinite-extent water plane mesh at Y=0 (sea level)
- Apply the Boujie Water Shader (MIT) or equivalent Gerstner wave shader from Section 7.5
- The ocean should be visible from the southern coastal areas and extend to the horizon
- Configure: wave height, color, transparency, foam at shoreline
- Add `ATTRIBUTION.md` entry for whichever water shader is used

**2.5.2 — Rivers**
- Create river meshes following the River Valley from the Foothills south to the ocean
- Use a UV-scrolling flow shader for water movement direction
- River width: 10–30m (varies along path)
- Rivers should carve slightly into the terrain heightmap (or be placed in pre-carved valleys)
- At minimum: one major river with 2–3 tributaries

**2.5.3 — Lakes**
- Place flat water plane meshes in terrain depressions
- Calmer shader than ocean (less wave amplitude)
- At minimum: one lake in the Forest biome, one in the Highland Meadow

**2.5.4 — Waterfall (stretch goal for Phase 2)**
- Particle effect + scrolling mesh at the elevation transition between Foothills and River Valley
- Can be deferred to Phase 8 (Polish) if needed

**Debug output required:**
- Log water plane initialization (position, shader type)
- Log player proximity to water (within 50m — for future swim/wade mechanics)

#### 2.6 — Central Plains Biome (Full Detail)

This is the starting area — build it to full quality first:

- **Paint terrain textures:** Lush grassland (slot 0) as base, dirt paths (slot 3) for roads, wildflower patches
- **Vegetation — grass:** Use Terrain3D's built-in instancer for grass on the grassland texture. Configure density, color variation, wind animation.
- **Vegetation — trees:** Place solitary trees and small copses using Spatial Gardener or manual placement. Use KayKit Forest Nature Pack models (CC0). Sparse — this is open plains, not forest.
- **Props:** Stone walls, fences (Kenney Nature Kit), a well, signposts
- **Starting Village:** Create a small cluster of structures using KayKit Medieval Hexagon Pack models. At minimum: 3–5 buildings, a central area, a path leading outward. This is where the player spawns and meets the Elder NPC.
- **Ability Shrine:** Place one ancient stone structure (the place where tuna coins are spent). Can use KayKit Dungeon Remastered pieces or placeholder geometry.
- **Tuna Coins:** Scatter 5–10 tuna coin pickups across the Central Plains for early exploration reward

**Debug output required:**
- Log vegetation instance count after placement
- Log all placed interactable objects with positions

#### 2.7 — Adjacent Biome Rough-In (Texturing Only)

For the biomes immediately adjacent to the Central Plains, apply terrain textures but don't fully populate with vegetation/props yet. This gives the player visible biome diversity on the horizon:

- **Deciduous Forest (West):** Paint forest floor texture, place a few large trees at the border to signal "forest ahead"
- **Foothills (North-West):** Paint rocky ground, raise elevation, place some boulders
- **Highland Meadow (North-East):** Paint wildflower grass, gentle rolling terrain
- **River Valley (South-West):** Paint mud/wet ground, carve river path in heightmap
- **Savanna (South-East):** Paint dry grass texture, flat terrain
- **Coast (South):** Paint sand, lower elevation to sea level

Full population of these biomes happens in later phases or iterations of Phase 2.

#### 2.8 — Performance Optimization Pass

With a 16km world, performance matters from day one:

- Verify Terrain3D's LOD clipmap is functioning (distant terrain should be lower resolution)
- Configure Terrain3D's foliage instancer view distance (grass should fade at ~100m)
- Set up distance-based tree LOD using MultiMeshInstance3D or visibility ranges
- Profile frame time — target 60 FPS on mid-range hardware with the Central Plains fully loaded
- If mobile is a target, test with Compatibility renderer early and note any shader incompatibilities

**Debug output required:**
- Log frame time and FPS periodically (every 30 seconds, not per frame)
- Log draw call count when available

#### Phase 2 — Acceptance Criteria

```
[ ] Terrain3D renders the full 16km × 16km world (most regions can be rough/flat)
[ ] Central Plains biome has full texture painting, grass, scattered trees, and village
[ ] Heightmap shows clear biome differentiation (peaks north, coast south, valley west)
[ ] Player walks on terrain without falling through, including across region boundaries
[ ] Sky3D day/night cycle runs (visually confirm sun moves, lighting changes)
[ ] Ocean water plane visible from coastal areas with wave shader
[ ] At least one river mesh with flow shader placed in the River Valley
[ ] Starting Village has 3-5 structures the player can walk around
[ ] At least 5 tuna coin pickups scattered in Central Plains
[ ] Ability Shrine structure placed and visible (doesn't need to be functional yet)
[ ] Adjacent biomes have rough terrain texturing visible on the horizon
[ ] All imported assets have entries in ATTRIBUTION.md
[ ] Performance: 60+ FPS in Central Plains on desktop
[ ] [DEBUG] shows terrain init, region transitions, time-of-day, water init
[ ] All Phase 2 tests pass headless
```

---

## Phase 3 — Game Systems

**Goal:** Tuna coin economy, ability unlock flow, and save/load all working.

**Depends on:** Phase 2

### Tasks

#### 3.1 — Tuna Coin Pickup Item

Create a COGITO-compatible pickup item for tuna coins:

- Scene: `res://scenes/interactables/tuna_coin_pickup.tscn`
- Mesh: placeholder (gold cylinder or sphere — replace with art later)
- On pickup: calls `GameState.add_tuna_coins(1)` (or the coin's configured value)
- Visual: gentle hover animation (bobbing up/down) and slow rotation
- Audio: coin pickup sound effect (placeholder beep)
- COGITO integration: extend COGITO's pickup item base class

**Debug output required:**
- Log coin pickup with position, value, new total

#### 3.2 — Tuna Coin HUD Display

- Add persistent HUD element showing current tuna coin count
- Position: top-right or wherever COGITO's HUD has space
- Updates reactively via `SignalBus.tuna_coins_changed`
- Animate coin count changes (brief scale-up or flash)

#### 3.3 — Ability Unlock Interface

Create a UI for spending tuna coins to unlock/level abilities:

- Accessible via a menu or an in-world object (shrine, altar, magical stone)
- Shows all 5 disciplines: Fire, Ice, Woodland, Dragon Taming, Creature Speak
- Each shows: name, current level, cost to upgrade (1 tuna coin per level), locked/unlocked state
- "Unlock" button calls `GameState.unlock_ability(discipline)`
- Visual feedback on unlock (particle effect, sound, brief screen flash)
- Disabled states: grey out if no coins available, show "Max Level" at cap

**Debug output required:**
- Log UI open/close
- Log unlock attempts with success/failure reason

#### 3.4 — Save/Load Integration

Extend COGITO's save/load system to persist Mission Impawsible's custom state:

- Tuna coin count
- Ability levels for all 5 disciplines
- Quest flags
- Player position and rotation
- Time of day (Sky3D state)
- Interactable states (which coins have been collected, which doors opened, etc.)

COGITO has a built-in save system with scene persistency — hook into it rather than building a parallel system.

**Debug output required:**
- Log save (what was saved, slot, timestamp)
- Log load (what was restored, slot, any missing/corrupted data)

#### 3.5 — Tests

```gdscript
# tests/unit/test_tuna_coins.gd
extends GutTest

func before_each():
    GameState.reset()

func test_pickup_adds_coins():
    # Simulate coin pickup
    GameState.add_tuna_coins(1)
    assert_eq(GameState.tuna_coins, 3, "2 starting + 1 pickup = 3")

func test_unlock_spend_cycle():
    GameState.add_tuna_coins(3)  # now 5 total
    GameState.unlock_ability("fire")    # costs 1 → 4
    GameState.unlock_ability("fire")    # costs 1 → 3 (fire level 2)
    GameState.unlock_ability("ice")     # costs 1 → 2
    assert_eq(GameState.tuna_coins, 2)
    assert_eq(GameState.get_ability_level("fire"), 2)
    assert_eq(GameState.get_ability_level("ice"), 1)

func test_signal_emitted_on_coin_change():
    var signal_received := false
    var received_old := -1
    var received_new := -1
    SignalBus.tuna_coins_changed.connect(func(old, new):
        signal_received = true
        received_old = old
        received_new = new
    )
    GameState.add_tuna_coins(1)
    assert_true(signal_received, "Signal should fire on coin change")
    assert_eq(received_old, 2)
    assert_eq(received_new, 3)
```

#### Phase 3 — Acceptance Criteria

```
[ ] Tuna coin pickups work in-game (walk over / interact → coin count increases)
[ ] HUD displays correct coin t, updates in real time
[ ] Ability unlock UI shows all 5 disciplines
[ ] Spending a coin unlocks/levels an ability
[ ] Cannot unlock without coins (UI shows disabled state)
[ ] Save game persists coins, abilities, player position, time of day
[ ] Load game restores all state correctly
[ ] [DEBUG] shows coin pickups, unlock attempts, save/load operations
[ ] All Phase 3 tests pass headless
```

---

## Phase 4 — Magic & Abilities

**Goal:** All five magic disciplines have at least a basic functional implentation the player can use.

**Depends on:** Phase 3

### Tasks

#### 4.1 — Ability Base System

Create `res://scenes/player/abilities/ability_base.gd`:

```gdscript
class_name AbilityBase
extends Node

@export var discipline: String = ""
@export var cooldown: float = 2.0
@export var stamina_cost: float = 10.0

var _cooldown_timer: float = 0.0
var _level: int = 0

func _ready() -> void:
    _level = GameState.get_ability_level(discipline)
    SignalBus.ability_unlocked.connect(_on_ability_unlocked)
    DegLog.log("Ability:%s" % discipline, "initialized at level %d" % _level)

func _process(delta: float) -> void:
    if _cooldown_timer > 0:
        _cooldown_timer -= delta

func can_use() -> bool:
    if _level <= 0:
        DebugLog.log("Ability:%s" % discipline, "cannot use — not unlocked")
        return false
    if _cooldown_timer > 0:
        DebugLog.log("Ability:%s" % discipline, "cannot use — on cooldown (%.1fs remaining)" % _cooldown_timer)
        return false
    return true

func use(camera:era3D) -> void:
    if not can_use():
        return
    _cooldown_timer = cooldown
    DebugLog.log("Ability:%s" % discipline, "USED at level %d" % _level)
    SignalBus.ability_used.emit(discipline, null)
    _execute(camera)

# Override in subclasses
func _execute(_camera: Camera3D) -> void:
    pass

func _on_ability_unlocked(ability_name: String, level: int) -> void:
    if ability_name == discipline:
        _level = level
        DebugLog.log("Ability:%s" % discipline, "level updated to %d" % _level)
```

#### 4.2 — Fire Ability

- **Effect:** Launches a fireball projectile from the player's view direction
- **Mechanics:** Raycast or physics projectile; deals damage to NPCs/objects; can ignite FLAMMABLE objects (COGITO systemic property)
- **Visual:** Orange-red particle effect on projectile; explosion/burst on impact
- **Scaling:** Higher levels → more damage, larger blast radius, shorter cooldown
- **Placeholder art:** Use Godot's built-in particle system with orange/red colors and a small sphereh

#### 4.3 — Ice Ability

- **Effect:** Freezes target or creates ice patch on ground
- **Mechanics:** Raycast target → applies "frozen" status (slows movement, tints blue); ground shot creates slippery area
- **Visual:** Blue-white particle burst; frozen targets get a blue tint shader
- **Scaling:** Higher levels → longer freeze duration, larger ice patch area

#### 4.4 — Woodland Ability

- **Effect:** Interacts with plant life — grow vines to create bridges/platforms, calm hostile woodland cre*Mechanics:** Targeted at ground/wall → spawns a vine platform (static body); targeted at woodland creature → pacifies
- **Visual:** Green particle effect; vine mesh spawns and "grows" (scale animation)
- **Scaling:** Higher levels → longer/sturdier vines, wider pacification range

#### 4.5 — Dragon Taming Ability

- **Effect:** Calms and befriends dragon NPCs; at high levels, can ride dragons
- **Mechanics:** Targeted at dragon NPC → applies "tamed" state; tamed dragons follow player and can be m*Visual:** Golden energy beam from player to dragon; dragon's eyes change color when tamed
- **Scaling:** Higher levels → faster taming, can tame more powerful dragons, unlock riding at level 3+
- **Note:** Dragons are Phase 5 NPCs — for Phase 4, implement the ability targeting/effect system; it will be "functional but no targets" until Phase 5

#### 4.6 — Creature Speak Ability

- **Effect:** Enables conversation with non-cat creatures (birds, fish, mice, etc.)
- **Mechanics:** Targeted at creature Npens Dialogue Manager conversation that was previously inaccessible; reveals hidden quest info, lore, hints
- **Visual:** Musical note particles between player and creature; creature turns to face player
- **Scaling:** Higher levels → can speak with more creature types, get better information
- **Note:** Like Dragon Taming, full functionality depends on Phase 5/6 NPCs and dialogue. Phase 4 implements the system; Phase 5/6 fills in the content.

#### 4.7 — Ability HUD

- Shows currently active/selected aty
- Shows cooldown state for each ability
- Shows lock icons for abilities not yet unlocked
- PC: 1-5 number keys to select; LMB/RT to activate
- Visual: row of 5 ability icons at bottom center of screen

#### 4.8 — Tests

```gdscript
# tests/unit/test_ability_system.gd
extends GutTest

var ability: AbilityBase

func before_each():
    GameState.reset()
    ability = AbilityBase.new()
    ability.discipline = "fire"
    ability.cooldown = 1.0
    add_child_autofree(ability)

func test_cannot_use_locked_ality():
    assert_false(ability.can_use(), "Level 0 ability should not be usable")

func test_can_use_after_unlock():
    GameState.unlock_ability("fire")
    # Force the ability to pick up the new level
    ability._on_ability_unlocked("fire", 1)
    assert_true(ability.can_use(), "Level 1 ability should be usable")

func test_cooldown_prevents_use():
    GameState.unlock_ability("fire")
    ability._on_ability_unlocked("fire", 1)
    ability._cooldown_timer = 0.5  # simulate mid-cooldown
    assert_false(ability.can_use(), "Should not use during cooldown")

func test_level_scales_with_unlocks():
    GameState.add_tuna_coins(3)  # now 5 coins
    GameState.unlock_ability("fire")
    GameState.unlock_ability("fire")
    GameState.unlock_ability("fire")
    assert_eq(GameState.get_ability_level("fire"), 3)
```

#### Phase 4 — Acceptance Criteria

```
[ ] All 5 ability scripts extend AbilityBase correctly
[ ] Locked abilities cannot be used (visual + debug feedback)
[ ] Unlocked abilities trigger effects on e (even if targets don't exist yet)
[ ] Fire: projectile launches, hits surfaces, particle effect visible
[ ] Ice: freeze effect applies, ice patch appears
[ ] Woodland: vine mesh spawns and grows
[ ] Dragon Taming: targeting beam works (no dragons yet)
[ ] Creature Speak: targeting works (no creatures yet)
[ ] Ability HUD shows all 5 slots, cooldowns, lock states
[ ] 1-5 keys switch abilities; LMB/RT activates
[ ] [DEBUG] shows ability use, cooldowns, level checks
[ ] All Phase 4 tests pass headless
```

---

## Phase 5 — NPCs & AI

**Goal:** Populate the world with creatures that use behavior trees, including basic cats, dragons, and speakable creatures.

**Depends on:** Phase 4

**IMPORTANT — Asset Gaps Expected:** NPC character models (anthropomorphic cats, dragons, birds, fish, mice) are the most likely asset gap in the project. The Asset Catalog (Section 7) has limited character model coverage. Follow the Placeholder Asset Policy (Section 7.9) rigorously in this phase:
- **Search first:** Before usi placeholder, search itch.io (CC0/CC-BY tag, 3D tag), Sketchfab (CC0 filter), and OpenGameArt for suitable character models. Log what you searched and what you found (or didn't) in `TO_RESOLVE.md`.
- **KayKit Adventurers Pack** has rigged humanoid characters that could serve as NPC base meshes if the art direction permits non-cat NPCs for some roles.
- **If nothing suitable is found:** Use magenta placeholder primitives (Section 7.9) and create a detailed `TO_RESOLVE.md` entry for each NPC type, specifying the model requirements (poly count, rig type, needed animations, style notes).
- Every NPC type gets its own `TO_RESOLVE.md` entry — don't batch them as "all NPC models."

### Tasks

#### 5.1 — Install BehaviourToolkit

- Install BehaviourToolkit addon
- Verify it loads without errors
- Create a simple test NPC with an idle behavior tree to validate

#### 5.2 — NPC Base Class

Create `res://scenes/npcs/npc_base.gd`:

- Extends CharacterBody3D
- Has an `npc_id: String` for save/load and quest references a `creature_type: String` (cat, dragon, bird, fish, mouse, etc.)
- Has a `can_speak: bool` — whether Creature Speak ability works on this NPC
- Has a `tamed: bool` state for Dragon Taming
- Integrates BehaviourToolkit for AI
- Default behavior tree: Idle → Wander → React to Player
- COGITO interactable component for basic interaction (talk)
- **Model handling:** The NPC base class should load its visual mesh from a configurable `model_scene` export var. This makes it trivial to swap placeholder mesh real models later — just change the export, no code changes needed.

**Debug output required:**
- Log state transitions (idle→wander→react→flee, etc.)
- Log player proximity events
- Log interaction events

#### 5.3 — Cat NPCs

- Friendly cats in the starting area
- Behavior: wander, approach player if nearby, interactable for dialogue
- Some cats give quests, some give lore/hints
- Visual: Search for CC0 cat model first. If not found, use `PH_` magenta capsule with Label3D and add entry to `TO_R.

#### 5.4 — Dragon NPCs

- Found in specific areas (dragon territory — Alpine Peaks and Foothills biomes)
- Behavior: patrol, aggressive if player approaches (unless tamed)
- Dragon Taming ability changes behavior to friendly/follow
- At ability level 3+: mountable (stretch goal — complex, can defer)
- Visual: Search for CC0 dragon/wyvern model first. If not found, use `PH_` orange capsule (larger than player) with Label3D and add entry to `TO_RESOLVE.md`.

#### 5.5 — Speakable Creatures

- Birds,ish scattered through the world per biome (birds everywhere, fish near water, mice in forest)
- Default: no interaction prompt (they're "just animals")
- With Creature Speak ability active: interaction prompt appears, opens dialogue
- Different creature types know different things (birds see far, mice know underground paths, fish know water secrets)
- Visual: Search for CC0 animal models. These are more commonly available than anthropomorphic characters. Check Kenney, KayKit, and OpenGameArt. Use `PH_` primitives as fallback (small spheres in species-appropriate colors).

#### Phase 5 — Acceptance Criteria

```
[ ] NPC base class works with BehaviourToolkit
[ ] NPC base class supports swappable model_scene export var
[ ] Cat NPCs wander, approach player, can be talked to
[ ] Dragon NPCs patrol, react aggressively to player approach
[ ] Dragon Taming ability changes dragon behavior to friendly
[ ] Speakable creatures show interaction prompt only when Creature Speak is active
[ ] All NPCs log state transitionvia [DEBUG]
[ ] NPCs persist state across save/load
[ ] Every placeholder NPC model has a TO_RESOLVE.md entry
[ ] All Phase 5 tests pass headless
```

---

## Phase 6 — Quests & Narrative

**Goal:** Main quest line (find the gem) and side quests functional with dialogue.

**Depends on:** Phase 5

### Tasks

#### 6.1 — Install Dialogue Manager 3

- Install from asset library
- Integrate with COGITO's interaction system
- Create test dialogue file and verify it plays when talking to an NPC

#### 6.2 — Mest: Find the Gem

Design the main quest as a chain:

1. **"Awakening"** — Player starts in a village; an elder cat explains the lore (the canonical lore text from Section 2). Player learns they have gem blood. Objective: talk to the elder.
2. **"First Steps"** — Elder directs player to find a clue about the gem's location. Objective: explore a nearby ruin and find a scroll.
3. **"The Five Trials"** — Each magic discipline has a trial/area. Completing each trial earns tuna coins and reveals part of ths location. (5 sub-quests, one per discipline.)
4. **"The Gem's Resting Place"** — All five clues combine to reveal the gem's location. Player travels there.
5. **"Restoration"** — Player finds the gem. Final sequence. `GameState.gem_found = true`.

For Phase 6, implement quests 1-2 fully. Quests 3-5 can be stubbed with placeholder content.

#### 6.3 — Side Quests

Create 2-3 simple side quests demonstrating different patterns:

- **Fetch quest:** NPC asks for an item → player finds it → return fon reward
- **Creature quest:** A speakable creature reveals a hidden location → player explores it → reward
- **Taming quest:** Tame a specific dragon → NPC rewards player

#### 6.4 — Dialogue Files

Write Dialogue Manager 3 `.dialogue` files for:

- Elder cat (main quest giver)
- 2-3 side quest NPCs
- 2-3 speakable creatures (unlocked via Creature Speak)
- Generic cat NPC ambient dialogue (2-3 variations)

The elder's initial dialogue MUST include the canonical lore text from Section 2, presented ader telling the player the story.

#### Phase 6 — Acceptance Criteria

```
[ ] Dialogue Manager 3 integrated with COGITO interactions
[ ] Elder cat dialogue plays canonical lore text
[ ] Main quest stages 1-2 completable
[ ] Main quest stages 3-5 stubbed (activatable but placeholder)
[ ] At least 2 side quests completable
[ ] Quest state persists across save/load
[ ] [DEBUG] shows quest state transitions, dialogue triggers
[ ] All Phase 6 tests pass headless
```

---

## Phase 7 — Mobile & Cross-Platfor*Goal:** Game runs on mobile with touch controls. Single codebase serves both platforms.

**Depends on:** Phase 6

### Tasks

#### 7.1 — Touch Control Overlay

Create `res://scenes/ui/touch_controls.tscn`:

- Virtual joystick (left side) for movement
- Touch drag (right side) for camera look
- Jump button (bottom right)
- Interact button (center right, appears contextually near interaction prompts)
- Ability buttons (bottom center, row of unlocked abilities)
- Menu button (top right)
- Auto-detected: contls show only on touch-capable devices

Implementation: Use Godot's `TouchScreenButton` or a custom `Control`-based virtual joystick. Ensure `InputEventScreenTouch` and `InputEventScreenDrag` are handled.

**Debug output required:**
- Log touch input events (joystick vector, button presses)
- Log platform detection (touch vs. desktop)

#### 7.2 — Responsive UI

- All COGITO UI elements (inventory, menus, prompts) must work at mobile resolutions
- Scale UI elements based on screen DPI
- Increase touch targesizes (minimum 48dp)
- Test at 1080×1920 (portrait) and 1920×1080 (landscape) — determine which orientation the game uses (recommendation: landscape)

#### 7.3 — Performance Optimization for Mobile

- Terrain3D LOD settings: more aggressive on mobile
- Reduce foliage density on mobile
- Sky3D: consider simplified sky shader for mobile
- Godot rendering: switch to `mobile` renderer for mobile exports
- Target: 30 FPS stable on mid-range devices

Use feature tags in project settings or runtime detectiongdscript
func _ready():
    if OS.has_feature("mobile"):
        # Apply mobile-specific settings
        RenderingServer.viewport_set_msaa_3d(get_viewport().get_viewport_rid(), RenderingServer.VIEWPORT_MSAA_DISABLED)
        # Reduce terrain detail, foliage density, etc.
        DebugLog.log("Platform", "mobile detected — applying performance settings")
    else:
        DebugLog.log("Platform", "desktop detected — full quality")
```

#### 7.4 — Export Presets

Set up export templates for:

- Windows64)
- Linux (x86_64)
- macOS (universal)
- Android (ARM64)
- iOS (ARM64)

#### Phase 7 — Acceptance Criteria

```
[ ] Touch controls visible and functional on mobile/touch devices
[ ] Touch controls hidden on desktop
[ ] Virtual joystick moves player correctly
[ ] Touch-drag rotates camera
[ ] All abilities usable via touch
[ ] UI readable and tappable at mobile resolutions
[ ] Game runs at 30+ FPS on mobile renderer
[ ] Export presets configured for all target platforms
[ ] [DEBUG] shows platform detecti, touch input events
```

---

## Phase 8 — Polish & Integration

**Goal:** Everything tied together, rough edges smoothed, ready for playtest.

**Depends on:** All previous phases

### Tasks

#### 8.1 — Audio

- Background music: ambient exploration music (different for day/night)
- Footstep sounds: vary by terrain type (grass, dirt, stone) — COGITO has footstep system
- Ability sound effects (fire whoosh, ice crack, vine grow, etc.)
- UI sounds (menu click, coin pickup, quest complete jingle)
- NPC t sounds (cat purrs, dragon growls, bird chirps)

#### 8.2 — Visual Polish

- Placeholder meshes replaced with actual models (or stylized low-poly)
- Particle effects refined for all abilities
- Terrain textures polished
- Skybox/atmosphere tuning in Sky3D
- Foliage variety (multiple grass types, flowers, bushes, trees)

#### 8.3 — World Building (Biome Expansion)

- Expand remaining biomes beyond Central Plains to full quality (vegetation, props, NPCs)
- Follow the biome definitions in Section 6.3 for  region
- Place landmarks, villages, quest locations, dragon territories per biome
- Populate with appropriate NPCs and interactables
- Ensure biome borders blend smoothly using Terrain3D texture painting

#### 8.4 — Placeholder Resolution Pass

- Review `TO_RESOLVE.md` for all outstanding items
- Replace as many `PH_` placeholder assets as possible with real assets
- For any remaining placeholders: ensure they don't appear in main quest-critical paths
- Update `TO_RESOLVE.md` status flags (move resolved ems to Resolved section)
- Update `ATTRIBUTION.md` for any newly imported replacement assets

#### 8.5 — Credits & Attribution Screen

- Add a "Credits" button to the main menu that opens a scrollable credits screen
- Parse `ATTRIBUTION.md` or maintain a parallel credits resource
- List all CC-BY attributions (legally required) prominently
- List CC0 attributions as a courtesy section ("Assets used under CC0 Public Domain")
- List all plugin authors and licenses
- Include the project team

#### 8.6 — Segs Menu

Extend COGITO's options menu:

- Mouse sensitivity slider
- Invert-Y toggle
- FOV slider (60-100)
- Head bob toggle
- Audio volume (master, music, SFX)
- Graphics quality preset (Low/Medium/High/Ultra)
- Touch control settings (joystick size, opacity)

#### 8.7 — Onboarding / Tutorial

- First 5 minutes guide the player through:
  1. Basic movement (WASD/joystick)
  2. Looking around
  3. Interacting with objects (E / tap)
  4. Talking to the elder (triggers lore)
  5. First coin pickup
  6. Openg the ability shrine
  7. First ability unlock
- Non-intrusive: contextual prompts, not a forced linear tutorial

#### 8.8 — Full Integration Test

Run through the entire game loop:

1. Start new game → spawn in village
2. Talk to elder → hear lore → accept quest
3. Explore → find coins → pick them up
4. Visit ability shrine → unlock an ability
5. Use ability in the world
6. Talk to NPCs → get side quests
7. Save game → quit → load game → verify all state
8. Test on mobile → touch coork
9. Complete main quest stages 1-2

#### Phase 8 — Acceptance Criteria

```
[ ] Audio plays for all major events (music, footsteps, abilities, UI)
[ ] All PH_ placeholder assets either replaced with real assets OR documented in TO_RESOLVE.md with 🟡 status
[ ] No placeholder meshes visible in main quest-critical paths (placeholders OK in optional/distant areas)
[ ] Settings menu fully functional
[ ] Credits/attribution screen accessible from main menu (lists all CC-BY and major CC0 attributions)
[ ] rial/onboarding guides new players
[ ] Full game loop completable without crashes
[ ] Save/load preserves everything
[ ] Mobile and desktop both playable
[ ] TO_RESOLVE.md reviewed — all 🔴 BLOCKING items resolved, remaining items are 🟡 or 🔵
[ ] ATTRIBUTION.md complete and accurate for all imported assets
[ ] No [DEBUG][ERROR] lines in output during full playthrough
```

---

## Appendix A — Debug Output Standard

This is the authoritative reference for debug output. All code in this project mushis standard.

### Prefix Format

```
[DEBUG] ComponentName: message with values
[DEBUG][ERROR] ComponentName: error description
```

### Required Debug Points by System

| System | What to Log |
|--------|-------------|
| Player Movement | State transitions (idle/walk/sprint/crouch/jump/fall), land events, speed values |
| Interactions | Raycast hits (target name, distance), interaction attempts (success/fail), prompt show/hide |
| Inventory | Item added/removed (item name, quantity), inventory full warnings |
| Tuna Coins | Pickup (position, value, new total), spend (purpose, new total) |
| Abilities | Use attempt (discipline, level, can_use result), cooldown start/end, effect spawn |
| NPC AI | State transitions (idle/wander/chase/flee/tamed), player proximity, interaction events |
| Quests | Quest start/complete, objective updates, reward grants |
| Save/Load | Save triggered (slot, data summary), load triggered (slot, data summary), errors |
| Day/Night | Time transitions (dawn/day/dusk/night), current game time (hourly) |
| Platform | Device detection (mobile/desktop), renderer selection, input mode changes |
| Terrain | Initialization (size, textures), height queries, collision setup |

### Anti-Patterns (Do NOT Do)

```gdscript
# BAD: per-frame spam with no state change check
func _physics_process(delta):
    print("[DEBUG] pos=%s" % global_position)  # Prints 60x/sec!

# GOOD: only log on state change
func _physics_process(delta):
    var new_on_floor := is_on_floor()
    if new_on_floor != _was_on_floor:
        DebugLog.log_state_change("Player", "is_on_floor", _was_on_floor, new_on_floor)
        _was_on_floor = new_on_floor
```

---

## Appendix B — Headless Testing Standard

### Test Naming Convention

- Test files: `test_<system>.gd` (e.g., `test_game_state.gd`)
- Test functions: `test_<what>_<expected>` (e.g., `test_unlock_ability_spends_coin`)
- Test classes extend `GutTest`

### Test Categories

| Directory | Purpose | Can Run Headless? |
|-----------|---------|-------------------|
| `tests/un/` | Pure logic tests (GameState, AbilityBase, math) | Yes — always |
| `tests/integration/` | Scene tests (player + terrain, NPC + dialogue) | Yes — with `--headless` flag |
| `tests/debug_test.gd` | Master test that exercises full game loop scripted | Yes — primary CI test |

### CI-Ready Command

```bash
#!/bin/bash
# run_tests.sh — Run all tests and report results
set -e

echo "=== Importing project ==="
godot --headless --import --quit

echo "=== Running unit tests ==="
godot --headless -d --pares://addons/gut/gut_cmdln.gd \
  -gdir=res://tests/unit -ginclude_subdirs -gexit

echo "=== Running integration tests ==="
godot --headless -d --path . -s res://addons/gut/gut_cmdln.gd \
  -gdir=res://tests/integration -ginclude_subdirs -gexit

echo "=== All tests passed ==="
```

---

## Appendix C — Agent Workflow Reference

### Quick Reference: What to Do First

When starting work on any phase:

1. **Read this PRD section** for the phase you're implementing
2. **Check plugin docs** — if a plugin is g installed, read its README/docs
3. **Check existing code** — `find res:// -name "*.gd"` to see what exists
4. **Check TO_RESOLVE.md** — see if any prior unresolved items affect this phase
5. **Implement incrementally** — one task at a time, test each before moving on
6. **Never skip testing** — the headless test loop is mandatory
7. **Update tracking docs** — add to `ATTRIBUTION.md` for every imported asset, add to `TO_RESOLVE.md` for every placeholder or decision point

### Common Gotchas

- **oloads:** COGITO registers its own autoloads. Don't create conflicting ones. Check `project.godot` after installing COGITO.
- **Terrain3D is a GDExtension (C++):** It must be compiled for the target platform. Download the correct binary. It won't work as a pure GDScript addon.
- **Sky3D + Terrain3D integration:** Both from Tokisan Games, designed to work together. Sky3D's DirectionalLight3D should be the scene's primary light source. Don't add a conflicting DirectionalLight3D.
- **GUT in headless mode requires import step:** Always run `godot --headless --import --quit` before running tests if you've added new resources.
- **Godot headless on WSL:** If running Godot headless from WSL2 with the Godot binary on Windows, use the Windows Godot path or a Linux build of Godot. The `--headless` flag eliminates the need for a display server.
- **Signal connection timing:** Autoloads initialize in order listed in `project.godot`. Ensure `SignalBus` loads before `GameState` (since GameState emits on SignalBus).
- **COGITO's save system:** Understand how COGITO saves before extending it. It uses scene persistency — objects in scenes must have persistence components. Custom global state (GameState) may need a separate save hook.
- **Placeholder assets (`PH_` prefix):** When you create a placeholder, you MUST also create a `TO_RESOLVE.md` entry in the same work session. Don't defer this. Use magenta (#FF00FF) for characters, cyan (#00FFFF) for props, yellow (#FFFF00) for VFX — these colors are deliberately ugly so placeers are impossible to miss visually.
- **ATTRIBUTION.md is append-only during development:** Never remove entries. If an asset is replaced, mark the old entry as `[REPLACED by <new asset>]` rather than deleting it, so there's an audit trail.
- **NPC model swapping:** The NPC base class uses an export var `model_scene` for its visual mesh. When a placeholder is eventually replaced, you only need to change this export — no code changes. Design all NPC logic to be mesh-independent.

### File Editing Tips forhe Agent

- Godot `.tscn` and `.tres` files are plain text — you can create and edit them directly
- `.tscn` format: `[gd_scene]` header, `[ext_resource]` for dependencies, `[node]` for scene tree
- `.tres` format: `[gd_resource]` header, then resource properties
- `project.godot` is an INI-like format — edit directly to add autoloads, input actions, project settings
- Always run syntax check after editing `.gd` files: `godot --check-only --script res://path/file.gd`

### Phase Dependency Graph

```
Pha (Setup)
    └── Phase 1 (Player Controller)
        └── Phase 2 (World)
            └── Phase 3 (Game Systems)
                └── Phase 4 (Abilities)
                    └── Phase 5 (NPCs)
                        └── Phase 6 (Quests)
                            └── Phase 7 (Mobile)
                                └── Phase 8 (Polish)
```

Each phase builds on the previous. Do not skip phases. Within a phase, tasks can sometimes be parallelized, but the numbered order is the recommended sequence.

---

*End of PRD — Mission Impawsible v1.0*

