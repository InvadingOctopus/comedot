## Moves the parent entity to chase after another [Node2D] by manipulating the entity's [member InputComponent.movementDirection].
## Speed, acceleration and friction are determined by the [OverheadPhysicsComponent] and its [OverheadMovementParameters].
## NOTE: Set [member CharacterBodyComponent.shouldResetVelocityIfZeroMotion] to `false`
## TIP:  For more complex pathfinding based on Godot's Navigation nodes, use [NavigationComponent]
## Requirements: BEFORE [OverheadPhysicsComponent]

class_name ChaseComponent
extends Component


#region Parameters

## If not specified and [member shouldChasePlayerIfUnspecified], then the first [PlayerEntity] from [member GameState.players] will be chased.
@export var nodeToChase: Node2D:
	set(newValue):
		if newValue != nodeToChase:
			nodeToChase = newValue
			self.set_physics_process(isEnabled and is_instance_valid(nodeToChase))

## If `true` amd [member nodeToChase] is `null`, the first [PlayerEntity] from [member GameState.players] will be chased.
@export var shouldChasePlayerIfUnspecified: bool = true

@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			self.set_physics_process(isEnabled and is_instance_valid(nodeToChase))

#endregion


#region State
var recentChaseDirection: Vector2
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

	if not nodeToChase and shouldChasePlayerIfUnspecified:
		nodeToChase = GameState.getPlayer(0)

	self.set_physics_process(isEnabled and is_instance_valid(nodeToChase)) # Apply setters because Godot doesn't on initialization


func _physics_process(_delta: float) -> void:
	# THANKS: GDQuest@YouTube https://www.youtube.com/watch?v=GwCiGixlqiU
	# Check for presence of target to account for destroyed entities.
	if not is_instance_valid(nodeToChase): return # isEnabled checked by property setter

	self.recentChaseDirection = parentEntity.global_position.direction_to(nodeToChase.global_position).normalized()
	inputComponent.movementDirection = self.recentChaseDirection

	if debugMode:
		Debug.watchList.set(parentEntity.name + "." + self.name, recentChaseDirection)
