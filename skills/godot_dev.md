# Godot Development Skill

> Quick reference for Godot 4.x and GDScript development. For full docs, see `godot-docs/` (local submodule).

---

## Core Concepts

### Nodes & Scenes
- **Nodes** are building blocks (Sprite2D, Control, Timer, etc.). Each has a name, properties, and callbacks.
- **Scenes** are saved node trees (`.tscn`). They instance like new node types.
- The scene tree is hierarchical: root → autoloads → current scene.

**Key docs:** `godot-docs/getting_started/step_by_step/nodes_and_scenes.rst`

### Resources
- Data containers (textures, scripts, custom data). Loaded once, shared across instances.
- Custom resources: extend `Resource`, use `class_name`, export properties with `@export`.
- Save as `.tres` (text) or `.res` (binary). Loaded via `load()` or `preload()`.

**Key docs:** `godot-docs/tutorials/scripting/resources.rst`

### Signals
- Observer pattern: nodes emit signals, other nodes connect to them.
- Define: `signal my_signal(arg1, arg2)`
- Emit: `my_signal.emit(value1, value2)`
- Connect: `node.my_signal.connect(callback)` or via editor Signals dock.

**Key docs:** `godot-docs/getting_started/step_by_step/signals.rst`

### Autoloads (Singletons)
- Always loaded, accessible globally by name (e.g., `GameManager.do_something()`).
- Configure in Project → Project Settings → Globals → Autoload.
- Must NOT be freed with `free()` or `queue_free()` at runtime.

**Key docs:** `godot-docs/tutorials/scripting/singletons_autoload.rst`

---

## GDScript Essentials

### File = Class
Each `.gd` file is a class. Use `class_name` to register globally:
```gdscript
class_name CardData
extends RefCounted
```

### Static Typing (Recommended)
```gdscript
var health: int = 10
var card_name: String = ""
func take_damage(amount: int) -> void:
    health -= amount
```

**Key docs:** `godot-docs/tutorials/scripting/gdscript/static_typing.rst`

### Exports (Inspector-Editable)
```gdscript
@export var damage: int = 5
@export var card_type: String = "encounter"
@export var effects: Array[Dictionary] = []
```

**Key docs:** `godot-docs/tutorials/scripting/gdscript/gdscript_exports.rst`

### Annotations Cheat Sheet
| Annotation | Purpose |
|------------|---------|
| `@export` | Expose to Inspector |
| `@onready` | Init before `_ready()` |
| `@tool` | Run script in editor |
| `@icon("path")` | Set class icon |
| `@warning_ignore("unused_variable")` | Suppress warning |

### Node Access Shorthand
```gdscript
# $NodeName is shorthand for get_node("NodeName")
@onready var label = $Label
@onready var timer = $Timer

# Path syntax
var child = $UI/HealthBar
```

### Creating & Freeing Nodes
```gdscript
var node = Sprite2D.new()
add_child(node)
node.queue_free()  # Safe deletion at end of frame
```

---

## Project Architecture (Warping Woods)

### Autoloads
| Name | Role | Stateful? |
|------|------|-----------|
| `GameManager` | Round/turn flow, character data, rules | Yes |
| `EventBus` | Central signal bus | No |
| `ZoneManager` | Card ownership tracking | Yes |
| `CardDatabase` | Loads card JSON, provides lookup | Yes |

### Data Flow
```
Input → GameManager → State Update → EventBus → UI
```

### Data Format
- **Cards:** JSON in `resources/cards/<type>/<name>.json` → loaded into `CardData` (RefCounted)
- **Blocks:** JSON in `resources/blocks/<name>.json` → loaded into `BlockData` (RefCounted)
- Card types: `encounter` and `treasure` only
- Quests = encounter cards with `grant_quest` effects

### Key Patterns
- **Single ownership:** Each card in one zone at a time, managed by ZoneManager
- **Atomic state changes:** Validate → Update → Emit signals
- **No manual positioning:** Use Container nodes for UI layout
- **Scene instancing:** One Card scene, many instances with different data

---

## Useful Built-in Nodes

| Node | Use Case |
|------|----------|
| `Control` | UI base class, anchors/container layout |
| `Container` | Auto-positions children (HBox, VBox, Grid, Margin) |
| `Timer` | One-shot or repeating timer with `timeout` signal |
| `Label` | Display text |
| `Button` | Clickable UI with `pressed` signal |
| `ColorRect` | Simple colored rectangle |
| `NinePatchRect` | Scalable texture with borders |
| `HTTPRequest` | Async HTTP requests |
| `JSON` | Parse JSON strings |
| `FileAccess` | Read/write files |
| `DirAccess` | Directory operations |
| `Tween` | Animate properties over time |
| `SceneTree` | Access scene tree, switch scenes |

---

## Common Patterns for This Project

### Loading JSON Data
```gdscript
func load_card(path: String) -> Dictionary:
    var file = FileAccess.open(path, FileAccess.READ)
    var json = JSON.new()
    json.parse(file.get_as_text())
    return json.data
```

### Signal Pattern (EventBus)
```gdscript
# In EventBus.gd
signal card_moved(card_id: String, from_zone: String, to_zone: String)

# Emitting
EventBus.card_moved.emit(card_id, "deck", "hand")

# Listening
EventBus.card_moved.connect(_on_card_moved)
```

### Custom Resource with JSON
```gdscript
class_name CardData
extends RefCounted

var card_id: String
var card_name: String
var card_type: String  # "encounter" or "treasure"
var effects: Array[Dictionary]

static func from_json(data: Dictionary) -> CardData:
    var card = CardData.new()
    card.card_id = data.get("id", "")
    card.card_name = data.get("name", "")
    card.card_type = data.get("type", "")
    card.card_effects = data.get("effects", [])
    return card
```

### Container-Based UI Layout
```gdscript
# In a scene with VBoxContainer
# Children auto-stack vertically, no manual positioning
# Use anchors for responsive layout:
#   Left: 0, Right: 0.3 → takes left 30% of screen
```

---

## Editor Tips

- **F5** — Run project
- **F6** — Run current scene
- **Ctrl+Shift+F** — Search in files
- **Ctrl+Click** — Jump to definition
- **Remote inspector** — Inspect live scene tree at runtime
- **Profiler** — Performance analysis (Debugger → Profiler)

---

## Reference Files

- `godot-docs/` — Full Godot 4 documentation (submodule)
- `implementation.md` — Project architecture and data formats
- `booklet.md` — Game rules and terminology
