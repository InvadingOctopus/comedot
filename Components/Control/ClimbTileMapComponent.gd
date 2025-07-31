## Allows the player to climb [TileMapLayer]s representing ladders, ropes, fences etc. in a platformer game.
## Switches between freeform/per-pixel movement and grid-based movement.
## TIP: For more flexible climbing use [ClimbComponent],
## Requirements: [TileBasedPositionComponent], BEFORE [CharacterBodyComponent], [PlatformerPhysicsComponent], and [InputComponent] (in order to suppress horizontal movement on ladders etc.)
## @experimental

class_name ClimbTileMapComponent
extends Component

# TODO: Lots of jank to fix
# TODO: Option for snapping vs. walking into TileMapLayer
# TODO: Option for confinement
# TBD:  Make a generic component for switching from platformer movement to tile-based movement?


#region Parameters

## The name of the InputEvent Action the player can press to cancel climbing, e.g. by jumping.
## NOTE: Cancellation occurs as soon as the input is pressed (not on release).
@export var cancelClimbInputActionName:	StringName = GlobalInput.Actions.jump

@export var isEnabled: bool = true

#endregion


#region State

## `true` if the Entity is actively climbing a ladder/rope/cliff etc.
@export_storage var isClimbing: bool = false:
	set(newValue):
		if newValue != isClimbing:
			if debugMode:
				Debug.printChange("isClimbing", isClimbing, newValue)
				emitDebugBubble(str("isClimbing->", newValue))
			isClimbing = newValue
			setComponentStates()
			# NOTE: Keep set_physics_process() enabled regardless of whether climbing or not, so it can watch for input when re-entering a climbable TileMapLayer.

## The "active" Climbable [TileMapLayer] that we're currently climbing in.
@export_storage var activeClimbingMap: TileMapLayer:
	set(newValue):
		if newValue != activeClimbingMap:
			if debugMode:
				Debug.printChange("activeClimbingMap", activeClimbingMap, newValue)
				emitDebugBubble(str("activeClimbingMap->", newValue))
			if activeClimbingMap: previousClimbedMap = activeClimbingMap # Don't let `previousClimbedMap` become null
			activeClimbingMap = newValue
			# Update the bounds
			if activeClimbingMap:
				activeClimbingMapBoundsGlobal = Tools.getTileMapScreenBounds(activeClimbingMap)
			else:
				activeClimbingMapBoundsGlobal = Rect2()

var activeClimbingMapBoundsGlobal:	Rect2
var previousClimbedMap:				TileMapLayer

var lastVerticalInput: float:
	set(newValue):
		if newValue != lastVerticalInput:
			if debugMode: Debug.printChange("lastVerticalInput", lastVerticalInput, newValue)
			lastVerticalInput = newValue
			lastVerticalInputDirection = int(signf(lastVerticalInput))
			isLastVerticalInputZero = is_zero_approx(lastVerticalInput)

var lastVerticalInputDirection:	int ## The sign of [member lastVerticalInput]: -1 if UP, +1 if DOWN
var isLastVerticalInputZero:	bool = true # Start by assuming 0

#endregion


#region Signals
signal didStartClimb(map: TileMapLayer)
signal didEndClimb(map:   TileMapLayer) # TBD: Should this be emitted by the `isClimbing` setter?
#endregion


#region Dependencies
# TBD: Static or dynamic?

@onready var tileBasedPositionComponent: TileBasedPositionComponent = coComponents.TileBasedPositionComponent
@onready var tileBasedControlComponent:	 TileBasedControlComponent	= coComponents.TileBasedControlComponent
@onready var inputComponent:			 InputComponent				= coComponents.InputComponent
@onready var jumpControlComponent:		 JumpComponent		= coComponents.JumpComponent
@onready var platformerPhysicsComponent: PlatformerPhysicsComponent = coComponents.PlatformerPhysicsComponent
@onready var characterBodyComponent:	 CharacterBodyComponent		= coComponents.CharacterBodyComponent
func getRequiredComponents() -> Array[Script]:
	return [TileBasedPositionComponent, CharacterBodyComponent, PlatformerPhysicsComponent]
#endregion


#region Input & Setup

func _ready() -> void:
	Tools.connectSignal(inputComponent.didProcessInput, self.onInputComponent_didProcessInput)


func onInputComponent_didProcessInput(event: InputEvent) -> void:
	if not isEnabled: return

	# DESIGN: TBD: PERFORMANCE: Some of these `if` and `else` chains may seem redundant & excessive,
	# but they were separated for readability and maintainability, to make the logic easier to follow at a glance.

	# Copy & cache InputComponent properties for quick internal access
	# NOTE: ALWAYS update the input state even if we're not in a climbable TileMapLayer or not climbing, for _physics_process() and other scripts to process
	# e.g. to grab onto a ladder bywhile pressing UP/DOWN in mid-air while outside the ladder
	lastVerticalInput			= inputComponent.verticalInput
	lastVerticalInputDirection	= int(signf(lastVerticalInput))
	isLastVerticalInputZero		= is_zero_approx(lastVerticalInput)

	# Are we not climbing? Check for events that will start climbing.
	if not isClimbing:

		# NOTE: Check `event` instead of Input.is_action_just_pressed() etc to allow for AI/scripted control etc.
		# TBD:  Also check Input.is_action_just_pressed()?

		# Was a vertical movement input received?
		# NOTE: If we're on the ground, then climb ONLY if the input is UP
		if (event.is_action_pressed(GlobalInput.Actions.moveUp) \
		or (not characterBodyComponent.isOnFloor and event.is_action_pressed(GlobalInput.Actions.moveDown))):

			var map: TileMapLayer = findTileMap()
			if  map: climbTileMap(map)

	# Are we already climbing? Check for events that will end the climb.
	elif isClimbing:

		# NOTE: Check `event` instead of Input.is_action_just_pressed() etc to allow for AI/scripted control etc.

		# Did we jump?
		if event.is_action_pressed(GlobalInput.Actions.jump) and characterBodyComponent.isOnFloor:
			stopClimbing()

		# Did we cancel climbing?
		# TBD: Cancel on "just pressed" or released?
		elif not cancelClimbInputActionName.is_empty() and event.is_action_pressed(cancelClimbInputActionName): # Make sure the string isn't empty first or we may match against unintended inputs!
			stopClimbing()

		# If we try to go lower while already touching the ground, get off the ladder etc.
		elif lastVerticalInputDirection > 0 and characterBodyComponent.isOnFloor:
			stopClimbing()

		# TBD: set_input_as_handled() after each cancellation?

	if debugMode: showDebugInfo()


## Returns the [TileMapLayer] at the entity's [member Node2D.global_position].
## @experimental
func findTileMap() -> TileMapLayer:
	# TODO: A better way to get all the nodes at a given position?
	for child in self.get_tree().get_nodes_in_group(Global.Groups.climbable):
		if child is TileMapLayer:
			# Conver the entity's global position to the TileMapLayer's space.
			if Tools.isPointInTileMap(child.get_parent().to_local(parentEntity.global_position), child):
				return child
	# else
	return null


func setComponentStates() -> void:
	if jumpControlComponent: jumpControlComponent.isEnabled = not isClimbing

	if platformerPhysicsComponent:
		platformerPhysicsComponent.isEnabled = not isClimbing
		platformerPhysicsComponent.isGravityEnabled = not isClimbing

	if tileBasedPositionComponent: tileBasedPositionComponent.isEnabled = isClimbing
	if tileBasedControlComponent:	tileBasedControlComponent.isEnabled = isClimbing

#endregion


#region Climb Interface

func climbTileMap(map: TileMapLayer) -> bool:
	if isClimbing: return activeClimbingMap == map # Nothing to do if already climbing a map

	tileBasedPositionComponent.setInitialCoordinatesFromEntityPosition = true
	tileBasedPositionComponent.tileMap = map
	tileBasedPositionComponent.validateTileMap(false) # not searchForTileMap
	tileBasedPositionComponent.applyInitialCoordinates()
	activeClimbingMap = map
	isClimbing = true
	didStartClimb.emit(map)
	return true


func stopClimbing() -> bool:
	if not isClimbing: return true # Nothing to do if already not climbing
	tileBasedPositionComponent.tileMap = null
	activeClimbingMap = null # `previousClimbedMap` set by property setter
	isClimbing = false
	didEndClimb.emit(previousClimbedMap)
	return true

#endregion


func showDebugInfo() -> void:
	# if not debugMode: return # Checked by called
	Debug.addComponentWatchList(self, {
		isClimbing		= isClimbing,
		activeMap		= activeClimbingMap,
		activeBounds	= activeClimbingMapBoundsGlobal,
		lastInput		= lastVerticalInput,
		lastDirection	= lastVerticalInputDirection,
		isLastInputZero	= isLastVerticalInputZero,
		previousMap		= previousClimbedMap,
		})
