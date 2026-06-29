# Warping Woods — Godot Implementation Guide

---

## 1. Project Overview

- **Engine:** Godot 4.x (forward_plus renderer)
- **Target:** Responsive resolution, no fixed size
- **Feel:** Table-top board game with cursor-based click controls (inspired by digital Catan)
- **Art:** Placeholder shapes/colours for now; real art later

---

## 2. Architecture Principles

### 2.1 Data vs. Presentation

Separate card data from card visuals:

- **JSON files:** Card definitions live in `resources/cards/<type>/<name>.json`. Fast to edit, easy to batch-edit in a spreadsheet.
- **`CardDatabase` autoload:** Loads all JSON at startup, creates typed `CardData` objects at runtime.
- **`Card` scene (Control):** Reusable visual scene that receives a `CardData` object and renders it.

This means cards can be defined in any text editor without opening Godot, then loaded into typed objects at runtime.

### 2.2 Signal-Driven Design

Cards emit signals (`card_played`, `card_hovered`, `card_clicked`, `card_discarded`). A central `GameManager` listens and applies rules. This decouples UI from game logic.

### 2.3 Scene Instancing

One Card scene, many instances — encounter deck, treasure deck, player inventories all use the same base scene with different data.

### 2.4 No Manual Positioning

All UI layout uses **Container nodes** with anchors. Never position UI elements manually via `position`. Reserve manual positioning only for drag previews and overlays.

---

## 3. UI Layout

```
┌─────────────────────────────────────────────────────────┐
│                     TURN BAR / CLOCK                    │
│    (analog clock)    │    [👤] [👤] [👤] [👤] [👤]      │
│                      │   (click → popup sheet)          │
├───────────────────────┬─────────────────────────────────┤
│                       │         DECK POOLS              │
│                       │   ┌───────────┬───────────┐     │
│                       │   │ Encounter │ Treasure  │     │
│      GAME BOARD       │   │   deck    │   deck    │     │
│   (Node2D + Camera    │   └───────────┴───────────┘     │
│    for pan/zoom)      │                                 │
│                       │       ┌─────────────────┐       │
│    ┌───┬───┬───┐      │       │   ACTION CARD    │      │
│    │   │   │   │      │       │ ┌─────┬─────┬─────┐│   │
│    ├───┼───┼───┤      │       │ │Move │Atk  │Esc  ││   │
│    │   │ ! │   │      │       │ ├─────┼─────┼─────┤│   │
│    ├───┼───┼───┤      │       │ │Trade│Item │Rest ││   │
│    │   │   │   │      │       │ └─────┴─────┴─────┘│   │
│    └───┴───┴───┘      │       └─────────────────┘     │
│                       │                                 │
├───────────────────────┴─────────────────────────────────┤
│              CURRENT PLAYER — CHARACTER SHEET           │
│  ┌────────────┬──────────────────────────────────────┐  │
│  │   STATS    │          INVENTORY (cards)           │  │
│  │  ┌──────┐  │  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐   │  │
│  │  │HP 10 │  │  │Item │ │Item │ │Item │ │Item │   │  │
│  │  │AP  5 │  │  └─────┘ └─────┘ └─────┘ └─────┘   │  │
│  │  │ATK  3│  │                                      │  │
│  │  │DEF  2│  │         Gold: 12                     │  │
│  │  │SPD  4│  │                                      │  │
│  │  └──────┘  │                                      │  │
│  └────────────┴──────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## 4. Scene Tree

```
Main (Node)
├── Board (Node2D)
│   ├── Camera2D
│   ├── Blocks (Node2D)
│   │   ├── Block_0_0 (Node2D)   — 3×3 tiles
│   │   ├── Block_0_1 (Node2D)
│   │   ├── ...
│   │   └── Block_3_3 (Node2D)
│   └── CharacterTokens (Node2D)
│       ├── Token_Char1 (Node2D)
│       ├── Token_Char2 (Node2D)
│       ├── ...
│       └── Token_Char5 (Node2D)
│
├── UI (CanvasLayer)
│   ├── TurnBar (HBoxContainer)              — top
│   │   ├── Clock (Control)                  — analog clock
│   │   └── CharacterIcons (HBoxContainer)   — clickable icons
│   │       ├── Icon_Char1 (Button)
│   │       ├── Icon_Char2 (Button)
│   │       ├── ...
│   │       └── Icon_Char5 (Button)
│   │
│   ├── RightPanel (VBoxContainer)           — right side
│   │   ├── DeckPools (HBoxContainer)
│   │   │   ├── EncounterDeck (PanelContainer)
│   │   │   └── TreasureDeck (PanelContainer)
│   │   └── ActionCard (GridContainer)       — 2×3 grid
│   │       ├── MoveOption (PanelContainer)
│   │       ├── AttackOption (PanelContainer)
│   │       ├── EscapeOption (PanelContainer)
│   │       ├── TradeOption (PanelContainer)
│   │       ├── UseItemOption (PanelContainer)
│   │       └── RestOption (PanelContainer)
│   │
│   ├── BottomPanel (Control)                — bottom
│   │   └── CharacterSheet (HBoxContainer)
│   │       ├── StatsPanel (VBoxContainer)
│   │       └── InventoryPanel (HBoxContainer)
│   │
│   └── CharacterPopup (PopupPanel)          — overlay
│       └── CharacterSheet (instance)
│
├── CardFocusPopup (Popup)                   — zoomed card overlay
│
└── GameManager (Node)                       — autoload, game logic
```

---

## 5. Board Implementation

### 5.1 Node Structure

The board is a `Node2D` containing all tiles and character tokens. A `Camera2D` child provides pan and zoom.

### 5.2 Placeholder Tiles

Each tile is a `ColorRect` or `Polygon2D`:

| Tile Type | Colour | Notes |
|-----------|--------|-------|
| Walkable | Light blue `#87CEEB` | Standard movement tile |
| Unwalkable (terrain) | Brown `#8B4513` | Impassable |
| Encounter | Green `#228B22` | Has encounter token overlay |
| Summoning Block | Light green `#90EE90` | Starting position |
| Shop Block | Yellow `#FFD700` | Buy items |
| Warp Wizard Block | Purple `#800080` | Bill's location |
| Character token | Red/Blue/etc. | Circle or pawn shape |

### 5.3 Camera Pan/Zoom

```gdscript
# Board.gd — attached to Board (Node2D)
# Camera2D is a child of this node

var zoom_speed := 0.1
var min_zoom := 0.3
var max_zoom := 3.0
var is_panning := false
var pan_start := Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
    # Zoom with mouse wheel
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            $Camera2D.zoom += Vector2.ONE * zoom_speed
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            $Camera2D.zoom -= Vector2.ONE * zoom_speed
        $Camera2D.zoom = $Camera2D.zoom.clamp(
            Vector2(min_zoom, min_zoom),
            Vector2(max_zoom, max_zoom)
        )

    # Pan with middle mouse button
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_MIDDLE:
            is_panning = event.pressed
            pan_start = event.position
    if event is InputEventMouseMotion and is_panning:
        $Camera2D.position -= (event.position - pan_start)
        pan_start = event.position
```

### 5.4 Block Construction

Each block is a `Node2D` scene containing 9 tile children in a 3×3 arrangement. Tile positions are local offsets within the block:

```gdscript
# Block.gd
const TILE_SIZE := 64
const TILE_GAP := 0  # no gap between tiles

func _ready() -> void:
    for row in range(3):
        for col in range(3):
            var tile: ColorRect = preload("res://scenes/tile.tscn").instantiate()
            tile.position = Vector2(col * TILE_SIZE, row * TILE_SIZE)
            add_child(tile)
```

---

## 6. Turn Bar & Clock

### 6.1 Analog Clock

A custom `Control` node that draws an analog clock face:

- **24 hours = 24 rounds**
- Clock hand rotates clockwise, completing one full rotation over 24 rounds
- Current round highlighted on the clock rim
- Warp rounds (6, 12, 18) marked with special indicators
- Final round (24) marked as "midnight"

```gdscript
# Clock.gd — attached to Clock (Control)

var current_round := 0
const MAX_ROUNDS := 24

func _draw() -> void:
    # Draw clock face (circle)
    var center := size / 2
    var radius := min(size.x, size.y) / 2 - 4
    draw_circle(center, radius, Color(0.2, 0.2, 0.2))
    draw_arc(center, radius, 0, TAU, 64, Color.WHITE, 2.0)

    # Draw hour markers (24 positions)
    for i in range(MAX_ROUNDS):
        var angle := (float(i) / MAX_ROUNDS) * TAU - PI / 2
        var inner := center + Vector2(cos(angle), sin(angle)) * (radius - 10)
        var outer := center + Vector2(cos(angle), sin(angle)) * radius
        draw_line(inner, outer, Color.WHITE, 1.0)

    # Draw hand
    var hand_angle := (float(current_round) / MAX_ROUNDS) * TAU - PI / 2
    var hand_end := center + Vector2(cos(hand_angle), sin(hand_angle)) * (radius - 15)
    draw_line(center, hand_end, Color.RED, 3.0)

func advance_round() -> void:
    current_round += 1
    queue_redraw()
```

### 6.2 Character Icons

A row of 5 buttons (one per character). Each shows a placeholder coloured circle with the character's initial. Clicking opens the character popup.

```gdscript
# CharacterIcons.gd

signal character_icon_clicked(character_id: int)

func _ready() -> void:
    for i in range(5):
        var btn := Button.new()
        btn.text = str(i + 1)
        btn.custom_minimum_size = Vector2(40, 40)
        btn.pressed.connect(func(): character_icon_clicked.emit(i))
        add_child(btn)
```

### 6.3 Character Popup

A `PopupPanel` that shows a read-only view of a character's sheet and inventory. Triggered by clicking a character icon.

```gdscript
# CharacterPopup.gd

func show_character(character_id: int) -> void:
    var char_data = GameManager.get_character(character_id)
    # Populate the sheet with character_data stats and inventory
    popup_centered(Vector2(400, 300))
```

---

## 7. Action Card

### 7.1 Layout

A `GridContainer` with 3 columns and 2 rows, styled as a single game card:

```
┌─────────────────────────────────────┐
│          ⚔️  ACTION CARD  ⚔️         │
├─────────────┬─────────────┬─────────┤
│    MOVE     │   ATTACK    │  ESCAPE │
├─────────────┼─────────────┼─────────┤
│    TRADE    │  USE ITEM   │   REST  │
└─────────────┴─────────────┴─────────┘
```

### 7.2 Action Option Node

Each cell is a `PanelContainer` with:
- A `TextureRect` for the icon (placeholder)
- A `Label` for the action name
- Visual states controlled by `modulate`

```gdscript
# ActionOption.gd — attached to each option PanelContainer

@onready var icon: TextureRect = $Icon
@onready var label: Label = $Label

var is_valid := false

func set_valid(valid: bool) -> void:
    is_valid = valid
    if valid:
        modulate = Color.WHITE
        mouse_filter = Control.MOUSE_FILTER_STOP
    else:
        modulate = Color(0.4, 0.4, 0.4)  # greyed out
        mouse_filter = Control.MOUSE_FILTER_IGNORE
```

### 7.3 Action Card Manager

The ActionCard node re-evaluates valid actions on every game state change:

```gdscript
# ActionCard.gd — attached to ActionCard (GridContainer)

@onready var move_option: PanelContainer = $MoveOption
@onready var attack_option: PanelContainer = $AttackOption
@onready var escape_option: PanelContainer = $EscapeOption
@onready var trade_option: PanelContainer = $TradeOption
@onready var item_option: PanelContainer = $UseItemOption
@onready var rest_option: PanelContainer = $RestOption

func update_actions(state: Dictionary) -> void:
    move_option.set_valid(state.get("can_move", false))
    attack_option.set_valid(state.get("can_attack", false))
    escape_option.set_valid(state.get("can_escape", false))
    trade_option.set_valid(state.get("can_trade", false))
    item_option.set_valid(state.get("can_use_item", false))
    rest_option.set_valid(state.get("can_rest", false))
```

### 7.4 Valid Action Rules

| Action | Valid When |
|--------|-----------|
| **Move** | Not in combat, has remaining speed, not resting |
| **Attack** | Character is in combat |
| **Escape** | Character is in combat |
| **Trade** | Another character on same tile, not in combat |
| **Use Item** | Character has usable items, not in combat |
| **Rest** | Not in combat, has not moved this turn |

---

## 8. Card System

### 8.1 CardData Resource

```gdscript
# card_data.gd
class_name CardData extends Resource

enum CardType { ENCOUNTER, TREASURE, QUEST, ITEM, COMPANION }

@export var card_name: String
@export var card_type: CardType
@export var description: String
@export var icon: Texture2D
@export var is_hostile: bool = false       # for encounter cards
@export var creature_hp: int = 0          # for hostile encounters
@export var creature_attack: int = 0
@export var creature_defence: int = 0
@export var gold_value: int = 0
@export var quest_item_id: String = ""    # for quest cards
@export var quest_reward: String = ""
```

### 8.2 Card Scene

```
Card (Control or PanelContainer)
├── MarginContainer
│   └── VBoxContainer
│       ├── TopRow (HBoxContainer)
│       │   ├── CardName (Label)
│       │   └── CardType (Label)
│       ├── CardIcon (TextureRect)
│       └── Description (RichTextLabel)
```

### 8.3 Card Interaction

**Hover (Tween zoom):**
```gdscript
# Card.gd

var original_scale := Vector2.ONE
var hover_scale := Vector2(1.3, 1.3)
var tween: Tween

func _on_mouse_entered() -> void:
    if tween and tween.is_valid():
        tween.kill()
    tween = create_tween()
    tween.tween_property(self, "scale", hover_scale, 0.15)\
        .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
    z_index = 10

func _on_mouse_exited() -> void:
    if tween and tween.is_valid():
        tween.kill()
    tween = create_tween()
    tween.tween_property(self, "scale", original_scale, 0.15)\
        .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
    z_index = 0
```

**Click to Focus (popup with enlarged card):**
```gdscript
# CardFocusPopup.gd

func show_card(card_data: CardData) -> void:
    var focus_card: Control = preload("res://scenes/card.tscn").instantiate()
    focus_card.set_data(card_data)
    focus_card.scale = Vector2(2.0, 2.0)  # enlarged
    add_child(focus_card)
    popup_centered(Vector2(400, 560))
```

**Drag-and-Drop:**
```gdscript
# Card.gd

func _get_drag_data(at_position: Vector2) -> Variant:
    var preview := duplicate()
    preview.modulate = Color(1, 1, 1, 0.7)
    preview.scale = Vector2(1.2, 1.2)
    set_drag_preview(preview)
    return self

# On drop targets (inventory, trade zone):
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
    return data is Card

func _drop_data(at_position: Vector2, data: Variant) -> void:
    var card: Card = data as Card
    GameManager.trade_card(card, owner_character, target_character)
```

---

## 9. Character Sheet (Bottom Panel)

### 9.1 Layout

```
┌──────────────────────────────────────────────────────┐
│  CURRENT PLAYER — CHARACTER SHEET                   │
├──────────────┬───────────────────────────────────────┤
│    STATS     │            INVENTORY                  │
│  ┌────────┐  │  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐   │
│  │ HP: 10 │  │  │Item │ │Item │ │Item │ │Item │   │
│  │ AP:  5 │  │  └─────┘ └─────┘ └─────┘ └─────┘   │
│  │ ATK: 3 │  │                                      │
│  │ DEF: 2 │  │  Gold: 12                            │
│  │ SPD: 4 │  │                                      │
│  └────────┘  │                                      │
└──────────────┴───────────────────────────────────────┘
```

### 9.2 Stats Panel

A `VBoxContainer` with `Label` nodes for each stat. Updated whenever stats change.

### 9.3 Inventory Panel

An `HBoxContainer` holding card instances. Cards are draggable. Gold displayed as a label with an icon.

---

## 10. Deck Management

### 10.1 Deck Pools

Two deck areas on the right panel:

| Deck | Cards | Trigger |
|------|-------|---------|
| **Encounter Deck** | Hostile + Neutral encounter cards | Player lands on encounter tile |
| **Treasure Deck** | Loot cards | Defeating a creature |

### 10.2 Deck Logic

```gdscript
# Deck.gd

var cards: Array[CardData] = []
var discard: Array[CardData] = []

func shuffle() -> void:
    cards.shuffle()

func draw() -> CardData:
    if cards.is_empty():
        # Reshuffle discard into deck
        cards = discard.duplicate()
        discard.clear()
        cards.shuffle()
    return cards.pop_back()

func add_to_discard(card: CardData) -> void:
    discard.append(card)
```

### 10.3 Drawing Animation

When a card is drawn, it animates from the deck position to the target area (hand, action card area, or inventory) using a `Tween`.

---

## 11. Key Godot Nodes Reference

| Element | Node Type | Notes |
|---------|-----------|-------|
| Game root | `Node` | Main scene |
| Board | `Node2D` | Contains tiles and tokens |
| Camera | `Camera2D` | Pan/zoom |
| Tiles | `ColorRect` | Placeholder rectangles |
| Blocks | `Node2D` | 3×3 tile groups |
| Character tokens | `Node2D` | Coloured circles/pawns |
| UI root | `CanvasLayer` | Draws above the board |
| Turn bar | `HBoxContainer` | Clock left, icons right |
| Clock | Custom `Control` | Analog face via `_draw()` |
| Character icons | `Button` | Clickable, opens popup |
| Right panel | `VBoxContainer` | Deck pools + action card |
| Deck pools | `HBoxContainer` | Encounter + treasure decks |
| Action card | `GridContainer` | 2×3 grid of action options |
| Action option | `PanelContainer` | Icon + label, modulate for state |
| Bottom panel | `Control` | Character sheet |
| Character sheet | `HBoxContainer` | Stats left, inventory right |
| Stats panel | `VBoxContainer` | HP, AP, ATK, DEF, SPD labels |
| Inventory panel | `HBoxContainer` | Draggable card instances |
| Card scene | `PanelContainer` | Reusable card with CardData |
| Card popup | `Popup` | Enlarged card focus view |
| Character popup | `PopupPanel` | Read-only character sheet |
| Drag preview | `CanvasLayer` | Above all UI during drag |
| Game manager | `Node` (autoload) | All game logic and state |

---

## 12. Implementation Phases

Suggested build order — each phase produces a testable milestone:

| Phase | Deliverable | Est. Complexity |
|-------|------------|----------------|
| **1** | Board layout: 16 blocks, 144 placeholder tiles, Camera2D pan/zoom | Low |
| **2** | Character tokens on the board, basic movement (click to move) | Low |
| **3** | Turn bar with analog clock, turn advancement | Medium |
| **4** | Card system: CardData class, JSON loader, Card scene, render from data | Medium |
| **5** | Card interaction: hover zoom, click focus popup | Medium |
| **6** | Card drag-and-drop between zones | Medium |
| **7** | Action card with valid action highlighting | Medium |
| **8** | Character sheet (bottom panel), stats display, inventory | Medium |
| **9** | Deck management: shuffle, draw, discard, reshuffle | Low |
| **10** | ZoneManager: single card ownership, card movement tracking | Medium |
| **11** | EventBus: cross-system signal bus | Low |
| **12** | GameManager: autoload, round/turn flow, game state machine | High |
| **13** | BoardState: block grid, tile positions, character positions | Medium |
| **14** | Encounter system: land on tile, draw card, resolve | High |
| **15** | CardEffect system: damage, heal, gain_gold, gain_item | Medium |
| **16** | Quest system: grant_quest, ConditionalEffect, auto-completion | High |
| **17** | Combat: turn-based, dice rolls, multi-character | High |
| **18** | Trading between characters | Low |
| **19** | Shop, gold, items | Medium |
| **20** | Warping: block shuffle, rotate, token reset | High |
| **21** | Revival at Summoning Block | Low |
| **22** | Bill encounter & win/lose conditions | High |
| **23** | Polish: animations, sound, visual feedback | Medium |

---

## 13. File Structure (Planned)

```
warping-woods-oc/
├── project.godot
├── booklet.md
├── implementation.md
├── images/
│   └── booklet/
│       └── board.png (user-provided)
├── scenes/
│   ├── main.tscn
│   ├── board.tscn
│   ├── tile.tscn
│   ├── block.tscn
│   ├── character_token.tscn
│   ├── card.tscn
│   ├── action_card.tscn
│   ├── action_option.tscn
│   ├── character_sheet.tscn
│   ├── clock.tscn
│   └── character_popup.tscn
├── scripts/
│   ├── board.gd
│   ├── camera_controller.gd
│   ├── block.gd
│   ├── tile.gd
│   ├── character_token.gd
│   ├── card.gd
│   ├── card_data.gd
│   ├── card_effect.gd
│   ├── damage_effect.gd
│   ├── heal_effect.gd
│   ├── gain_gold_effect.gd
│   ├── gain_item_effect.gd
│   ├── quest_effect.gd
│   ├── conditional_effect.gd
│   ├── on_defeat_effect.gd
│   ├── action_card.gd
│   ├── action_option.gd
│   ├── clock.gd
│   ├── deck.gd
│   ├── character_sheet.gd
│   ├── character_popup.gd
│   ├── card_focus_popup.gd
│   ├── game_manager.gd
│   ├── event_bus.gd
│   ├── zone_manager.gd
│   └── card_database.gd
├── resources/
│   ├── cards/
│   │   ├── encounters/
│   │   │   ├── warped_wolf.json
│   │   │   ├── friendly_hermit.json
│   │   │   └── ...
│   │   └── treasures/
│   │       ├── health_potion.json
│   │       └── ...
│   └── characters/
│       ├── char_01.tres
│       └── ...
└── themes/
    └── default_theme.tres
```

---

## 14. World State Architecture

### 14.1 Autoload Singletons

The game uses multiple focused autoloads rather than one "god object":

| Autoload | Responsibility | Has State? |
|----------|---------------|------------|
| **GameManager** | Round/turn flow, character data, game rules, warp logic | Yes — owns authoritative game state |
| **EventBus** | All cross-system signals | No — pure signal bus, no state |
| **ZoneManager** | Card ownership tracking (which zone each card is in) | Yes — card location registry |
| **CardDatabase** | Loads all card JSON, provides lookup by name | Yes — card definitions |

### 14.2 Data Flow

```
Player Input → UI → GameManager → State Update → EventBus → UI Update
```

**Key principle:** Update all logical state first, then emit signals for UI animations. Never let UI animations block or delay the state update.

### 14.3 Signal Bus (EventBus)

```gdscript
# event_bus.gd — autoload, no state, only signals

# Board events
signal card_moved(card_id: StringName, from_zone: StringName, to_zone: StringName)
signal encounter_triggered(character_id: int, tile_pos: Vector2i)
signal creature_defeated(creature_id: StringName)
signal warp_started(warp_number: int)
signal warp_completed

# Turn events
signal turn_started(character_id: int)
signal turn_ended(character_id: int)
signal round_started(round_number: int)
signal round_ended(round_number: int)

# Character events
signal character_damaged(character_id: int, amount: int)
signal character_healed(character_id: int, amount: int)
signal character_defeated(character_id: int)
signal character_revived(character_id: int)
signal character_moved(character_id: int, tile_pos: Vector2i)

# UI events
signal action_selected(action: StringName)
signal card_hovered(card_id: StringName)
signal card_clicked(card_id: StringName)
signal state_changed(new_state: GameState)
```

---

## 15. Board State Management

### 15.1 BoardState (RefCounted)

Runtime board state — lightweight, mutable, not saved as `.tres`:

```gdscript
# board_state.gd
class_name BoardState extends RefCounted

# 4×4 grid — each cell holds a block_id (StringName) or &""
var block_grid: Array[Array] = []

# block_id → rotation in degrees (0, 90, 180, 270)
var block_rotations: Dictionary = {}

# Vector2i (tile coords) → bool (true = encounter token present)
var encounter_tokens: Dictionary = {}

# character_id → Vector2i (global tile coordinates)
var character_positions: Dictionary = {}

func _init() -> void:
    # Initialize empty 4×4 grid
    for row in range(4):
        var grid_row: Array = []
        for col in range(4):
            grid_row.append(&"")
        block_grid.append(grid_row)
```

### 15.2 BlockData (Resource)

Block definitions — created once, never changed:

```gdscript
# block_data.gd
class_name BlockData extends Resource

enum BlockType { SUMMONING, SHOP, WARP_WIZARD, ENCOUNTER }

@export var block_id: StringName
@export var block_type: BlockType
@export var tiles: Array[TileData] = []
```

### 15.3 TileData (Resource)

Individual tile definitions within a block:

```gdscript
# tile_data.gd
class_name TileData extends Resource

enum TileType { WALKABLE, UNWALKABLE, ENCOUNTER }

@export var tile_type: TileType
@export var local_position: Vector2i  # 0–2, 0–2 within the block
@export var has_encounter_token: bool = false
```

### 15.4 Warping Logic

```gdscript
# In GameManager

func execute_warp() -> void:
    var unshielded: Array[StringName] = []
    var shielded: Array[StringName] = []

    # 1. Identify shielded vs unshielded blocks
    for row in range(4):
        for col in range(4):
            var block_id: StringName = board_state.block_grid[row][col]
            if block_id == &"":
                continue
            if _is_block_shielded(block_id):
                shielded.append(block_id)
            else:
                unshielded.append(block_id)

    # 2. Shuffle unshielded blocks
    unshielded.shuffle()

    # 3. Rebuild grid: shielded blocks stay, unshielded fill remaining slots
    _rebuild_grid(shielded, unshielded)

    # 4. Randomly rotate each unshielded block
    for block_id in unshielded:
        board_state.block_rotations[block_id] = [0, 90, 180, 270].pick_random()

    # 5. Restore encounter tokens on warped blocks
    for block_id in unshielded:
        _restore_encounter_tokens(block_id)

    EventBus.warp_completed.emit()

func _is_block_shielded(block_id: StringName) -> bool:
    # A block is shielded if any character stands on it
    for char_id in board_state.character_positions:
        var char_tile: Vector2i = board_state.character_positions[char_id]
        var char_block := _tile_to_block(char_tile)
        if char_block == block_id:
            return true
    return false
```

---

## 16. Player Token System

### 16.1 Token Scene

Player tokens are visual representations only. The authoritative position lives in `BoardState.character_positions`.

```
CharacterToken (Node2D)
├── Sprite2D (placeholder circle)
├── Label (character initial)
└── Tween (for movement animation)
```

### 16.2 Movement

```gdscript
# character_token.gd
extends Node2D

@export var character_id: int
var tween: Tween

func move_to(target_tile: Vector2i) -> void:
    # Update authoritative state
    GameManager.board_state.character_positions[character_id] = target_tile

    # Animate visual movement
    var target_pos := _tile_to_pixel(target_tile)
    if tween and tween.is_valid():
        tween.kill()
    tween = create_tween()
    tween.tween_property(self, "position", target_pos, 0.3)\
        .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

    EventBus.character_moved.emit(character_id, target_tile)
```

### 16.3 Movement Validation

```gdscript
func can_move_to(character_id: int, target_tile: Vector2i) -> bool:
    var current_tile: Vector2i = board_state.character_positions[character_id]
    var distance := _manhattan_distance(current_tile, target_tile)
    var speed: int = get_character(character_id).speed
    return distance <= speed and _is_walkable(target_tile)
```

---

## 17. Card Zone Management

### 17.1 Single Ownership

Every card exists in exactly **one zone** at a time. The `ZoneManager` is the single source of truth.

**Zones:**

| Zone Name | Description |
|-----------|-------------|
| `encounter_deck` | Face-down encounter cards |
| `treasure_deck` | Face-down treasure cards |
| `encounter_discard` | Resolved encounter cards |
| `treasure_discard` | Resolved treasure cards |
| `hand_<character_id>` | Character's inventory |
| `trade` | Mid-trade between characters |
| `in_play` | Active card (e.g., ongoing hostile encounter) |

### 17.2 ZoneManager

```gdscript
# zone_manager.gd — autoload
extends Node

signal card_moved(card_id: StringName, from_zone: StringName, to_zone: StringName)

var _card_zones: Dictionary = {}  # card_id → zone_name

func move_card(card_id: StringName, to_zone: StringName) -> bool:
    var from_zone: StringName = _card_zones.get(card_id, &"")
    if from_zone == to_zone:
        return false
    if from_zone == &"":
        push_warning("Card %s not registered in any zone" % card_id)
        return false

    # Atomic: update state, then emit
    _card_zones[card_id] = to_zone
    card_moved.emit(card_id, from_zone, to_zone)
    return true

func get_cards_in_zone(zone: StringName) -> Array[StringName]:
    var result: Array[StringName] = []
    for card_id in _card_zones:
        if _card_zones[card_id] == zone:
            result.append(card_id)
    return result

func get_card_zone(card_id: StringName) -> StringName:
    return _card_zones.get(card_id, &"")
```

### 17.3 Trade Atomicity

```gdscript
func trade_card(card_id: StringName, from_id: int, to_id: int) -> bool:
    var from_zone := "hand_%d" % from_id
    var to_zone := "hand_%d" % to_id

    if _card_zones.get(card_id) != from_zone:
        return false

    # Atomic state update
    _card_zones[card_id] = to_zone

    # Emit single signal
    card_moved.emit(card_id, from_zone, to_zone)
    return true
```

---

## 18. State Transitions & Atomicity

### 18.1 Game State Enum

```gdscript
enum GameState {
    SETUP,
    PLAYER_TURN,
    ENCOUNTER,
    COMBAT,
    CREATURE_TURN,
    WARPING,
    GAME_OVER
}
```

### 18.2 Turn Flow

```
SETUP → PLAYER_TURN → (ENCOUNTER → COMBAT)* → CREATURE_TURN → PLAYER_TURN
                                                      ↓
                                                  WARPING (at rounds 6/12/18)
                                                      ↓
                                                  PLAYER_TURN
                                                      ↓
                                              GAME_OVER (round 24)
```

### 18.3 Atomic Transaction Pattern

All state changes follow this order:

1. **Validate** preconditions (is this action legal?)
2. **Update** all logical state (board_state, card_zones, character_stats)
3. **Emit** signals via EventBus (UI listens and animates)
4. **Never** let UI animation delay or block the state update

```gdscript
func resolve_encounter(character_id: int, encounter_card: CardData) -> void:
    # 1. Validate
    assert(current_state == GameState.ENCOUNTER)

    # 2. Update state
    if encounter_card.is_hostile:
        _enter_combat(character_id, encounter_card)
        current_state = GameState.COMBAT
    else:
        _apply_neutral_effect(character_id, encounter_card)
        _move_card_to_zone(encounter_card.card_id, "hand_%d" % character_id)
        current_state = GameState.PLAYER_TURN

    # 3. Emit signals
    EventBus.encounter_resolved.emit(character_id, encounter_card)
    EventBus.state_changed.emit(current_state)
```

---

## 19. Card Data (JSON)

### 19.1 Directory Structure

```
resources/
└── cards/
    ├── encounters/
    │   ├── warped_wolf.json
    │   ├── friendly_hermit.json
    │   └── ...
    └── treasures/
        ├── health_potion.json
        ├── gold_coins.json
        └── ...
```

### 19.2 JSON Schema

**Encounter card (`resources/cards/encounters/warped_wolf.json`):**

```json
{
  "name": "Warped Wolf",
  "type": "encounter",
  "description": "A snarling beast with glowing eyes.",
  "is_hostile": true,
  "creature_hp": 8,
  "creature_attack": 3,
  "creature_defence": 1,
  "reward_gold": 5,
  "effects": [
    {
      "type": "on_defeat",
      "then": [
        { "type": "gain_gold", "value": 5 }
      ]
    }
  ]
}
```

**Neutral encounter card (`resources/cards/encounters/friendly_hermit.json`):**

```json
{
  "name": "Friendly Hermit",
  "type": "encounter",
  "description": "An old man who offers healing.",
  "is_hostile": false,
  "effects": [
    {
      "type": "heal",
      "value": 3,
      "target": "self"
    }
  ]
}
```

**Quest card (`resources/cards/encounters/wolf_head_quest.json`):**

```json
{
  "name": "Wolf Head Quest",
  "type": "encounter",
  "description": "Bring back the head of the Warped Wolf.",
  "is_hostile": false,
  "effects": [
    {
      "type": "grant_quest",
      "quest_id": "wolf_head",
      "quest_item": "Warped Wolf Head",
      "quest_reward": "Enchanted Sword",
      "condition": {
        "check": "card_not_in_zone",
        "card_name": "Warped Wolf Head",
        "zone": "encounter_deck"
      },
      "on_complete": [
        { "type": "gain_item", "item_id": "enchanted_sword" }
      ]
    }
  ]
}
```

**Treasure card (`resources/cards/treasures/health_potion.json`):**

```json
{
  "name": "Health Potion",
  "type": "treasure",
  "description": "Restores 5 HP when consumed.",
  "gold_value": 0,
  "is_usable": true,
  "effects": [
    {
      "type": "heal",
      "value": 5,
      "target": "self"
    }
  ]
}
```

### 19.3 Field Reference

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Card display name |
| `type` | string | Yes | `"encounter"` or `"treasure"` |
| `description` | string | Yes | Card text |
| `is_hostile` | bool | No | Whether the encounter is a fight |
| `creature_hp` | int | No | Creature HP (hostile only) |
| `creature_attack` | int | No | Creature attack (hostile only) |
| `creature_defence` | int | No | Creature defence (hostile only) |
| `reward_gold` | int | No | Gold gained on defeat |
| `gold_value` | int | No | Gold value if sold |
| `is_usable` | bool | No | Can be used from inventory |
| `effects` | array | Yes | Array of effect objects |

---

## 20. CardDatabase Autoload

```gdscript
# card_database.gd — autoload
extends Node

signal cards_loaded

var cards: Dictionary = {}  # card_name -> CardData

func _ready() -> void:
    _load_cards_from_dir("res://resources/cards/encounters")
    _load_cards_from_dir("res://resources/cards/treasures")
    cards_loaded.emit()

func _load_cards_from_dir(path: String) -> void:
    var dir := DirAccess.open(path)
    if not dir:
        push_error("Cannot open directory: " + path)
        return
    dir.list_dir_begin()
    var file_name := dir.get_next()
    while file_name != "":
        if file_name.ends_with(".json"):
            _load_card(path + "/" + file_name)
        file_name = dir.get_next()
    dir.list_dir_close()

func _load_card(file_path: String) -> void:
    var file := FileAccess.open(file_path, FileAccess.READ)
    if not file:
        push_error("Cannot open file: " + file_path)
        return
    var json := JSON.new()
    var error := json.parse(file.get_as_text())
    if error != OK:
        push_error("JSON parse error in %s: %s" % [file_path, json.get_error_message()])
        return
    var data: Dictionary = json.data

    var card := CardData.new()
    card.card_name = data.get("name", "Unknown")
    card.card_type = CardData.CardType[data.get("type", "encounter").to_upper()]
    card.description = data.get("description", "")
    card.is_hostile = data.get("is_hostile", false)
    card.creature_hp = data.get("creature_hp", 0)
    card.creature_attack = data.get("creature_attack", 0)
    card.creature_defence = data.get("creature_defence", 0)
    card.reward_gold = data.get("reward_gold", 0)
    card.gold_value = data.get("gold_value", 0)
    card.is_usable = data.get("is_usable", false)

    # Parse effects
    var effects: Array = data.get("effects", [])
    for effect_dict in effects:
        var effect := _parse_effect(effect_dict)
        if effect:
            card.effects.append(effect)

    cards[card.card_name] = card

func _parse_effect(dict: Dictionary) -> CardEffect:
    match dict.get("type", ""):
        "damage":
            return DamageEffect.new(dict.get("value", 0), dict.get("target", "enemy"))
        "heal":
            return HealEffect.new(dict.get("value", 0), dict.get("target", "self"))
        "gain_gold":
            return GainGoldEffect.new(dict.get("value", 0))
        "gain_item":
            return GainItemEffect.new(dict.get("item_id", ""))
        "grant_quest":
            return QuestEffect.new(dict)
        "conditional":
            return ConditionalEffect.new(dict)
        "on_defeat":
            return OnDefeatEffect.new(dict.get("then", []))
        _:
            push_warning("Unknown effect type: " + dict.get("type", ""))
            return null

func get_card(card_name: String) -> CardData:
    return cards.get(card_name, null)

func get_all_cards() -> Array[CardData]:
    return cards.values()
```

---

## 21. CardEffect System

### 21.1 Base Effect Class

```gdscript
# card_effect.gd
class_name CardEffect extends RefCounted

func apply(game_state: Dictionary, source: CardData, target_entity: Node) -> void:
    push_warning("Base apply() called — override in child class")
```

### 21.2 Concrete Effect Types

**DamageEffect:**
```gdscript
# damage_effect.gd
class_name DamageEffect extends CardEffect

var value: int
var target: String  # "enemy", "self", "all_allies"

func _init(dmg: int = 0, tgt: String = "enemy") -> void:
    value = dmg
    target = tgt

func apply(game_state: Dictionary, source: CardData, target_entity: Node) -> void:
    if target_entity.has_method("take_damage"):
        target_entity.take_damage(value)
```

**HealEffect:**
```gdscript
# heal_effect.gd
class_name HealEffect extends CardEffect

var value: int
var target: String  # "self", "ally"

func _init(amt: int = 0, tgt: String = "self") -> void:
    value = amt
    target = tgt

func apply(game_state: Dictionary, source: CardData, target_entity: Node) -> void:
    if target_entity.has_method("heal"):
        target_entity.heal(value)
```

**GainGoldEffect:**
```gdscript
# gain_gold_effect.gd
class_name GainGoldEffect extends CardEffect

var value: int

func _init(amt: int = 0) -> void:
    value = amt

func apply(game_state: Dictionary, source: CardData, target_entity: Node) -> void:
    if target_entity.has_method("add_gold"):
        target_entity.add_gold(value)
```

**GainItemEffect:**
```gdscript
# gain_item_effect.gd
class_name GainItemEffect extends CardEffect

var item_id: String

func _init(id: String = "") -> void:
    item_id = id

func apply(game_state: Dictionary, source: CardData, target_entity: Node) -> void:
    var item_card: CardData = CardDatabase.get_card(item_id)
    if item_card:
        ZoneManager.move_card(item_card.card_name, "hand_%d" % target_entity.character_id)
```

**OnDefeatEffect:**
```gdscript
# on_defeat_effect.gd
class_name OnDefeatEffect extends CardEffect

var then_effects: Array[CardEffect]

func _init(then: Array = []) -> void:
    then_effects = []
    for effect_dict in then:
        var effect := CardDatabase._parse_effect(effect_dict)
        if effect:
            then_effects.append(effect)

func apply(game_state: Dictionary, source: CardData, target_entity: Node) -> void:
    for effect in then_effects:
        effect.apply(game_state, source, target_entity)
```

**QuestEffect:**
```gdscript
# quest_effect.gd
class_name QuestEffect extends CardEffect

var quest_id: String
var quest_item: String
var quest_reward: String
var condition: ConditionalEffect
var on_complete_effects: Array[CardEffect]

func _init(data: Dictionary = {}) -> void:
    quest_id = data.get("quest_id", "")
    quest_item = data.get("quest_item", "")
    quest_reward = data.get("quest_reward", "")
    var cond_dict: Dictionary = data.get("condition", {})
    if not cond_dict.is_empty():
        condition = ConditionalEffect.new(cond_dict)
    on_complete_effects = []
    for effect_dict in data.get("on_complete", []):
        var effect := CardDatabase._parse_effect(effect_dict)
        if effect:
            on_complete_effects.append(effect)

func apply(game_state: Dictionary, source: CardData, target_entity: Node) -> void:
    # Register quest as active
    game_state.active_quests[quest_id] = {
        "card": source,
        "owner": target_entity.character_id,
        "condition": condition,
        "rewards": on_complete_effects
    }

func check_completion(game_state: Dictionary) -> bool:
    if condition:
        return condition.check(game_state)
    return false
```

**ConditionalEffect:**
```gdscript
# conditional_effect.gd
class_name ConditionalEffect extends CardEffect

var condition_check: String   # "card_not_in_zone", "card_in_zone", "player_on_tile"
var condition_card: String
var condition_zone: String

func _init(data: Dictionary = {}) -> void:
    condition_check = data.get("check", "")
    condition_card = data.get("card_name", "")
    condition_zone = data.get("zone", "")

func check(game_state: Dictionary) -> bool:
    match condition_check:
        "card_not_in_zone":
            var cards_in_zone: Array = ZoneManager.get_cards_in_zone(condition_zone)
            return condition_card not in cards_in_zone
        "card_in_zone":
            var cards_in_zone: Array = ZoneManager.get_cards_in_zone(condition_zone)
            return condition_card in cards_in_zone
        "player_on_tile":
            var pos: Vector2i = game_state.get("current_player_position", Vector2i.ZERO)
            return pos == condition_tile
        _:
            return false

func apply(game_state: Dictionary, source: CardData, target_entity: Node) -> void:
    # ConditionalEffect doesn't apply directly — it's used by QuestEffect
    pass
```

---

## 22. Quest Completion Check

Quests are checked on every game state change (card moved, zone updated):

```gdscript
# In GameManager

func _on_card_moved(card_id: StringName, from_zone: StringName, to_zone: StringName) -> void:
    _check_quest_completions()

func _check_quest_completions() -> void:
    var completed: Array[StringName] = []
    for quest_id in active_quests:
        var quest: QuestEffect = active_quests[quest_id].condition
        if quest.check_completion(get_game_state()):
            _complete_quest(quest_id)
            completed.append(quest_id)
    for quest_id in completed:
        active_quests.erase(quest_id)

func _complete_quest(quest_id: String) -> void:
    var quest_data: Dictionary = active_quests[quest_id]
    var rewards: Array[CardEffect] = quest_data.rewards
    var owner_id: int = quest_data.owner
    var owner: Node = get_character_node(owner_id)

    for effect in rewards:
        effect.apply(get_game_state(), quest_data.card, owner)

    EventBus.quest_completed.emit(quest_id, owner_id)
```

---

## 23. Data Workflow

### 23.1 Prototyping Phase

1. Write card JSON files in any text editor
2. Place in `resources/cards/<type>/`
3. Run the game — `CardDatabase` autoloads and loads all JSON
4. Cards are immediately available as typed `CardData` objects

### 23.2 Iteration

- Edit JSON → restart game (no hot-reload for JSON)
- Or add a debug key to call `CardDatabase._ready()` to reload

### 23.3 Production

- Cards are playtested and balanced
- JSON files are the source of truth
- No need to migrate to `.tres` — JSON loads into typed objects at runtime
