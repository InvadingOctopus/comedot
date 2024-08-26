# meta-default: true

## A script to execute when the associated [CollectibleComponent] is collected by an [Entity]'s [CollectorComponent].

class_name _CLASS_
extends CollectiblePayload


## A function to execute when a [CollectorComponent] picks up a [CollectibleComponent].
## May optionally return any value.
static func onCollectible_didCollect(collectorEntity: Entity, collectorComponent: CollectorComponent, collectibleComponent: CollectibleComponent) -> Variant:
	Debug.printLog(str("onCollectible_didCollect() collectorEntity: ", collectorEntity, ", collectorComponent: ", collectorComponent), str(collectibleComponent))
	return null
