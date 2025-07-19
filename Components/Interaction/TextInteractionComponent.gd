## Displays and cycles through a list of text strings.
## TIP: May be used for signboards and static NPC dialogues.

class_name TextInteractionComponent
extends InteractionWithCooldownComponent


#region Parameters
## The list of text strings to display in turn. If the player interacts again after the last string, the index will wrap around and the first string will be shown.
@export var textStrings:	PackedStringArray = ["String1", "String2", "String3"]

## The color to apply to each string. This array may be a different size than the text array; the list will just wrap around.
@export var textColors:		Array[Color]  = [Color.WHITE, Color.YELLOW]

@export var shouldAnimate:							  bool = true
@export var shouldClearBeforeAnimation:				  bool = true
@export_range(0.0, 10.0, 0.1) var animationDurationPerCharacter: float = 0.05
#endregion


#region State
var currentTextIndex:		int
var currentColorIndex:		int
var currentAnimation:		Tween

var animationDurationForCurrentString: float: ## Returns the number of seconds to pause between each character of the current text string.
	get: return self.animationDurationPerCharacter * self.textStrings[currentTextIndex].length()

@onready var selfAsNode2D:	Node2D = self.get_node(^".") as Node2D
@onready var labelControl:	Label  = self.interactionIndicator as Label
#endregion


#region Signals
signal didDisplayFinalText
#endregion


func _ready() -> void:
	super._ready()
	applyTextFromArray()
	updateLabel()


## Suppresses the cooldown indication from [InteractionWithCooldownComponent] and just displays the text normally.
func updateLabel() -> void:
	# NOTE: Don't check `labelText.is_empty()` so we can have empty pauses etc.
	if  interactionIndicator is Label:
		interactionIndicator.text = self.labelText


## Returns the updated label text.
@warning_ignore("unused_parameter")
func performInteraction(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> String:
	if not isEnabled or not is_zero_approx(cooldownTimer.time_left): return self.labelText

	# Are we still animating a previous string? Skip the animation and display it all, instead of moving to the next string.
	if currentAnimation and currentAnimation.is_running():
		# currentAnimation.custom_step(self.animationDurationForCurrentString - currentAnimation.get_total_elapsed_time())
		currentAnimation.kill()
		self.labelText = self.textStrings[currentTextIndex]
	else:
		displayNextText()
		cooldownTimer.start()

	return self.labelText


## This function may be called by a [Timer] or other scripts to automate the text display.
func displayNextText() -> void:
	incrementIndices()
	applyTextFromArray()
	updateLabel()


@warning_ignore("unused_parameter")
func applyTextFromArray(indexOverride: int = self.currentTextIndex, animate: bool = self.shouldAnimate) -> void:

	if animate:
		if shouldClearBeforeAnimation: self.labelText = ""
		if currentAnimation: currentAnimation.kill()
		if labelControl:
			labelControl.label_settings.font_color = textColors[currentColorIndex]

		self.currentAnimation = Animations.tweenProperty(selfAsNode2D, ^"labelText", self.textStrings[currentTextIndex], self.animationDurationForCurrentString)
	else:
		self.labelText = self.textStrings[currentTextIndex]
		if labelControl:
			labelControl.label_settings.font_color = textColors[currentColorIndex]


		# if animate:
		# 	Animations.tweenProperty(labelControl, ^"label_settings:font_color", self.textColors[currentColorIndex], self.animationDurationForCurrentString)
		# else:

	if currentTextIndex == textStrings.size() - 1: # The last index
		didDisplayFinalText.emit()


func incrementIndices() -> void:
	# TBD: Should this be a `Tools.incrementAndWrapArrayIndex()` or would that be slower? :)
	currentTextIndex += 1
	if  currentTextIndex >= textStrings.size():
		currentTextIndex = 0

	currentColorIndex += 1
	if  currentColorIndex >= textColors.size():
		currentColorIndex = 0 # TBD: Cycle the colors or stop at the last color if there are fewer colors than strings?
