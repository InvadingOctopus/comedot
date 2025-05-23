## A [ScriptPayload] for an [InteractionComponent] that lets the target [InteractionControlComponent] "rider" Entity mount or ride the source "vehicle" Entity's [RideableComponent]
## TIP: A game-specific subclass of [RideableComponent] should disable the mount's [InteractionComponent] while mounted to update the UI etc.

# class_name RidePayload # Unnecessary
extends GDScript

# TBD: Rename to MountPayload? or would that be ambiguous with the more computer-associated connotation of "mounting" :')


static func onPayload_didExecute(payload: Payload, source: InteractionComponent, riderEntity: Entity) -> bool:
	if not source:
		Debug.printWarning(str("onPayload_didExecute(): Payload: ", payload, " source: ", source, " is null or not an InteractionComponent"), payload)
		return false

	var mountEntity: Entity = source.parentEntity
	if not mountEntity:
		Debug.printWarning(str("onPayload_didExecute(): Payload: ", payload, " source.parentEntity: ", mountEntity, " is null or not an Entity"), payload)
		return false

	if not riderEntity:
		Debug.printWarning(str("onPayload_didExecute(): Payload: ", payload, " target: ", riderEntity, " is null or not an Entity"), payload)
		return false

	var rideableComponent: RideableComponent = mountEntity.getComponent(RideableComponent, true) as RideableComponent # findSubclasses to include game-specific mount implementations.

	if rideableComponent.rider != riderEntity: rideableComponent.mount(riderEntity)
	else: rideableComponent.dismount()

	return true
