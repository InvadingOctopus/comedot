## Abstract base class for Scripts for an [Upgrade] to execute when it's "installed" into an Entity's [UpgradesComponent].
## MUST be subclassed.

class_name UpgradePayload
extends Resource


@warning_ignore("unused_parameter")
static func onUpgrade_didAcquireOrLevelUp(upgrade: Upgrade, entity: Entity) -> bool:
	Debug.printLog(str("onUpgrade_didAcquireOrLevelUp() upgrade: ", upgrade, ", entity: ", entity), str(self))
	return false


@warning_ignore("unused_parameter")
static func onUpgrade_willDiscard(upgrade: Upgrade, entity: Entity) -> bool:
	Debug.printLog(str("onUpgrade_willDiscard() upgrade: ", upgrade, ", entity: ", entity), str(self))
	return false
