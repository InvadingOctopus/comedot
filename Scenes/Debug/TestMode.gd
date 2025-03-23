## TestMode. Attach to any [Node] in a scene. Shows/hides selected nodes and performs other debugging-related actions when toggled.
## Assists with testing a project during development by temporarily modifying nodes, global flags and other variables from a single point,
## such as disabling superfluous visual effects for a game, or increasing the lives of a player,
## instead of permanently modifying values in the Godot Editor and multiple files then trying to remember, find and revert them.
## Sets [member Debug.testMode] for use by other scripts/Components.
## NOTE: The [TestMode] node itself will be visible when Test Mode is active, and hidden when not.
## TIP: In a subclass, just implement [method TestMode.onDidToggleTestMode]

class_name TestMode
extends Node


#region Parameters
@export var activateTestModeOnStart: bool = false

## A list of nodes to hide when the Test Mode is activated, and to show when deactivated.
## NOTE: The [TestMode] node itself will be visible when [member isInTestMode], and hidden when not.
@export var nodesToHide: Array[Node2D]
#endregion


#region State
var isInTestMode: bool = false:
	set(newValue):
		if newValue == isInTestMode: return # Avoid emitting signals needlessly
		isInTestMode = newValue
		Debug.testMode = newValue
		applyTestMode()
#endregion


#region Signals
signal didEnableTestMode
signal didDisableTestMode
#endregion


#region Dependencies
var player: PlayerEntity:
	get: return GameState.players.front()
#endregion


#region Game-specific Temporary Modifications

## TIP: Override in a project-specific subclass.
func onDidToggleTestMode() -> void:
	# Examples:
	# Debug.debugBackground.visible = isInTestMode
	# player.statsComponent.getStat(&"lives").value += 999 if isInTestMode else 0
	pass


# func _process(_delta: float) -> void: # UNUSED: Commented out to prevent wasting per-frame calls until needed.
	# Perform any per-frame updates that may help with testing, such as displaying the values of other variables or clamping the physics of entities etc.
	# pass

#endregion


#region Setup
# Do NOT modify with project-specific stuff

func _ready() -> void:
	self.didEnableTestMode.connect(self.onDidToggleTestMode)
	self.didDisableTestMode.connect(self.onDidToggleTestMode)

	if activateTestModeOnStart: isInTestMode = true # Calls `applyTestMode()`
	else: setNodesVisibility() # Called by `applyTestMode()` when `activateTestModeOnStart`


func _input(event: InputEvent) -> void:
	if event.is_action(GlobalInput.Actions.debugTest) \
	and event.is_action_pressed(GlobalInput.Actions.debugTest):
		self.get_viewport().set_input_as_handled()
		isInTestMode = not isInTestMode


func applyTestMode() -> void:
	Debug.addTemporaryLabel(&"Test Mode", str(isInTestMode))
	GlobalUI.createTemporaryLabel(str("TEST MODE ", "ON" if isInTestMode else "OFF"))

	setNodesVisibility()

	if isInTestMode: didEnableTestMode.emit()
	else: didDisableTestMode.emit()


## Shows the [TestMode] node itself and hides [nodesToHide] when [member isInTestMode], and vice-versa.
func setNodesVisibility() -> void:
	self.visible = isInTestMode
	for node in nodesToHide:
		node.visible = not isInTestMode

#endregion
