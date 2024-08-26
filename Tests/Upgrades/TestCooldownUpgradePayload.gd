## Description

class_name TestCooldownUpgradePayload
extends UpgradePayload


static func onUpgrade_didAcquireOrLevelUp(upgrade: Upgrade, entity: Entity) -> bool:
	super.onUpgrade_didAcquireOrLevelUp(upgrade, entity)
	entity.getComponent(GunComponent).cooldown -= 0.2
	return false


static func onUpgrade_willDiscard(upgrade: Upgrade, entity: Entity) -> bool:
	super.onUpgrade_willDiscard(upgrade, entity)
	return false

