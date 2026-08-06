## Adds a [Node] to [member SceneManager.globalNodeNames] [Dictionary] using the name of the node as the key.
## This may provide more convenient access to arbitrary nodes than `%` names.
## EXAMPLE: If the node is named "PlayerSpawnMarker" then `SceneManager.globalNodeNames.playerSpawnMarker` will point to this node.
## NOTE: Names are converted to camelCase: The first letter of the key will always be lowercase.
## The name-key is removed from [member SceneManager.globalNodeNames] when this node exits the scene.

extends Node


#region State
var savedCamelCaseName: StringName # Store this for later removal
#endregion


func _enter_tree() -> void: # TBD: Setup early, in _enter_tree() before _ready()
	self.savedCamelCaseName = self.name.to_camel_case() # O_O I CANT BELEIVE GODOT HAS THIS!
	if self.savedCamelCaseName.is_empty(): # Catch weird cases
		Debug.printWarning(str("RegisterGlobalNodeName.gd: to_camel_case() returned empty string"), self)
		return
	SceneManager.globalNodeNames[savedCamelCaseName] = self


func _exit_tree() -> void:
	# IMPORTANT: Use the stored key we used during _enter_tree()
	# in case the node's name was changed before the exit!
	if self.savedCamelCaseName.is_empty() or not SceneManager.globalNodeNames.has(self.savedCamelCaseName): return

	# NOTE: Also check that the key still points to us, in case the key was reassigned to another node, or `globalNodeNames` itself was reassigned.
	if is_same(SceneManager.globalNodeNames.get(savedCamelCaseName), self):
		SceneManager.globalNodeNames.erase(savedCamelCaseName)
