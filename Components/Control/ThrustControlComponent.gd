## Applies thrust or braking to the entity's [CharacterBody2D] when the player uses the up or down controls.
## May be combined with the [TurningControlComponent] to provide spaceship or tank-like controls, similar to Asteroids.
## Use [VelocityClampComponent] to limit the speed.
## Requirements: AFTER [InputComponent], BEFORE [CharacterBodyComponent]

class_name ThrustControlComponent
extends CharacterBodyDependentComponentBase

# TODO: Add braking
# TODO: Add support for `shouldResetVelocityOnCollision` similar to [OverheadControlComponent]


#region Parameters
@export_range(0, 1000, 5.0) var thrust:		float = 100
@export_range(0, 1000, 5.0) var friction:	float = 50
@export var isEnabled: bool = true:
	set(newValue):
		isEnabled = newValue # Don't bother checking for a change
		self.set_physics_process(isEnabled) # PERFORMANCE: Set once instead of every frame
#endregion


#region Dependencies
@onready var inputComponent: InputComponent = coComponents.InputComponent # TBD: Static or dynamic?
#endregion


func _ready() -> void:
	# Set the entity's [CharacterBody2D] motion mode to Floating.
	if parentEntity.body:
		printLog("parentEntity.body.motion_mode → Floating")
		parentEntity.body.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	else:
		printWarning("Missing parentEntity.body: " + parentEntity.logName)
	self.set_physics_process(isEnabled) # Apply setter because Godot doesn't on initialization


func _physics_process(delta: float) -> void:
	var input: float = inputComponent.thrustInput

	if not is_zero_approx(input): # Apply thrust
		var direction: Vector2 = Vector2.from_angle(body.rotation) # No need for [.normalized()]
		body.velocity += direction * thrust * delta
		Debug.watchList.direction = direction
	else: # Apply friction
		body.velocity = body.velocity.move_toward(Vector2.ZERO, friction * delta)

	characterBodyComponent.shouldMoveThisFrame = true

	#Debug.watchList.velocity = body.velocity
