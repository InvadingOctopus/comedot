## Quick settings for commonly accessed options.
## Usually displayed on a pause screen.

# class_name PauseOverlay
extends Control


func _ready() -> void:
	%TitleLabel.text = ProjectSettings.get_setting("application/config/name", "COMEDOT").to_upper()


func _process(_delta: float) -> void:
	%TimeLabel.text = str("Time Played: %1.1f" % (Time.get_ticks_msec() / 1000.0))
