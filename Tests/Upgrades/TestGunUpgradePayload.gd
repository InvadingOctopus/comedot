extends UpgradePayload


static func onUpgrade_didAcquireOrLevelUp(upgrade: Upgrade, entity: Entity) -> bool:
	upgrade.printLog(str("onUpgrade_didAcquireOrLevelUp() entity: ", entity))
	
	var gunComponent: GunComponent = entity.getComponent(GunComponent)
	var mouseRotationComponent: MouseRotationComponent = entity.getComponent(MouseRotationComponent)
	gunComponent.visible = true
	gunComponent.isEnabled = true
	mouseRotationComponent.isEnabled = true

	return true


static func onUpgrade_willDiscard(upgrade: Upgrade, entity: Entity) -> bool:
	upgrade.printLog(str("onUpgrade_willDiscard() entity: ", entity))
	return false