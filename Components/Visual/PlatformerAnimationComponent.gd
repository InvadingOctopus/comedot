## Tells the Entity's [AnimatedSprite2D] to play different animations based on its movement and the state of the [CharacterBodyComponent] and/or an [InputComponent].
## Requirements: [AnimatedSprite2D], AFTER [InputComponent] (optional) & [CharacterBodyComponent]

class_name PlatformerAnimationComponent
extends Component

# TODO: Climbing animations
# TODO: PERFORMANCE: Update animations only on movement events
# TBD: A better name? :)


#region Parameters

## If omitted, then the parent Entity's [member Entity.sprite] property is used, or the Entity ITSELF, if it is an [AnimatedSprite2D], otherwise the first matching child node of the Entity is used, if any.
@export var animatedSprite: AnimatedSprite2D:
	set(newValue):
		if newValue != animatedSprite:
			animatedSprite = newValue
			self.set_process(isEnabled and is_instance_valid(animatedSprite))

@export var idleAnimation: StringName = &"idle"
@export var walkAnimation: StringName = &"walk"
@export var jumpAnimation: StringName = &"jump"
@export var fallAnimation: StringName = &"fall"

@export var flipWhenWalkingLeft: bool = true

@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			self.set_process(isEnabled and is_instance_valid(animatedSprite)) # PERFORMANCE: Set once instead of every frame

#endregion


#region Dependencies
@onready var characterBodyComponent:CharacterBodyComponent 	= parentEntity.findFirstComponentSubclass(CharacterBodyComponent) # TBD: Include entity?
@onready var body:					CharacterBody2D			= characterBodyComponent.body
@onready var inputComponent:		InputComponent			= coComponents.get(&"InputComponent") # Optional
@onready var climbComponent:		ClimbComponent			= coComponents.get(&"ClimbComponent") # Optional

func getRequiredComponents() -> Array[Script]:
	return [CharacterBodyComponent] # Other components are optional
#endregion


func _ready() -> void:
	parentEntity.getSprite() # Let the Entity decide its own sprite, even if it's just a Sprite2D, so we can flip it when the direction changes

	if not self.animatedSprite: # If this component's property is unspecified
		if parentEntity.sprite is AnimatedSprite2D: # Try the Entity's sprite in case it's animated
			self.animatedSprite	= parentEntity.sprite
		if not self.animatedSprite: # Find some other AnimatedSprite2D if it'the Entity's primary sprite isn't one
			self.animatedSprite	= parentEntity.findFirstChildOfType(AnimatedSprite2D, true) # includeEntity
		if not self.animatedSprite: printWarning("Missing AnimatedSprite2D!")

	if inputComponent:
		Tools.connectSignal(inputComponent.didChangeHorizontalDirection, self.onInputComponent_didChangeHorizontalDirection)

	self.set_process(isEnabled and is_instance_valid(animatedSprite)) # Apply setters because Godot doesn't on initialization


func onInputComponent_didChangeHorizontalDirection() -> void:
	if not isEnabled: return
	# Even if we don't have an AnimatedSprite2D we can flip a normal Sprite2D
	(animatedSprite if self.animatedSprite else parentEntity.sprite).flip_h = true if signf(inputComponent.horizontalInput) < 0 else false # NOTE: Check the CURRENT/most recent input, NOT the `previousMovementDirection` because that would be the opposite!


func _process(_delta: float) -> void:
	# INFO: Animations are checked in order of priority: "walk" overrides "idle"

	var animationToPlay: StringName

	# If there is no InputComponent, figure out the direction from the CharacterBodyComponent
	if not inputComponent and flipWhenWalkingLeft: # Check the rarer flag first, so we don't have to check 2
		animatedSprite.flip_h = true if signf(characterBodyComponent.previousVelocity.x) < 0 else false

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
	animatedSprite.play(animationToPlay)
