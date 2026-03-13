## Displays and cycles through a list of text strings.
## TIP: May be used for signboards and static NPC dialogues.
## @experimental

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
@export_range(0.0, 60.0, 0.01) var cooldownBeforeAutomaticNext:		float = 2 ## The pause before automatically displaying the next string if [member shouldRepeatInteractionAfterCooldown]

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

func requestToInteract(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> bool:
	return super.requestToInteract(interactorEntity, interactionControlComponent) \
		and self.textSequence and not self.textSequence.strings.is_empty()


## Executes the [member payload] and cycles through the [member textSequence]
## Returns: The updated label text, or the [Payload] result if the [Payload] FAILED.
## @experimental
@warning_ignore("unused_parameter")
func performInteraction(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> String:
	# Are we on cooldown or disabled? Then just return the current text
	if  not isEnabled \
	or (not canSkipCurrentCooldown and not is_zero_approx(cooldownTimer.time_left)): # TBD: Check cooldown again in performInteraction() or only in requestToInteract()?
		return labelControl.text if labelControl else self.text

	if not payload and not allowNoPayload:
		printWarning("performInteraction(): No payload and not allowNoPayload")
		return labelControl.text if labelControl else self.text

	self.willPerformInteraction.emit(interactorEntity)

	# If there is a Payload, run it
	if payload:
		var payloadResult: Variant = payload.execute(self, interactorEntity) if payload else null # NOTE: Keep `null` and NOT `true`; the `true` is for the function result if `allowNoPayload`
		# If the Payload failed, do not advance the text
		if not Tools.checkResult(payloadResult):
			# TBD: Return payloadResult on failure or text as always?
			self.didPerformInteraction.emit(interactorEntity, payloadResult)
			return payloadResult

	# Carry on with the text stuff

	previousInteractor = interactionControlComponent # NOTE: Update this first in case it's accessed by any cooldown-related signals.

	# Are we still animating a previous string?
	# Skip the animation and display it all at once, instead of moving to the next string before the player can fully read the previous one.
	if currentAnimation and currentAnimation.is_running():
		# UNUSED: currentAnimation.custom_step(self.animationDurationForCurrentString - currentAnimation.get_total_elapsed_time())
		currentAnimation.kill() # TBD: kill() or fast-forward remaining time?
		self.text = textSequence.getCurrentString()

		# After the previous animation has been finished, give the player some time to read;
		# if we're automatic, wait again before displaying the next message!
		if shouldRepeatInteractionAfterCooldown:
			if debugMode: emitDebugBubble("SkipText,AutoNext")
			startCooldown(cooldownBeforeAutomaticNext, true) # restartIfOnCooldown
			canSkipCurrentCooldown = true # Allow skipping the delay before the next message
		elif debugMode:
			emitDebugBubble("SkipText")

	else: # If we're not animating, there is no need to make sure the previous string has been fully displayed, just display the next string.
		displayNextText()
		# Which cooldown to use?
		if shouldRepeatInteractionAfterCooldown and not shouldAnimate:
			startCooldown(cooldownBeforeAutomaticNext, true) # restartIfOnCooldown
			canSkipCurrentCooldown = true
		else:
			startCooldown()

	self.didPerformInteraction.emit(interactorEntity, self.text)
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
		# Wait for the animation to finish before showing the next message
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
	if not interactionIndicator: return
	super.updateIndicator()
	
	# Update the Label in our own way, to avoid the "COOLDOWN" text from InteractionWithCooldownComponent etc.
	# NOTE: Don't check `text.is_empty()` so we can have empty pauses etc.
	if  labelControl:
		labelControl.text = self.text if isEnabled else "" # Clear the text when the component is disabled


func onCurrentAnimation_finished() -> void:
	if shouldRepeatInteractionAfterCooldown:
		startCooldown(cooldownBeforeAutomaticNext, true) # restartIfOnCooldown
		canSkipCurrentCooldown = true # Allow skipping the delay before the next message
	# Don't repeat automatically here; let applyText() determine whether to animate again
	Tools.disconnectSignal(self.currentAnimation.finished, self.onCurrentAnimation_finished)

#endregion
