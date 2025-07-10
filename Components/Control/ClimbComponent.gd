## Enables vertical movement within an [Area2D] that belongs to the "climbable" Group, representing a ladder, rope or cliff etc.
## Covers several situations & edge cases like cancelling a climb if jumping or walking out of it while on a floor, grabbing on to a ladder in mid-jump, and so on.
## TIP: For "inverted gravity", modify [member CharacterBody2D.up_direction] on the [CharacterBodyComponent].
## Requirements: BEFORE [JumpComponent] & [PlatformerPhysicsComponent] & [CharacterBodyComponent] & [InputComponent] (in order to suppress horizontal input & confine movement within ladders etc.)

class_name ClimbComponent
extends AreaContactComponent

# DESIGN: Climbing should not be a part of PlatformerPhysicsComponent because it would add a lot of extra Area2D-related bloat etc.
# For now, climbing logic seems to be a separate self-contained behavior, so far.
# TODO: Prevent PlatformerPhysicsComponent from applying "friction in air" while climbing.
# TODO: Allow jumping from ladders/etc.
# TODO: Option to get knocked off Climbable if receiving damage
# TODO: Transfer between adjacent Climbable areas


#region Parameters

## If `true`, then the Entity is horizontally confined within the rectangular bounds of the [member activeClimbingArea] [Area2D] while [member isClimbing].
## NOTE: This prevents ANY movement outside the Climbable caused by ANY physics source.
## TIP: Horizontal input can be disabled via [member shouldAllowHorizontalInput]
@export var shouldConfineHorizontally:	bool = true

## If `true`, then the Entity is vertically confined within the rectangular bounds of the [member activeClimbingArea] [Area2D] while [member isClimbing].
## NOTE: This prevents ANY movement outside the Climbable caused by ANY physics source.
@export var shouldConfineVertically:	bool = true

## If `true`, then the Entity will be INSTANTLY repositioned fully inside the rectangular bounds of the chosen Climbable [Area2D].
## NOTE: Superseded by [member shouldWalkIntoClimbableArea] while [CharacterBodyComponent] [member CharacterBody2D.is_on_floor].
@export var shouldSnapToClimbableArea:	bool = false

## If `true` and the bounds of this component's [Area2D] are not fully inside the nearest Climbable [Area2D] currently in contact,
## and the Entity's [CharacterBodyComponent] [member CharacterBody2D.is_on_floor],
## then the [member PlatformerPhysicsComponent.inputDirection] will be adjusted to make the Entity walk towards the interior of the chosen Climbable [Area2D].
## NOTE: Supercededs [member shouldSnapToClimbableArea].
@export var shouldWalkIntoClimbableArea:bool = true

## If `true`, suppresses the horizontal [member InputComponent.horizontalInput].
## NOTE: Walking is always allowed when in contact with the ground or a floor platform.
## IMPORTANT: This [ClimbComponent] must come BEFORE the [PlatformerPhysicsComponent] in the Scene Tree to suppress input events.
@export var shouldAllowHorizontalInput: bool = true

@export var isPlayerControlled:			bool = true:
	set(newValue):
		if newValue != isPlayerControlled:
			isPlayerControlled = newValue
			self.set_process_unhandled_input(isInClimbableArea and isPlayerControlled and isEnabled)

## The name of the InputEvent Action the player can press to cancel climbing, e.g. by jumping.
## NOTE: Cancellation occurs as soon as the input is pressed (not on release).
@export var cancelClimbInputActionName:	StringName = GlobalInput.Actions.jump

#endregion


#region State

## `true` if the Entity is inside one or MORE [Area2D]s which belong to the [constant Global.Groups.climbable] node group.
@export_storage var isInClimbableArea: bool = false:
	set(newValue):
		if newValue != isInClimbableArea:
			if debugMode:
				Debug.printChange("isInClimbableArea", isInClimbableArea, newValue)
				emitDebugBubble(str("isInClimbableArea->", newValue), Color.GREEN if newValue else Color.RED)
			isInClimbableArea = newValue
			if not isInClimbableArea: isClimbing = false
			self.set_physics_process(isInClimbableArea and isEnabled)
			# self.set_process_unhandled_input(isInClimbableArea and isPlayerControlled and isEnabled) # REMOVED: Always check input even outside climbables, to allow pressing & holding UP/DOWN while outside climbables and then "grabbing" the climbable when entering it.

## `true` if the Entity is actively climbing a ladder/rope/cliff etc.
@export_storage var isClimbing: bool = false:
	set(newValue):
		if newValue != isClimbing:
			if debugMode:
				Debug.printChange("isClimbing", isClimbing, newValue)
				emitDebugBubble(str("isClimbing->", newValue))
			isClimbing = newValue
			if platformerPhysicsComponent: platformerPhysicsComponent.isGravityEnabled = not isClimbing
			# NOTE: Keep set_physics_process() enabled regardless of whether climbing or not, so it can watch for input when re-entering a climbable area

## The "active" Climbable [Area2D] that we're currently climbing in.
@export_storage var activeClimbingArea: Area2D:
	set(newValue):
		if newValue != activeClimbingArea:
			if debugMode:
				Debug.printChange("activeClimbingArea", activeClimbingArea, newValue)
				emitDebugBubble(str("activeClimbingArea->", newValue))
			activeClimbingArea = newValue
			# Update the bounds
			if activeClimbingArea:
				activeClimbingAreaBounds = Tools.getShapeBoundsInNode(activeClimbingArea)
				activeClimbingAreaBoundsGlobal = Rect2(activeClimbingAreaBounds.position + activeClimbingArea.global_position, activeClimbingAreaBounds.size)
			else:
				activeClimbingAreaBounds = Rect2()
				activeClimbingAreaBoundsGlobal = Rect2()

var activeClimbingAreaBounds:		Rect2
var activeClimbingAreaBoundsGlobal:	Rect2
var previousClimbedArea:			Area2D

var lastVerticalInput: float:
	set(newValue):
		if newValue != lastVerticalInput:
			if debugMode: Debug.printChange("lastVerticalInput", lastVerticalInput, newValue)
			lastVerticalInput = newValue
			lastVerticalInputDirection = int(signf(lastVerticalInput))
			isLastVerticalInputZero = is_zero_approx(lastVerticalInput)

var lastVerticalInputDirection:	int ## The sign of [member lastVerticalInput]: -1 if UP, +1 if DOWN
var isLastVerticalInputZero:	bool = true: # Start by assuming 0
	set(newValue):
		isLastVerticalInputZero = newValue
		self.set_physics_process(isInClimbableArea and isEnabled) # NOTE: Do NOT check `isLastVerticalInputZero` because `PlatformerPhysicsComponent.shouldSkipFriction` should be set every frame while climbing, even if there is no input.

#endregion


#region Signals
signal didEnterClimbableArea(area: Area2D) ## Emitted AFTER [signal AreaCollisionComponent.didEnterArea] & [method onCollide]
signal didExitClimbableArea(area:  Area2D) ## Emitted AFTER [signal AreaCollisionComponent.didExitArea] & [method onExit]
signal didStartClimb(area:	Area2D)
signal didEndClimb(area:	Area2D) # TBD: Should this be emitted by the `isClimbing` setter?
#endregion


#region Dependencies
@onready var inputComponent:			 InputComponent				= parentEntity.findFirstComponentSubclass(InputComponent) # Include subclasses to allow AI etc.
@onready var platformerPhysicsComponent: PlatformerPhysicsComponent = coComponents.PlatformerPhysicsComponent # TBD: Static or dynamic?
@onready var characterBodyComponent:	 CharacterBodyComponent		= coComponents.CharacterBodyComponent # TBD: Static or dynamic?
func getRequiredComponents() -> Array[Script]:
	return [CharacterBodyComponent, PlatformerPhysicsComponent, InputComponent]
#endregion


#region Initialization

func _ready() -> void:
	self.groupToInclude		 = Global.Groups.climbable
	self.shouldMonitorAreas  = true
	self.shouldMonitorBodies = false
	self.shouldConnectSignalsOnReady = true
	super._ready()

	# Apply setters because Godot doesn't on initialization

	self.lastVerticalInputDirection = int(signf(self.lastVerticalInput))
	self.isLastVerticalInputZero = lastVerticalInputDirection == 0

	self.set_process(debugMode)
	self.set_process_unhandled_input(isPlayerControlled and isEnabled)
	self.set_physics_process(isInClimbableArea and isEnabled)

	Tools.connectSignal(inputComponent.didProcessInput, self.onInputComponent_didProcessInput)
	Tools.connectSignal(characterBodyComponent.didMove, self.oncharacterBodyComponent_didMove) # For confinement

#endregion


#region Area Collisions

func onAreaEntered(areaEntered: Area2D) -> void:
	super.onAreaEntered(areaEntered) # DESIGN: Leave AreaContactComponent implementation untouched incase someone wants to change the `groupToInclude` at runtime,
	self.isInClimbableArea = true
	didEnterClimbableArea.emit(areaEntered)


func onAreaExited(areaExited: Area2D) -> void:
	super.onAreaExited(areaExited)
	if self.areasInContact.is_empty(): # NOTE: Only clear `isInClimbableArea` if there are no areas, to account for overlapping areas!
		self.isInClimbableArea = false
	didExitClimbableArea.emit(areaExited)

#endregion


#region Input & Interface

func onInputComponent_didProcessInput(_event: InputEvent) -> void:
	if not isEnabled: return

	# DESIGN: TBD: PERFORMANCE: Some of these `if` and `else` chains may seem redundant & excessive,
	# but they were separated for readability and maintainability, to make the logic easier to follow at a glance.

	# Copy & cache InputComponent properties for quick internal access
	# NOTE: ALWAYS update the input state even if we're not in a climbable area or not climbing, for _physics_process() and other scripts to process
	# e.g. to grab onto a ladder bywhile pressing UP/DOWN in mid-air while outside the ladder
	lastVerticalInput			= inputComponent.verticalInput
	lastVerticalInputDirection	= int(signf(lastVerticalInput))
	isLastVerticalInputZero		= is_zero_approx(lastVerticalInput)

	# Are we not climbing?
	if not isClimbing:

		# Are we in a climbable area?
		# and is it a vertical movement input?
		if isInClimbableArea \
		and not is_zero_approx(inputComponent.verticalInput):

			# NOTE: If we're on the ground, then climb ONLY if the input is UP
			if lastVerticalInputDirection < 0 or not characterBodyComponent.isOnFloor:
				startClimbing()

	# Are we already climbing?
	else:

		# First of all, is horizontal movement not allowed during climbing?
		if not self.shouldAllowHorizontalInput and not is_zero_approx(inputComponent.horizontalInput) \
		and not characterBodyComponent.isOnFloor: # Cancel only when not touching the ground! To allow walking while holding a fence or cliff etc. for example.
			inputComponent.horizontalInput = 0

		# Did we jump?
		if inputComponent.inputActionsPressed.has(GlobalInput.Actions.jump) and characterBodyComponent.isOnFloor:
			stopClimbing()
			return

		# Did we cancel climbing?
		# TBD: Cancel on "just pressed" or released?
		if not cancelClimbInputActionName.is_empty() and Input.is_action_just_pressed(cancelClimbInputActionName): # Make sure the string isn't empty first or we may match against unintended inputs!
			stopClimbing()
			return

		# Get off the ladder etc. if trying to go lower while already touching the ground
		if lastVerticalInputDirection > 0 and characterBodyComponent.isOnFloor: # NOTE: or
			stopClimbing()
			return

	# NOTE: Per-frame movement occurs in _physics_process()


## If not already climbing, uses [method climbNearestArea] to start climbing and returns the [member activeClimbingArea].
func startClimbing() -> Area2D:
	if isClimbing and activeClimbingArea: return activeClimbingArea
	# If either of the above is false then climb
	return climbNearestArea()


func climbNearestArea() -> Area2D:
	if areasInContact.is_empty() or not isEnabled:
		if debugMode: printDebug("climbNearestArea(): No areasInContact")
		return null

	var nearestClimbableArea: Area2D = findNearestClimbableArea()
	if not nearestClimbableArea: return null

	# If we're nut fully inside the nearest Climbable we're touching, walk a bit before we can climb.
	if characterBodyComponent.isOnFloor and shouldWalkIntoClimbableArea and not is_zero_approx(walkIntoArea(nearestClimbableArea).x): # NOTE: Just check for the horizontal displacement
		return null

	activeClimbingArea = nearestClimbableArea

	if activeClimbingArea:
		characterBodyComponent.body.velocity.y = 0 # NOTE: Stop any other vertical movement. FIXES: Gradual buildup of gravity from "bouncing" outside a Climbable etc.
		if shouldSnapToClimbableArea: snapToActiveClimbingArea()

		# Stop walking or flying off the ladder if trying to climb in mid-air/jump!
		# TBD: Is this necessary or the expected behavior?
		inputComponent.horizontalInput = 0
		characterBodyComponent.body.velocity.x = 0

		isClimbing = true
		didStartClimb.emit(activeClimbingArea)

	return activeClimbingArea


func findNearestClimbableArea() -> Area2D:
	if areasInContact.is_empty():  return null

	var nearestArea: Area2D
	if areasInContact.size() == 1: nearestArea = areasInContact[0]
	else: nearestArea = Tools.findNearestArea(self.area, areasInContact)

	#if debugMode: printTrace(nearestArea)
	return nearestArea


## Returns the offset of this component's [Area2D] in relation to the bounds of the [param targetRect].
## If the [param targetRect] object is thinner than the character's body, e.g. a rope or vine, then displacement is ignored, and the offset attempts to align the area centers.
func getOffsetOutsideClimbable(targetRect: Rect2) -> Vector2:
	var displacement: Vector2

	if targetRect.size.x >= self.areaBoundsGlobal.size.x:
		displacement = Tools.getRectOffsetOutsideContainer(self.areaBoundsGlobal, targetRect)

	# NOTE: If the Climbable object is thinner than the character's body, e.g. a rope or vine, then ignore the displacement,
	# because then otherwise we would always stick out on either side and never "snap" in!
	# Just try to align the centers.
	else:
		displacement.x = self.areaBoundsGlobal.get_center().x - targetRect.get_center().x # Make sure the displacement is negative if we're to the left

	return displacement


## If the [CharacterBodyComponent] [member CharacterBody2D.is_on_floor] and the rectangular bounds of this component's [Area2D] are not fully inside the nearest Climbable [Area2D],
## then [PlatformerPhysicsComponent] is used to make the character walk towards the Climbable area's interior.
## Returns: The displacement/offset outside the [param targetRect] (BEFORE the movement).
func walkIntoArea(targetArea: Area2D) -> Vector2:
	# DESIGN: Cannot use PlatformerPhysicsComponent.walkIntoRect() because ClimbComponent uses its own Area2D, not the CharacterBody2D's CollisionShape2D.

	var displacement: Vector2 = getOffsetOutsideClimbable(Tools.getShapeGlobalBounds(targetArea))

	# Walk into the interior
	if not displacement.is_zero_approx():
		# NOTE: Use the INVERSE of the displacement, because -1.0 means we're sticking out to the LEFT, so we need to move to the RIGHT
		if absf(displacement.x) > 1 or is_equal_approx(absf(displacement.x), 1): # Check the absolute value because <0 means a leftwards offset
			inputComponent.horizontalInput = signf(-displacement.x) # Set the input fully to the left or right (-1/+1)
		else:
			inputComponent.horizontalInput = -displacement.x # If the displacement is too minor, don't use the maximum -1/+1 input range

	# TBD: Neutralize inertia so we don't slide too deep into the Climbable?

	# After sending the movement command,
	if abs(displacement.x) > 1: return displacement # Check the absolute value because <0 means a leftwards offset
	else: return Vector2.ZERO # If the difference was just 1 pixel or less, just assume we're close enough


## Instantly repositions the Entity to place this component's [Area2D] inside the [member activeClimbingArea].
## Returns: The distance moved. (0,0) if no movement required or if there is no [member activeClimbingArea].
func snapToActiveClimbingArea() -> Vector2:
	if not activeClimbingArea: return Vector2.ZERO
	var displacement: Vector2 = self.getOffsetOutsideClimbable(activeClimbingAreaBoundsGlobal)
	if not displacement.is_zero_approx():
		characterBodyComponent.body.velocity = Vector2.ZERO # Stop all other inertia
		parentEntity.position += -displacement # NOTE: Recorrect the position by applying the NEGATIVE of the displacement,
		parentEntity.reset_physics_interpolation() # TBD: Is the reset necessary?
	return -displacement


func stopClimbing() -> void:
	# NOTE: Don't check `isEnabled` for removals
	if activeClimbingArea:
		self.previousClimbedArea = self.activeClimbingArea
		self.activeClimbingArea  = null
		self.isClimbing = false
		# self.lastVerticalInput = 0 # UNUSED: FIXED: Resetting `lastVerticalInput` causes unintuitive behavior if UP/DOWN is held pressed through the end of a climb and then re-entering a climbable area, because then climbing won't be reactivated.
		characterBodyComponent.body.velocity.y = 0 # TBD: Instantly reset vertical velocity this way?
		characterBodyComponent.shouldMoveThisFrame = true
		didEndClimb.emit(previousClimbedArea) # TBD: Should this be emitted by the `isClimbing` setter?

#endregion


#region Per-Frame Update

func _physics_process(delta: float) -> void:
	# NOTE: Recheck input every frame, so we can reactivate climbing if input is still pressed while exiting and then re-entering a Climbable area
	# such as when jumping out of a ladder and then touching it again in mid-air while still holding the UP input.

	if not isLastVerticalInputZero and not isClimbing \
	and (not lastVerticalInputDirection > 0 or not characterBodyComponent.isOnFloor): # Ignore DOWN input while on the ground
		climbNearestArea()

	# Still not climbing? Then nothing to do
	if not isClimbing: return

	# TODO: Disable acceleration/friction in "air" to avoid slippy-sliding while climbing
	platformerPhysicsComponent.shouldSkipAcceleration = true # FIXME: Does not produce expected behavior

	# Process vertical input
	# Multiply velocities by `lastVerticalInput` to allow for analog joystick fine-control.
	# NOTE: `PlatformerMovementParameters.climbUpSpeed` & `climbDownSpeed` should both be POSITIVE and multiplied by the `CharacterBody2D.up_direction` to allow for inverted gravity etc.

	if isLastVerticalInputZero: return

	var  verticalPositionOffset: float
	if   lastVerticalInputDirection < 0:
		verticalPositionOffset = (platformerPhysicsComponent.parameters.climbUpSpeed   *  characterBodyComponent.body.up_direction.y) * abs(lastVerticalInput) * delta
	elif lastVerticalInputDirection > 0 and not characterBodyComponent.isOnFloor: # Descend down only if not already on ground
		verticalPositionOffset = (platformerPhysicsComponent.parameters.climbDownSpeed * -characterBodyComponent.body.up_direction.y) * abs(lastVerticalInput) * delta # NOTE: Since `CharacterBody2D.up_direction` is normally -1 we have to make it +1 to climb DOWN

	parentEntity.position.y += verticalPositionOffset

	# NOTE: shouldConfineHorizontally & shouldConfineVertically will take effect in oncharacterBodyComponent_didMove()
	# to ensure that ANY movement from ANY physics source is confined within the Climbable area.
	# DESIGN: For effects that knock the character off a Climbable, like receiving damage, there should be separate flags & logic.

	parentEntity.reset_physics_interpolation() # TBD: Is the reset necessary?
	characterBodyComponent.shouldMoveThisFrame = true # TBD: Is move_and_slide() necessary?
	if debugMode: showDebugInfo() # Refresh the watchlist after all the various conditional updates


func oncharacterBodyComponent_didMove(_delta: float) -> void:
	# Confine the character inside the Climbable?
	if  not isClimbing or not activeClimbingArea \
	or (not shouldConfineHorizontally and not shouldConfineVertically): return

	var displacement: Vector2 = self.getOffsetOutsideClimbable(activeClimbingAreaBoundsGlobal)
	if debugMode: Debug.watchList.displacement = displacement

	if not displacement.is_zero_approx(): # Are we going to be within the Climbable bounds?
		# NOTE: Recorrect the position by applying the NEGATIVE of the displacement, to put the node back inside the target area. e.g. -1 means 1 pixel outside the container's LEFT edge, so ADD 1 pixel to X.
		if shouldConfineVertically:   parentEntity.position.y += -displacement.y
		if shouldConfineHorizontally:
			if not characterBodyComponent.isOnFloor: parentEntity.position.x += -displacement.x
			# NOTE: If we're on the floor, let us WALK OUT of the climbable!
			# TBD: Should this be an optional flag?
			else: stopClimbing()
		parentEntity.reset_physics_interpolation() # TBD: Is the reset necessary?

#endregion


#region Debugging

func showDebugInfo() -> void:
	# if not debugMode: return # Checked by property setter
	# SKIP: super.showDebugInfo()
	Debug.addComponentWatchList(self, {
		climbableAreas		= areasInContact,
		isInClimbableArea	= isInClimbableArea,
		isClimbing			= isClimbing,
		activeClimbingArea	= activeClimbingArea,
		climbingAreaRectGlobal	= activeClimbingAreaBoundsGlobal,
		climberRect			= areaBoundsGlobal,
		#displacement		= Tools.getRectOffsetOutsideContainer(areaBoundsGlobal, activeClimbingAreaBoundsGlobal),
		input				= lastVerticalInput,
		inputSign			= lastVerticalInputDirection,
		inputZero			= isLastVerticalInputZero,
		velocity			= characterBodyComponent.body.velocity.y,

		gravity				= platformerPhysicsComponent.isGravityEnabled if platformerPhysicsComponent else false,
		horizontalInput		= platformerPhysicsComponent.horizontalInput if platformerPhysicsComponent else 0.0,
		})


# DEBUG: Comment/uncomment this method whenever debugging is needed regardless of _physics_process() being enabled or not.
func _process(_delta: float) -> void:
	if debugMode: showDebugInfo()

#endregion
