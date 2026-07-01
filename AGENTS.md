# AGENTS.md

## Project
**Warping Woods** — Cooperative board game for 1–5 players.
- **Goal:** Defeat Bill the Warping Wizard before Round 24.
- **Engine:** Godot 4.7 (forward_plus).
- **Core Loop:** 12×12 tile board (4×4 blocks of 3×3). Warp at end of rounds 6, 12, 18.

## High-Signal Sources
- `booklet.md`: Canonical source for game rules and terminology.
- `implementation.md`: Canonical source for technical architecture and the 7-phase roadmap.
- `godot-docs/`: Local Godot 4 API reference.
- `skills/`: Project-specific GDScript and debugging patterns.

## Developer Commands
- **Parse Check (Headless):**
  `& "C:\Users\owner\Coding\godot\Godot_v4.7-stable_win64_console.exe" --headless --path "C:\Users\owner\Coding\warping-woods-oc" --quit`
- **Capture Errors:** `tools\capture_errors.bat`
- **Capture Screenshots:** `tools\capture_screenshots.bat` (Requires non-headless Godot)

## Technical Quirks & Constraints
- **Strict Typing:** Godot 4.7 inference (`var x := func()`) can cause parse errors. Use explicit types for variants.
- **GameManager:** Autoload. No `class_name` used to avoid conflict; access via `get_node("/root/GameManager")`.
- **UI Layout:** Viewport 1280×720. Board is centered; ActionPanel is right-anchored (PanelContainer) to avoid overlap.
- **Data:** Strictly JSON-driven for characters, blocks, and cards.
- **Warping:** Only blocks without characters are moved/rotated (Shielding).

## Implementation Roadmap
Currently in **Phase 3 (Encounter Cards)**.
- **Ph 0:** AI Harnesses [Done]
- **Ph 1:** The Map [Done]
- **Ph 2:** Characters & Turn Flow [Done]
- **Ph 3:** Encounter Cards [In Progress]
- **Ph 4:** Combat [TODO]
- **Ph 5:** Treasure Cards [TODO]
- **Ph 6:** Shopping & Trading [TODO]
- **Ph 7:** Boss Bill [TODO]

## Conventions
- **terminology:** `booklet.md` $\rightarrow$ **technical:** `implementation.md`.
- **No code** in `implementation.md`.
- Run parse check before every commit.

## Debugging

See `skills/debug.md` for the full 3-layer debugging workflow.

### Write → Debug → Fix Loop
1. Implement
2. Run Layer 1 + Layer 2 (and Layer 3 if GUT works)
3. Fix any errors found → go to step 2
4. When clean → commit
