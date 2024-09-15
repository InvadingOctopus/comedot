## A [Label] linked to a [Stat] which automatically updates its text when the Stat's value changes.

class_name StatLabel
extends Container

# TBD: Choose a different name since the root node is no longer a Label?


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

@export var shouldUppercase: bool = false:
	set(newValue):
		if newValue != shouldUppercase:
			shouldUppercase = newValue
			if label: label.uppercase = shouldUppercase

@export var shouldAnimate: bool = true

@export var shouldShowText: bool = true: ## Affects the prefix and suffix labels, not the actual Stat value numbers.
	set(newValue):
		if newValue != shouldShowText:
			shouldShowText = newValue
			if label: updateStatText(false) # Update the label, without animation

@export var shouldShowIcon: bool = true:
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
@onready var label: Label = $Label
@onready var icon:  TextureRect = $Icon
#endregion


func _ready() -> void:
	applyInitialFlags()

	if stat:
		updateUI(false) # Display the initial value, without animation
		stat.changed.connect(self.onStat_changed)
	else:
		Debug.printWarning("Missing stat", str(self))


func applyInitialFlags() -> void:
	if label: label.uppercase	= shouldUppercase
	if icon:  icon.visible		= shouldShowIcon
	if shouldShowIconAfterText: arrangeControls()


func arrangeControls() -> void:
	if not shouldShowIconAfterText:
		self.move_child(icon,  0)
		self.move_child(label, 1)
	else:
		self.move_child(label, 0)
		self.move_child(icon,  1)


func onStat_changed() -> void:
	updateStatText()


func updateUI(animate: bool = self.shouldAnimate) -> void:
	updateIcon()
	updateStatText(animate)
	self.tooltip_text = stat.description


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
	var fullPrefix: String
	var fullSuffix: String

	if shouldShowText:
		fullPrefix = prefix + " " if shouldAddSpaceAfterPrefix  else prefix
		fullSuffix = " " + suffix if shouldAddSpaceBeforeSuffix else suffix

		if shouldShowStatDisplayName: fullPrefix += stat.displayName + ":"

	if minimumDigits >= 1:
		var format: String = "%0" + str(minimumDigits) + "d"
		return str(fullPrefix, format % stat.value, fullSuffix)
	else:
		return str(fullPrefix, stat.value, fullSuffix)
