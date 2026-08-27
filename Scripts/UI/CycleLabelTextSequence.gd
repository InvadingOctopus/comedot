## A [Label] that displays and cycles through a [TextSequence]
## Supports [ColoredTextSequence] formatting and optional animation per character.
## Used by [TextInteractionComponent]

class_name CycleLabelTextSequence
extends Label


#region Parameters
@export var textSequence:				TextSequence ## The list of strings to be displayed in order. See [TextSequence] or [ColoredTextSequence]
@export var shouldAnimate:				bool = true
@export var shouldClearBeforeAnimation:	bool = true  ## If `false` then the previous message "morphs" into the next message for some weird effects :)

@export_range(0.0, 10.0, 0.01) var animationDurationPerCharacter: float = 0.05
#endregion


#region State
var currentAnimation: Tween

var animationDurationForCurrentString: float: ## Returns the number of seconds to pause between each character of the current text string.
	get: return self.animationDurationPerCharacter * textSequence.getCurrentString().length() if textSequence and not textSequence.strings.is_empty() else 0.0
#endregion


#region Signals
signal didDisplayString(index: int, animation: Tween)
signal didDisplayFinalString(animation:	Tween)
signal didFinishAnimation ## Emitted only when an animation completes normally, not when [method skipCurrentAnimation] cancels it.
#endregion


#region Text & Animation

## Calls [method TextSequence.incrementIndex] then [method applyText]
## NOTE: [method TextSequence.incrementIndex] is NOT called if our [member text] is not the same as the [method TextSequence.getCurrentString]
## This allows an initial label string to be displayed before advancing the [member textSequence]
## TIP: This function may be called by a [Timer] or other scripts to automate the text display.
func displayNextText(animate: bool = self.shouldAnimate) -> void:
	# NOTE:   If our current `text` is not the current TextSequence string, re-display the current TextSequence string.
	# FIXED:  This lets the first sequence message be visible and animated instead of being skipped immediately.
	if textSequence and self.text == textSequence.getCurrentString(): textSequence.incrementIndex()
	applyText(animate)


func applyText(animate: bool = self.shouldAnimate) -> void:
	# Clear any previous animation, whether we're going to animate the next string or not
	if  currentAnimation:
		Tools.disconnectSignal(currentAnimation.finished, self.onCurrentAnimation_finished) # Don't trigger any false signals
		currentAnimation.kill()
		currentAnimation = null

	# If there's no text, there's nothing to do
	if not textSequence or textSequence.strings.is_empty():
		self.text = ""
		return

	# Apply the color first
	if textSequence:
		# DESIGN: Animating the color looks jank
		textSequence.formatLabel(self)

	var currentString: String = textSequence.getCurrentString()

	# Animate the string?
	if animate:
		if shouldClearBeforeAnimation: self.text = ""
		currentAnimation = Animations.tweenProperty(self, ^"text", currentString, self.animationDurationForCurrentString)
		Tools.connectSignal(currentAnimation.finished, self.onCurrentAnimation_finished)

	else: # or apply instantly?
		self.text = currentString

	# Signals
	didDisplayString.emit(textSequence.currentStringIndex, currentAnimation)
	if textSequence.currentStringIndex == textSequence.getSize() - 1: # Did we i
		didDisplayFinalString.emit(currentAnimation)


## Skips the current animation and displays the full string from [method TextSequence.getCurrentString]
## Returns `true` if an animation was skipped, or `false` if there was no running or paused animation.
func skipCurrentAnimation() -> bool:
	if not currentAnimation or not currentAnimation.is_valid(): return false # NOTE: Don't check is_running() because that excludes paused animations

	# UNUSED: currentAnimation.custom_step(self.animationDurationForCurrentString - currentAnimation.get_total_elapsed_time())
	Tools.disconnectSignal(currentAnimation.finished, self.onCurrentAnimation_finished)
	currentAnimation.kill() # TBD: kill() or fast-forward remaining time?
	currentAnimation = null
	if textSequence: self.text = textSequence.getCurrentString()
	return true


## Called after the current message animation has completed and the message is fully displayed.
func onCurrentAnimation_finished() -> void:
	Tools.disconnectSignal(currentAnimation.finished, self.onCurrentAnimation_finished) # Just in case
	currentAnimation = null
	didFinishAnimation.emit()

#endregion
