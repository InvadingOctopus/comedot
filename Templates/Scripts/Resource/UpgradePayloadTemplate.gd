# meta-default: true

## A script to execute when the associated [Upgrade] is "installed" or "uninstalled" in an [Entity]'s [UpgradesComponent].

class_name _CLASS_
extends UpgradePayload


static func onUpgrade_didAcquireOrLevelUp(upgrade: Upgrade, entity: Entity) -> bool:
	upgrade.printLog(str("onUpgrade_didAcquireOrLevelUp() entity: ", entity))
	return false


static func onUpgrade_willDiscard(upgrade: Upgrade, entity: Entity) -> bool:
	upgrade.printLog(str("onUpgrade_willDiscard() entity: ", entity))
	return false
