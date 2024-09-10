## Description

class_name TestCooldownUpgradePayload
extends UpgradePayload


static func onUpgrade_didAcquireOrLevelUp(upgrade: Upgrade, entity: Entity) -> bool:
	upgrade.printLog(str("onUpgrade_didAcquireOrLevelUp() entity: ", entity))
	entity.getComponent(GunComponent).cooldown -= 0.2
	return false


static func onUpgrade_willDiscard(upgrade: Upgrade, entity: Entity) -> bool:
	upgrade.printLog(str("onUpgrade_willDiscard() entity: ", entity))
	return false

