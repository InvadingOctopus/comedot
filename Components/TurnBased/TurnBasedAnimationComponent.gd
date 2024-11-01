## Plays different animations on an [AnimationPlayer] or [AnimatedSprite2D] in response to various turn-based signals from the parent [TurnBasedEntity] such as [signal TurnBasedEntity.willBeginTurn] and [signal TurnBasedEntity.didEndTurn].
## Requirements: [TurnBasedEntity], [AnimationPlayer] or [AnimatedSprite2D]

class_name TurnBasedAnimationComponent
extends TurnBasedComponent


#region Parameters

## The [AnimationPlayer] or [AnimatedSprite2D] node that will play the animations. If not specified, the parent Entity's first [AnimationPlayer] or [AnimatedSprite2D] child node will be used.
@export var animationNode: Node

@export var animationForTurnWillBegin:	StringName = &"turnBegin"
@export var animationForTurnDidBegin:	StringName = &"turnBegin"
@export var animationForTurnWillUpdate:	StringName = &"turnUpdate"
@export var animationForTurnDidUpdate:	StringName = &"turnUpdate"
@export var animationForTurnWillEnd:	StringName = &"turnEnd"
@export var animationForTurnDidEnd:		StringName = &"turnEnd"

#endregion


func _ready() -> void:
	if not animationNode: findAnimationPlayer()
	connectSignals()


func findAnimationPlayer() -> void:
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


#region Parent Entity Signal Handlers
# TIP: Override any of these methods in a subclass to provide more complex animations and effects.

func onEntity_willBeginTurn() -> void:
	animationNode.play(animationForTurnWillBegin)

func onEntity_didBeginTurn() -> void:
	animationNode.play(animationForTurnDidBegin)

func onEntity_willUpdateTurn() -> void:
	animationNode.play(animationForTurnWillUpdate)

func onEntity_didUpdateTurn() -> void:
	animationNode.play(animationForTurnDidUpdate)

func onEntity_willEndTurn() -> void:
	animationNode.play(animationForTurnWillEnd)

func onEntity_didEndTurn() -> void:
	animationNode.play(animationForTurnDidEnd)

#endregion
