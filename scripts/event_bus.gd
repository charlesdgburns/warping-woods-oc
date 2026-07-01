extends Node

signal event_logged(message: String)

func log_event(message: String) -> void:
	event_logged.emit(message)
