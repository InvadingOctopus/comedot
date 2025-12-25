extends Control

var didSetInitialFocus: bool = false
var _manager: SavableStateManager

func setInitialFocus() -> void:
	if not didSetInitialFocus:
		$SaveButton.grab_focus()
		didSetInitialFocus = true
		
func _input(event: InputEvent) -> void: # TBD: Use `_unhandled_input()`
	if not didSetInitialFocus and event is InputEventAction:
		setInitialFocus()
		self.get_viewport().set_input_as_handled()

func _ready() -> void:
	_manager = GameState.get_node_or_null("SavableStateManager")

func onClose_pressed() -> void:
	$SaveModal.closeModalUI()

func onLogButton_pressed() -> void:
	print(_manager.getSaveState())
	
func onSaveButton_pressed() -> void:
	print('saving...')
	_manager.saveStateAsJson("user://saved_games/testSave.json")


func onClearButton_pressed() -> void:
	print('clearing save')
	_manager.resetSaveState()
	_manager.saveStateAsJson("user://testSave.json")
	pass # Replace with function body.
