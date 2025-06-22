## Enables vertical movement within an [Area2D] that belongs to the "climbable" Group, representing a ladder, rope or cliff etc.
## TIP: For "inverted gravity", modify [member CharacterBody2D.up_direction] on the [CharacterBodyComponent].
## Requirements: BEFORE [CharacterBodyComponent], [PlatformerPhysicsComponent], but AFTER [PlatformerControlComponent] (in order to suppress horizontal movement on ladders etc.)

class_name ClimbComponent
extends AreaContactComponent

# DESIGN: Climbing should not be a part of PlatformerControlComponent or PlatformerPhysicsComponent because it would add a lot of extra Area2D-related bloat etc.
# DESIGN: For now, this isn't split into multiple components like PlatformerControlComponent + PlatformerPhysicsComponent because climbing logic seems to be a separate self-contained behavior, so far.
# TODO: Allow jumping from ladders/etc.
# TODO: Transfer between adjacent Climbable areas


#region Parameters

## If `true`, then the Entity is VERTICALLY confined within the rectangular bounds of the [member activeClimbingArea] [Area2D] while [member isClimbing].
## NOTE: Horizontal movement depends on [member shouldAllowHorizontalInput]
@export var shouldStayInClimbableArea:	bool = true  

## If `true`, then the Entity will be INSTANTLY repositioned fully inside the rectangular bounds of the chosen Climbable [Area2D].
## NOTE: Superseded by [member shouldWalkIntoClimbableArea] while [CharacterBodyComponent] [member CharacterBody2D.is_on_floor].
@export var shouldSnapToClimbableArea:	bool = false

## If `true` and the bounds of this component's [Area2D] are not fully inside the nearest Climbable [Area2D] currently in contact,
## and the Entity's [CharacterBodyComponent] [member CharacterBody2D.is_on_floor],
## then the [member PlatformerPhysicsComponent.inputDirection] will be adjusted to make the Entity walk towards the interior of the chosen Climbable [Area2D].
## NOTE: Supercededs [member shouldSnapToClimbableArea].
@export var shouldWalkIntoClimbableArea:bool = true

## If `true`, suppresses the horizontal [member PlatformerPhysicsComponent.inputDirection] which is usually provided by [PlatformerControlComponent].
## IMPORTANT: This [ClimbComponent] must come AFTER the [PlatformerControlComponent] in the Scene Tree and BEFORE the [PlatformerPhysicsComponent]
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
			self.set_physics_process(isInClimbableArea and not isLastVerticalInputZero and isEnabled)
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
		self.set_physics_process(isInClimbableArea and not isLastVerticalInputZero and isEnabled)

#endregion


#region Signals
signal didEnterClimbableArea(area: Area2D) ## Emitted AFTER [signal AreaCollisionComponent.didEnterArea] & [method onCollide]
signal didExitClimbableArea(area:  Area2D) ## Emitted AFTER [signal AreaCollisionComponent.didExitArea] & [method onExit]
signal didStartClimb(area:	Area2D)
signal didEndClimb(area:	Area2D) # TBD: Should this be emitted by the `isClimbing` setter?
#endregion


#region Dependencies
@onready var platformerPhysicsComponent: PlatformerPhysicsComponent = coComponents.PlatformerPhysicsComponent # TBD: Static or dynamic?
@onready var characterBodyComponent:	 CharacterBodyComponent		= coComponents.CharacterBodyComponent # TBD: Static or dynamic?
func getRequiredComponents() -> Array[Script]:
	return [CharacterBodyComponent, PlatformerPhysicsComponent]
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
	self.set_physics_process(isInClimbableArea and not isLastVerticalInputZero and isEnabled)

#endregion


#region Area Collisions

func onAreaEntered(areaEntered: Area2D) -> void:
	super.onAreaEntered(areaEntered) # DESIGN: Leave AreaContactComponent implementation untouched incase someone wants to change the `groupToInclude` at runtime,
	if debugMode: emitDebugBubble(str("+CLIMBABLE:", areaEntered), Color.YELLOW) # Text log is generated by superclass
	self.isInClimbableArea = true
	didEnterClimbableArea.emit(areaEntered)


func onAreaExited(areaExited: Area2D) -> void:
	super.onAreaExited(areaExited)
	if debugMode: emitDebugBubble(str("-CLIMBABLE:", areaExited), Color.ORANGE)  # Text log is generated by superclass
	if self.areasInContact.is_empty(): # NOTE: Only clear `isInClimbableArea` if there are no areas, to account for overlapping areas!
		self.isInClimbableArea = false
	didExitClimbableArea.emit(areaExited)

#endregion


#region Events & Update

func _unhandled_input(event: InputEvent) -> void:
	# DESIGN: TBD: PERFORMANCE: Some of these `if` and `else` chains may be redundant, but they were separated for readability and maintainability, to make the logic easier to follow at a glance.

	if not isEnabled: return

	# NOTE: ALWAYS update the `lastVerticalInput` for _physics_process() and other scripts to process
	# e.g. to grab onto a ladder bywhile pressing UP/DOWN in mid-air while outside the ladder
	if event.is_action(GlobalInput.Actions.moveUp) or event.is_action(GlobalInput.Actions.moveDown):

		lastVerticalInput			= Input.get_axis(GlobalInput.Actions.moveUp, GlobalInput.Actions.moveDown)
		lastVerticalInputDirection	= int(signf(lastVerticalInput))
		isLastVerticalInputZero		= is_zero_approx(lastVerticalInput)

		# Before performing any climbing behavior, first check if we are in a Climbable Area2D
		if not isInClimbableArea: return

		# Start climbing/descending if we're not already climbing and press UP/DOWN
		if not isClimbing \
		and (lastVerticalInputDirection < 0 and not characterBodyComponent.isOnFloor): # NOTE: BUT if we're on the ground, then climb ONLY if the input is UP
			startClimbing()
			self.get_viewport().set_input_as_handled()

		# If we're already climbing but input DOWN while on the ground, get off the ladder/rope/etc.
		elif lastVerticalInputDirection > 0 and characterBodyComponent.isOnFloor: # NOTE: or
			stopClimbing()
			self.get_viewport().set_input_as_handled()

	# Did we JUMP while on the ground? Then just let JumpControlComponent handle the input.
	# NOTE: Even if JUMP is the `cancelClimbInputActionName`, checking this `if` condition first will result in the same behavior: cancelling the climb.
	elif event.is_action(GlobalInput.Actions.jump):
		if isClimbing and characterBodyComponent.isOnFloor: stopClimbing() # Cancel the climb if we were grabbing on to the ladder/etc.
		# NOTE: Do NOT gobble up the event with set_input_as_handled()
		return

	# If no other applicable inputs match, check for the cancelation input
	elif not cancelClimbInputActionName.is_empty() and Input.is_action_just_pressed(cancelClimbInputActionName): # Make sure the string isn't empty first or we may match against unintended inputs! # TBD: Cancel on "just pressed" or released?
		stopClimbing()
		self.get_viewport().set_input_as_handled()

	# NOTE: Per-frame movement occurs in _physics_process()


func _physics_process(delta: float) -> void:
	# NOTE: Recheck input every frame, so we can reactivate climbing if input is still pressed while exiting and then re-entering a Climbable area
	# such as when jumping out of a ladder and then touching it again in mid-air while still holding the UP input.
	# lastVerticalInput = Input.get_axis(GlobalInput.Actions.moveUp, GlobalInput.Actions.moveDown) # UNUSED: Should be handled by _unhandled_input()
	if not isLastVerticalInputZero and not isClimbing \
	and (not lastVerticalInputDirection > 0 or not characterBodyComponent.isOnFloor): # Ignore DOWN input while on the ground
		climbNearestArea()

	# Still not climbing? Then nothing to do
	if not isClimbing: return

	# Cancel horizontal movement?
	# NOTE: Check this BEFORE vertical input, because if the flag is set, horizontal movement should be disabled while on a ladder etc. regardless of whether actually climbing up/down.
	if not shouldAllowHorizontalInput and not characterBodyComponent.isOnFloor: # Only when not touching the ground! To allow walking while holding a fence or cliff etc.
		platformerPhysicsComponent.inputDirection = 0

	# Process vertical input
	# Multiply velocities by `lastVerticalInput` to allow for analog joystick fine-control.
	# NOTE: `PlatformerMovementParameters.climbUpSpeed` & `climbDownSpeed` should both be POSITIVE and multiplied by the `CharacterBody2D.up_direction` to allow for inverted gravity etc.

	if isLastVerticalInputZero: return

	var  verticalPositionOffset: float
	if   lastVerticalInputDirection < 0:
		verticalPositionOffset = (platformerPhysicsComponent.parameters.climbUpSpeed   *  characterBodyComponent.body.up_direction.y) * abs(lastVerticalInput) * delta
	elif lastVerticalInputDirection > 0 and not characterBodyComponent.isOnFloor: # Descend down only if not already on ground
		verticalPositionOffset = (platformerPhysicsComponent.parameters.climbDownSpeed * -characterBodyComponent.body.up_direction.y) * abs(lastVerticalInput) * delta # NOTE: Since `CharacterBody2D.up_direction` is normally -1 we have to make it +1 to climb DOWN

	# Keep within bounds?

	if not shouldStayInClimbableArea: # If not, just move directly.
		parentEntity.position.y += verticalPositionOffset

	else:
		# DESIGN: Cneck the expected movement before actually moving, in case maybe some other signal or thread or whatever accesses `position`
		var projectedRect: Rect2  = self.areaBoundsGlobal
		projectedRect.position.y += verticalPositionOffset

		# See if the projected position falls outside the Climbable area
		var displacement: Vector2 = Tools.getRectOffsetOutsideContainer(projectedRect, activeClimbingAreaBoundsGlobal)
		if debugMode: Debug.watchList.displacement = displacement

		# TODO: Option to allow "transfer" between different Climbable Area2Ds

		if displacement.is_zero_approx(): # Are we going to be within the Climbable bounds?
			parentEntity.position.y += verticalPositionOffset # Then just move directly

		else: # Will we be outside the Climbable bounds?
			# NOTE: Recorrect the position by applying the NEGATIVE of the displacement, to put the node back inside the target area. e.g. -1 means 1 pixel outside the container's LEFT edge, so ADD 1 pixel to X.
			if not shouldAllowHorizontalInput: # Should we restrict horizontal movement?
				parentEntity.position.x += -displacement.x

			parentEntity.position.y += verticalPositionOffset - displacement.y # Or allow walking left/right outside the Climbable area?

	parentEntity.reset_physics_interpolation() # TBD: Is the reset necessary?
	characterBodyComponent.queueMoveAndSlide() # TBD: Is move_and_slide() necessary?
	if debugMode: showDebugInfo() # Refresh the watchlist after all the various conditional updates


# DEBUG: Comment/uncomment this method whenever debugging is needed regardless of _physics_process() being enabled or not.
func _process(_delta: float) -> void:
	if debugMode: showDebugInfo()

#endregion


#region Climb Interface

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
	if characterBodyComponent.isOnFloor and shouldWalkIntoClimbableArea and not walkIntoArea(nearestClimbableArea).is_zero_approx():
		return null

	activeClimbingArea = nearestClimbableArea

	if activeClimbingArea:
		characterBodyComponent.body.velocity.y = 0 # NOTE: Stop any other vertical movement. FIXES: Gradual buildup of gravity from "bouncing" outside a Climbable etc.
		if shouldSnapToClimbableArea: snapToActiveClimbingArea()
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


## If the [CharacterBodyComponent] [member CharacterBody2D.is_on_floor] and the rectangular bounds of this component's [Area2D] are not fully inside the nearest Climbable [Area2D],
## then [PlatformerPhysicsComponent] is used to make the character walk towards the Climbable area's interior.
## Returns: The displacement/offset outside the [param targetRect] (BEFORE the movement).
func walkIntoArea(targetArea: Area2D) -> Vector2:
	# TODO: Fix seemingly unnecessary inertia & overlapping Climbables
	# DESIGN: Cannot use PlatformerPhysicsComponent.walkIntoRect() because ClimbComponent uses its own Area2D, not the CharacterBody2D's CollisionShape2D.
	
	var targetAreaBounds: Rect2 = Tools.getShapeGlobalBounds(targetArea)
	var displacement: Vector2 = Tools.getRectOffsetOutsideContainer(self.areaBoundsGlobal, targetAreaBounds)
	# Walk into the interior
	if not displacement.is_zero_approx():
		# NOTE: Use the INVERSE of the displacement, because -1.0 means we're sticking out to the LEFT, so we need to move to the RIGHT
		platformerPhysicsComponent.inputDirection = signf(-displacement.x) # Clamp input range to 0.0…1.0
		# TBD: Neutralize inertia so we don't slide too deep into the Climbable?

	return displacement


## Instantly repositions the Entity to place this component's [Area2D] inside the [member activeClimbingArea]. 
## Returns: The distance moved. (0,0) if no movement required or if there is no [member activeClimbingArea].
func snapToActiveClimbingArea() -> Vector2:
	if not activeClimbingArea: return Vector2.ZERO
	var displacement: Vector2 = Tools.getRectOffsetOutsideContainer(self.areaBoundsGlobal, activeClimbingAreaBoundsGlobal)
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
		characterBodyComponent.queueMoveAndSlide()
		didEndClimb.emit(previousClimbedArea) # TBD: Should this be emitted by the `isClimbing` setter?

#endregion


#region Debug

func showDebugInfo() -> void:
	#if not debugMode: return
	super.showDebugInfo()
	Debug.watchList[str("\n —", parentEntity.name, ".", self.name)] = ""
	Debug.watchList.climbableAreas		= self.areasInContact
	Debug.watchList.isInClimbableArea	= self.isInClimbableArea
	Debug.watchList.isClimbing			= self.isClimbing
	Debug.watchList.activeClimbingArea	= self.activeClimbingArea
	Debug.watchList.climbingAreaRectGlobal	= self.activeClimbingAreaBoundsGlobal
	Debug.watchList.climberRect			= self.areaBoundsGlobal
	#Debug.watchList.displacement		= Tools.getRectOffsetOutsideContainer(self.areaBoundsGlobal, self.activeClimbingAreaBoundsGlobal)
	Debug.watchList.input				= self.lastVerticalInput
	Debug.watchList.inputSign			= self.lastVerticalInputDirection
	Debug.watchList.inputZero			= self.isLastVerticalInputZero
	Debug.watchList.velocity			= characterBodyComponent.body.velocity.y

	if platformerPhysicsComponent:
		Debug.watchList.gravity			= platformerPhysicsComponent.isGravityEnabled
		Debug.watchList.horizontalInput	= platformerPhysicsComponent.inputDirection

#endregion
