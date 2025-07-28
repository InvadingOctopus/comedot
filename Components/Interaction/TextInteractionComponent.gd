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

## See [TextSequence] or [ColoredTextSequence]
@export var textSequence:				TextSequence # TBD: Is this too overengineered? :')
@export var shouldAnimate:				bool = true
@export var shouldClearBeforeAnimation:	bool = true
@export_range(0.0, 10.0, 0.01) var animationDurationPerCharacter:	float = 0.05
@export_range(0.0, 60.0, 0.01) var cooldownBeforeAutomaticNext:		float = 2 ## The pause before automatically displaying the next string if [member shouldRepeatInteractionAfterCooldown].

#endregion


#region State

@onready var selfAsNode2D:	Node2D = self.get_node(^".") as Node2D
@onready var labelControl:	Label  = self.interactionIndicator as Label # TBD: Move to InteractionComponent?

var currentAnimation:		Tween

var animationDurationForCurrentString: float: ## Returns the number of seconds to pause between each character of the current text string.
	get: return self.animationDurationPerCharacter * textSequence.getCurrentString().length()

#endregion


#region Signals
signal didDisplayString(index: int, animation: Tween)
signal didDisplayFinalString(animation: Tween)
#endregion


func _ready() -> void:
	super._ready()
	# NOTE: If we're automatic, do NOT apply the initial `textSequence` string,
	# because that would cause the initial `textSequence` string to be IMMEDIATELY REPLACED by the next string,
	# as soon as the Interactor enters our Area2D, before the player has a chance to see the initial `textSequence`.
	# displayNextText() does NOT `textSequence.incrementIndex()` if `self.text` is not the same as `textSequence.getCurrentString()`
	# so the initial `textSequence` will be readable.
	if not isAutomatic:
		applyText(false) # Don't animate the initial text. Calls updateIndicator()


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
		self.text = textSequence.getCurrentString()

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

## Calls [method TextSequence.incrementIndex] then [method applyText].
## NOTE: [method TextSequence.incrementIndex] is NOT called if [member text] is not the same as the [method TextSequence.getCurrentString];
## This prevents the initial string from being immediately replaced on the first interaction when [member isAutomatic].
## TIP: This function may be called by a [Timer] or other scripts to automate the text display.
func displayNextText(animate: bool = self.shouldAnimate) -> void:
	# NOTE:   If the current `text` is not the current TextSequence string, re-display the current TextSequence string.
	# FIXED:  This lets the first message be visible and animated instead of being skipped immediately if `isAutomatic`
	if self.text == textSequence.getCurrentString():
		textSequence.incrementIndex()
	applyText(animate)
	# updateIndicator() called by property setter


func applyText(animate: bool = self.shouldAnimate) -> void:
	# Apply the color first
	if labelControl:
		# DESIGN: Animating the color looks jank
		textSequence.formatLabel(labelControl)

	# If there's no text, there's nothing to do
	if textSequence.strings.is_empty():
		self.text = ""
		return

	var currentString: String = textSequence.getCurrentString()

	# Clear any previous animation, whether we're going to animate the next string or not
	if currentAnimation:
		currentAnimation.kill()
		Tools.disconnectSignal(currentAnimation.finished, self.onCurrentAnimation_finished)

	# Display the string
	if animate:
		if shouldClearBeforeAnimation: self.text = ""
		currentAnimation = Animations.tweenProperty(selfAsNode2D, ^"text", currentString, self.animationDurationForCurrentString)
		if shouldRepeatInteractionAfterCooldown:
			Tools.connectSignal(currentAnimation.finished, self.onCurrentAnimation_finished)

	else:
		self.text = currentString # Calls updateIndicator()

	# Signals
	didDisplayString.emit(textSequence.currentStringIndex, currentAnimation)
	if textSequence.currentStringIndex == textSequence.getSize() - 1: # The last index
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
