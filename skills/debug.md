# Debugging & Testing Skill

> Structured debugging loop for feature development. Uses GUT (Godot Unit Test) for testing.

---

## Debugging Loop

The core workflow when fixing bugs or developing features:

```
0. CAPTURE → Run .\tools\capture_errors.ps1 to snapshot Godot parse errors
1. RUN     → Execute the game or relevant tests
2. CATCH   → Error occurs → log to /debug/<feature>_<date>.log
3. ANALYSE → Read the error, identify root cause
4. TEST    → Write a GUT test that reproduces the bug (in /tests/)
5. FIX     → Modify the source code
6. VERIFY  → Run .\tools\capture_errors.ps1 again, then tests until green
7. REPEAT  → If new error surfaces, go to step 2
8. COMMIT  → All tests pass, commit the fix + test
```

### Key Rules

- **Bug fix:** Write the reproducing test first, then fix the code
- **New feature:** Write tests alongside implementation
- **Refactor:** Run existing tests before and after to ensure nothing broke
- **No tests, no commit:** A feature is not done until it has tests

---

## Directory Structure

```
/tests/
├── .gutconfig.json              # GUT configuration (res://tests/.gutconfig.json)
├── unit/                        # Unit tests — isolated function/method tests
│   └── test_<module>.gd         # e.g. test_card_data.gd, test_zone_manager.gd
└── integration/                 # Integration tests — cross-system interactions
    └── test_<feature>.gd        # e.g. test_equip_flow.gd, test_combat.gd

/debug/
└── <feature>_<date>.log         # e.g. equip_bug_2026-06-29.log
```

Each test file extends `GutTest` and is prefixed with `test_`.

---

## Error Capture Script

**Script:** `tools/capture_errors.ps1`

Automatically runs Godot in headless mode and captures parse/script errors before manual play-testing.

### Usage

```powershell
# From project root (defaults auto-detect Godot binary + project dir)
.\tools\capture_errors.ps1

# Explicit paths
.\tools\capture_errors.ps1 -GodotBin "C:\Users\owner\Coding\godot\Godot_v4.7-stable_win64_console.exe" -ProjectDir "C:\Users\owner\Coding\warping-woods-oc"
```

### Behavior

1. Locates Godot binary (checks known paths, then `PATH`)
2. Finds project root (looks for `project.godot`)
3. Runs `godot --path <project> --headless --quit`, capturing all output
4. Writes full output to `debug/parse_errors_<yyyy-MM-dd_HH-mm-ss>.log`
5. Scans output for error keywords (`Parser Error`, `Parse Error`, `ERROR`, `SCRIPT ERROR`)
6. Exits with code `0` if clean, `1` if errors found

### When to use

- **First diagnostic step** when Godot refuses to open the project
- **After any script edit** to catch parse errors before the editor loads
- **Before committing** to ensure no syntax/type errors slipped in

---

## GUT Setup

### Installation

1. Open Godot → AssetLib → search "GUT" → Download
2. The `addons/gut/` folder is placed in your project
3. Enable: Project → Project Settings → Plugins → GUT → Enable

### Configuration (`/tests/.gutconfig.json`)

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

### Running Tests

**From Godot editor:**
- Open GUT dock: Project → Tools → GUT
- Click "Run All" or select individual test scripts

**From command line:**
```bash
godot -s addons/gut/gut_cmdln.gd -d --path "$PWD" -gconfig=res://tests/.gutconfig.json -gexit
```

**Run a single test file:**
```bash
godot -s addons/gut/gut_cmdln.gd -d --path "$PWD" -gconfig=res://tests/.gutconfig.json -gtest=res://tests/unit/test_<name>.gd -gexit
```

**Run a single test by name:**
```bash
godot -s addons/gut/gut_cmdln.gd -d --path "$PWD" -gconfig=res://tests/.gutconfig.json -gunit_test_name="test_<name>" -gexit
```

---

## Test File Template

```gdscript
#! test/unit/test_<module>.gd
extends GutTest

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

func before_each():
	# Create fresh instances for each test
	pass

func after_each():
	# Cleanup
	pass

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

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
| `assert_signal_not_emitted(obj, signal_name, msg)` | Signal was not emitted |
| `pending(msg)` | Mark test as pending |
| `pass_test(msg)` | Force pass |
| `fail_test(msg)` | Force fail |

Full reference: `res://addons/gut/` or https://gut.readthedocs.io/

---

## Error Log Format

Write errors to `/debug/<feature>_<date>.log` in this format:

```
=== <Feature Name> Error ===
Date: 2026-06-29 12:00:00

Error:
<raw error message from Godot>

Stack Trace:
<stack trace>

Source File:
<file path>:<line>

Reproduction Steps:
1. <step one>
2. <step two>

Expected:
<what should happen>

Actual:
<what actually happens>

Test:
<test file that reproduces this>
```

### Writing from GDScript (for capturing runtime errors)

```gdscript
func log_error(feature: String, error_text: String, stack: String):
	var time = Time.get_datetime_dict_from_system()
	var filename = "%s_%04d-%02d-%02d.log" % [feature, time.year, time.month, time.day]
	var path = "user://debug/%s" % filename
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(error_text + "\n---\n" + stack)
```

---

## Test Categories

### Unit Tests (`/tests/unit/`)
Test a single function or method in isolation. No dependencies on other systems.

```gdscript
# test_card_data.gd
func test_card_data_from_json():
	var json = {"id": "test_card", "name": "Test", "type": "treasure"}
	var card = CardData.from_json(json)
	assert_eq(card.card_id, "test_card", "ID should match")
```

### Integration Tests (`/tests/integration/`)
Test interactions between two or more systems.

```gdscript
# test_equip_flow.gd
func test_equip_weapon_moves_card_to_hand():
	var card = load_card("iron_sword")
	var char = create_test_character()
	char.hand.append(card)
	ZoneManager.equip_card(card.card_id, char.id)
	assert_eq(char.hand.size(), 0, "Card should leave hand")
	assert_not_null(char.equipment.hands[0], "Card should be in hand slot")
```
