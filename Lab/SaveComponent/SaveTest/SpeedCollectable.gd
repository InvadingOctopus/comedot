extends Entity

func _ready() -> void:
	%CollectibleComponent.payload.payloadCallable = onCollectible_didCollect
	pass

func onCollectible_didCollect(_collectibleComponent: CollectibleComponent, collectorEntity: Entity) -> bool:
	if(collectorEntity.hasComponent(GunComponent) and collectorEntity.hasComponent(SaveComponent)):
		var saveComponent: SaveComponent = collectorEntity.getComponent(SaveComponent)
		saveComponent.updateComponentPropertyPersist(GunComponent, "cooldown", .25)
		return true
	else:
		return false
	
