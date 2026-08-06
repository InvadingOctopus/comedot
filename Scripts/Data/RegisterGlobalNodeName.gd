## Adds a [Node] to [member GameState.globalData] using the name of the node as the key.
## EXAMPLE: If the node is named "PlayerSpawnMarker" then `GameState.globalData.playerSpawnMarker` will point to that node.
## NOTE: Names are converted to camelCase: The first letter of the key will always be lowercase.
## The name-key is removed from [GlobalData] when this node exits the scene.

extends Node


#region State
var savedCamelCaseName: StringName # Store this for later removal
#endregion


func _enter_tree() -> void: # TBD: Setup early, in _enter_tree() before _ready()
	self.savedCamelCaseName = self.name.to_camel_case() # O_O I CANT BELEIVE GODOT HAS THIS!
	GameState.globalData[savedCamelCaseName] = self


func _exit_tree() -> void:
	# IMPORTANT: Use the stored key we used during _enter_tree()
	# in case the node's name was changed before the exit!
	if self.savedCamelCaseName.is_empty() or not GameState.globalData.dictionary.has(self.savedCamelCaseName): return

	# NOTE: Also check that the key still points to us, in case the key was mutated or `globalData` itself was reassigned.
	var existingValue: Variant = GameState.globalData.dictionary.get(savedCamelCaseName) # Avoid crash if null
	if  existingValue and is_same(existingValue, self): # is_same() avoids crash when types mismatch, unlike `==`
		GameState.globalData.eraseValue(savedCamelCaseName)
