## A [Container] with a [Label] and other [Control]s linked to a [Stat] which automatically updates its text when the Stat's value changes.

class_name StatUI
extends Container


#region Parameters

@export var stat: Stat

@export var shouldAnimate: bool = true

@export_group("Text")

@export var labelColor: Color = Color.WHITE

## An optional string to write before the stat's [member Stat.displayName], e.g. "Player" to make "Player Lives:".
@export var prefix: String
@export var shouldAddSpaceAfterPrefix:		bool = true

## Appends the stat's [member Stat.displayName] + a colon, AFTER the [member prefix] and before the value, e.g. "Lives:"
@export var shouldShowStatDisplayName:		bool = true
@export var shouldAddColonAfterDisplayName:	bool = true

## An optional string to add after the stat's value.
@export var suffix: String
@export var shouldAddSpaceBeforeSuffix:		bool = true

## Affects the prefix and suffix labels, not the actual Stat value numbers.
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


@export_group("Number Value")

## Affects the actual Stat value numbers, NOT the prefix and suffix labels. Useful if showing multiple symbols/icons or "pips" to represent the value, as with [StatPips].
@export var shouldShowValue: bool = true:
	set(newValue):
		if newValue != shouldShowValue:
			shouldShowValue = newValue
			if label: updateText(false) # Update the label, without animation

## If greater than 1, then smaller values will be padded with leading 0s.
@export var minimumDigits:   int = 2


@export_group("Icon")

@export var shouldShowIcon: bool = true:
	set(newValue):
		if newValue != shouldShowIcon:
			shouldShowIcon = newValue
			if icon: icon.visible = shouldShowIcon

@export var iconColor: Color = Color.WHITE

@export var shouldShowIconAfterText: bool = false:
	set(newValue):
		if newValue != shouldShowIconAfterText:
			shouldShowIconAfterText = newValue
			if self.is_node_ready(): arrangeControls()

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
		Debug.printWarning("Missing stat", self)


func applyInitialFlags() -> void:
	if label: label.uppercase	= shouldUppercase
	if icon:  icon.visible		= shouldShowIcon and stat.icon # NOTE: Don't let the TextureRect take up space if the Stat has no icon.
	if shouldShowIconAfterText: arrangeControls()


func arrangeControls() -> void:
	if not shouldShowIconAfterText:
		self.move_child(icon,  0)
		self.move_child(label, 1)
	else:
		self.move_child(label, 0)
		self.move_child(icon,  1)


func onStat_changed() -> void:
	updateText()


func updateUI(animate: bool = self.shouldAnimate) -> void:
	label.label_settings.font_color = self.labelColor
	icon.self_modulate = self.iconColor
	updateText(animate)
	updateIcon(animate)
	self.tooltip_text = stat.description


## TIP: May be overridden in subclass to customize the icon, for example, show different icons or colors for different ranges of the [member Stat.value].
func updateIcon(_animate: bool = self.shouldAnimate) -> void:
	icon.texture = stat.icon


func updateText(animate: bool = self.shouldAnimate) -> void:
	label.text = self.buildLabelText()
	if animate: Animations.animateNumberLabel(label, stat.value, stat.previousValue, self.labelColor)


## Combines the prefix + [member Stat.displayName] + value of the stat + the suffix.
## May be customized by a subclass for game specific styles,
## e.g.: drawing multiple hearts instead of a number to represent lives.
func buildLabelText() -> String:
	var fullPrefix: String
	var fullSuffix: String

	# The pre/suf -fixes

	if shouldShowText:
		# Add spaces only if there is any actual text, to avoid phantom spacing issues.
		fullPrefix = prefix + " " if shouldAddSpaceAfterPrefix  and not prefix.is_empty() else prefix
		fullSuffix = " " + suffix if shouldAddSpaceBeforeSuffix and not suffix.is_empty() else suffix

		if shouldShowStatDisplayName: fullPrefix += stat.displayName + (":" if shouldAddColonAfterDisplayName else "")

	# The value numbers

	var valueText: String

	if shouldShowValue:
		if minimumDigits >= 1:
			var format: String = "%0" + str(minimumDigits) + "d"
			valueText = format % stat.value
		else:
			valueText = str(stat.value)
	
	# DEBUG: Debug.printTrace([fullPrefix, valueText, fullSuffix], self)
	return str(fullPrefix, valueText, fullSuffix)
