class_name EventLog
extends RichTextLabel

func _ready() -> void:
	get_node("/root/EventBus").event_logged.connect(_on_event_logged)

func _on_event_logged(message: String) -> void:
	append_text(message + "\n")
	# Auto-scroll to bottom
	await get_tree().process_frame
	scroll_to_line(get_line_count() - 1)
