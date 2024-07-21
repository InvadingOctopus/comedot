## Placeholder prototype for an Options menu.
## @experimental

#class_name OptionsContainer
extends Control

# TODO: @export var setting: UserSetting

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	# TODO: buildTestSettings()
	#printInputList()


# TODO: 
#func buildTestSettings():
	#var settings = {}
	#var newSetting := UserSetting.new()
	#newSetting.path = &"physics/2d/default_gravity"
	#settings.test = newSetting
	#print(newSetting.currentValue)

func printInputList():
	for action: StringName in InputMap.get_actions():
		print(action)
