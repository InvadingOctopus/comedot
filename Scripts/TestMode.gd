## TestMode
## Assists with testing a project during development by temporarily modifying nodes, global flags and other variables from a single point,
## such as disabling superfluous visual effects for a game, or increasing the lives of a player,
## instead of permanently modifying values in the Godot Editor and multiple files then trying to remember, find and revert them.

#class_name TestMode
extends Node


#region Parameters
@export var activateTestModeOnStart: bool = false
#endregion


#region State
var isInTestMode: bool = false:
	set(newValue):
		if newValue == isInTestMode: return # Avoid emitting signals needlessly
		isInTestMode = newValue
		if isInTestMode: didEnableTestMode.emit()
		else: didDisableTestMode.emit()

#endregion


#region Signals
signal didEnableTestMode
signal didDisableTestMode
#endregion


#region Dependencies
var player: PlayerEntity:
	get: return GameState.players[0]
#endregion


func onDidToggleTestMode() -> void:
	var exampleFlag: bool = isInTestMode
	var exampleProperty: int = 42 if isInTestMode else 69
	pass


func _process(_delta: float) -> void:
	# Perform any per-frame updates that may help with testing, such as displaying the values of other variables or clamping the physics of entities etc.
	pass  


#region Setup 
# Do NOT modify with project-specific stuff

func _ready() -> void:
	self.didEnableTestMode.connect(self.onDidToggleTestMode)
	self.didEnableTestMode.connect(self.onDidToggleTestMode)
		
	if activateTestModeOnStart:
		isInTestMode = true
		didEnableTestMode.emit() # CHECK: Emit manually or will the property setter be called during _ready()?


func _input(event: InputEvent) -> void:
	if event.is_action(GlobalInput.Actions.debugTest):
		isInTestMode = not isInTestMode

#endregion 