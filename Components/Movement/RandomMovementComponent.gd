## Moves the entity randomly, either by manipulating an [InputComponent] or setting the position directly.

class_name RandomMovementComponent
extends Component


#region Parameters

@export var horizontalMovementOptions:	Array[float] = [-1.0, 0.0, +1.0] ## The range to [method Array.pick_random] from for [member nextDirection]'s `x` value.
@export var verticalMovementOptions:	Array[float] = [-1.0, 0.0, +1.0] ## The range to [method Array.pick_random] from for [member nextDirection]'s `y` value.

@export_range(0, 60, 0.01) var randomizationInterval:	float = 1.0 ## The delay in seconds before randomizing the [member nextDirection]. 0 = change every frame.
@export var dontAllowZeroDirection:		 bool = false ## If `true`, a [member nextDirection] of (0,0) will not be allowed. ALERT: This may cause [member horizontalMovementOptions] & [member verticalMovementOptions] to be ignored.
@export var shouldUseInputComponent:	 bool = true  ## If `true`, the [member InputComponent.movementDirection] is modified. Otherwise, the entity's position is directly modified by [member currentDirection] ✕ [member speed].

@export_range(4, 2000, 4) var speed:	float = 320   ## If not [member shouldUseInputComponent], the entity's position is directly modified by [member currentDirection] multiplied by this speed.

@export var shouldTween:				 bool = true  ## If `true`, [member currentDirection] is gradually animated towards [member nextDirection] over the [member tweenDuration]
@export_range(0.1, 10, 0.01) var tweenDuration:			float = 0.25
#endregion


#region State
var currentDirection:	Vector2
var nextDirection:		Vector2
var tween:				Tween

@onready var timeToRandomize: float = randomizationInterval
#endregion


#region Dependencies
@onready var inputComponent: InputComponent = parentEntity.findFirstComponentSubclass(InputComponent)
#endregion


func _ready() -> void:
	# TBD: PERFORMANCE: Set individually or construct Vector2?
	# Construct to initialize then set components each frame, I guess?
	nextDirection = Vector2(horizontalMovementOptions.pick_random(), verticalMovementOptions.pick_random())


func _physics_process(delta: float) -> void:
	# Randomize the next direction
	if timeToRandomize < 0 or is_zero_approx(timeToRandomize):
		timeToRandomize = randomizationInterval
		nextDirection.x = horizontalMovementOptions.pick_random()
		nextDirection.y = verticalMovementOptions.pick_random()

		if dontAllowZeroDirection and nextDirection.is_zero_approx():
			nextDirection.x = Tools.plusMinusOne.pick_random()
			nextDirection.y = Tools.plusMinusOne.pick_random()
	else:
		timeToRandomize -= delta

	# Set the current direction towards the next direction
	if shouldTween:
		if tween: tween.kill()
		tween = self.create_tween()
		tween.tween_property(self, ^"currentDirection", nextDirection, tweenDuration)
	else:
		currentDirection = nextDirection

	# Apply the movement
	if shouldUseInputComponent and inputComponent:
		inputComponent.movementDirection = currentDirection
	elif not shouldUseInputComponent:
		parentEntity.position += currentDirection * speed * delta
		parentEntity.reset_physics_interpolation()

	if debugMode: showDebugInfo()


func showDebugInfo() -> void:
	# TBD: Visual debugging (without making this component a Node2D)
	# if not debugMode: return # Checked by caller
	Debug.addComponentWatchList(self, {
		currentDirection = currentDirection,
		nextDirection	 = nextDirection})
