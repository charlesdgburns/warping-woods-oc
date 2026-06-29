# Warping Woods — Godot Implementation Guide

> **Note:** For game terminology (encounters, quests, warping, combat, characters, etc.), consult `booklet.md`. This document covers Godot implementation principles and architecture.

---

# PART 1: OVERVIEW & PRINCIPLES

---

## 1. Project Overview

- **Engine:** Godot 4.x (forward_plus renderer)
- **Target:** Responsive resolution, no fixed size
- **Feel:** Table-top board game with cursor-based click controls (inspired by digital Catan)
- **Art:** Placeholder shapes/colours for now; real art later

---

## 2. Architecture Principles

### 2.1 Data vs. Presentation

- **JSON files:** Card and block definitions live in `resources/cards/<type>/<name>.json` and `resources/blocks/<name>.json`. Fast to edit, easy to batch-edit in a spreadsheet.
- **`CardDatabase` autoload:** Loads all card JSON at startup, creates typed `CardData` objects at runtime.
- **`BlockDatabase` (or Board setup):** Loads all block JSON at game start, creates `BlockData` objects.
- **`Card` scene (Control):** Reusable visual scene that receives a `CardData` object and renders it.

Cards and blocks are defined in any text editor without opening Godot, then loaded into typed objects at runtime.

### 2.2 Signal-Driven Design

Systems communicate via signals through a central `EventBus`. Cards emit `card_hovered`, `card_clicked`, `card_discarded`. GameManager listens and applies rules. This decouples UI from game logic.

### 2.3 Scene Instancing

One Card scene, many instances — encounter deck, treasure deck, player inventories all use the same base scene with different data.

### 2.4 No Manual Positioning

All UI layout uses **Container nodes** with anchors. Never position UI elements manually via `position`. Reserve manual positioning only for drag previews and overlays.

### 2.5 Single Ownership

Every card exists in exactly **one zone** at a time. The `ZoneManager` is the single source of truth. Cards are never moved by visual nodes directly — they request a move through the central authority.

### 2.6 Atomic State Changes

All state changes follow this order:
1. **Validate** preconditions (is this action legal?)
2. **Update** all logical state (board_state, card_zones, character_stats)
3. **Emit** signals via EventBus (UI listens and animates)

---

## 3. Autoloads & Singletons

The game uses multiple focused autoloads rather than one "god object":

| Autoload | Responsibility | Has State? |
|----------|---------------|------------|
| **GameManager** | Round/turn flow, character data (loads/saves all 5 characters), game rules, warp logic | Yes |
| **EventBus** | All cross-system signals | No — pure signal bus |
| **ZoneManager** | Card ownership tracking (which zone each card is in) | Yes |
| **CardDatabase** | Loads all card JSON, provides lookup by name | Yes |

### 3.1 Data Flow

```
Player Input → UI → GameManager → State Update → EventBus → UI Update
```

### 3.2 EventBus Signals

| Signal | Parameters | When Emitted |
|--------|-----------|--------------|
| `card_moved` | card_id, from_zone, to_zone | A card changes zone |
| `card_drawn` | card_id, drawn_by | A card is drawn from a deck |
| `encounter_triggered` | character_id, tile_pos | Player lands on encounter tile |
| `encounter_resolved` | character_id, card | Encounter fully resolved |
| `creature_defeated` | creature_id | Hostile creature HP reaches 0 |
| `warp_started` | warp_number | Warp begins |
| `warp_completed` | — | Warp finishes |
| `turn_started` | character_id | Character's turn begins |
| `turn_ended` | character_id | Character's turn ends |
| `round_started` | round_number | New round begins |
| `round_ended` | round_number | Round ends |
| `character_damaged` | character_id, amount | Character takes damage |
| `character_healed` | character_id, amount | Character is healed |
| `character_defeated` | character_id | Character HP reaches 0 |
| `character_revived` | character_id | Character is revived |
| `character_moved` | character_id, tile_pos | Character token moves |
| `quest_started` | quest_id, owner_id | Quest accepted |
| `quest_completed` | quest_id, owner_id | Quest condition met |
| `action_selected` | action_name | Player clicks an action |
| `card_hovered` | card_id | Mouse enters a card |
| `card_clicked` | card_id | Card is clicked |
| `card_discarded` | card_id, zone | Card discarded (from hand or equipment) |
| `card_equipped` | card_id, character_id | Card equipped to character |
| `card_unequipped` | card_id, character_id | Card unequipped from character |
| `hand_full` | character_id | Character's hand is full (7 cards) |
| `state_changed` | new_state | GameManager state changes |

### 3.3 Game States

The GameManager tracks the following states:

| State | Description |
|-------|-------------|
| **SETUP** | Game not yet started |
| **PLAYER_TURN** | A character is taking their turn |
| **ENCOUNTER** | Encounter card being resolved |
| **COMBAT** | Character is fighting a creature |
| **CREATURE_TURN** | Creature takes its turn (after all characters) |
| **WARPING** | Board is warping (end of rounds 6/12/18) |
| **GAME_OVER** | Round 24 ended, Bill undefeated |

### 3.4 Turn Flow

```
SETUP → PLAYER_TURN → (ENCOUNTER → COMBAT)* → CREATURE_TURN → PLAYER_TURN
                                                      ↓
                                                  WARPING (at rounds 6/12/18)
                                                      ↓
                                                  PLAYER_TURN
                                                      ↓
                                              GAME_OVER (round 24)
```

---

# PART 2: DATA LAYER

---

## 4. Card Data

### 4.1 CardData Fields

CardData is `RefCounted` — lightweight, JSON-loaded at runtime:

| Field | Type | Description |
|-------|------|-------------|
| `card_id` | StringName | Unique identifier (snake_case) |
| `card_name` | String | Display name |
| `card_type` | CardType | `ENCOUNTER` or `TREASURE` |
| `description` | String | Card text |
| `icon` | Texture2D | Card art (placeholder initially) |
| `is_hostile` | bool | Whether the encounter is a fight |
| `creature_hp` | int | Creature HP (hostile encounters only) |
| `creature_attack` | int | Creature attack (hostile encounters only) |
| `creature_defence` | int | Creature defence (hostile encounters only) |
| `reward_gold` | int | Gold gained on defeat |
| `gold_value` | int | Gold value if sold |
| `is_usable` | bool | Can be used from inventory |
| `effects` | Array[CardEffect] | Array of effect objects |
| `equip_slot` | String | *(Treasure only)* Equipment slot: `"weapon"`, `"armor"`, `"headgear"`, `"footgear"`, `"accessory"`, or `""` (consumable) |
| `hand_slots_needed` | int | *(Treasure only)* Number of hand slots occupied when equipped: `1` (default) or `2` (two-handed weapons) |
| `class_restriction` | String | *(Treasure only)* Class required to equip, or `""` (any) |
| `character_restriction` | int | *(Treasure only)* Specific character ID required, or `0` (any) |

### 4.2 JSON Format

Cards are stored in `resources/cards/<type>/<name>.json`. Each card has an `id`, `name`, `type`, `description`, and an `effects` array.

**Hostile encounter example:**

| Field | Value |
|-------|-------|
| id | `warped_wolf` |
| name | `Warped Wolf` |
| type | `encounter` |
| description | `A snarling beast with glowing eyes.` |
| is_hostile | `true` |
| creature_hp | `8` |
| creature_attack | `3` |
| creature_defence | `1` |
| reward_gold | `5` |
| effects | `[{ type: "on_defeat", then: [{ type: "gain_gold", value: 5 }] }]` |

**Neutral encounter example:**

| Field | Value |
|-------|-------|
| id | `friendly_hermit` |
| name | `Friendly Hermit` |
| type | `encounter` |
| description | `An old man who offers healing.` |
| is_hostile | `false` |
| effects | `[{ type: "heal", value: 3, target: "self" }]` |

**Encounter card with quest effect:**

| Field | Value |
|-------|-------|
| id | `wolf_head_quest` |
| name | `Wolf Head Quest` |
| type | `encounter` |
| description | `Bring back the head of the Warped Wolf.` |
| is_hostile | `false` |
| effects | `[{ type: "grant_quest", quest_id: "wolf_head", quest_item: "warped_wolf_head", quest_reward: "Enchanted Sword", condition: { check: "card_not_in_zone", card_name: "warped_wolf_head", zone: "encounter_deck" }, on_complete: [{ type: "gain_item", item_id: "enchanted_sword" }] }]` |

**Treasure card example (equippable):**

| Field | Value |
|-------|-------|
| id | `iron_shield` |
| name | `Iron Shield` |
| type | `treasure` |
| description | `A sturdy shield that blocks incoming attacks.` |
| gold_value | `3` |
| is_usable | `false` |
| equip_slot | `weapon` |
| hand_slots_needed | `1` |
| class_restriction | `warrior` |
| effects | `[{ type: "gain_stat", stat: "defence", value: 2 }]` |

### 4.3 Treasure Card Equipment Rules

Treasure cards are **uniquely equippable** — only one copy of a given treasure can be equipped at a time. Equipment has the following restrictions:

| Restriction | Description | Example |
|-------------|-------------|---------|
| **Equip slot** | Where the item is worn. A character can only have one item per slot (except `weapon` which has 2 slots and `accessory` which has 2 slots). | `"weapon"` — can equip 2 one-handed or 1 two-handed |
| **Hand slots** | Two-handed weapons (`hand_slots_needed: 2`) occupy both weapon hand slots. One-handed weapons (`hand_slots_needed: 1`) occupy one. | `"weapon"` with `hand_slots_needed: 2` |
| **Class restriction** | Only characters of the specified class can equip. | `"armor"` class can wear heavy armour |
| **Character restriction** | Only a specific character can equip (by ID). | A unique legendary item |

If `equip_slot` is empty (`""`), the treasure is a **consumable** (e.g., health potion) — it is used once and discarded.

**Equipment slot counts per character:**

| Slot | Count | Notes |
|------|-------|-------|
| `armor` | 1 | Body armour |
| `weapon` | 2 hand slots | Two-handed weapons use both; one-handed use one |
| `headgear` | 1 | Helmets, hoods |
| `footgear` | 1 | Boots, greaves |
| `accessory` | 2 | Rings, amulets, cloaks |

**Total: 7 equipment slots per character.**

### 4.4 Field Reference

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique identifier (snake_case) |
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
| `equip_slot` | string | No | Equipment slot: `"weapon"`, `"armor"`, `"headgear"`, `"footgear"`, `"accessory"`, or `""` (treasure only) |
| `hand_slots_needed` | int | No | Hand slots occupied when equipped: 1 or 2 (treasure only) |
| `class_restriction` | string | No | Required class (treasure only) |
| `character_restriction` | int | No | Required character ID (treasure only) |

---

## 5. CardDatabase Autoload

The CardDatabase is an autoload that loads all card JSON files at startup. It scans `resources/cards/encounters/` and `resources/cards/treasures/`, parses each JSON file, and creates `CardData` objects with their effects parsed into typed `CardEffect` objects.

**Responsibilities:**
- Load all JSON card files on `_ready()`
- Parse effect dictionaries into typed `CardEffect` instances
- Provide `get_card(card_id)` for lookup by ID
- Provide `get_all_cards()` to get all loaded cards

**Effect parsing** maps the `"type"` field in each effect dictionary to the corresponding effect class:

| Effect type string | Effect class |
|-------------------|-------------|
| `"damage"` | DamageEffect |
| `"heal"` | HealEffect |
| `"gain_gold"` | GainGoldEffect |
| `"gain_item"` | GainItemEffect |
| `"gain_stat"` | GainStatEffect |
| `"draw_card"` | DrawCardEffect |
| `"grant_quest"` | QuestEffect |
| `"conditional"` | ConditionalEffect |
| `"on_defeat"` | OnDefeatEffect |

---

## 6. CardEffect System

### 6.1 Base Effect

All effects extend a base `CardEffect` class. Effects read directly from GameManager and ZoneManager singletons — no state parameter needed.

### 6.2 Effect Types

| Effect | Parameters | Description |
|--------|-----------|-------------|
| **DamageEffect** | `value: int`, `target: String` (`"enemy"`, `"self"`, `"all_allies"`) | Deals damage to target |
| **HealEffect** | `value: int`, `target: String` (`"self"`, `"ally"`) | Restores HP |
| **GainGoldEffect** | `value: int` | Adds gold to character |
| **GainItemEffect** | `item_id: String` | Adds a card to character's hand (or discard if hand full) |
| **GainStatEffect** | `stat: String`, `value: int` | Temporarily or permanently modifies a stat |
| **DrawCardEffect** | `deck: String` (`"encounter"`, `"treasure"`), `count: int` | Draws cards from a deck |
| **OnDefeatEffect** | `then: Array` | Executes child effects when creature is defeated |
| **QuestEffect** | `quest_id`, `quest_item`, `quest_reward`, `condition`, `on_complete` | Registers a quest and checks completion |
| **ConditionalEffect** | `check: String`, `card_name`, `zone`, `tile` | Evaluates a condition (used by QuestEffect) |

---

## 7. Quest System

### 7.1 Quest Lifecycle

1. **Accept:** A neutral encounter card with a `grant_quest` effect is drawn
2. **Register:** QuestEffect registers the quest in GameManager's `active_quests` dictionary
3. **Hand:** The quest card is added to the character's hand (counts toward 7-card hand limit)
3. **Condition:** A ConditionalEffect specifies when the quest is complete (e.g., "card_not_in_zone" checks if a specific card has left the encounter deck)
4. **Check:** On every card movement (via `card_moved` signal), GameManager checks all active quests for completion
5. **Complete:** When the condition is met, rewards are applied and `quest_completed` is emitted

### 7.2 Condition Types

| Condition | Checks | Example |
|-----------|--------|---------|
| `card_not_in_zone` | A specific card is NOT in the specified zone | Quest item has been acquired (left encounter deck) |
| `card_in_zone` | A specific card IS in the specified zone | Required card is in a player's hand |
| `player_on_tile` | The quest owner is on a specific tile | Return to a location |

### 7.3 Quest Data Structure

Each active quest is stored as a dictionary in `GameManager.active_quests`:

| Key | Type | Description |
|-----|------|-------------|
| `card` | CardData | The encounter card that started the quest |
| `owner` | int | Character ID of the quest holder |
| `condition` | ConditionalEffect | The completion condition |
| `rewards` | Array[CardEffect] | Effects applied on completion |

---

## 8. Character Data

### 8.1 CharacterData Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `id` | int | — | Unique character identifier |
| `character_name` | String | — | Display name |
| `character_class` | String | — | Class (e.g., `"warrior"`, `"rogue"`) |
| `lore` | String | — | Backstory text |
| `max_hp` | int | 10 | Maximum health |
| `hp` | int | 10 | Current health |
| `max_ap` | int | 5 | Maximum ability points |
| `ap` | int | 5 | Current ability points |
| `attack` | int | 3 | Attack stat |
| `defence` | int | 2 | Defence stat |
| `speed` | int | 4 | Movement steps per turn |
| `gold` | int | 0 | Currency |
| `hand` | Array[CardData] | `[]` | Cards in hand (max 7). Includes quest cards, unequipped treasures, consumables |
| `equipment` | EquipmentSlots | new | Equipped items (7 slots total) |
| `active_quests` | Array[String] | `[]` | Active quest IDs |

### 8.2 EquipmentSlots

Each character has 7 equipment slots:

```gdscript
class_name EquipmentSlots
extends RefCounted

var armor: CardData                    # 1 slot — body armour
var hands: Array[CardData]             # 2 slots — weapons (one-handed: 1 slot, two-handed: 2 slots)
var headgear: CardData                 # 1 slot — helmets, hoods
var footgear: CardData                 # 1 slot — boots, greaves
var accessories: Array[CardData]       # 2 slots — rings, amulets, cloaks
```

**Methods:**

| Method | Description |
|--------|-------------|
| `equip(card)` | Equips card to correct slot. Returns `true` on success, `false` if slot full or incompatible |
| `unequip(card)` | Removes card from equipment (caller must add to hand) |
| `get_occupied_slots()` | Returns total number of occupied equipment slots |
| `get_free_weapon_slots()` | Returns number of free hand slots (0, 1, or 2) |
| `can_equip_weapon(card)` | Returns `true` if enough hand slots are free for this weapon |
| `is_two_handed(card)` | Returns `true` if `card.hand_slots_needed == 2` |

**Equip logic for weapons:**
1. Check if weapon is one-handed (`hand_slots_needed: 1`) or two-handed (`hand_slots_needed: 2`)
2. If one-handed: requires 1 free hand slot
3. If two-handed: requires 2 free hand slots (player must manually discard/unequip items in hand slots first)

### 8.3 Character Methods

| Method | Description |
|--------|-------------|
| `is_defeated()` | Returns true if HP is 0 |
| `take_damage(amount)` | Reduces HP, emits `character_defeated` if 0 |
| `heal(amount)` | Restores HP up to max |
| `add_gold(amount)` | Adds gold |
| `spend_gold(amount)` | Returns true and deducts if affordable |
| `rest()` | Regenerates AP *(amount TBD)* |
| `is_hand_full()` | Returns `true` if hand has 7 cards |
| `draw_to_hand(card)` | Adds card to hand; if hand full, card goes to discard instead |

### 8.4 Character Loading

Characters are loaded from JSON files in `resources/characters/<name>.json`. Each file defines the character's base stats, lore, and class. At game startup, a `CharacterLoader` (or GameManager) scans the directory, parses each JSON, and creates `CharacterData` objects with starting HP/AP set to their max values.

**JSON format:**

```json
{
  "id": 1,
  "name": "Serra",
  "class": "warrior",
  "lore": "Once captain of the King's Guard...",
  "stats": {
    "max_hp": 14,
    "max_ap": 3,
    "attack": 4,
    "defence": 4,
    "speed": 3
  },
  "gold": 0,
  "abilities": []
}
```

The `abilities` array will be populated as character abilities are designed (TBD).

---

# PART 3: GAME STATE

---

## 9. GameManager

The GameManager is the central autoload that owns all authoritative game state.

### 9.1 Responsibilities

- Track current round (1–24) and current character turn
- Manage game state machine (SETUP → PLAYER_TURN → ENCOUNTER → COMBAT → CREATURE_TURN → WARPING → GAME_OVER)
- Hold the `BoardState` instance
- Hold `active_quests` dictionary
- Provide `get_valid_actions(character_id)` for the action card
- Execute warping logic

### 9.2 Action Validation

The `get_valid_actions` method returns a dictionary of which actions are currently available for a character:

| Action | Valid When |
|--------|-----------|
| **Move** | Not in combat, has remaining speed, not resting |
| **Attack** | Character is in combat |
| **Escape** | Character is in combat |
| **Trade** | Another character on same tile, not in combat |
| **Use Item** | Character has usable items, not in combat |
| **Rest** | Not in combat, has not moved this turn |

### 9.3 Round Advancement

- `advance_round()` increments the round counter, emits `round_started`
- If the round is 6, 12, or 18, triggers `execute_warp()`
- If round exceeds 24, sets state to `GAME_OVER`

### 9.4 Turn Advancement

- `next_turn()` emits `turn_ended` for current character, advances to next character index, emits `turn_started`
- Turn order is sequential through the character array

---

## 10. Board State

### 10.1 BoardState Fields

The BoardState is a `RefCounted` object that tracks the current state of the game board:

| Field | Type | Description |
|-------|------|-------------|
| `block_grid` | Array[Array] | 4×4 grid, each cell holds a block_id (StringName) or `""` |
| `block_rotations` | Dictionary | block_id → rotation in degrees (0, 90, 180, 270) |
| `encounter_tokens` | Dictionary | Vector2i (tile coords) → bool (token present) |
| `character_positions` | Dictionary | character_id → Vector2i (global tile coordinates) |

### 10.2 BlockData Fields

Block definitions — created once, never changed:

| Field | Type | Description |
|-------|------|-------------|
| `block_id` | StringName | Unique block identifier |
| `block_type` | BlockType | `SUMMONING`, `SHOP`, `WARP_WIZARD`, or `ENCOUNTER` |
| `tiles` | Array[TileData] | 9 tiles in 3×3 arrangement |

### 10.3 TileData Fields

Individual tile definitions within a block:

| Field | Type | Description |
|-------|------|-------------|
| `tile_type` | TileType | `WALKABLE`, `UNWALKABLE`, or `ENCOUNTER` |
| `local_position` | Vector2i | Position within block (0–2, 0–2) |
| `has_encounter_token` | bool | Whether an encounter token is placed |

### 10.4 Block Generation

Blocks are **pre-generated** and stored as JSON files in `resources/blocks/`. The tile layout within each block does not change at runtime — blocks are only moved and rotated during warping.

#### Block Data Format

Each block is a JSON file:

```json
{
  "id": "encounter_01",
  "type": "encounter",
  "tiles": [
    { "type": "walkable",  "pos": [0, 0] },
    { "type": "unwalkable","pos": [1, 0] },
    { "type": "walkable",  "pos": [2, 0] },
    { "type": "walkable",  "pos": [0, 1] },
    { "type": "encounter", "pos": [1, 1] },
    { "type": "walkable",  "pos": [2, 1] },
    { "type": "walkable",  "pos": [0, 2] },
    { "type": "unwalkable","pos": [1, 2] },
    { "type": "walkable",  "pos": [2, 2] }
  ]
}
```

#### Block Types

| Block Type | Count | Encounter Tiles | Unwalkable | Walkable | Notes |
|------------|-------|----------------|------------|----------|-------|
| **Summoning** | 1 | 0 | 0 | 9 | Starting position, hand-designed |
| **Shop** | 1 | 0 | 0 | 9 | Shop interface, hand-designed |
| **Warp Wizard** | 1 | 0 | 2 | 7 | Bill's lair, hand-designed |
| **Encounter** | 13 | 1 | 2 | 6 | Generated from pool |

#### Block Generator (Editor Tool)

A `BlockGenerator` tool runs in the Godot editor to produce encounter block JSONs. It is NOT a runtime tool — it generates a pool of blocks once, which are then saved as JSON files and used as the source of truth.

**Generation rules for encounter blocks:**
- Exactly 1 encounter tile
- Exactly 2 unwalkable tiles
- Exactly 6 walkable tiles
- Walkable tiles must be connected (no isolated islands)
- Tile placement is random per block

**Workflow:**
1. Run the generator in the editor → produces ~20 encounter block JSONs
2. Playtest and tweak individual blocks if needed
3. The JSON files in `resources/blocks/` are the permanent pool
4. At game setup, 13 encounter blocks are randomly selected from the pool

**File structure:**
```
resources/blocks/
├── summoning.json          (hand-designed)
├── shop.json               (hand-designed)
├── warp_wizard.json         (hand-designed)
├── encounter_01.json        (generated)
├── encounter_02.json        (generated)
├── ...
└── encounter_20.json        (generated)
```

### 10.5 Warping Process

Warping happens at the end of rounds 6, 12, and 18. The block tile layouts do NOT change — blocks are only **moved** to new grid positions and **rotated**.

The process:

1. **Identify** shielded blocks (any block with a character on it)
2. **Separate** blocks into shielded (stay) and unshielded (move)
3. **Shuffle** unshielded blocks to new grid positions
4. **Rebuild** the 4×4 grid: shielded blocks stay, unshielded fill remaining slots
5. **Rotate** each unshielded block randomly (0°, 90°, 180°, or 270°)
6. **Restore** encounter tokens on all warped blocks
7. **Emit** `warp_completed`

A block is shielded if **any** character stands on any tile within it.

---

## 11. Card Zone Management

### 11.1 Zones

Every card exists in exactly one zone at a time:

| Zone Name | Description |
|-----------|-------------|
| `encounter_deck` | Face-down encounter cards |
| `treasure_deck` | Face-down treasure cards |
| `encounter_discard` | Resolved encounter cards |
| `treasure_discard` | Resolved treasure cards |
| `hand_<character_id>` | Character's hand (max 7 cards). Quest cards, unequipped treasures, consumables |
| `equipment_<character_id>` | Character's equipment (7 slots: 1 armor, 2 weapon hand slots, 1 headgear, 1 footgear, 2 accessory) |
| `in_play_<character_id>` | Active hostile encounter during combat (max 1 per character, max 5 total) |

### 11.2 ZoneManager Rules

- `register_card(card_id, zone)` — adds a card to a zone (used when cards are first created)
- `move_card(card_id, to_zone)` — moves a card from its current zone to a new zone, emits `card_moved`
- `get_cards_in_zone(zone)` — returns all card IDs in a zone
- `get_card_zone(card_id)` — returns which zone a card is in
- `equip_card(card_id, character_id)` — moves card from hand to equipment slot (validates slot availability and compatibility)
- `unequip_card(card_id, character_id)` — moves card from equipment to hand (fails if hand full)
- `can_equip(card_id, character_id)` — checks if slot is available and compatible
- `draw_to_hand(card_id, character_id)` — adds card to hand; if hand full, card goes to discard
- `trade_card(card_id, from_id, to_id)` — atomic transfer between two characters. Card can be in hand OR equipped. If equipped on sender, stays equipped on receiver (if slot compatible); otherwise goes to receiver's hand

### 11.3 Hand Overflow

When a character's hand has 7 cards and a new card is drawn:
- The drawn card goes directly to the appropriate discard pile
- Emit `card_discarded` signal
- Character is notified (UI shows "hand full")

### 11.4 Equipment Death Rule

When a character is defeated (HP reaches 0):
- Items **stay equipped** — they do not drop or move to hand
- Character is sent to the Summoning Block with all equipment intact

### 11.5 Two-Handed Weapon Rule

When equipping a two-handed weapon (`hand_slots_needed: 2`):
- Both weapon hand slots must be free
- Player must **manually discard or unequip** items in hand slots before equipping a two-handed weapon
- No auto-unequip/auto-discard — player must explicitly manage their hand slots

---

## 12. Player Token System

### 12.1 Token Representation

Player tokens are visual representations only. The authoritative position lives in `BoardState.character_positions`. Each token scene contains:

- A `Sprite2D` (placeholder circle)
- A `Label` (character initial)
- A `Tween` for movement animation

### 12.2 Movement

When a token moves:
1. Update `board_state.character_positions[character_id]` to the new tile
2. Animate the visual position to the target tile using a Tween
3. Emit `character_moved`

### 12.3 Movement Validation

A character can move to a target tile if:
- The Manhattan distance from current tile ≤ character's speed
- The target tile is walkable

---

# PART 4: UI

---

## 13. UI Layout

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
│    static, centered)  │                                 │
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
│              CURRENT PLAYER — CHARACTER SHEET                          │
│  ┌────────────┬──────────────────────────────────────┬───────────┐  │
│  │   STATS    │          HAND (cards)                │EQUIPMENT  │  │
│  │  ┌──────┐  │  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐   │┌─────────┐│  │
│  │  │HP 10 │  │  │Item │ │Item │ │Item │ │Item │   ││ Headgear││  │
│  │  │AP  5 │  │  └─────┘ └─────┘ └─────┘ └─────┘   ││ Armor   ││  │
│  │  │ATK 3 │  │  ┌─────┐ ┌─────┐ ┌─────┐           ││ Weapon×2││  │
│  │  │DEF 2 │  │  │Item │ │Item │ │Item │           ││ Footgear││  │
│  │  │SPD 4 │  │  └─────┘ └─────┘ └─────┘           ││ Accs ×2 ││  │
│  │  └──────┘  │                                      │└─────────┘│  │
│  │            │         Gold: 12                     │           │  │
│  └────────────┴──────────────────────────────────────┴───────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 14. Scene Tree

```
Main (Node)
├── Board (Node2D)
│   ├── Blocks (Node2D)
│   │   ├── Block_0_0 (Node2D)   — 3×3 tiles
│   │   ├── Block_0_1 (Node2D)
│   │   ├── ...
│   │   └── Block_3_3 (Node2D)
│   └── CharacterTokens (Node2D)
│       ├── Token_Char1 (Node2D)
│       ├── ...
│       └── Token_Char5 (Node2D)
│
├── UI (CanvasLayer)
│   ├── TurnBar (HBoxContainer)
│   │   ├── Clock (Control)
│   │   └── CharacterIcons (HBoxContainer)
│   │       ├── Icon_Char1 (Button)
│   │       └── ...
│   │
│   ├── RightPanel (VBoxContainer)
│   │   ├── DeckPools (HBoxContainer)
│   │   │   ├── EncounterDeck (PanelContainer)
│   │   │   └── TreasureDeck (PanelContainer)
│   │   └── ActionCard (GridContainer) — 2×3 grid
│   │       ├── MoveOption, AttackOption, EscapeOption
│   │       └── TradeOption, UseItemOption, RestOption
│   │
│   ├── BottomPanel (Control)
│   │   └── CharacterSheet (HBoxContainer)
│   │       ├── StatsPanel (VBoxContainer)
│   │       ├── HandPanel (HBoxContainer)
│   │       └── EquipmentPanel (VBoxContainer)
│   │
│   └── CharacterPopup (PopupPanel)
│
├── CardFocusPopup (Popup)
└── GameManager (Node) — autoload
```

---

## 15. Board & Layout

### 15.1 Board

The Board is a `Node2D` containing all tiles and character tokens. The board is centered in the window with padding for the turn bar (top) and character stats strip (bottom). No camera pan/zoom — the full board fits within the window.

### 15.2 Placeholder Tiles

| Tile Type | Colour | Notes |
|-----------|--------|-------|
| Walkable | Light blue `#87CEEB` | Standard movement tile |
| Unwalkable | Brown `#8B4513` | Impassable terrain |
| Encounter | Green `#228B22` | Has encounter token overlay |
| Summoning Block | Light green `#90EE90` | Starting position |
| Shop Block | Yellow `#FFD700` | Buy items |
| Warp Wizard Block | Purple `#800080` | Bill's location |
| Character token | Red/Blue/etc. | Circle or pawn shape |

### 15.3 Camera

- **Pan:** Middle mouse button drag
- **Zoom:** Mouse wheel (range: 0.3x to 3.0x)

### 15.4 Board Helpers

Static utility functions:
- `tile_to_pixel(tile: Vector2i) → Vector2` — converts tile coordinates to pixel position
- `pixel_to_tile(pos: Vector2) → Vector2i` — converts pixel position to tile coordinates
- `manhattan_distance(a, b) → int` — calculates movement distance
- `is_walkable(tile) → bool` — checks if a tile can be walked on

### 15.5 Block Construction

Each block is a `Node2D` scene containing 9 tile children in a 3×3 arrangement. Tile positions are local offsets within the block (tile size: 64px).

---

## 16. Turn Bar & Clock

### 16.1 Analog Clock

A custom `Control` node that draws an analog clock face:
- **24 hours = 24 rounds**
- Clock hand rotates clockwise, completing one full rotation over 24 rounds
- Warp rounds (6, 12, 18) marked with special indicators
- Final round (24) marked as "midnight"

### 16.2 Character Icons

A row of 5 buttons (one per character). Each shows a placeholder coloured circle with the character's initial. Clicking opens the character popup.

### 16.3 Character Popup

A `PopupPanel` that shows a read-only view of a character's sheet and inventory. Triggered by clicking a character icon in the turn bar. Closable via close button or click-away.

---

## 17. Action Card

### 17.1 Layout

A `GridContainer` with 3 columns and 2 rows, styled as a single game card:

```
┌─────────────────────────────────────┐
│           ACTION CARD               │
├─────────────┬─────────────┬─────────┤
│    MOVE     │   ATTACK    │  ESCAPE │
├─────────────┼─────────────┼─────────┤
│    TRADE    │  USE ITEM   │   REST  │
└─────────────┴─────────────┴─────────┘
```

### 17.2 Action Options

Each cell is a `PanelContainer` with an icon and label. Visual states:
- **Valid:** Full colour, clickable (`modulate = Color.WHITE`)
- **Invalid:** Greyed out (`modulate = Color(0.4, 0.4, 0.4)`), non-interactive

### 17.3 Action Card Manager

Re-evaluates valid actions on every game state change by calling `GameManager.get_valid_actions()`.

---

## 18. Card Scene & Interaction

### 18.1 Card Scene

```
Card (PanelContainer)
├── MarginContainer
│   └── VBoxContainer
│       ├── TopRow (HBoxContainer)
│       │   ├── CardName (Label)
│       │   └── CardType (Label)
│       ├── CardIcon (TextureRect)
│       └── Description (RichTextLabel)
```

### 18.2 Hover

On mouse enter: scale up to 1.3x with Tween easing (TRANS_BACK), raise z_index. On mouse exit: return to original scale.

### 18.3 Click to Focus

Clicking a card opens a `Popup` showing an enlarged version (2x scale) for reading. Closable.

### 18.4 Drag-and-Drop

Cards use Godot's built-in `_get_drag_data` / `_can_drop_data` / `_drop_data` system:
- Drag creates a semi-transparent preview that follows the cursor
- Drop targets validate the card type
- On drop, `ZoneManager.trade_card()` or `move_card()` is called

---

## 19. Character Sheet (Bottom Panel)

```
┌──────────────────────────────────────────────────────────────────────┐
│  CURRENT PLAYER — CHARACTER SHEET                                   │
├──────────────┬───────────────────────────────────────────────────────┤
│    STATS     │            HAND (max 7)           │    EQUIPMENT     │
│  ┌────────┐  │  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ │  ┌───────────┐  │
│  │ HP: 10 │  │  │Card │ │Card │ │Card │ │Card │ │  │ Headgear  │  │
│  │ AP:  5 │  │  └─────┘ └─────┘ └─────┘ └─────┘ │  │ Armor     │  │
│  │ ATK: 3 │  │  ┌─────┐ ┌─────┐ ┌─────┐         │  │ Weapon ×2 │  │
│  │ DEF: 2 │  │  │Card │ │Card │ │Card │         │  │ Footgear  │  │
│  │ SPD: 4 │  │  └─────┘ └─────┘ └─────┘         │  │ Access ×2 │  │
│  └────────┘  │                                   │  └───────────┘  │
│              │  Gold: 12                          │                  │
└──────────────┴───────────────────────────────────┴──────────────────┘
```

- **Stats panel:** VBoxContainer with Label nodes, updated on stat change
- **Hand panel:** HBoxContainer of draggable card instances (max 7)
- **Equipment panel:** VBoxContainer showing equipped items per slot
- **Gold display:** Label with icon

---

## 20. Deck Visuals

Two deck areas on the right panel:

| Deck | Cards | Trigger |
|------|-------|---------|
| **Encounter Deck** | Hostile + Neutral encounter cards | Player lands on encounter tile |
| **Treasure Deck** | Loot cards | Defeating a creature |

**Deck logic:**
- Cards are drawn from the top
- When the deck is empty, the discard pile is reshuffled back in
- Drawing animates from deck position to target area

---

# PART 5: GAME SYSTEMS

---

## 21. Turn Flow & Actions

### 21.1 Player Turn

On their turn, a player may:
1. **Move** up to their Speed in steps (base 4)
2. If they land on an encounter tile → draw encounter card → resolved immediately
3. If the encounter is hostile → enter combat (speed drops to 0)
4. If already in combat at turn start → continue combat or attempt to escape

### 21.2 Resting

A character may spend their turn resting instead of moving. Resting:
- Prevents movement for this turn
- Regenerates AP *(amount TBD)*
- Can only be done if not in combat and has not moved this turn

### 21.3 Trading

When two or more characters are on the **same tile**, they may freely trade any cards between them. Trading can occur on **either player's turn** and there is **no limit** to the number of trades per turn.

### 21.4 Encounter Resolution

When a character lands on an encounter tile:
- Draw the top card from the encounter deck
- Resolve the encounter immediately
- Remove the encounter token from the tile (tile becomes walkable)
- Cannot avoid encounters — they are mandatory

---

## 22. Combat System

### 22.1 Starting Combat

When a hostile encounter is drawn, combat begins immediately. The character's speed drops to **0** for the remainder of the turn.

### 22.2 Joining Combat

Other characters may join by moving onto the same encounter tile. Each character participates in the fight.

### 22.3 Combat Turn Order

1. **All character turns** — each character attacks, uses abilities, or attempts to escape
2. **Creature's turn** — attacks **one random target** (roll a die)

### 22.4 Damage

- **Player attacks:** Roll attack dice (Attack stat modifies the roll)
- **Creature attacks:** Damage reduced by target's Defence / Armor

### 22.5 Defeating a Creature

When creature HP reaches 0:
- Combat ends
- Encounter card kept by a participating player
- Treasure cards drawn and divided freely among participants
- Gold may be gained

### 22.6 Character Defeat

When HP reaches 0 → character is defeated → sent to Summoning Block. May be revived by another character at the Summoning Block.

### 22.7 Escaping Combat

Make a "run away" roll on your turn:
- Success: disengage, may move next turn
- Failure: combat continues

*(Run away roll mechanics TBD — target number, dice used.)*

---

## 23. Warping System

*(See §10.4 for the warp process.)*

Warping happens at the **end of rounds 6, 12, and 18**.

1. All blocks with **no characters** are shuffled and rotated
2. Encounter tokens restored on warped blocks
3. Characters on a block shield it from warping

---

## 24. Trading System

*(See §11.2 ZoneManager for implementation.)*

- Characters must be on the same tile
- Any cards can be traded — hand OR equipped
- No limit to trades per turn
- Either player's turn
- **Equipment stays equipped** on receiver if slot is compatible; otherwise card goes to receiver's hand

---

## 25. Shop & Gold

### 25.1 Gold

Gold is obtained from:
- Neutral encounters
- Defeated hostile creatures
- Treasure cards

### 25.2 Shop

The Shop Block offers items for purchase using gold.

*(Shop stock, pricing, and refresh mechanics TBD.)*

---

# PART 6: REFERENCE

---

## 26. Key Godot Nodes

| Element | Node Type | Notes |
|---------|-----------|-------|
| Game root | `Node` | Main scene |
| Board | `Node2D` | Contains tiles and tokens |
| (removed — board is static, no camera) | | |
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
| Character sheet | `HBoxContainer` | Stats left, hand middle, equipment right |
| Card scene | `PanelContainer` | Reusable card with CardData |
| Card popup | `Popup` | Enlarged card focus view |
| Character popup | `PopupPanel` | Read-only character sheet |
| Game manager | `Node` (autoload) | Game logic and state |
| Event bus | `Node` (autoload) | Cross-system signal bus |
| Zone manager | `Node` (autoload) | Card zone tracking |
| Card database | `Node` (autoload) | JSON card loader |

---

## 27. File Structure

```
warping-woods-oc/
├── project.godot
├── booklet.md
├── implementation.md
├── images/
│   └── booklet/
│       └── board.png
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
│   ├── gain_stat_effect.gd
│   ├── draw_card_effect.gd
│   ├── quest_effect.gd
│   ├── conditional_effect.gd
│   ├── on_defeat_effect.gd
│   ├── character_data.gd
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
│   ├── board_state.gd
│   ├── block_data.gd
│   ├── tile_data.gd
│   └── card_database.gd
├── resources/
│   ├── blocks/
│   │   ├── summoning.json
│   │   ├── shop.json
│   │   ├── warp_wizard.json
│   │   ├── encounter_01.json
│   │   ├── encounter_02.json
│   │   └── ...
│   ├── cards/
│   │   ├── encounters/
│   │   │   ├── warped_wolf.json
│   │   │   ├── friendly_hermit.json
│   │   │   └── ...
│   │   └── treasures/
│   │       ├── health_potion.json
│   │       └── ...
│   └── characters/
│       ├── serra.json
│       ├── kaelen.json
│       ├── elara.json
│       ├── bran.json
│       └── lyra.json
├── tests/
│   ├── .gutconfig.json
│   ├── unit/
│   └── integration/
├── tools/
│   └── block_generator.gd
├── debug/
└── themes/
    └── default_theme.tres
```

---

## 28. Implementation Plan

The implementation follows 7 sequential steps. Each step produces a testable milestone before moving to the next.

| Step | Deliverable | Depends On | Est. |
|------|-------------|------------|------|
| **1** | **Block Generator Tool** — `TileData`/`BlockData` classes, `@tool` editor script that generates encounter block pool JSONs | Nothing | Medium |
| **2** | **Board + Characters + Turns + Warping** — `main.tscn`, board/block/tile/character_token scenes, action card (Move/Rest + End Turn), turn bar, round/turn flow, BoardState, CharacterData, click-to-move (snap, Manhattan distance ≤ speed), block warp at rounds 6/12/18 | Step 1 (block JSONs) | High |
| **3** | **Encounter System** — `CardData`, `CardEffect` types, `EventBus`, `CardDatabase`, `ZoneManager`, card scene, draw-on-encounter-tile, effect resolution (neutral + hostile) | Step 2 (movement reaches encounter tiles) | High |
| **4** | **Combat** — hostile encounters with dice combat, creature turns, multi-character joining, escape, character defeat/revival | Step 3 (hostile encounter cards) | High |
| **5** | **Treasure System** — treasure deck, loot on creature defeat, `Card` scene renders treasure data, consumable items | Step 4 (combat produces loot) | Medium |
| **6** | **Hand & Equipment** — 7-slot hand UI, 7-slot equipment UI, equip/unequip from hand to slots, drag-and-drop between zones | Step 5 (treasure cards to equip) | Medium |
| **7** | **Gold & Shop** — gold tracking per character, Shop Block UI, buy/sell items from shop stock | Step 6 (spend gold on items) | Medium |

### Post-Plan Features

After the core loop (Steps 1-7) is playable, add these features in any order:

| Feature | Depends On | Est. |
|---------|------------|------|
| Warping (block shuffle, rotation, token reset, shielding) | Step 2 | High |
| Turn bar with analog clock (24-round display, character icons) | Step 2 | Medium |
| Action card (valid action highlighting for Move/Attack/Escape/Trade/Item/Rest) | Step 4 | Medium |
| Quest system (grant_quest effect, conditional completion, rewards) | Step 3 | High |
| Trading between characters (drag cards between hands/equipment) | Step 6 | Low |
| Character popup (read-only sheet for non-active characters) | Step 2 | Low |
| Bill the Warping Wizard encounter & win/lose conditions | Step 4 | High |
| Revival at Summoning Block | Step 2 | Low |
| Polish (animations, sound, visual feedback) | All | Medium |

### Dependencies Map

```
Step 1         Step 2         Step 3         Step 4         Step 5         Step 6         Step 7
Generator ──► Board + Char ──► Encounters ──► Combat ─────► Treasures ──► Hand/Equip ──► Gold/Shop
                              │               │                                       │
                              ▼               ▼                                       ▼
                          Quests          Bill + Revival                          Trading
```

---

## 29. Data Workflow

### 29.1 Block Workflow (Step 1)

1. Run `BlockGenerator` in the Godot editor → produces encounter block JSONs
2. Place in `resources/blocks/`
3. Playtest and tweak individual blocks as needed
4. The JSON files are the source of truth for block layouts
5. At game setup, 13 encounter blocks are randomly selected from the pool

### 29.2 Card Workflow (Steps 3-5)

1. Write card JSON files in any text editor
2. Place in `resources/cards/<type>/`
3. Run the game — `CardDatabase` autoloads and loads all JSON
4. Cards are immediately available as typed `CardData` objects

### 29.3 Character Workflow (Step 2)

1. Write character JSON files in any text editor
2. Place in `resources/characters/`
3. GameManager loads all character JSONs at startup
4. 5 `CharacterData` objects are created with starting stats, hand, and equipment

### 29.4 Iteration

- Edit JSON → restart game (no hot-reload for JSON)
- Or add a debug key to call `CardDatabase._ready()` to reload

### 29.4 Production

- Blocks and cards are playtested and balanced
- JSON files are the source of truth
