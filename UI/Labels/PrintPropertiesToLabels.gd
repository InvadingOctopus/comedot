## Automatically displays the values of the specified Node's properties in different [Label]s.
## Each [Label] must have EXACTLY the same case-sensitie name as a matching property: `isEnabled` but NOT `IsEnabled` or `EnabledLabel` etc.
## TIP: Example: May be used to quickly display a [Component]'s data in a UI [Container].
## NOTE: The monitored object must call [method Object.notify_property_list_changed()] when a value is changed,
## for dynamic updates without manually updating every frame (which slows performance).

# class_name PrintPropertiesToLabels # Unnecessary
extends Container


#region Parameters

@export var objectToMonitor: Node:
	set(newValue):
		if newValue != objectToMonitor:
			objectToMonitor = newValue
			objectToMonitor.property_list_changed.connect(self.onObjectToMonitor_PropertyListChanged)
			if self.is_node_ready(): updateLabels()

## Append the [Label]/property names before the value?
@export var shouldShowPropertyNames:  		bool = true

## Hide a [Label] if a matching property doesn't exist or is `null`?
@export var shouldHideNullProperties:		bool = true

## Automatically enables [member Node.visible] of a hidden [Label] if the [member objectToMonitor] has a property with a matching name.
@export var shouldUnhideAvailableLabels:	bool = false

## Updates [Label]s every frame during [method _process].
## WARNING: Slows performance!
@export var shouldUpdateEveryFrame:			bool = false:
	set(newValue):
		if newValue != shouldUpdateEveryFrame:
			shouldUpdateEveryFrame = newValue
			self.set_process(shouldUpdateEveryFrame)

#endregion


#region State
var labels: Array[Label] ## The list of child [Label]s under this UI [Container].
#endregion


func _ready() -> void:
	self.set_process(shouldUpdateEveryFrame)
	rebuildLabelsArray()

	if objectToMonitor:
		objectToMonitor.property_list_changed.connect(self.onObjectToMonitor_PropertyListChanged)
		updateLabels()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_CHILD_ORDER_CHANGED:
			rebuildLabelsArray()


func onObjectToMonitor_PropertyListChanged() -> void:
	updateLabels()


func rebuildLabelsArray() -> void:
	labels.clear()

	# Can't assign Array[Node] to Array[Label] :(
	for node in self.find_children("*", "Label", true, true): # recursive, owned
		labels.append(node)


func updateLabels() -> void:
	if not self.is_node_ready(): return
	Tools.printPropertiesToLabels(self.objectToMonitor, self.labels, self.shouldShowPropertyNames, self.shouldHideNullProperties, self.shouldUnhideAvailableLabels)


func _process(_delta: float) -> void:
	if not shouldUpdateEveryFrame: return
	updateLabels()
