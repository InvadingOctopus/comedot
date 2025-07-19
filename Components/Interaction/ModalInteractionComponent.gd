## Displays a UI control and pauses the parent entity.
## This component is not affected by pausing; the [member Node.process_mode] should be [constant Node.PROCESS_MODE_ALWAYS].

class_name ModalInteractionComponent
extends InteractionComponent


#region Parameters

## The scene to display when this interaction occurs. 
@export var modalScene: PackedScene

@export var setViewGlobalPositionToEntity: bool = false

@export var viewPositionOffset: Vector2

#endregion


#region State
var currentModalUI: ModalUI
#endregion


#region Signals
#endregion


## NOTE: Subclasses MUST call `super.performInteraction(...)`
## Returns [member ModalUI.lastResult]
func performInteraction(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> Variant:
	printDebug(str("performInteraction() interactorEntity: ", interactorEntity, "interactionControlComponent: ", interactionControlComponent))
	
	if not modalScene:
		printWarning("No modalView")
		return false
		
	var sceneTree: SceneTree = self.get_tree()
	var modalView: ModalUI   = modalScene.instantiate()
	
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	modalView.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Set the position if the view can be positioned
	var positionableView: Node2D = (modalView.get_node(^".") as Node2D)
	if positionableView:
		if setViewGlobalPositionToEntity: positionableView.global_position = parentEntity.global_position
		positionableView.position += viewPositionOffset
	
	# Pause the gameplay and display the view
	
	sceneTree.paused = true
	sceneTree.current_scene.add_child(modalView)
	modalView.owner = sceneTree.current_scene # INFO: Necessary for persistence to a [PackedScene] for save/load.
	modalView.didFinish.connect(self.modalView_didFinish)
	
	self.currentModalUI = modalView
	return modalView.lastResult


func modalView_didFinish(result: Variant) -> void:
	printDebug(str("modalView_didFinish(): ", result))
	
	var sceneTree: SceneTree = self.get_tree()
	
	sceneTree.current_scene.remove_child(currentModalUI)
	currentModalUI.queue_free()
	
	sceneTree.paused = false
