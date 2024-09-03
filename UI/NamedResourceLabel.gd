## Displays the name and icon of a [NamedResourceBase] and uses the [member NamedResourceBase.description] as the tooltip.

@tool
class_name NamedResourceLabel
extends GridContainer

# TBD: Should it be named "-Label" or "-UI"?


#region Parameters
@export var resource: NamedResourceBase:
	set(newValue):
		if newValue != resource:
			resource = newValue
			updateUI()
#endregion


#region State
@onready var label: Label = $Label
@onready var icon:  TextureRect = $Icon
#endregion


func _ready() -> void:
	updateUI()


func updateUI() -> void:
	if is_instance_valid(resource): 
		if label: label.text   = resource.displayName
		if icon:  icon.texture = resource.icon
		self.tooltip_text	   = resource.description
	else:
		if label: label.text   = ""
		if icon:  icon.texture = null # TBD:
		self.tooltip_text	   = ""
