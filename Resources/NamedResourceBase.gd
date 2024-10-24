## Abstract base class for Resources with a named identity and a visual representation including optionally displayed name, description and icon.

@tool
class_name NamedResourceBase
extends Resource


#region Common Parameters

## The identity for an instance of this Resource.
## NOTE: This name MUST BE UNIQUE across all Resources of the same type, because components and other classes may search these Resources by their names.
@export var name: StringName:
	set(newValue):
		if newValue.is_empty():
			Debug.printWarning("Rejected attempt to set name to empty string", self)
			return
		name = newValue
		self.resource_name = name # CHECK: Does this work without @tool?

## An optional different name for displaying in the HUD and other UI. If empty, returns [member name] capitalized.
@export var displayName: String:
	get:
		if not displayName.is_empty(): return displayName
		else: return self.name.capitalize()

@export var description: String ## An optional explanation, for internal development notes or to show the player.

@export var icon: Texture2D ## An optional image to display in UI views such as [StatUI].

#endregion

