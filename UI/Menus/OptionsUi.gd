## The Options Menu which may be accessed from the Main Menu or the Pause screen.

# class_name OptionsUI
extends Container


@onready var skipMusicButton: Button = %SkipMusicButton


func _ready() -> void:
	updateSkipMusicButton()
	Tools.connectSignal(GlobalSonic.musicPlayerDidPlay, self.updateSkipMusicButton)
	Tools.connectSignal(GlobalSonic.musicPlayerDidStop, self.updateSkipMusicButton)


#region Music

func updateSkipMusicButton(_musicFileName: String = "") -> void:
	skipMusicButton.disabled = GlobalSonic.musicFiles.is_empty()


func onSkipMusicButton_pressed() -> void:
	GlobalSonic.skipMusic()

#endregion
