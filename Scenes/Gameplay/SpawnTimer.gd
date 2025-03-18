## A [Timer] that creates copies of a specified Scene at regular intervals.

class_name SpawnTimer
extends Spawner


#region Parameters

## If `true` then a copy of [member sceneToSpawn] is spawned as soon as this spawner node os [method Node._ready] and then the [Timer] is started.
@export var shouldSpawnOnReady: bool = false

## Stops the [Timer] when set to `false`
# @export var isEnabled: bool = true: # UNUSED: sigh GDScript can't override setters/getters :(
# 	set(newValue):
# 		if newValue != isEnabled:
# 			isEnabled = newValue
# 			self.paused = not isEnabled
# 			if self.is_node_ready():
# 				if isEnabled: selfAsTimer.start()
# 				else: selfAsTimer.stop()

#endregion


#region State
@onready var selfAsTimer: Timer = self.get_node(^".") as Timer
#region


func _ready() -> void:
	if shouldSpawnOnReady:
		selfAsTimer.stop() # Stop the Timer
		spawn.call_deferred() # Defer to avoid the error: "Parent node is busy setting up children, `add_child()` failed."

	Tools.connectSignal(selfAsTimer.timeout, self.onTimeout)
	selfAsTimer.start() # Start the Timer after the initial spawn


func onTimeout() -> void:
	spawn()


func spawn() -> Node2D:
	if not isEnabled: return null
	return super.spawn()
