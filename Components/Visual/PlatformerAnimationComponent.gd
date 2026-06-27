## Tells the Entity's [AnimatedSprite2D] to play different animations based on its movement and the state of the [CharacterBodyComponent] and/or an [InputComponent].
## TIP: Use `/Scripts/Visual/CreateSpriteFramesFromSheet.gd` to automatically create [AnimatedSprite2D] [SpriteFrames] animations from an sprite sheet image
## Requirements: [AnimatedSprite2D], AFTER [InputComponent] (optional) & [CharacterBodyComponent]

class_name PlatformerAnimationComponent
extends AnimationComponentBase

# TODO: Climbing animations
# TODO: PERFORMANCE: Update animations only on movement events
# TBD: A better name? :)


#region Parameters

@export var idleAnimation: StringName = &"idle"
@export var walkAnimation: StringName = &"walk"
@export var jumpAnimation: StringName = &"jump"
@export var fallAnimation: StringName = &"fall"

@export var flipWhenWalkingLeft: bool = true

#endregion


#region Dependencies
@onready var characterBodyComponent:CharacterBodyComponent 	= getCoComponent(CharacterBodyComponent, true) # findSubclasses # TBD: Include entity?
@onready var body:					CharacterBody2D			= characterBodyComponent.body
@onready var inputComponent:		InputComponent			= coComponents.get(&"InputComponent") # Optional
@onready var climbComponent:		ClimbComponent			= coComponents.get(&"ClimbComponent") # Optional

func getRequiredComponents() -> Array[Script]:
	return [CharacterBodyComponent] # Other components are optional
#endregion


func _ready() -> void:
	super._ready()

	if inputComponent: Tools.connectSignal(inputComponent.didChangeHorizontalDirection, self.onInputComponent_didChangeHorizontalDirection)
	# TBD: Tools.connectSignal(characterBodyComponent.didMove, self.onCharacterBodyComponent_didMove)

	self.set_physics_process(isEnabled and is_instance_valid(animatedSprite)) # Apply setters because Godot doesn't on initialization


func onInputComponent_didChangeHorizontalDirection() -> void:
	if not flipWhenWalkingLeft or not isEnabled: return
	# Even if we don't have an AnimatedSprite2D we can flip a normal Sprite2D
	(animatedSprite if self.animatedSprite else entity.sprite).flip_h = true if signf(inputComponent.horizontalInput) < 0 else false # NOTE: Check the CURRENT/most recent input, NOT the previous/change of `movementDirection` because that would be the opposite!


func _physics_process(_delta: float) -> void:
	# INFO: Animations are checked in order of priority: "walk" overrides "idle"

	# TBD: PERFORMANCE: Polling state every frame is inefficient compared to just reacting to input/physics events.
	# But updating every frame may be more "correct":
	# For example, if a moving platform slides under the character, then it would count as being "on floor"
	# even though the entity's CharacterBody2D itself did not move.
	# NOTE: Also, `CharacterBodyComponent.didMove` is emitted every frame anyway by PlatformerPhysicsComponent etc. because of gravity/friction processing etc.,
	# And signals that fire every frame may be slower than good ol' _physics_process()

	var animationToPlay: StringName

	# If there is no InputComponent, figure out the direction from the CharacterBodyComponent, without resetting it while idle
	if not inputComponent and flipWhenWalkingLeft: # Check the rarer flag first, so we don't have to check 2
		animatedSprite.flip_h = characterBodyComponent.previousVelocity.x < 0

	# Check and set animation in order of lowest priority to highest. e.g. walk overrides idle

	# NOTE: BUG: Including `body.velocity.y` in the check for "idle" and "walk" SOMETIMES causes a "walk" animation after [GunComponent] because the Y velocity remains a miniscule amount like -0.000023

	# Are we chilling?
	if not idleAnimation.is_empty() \
	and is_zero_approx(body.velocity.x):
		animationToPlay = idleAnimation

	# Are we walking?
	if not walkAnimation.is_empty() \
	and not is_zero_approx(body.velocity.x):
		animationToPlay = walkAnimation

	# Are we jumping or falling?
	# DEBUG: if debugMode: Debug.watchList.onFloor = body.is_on_floor()

	if not characterBodyComponent.isOnFloor:
		var verticalDirection: float = signf(body.velocity.y)

		if not jumpAnimation.is_empty() \
		and verticalDirection < 0.0:
			animationToPlay = jumpAnimation

		elif not fallAnimation.is_empty() \
		and verticalDirection > 0.0:
			animationToPlay = fallAnimation

	# Play the chosen animation
	if  animatedSprite.animation != animationToPlay:
		animatedSprite.play(animationToPlay)
