## An example of swapping components from an [Entity] based on which [Area2D] it is in.

class_name ControlSwapperExampleComponent
extends ComponentSwapperComponent


#region Constants
const indoorZoneName		:= &"IndoorZone"
const walkingComponentSet	:= &"walk"
const flyingComponentSet	:= &"fly"
#endregion


#region Dependencies
@onready var areaContactComponent: AreaContactComponent = coComponents.AreaContactComponent
#endregion


func _ready() -> void:
	Tools.connectSignal(areaContactComponent.didEnterArea, self.onAreaContactComponent_didEnterArea)
	Tools.connectSignal(areaContactComponent.didExitArea,  self.onAreaContactComponent_didExitArea)


func onAreaContactComponent_didEnterArea(area: Area2D) -> void:
	if area.name == indoorZoneName: enableFlyingComponentSet(false)


func onAreaContactComponent_didExitArea(area: Area2D) -> void:
	if area.name == indoorZoneName: enableFlyingComponentSet(true)


func enableFlyingComponentSet(isPlayerFlying: bool) -> void:
	# NOTE: Mind the order of component dependencies!
	if isPlayerFlying:
		self.swapToSet(flyingComponentSet)
		entity.findFirstChildOfType(AnimatedSprite2D).play(&"fly")
	else:
		self.swapToSet(walkingComponentSet)
		entity.move_child(coComponents.PlatformerPhysicsComponent, -1) # Put last so other components may control it
		entity.findFirstChildOfType(AnimatedSprite2D).play(&"walk")

	entity.move_child(coComponents.CharacterBodyComponent, -1) # Put last so other components may control it
