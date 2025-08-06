## Moves the parent entity to chase after another [Node2D] by manipulating the entity's [member InputComponent.movementDirection].
## Speed, acceleration and friction are determined by components such as [PlatformerPhysicsComponent] or [OverheadPhysicsComponent] and their associated "Parameter" Resources.
## NOTE: Set [member CharacterBodyComponent.shouldResetVelocityIfZeroMotion] to `false`
## TIP:  For more complex pathfinding based on Godot's Navigation nodes, use [NavigationComponent]
## Requirements: BEFORE [InputComponent] and other input-dependent components

class_name ChaseComponent
extends Component


#region Parameters

## A specific target to chase. Overrides [member groupToChase] and [member playerIndexToChase].
## If not specified then [member groupToChase] is targeted, if any, otherwise [member playerIndexToChase] will be the fallback.
@export var nodeToChase: Node2D:
	set(newValue):
		if newValue != nodeToChase:
			nodeToChase = newValue
			updateTarget()

## If specified, then the nearest node that belongs to the specified group is targeted.
## Overridden by [member nodeToChase]. Overrides or falls back to [member playerIndexToChase].
## TIP: Enable [member shouldUpdateTargetRegularly] to retarget the nearest node as the nodes move, otherwise the first node found will always remain the target.
@export var groupToChase: StringName:
	set(newValue):
		if newValue != groupToChase:
			groupToChase = newValue
			updateTarget()

## If [member nodeToChase] is `null` and [member groupToChase] is empty, the specified [PlayerEntity] from the [member GameState.players] array will be targeted.
## An invalid index such as -1 will be ignored.
## Overridden by [member nodeToChase] & [member groupToChase].
@export var playerIndexToChase: int = 0:
	set(newValue):
		if newValue != playerIndexToChase:
			playerIndexToChase = newValue
			updateTarget()

## If `true` then the [member activeTarget] is updated every [member updateTargetInterval] seconds.
## PERFORMANCE: Should be enabled only if [member groupToChase] is used and expected to have a large amount of moving targets.
@export var shouldUpdateTargetRegularly: bool = false

## The rate at which [member activeTarget] is updated if [member shouldUpdateTargetRegularly].
## PERFORMANCE: Updating the target too frequently may decrease performance.
@export_range(0.1, 60, 0.1) var updateTargetInterval: float = 3.0

@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			self.set_physics_process(isEnabled and (is_instance_valid(activeTarget) or shouldUpdateTargetRegularly))

#endregion


#region State

@export_storage var activeTarget: Node2D: ## The actual target being chased, based on [member nodeToChase] or [member groupToChase] or [member playerIndexToChase].
	set(newValue):
		if newValue != activeTarget:
			if debugMode:
				Debug.printChange("activeTarget", activeTarget, newValue, self.debugModeTrace) # logAsTrace
				if self.is_node_ready(): emitDebugBubble.call_deferred(str("@", activeTarget.name if activeTarget else &"NONE")) # Not using call_deferred() causes crash on _ready()
			activeTarget = newValue
			self.set_physics_process(isEnabled and (is_instance_valid(activeTarget) or shouldUpdateTargetRegularly))

# TBD: @export_storage?
var recentChaseDirection: Vector2
@onready var timeToUpdateTarget: float = updateTargetInterval

#endregion


#region Dependencies
@onready var characterBodyComponent: CharacterBodyComponent = coComponents.CharacterBodyComponent
@onready var inputComponent: InputComponent = parentEntity.findFirstComponentSubclass(InputComponent)

func getRequiredComponents() -> Array[Script]:
	return [CharacterBodyComponent, InputComponent]
#endregion



func _ready() -> void:
	if not characterBodyComponent.shouldResetVelocityIfZeroMotion:
		printLog("characterBodyComponent.shouldResetVelocityIfZeroMotion = false")
		characterBodyComponent.shouldResetVelocityIfZeroMotion = false

	updateTarget()
	self.set_physics_process(isEnabled and (is_instance_valid(activeTarget) or shouldUpdateTargetRegularly)) # Apply setters because Godot doesn't on _ready()


func updateTarget() -> Node2D:
	# TBD: Fallback order

	# Got a specific victim in mind?
	if is_instance_valid(nodeToChase):
		activeTarget = nodeToChase

	# If not, get the nearest target from a list.
	elif not groupToChase.is_empty():
		activeTarget = Tools.findNearestNodeInGroup(parentEntity.global_position, groupToChase)

	# If no other targets, settle for a player.
	elif playerIndexToChase >= 0 and playerIndexToChase < GameState.players.size():
		activeTarget = GameState.getPlayer(playerIndexToChase)

	# Give up
	else:
		activeTarget = null

	if debugMode and not is_instance_valid(activeTarget):
		printDebug(str("updateTarget(): No valid target! nodeToChase: ", nodeToChase, ", groupToChase: \"", groupToChase, "\": ", Engine.get_main_loop().get_nodes_in_group(groupToChase), ", playerIndexToChase: ", playerIndexToChase))

	return activeTarget


func _physics_process(delta: float) -> void:
	# THANKS: GDQuest@YouTube https://www.youtube.com/watch?v=GwCiGixlqiU

	if shouldUpdateTargetRegularly:
		timeToUpdateTarget -= delta
		if timeToUpdateTarget < 0 or is_zero_approx(timeToUpdateTarget):
			timeToUpdateTarget = updateTargetInterval
			updateTarget()

	# Reverify instance to account for destroyed entities etc.
	if not is_instance_valid(activeTarget): return # `isEnabled` checked by property setters

	self.recentChaseDirection = parentEntity.global_position.direction_to(activeTarget.global_position).normalized()
	inputComponent.movementDirection = self.recentChaseDirection

	if debugMode: showDebugInfo()


func showDebugInfo() -> void:
	if not debugMode: return
	Debug.addComponentWatchList(self, {
		target		= activeTarget,
		direction	= recentChaseDirection})
