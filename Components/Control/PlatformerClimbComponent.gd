## Enables vertical movement within an [Area2D] that belongs to the "climbable" Group, representing a ladder, rope or cliff etc.
## Requirements: BEFORE [CharacterBodyComponent], [PlatformerPhysicsComponent], but AFTER [PlatformerControlComponent] (in order to suppress horizontal movement on ladders etc.)

class_name PlatformerClimbComponent
extends AreaContactComponent

# DESIGN: Climbing should not be a part of PlatformerControlComponent or PlatformerPhysicsComponent because it would add a lot of extra Area2D-related bloat etc.
# TODO: Allow jumping from ladders/etc.
# TODO: Transfer between adjacent Climbable areas


#region Parameters

@export var shouldStayInClimbableArea:	bool = true  ## If `true`, then the Entity is VERTICALLY confined within the rectangular bounds of the [member activeClimbingArea] [Area2D] while [member isClimbing]. NOTE: Horizontal movement depends on [member shouldAllowHorizontalMovmement]
@export var shouldSnapToClimbableArea:	bool = false ## If `true`, then the Entity will be moved fully inside the rectangular bounds of the chosen Climbable [Area2D].
@export var shouldSnapInstantly:		bool = true  ## @experimental

## If `true`, suppresses the horizontal [member PlatformerPhysicsComponent.inputDirection] which is usually provided by [PlatformerControlComponent].
## IMPORTANT This [PlatformerClimbComponent] must come AFTER the [PlatformerControlComponent] in the Scene Tree and BEFORE the [PlatformerPhysicsComponent]
@export var shouldAllowHorizontalMovmement: bool = true

@export var isPlayerControlled:			bool = true:
	set(newValue):
		if newValue != isPlayerControlled:
			isPlayerControlled = newValue
			self.set_process_unhandled_input(isInClimbableArea and isPlayerControlled and isEnabled)

## The name of the InputEvent Action the player can press to cancel climbing, e.g. by jumping.
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
			self.set_process_unhandled_input(isInClimbableArea and isPlayerControlled and isEnabled)

## `true` if the Entity is actively climbing a ladder/rope/cliff etc.
@export_storage var isClimbing: bool = false:
	set(newValue):
		if newValue != isClimbing:
			if debugMode:
				Debug.printChange("isClimbing", isClimbing, newValue)
				emitDebugBubble(str("isClimbing->", newValue))
			isClimbing = newValue
			if platformerPhysicsComponent: platformerPhysicsComponent.isGravityEnabled = not isClimbing

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
				activeClimbingAreaBounds = Tools.getShapeBoundsInArea(activeClimbingArea)
				activeClimbingAreaGlobalBounds = Rect2(activeClimbingAreaBounds.position + activeClimbingArea.global_position, activeClimbingAreaBounds.size)
			else:
				activeClimbingAreaBounds = Rect2()
				activeClimbingAreaGlobalBounds = Rect2()

var activeClimbingAreaBounds:		Rect2
var activeClimbingAreaGlobalBounds:	Rect2
var previousClimbedArea:			Area2D

var lastVerticalInputDirection:		float

#endregion


#region Signals
signal didEnterClimbableArea(area: Area2D) ## Emitted BEFORE [signal AreaCollisionComponent.didEnterArea]
signal didExitClimbableArea(area:  Area2D) ## Emitted BEFORE [signal AreaCollisionComponent.didExitArea]
signal didStartClimb(area:	Area2D)
signal didEndClimb(area:	Area2D)
#endregion


#region Dependencies
@onready var platformerPhysicsComponent: PlatformerPhysicsComponent = coComponents.PlatformerPhysicsComponent # TBD: Static or dynamic?
@onready var characterBodyComponent: CharacterBodyComponent = coComponents.CharacterBodyComponent # TBD: Static or dynamic?
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
	self.set_process(debugMode)
	self.set_physics_process(isInClimbableArea and isEnabled)
	self.set_process_unhandled_input(isInClimbableArea and isPlayerControlled and isEnabled)

#endregion


#region Area Collisions

func onCollide(collidingNode: Node2D) -> void:
	if debugMode:
		printDebug(str("onCollide(): ", collidingNode))
		emitDebugBubble(str("+CLIMBABLE:", collidingNode), Color.YELLOW)
	self.isInClimbableArea = true
	didEnterClimbableArea.emit(collidingNode)


func onExit(exitingNode: Node2D) -> void:
	if debugMode:
		printDebug(str("onExit(): ", exitingNode))
		emitDebugBubble(str("-CLIMBABLE:", exitingNode), Color.ORANGE)
	if self.areasInContact.is_empty(): # Account for overlapping areas!
		self.isInClimbableArea = false
	didExitClimbableArea.emit(exitingNode)

#endregion


#region Climb Interface

## @experimental
func climbNearestArea() -> Area2D:
	# TODO: Implement snapping
	if areasInContact.is_empty() or not isEnabled: return null
	activeClimbingArea = getNearestClimbableArea()
	if activeClimbingArea:
		characterBodyComponent.body.velocity.y = 0 # NOTE: Stop any other vertical movement. FIXES: Gradual buildup of gravity from "bouncing" outside a Climbable etc.
		isClimbing = true
		didStartClimb.emit(activeClimbingArea)
	return activeClimbingArea


## UNIMPLEMENTED: For now, just returns the latest index from [member areasInContact]
## @experimental
func getNearestClimbableArea() -> Area2D:
	return areasInContact.back()


func stopClimbing() -> void:
	# NOTE: Don't check `isEnabled` for removals
	if activeClimbingArea:
		previousClimbedArea = activeClimbingArea
		activeClimbingArea = null
		self.isClimbing = false
		characterBodyComponent.body.velocity.y = 0 # TBD: Instantly reset vertical velocity this way?
		characterBodyComponent.queueMoveAndSlide()
		didEndClimb.emit(previousClimbedArea)

#endregion


#region Events & Per-Frame Update

func _unhandled_input(event: InputEvent) -> void:
	if not isEnabled or not isInClimbableArea: return

	if (event.is_action(GlobalInput.Actions.moveUp) or event.is_action(GlobalInput.Actions.moveDown)) \
	and not isClimbing:
		lastVerticalInputDirection = Input.get_axis(GlobalInput.Actions.moveUp, GlobalInput.Actions.moveDown)
		# If we pressed up or down, grab the ladder! (or rope or whatever)
		if not is_zero_approx(lastVerticalInputDirection): climbNearestArea()
		self.get_viewport().set_input_as_handled()

	# Jump or other input to cancel the climb
	elif isClimbing and not cancelClimbInputActionName.is_empty() and event.is_action(cancelClimbInputActionName):
		isClimbing = false
		self.get_viewport().set_input_as_handled()


# DEBUG:
func _process(_delta: float) -> void:
	if debugMode: showDebugInfo()


func _physics_process(delta: float) -> void:
	# Reactivate climbing if input is still pressed while exiting and then re-entering a Climbable area
	lastVerticalInputDirection = Input.get_axis(GlobalInput.Actions.moveUp, GlobalInput.Actions.moveDown)
	if not is_zero_approx(lastVerticalInputDirection) and not isClimbing: climbNearestArea()

	# Still not climbing? Nothing to do
	if not isClimbing: return

	# Cancel horizontal movement?
	if not shouldAllowHorizontalMovmement and not characterBodyComponent.isOnFloor: # Only when not on the ground!
		platformerPhysicsComponent.inputDirection = 0
	
	# Process vertical input

	if is_zero_approx(lastVerticalInputDirection): return

	var  verticalPositionOffset: float
	if   signf(lastVerticalInputDirection) < 0: verticalPositionOffset = -platformerPhysicsComponent.parameters.climbUpSpeed * delta
	elif signf(lastVerticalInputDirection) > 0: verticalPositionOffset = +platformerPhysicsComponent.parameters.climbDownSpeed * delta

	# Keep within bounds?
	
	if not shouldStayInClimbableArea: # If not, just move directly.
		parentEntity.position.y  += verticalPositionOffset
	
	else:
		# TODO: Perfect the expected behavior of all the flags
		# DESIGN: Get the expected movement before actually moving, In case maybe some other signal or thread or whatever accesses the position.
		var projectedRect: Rect2  = self.areaBoundsGlobal
		projectedRect.position.y += verticalPositionOffset

		# See if the projected position falls outside the Climbable area.
		var displacement: Vector2 = Tools.getRectOffsetOutsideContainer(projectedRect, activeClimbingAreaGlobalBounds)
		
		if displacement == Vector2.ZERO: # Are we going to be within the Climbable bounds?
			parentEntity.position.y += verticalPositionOffset # Then just move directly
	
		else: # Will we be outside the Climbable bounds?
			# NOTE: Recorrect the position by applying the NEGATIVE of the displacement, to put the node back inside the target area. e.g. -1 means 1 pixel outside the container's LEFT edge, so ADD 1 pixel to X.
			if not shouldAllowHorizontalMovmement: # Should we restrict horizontal movement?
				parentEntity.position.x += -displacement.x
			
			parentEntity.position.y += verticalPositionOffset - displacement.y # Or allow walking left/right outside the Climbable area?

	# TBD: Is the reset necessary?
	parentEntity.reset_physics_interpolation()
	characterBodyComponent.body.reset_physics_interpolation()

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
	Debug.watchList.climbingAreaRectGlobal	= self.activeClimbingAreaGlobalBounds
	Debug.watchList.climberRect			= self.areaBoundsGlobal
	Debug.watchList.displacement		= Tools.getRectOffsetOutsideContainer(self.areaBoundsGlobal, self.activeClimbingAreaGlobalBounds)
	Debug.watchList.lastVerticalInputDirection	= self.lastVerticalInputDirection
	Debug.watchList.velocity			= characterBodyComponent.body.velocity.y
	if platformerPhysicsComponent:
		Debug.watchList.gravity			= platformerPhysicsComponent.isGravityEnabled
		Debug.watchList.horizontalInput	= platformerPhysicsComponent.inputDirection

#endregion
