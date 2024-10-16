## Sets the volume of an audio bus in discrete steps.

@tool
#class_name BusVolumeUI
extends Control


#region Parameters

const volumeSteps: Array[float] = [-72, -60, -24, -18, -12, -6, 0, +6] # In decibels

@export var busIndex: int

@export var busTitle: String = "V":
	set(newValue):
		busTitle = newValue
		if busLabel: busLabel.text = busTitle

## The key in the settings configuration file with which to save and load the volume for this bus to,
## such as &"musicVolume" for [member Setting.musicVolume] or &"sfxVolume" for [member Setting.sfxVolume].
@export var settingsKey: StringName

#endregion


#region State

@onready var busLabel:	  Label = %BusLabel
@onready var volumeLabel: Label = %VolumeLabel

## The index of the value to choose from the [const volumeSteps] array.
## 0 = mute. Second last index = 0 db (normal volume).
## WARNING: Maximum index = distorted volume!
var volumeStepIndex: int = volumeSteps.size() - 2: # Default to the second last value (0 db)
	set(newValue):
		if newValue != volumeStepIndex:
			volumeStepIndex = clampi(newValue, 0, volumeSteps.size() - 1)
			updateUI()
			setBusVolume()

#endregion


func _ready() -> void:
	busLabel.text = busTitle
	self.volumeStepIndex = getStepIndexFromBusVolume()
	setBusVolume()
	updateUI()


func updateUI() -> void:
	volumeLabel.text = str(volumeStepIndex)
	volumeLabel.tooltip_text = str(volumeSteps[volumeStepIndex])


## Returns the index for the [member volumeSteps] member which most closely corresponds to the actual current bus volume.
## Rounds DOWN to the last highest volume step: e.g. a volume of -30db may get "snapped" to -60db, and a volume of +12db will get snapped to +6db.
func getStepIndexFromBusVolume() -> int:
	var currentVolume: float = AudioServer.get_bus_volume_db(busIndex)
	var closestIndex:  int = volumeSteps.size() - 2 # Default to 0, normal volume, the second-last index.

	# Round DOWN to the last highest volume step.
	# TODO: A more accurate way to get the closest volume step from the current volume :)

	for index: int in volumeSteps.size() - 1:
		if is_equal_approx(currentVolume, volumeSteps[index]) \
		or currentVolume > volumeSteps[index]:
			closestIndex = index

	return closestIndex


func setBusVolume() -> void:
	var volume: float = self.volumeSteps[self.volumeStepIndex]
	var labelColor: Color = Color.WHITE

	if volumeStepIndex <= 0: # The lowest volume == mute
		labelColor = Color.GRAY
	elif volumeStepIndex == volumeSteps.size() - 2: ## The second last index = 0 = no attenuation = normal default volume
		labelColor = Color.GREEN
	elif volumeStepIndex >= volumeSteps.size() - 1: # The last index = +6 db = Distored amplification
		labelColor = Color.RED

	if not volumeLabel.label_settings: volumeLabel.label_settings = LabelSettings.new()
	volumeLabel.label_settings.font_color = labelColor

	setBusMute()
	AudioServer.set_bus_volume_db(busIndex, volume)

	if not settingsKey.is_empty():
		Settings.set(settingsKey, volume)

	#Debug.watchList.volumeSetting = self.volumeSteps[self.volumeStepIndex]
	#Debug.watchList.volume = AudioServer.get_bus_volume_db(busIndex)


## Mutes the bus if the lowest volume index is chosen, and unmutes if the index is higher.
func setBusMute() -> bool:
	var shouldMute: bool = self.volumeStepIndex <= 0
	AudioServer.set_bus_mute(busIndex, shouldMute)
	return shouldMute


func onIncreaseButton_pressed() -> void:
	volumeStepIndex += 1


func onDecreaseButton_pressed() -> void:
	volumeStepIndex -= 1
