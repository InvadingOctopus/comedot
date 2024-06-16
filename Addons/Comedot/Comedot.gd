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


func addCustomTypes():
	# Entity
	const entityScript	:= preload("res://Entities/Entity.gd")
	const entityIcon	:= preload("res://Assets/Icons/entity.svg")
	add_custom_type(entityTypeName, "Node2D", entityScript, entityIcon)

	# Component
	const componentScript	:= preload("res://Components/Component.gd")
	const componentIcon		:= preload("res://Assets/Icons/component.svg")
	add_custom_type(componentTypeName, "Node", componentScript, componentIcon)


func removeCustomTypes():
	remove_custom_type(entityTypeName)
	remove_custom_type(componentTypeName)
