## An abstract base cass for [Container] [Controls] that represent a [GameplayResourceBase]-derived Resource.
## Displays the name and icon, and uses the [member GameplayResourceBase.description] as the tooltip.

@tool
class_name GameplayResourceUI
extends Container

# TODO: Better abstraction when GDScript supports overriding properties :')
# TBD: A better name? ViewableResource? :')


#region Parameters

# @export var resource: GameplayResourceBase # PLACEHOLDER: Replace with actual Resource class name & type.
# 	set(newValue):
# 		if newValue != resource:
# 			resource = newValue
# 			if self.is_node_ready(): updateUI()
		
@export var shouldAnimate:   bool = true

@export var shouldShowText:  bool = true: 
	set(newValue):
		if newValue != shouldShowText:
			shouldShowText = newValue
			if label: updateText(false) # Update the label, without animation

@export var shouldUppercase: bool = false:
	set(newValue):
		if newValue != shouldUppercase:
			shouldUppercase = newValue
			if label: label.uppercase = shouldUppercase

@export var shouldShowIcon:  bool = true:
	set(newValue):
		if newValue != shouldShowIcon:
			shouldShowIcon = newValue
			if icon: icon.visible = shouldShowIcon

@export var shouldShowIconAfterText: bool = false:
	set(newValue):
		if newValue != shouldShowIconAfterText:
			shouldShowIconAfterText = newValue
			arrangeControls()

#endregion


#region State
@onready var label:	Label		= $Label
@onready var icon:	TextureRect	= $Icon
#endregion


## May be overridden in subclass.
func _ready() -> void:
	applyInitialFlags()


func applyInitialFlags() -> void:
	if label: label.uppercase	= shouldUppercase
	if icon:  icon.visible		= shouldShowIcon
	if shouldShowIconAfterText: arrangeControls()


func arrangeControls() -> void:
	# TBD: Account for other controls in between?
	if not shouldShowIconAfterText:
		self.move_child(icon,  0)
		self.move_child(label, 1)
	else:
		self.move_child(label, 0)
		self.move_child(icon,  1)


## May be overridden in subclass.
func updateUI(animate: bool = self.shouldAnimate) -> void:
	# Update the text first in case its length changes and affects the icon.
	updateText(animate)
	updateIcon(animate)


## IMPORTANT: Abstract; MUST be overridden in subclass
@warning_ignore("unused_parameter")
func updateIcon(animate: bool = self.shouldAnimate) -> void:
	pass # icon.texture = resource.icon


## IMPORTANT: Abstract; MUST be overridden in subclass
@warning_ignore("unused_parameter")
func updateText(animate: bool = self.shouldAnimate) -> void:
	pass
	# self.label.text = resource.displayName
	# self.tooltip_text = resource.description


