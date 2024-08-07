## A container for a `Callable` function to execute when a [CollectibleComponent] is processed by a [CollectorComponent].
## This must be subclassed and the subclass must override the [method executeCollectibleScript] method.

class_name CollectiblePayloadScript
extends Script

## A script to execute when a [CollectorComponent] picks up a [CollectibleComponent].
## May optionally return any value.
func executeCollectibleScript(collectorEntity: Entity, collectorComponent: CollectorComponent, collectibleComponent: CollectibleComponent) -> Variant:
	Debug.printWarning(str("executeCollectibleScript() not implemented! collectorEntity: ", collectorEntity, ", collectorComponent: ", collectorComponent, ", collectibleComponent: ", collectibleComponent), str(self))
	return null
