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

No scenes, scripts, or assets exist yet. `images/booklet/` is empty. The `.gitignore` covers Godot exports, `.godot/`, and `*.import`.

## Reference

- `godot-docs/` — local Godot 4 documentation (git submodule from `godotengine/godot-docs`). Useful for API lookups during implementation.
- `skills/godot_dev.md` — quick reference for GDScript, nodes, signals, and project architecture patterns.

## Conventions

- Game terminology is defined in `booklet.md`, not `implementation.md`
- Implementation details stay in `implementation.md`, not `booklet.md`
- Block and card data use JSON (editable outside Godot)
- No code in `implementation.md` — it's a design principles doc only
