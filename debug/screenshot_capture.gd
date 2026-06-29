extends Node

const FLAG := "--capture-screenshots"

var _capture_dir: String = ""
var _capture_index: int = 0
var _capturing: bool = false


func _ready() -> void:
	if not FLAG in OS.get_cmdline_args():
		return

	_capture_dir = ProjectSettings.globalize_path("res://debug/screenshots/")
	var err := DirAccess.make_dir_recursive_absolute(_capture_dir)
	if err != OK:
		push_error("ScreenshotCapture: cannot create dir ", _capture_dir)
		return

	var existing := DirAccess.get_files_at(_capture_dir)
	for f in existing:
		if f.ends_with(".png"):
			DirAccess.remove_absolute(_capture_dir.path_join(f))

	if GameManager.board_ready:
		_run_capture_sequence()
	elif not GameManager.round_started.is_connected(_run_capture_sequence):
		GameManager.round_started.connect(_run_capture_sequence)


func _capture(name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	if not img:
		push_warning("ScreenshotCapture: got null image for ", name)
		return
	var path := _capture_dir.path_join("%02d_%s.png" % [_capture_index, name])
	img.save_png(path)
	_capture_index += 1


func _run_capture_sequence(_round_num := 0) -> void:
	if _capturing:
		return
	_capturing = true
	if GameManager.round_started.is_connected(_run_capture_sequence):
		GameManager.round_started.disconnect(_run_capture_sequence)

	await RenderingServer.frame_post_draw
	_capture("board_initial")

	GameManager.enter_move_mode()
	await RenderingServer.frame_post_draw
	_capture("move_mode")

	var valid := GameManager._get_valid_move_positions()
	if not valid.is_empty():
		GameManager.handle_tile_click(valid[0])
		await RenderingServer.frame_post_draw
		_capture("after_move")
	else:
		GameManager.exit_move_mode()

	var target_round := GameManager.round_number + 4
	while GameManager.round_number < target_round and GameManager.round_number <= 24:
		for _i in 5:
			GameManager.end_turn()
		await RenderingServer.frame_post_draw
	_capture("round_5")

	for _i in 4:
		GameManager.end_turn()
	await RenderingServer.frame_post_draw
	_capture("before_warp")

	GameManager.end_turn()
	await RenderingServer.frame_post_draw
	_capture("after_warp")

	for _i in 3:
		GameManager.end_turn()
	await RenderingServer.frame_post_draw
	_capture("later_turn")

	get_tree().quit()
