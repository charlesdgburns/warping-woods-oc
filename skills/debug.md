# Debugging & Testing

> Proven 3-layer debugging workflow. The `--quit` parse check alone misses most errors.

---

## Three-Layer Error Discovery

Godot's `--quit` / `--check-only` only validates autoload scripts and the main scene.
Scripts loaded by scenes or using `class_name` are compiled **lazily** on first use.
Errors only surface when the script is actually loaded or executed.

### Layer 1: Parse Check

```
godot --headless --path . --quit
```

Catches parse errors in autoloads and the main scene only.

**Blind to:** Scene-referenced scripts, `class_name` scripts, and any script not in the
autoload → main scene dependency chain.

### Layer 2: Scene-Load Check

```
godot --headless --path . res://scenes/<target>.tscn --quit
```

Forces instantiation and compilation of the scene's root script plus its entire
dependency chain. This catches parse errors that `--quit` silently skips.

**Example output from a real bug:**

```
SCRIPT ERROR: Parse Error: Cannot infer the type of "deck_size"
  at: res://scripts/test_card_piles.gd:47
SCRIPT ERROR: Parse Error: Cannot infer the type of "card_data"
  at: res://scripts/test_card_piles.gd:67
ERROR: Failed to load script "res://scripts/test_card_piles.gd"
WARNING: Parent path ... has vanished when instantiating
```

A single parse error in the root script cascades: script fails to load → scene
structure breaks → all child nodes lose their parent path references.

### Layer 3: GUT Test Run (when available)

```
godot --headless --path . --res://addons/gut/gut_cmdln.gd -gselect=<test> -gexit
```

Catches compile errors in all scripts the test suite references, plus runtime
assertion failures. Also forces lazy compilation of `class_name` scripts that
neither autoloads nor scenes reference.

### Common Silent Errors

| Error pattern | Root cause |
|---|---|
| `Cannot infer the type of "x"` | `var x := expr()` where `expr` returns Variant from an untyped base (e.g. typed as `Node` instead of the actual class) |
| `vanished when instantiating` | Root script failed to load → child node paths unresolved |
| GUT hangs silently | Test file has a compile error, e.g. uses a type name without `class_name` declaration |

---

## Write → Debug → Fix Loop

```
1. Write code
2. Run Layer 1 + Layer 2 (and Layer 3 if GUT works)
3. If errors found → fix them → go to step 2
4. When clean → commit
```

### Checklist
- [ ] `--quit` passes
- [ ] `res://scene.tscn --quit` passes for all changed scenes
- [ ] All scripts used as types have `class_name` declared
- [ ] No `var x := untyped_expr` in scene root scripts

---

## Common Bug Patterns Found in This Project

### Type inference fails on `Node`-typed variables

```gdscript
# ❌ BROKEN: typed as Node, so .size() returns Variant, := fails
var _card_database: Node
var deck_size := _card_database.encounter_deck.size()
```

```gdscript
# ✅ FIXED: explicit type hint
var _card_database: Node
var deck_size: int = _card_database.encounter_deck.size()
```

### Script used as type without `class_name`

```gdscript
# ❌ BROKEN: CardDatabase has no class_name declaration
var db: CardDatabase
var card = db.encounter_deck.pop_front() as CardDatabase
```

Fix: either add `class_name CardDatabase` to the source script, or type as `Node`
and use explicit type hints.

### Wrong CLI syntax for scene loading

```powershell
# ❌ --"res://..." loads the main scene, not the target scene
godot --"res://scenes/target.tscn" --quit

# ✅ Correct: no -- before the path
godot res://scenes/target.tscn --quit
```

---

## Testing Reference

### Directory Structure

```
/tests/
├── .gutconfig.json              # GUT configuration
├── unit/                        # Isolated function/method tests
│   └── test_<module>.gd
└── integration/                 # Cross-system interaction tests
    └── test_<feature>.gd
```

### GUT Configuration (`/tests/.gutconfig.json`)

```json
{
  "dirs": ["res://tests/unit/", "res://tests/integration/"],
  "include_subdirs": true,
  "prefix": "test_",
  "suffix": ".gd",
  "double_strategy": "partial",
  "log_level": 1,
  "should_exit": true,
  "should_maximize": false
}
```

### GUT Commands

| Command | Runs |
|---|---|
| `godot --path . --res://addons/gut/gut_cmdln.gd -gexit` | All tests |
| `godot --path . --res://addons/gut/gut_cmdln.gd -gselect=<test_name> -gexit` | Single test by name |
| `godot --path . --res://addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_<file>.gd -gexit` | Single file |

### Test File Template

```gdscript
extends GutTest

func before_each():
    # Create fresh instances
    pass

func after_each():
    # Cleanup
    pass

func test_<what_it_tests>():
    var result = <call_function_under_test>
    assert_eq(result, <expected_value>, "<descriptive message>")
```

### Common Assertions

| Assertion | Purpose |
|-----------|---------|
| `assert_eq(got, expected, msg)` | Value equality |
| `assert_ne(got, not_expected, msg)` | Value inequality |
| `assert_true(condition, msg)` | Boolean true |
| `assert_false(condition, msg)` | Boolean false |
| `assert_null(value, msg)` | Null check |
| `assert_not_null(value, msg)` | Not null |
| `assert_has(obj, element, msg)` | Array/element contains |
| `assert_does_not_have(obj, element, msg)` | Array/element does not contain |
| `assert_signal_emitted(obj, signal_name, msg)` | Signal was emitted |
| `pending(msg)` | Mark test as pending |
| `pass_test(msg)` | Force pass |
| `fail_test(msg)` | Force fail |
