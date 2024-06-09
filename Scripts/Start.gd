## ATTENTION: This script MUST be attached to the root node of the main scene of your game.
## "Boots" and initializes the Godoctopus Framework and applies global flags.

#class_name Start
extends Node


#region Framework Settings

@export_category("Godoctopus")
@export_group("Framework Flags")

@export var showTestBackground: bool = true

#endregion


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.hasStartScript = true
	Debug.performFrameworkChecks() # Update the warning about missing Start script
	applyGlobalFlags()


func applyGlobalFlags():
	GlobalOverlay.testBackground.visible = showTestBackground
