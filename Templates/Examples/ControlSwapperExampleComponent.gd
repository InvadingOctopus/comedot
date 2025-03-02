## An example of swapping components from an [Entity] based on which [Area2D] it is in.

class_name ControlSwapperExampleComponent
extends ZoneComponent


#region Constants
const indoorZoneName := "IndoorZone"
#endregion


#region Dependencies
# Preload all the required components' scenes

const platformerControlComponentScene:	PackedScene = preload("res://Components/Control/PlatformerControlComponent.tscn")
const jumpControlComponentScene:		PackedScene = preload("res://Components/Control/JumpControlComponent.tscn")
const platformerPhysicsComponentScene:	PackedScene = preload("res://Components/Physics/PlatformerPhysicsComponent.tscn")

const overheadControlComponentScene:	PackedScene = preload("res://Components/Control/OverheadControlComponent.tscn")
const overheadPhysicsComponentScene:	PackedScene = preload("res://Components/Physics/OverheadPhysicsComponent.tscn")

#endregion


func onAreaEntered(area: Area2D) -> void:
	super.onAreaEntered(area)
	if area.name == indoorZoneName: switchComponentSet(false)


func onAreaExited(area: Area2D) -> void:
	super.onAreaExited(area)
	if area.name == indoorZoneName: switchComponentSet(true)


func switchComponentSet(isPlayerFlying: bool) -> void:
	# NOTE: Mind the order of component dependencies!
	if isPlayerFlying:
		parentEntity.removeComponents([JumpControlComponent,  PlatformerControlComponent, PlatformerPhysicsComponent]) # Types
		parentEntity.createNewComponents([OverheadPhysicsComponent, OverheadControlComponent]) # Instances
		parentEntity.findFirstChildOfType(AnimatedSprite2D).play(&"fly")
	else:
		parentEntity.removeComponents([OverheadControlComponent, OverheadPhysicsComponent]) # Types
		parentEntity.createNewComponents([PlatformerPhysicsComponent, PlatformerControlComponent, JumpControlComponent]) # Instances
		parentEntity.move_child(coComponents.PlatformerPhysicsComponent, -1) # Put last so PlatformerControlComponent can control it each frame
		parentEntity.findFirstChildOfType(AnimatedSprite2D).play(&"walk")

	parentEntity.move_child(coComponents.CharacterBodyComponent, -1) # Put last so other components can control it each frame
