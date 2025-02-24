## Transfers all of its child nodes (which may be other Components) to the first Entity that collides with it.
## Useful for applying buffs/debuffs, for example: a "bullet" entity representing a poison arrow etc. that adds a [DamageOverTimeComponent] to the victim entity.
## NOTE: To use, connect the [signal Area2D.area_entered] or [signal Area2D.body_entered] signal of an [Area2D] to the [method onAreaOrBodyEntered] method of this component.
## TIP: If adding other Components as child nodes of this component, enable the [member allowNonEntityParent] flag on those Components.

class_name InjectorComponent
extends Component

# TODO: Automatically set/unset allowNonEntityParent
# DESIGN: The component's scene is a Node2D so any visual children can move along with the "injector entity"


#region Parameters
@export var process: int

@export var shouldKeepGlobalTransform:	bool = false ## If `true`, each child node's global position/rotation/etc. will be preserved after transferring to the new parent, if supported.

@export var shouldHideBeforeTransfer:	bool = false ## Hide all child nodes before they are transferred to a new parent?
@export var shouldShowAfterTransfer:	bool = true  ## Make all child nodes visible after they are transferred to a new parent?

@export var shouldSetProcessModeBeforeTransfer: bool = true ## Should the children's [member Node.process_mode] be set to [member processModeBeforeTransfer] until they're transferred? e.g. pause them.
@export var processModeBeforeTransfer:	ProcessMode = PROCESS_MODE_DISABLED ## Example: [constant ProcessMode.PROCESS_MODE_DISABLED] to pause the nodes until they're transferred.

@export var shouldSetProcessModeAfterTransfer: bool = true ## Should the children's [member Node.process_mode] be set to [member processModeAfterTransfer] after they're transferred? e.g. unpause them.
@export var processModeAfterTransfer:	ProcessMode = PROCESS_MODE_INHERIT ## Example: [constant ProcessMode.PROCESS_MODE_INHERIT] to allow the nodes to be unpaused after they are transferred to a new parent.

@export var isEnabled:					bool = true
#endregion


#region State
var isInjecting: bool = false ## Set to `true` during [method inject] so that subsequent calls are ignored.
#endregion


#region Signals
signal willInject(targetParent: Node)
signal didInject(node: Node, newParent: Node) ## Emitted for each child node that is transferred to a new parent during [method inject]
#endregion


func _ready() -> void:
	# Set properties before transfer, if needed
	if shouldHideBeforeTransfer or shouldSetProcessModeBeforeTransfer:
		for child in self.get_children():
			if shouldHideBeforeTransfer and child is Node2D: # `is` is better/faster than is_instance_of() in this case
				child.visible = false
			if shouldSetProcessModeBeforeTransfer:
				child.process_mode = processModeBeforeTransfer
			
			if child is Component:
				if not child.allowNonEntityParent:
					printWarning(str("`allowNonEntityParent` is not set on a child component added to InjectorComponent: ", child))


## Moves (reparents) all the child [Node]s of this Component to the [param newParentEntity], and returns an array of all the transferred nodes.
func inject(newParentEntity: Entity, keepGlobalTransform: bool = self.shouldKeepGlobalTransform) -> Array[Node]:
	if not isEnabled or isInjecting or self.get_child_count() < 1: return []
	
	isInjecting = true # Ignore multiple calls while isInjecting
	willInject.emit(newParentEntity)

	var childrenTransferred: Array[Node]
	
	for childToTransfer in self.get_children():
		if debugMode: printDebug(str("inject(): ", childToTransfer, " → ", newParentEntity.logName))

		childToTransfer.reparent(newParentEntity, keepGlobalTransform)
		childToTransfer.owner = newParentEntity # For persistence etc. otherwise reparent() may try to keep the previous `owner`
		childrenTransferred.append(childToTransfer)
		didInject.emit(childToTransfer, newParentEntity)

		# Show & unpause the nodes after the transfer?

		if shouldShowAfterTransfer and childToTransfer is Node2D: # `is` is better/faster than is_instance_of() in this case
			childToTransfer.visible = true

		if shouldSetProcessModeAfterTransfer:
			childToTransfer.process_mode = processModeAfterTransfer

	isInjecting = false
	return childrenTransferred


## Calls [method inject] if the colliding [param areaOrBody] is an [Entity] or the grand/child of an [Entity].
## NOTE: This method is NOT connected to any [Area2D] or other signals by default.
## TIP:  Connect the [signal Area2D.area_entered] or [signal Area2D.body_entered] signal of an [Area2D] to this method.
func onAreaOrBodyEntered(areaOrBody: Node2D) -> void:
	if debugMode: printDebug(str("onAreaOrBodyEntered(): ", areaOrBody, ", isEnabled: ", isEnabled, ", isInjecting: ", isInjecting, ", children: ", self.get_child_count()))
	if not isEnabled or isInjecting or self.get_child_count() < 1: return # Faster checks first
	
	var targetEntity: Entity
	
	if areaOrBody is Entity: # `is` is better/faster than is_instance_of() in this case, right?
		targetEntity = areaOrBody
	elif areaOrBody.get_parent() is Entity:
		targetEntity = areaOrBody.get_parent()
	else: # Search further up the tree
		targetEntity = Tools.findFirstParentOfType(areaOrBody, Entity)

	if targetEntity: inject(targetEntity)
