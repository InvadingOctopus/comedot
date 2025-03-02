## A component which is a [NavigationAgent2D] node for pathfinding. Directs the parent entity towards another node specified as the destination,
## while avoiding obstacles such as walls. Set the [member NavigationAgent2D.navigation_layers], [member NavigationAgent2D.avoidance_layers] and masks etc. as proper for your gameplay.
## Uses an internal [Timer] $DestinationUpdateTimer to update the final target destination, instead of every frame, though the immediate movement direction is calculated each frame.
## TIP: For a simple node-chasing component without pathfinding, use [ChaseComponent]
## @experimental

class_name NavigationComponent
extends Component


#region Parameters

## If not specified and [member shouldChasePlayerIfUnspecified], then the first [PlayerEntity] from [member GameState.players] will be chosen.
@export var destinationNode: Node2D:
	set(newValue):
		if newValue != destinationNode:
			destinationNode = newValue
			if destinationNode and self.is_node_ready():
				updateTargetPosition()
				$DestinationUpdateTimer.start()
			else:
				$DestinationUpdateTimer.stop()

## If `true` amd [member destinationNode] is `null`, the first [PlayerEntity] from [member GameState.players] will be chosen.
@export var shouldChasePlayerIfUnspecified: bool = true

@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			if isEnabled and destinationNode and self.is_node_ready(): $DestinationUpdateTimer.start()
			else: $DestinationUpdateTimer.stop()

#endregion


#region State
var selfAsAgent: NavigationAgent2D # Needed because [Component] extends [Node]
var recentDirection: Vector2
#endregion


#region Dependencies
#endregion


func _ready() -> void:
	selfAsAgent = self.get_node(^".") as NavigationAgent2D
	# if not characterBodyComponent.shouldResetVelocityIfZeroMotion:
	# 	printLog("characterBodyComponent.shouldResetVelocityIfZeroMotion = false")
	# 	characterBodyComponent.shouldResetVelocityIfZeroMotion = false

	if not destinationNode and shouldChasePlayerIfUnspecified:
		destinationNode = GameState.players.front()

	updateTargetPosition()
	$DestinationUpdateTimer.start()


func updateTargetPosition() -> void:
	if isEnabled and destinationNode:
		selfAsAgent.target_position = destinationNode.global_position


func onDestinationUpdateTimer_timeout() -> void:
	updateTargetPosition() # PERFORMANCE: Update periodically, not every frame!


func _physics_process(_delta: float) -> void:
	if not isEnabled or not destinationNode: return
	self.recentDirection = parentEntity.to_local(selfAsAgent.get_next_path_position()).normalized()
	moveTowardsDestination()
	
	if debugMode: showDebugInfo()


## Moves the parent entity in the [member recentDirection] towards the [member NavigationAgent2D.target_position]
## The default implementation sets the [member Node2D.position] directly, foregoing physics.
## NOTE: Override this method in subclasses to implement different ways to move an entity, such as via [member CharacterBody2D.velocity] physics etc.
func moveTowardsDestination() -> void:
	parentEntity.position += self.recentDirection


func showDebugInfo() -> void:
	if not debugMode: return
	Debug.watchList[str("\n— ", parentEntity.name, ".", self.name)] = ""
	Debug.watchList.recentDirection = self.recentDirection
	Debug.watchList.destination = destinationNode.global_position
	Debug.watchList.target = selfAsAgent.target_position
