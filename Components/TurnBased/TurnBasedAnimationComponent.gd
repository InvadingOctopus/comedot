## Plays different animations on an [AnimationPlayer] or [AnimatedSprite2D] in response to various turn-based signals from the parent [TurnBasedEntity] such as [signal TurnBasedEntity.willBeginTurn] and [signal TurnBasedEntity.didEndTurn].
## Leave an animation name empty to skip animation for that signal.
## Requirements: [TurnBasedEntity], [AnimationPlayer] or [AnimatedSprite2D]

class_name TurnBasedAnimationComponent
extends TurnBasedComponent

# NOTE: Lucky that methods and signals like `is_playing()` and `animation_finished` are the same for both AnimationPlayer and AnimatedSprite2D! yAy Godot :)


#region Parameters

## The [AnimationPlayer] or [AnimatedSprite2D] node that will play the animations. If not specified, the parent Entity's first [AnimationPlayer] or [AnimatedSprite2D] child node will be used.
@export var animationNode: Node

@export var defaultAnimation:			StringName = &"RESET"
@export var animationForTurnWillBegin:	StringName = &"turnBegin"
@export var animationForTurnDidBegin:	StringName = &"turnBegin"
@export var animationForTurnWillUpdate:	StringName = &"turnUpdate"
@export var animationForTurnDidUpdate:	StringName = &"turnUpdate"
@export var animationForTurnWillEnd:	StringName = &"turnEnd"
@export var animationForTurnDidEnd:		StringName = &"turnEnd"

## If `true`, the component will `await` for the animation to finish.
## IMPORTANT: This may cause a delay in the turn state cycle, based on the animation duration.
@export var shouldWaitForAnimation: bool = true

#endregion


func _ready() -> void:
	if not animationNode: findAnimationNode()
	animationNode.play(defaultAnimation)
	connectSignals()


func findAnimationNode() -> void:
	# If the animation player hasn't been manually specified, try the parent entity first.
	if not animationNode:

		# Try searching for an AnimationPlayer before an AnimatedSprite2D

		animationNode = self.parentEntity.get_node(^".") as AnimationPlayer
		if not animationNode: animationNode = self.parentEntity.get_node(^".") as AnimatedSprite2D

		if animationNode:
			if shouldShowDebugInfo: printDebug("animationNode not specified. Using parent Entity: " + parentEntity.logName)

		else: # Or search for the first matching sibling node.
			animationNode = self.parentEntity.findFirstChildOfType(AnimationPlayer)
			if not animationNode: animationNode = self.parentEntity.findFirstChildOfType(AnimatedSprite2D)

			if animationNode:
				if shouldShowDebugInfo: printDebug(str("animationNode not specified. Using first sibling found: ", animationNode))
			else:
				printWarning("No AnimationPlayer or AnimatedSprite2D!")


func connectSignals() -> void:
	parentEntity.willBeginTurn.connect(self.onEntity_willBeginTurn)
	parentEntity.didBeginTurn.connect(self.onEntity_didBeginTurn)
	parentEntity.willUpdateTurn.connect(self.onEntity_willUpdateTurn)
	parentEntity.didUpdateTurn.connect(self.onEntity_didUpdateTurn)
	parentEntity.willEndTurn.connect(self.onEntity_willEndTurn)
	parentEntity.didEndTurn.connect(self.onEntity_didEndTurn)


func playAnimation(animationName: StringName = defaultAnimation) -> void:
	if animationName.is_empty(): return
	printDebug("playAnimation(): " + animationName)
	animationNode.play(animationName)


#region Parent Entity Signal Handlers
# TIP: Override any of these methods in a subclass to provide more complex animations and effects.

func onEntity_willBeginTurn() -> void:
	playAnimation(animationForTurnWillBegin)

func onEntity_didBeginTurn() -> void:
	playAnimation(animationForTurnDidBegin)

func onEntity_willUpdateTurn() -> void:
	playAnimation(animationForTurnWillUpdate)

func onEntity_didUpdateTurn() -> void:
	playAnimation(animationForTurnDidUpdate)

func onEntity_willEndTurn() -> void:
	playAnimation(animationForTurnWillEnd)

func onEntity_didEndTurn() -> void:
	playAnimation(animationForTurnDidEnd)

#endregion


#region Turn Processes

func processTurnBegin() -> void:
	if shouldWaitForAnimation:
		if shouldShowDebugInfo: printDebug("processTurnBegin(): Waiting for animation…")
		await animationNode.animation_finished

func processTurnUpdate() -> void:
	if shouldWaitForAnimation:
		if shouldShowDebugInfo: printDebug("processTurnUpdate(): Waiting for animation…")
		await animationNode.animation_finished

func processTurnEnd() -> void:
	if shouldWaitForAnimation:
		if shouldShowDebugInfo: printDebug("processTurnEnd(): Waiting for animation…")
		await animationNode.animation_finished

#endregion
