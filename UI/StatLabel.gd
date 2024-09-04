## A [Label] linked to a [Stat] which automatically updates its text when the Stat's value changes.

class_name StatLabel
extends Container


#region Parameters

@export var stat: Stat

## An optional string to write before the stat's [member Stat.displayName], e.g. "Player" to make "Player Lives:".
@export var prefix: String
@export var shouldAddSpaceAfterPrefix:  bool = true

## Appends the stat's [member Stat.displayName] + a colon, AFTER the [member prefix] and before the value, e.g. "Lives:"
@export var shouldShowStatDisplayName:  bool = true

## An optional string to add after the stat's value.
@export var suffix: String
@export var shouldAddSpaceBeforeSuffix: bool = true

## If greater than 1, then smaller values will be padded with leading 0s.
@export var minimumDigits: int = 2 

@export var shouldAnimate: bool = true

#endregion


#region State
@onready var label: Label = $Label
@onready var icon:  TextureRect = $Icon
#endregion


func _ready() -> void:
	updateIcon()

	if stat: 
		stat.changed.connect(self.onStat_changed)
		updateStatText(false) # Display the initital value, without animation
	else:
		Debug.printWarning("Missing stat", str(self))


func onStat_changed() -> void:
	updateStatText()


func updateUI() -> void:
	updateIcon()
	updateStatText()


## TIP: May be overridden in subclass to customize the icon, for example, show different icons or colors for different ranges of the [member Stat.value].
func updateIcon() -> void:
	icon.texture = stat.icon


func updateStatText(animate: bool = self.shouldAnimate) -> void:
	self.label.text = self.buildLabelText()
	if animate: Animations.animateNumberLabel(self.label, stat.value, stat.previousValue)


## Combines the prefix + [member Stat.displayName] + value of the stat + the suffix.
## May be customized by a subclass for game specific styles,
## e.g.: drawing multiple hearts instead of a number to represent lives.
func buildLabelText() -> String:
	var fullPrefix: String = prefix + " " if shouldAddSpaceAfterPrefix  else prefix
	var fullSuffix: String = " " + suffix if shouldAddSpaceBeforeSuffix else suffix

	if shouldShowStatDisplayName:
		fullPrefix += stat.displayName + ":"

	if minimumDigits >= 1:
		var format: String = "%0" + str(minimumDigits) + "d"
		return str(fullPrefix, format % stat.value, fullSuffix)
	else:
		return str(fullPrefix, stat.value, fullSuffix)