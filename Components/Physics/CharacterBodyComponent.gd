## Manages updates to a [CharacterBody2D]. Ensures that [method CharacterBody2D.move_and_slide] is called only once every frame (to prevent excessive movement) and updates related flags.
## Components which need to process updates AFTER the [CharacterBody2D] moves must connect to the [signal CharacterBodyComponent.didMove] signal.
## NOTE: This component must come AFTER all other components which move the body, like [JumpControlComponent].
## @experimental

class_name CharacterBodyComponent
extends Component


#region Parameters

## If `null` then it will be acquired from the parent [Entity] on [method _enter_tree()]
@export var body: CharacterBody2D:
	get:
		if body == null and not skipFirstWarning:
			printWarning("body is null! Call parentEntity.getBody() to find and remember the Entity's CharacterBody2D")
		return body

## Removes any leftover "ghost" velocity when the net motion is zero. 
## Enable to avoid the "glue effect" where the character sticks to a wall until the velocity changes to the opposite direction.
## Applied after [method CharacterBody2D.move_and_slide]
@export var shouldResetVelocityIfZeroMotion: bool = true
		
@export var shouldShowDebugInfo: bool = false

#endregion


#region State

var isOnFloor:		bool ## Did the body collide with the floor after [method CharacterBody2D.move_and_slide]? (may be cached since the previous frame).

var wasOnFloor:		bool ## Was the body on the floor before the last [method CharacterBody2D.move_and_slide]?
var wasOnWall:		bool ## Was the body on a wall before the last [method CharacterBody2D.move_and_slide]?
var wasOnCeiling:	bool ## Was the body on a ceiling before the last [method CharacterBody2D.move_and_slide]?

var previousVelocity:	Vector2
var previousWallNormal:	Vector2 ## The direction of the wall we were in contact with.

## This avoids the superfluous warning when checking the [member body] for the first time in [method _enter_tree()].
var skipFirstWarning:		bool = true

var shouldMoveThisFrame:	bool = false

#endregion


#region Signals
signal didMove(delta: float) ## Emitted after [method CharacterBody2D.move_and_slide]
#endregion


# Called whenever the node enters the scene tree.
func _enter_tree() -> void:
	super._enter_tree()
	
	if self.body == null and parentEntity != null:
		self.body = parentEntity.getBody()
	
	if not body:
		printError("Missing CharacterBody2D in parent Entity: \n" + parentEntity.logFullName)


func _ready() -> void:
	cacheBodyFlags() # Cache the initial state of body flags.


func cacheBodyFlags() -> void:
	self.isOnFloor = body.is_on_floor()


func queueMoveAndSlide() -> void:
	self.shouldMoveThisFrame = true


## NOTE: If a subclass overrides this function, it MUST call super.
func _physics_process(delta: float) -> void:
	# DEBUG: printLog(str("_physics_process() delta: ", delta))
	
	if self.shouldMoveThisFrame:
		updateStateBeforeMove(delta)
		if shouldShowDebugInfo and not body.velocity.is_equal_approx(previousVelocity): printDebug(str("_physics_process() delta: ", delta, ", body.velocity: ", body.velocity))
		
		parentEntity.callOnceThisFrame(body.move_and_slide)
		updateStateAfterMove(delta)
		
		self.shouldMoveThisFrame = false # Reset the flag so we don't move more than once.
		didMove.emit(delta)
	
	if shouldShowDebugInfo: showDebugInfo()


## NOTE: If a subclass overrides this function, it MUST call super.
func updateStateBeforeMove(_delta: float) -> void:
	self.wasOnFloor		= body.is_on_floor()
	self.wasOnWall		= body.is_on_wall()
	self.wasOnCeiling	= body.is_on_ceiling()
	
	self.previousVelocity = body.velocity
	
	if wasOnWall: 
		self.previousWallNormal = body.get_wall_normal()


## NOTE: If a subclass overrides this function, it MUST call super.
func updateStateAfterMove(_delta: float) -> void:
	# NOTE: `is_on_floor()` returns `true` if the body collided with the floor on the last call of `move_and_slide()`,
	# so it makes sense to cache it after the move.
	self.isOnFloor = body.is_on_floor()
	
	# Avoid the "glue effect" where the character sticks to a wall until the velocity changes to the opposite direction.
	if self.shouldResetVelocityIfZeroMotion:
		parentEntity.callOnceThisFrame(Global.resetBodyVelocityIfZeroMotion, [body]) 
	
	if shouldShowDebugInfo and not body.velocity.is_equal_approx(previousVelocity): printDebug(str("updateStateAfterMove() body.velocity: ", body.velocity))


func showDebugInfo() -> void:
	if not shouldShowDebugInfo: return
	Debug.watchList.velocity	= body.velocity
	Debug.watchList.lastVelocity= previousVelocity
	Debug.watchList.lastMotion	= body.get_last_motion()
	Debug.watchList.isOnFloor	= isOnFloor
	Debug.watchList.wasOnFloor	= wasOnFloor
	Debug.watchList.wasOnWall	= wasOnWall
	Debug.watchList.wallNormal	= body.get_wall_normal()
