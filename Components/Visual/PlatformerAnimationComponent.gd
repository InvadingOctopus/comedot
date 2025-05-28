## Tells the Entity's [AnimatedSprite2D] to play different animations based on the [member PlatformerControlComponent.lastInputDirection] movement.
## If a [PlatformerControlComponent] is not present, then [member CharacterBodyComponent.previousVelocity] is used.
## Requirements: [AnimatedSprite2D], AFTER [PlatformerControlComponent] (optional) & [CharacterBodyComponent]

class_name PlatformerAnimationComponent
extends Component

# TBD: A better name? :)


#region Parameters

## If omitted, then the parent Entity is used if it is an [AnimatedSprite2D], or then the first matching child node of the parent Entity is used, if any.
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
var characterBodyComponent:		CharacterBodyComponent
var body:						CharacterBody2D
var platformerControlComponent: PlatformerControlComponent

func getRequiredComponents() -> Array[Script]:
	return [CharacterBodyComponent]
#endregion


func _ready() -> void:
	if not self.animatedSprite:
		self.animatedSprite	= parentEntity.findFirstChildOfType(AnimatedSprite2D, true) # includeEntity
		if not self.animatedSprite: printWarning("Missing AnimatedSprite2D!")

	self.characterBodyComponent		= parentEntity.findFirstComponentSubclass(CharacterBodyComponent) # TBD: Include entity?
	self.body						= characterBodyComponent.body
	self.platformerControlComponent	= coComponents.get(&"PlatformerControlComponent") # Optional

	if platformerControlComponent:
		Tools.connectSignal(platformerControlComponent.didChangeHorizontalDirection, self.onPlatformerControlComponent_didChangeHorizontalDirection)

	self.set_process(isEnabled and is_instance_valid(animatedSprite)) # Apply setters because Godot doesn't on initialization


func onPlatformerControlComponent_didChangeHorizontalDirection() -> void:
	if not isEnabled: return
	animatedSprite.flip_h = true if signf(platformerControlComponent.inputDirection) < 0 else false # NOTE: Check the CURRENT/most recent input, NOT the [lastInputDirection] because that would be the opposite!


func _process(_delta: float) -> void:
	# INFO: Animations are checked in order of priority: "walk" overrides "idle"

	var animationToPlay: StringName

	# If there is no PlatformerControlComponent, figure out the direction from the CharacterBodyComponent
	if not platformerControlComponent and flipWhenWalkingLeft: # Check the rarer flag first, so we don't have to check 2
		animatedSprite.flip_h = true if signf(characterBodyComponent.previousVelocity.x) < 0 else false
	# if debugMode and platformerControlComponent: Debug.watchList.hDirection = platformControlComponent.lastDirection

	# Check and set animation in order of lowest priority to highest. e.g. walk overrides idle

	# Are we chilling?
	if not idleAnimation.is_empty() \
	and body.velocity.is_zero_approx():
		animationToPlay = idleAnimation

	# Are we walking?
	if not walkAnimation.is_empty() \
	and not body.velocity.is_zero_approx():
		animationToPlay = walkAnimation

	# Are we jumping or falling?
	# if debugMode: Debug.watchList.onFloor = body.is_on_floor()

	if not characterBodyComponent.isOnFloor:
		var verticalDirection: float = signf(body.velocity.y)

		if not jumpAnimation.is_empty() \
		and verticalDirection < 0.0:
			animationToPlay = jumpAnimation
		elif not fallAnimation.is_empty() \
		and verticalDirection > 0.0:
			animationToPlay = fallAnimation

		# if debugMode: Debug.watchList.vDirection = verticalDirection

	# Play the chosen animation
	animatedSprite.play(animationToPlay)
