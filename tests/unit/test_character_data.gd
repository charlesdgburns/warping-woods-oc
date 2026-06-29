extends GutTest

func test_from_dict_creates_character() -> void:
	var data := {
		"id": "test_hero", "name": "Hero", "class": "warrior",
		"max_hp": 12, "max_ap": 4, "attack": 5, "defence": 3, "speed": 3
	}
	var c := CharacterData.from_dict(data)
	assert_eq(c.id, "test_hero")
	assert_eq(c.character_name, "Hero")
	assert_eq(c.max_hp, 12)
	assert_eq(c.hp, 12)
	assert_eq(c.max_ap, 4)
	assert_eq(c.ap, 4)
	assert_eq(c.attack, 5)
	assert_eq(c.defence, 3)
	assert_eq(c.speed, 3)
	assert_eq(c.gold, 0)


func test_from_dict_defaults() -> void:
	var c := CharacterData.from_dict({"id": "minimal"})
	assert_eq(c.max_hp, 10)
	assert_eq(c.max_ap, 5)
	assert_eq(c.attack, 3)
	assert_eq(c.defence, 2)
	assert_eq(c.speed, 4)
	assert_eq(c.gold, 0)


func test_from_dict_uses_nested_stats_is_not_read() -> void:
	var data := {"id": "x", "stats": {"max_hp": 99}}
	var c := CharacterData.from_dict(data)
	assert_eq(c.max_hp, 10, "Nested stats should not be read")


func test_is_defeated_true_when_hp_zero() -> void:
	var c := CharacterData.new()
	c.max_hp = 10
	c.hp = 0
	assert_true(c.is_defeated())


func test_is_defeated_false_when_hp_positive() -> void:
	var c := CharacterData.new()
	c.max_hp = 10
	c.hp = 5
	assert_false(c.is_defeated())


func test_rest_restores_ap() -> void:
	var c := CharacterData.new()
	c.max_ap = 6
	c.ap = 2
	c.rest()
	assert_eq(c.ap, 6)


func test_initial_has_moved_false() -> void:
	var c := CharacterData.new()
	assert_false(c.has_moved)


func test_initial_grid_position() -> void:
	var c := CharacterData.new()
	assert_eq(c.grid_position, Vector2i(0, 0))
