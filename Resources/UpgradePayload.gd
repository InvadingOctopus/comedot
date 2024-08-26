## Abstract base class for Scripts for an [Upgrade] to execute when it's "installed" into an Entity's [UpgradesComponent].
## MUST be subclassed.

class_name UpgradePayload
extends Resource


static func onUpgrade_didAcquireOrLevelUp(upgrade: Upgrade, entity: Entity) -> bool:
	Debug.printLog(str("onUpgrade_didAcquireOrLevelUp() entity: ", entity), str(upgrade))
	return false


static func onUpgrade_willDiscard(upgrade: Upgrade, entity: Entity) -> bool:
	Debug.printLog(str("onUpgrade_willDiscard() entity: ", entity), str(upgrade))
	return false
