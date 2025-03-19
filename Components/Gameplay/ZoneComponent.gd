## Monitors an [Area2D] when it enters or exits another [Area2D] belonging to the "zones" group, and maintains a list of overlapping zones.
## Intended to be subclassed for game-specific functionality.
## Examples: A "home zone" which heals the player, or an area of fire or poison which causes damage.

class_name ZoneComponent
extends AreaContactComponent


#region Signals
signal didEnterZone(zoneArea: Area2D) ## Emitted AFTER [signal AreaCollisionComponent.didEnterArea]
signal didExitZone(zoneArea:  Area2D) ## Emitted AFTER [signal AreaCollisionComponent.didExitArea]
signal didUpdateZones
#endregion


#region State
## The list of [Area2D]s which belong to the "zones" group and overlap this component's area.
var currentZones: Array[Area2D]
#endregion


func _ready() -> void:
	super._ready()
	self.shouldMonitorAreas  = true
	self.shouldMonitorBodies = false
	connectSignals()


## Overrides [method AreaContactComponent.connectSignals] and only monitors for [Area2D]s, regardless of flags.
func connectSignals() -> void:
	# TBD: CHECK: Should it CONNECT_PERSIST?
	Tools.connectSignal(area.area_entered, self.onAreaEntered, CONNECT_PERSIST)
	Tools.connectSignal(area.area_exited,  self.onAreaExited,  CONNECT_PERSIST)
	# NOTE: Ignore "bodies"


## Overrides [method AreaContactComponent.readdAllContacts] and only adds "zones".
func readdAllContacts() -> void:
	# Clear the current lists.
	areasInContact.clear()
	bodiesInContact.clear()
	currentZones.clear()
	
	# Ignore shouldMonitorAreas/shouldMonitorBodies flags 
	# Allow signal observers to respond to zones already in contact.

	for overlappingArea in selfAsArea.get_overlapping_areas():
		areasInContact.append(overlappingArea)
		self.didEnterArea.emit(overlappingArea)
		
		if overlappingArea.is_in_group(Global.Groups.zones):
			currentZones.append(overlappingArea)
			self.didEnterZone.emit(overlappingArea)

	didUpdateZones.emit()
	return currentZones.size() # TBD: How does this work with `void`?


## Overrides [method AreaContactComponent.onAreaEntered] and only adds "zones".
func onAreaEntered(areaEntered: Area2D) -> void:
	# Is the area a member of the "zones" group?
	if not isEnabled or not areaEntered.is_in_group(Global.Groups.zones): return

	areasInContact.append(areaEntered)

	# Add it to the [currentZones] array if it isn't already in it.
	if self.currentZones.count(areaEntered) <= 0:
		currentZones.append(areaEntered)
		didUpdateZones.emit()

	if debugMode: printDebug(str("onAreaEntered(): ", areaEntered, ", currentZones: ", currentZones.size()))
	self.onCollide(areaEntered)
	didEnterArea.emit(areaEntered)
	didEnterZone.emit(areaEntered)


## Overrides [method AreaContactComponent.readdonAreaExitedllContacts] and only adds "zones".
## NOTE: This is NOT affected by `isEnabled`; zones that exit should ALWAYS be removed!
func onAreaExited(areaExited: Area2D) -> void:
	# Is the area a member of the "zones" group?
	if not areaExited.is_in_group(Global.Groups.zones): return
	
	areasInContact.erase(areaExited)

	# Remove it from the [currentZones] array.
	if self.currentZones.count(areaExited) >= 1:
		currentZones.erase(areaExited)
		didUpdateZones.emit()

	if debugMode: printDebug(str("onAreaExited(): ", areaExited, ", currentZones: ", currentZones.size()))
	self.onExit(areaExited)
	didExitArea.emit(areaExited)
	didExitZone.emit(areaExited)


#region Abstract Methods
# NOTE: Ignore the AreaContactComponent implementation because here we only care about zones.

## Abstract; Must be implemented by subclass.
@warning_ignore("unused_parameter")
func onCollide(collidingNode: Node2D) -> void:
	pass


## Abstract; Must be implemented by subclass.
@warning_ignore("unused_parameter")
func onExit(exitingNode: Node2D) -> void:
	pass

#endregion


#region DEBUG

# func _physics_process(_delta: float) -> void:
# 	showDebugInfo()


func showDebugInfo() -> void:
	if not debugMode: return
	Debug.watchList[str("\n —", parentEntity.name, ".", self.name)] = ""
	Debug.watchList.currentZones = self.currentZones

#endregion
