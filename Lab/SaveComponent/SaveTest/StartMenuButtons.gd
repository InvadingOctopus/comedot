extends Control


var didSetInitialFocus: bool = false

func _ready() -> void:
	await %LoadMenu.loaded
	if(%LoadMenu.noSaves == false):
		$LoadButton.disabled = false

func setInitialFocus() -> void:
	if not didSetInitialFocus:
		$StartButton.grab_focus()
		didSetInitialFocus = true
		
func _input(event: InputEvent) -> void: # TBD: Use `_unhandled_input()`
	if not didSetInitialFocus and event is InputEventAction:
		setInitialFocus()
		self.get_viewport().set_input_as_handled()

func onStartButton_pressed() -> void:
	GameState.startMainScene() # Replace with function body.


func onLoadButton_pressed() -> void:
	%LoadMenu.visible = true
	%StartMenu.visible = false


func onBack_pressed() -> void:
	%LoadMenu.visible = false
	%StartMenu.visible = true


func onQuitButton_pressed() -> void:
	get_tree().quit()
