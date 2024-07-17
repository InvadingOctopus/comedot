## Displays a control that pauses the gameplay while it is displayed.
## Calls a specified function which may then resume the gameplay. 

class_name ModalUI
extends Control


#region Parameters
## The function to call when the modal UI closes. 
## Must accept a [Variant] argument to receive the result of the modal UI.
@export var callbackOnFinish: Callable
#endregion


#region Signals
signal didFinish(result: Variant)
#endregion


func close(result: Variant = 0) -> void:
	didFinish.emit(result)
	callbackOnFinish.call(result)
