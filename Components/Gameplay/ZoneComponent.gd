## Monitors an [Area2D] and performs actions when it enters or exits another [Area2D] belonging to the "Zones" group.
## Keeps a list of overlapping zones.
## Examples: A "home zone" which heals the player, or an area of fire or poison which causes damage.
## Recommended to be subclassed.

class_name ZoneComponent
extends Component


#region Parameters

## The area which this component represents. If `null` then the component node itself is used if it is an [Area2D], otherwise the parent [Entity] node is used if that is an [Area2D]
## NOTE: The area's signals are connected to this component automatically in [method _ready]
## Default: `self` or `parentEntity.area`
@export var areaOverride: Area2D

@export var isEnabled := true
#endregion


#region Signals
signal didEnterZone(zoneArea: Area2D)
signal didExitZone(zoneArea: Area2D)
signal didUpdateZones
#endregion


#region State
## The list of [Area2D]s which belong to the "zones" group and overlap this component's area.
var currentZones: Array[Area2D]
#endregion


func _ready() -> void:
	if not areaOverride:
		areaOverride = self.get_node(".") as Area2D # HACK: TODO: Find better way to cast

	# If we still have no area, check if the parent [Entity] has an area.

	if not areaOverride:
		areaOverride = parentEntity.getArea()

	connectSignals()
	updateCurrentZones()


func connectSignals() -> void:
	if not areaOverride: return
	areaOverride.area_entered.connect(self.onAreaEntered)
	areaOverride.area_exited.connect(self.onAreaExited)


## Returns: The number of overlapping [Area2D]s which belong to the "zones" group, and adds them to the [member currentZones] array.
func updateCurrentZones() -> int:
	var areas: Array[Area2D] = self.areaOverride.get_overlapping_areas()

	# First, clear the current list.
	self.currentZones.clear()

	for zone in areas:
		if zone.is_in_group(Global.Groups.zones):
			currentZones.append(zone)

	didUpdateZones.emit()
	return currentZones.size()


func onAreaEntered(area: Area2D):
	# Is the area a member of the "zones" group?
	if not isEnabled or not area.is_in_group(Global.Groups.zones): return

	# Add it to the [currentZones] array if it isn't already in it.
	if self.currentZones.count(area) <= 0:
		currentZones.append(area)
		didUpdateZones.emit()

	printDebug("onAreaEntered: " + str(area) + " | currentZones: " + str(currentZones.size()))
	didEnterZone.emit(area)


func onAreaExited(area: Area2D):
	# Is the area a member of the "zones" group?
	if not isEnabled or not area.is_in_group(Global.Groups.zones): return

	# Remove it from the [currentZones] array.
	if self.currentZones.count(area) >= 1:
		currentZones.erase(area)
		didUpdateZones.emit()

	printDebug("onAreaExited: " + str(area) + " | currentZones: " + str(currentZones.size()))
	didExitZone.emit(area)


#region DEBUG
#func _physics_process(_delta: float):
	#Debug.watchList.currentZones = self.currentZones
#endregion
