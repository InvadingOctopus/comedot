# meta-default: true

## A node that is only visible during Test Mode.
## See [TestMode] for documentation.

class_name _CLASS_
extends TestMode


#region Game-specific Temporary Modifications

func onDidToggleTestMode() -> void:
	# Examples:
	# Debug.debugBackground.visible = isInTestMode
	# player.statsComponent.getStat(&"lives").value += 999 if isInTestMode else 0
	pass


func _process(_delta: float) -> void:
	# Perform any per-frame updates that may help with testing, such as displaying the values of other variables or clamping the physics of entities etc.
	pass  

#endregion
