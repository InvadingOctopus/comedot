## Adds a node to the global [member GameState.globalData] dictionary, using the name of the node as the key.
## Example: If the node is named "PlayerSpawnMarker" then `GameState.globalData.playerSpawnMarker` will point to that node.
## NOTE: The first letter of the key will always be lowercase (camelCase).

extends Node

# TBD: Should we use `_ready()` or `_enter_tree()`?

func _ready() -> void:
	var camelCaseName: StringName = self.name.to_camel_case() # O_O I CANT BELEIVE GODOT HAS THIS!
	GameState.globalData[camelCaseName] = self
