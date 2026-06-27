## Plays different animations on an [AnimationPlayer] or [AnimatedSprite2D] in response to various turn-based signals from this [TurnBasedComponent] such as [signal TurnBasedComponent.willBeginTurn] and [signal TurnBasedComponent.didEndTurn].
## Leave an animation name empty to skip animation for that signal.
## NOTE: Animations are played in response to this COMPONENT's signals, NOT the parent [TurnBasedEntity]'s.
## TIP: To automatically create [AnimatedSprite2D] [SpriteFrames] animations from an sprite sheet image, see `Scripts/Visual/CreateSpriteFramesFromSheet.gd`
## Requirements: [TurnBasedEntity], [AnimationPlayer] or [AnimatedSprite2D]

class_name TurnBasedAnimationComponent
extends TurnBasedComponent

# TBD:  Option to choose entity's signals or component's?
# NOTE: Lucky that methods and signals like `is_playing()` and `animation_finished` are the same for both AnimationPlayer and AnimatedSprite2D! yAy Godot :)


#region Parameters

## The [AnimationPlayer] or [AnimatedSprite2D] node that will play the animations. If not specified, the parent Entity's first [AnimationPlayer] or [AnimatedSprite2D] child node will be used.
@export var animationNode: Node

@export var defaultAnimation:			StringName = &"RESET"
@export var animationForTurnWillBegin:	StringName = TurnBasedCoordinator.TurnStates.begin
@export var animationForTurnDidBegin:	StringName = TurnBasedCoordinator.TurnStates.begin
@export var animationForTurnWillExecute:StringName = TurnBasedCoordinator.TurnStates.execute
@export var animationForTurnDidExecute:	StringName = TurnBasedCoordinator.TurnStates.execute
@export var animationForTurnWillEnd:	StringName = TurnBasedCoordinator.TurnStates.end
@export var animationForTurnDidEnd:		StringName = TurnBasedCoordinator.TurnStates.end

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

		animationNode = entity.get_node(^".") as AnimationPlayer
		if not animationNode: animationNode = entity.get_node(^".") as AnimatedSprite2D

		if animationNode:
			if debugMode: printDebug("animationNode not specified. Using parent Entity: " + entity.logName)

		else: # Or search for the first matching sibling node.
			animationNode = entity.findFirstChildOfType(AnimationPlayer)
			if not animationNode: animationNode = entity.findFirstChildOfType(AnimatedSprite2D)

			if animationNode:
				if debugMode: printDebug(str("animationNode not specified. Using first sibling found: ", animationNode))
			else:
				printWarning("No AnimationPlayer or AnimatedSprite2D!")


func connectSignals() -> void:
	# IMPORTANT: DESIGN: Connect to this COMPONENT's signals, NOT the Entity's, because this respects the scene tree's node order.
	self.willBeginTurn.connect(self.onWillBeginTurn)
	self.didBeginTurn.connect(self.onDidBeginTurn)
	self.willExecuteTurn.connect(self.onWillExecuteTurn)
	self.didExecuteTurn.connect(self.onDidExecuteTurn)
	self.willEndTurn.connect(self.onWillEndTurn)
	self.didEndTurn.connect(self.onDidEndTurn)


func playAnimation(animationName: StringName = defaultAnimation) -> void:
	if animationName.is_empty(): return
	printDebug("playAnimation(): " + animationName)
	animationNode.play(animationName)


#region Signal Handlers
# TIP: Override any of these methods in a subclass to provide more complex animations and effects.

func onWillBeginTurn() -> void:
	playAnimation(animationForTurnWillBegin)

func onDidBeginTurn() -> void:
	playAnimation(animationForTurnDidBegin)

func onWillExecuteTurn() -> void:
	playAnimation(animationForTurnWillExecute)

func onDidExecuteTurn() -> void:
	playAnimation(animationForTurnDidExecute)

func onWillEndTurn() -> void:
	playAnimation(animationForTurnWillEnd)

func onDidEndTurn() -> void:
	playAnimation(animationForTurnDidEnd)

#endregion


#region Turn Processes

func processTurnBegin() -> void:
	if shouldWaitForAnimation:
		if debugMode: printDebug("processTurnBegin(): Waiting for animation…")
		await animationNode.animation_finished

func processTurnExecute() -> void:
	if shouldWaitForAnimation:
		if debugMode: printDebug("processTurnExecute(): Waiting for animation…")
		await animationNode.animation_finished

func processTurnEnd() -> void:
	if shouldWaitForAnimation:
		if debugMode: printDebug("processTurnEnd(): Waiting for animation…")
		await animationNode.animation_finished

#endregion
