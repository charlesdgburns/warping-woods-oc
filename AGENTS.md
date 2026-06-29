# AGENTS.md

## Project

**Warping Woods** — cooperative board game for 1–5 players, Godot 4.x. Currently pre-implementation: design docs exist, no game code yet.

## Key Files

- `booklet.md` — game rules, terminology, mechanics (canonical for game design questions)
- `implementation.md` — Godot architecture, data format, UI layout, implementation phases (canonical for code decisions)
- `project.godot` — Godot 4 project config (forward_plus renderer)

## Architecture (from implementation.md)

- **Data:** JSON files for cards (`resources/cards/`) and blocks (`resources/blocks/`), loaded at runtime into typed RefCounted objects
- **Autoloads:** GameManager, EventBus, ZoneManager, CardDatabase
- **State flow:** Input → GameManager → State Update → EventBus → UI
- **Board:** 4×4 grid of 3×3 blocks (144 tiles), pre-generated blocks moved/rotated during warping
- **Cards:** Two types only — `encounter` and `treasure`. Quests are encounter cards with `grant_quest` effects

## Current State

Step 1 (Block Generator) complete. 23 block JSONs in `resources/blocks/`: 3 hand-designed + 20 generated encounter blocks. Scripts exist for TileData, BlockData, BlockGenerator (@tool), standalone generator, and validation.

Step 2 (Board + Characters + Turns + Warping) complete. Main scene (main.tscn) with board, turn bar, action card (Move/Rest + End Turn), 5 character tokens. Click-to-move with highlighted valid tiles. Turn/round management with End Turn. Block warping at rounds 6/12/18. No Camera2D — board is static and centered.

Data classes: CharacterData, BoardState (with tile_type_grid for walkability lookups).
Scene scripts: GameBoard, BoardBlock, BoardTile, CharacterToken, ActionCard, ActionOption, TurnBar.
Autoload: GameManager (character loading, turn flow, move validation, warp execution).

## Reference

- `godot-docs/` — local Godot 4 documentation (git submodule from `godotengine/godot-docs`). Useful for API lookups during implementation.
- `skills/godot_dev.md` — quick reference for GDScript, nodes, signals, and project architecture patterns.
- `skills/debug.md` — debugging loop workflow, GUT test setup, error logging format.

## Conventions

- Game terminology is defined in `booklet.md`, not `implementation.md`
- Implementation details stay in `implementation.md`, not `booklet.md`
- Block and card data use JSON (editable outside Godot)
- No code in `implementation.md` — it's a design principles doc only
