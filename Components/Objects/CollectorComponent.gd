## When this component collides with a [CollectibleComponent], the "[Payload]" of the collectible is executed.
## The "payload" may be a new [Component] to add to the collector [Entity], or a change in an [Stat], or a custom script or [Callable] function/method to execute].

class_name CollectorComponent
extends Component


#region Parameters
@export var isEnabled: bool = true:
	set(newValue):
		isEnabled = newValue
		if  area:
			# `DISABLE_MODE_REMOVE` excludes this Area2D from physics while not `isEnabled` and emits signals for existing contacts when re-enabled.
			area.set_deferred(&"process_mode", self.defaultProcessMode if isEnabled else Node.PROCESS_MODE_DISABLED) # set_deferred() avoids the Godot error: "Function blocked during in/out signal"
#endregion


#region State
var area: Area2D ## The [Area2D] which represents this collector, which may be this component's own node.
var defaultProcessMode: Node.ProcessMode
#endregion


#region Signals
signal didCollideCollectible(collectibleComponent: CollectibleComponent)
signal didCollect(collectibleComponent: CollectibleComponent, payload: Variant, result: Variant)
#endregion


func _ready() -> void:
	if not area: area = self.get_node(^".") as Area2D
	self.defaultProcessMode = self.process_mode
	if  area:
		area.disable_mode = CollisionObject2D.DISABLE_MODE_REMOVE # Exclude from physics processing when disabled
		area.process_mode = self.defaultProcessMode if isEnabled else Node.PROCESS_MODE_DISABLED


func onAreaEntered(areaEntered: Area2D) -> void:
	if not isEnabled: return
	var collectibleComponent: CollectibleComponent = areaEntered.get_node(^".") as CollectibleComponent # HACK: Find better way to cast self?
	if not collectibleComponent: return

	printDebug(str("onAreaEntered() CollectibleComponent: ", collectibleComponent))
	didCollideCollectible.emit(collectibleComponent)

	handleCollection(collectibleComponent)


## Checks the COLLECTOR's conditions, such as maximum health or ammo, then calls the [method CollectibleComponent.requestToCollect] to check the COLLECTIBLE's conditions.
## Affected by [member isEnabled]
## If all conditions are satisfied, calls [method collect]
## Returns: The result of the [member CollectibleComponent.payload] 
func handleCollection(collectibleComponent: CollectibleComponent) -> Variant:
	if not isEnabled: return false

	# First, check our own conditions. Can we collect this item?
	# For example, are we already at maximum health or ammo, or do we have enough inventory space?

	if not checkCollectionConditions(collectibleComponent): 
		printDebug("CollectorComponent denied collection: " + self.logFullName)
		return false

	if collectibleComponent.requestToCollect(self.entity, self) == true:
		return collect(collectibleComponent)
	else:
		printDebug("CollectibleComponent denied collection: " + collectibleComponent.logFullName)
		return false


## May be overridden in a subclass to approve or deny the collection of a [CollectibleComponent] by this [CollectorComponent] and the parent [Entity].
## For example, is the player already at maximum health or ammo, or is there enough inventory space?
## Default: `true`
func checkCollectionConditions(_collectibleComponent: CollectibleComponent) -> bool:
	return true


## Performs the collection of a [CollectibleComponent],
## which calls [method Payload.execute] with the [CollectibleComponent] as the `source` and this [CollectorComponent]'s parent [Entity] as the `target`.
## Either adds a [Payload] [Node] to the [Entity],
## or executes a script or [Callable] provided by the collectible,
## or emits a [Signal], or may perform other game-specific custom behavior.
## Returns: The result of [method Payload.execute] or `false` if the [member CollectibleComponent.payload] is missing.
func collect(collectibleComponent: CollectibleComponent) -> Variant:
	var payload: Payload = collectibleComponent.payload
	
	printDebug(str("collect() collectibleComponent: ", collectibleComponent, ", payload: ", payload))
	
	if not payload:
		printWarning("collectibleComponent missing payload")
		return false

	var result: Variant = collectibleComponent.collect(self)
	
	if result: # Must not be `null` and not `false`
		didCollect.emit(collectibleComponent, payload, result)

	return result
