## Displays and cycles through a list of text strings.
## TIP: May be used for signboards and static NPC dialogues.

class_name TextInteractionComponent
extends InteractionWithCooldownComponent

# INFO: There are multiple cooldowns which may be confusing:
	# The cooldown after interaction: Disable skipping, after displaying the next message: InteractionComponent.cooldownTimer.wait_time
	# The cooldown between each character when animating: `animationDurationPerCharacter` (skipable)
	# The cooldown before automatically showing the next message: `cooldownBeforeAutomaticNext` (skipable)

#region Parameters
# Default placeholders in .tscn scene file

## The list of text strings to display in turn. If the player interacts again after the last string, the index will wrap around and the first string will be shown.
## If [member text] is empty, then the [member interactionIndicator] is set to the first string if it's a [Label].
@export var textStrings:				PackedStringArray

## The color to apply to each string. If this array is a different size than the text array, the colors will wrap around.
@export var textColors:					PackedColorArray
@export var shouldAnimate:				bool = true
@export var shouldClearBeforeAnimation:	bool = true
@export_range(0.0, 10.0, 0.01) var animationDurationPerCharacter:	float = 0.05
@export_range(0.0, 60.0, 0.01) var cooldownBeforeAutomaticNext:		float = 2 ## The pause before automatically displaying the next string if [member shouldRepeatInteractionAfterCooldown].

#endregion


#region State
var currentStringIndex:		int
var currentColorIndex:		int
var currentAnimation:		Tween

var animationDurationForCurrentString: float: ## Returns the number of seconds to pause between each character of the current text string.
	get: return self.animationDurationPerCharacter * self.textStrings[currentStringIndex].length()

@onready var selfAsNode2D:	Node2D = self.get_node(^".") as Node2D
@onready var labelControl:	Label  = self.interactionIndicator as Label # TBD: Move to InteractionComponent?
#endregion


#region Signals
signal didDisplayString(index: int, animation: Tween)
signal didDisplayFinalString(animation: Tween)
#endregion


func _ready() -> void:
	super._ready()
	# NOTE: If we're automatic, do NOT apply the initial `textStrings`,
	# because that would cause the initial `textStrings` to be IMMEDIATELY REPLACED by the next string,
	# as soon as the Interactor enters our Area2D, before the player has a chance to see the initial `textStrings`.
	# displayNextText() does NOT incrementIndices() if `self.text` is not the same as `textStrings[currentStringIndex]`
	# so the initial `textStrings` will be readable.
	if not isAutomatic:
		applyTextFromArray(currentStringIndex, false) # Don't animate the initial text. Calls updateIndicator()


#region Interaction & Update

## Returns the updated label text.
@warning_ignore("unused_parameter")
func performInteraction(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> String:
	if  not isEnabled \
	or (not canSkipNextCooldown and not is_zero_approx(cooldownTimer.time_left)): # TBD: Check cooldown again in performInteraction() or only in requestToInteract()?
		return labelControl.text

	previousInteractor = interactionControlComponent # NOTE: Update this first in case it's accessed by any cooldown-related signals.

	# Are we still animating a previous string? Skip the animation and display it all, instead of moving to the next string.
	if currentAnimation and currentAnimation.is_running():
		# UNUSED: currentAnimation.custom_step(self.animationDurationForCurrentString - currentAnimation.get_total_elapsed_time())
		currentAnimation.kill() # TBD: kill() or fast-forward remaining time?
		self.text = self.textStrings[currentStringIndex]

		# If we're automatic, wait again before displaying the next message!
		if shouldRepeatInteractionAfterCooldown:
			if debugMode: emitDebugBubble("SkipText,AutoNext")
			startCooldown(cooldownBeforeAutomaticNext)
			canSkipNextCooldown = true # Allow skipping the delay before the next message
		elif debugMode:
			emitDebugBubble("SkipText")

	else: # If we're not animating, just display the next string.
		displayNextText()
		startCooldown()

	return self.text


## Calls [method InteractionControlComponent.interact] is called again on [member previousInteractor]
## May be overridden by subclasses such as [TextInteractionComponent] to add further checks on whether to repeat or not.
func repeatPreviousInteraction() -> Variant:
	if debugMode: printLog(str("repeatPreviousInteraction() with: ", previousInteractor))
	if is_instance_valid(previousInteractor):
		# NOTE: Go to the next string only if there is no ongoing animation,
		# otherwise the animation will skip and instantly display the current message,
		# which may look and feel jank in the absence of player input.
		if not currentAnimation or not currentAnimation.is_valid() or not currentAnimation.is_running():
			return previousInteractor.interact(self)
		else:
			if debugMode: printDebug(str("Not skipping currentAnimation: ", currentAnimation))
			return null
	else: return null

#endregion


#region Text & Animation

## Calls [method incrementIndices] then [method applyTextFromArray].
## NOTE: [method incrementIndices] is NOT called if [member text] is not the same as the [member currentStringIndex] of [member textStrings];
## This prevents the initial string from being immediately replaced on the first interaction when [member isAutomatic].
## TIP: This function may be called by a [Timer] or other scripts to automate the text display.
func displayNextText(animate: bool = self.shouldAnimate) -> void:
	# DESIGN: Crash on invalid array indices
	# NOTE:   If the current `text` is not the current `textStrings`, re-display the current `textStrings`.
	# FIXED:  This lets the first message be visible and animated instead of being skipped immediately if `isAutomatic`
	if self.text == textStrings[currentStringIndex]:
		incrementIndices()
	applyTextFromArray(currentStringIndex, animate)
	# updateIndicator() called by property setter


@warning_ignore("unused_parameter")
func incrementIndices() -> void:
	# TBD: Should we call `Tools.incrementAndWrapArrayIndex()` or would that be slower? :')
	currentStringIndex += 1
	if  currentStringIndex >= textStrings.size():
		currentStringIndex = 0

	currentColorIndex += 1
	if  currentColorIndex >= textColors.size():
		currentColorIndex = 0 # TBD: Cycle the colors or stop at the last color if there are fewer colors than strings?


func applyTextFromArray(indexOverride: int = self.currentStringIndex, animate: bool = self.shouldAnimate) -> void:
	# DESIGN: Crash on invalid array indices

	# Apply the color right away
	if labelControl:
		# DESIGN: Animating the color looks jank
		labelControl.label_settings.font_color = textColors[currentColorIndex] if not textColors.is_empty() else Color.WHITE

	# If there's no text, there's nothing to do
	if textStrings.is_empty():
		self.text = ""
		return

	# Clear any previous animation, whether we're going to animate the next string or not
	if currentAnimation:
		currentAnimation.kill()
		Tools.disconnectSignal(currentAnimation.finished, self.onCurrentAnimation_finished)

	# Display the string
	if animate:
		if shouldClearBeforeAnimation: self.text = ""
		currentAnimation = Animations.tweenProperty(selfAsNode2D, ^"text", self.textStrings[indexOverride], self.animationDurationForCurrentString)
		if shouldRepeatInteractionAfterCooldown:
			Tools.connectSignal(currentAnimation.finished, self.onCurrentAnimation_finished)

	else:
		self.text = self.textStrings[indexOverride] # Calls updateIndicator()

	# Signals
	didDisplayString.emit(currentStringIndex, currentAnimation)
	if currentStringIndex == textStrings.size() - 1: # The last index(index: int)
		didDisplayFinalString.emit(currentAnimation)


## Suppresses the cooldown indication from [InteractionWithCooldownComponent] and just displays the text normally.
func updateIndicator() -> void:
	# NOTE: Don't check `text.is_empty()` so we can have empty pauses etc.
	if  labelControl:
		labelControl.text = self.text


func onCurrentAnimation_finished() -> void:
	if shouldRepeatInteractionAfterCooldown:
		startCooldown(cooldownBeforeAutomaticNext)
		canSkipNextCooldown = true # Allow skipping the delay before the next message
	Tools.disconnectSignal(self.currentAnimation.finished, self.onCurrentAnimation_finished)

#endregion
