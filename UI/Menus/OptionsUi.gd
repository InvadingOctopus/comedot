## The Options Menu which may be accessed from the Main Menu or the Pause screen.

# class_name OptionsUI
extends Container


func onSkipMusicButton_pressed() -> void:
	GlobalSonic.skipMusic()
