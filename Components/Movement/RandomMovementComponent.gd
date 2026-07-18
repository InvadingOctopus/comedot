## Moves the entity randomly by directly modifying its [Node2D.position]
## Does NOT use physics velocity via [CharacterBody2D] etc.
## TIP: Handy for quick testing or prototyping.
## TIP: For a more powerful "lower-level" way of "injecting" random input for other components, see [RandomInputComponent]

class_name RandomMovementComponent
extends Component


#region Parameters
# TRIED: PERFORMANCE: Using a "weighted" [Dictionary] & Tools.pickRandomFromWeightsDictionary() is slower than Array.pick_random() or randi()

## The set of directions to randomly pick from for [member nextDirection]
@export var randomVectors: PackedVector2Array = GlobalInput.directions

## Scales [member currentDirection] together with the frame delta.
@export_range(4, 2000, 4) var speed: float = 320

## The delay in seconds before randomizing the [member nextDirection]. 0 = change every frame.
@export_range(0, 60, 0.01) var randomizationInterval: float = 1.0

## If `true`, a [member nextDirection] of (0,0) is always replaced with [±1,0], [0,±1] or [±1,±1]
@export var dontAllowZeroDirection:	bool = false

## If `true`, [member currentDirection] is gradually animated towards [member nextDirection] over the [member tweenDuration]
## Irrelevant if [member randomizationInterval] is 0
@export var shouldTween: bool = true:
	set(newValue):
		if newValue != shouldTween:
			if  tween: # Stop any previous Tween
				tween.kill()
				tween = null
			shouldTween = newValue
			if not shouldTween: currentDirection = nextDirection # Snap or "teleport" right away

@export_range(0.1, 10, 0.01) var tweenDuration: float = 0.25

@export var isEnabled: bool = true:
	set(newValue):
		if newValue  != isEnabled:
			isEnabled = newValue
			if not isEnabled and tween: # Stop any previous Tween
				tween.kill()
				tween = null
				currentDirection = nextDirection # Snap/reset
			self.set_physics_process(isEnabled)

#endregion


#region State
var currentDirection:	Vector2
var nextDirection:		Vector2
var tween:				Tween

var timeToRandomize: float = 0.0 # 0 to set the initial direction right away on the 1st frame
#endregion


func _ready() -> void:
	self.set_physics_process(isEnabled) # Apply setter because Godot doesn't on init


func _physics_process(delta: float) -> void:
	# if not isEnabled: return # Checked by setter

	# Do we have any directions to choose from?
	if randomVectors.is_empty():
		if  tween:
			tween.kill()
			tween = null
		currentDirection = Vector2.ZERO
		nextDirection	 = Vector2.ZERO
		timeToRandomize	 = 0.0
		return

	# Randomize the next direction
	# TBD: Use GameState.randomNumberGenerator?
	# TBD: Maybe random movement should be allowed to be different after each Load of a Saved state...

	timeToRandomize -= delta
	if  timeToRandomize < 0 or is_zero_approx(timeToRandomize):
		timeToRandomize	= randomizationInterval
		nextDirection	= randomVectors[randi_range(0, randomVectors.size()-1)] # DUMBDOT: PackedVector2Array doesn't have pick_random() :(

		if dontAllowZeroDirection and nextDirection.is_zero_approx():
			nextDirection = GlobalInput.directions[randi_range(0, GlobalInput.directions.size()-1)]

		# Normalize diagonal movement to avoid the 41% faster curse
		nextDirection = nextDirection.normalized()

		# Retarget the current direction after each random selection
		if  tween:
			tween.kill()
			tween = null

		# Should we interpolate the movment?
		# NOTE: Make sure there's enough time to do or need interpolation,
		# because tweening cannot complete if the target changes [almost] every physics frame
		if shouldTween \
		and not currentDirection.is_equal_approx(nextDirection) \
		and (randomizationInterval > tweenDuration or is_equal_approx(randomizationInterval, tweenDuration)):
			tween = self.create_tween()
			tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
			tween.tween_property(self, ^"currentDirection", nextDirection, tweenDuration)
		else:
			currentDirection = nextDirection

	# Apply the movement
	entity.position += currentDirection * speed * delta

	if debugMode: showDebugInfo()


func showDebugInfo() -> void:
	# TBD: Visual debugging (without making this component a Node2D)
	# if not debugMode: return # Checked by caller
	Debug.addComponentWatchList(self, {
		currentDirection = currentDirection,
		nextDirection	 = nextDirection})
