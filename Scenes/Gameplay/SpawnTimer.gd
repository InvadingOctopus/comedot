## A [Timer] with a [Spawner] child node that creates copies of a specified Scene at regular intervals.
## TIP: See [SpawnPoint], [SpawnArea] and [SpawnEdge] to spawn at specific positions or regions.
## TIP: The [Spawner] script may be replaced with subclasses such as [RandomSpawner] etc.

class_name SpawnTimer
extends Timer


#region Parameters

@export var spawner: Spawner

## If `true` then a copy of [member Spawner.sceneToSpawn] is spawned as soon as the [Spawner] is [method Node._ready] and then this [Timer] is started.
@export var shouldSpawnOnReady: bool = false

@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			if spawner: spawner.isEnabled = self.isEnabled
			if self.is_node_ready():
				if isEnabled: self.start()
				else: self.stop()

#endregion


func _ready() -> void:
	if not is_instance_valid(spawner):
		Debug.printWarning("No spawner assigned!", self)
		self.autostart = false
		self.stop()
		return

	if  not spawner.spawnInSceneRoot \
	and not spawner.parentOverride.is_empty() \
	and not spawner.get_node_or_null(spawner.parentOverride):
		Debug.printWarning("Spawner.parentOverride invalid; set `Spawner.parentOverride` to \"../..\" or another parent.", self)
	elif spawner.get_node_or_null(spawner.parentOverride) == self:
		# DESIGN: A Timer shouldn't have visible kids! Fix it even if `spawnInSceneRoot`
		spawner.parentOverride = ^"../.."
		if spawner.debugMode: Debug.printWarning(str("Spawner.parentOverride was set to this Timer node; changed to the parent of this Timer: ", self.get_parent()), self)

	if not self.isEnabled or not spawner.isEnabled:
		self.stop()
		return

	if shouldSpawnOnReady:
		self.stop() # Stop the Timer just in case to prevent a double spawn etc.
		spawner.spawn.call_deferred() # Defer to avoid the error: "Parent node is busy setting up children, `add_child()` failed."

	self.start() # Start the Timer after the initial spawn


func onTimeout() -> void:
	if isEnabled: spawner.spawn()
