extends UpgradePayload


static func onUpgrade_didAcquireOrLevelUp(upgrade: Upgrade, entity: Entity) -> bool:
	upgrade.printLog(str("onUpgrade_didAcquireOrLevelUp() entity: ", entity))
	entity.getComponent(OverheadPhysicsComponent).parameters.speed += 100
	return true


static func onUpgrade_willDiscard(upgrade: Upgrade, entity: Entity) -> bool:
	upgrade.printLog(str("onUpgrade_willDiscard() entity: ", entity))
	return false
