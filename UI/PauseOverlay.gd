## Quick settings for commonly accessed options.
## Usually displayed on a pause screen.

class_name PauseOverlay # Named so other objects can access our properties.
extends Control


## A label for any game-specific text, such as help, instructions or credits.
@onready var extraLabel: Label = %ExtraLabel


func _ready() -> void:
	%TitleLabel.text	= ProjectSettings.get_setting("application/config/name", "COMEDOT")
	%SubtitleLabel.text	= ProjectSettings.get_setting("application/config/description", "")


func _process(_delta: float) -> void:
	%TimeLabel.text = str("Time Launched: %1.1f" % (Time.get_ticks_msec() / 1000.0))


func onRestartButton_longPressed() -> void:
	SceneManager.setPause(false)
	GameState.restart()
