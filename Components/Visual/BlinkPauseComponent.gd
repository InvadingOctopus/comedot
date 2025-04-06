## Pauses the Entity node and blinks (toggles visibility on & off) for the specified number of times, then the Entity is unpaused and this component removes itself.
## May be used as a visual delay effect to draw the player's attention to new characters or objects before they enter gameplay.
## Examples: Spawning Collectibles or dying monsters.

class_name BlinkPauseComponent
extends Component


#region Parameters
@export var timesToBlink: int = 5
#endregion


#region State
@export_storage var count: int
@export_storage var entityPreviousProcessMode: ProcessMode
#endregion


#region Signals
signal didFinishBlinking
#endregion


func _ready() -> void:
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	self.autostart = true
	startBlink()


func startBlink() -> void: # Not named "start" to avoid conflict with Timer.start()
	self.entityPreviousProcessMode  = parentEntity.process_mode
	parentEntity.visible = false
	parentEntity.process_mode = Node.PROCESS_MODE_DISABLED


func onTimeout() -> void:
	parentEntity.visible = not parentEntity.visible
	if parentEntity.visible:  count += 1 # 2 ticks of the Timer count as 1 "blink"; when the node becomes visible again.
	if count >= timesToBlink: finishBlink()


func finishBlink() -> void:
	parentEntity.visible = true
	parentEntity.process_mode = self.entityPreviousProcessMode
	didFinishBlinking.emit() # In case we are used as a death animation
	self.removeFromEntity()
