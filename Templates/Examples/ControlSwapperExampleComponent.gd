## An example of swapping components from an [Entity] based on which [Area2D] it is in.

class_name ControlSwapperExampleComponent
extends AreaContactComponent


#region Constants
const indoorZoneName := "IndoorZone"
#endregion


#region Dependencies
# Preload all the required components' scenes

const jumpComponentScene:				PackedScene = preload("res://Components/Control/JumpComponent.tscn")
const platformerPhysicsComponentScene:	PackedScene = preload("res://Components/Physics/PlatformerPhysicsComponent.tscn")

const overheadPhysicsComponentScene:	PackedScene = preload("res://Components/Physics/OverheadPhysicsComponent.tscn")

#endregion


func onCollide(collidingNode: Node2D) -> void:
	super.onCollide(collidingNode)
	if collidingNode.name == indoorZoneName: enableFlyingComponentSet(false)


func onExit(exitingNode: Node2D) -> void:
	super.onExit(exitingNode)
	if exitingNode.name == indoorZoneName: enableFlyingComponentSet(true)


func enableFlyingComponentSet(isPlayerFlying: bool) -> void:
	# NOTE: Mind the order of component dependencies!
	if isPlayerFlying:
		parentEntity.removeComponents([JumpComponent, PlatformerPhysicsComponent]) # Types
		parentEntity.createNewComponents([OverheadPhysicsComponent]) # Instances
		parentEntity.findFirstChildOfType(AnimatedSprite2D).play(&"fly")
	else:
		parentEntity.removeComponents([OverheadPhysicsComponent]) # Types
		parentEntity.createNewComponents([PlatformerPhysicsComponent, JumpComponent]) # Instances
		parentEntity.move_child(coComponents.PlatformerPhysicsComponent, -1) # Put last so other components may control it
		parentEntity.findFirstChildOfType(AnimatedSprite2D).play(&"walk")

	parentEntity.move_child(coComponents.CharacterBodyComponent, -1) # Put last so other components may control it
