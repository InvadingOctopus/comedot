## Represents an object carried in a character's inventory.

@warning_ignore("missing_tool")
class_name InventoryItem
extends GameplayResourceBase


#region Parameters
@export var weight: float ## Optional
#endregion


#region State
var logName: String:
	get: return str(self.get_script().get_global_name(), " ", self, " ", self.name, ", weight: ", weight)
#endregion

