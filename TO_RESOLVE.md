# Mission Impawsible — Items Requiring Resolution

> This file is maintained by the coding agent. Each entry represents a placeholder,
> missing asset, design decision, or blocker that needs human input.
>
> **Status key:** 🔴 BLOCKING (can't proceed without this) | 🟡 PLACEHOLDER (functional but needs real asset) | 🔵 DECISION (needs human input on direction)
>
> When you resolve an item, delete it from this file or move it to the ## Resolved section at the bottom.

## Unresolved

### BUG-001 — Sky3D GDExtension not functional 🔴 BLOCKING
- **Phase:** 2/8
- **Description:** Sky3D plugin (TokisanGames/Sky3D) is a GDExtension that requires a compiled native library (`.so`/`.dll`). The GDScript wrapper and plugin config are installed, but no compiled binary exists for Godot 4.6. The `Sky3D`, `TimeOfDay`, and `SkyDome` classes are unregistered at runtime, causing instantiation errors.
- **Current workaround:** Replaced GDExtension node types with plain `Node3D`/`Node` placeholders in `world.tscn`. Sun/moon `DirectionalLight3D` nodes still provide basic lighting. `sky_bridge.gd` gracefully skips when Sky3D is unavailable.
- **Impact:** No dynamic day/night cycle, no atmospheric sky rendering. The game uses Godot's default sky instead.
- **Options:** (A) Build Sky3D from source for Godot 4.6 (B) Use a GDScript-based sky shader alternative (C) Implement a simple day/night cycle with Godot's built-in `ProceduralSkyMaterial` and a time-driven script (D) Wait for an official Sky3D release targeting Godot 4.6
- **Files affected:** `scenes/world/world.tscn`, `scenes/world/sky_bridge.gd`, `addons/sky_3d/`

### PH-NPC-001 — Cat NPC Model 🟡 PLACEHOLDER
- **Phase:** 5
- **Description:** Cat NPCs (elder_cat, village_cat_1, village_cat_2) use magenta capsule placeholders
- **Requirements:** Low-poly anthropomorphic or quadruped cat model, ~2000 polys, rigged for walk/idle/talk animations, CC0 or CC-BY 4.0
- **Searched:** Sketchfab (CC0 filter, "cat low poly"), itch.io (CC0+3D tags), OpenGameArt ("cat model"), KayKit packs — no suitable anthropomorphic cat models found
- **Impact:** Visual only — gameplay works with placeholders

### PH-NPC-002 — Dragon NPC Model 🟡 PLACEHOLDER
- **Phase:** 5
- **Description:** Dragon NPCs (dragon_1, dragon_2) use orange capsule placeholders (larger than player)
- **Requirements:** Low-poly dragon/wyvern model, ~3000-5000 polys, rigged for walk/fly/idle/attack animations, CC0 or CC-BY 4.0
- **Searched:** Sketchfab (CC0, "dragon low poly"), itch.io, OpenGameArt, KayKit — no suitable CC0 dragon model found
- **Impact:** Visual only — taming mechanic works with placeholders

### PH-NPC-003 — Bird Creature Model 🟡 PLACEHOLDER
- **Phase:** 5
- **Description:** Bird creatures (bird_1) use sky-blue sphere placeholders
- **Requirements:** Low-poly bird model, ~500 polys, simple hop/fly animation, CC0 or CC-BY 4.0
- **Searched:** Kenney Nature Kit (no birds), KayKit (no birds), OpenGameArt — some options exist but unclear licensing
- **Impact:** Visual only

### PH-NPC-004 — Mouse Creature Model 🟡 PLACEHOLDER
- **Phase:** 5
- **Description:** Mouse creatures (mouse_1) use brown sphere placeholders
- **Requirements:** Low-poly mouse/rat model, ~500 polys, scurry/idle animation, CC0 or CC-BY 4.0
- **Searched:** Same sources as bird — no suitable CC0 mouse model found
- **Impact:** Visual only

### PH-NPC-005 — Fish Creature Model 🟡 PLACEHOLDER
- **Phase:** 5
- **Description:** Fish creatures (fish_1) use blue sphere placeholders
- **Requirements:** Low-poly fish model, ~300 polys, swim animation, CC0 or CC-BY 4.0
- **Searched:** Same sources — no suitable standalone fish model found
- **Impact:** Visual only



## Resolved

### DEC-001 — Art Style Direction 🔵 DECISION
- **Phase:** 2
- **Question:** Should the game use a consistent low-poly style (matching KayKit/Kenney assets) or aim for a more realistic look (using Poly Haven scans)? Mixing styles will look jarring.
- **Options:** (A) Commit to low-poly stylized — use KayKit/Kenney exclusively (B) Commit to realistic — need different asset sources for everything (C) Stylized terrain + low-poly models (common indie approach)
- **Current assumption:** Option C — stylized terrain textures with low-poly KayKit models
- **Impact:** Affects every asset decision going forward
- **Resolution:** Option C — stylized terrain textures with low-poly KayKit models
