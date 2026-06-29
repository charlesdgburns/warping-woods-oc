# Warping Woods — Instruction Booklet

---

## 1. Overview

**Warping Woods** is a cooperative campaign board game for 1–5 players. All 5 characters are always in play — when playing with fewer than 5 players, one or more players control multiple characters. The group must defeat **Bill the Warping Wizard** before the entire world is warped beyond repair.

- **Players:** 1–5
- **Characters:** 5 (always all in play)
- **Rounds:** 24
- **Warp Events:** 3 (end of rounds 6, 12, and 18)
- **Goal:** Defeat Bill before the end of round 24

---

## 2. Components

- Game board (4×4 grid of 3×3 blocks = 144 tiles)
- Character sheets (×5)
- Encounter deck (Hostile + Neutral)
- Treasure deck
- Gold tokens
- Shop stock
- Dice
- Encounter tokens (placed on encounter tiles, removed when triggered)

> **Note:** Quests, companions, and items are not separate card types. They are revealed through encounter cards (e.g., a neutral encounter may grant a companion or start a quest) or treasure cards (e.g., defeating a creature may yield an item).

---

## 3. Characters

### 3.1 Character Roster

Five characters are available. Each has a unique lore, playstyle, and class.

| # | Name | Lore | Class | Abilities |
|---|------|------|-------|-----------|
| 1 | *(TBD)* | *(TBD)* | *(TBD)* | *(TBD)* |
| 2 | *(TBD)* | *(TBD)* | *(TBD)* | *(TBD)* |
| 3 | *(TBD)* | *(TBD)* | *(TBD)* | *(TBD)* |
| 4 | *(TBD)* | *(TBD)* | *(TBD)* | *(TBD)* |
| 5 | *(TBD)* | *(TBD)* | *(TBD)* | *(TBD)* |

### 3.2 Stats

Each character has the following stats:

| Stat | Description |
|------|-------------|
| **Health Points (HP)** | When reduced to 0, the character is defeated. |
| **Ability Points (AP)** | Spent to use special abilities. |
| **Attack** | Added to attack rolls during combat. |
| **Defence / Armor** | Reduces incoming damage or opposes enemy attacks. |
| **Speed** | Determines how many tiles the character can move per turn (base: 4). |

### 3.3 AP Regeneration

AP is restored through the following means:

- **Resting:** A character may spend their turn resting instead of moving. Resting regenerates AP *(amount TBD)*. A character cannot rest while in combat.
- **Potions & Drinks:** Consumable items purchasable at the Shop or found via encounters.
- **Encounters:** Some neutral encounters may grant AP as a reward.

### 3.4 Companions

Each player may have one companion. Companions have their own stats and abilities and act alongside their controlling player.

*(Companion mechanics, stat blocks, and acquisition TBD.)*

---

## 4. The Map

### 4.1 Layout

The map is a **4×4 grid of 3×3 blocks**, totalling **144 tiles**.

### 4.2 Block Types

**Special Blocks (3):**

| Block | Description |
|-------|-------------|
| **Summoning Block** | Starting location for all characters. Defeated characters are revived here. Contains no encounter tiles. |
| **Shop Block** | Purchase items using gold. Contains no encounter tiles. |
| **Warping Wizard Block** | Bill's location. The site of the final encounter. Contains no encounter tiles. |

**Encounter Blocks (13):**

Each encounter block contains:
- **1 Encounter Tile** — triggers an encounter card when a character lands on it. An encounter token is placed on this tile at the start of the game.
- **6 Walkable Tiles** — normal movement tiles
- **2 Unwalkable Tiles** — impassable terrain

The arrangement of tiles within each block is random and unique per block.

### 4.3 Example Board

![Board diagram](images/booklet/board.png)

**Block-level view (4×4 grid):**

```
+--------+--------+--------+--------+
|        |        |        | WARP   |
|   E    |   E    |   E    | WIZARD |
|        |        |        | BLOCK  |
+--------+--------+--------+--------+
|        |        |        |        |
|   E    |   E    |   E    |   E    |
|        |        |        |        |
+--------+--------+--------+--------+
|        |        |        |        |
|   E    |   E    | SHOP   |   E    |
|        |        | BLOCK  |        |
+--------+--------+--------+--------+
|        |        |        |        |
|SUMMON  |   E    |   E    |   E    |
| BLOCK  |        |        |        |
+--------+--------+--------+--------+
```

**Example encounter block (3×3 tiles):**

```
+---+---+---+
| . | ! | . |
+---+---+---+
| # | . | . |
+---+---+---+
| . | . | # |
+---+---+---+
```

- `.` = Walkable tile
- `#` = Unwalkable terrain
- `!` = Encounter tile (with encounter token)

### 4.4 Encounter Tile Removal

When a character lands on an encounter tile and resolves the encounter, the encounter token is **removed** from the board. The tile now functions as a regular walkable tile for the remainder of the game. Encounter tokens are only restored on blocks that are warped (see §6 Warping).

---

## 5. Setup

1. Arrange the 16 blocks into a 4×4 grid to form the game board.
2. Place encounter tokens on all encounter tiles across the 13 encounter blocks.
3. All 5 characters begin on the **Summoning Block**.
4. Shuffle the encounter deck, treasure deck, and quest cards.
5. Place gold tokens, item cards, and shop stock within reach.
6. Determine player control: distribute the 5 characters among players as desired. All 5 characters must be in play at all times.

---

## 6. Turn Structure

Each round, every character takes a turn. The order of turns is determined by player agreement or a fixed sequence.

### 6.1 Decision Tree

At the start of your turn, check the following:

```
Are you currently in combat?
├── YES → You may Continue Combat or attempt to Escape.
│         (You cannot move, rest, or take other actions.)
└── NO  → You may either:
          ├── MOVE (up to your Speed in steps)
          │     └── Did you land on an encounter tile?
          │           ├── YES → Draw encounter card (see §7).
          │           │         Your turn ends immediately.
          │           │         You cannot move further this turn.
          │           └── NO  → You may continue moving
          │                     (up to remaining Speed).
          └── REST (do not move; regenerate AP — see §3.3)
```

### 6.2 Movement Rules

- You cannot move while in combat.
- You cannot move after triggering an encounter (your turn ends immediately).
- You may not move through unwalkable tiles.
- You may freely move through tiles occupied by other characters.

### 6.3 Trading

When two or more characters are on the **same tile**, they may freely trade any cards (encounter cards, treasure cards, item cards, quest cards) between them. Trading can occur on **either player's turn** and there is **no limit** to the number of trades per turn.

### 6.4 Actions Summary

| Action | When Available | Notes |
|--------|---------------|-------|
| Move | Not in combat | Up to Speed steps; ends immediately on encounter tile |
| Rest | Not in combat | No movement; regenerate AP |
| Continue combat | Start of turn in combat | Attack the creature |
| Escape combat | Start of turn in combat | Requires a "run away" roll |
| Trade | Characters on same tile | Any cards, any number, either turn |
| Use item | Not in combat | *(Details TBD)* |
| Interact with shop | On Shop Block | Spend gold to buy items |

---

## 7. Warping

### 7.1 When Warping Occurs

Warping happens at the **end of rounds 6, 12, and 18**. Round 24 is the game-end (no warp, but Bill must be defeated by then).

The warp resolves **after all character turns and creature turns** for that round are complete.

### 7.2 What Happens During a Warp

All blocks that have **no characters standing on them** are:
1. **Shuffled** to new positions on the 4×4 grid
2. **Randomly rotated** (90°, 180°, 270°, or 360°)
3. **Encounter tokens restored** on all encounter tiles on warped blocks

### 7.3 Block Shielding

A character standing on a block **shields** it from warping:
- The block is not moved or rotated
- Encounter tokens on that block are not restored
- Any active combat or items on that block persist

This means players must coordinate to shield important blocks before a warp.

---

## 8. Encounters

### 8.1 Triggering Encounters

When a character lands on an **encounter tile**, they **must** draw the top card from the **encounter deck** and resolve it immediately. Encounters are mandatory — a player cannot choose to avoid an encounter.

After the encounter is resolved, the encounter token is **removed** from the tile. The tile becomes a regular walkable tile.

### 8.2 Neutral Encounters

Neutral encounters involve meeting villagers, healers, or other non-hostile characters. The encounter card is **kept by the player** who drew it. Neutral encounters may provide:

- **Immediate rewards** — healing, AP restoration, gold, items
- **Quests** — the card describes a condition for completion (e.g., acquire a specific quest item). The card is kept until the condition is met.

### 8.3 Hostile Encounters

Hostile encounters are **Warped Creatures** that must be defeated in combat. The encounter card stays in play (face-up on the table) for the duration of the combat.

Upon defeating a creature:
- The encounter card is **kept** by one of the players who helped defeat it
- Draw **treasure cards** for loot
- Gold may be gained from the creature or treasure cards

### 8.4 Quests

- A quest card describes a condition: acquire a specific **quest item** (e.g., treasure card, monster card such as "Head of a Warped Wolf")
- The quest card is kept by a player until the condition is met
- When the matching quest item is acquired, the quest is completed **immediately** — the player(s) receive the reward listed on the quest card
- Quest cards may be **traded** between characters on the same tile. One character may hold the quest while another holds the matching item — they must meet to complete it.

### 8.5 Encounter Token Lifecycle

| State | Description |
|-------|-------------|
| **Placed** | Token on encounter tile at game start or after a warp |
| **Removed** | Encounter triggered and resolved; tile becomes walkable |
| **Restored** | Only during a warp, on blocks that were warped (no characters present) |

---

## 9. Items & Gold

### 9.1 Gold

Gold is the currency used at the Shop. It is obtained from:
- Neutral encounters
- Defeated hostile creatures
- Treasure cards

### 9.2 Obtaining Items

Items are obtained from:
- **Encounters** — quest rewards, neutral NPC gifts
- **Shops** — purchased at the Shop Block using gold
- **Treasure loot** — drawn after defeating a Warped Creature

### 9.3 Item Types

| Type | Description |
|------|-------------|
| **Character-Specific** | Only usable by a particular character |
| **Generic** | Usable by any character |

### 9.4 Item Effects

Items may:
- Modify stats (HP, AP, Attack, Defence, Speed)
- Grant combat bonuses (extra dice, special effects)
- Provide utility (extra movement, quest aids)
- Be consumable (potions, one-use items) or persistent (equipment)

*(Item catalog and shop prices TBD.)*

---

## 10. Combat

Combat is a **turn-based dice system**.

### 10.1 Starting Combat

When a hostile encounter is drawn, combat begins immediately. The character's speed drops to **0** for the remainder of the turn.

### 10.2 Joining Combat

Other characters may **join** an ongoing combat by moving onto the same encounter tile. Each additional character contributes their own turn to the fight.

### 10.3 Combat Turn Order

Within each round, combat follows this order:

1. **All character turns** — each character in the combat takes their turn (attack, use abilities, attempt to escape)
2. **Creature's turn** — the Warped Creature attacks **once**, targeting **one random character** in the fight (roll a die to determine the target)

If a character's turn occurs after they have joined an ongoing combat, they participate immediately.

### 10.4 Combat Turn Actions

On your combat turn, you may:

1. **Attack:** Roll attack dice (Attack stat modifies the roll)
2. **Use an ability:** Spend AP to activate a special ability *(details TBD)*
3. **Attempt to escape:** Make a "run away" roll *(mechanics TBD)*

### 10.5 Damage & Defence

- **Player attacks:** Damage dealt is compared to the creature's HP
- **Creature attacks:** Damage dealt is reduced by the target character's Defence / Armor

### 10.6 Defeating a Creature

When the creature's HP reaches 0:
- Combat ends
- The encounter card is **kept** by one of the participating players
- **Treasure cards** are drawn and divided freely among participating players (players agree on distribution)
- **Gold** may be gained from the creature or treasure cards

### 10.7 Character Defeat

When a character's HP reaches 0:
- The character is **defeated** and sent to the **Summoning Block**
- They do not act for the remainder of the current round
- They may be revived by another character at the Summoning Block (see §11)

### 10.8 Escaping Combat

A character may attempt to **escape** on their turn by making a **"run away" roll**:
- **Success:** Character disengages from combat and may move normally on their next turn
- **Failure:** Combat continues as normal

*(Run away roll mechanics TBD — e.g., target number, dice used.)*

---

## 11. Revival

### 11.1 Defeated Characters

When a character's HP reaches 0, they are **defeated** and sent to the **Summoning Block**.

### 11.2 Resummoning

- Another player must have a character **standing on a tile within the Summoning Block**
- The resummoning player's turn **ends immediately** upon resummoning
- The revived character **does not act this round** — they begin their turn normally in the **next round**

---

## 12. Bill — The Warping Wizard

Bill is the final boss, located on the **Warping Wizard Block**.

*(Bill's stats, abilities, encounter mechanics, and defeat conditions TBD.)*

### 12.1 Reaching Bill

Players must navigate the warping map to reach the Warping Wizard Block and engage Bill in combat.

### 12.2 Defeating Bill

*(Winning encounter mechanics TBD.)*

---

## 13. Win & Lose Conditions

### 13.1 Victory

The players **win** if Bill is defeated **before the end of round 24**.

### 13.2 Defeat

The players **lose** if round 24 ends and Bill is still alive. The world is warped beyond recovery.

---

## Appendix: Quick Reference

### Turn Flow
```
In combat?
├── YES → Continue Combat or Escape
└── NO  → Move (up to Speed) or Rest (regen AP)
            └── Landing on encounter tile? → Draw card, turn ends
```

### Warp Timeline
| Round | Event |
|-------|-------|
| 6 | Warp #1 |
| 12 | Warp #2 |
| 18 | Warp #3 |
| 24 | Game-end (Bill must be defeated) |

### Character Stats at a Glance
| Stat | Effect |
|------|--------|
| HP | Health — 0 = defeated |
| AP | Fuel for special abilities |
| Attack | Added to attack rolls |
| Defence | Reduces incoming damage |
| Speed | Movement steps per turn (base 4) |

### Key Rules
- Encounters are **mandatory** — you cannot avoid them
- Encounter tiles are **removed** (not flipped) after triggering
- Cards may be **traded freely** between characters on the same tile
- **Resting** = skip movement to regenerate AP; cannot rest in combat
- Creature attacks **one random target** per round in multi-character combat
- Loot is divided **freely** among participating players
- Quests are completed **immediately** when the matching item is acquired
- Blocks are **shielded** from warping when a character stands on them
