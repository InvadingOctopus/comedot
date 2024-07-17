## Comedot Plugin Prototype

@tool
extends EditorPlugin


#region Constants
const entityTypeName	:= &"Comedot Entity"
const componentTypeName	:= &"Comedot Component"
#endregion


func _enter_tree() -> void:
	addCustomTypes()


func _exit_tree() -> void:
	removeCustomTypes()


func addCustomTypes() -> void:
	# Entity
	const entityScript	:= preload("res://Entities/Entity.gd")
	const entityIcon	:= preload("res://Assets/Icons/Entity.svg")
	add_custom_type(entityTypeName, "Node2D", entityScript, entityIcon)

	# Component
	const componentScript	:= preload("res://Components/Component.gd")
	const componentIcon		:= preload("res://Assets/Icons/Component.svg")
	add_custom_type(componentTypeName, "Node", componentScript, componentIcon)


func removeCustomTypes() -> void:
	remove_custom_type(entityTypeName)
	remove_custom_type(componentTypeName)
