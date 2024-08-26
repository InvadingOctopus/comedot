# meta-default: true

## Description

class_name _CLASS_
extends UpgradePayload


static func onUpgrade_didAcquireOrLevelUp(upgrade: Upgrade, entity: Entity) -> bool:
	super.onUpgrade_didAcquireOrLevelUp(upgrade, entity)
	return false


static func onUpgrade_willDiscard(upgrade: Upgrade, entity: Entity) -> bool:
	super.onUpgrade_willDiscard(upgrade, entity)
	return false
