# Godot Development Skill

> Quick reference for Godot 4.x and GDScript development. For full docs, see `godot-docs/` (local submodule). For project-specific architecture, see `implementation.md`.

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
class_name MyClass
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

## Editor Tips

- **F5** — Run project
- **F6** — Run current scene
- **Ctrl+Shift+F** — Search in files
- **Ctrl+Click** — Jump to definition
- **Remote inspector** — Inspect live scene tree at runtime
- **Profiler** — Performance analysis (Debugger → Profiler)

---

## Reference

- `godot-docs/` — Full Godot 4 documentation (submodule)
- `implementation.md` — Project architecture and data formats
- `booklet.md` — Game rules and terminology
