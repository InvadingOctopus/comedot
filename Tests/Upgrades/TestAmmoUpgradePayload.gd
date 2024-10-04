## A script called by a [ScriptPayload] when an [Upgrade] is "installed" into or removed from an [UpgradesComponent].


@warning_ignore("unused_parameter")
static func onPayload_didExecute(payload: Payload, source: Upgrade, target: Entity) -> Variant:
	var ammo: Stat = target.getComponent(StatsComponent).getStat(&"testAmmo")
	ammo.max += 10; ammo.setToMax()
	return true
