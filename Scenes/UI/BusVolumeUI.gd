## Sets the volume of an audio bus in discrete steps.

#class_name BusVolumeUI
extends Control


#region Parameters

@export var busIndex: int

@export var busTitle: String = "V":
	set(newValue):
		busTitle = newValue
		busLabel.text = busTitle

#endregion


#region State
@onready var busLabel: Label = %BusLabel
@onready var volumeLabel: Label = %VolumeLabel

var volumeInSteps: int = 3: ## 5 steps, where 0 = Mute, 5 = 0 db
	set(newValue):
		volumeInSteps = newValue
		volumeLabel.text = str(volumeInSteps)
		setBusVolume()

#endregion


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	busLabel.text = busTitle
	volumeLabel.text = str(volumeInSteps)


func getBusVolume() -> int:
	# TODO: Implement
	return 0


func setBusVolume():
	var volumeInDb: float = 0

	match self.volumeInSteps:
		0: volumeInDb = -60
		1: volumeInDb = -24
		2: volumeInDb = -12
		3: volumeInDb = -6
		4: volumeInDb = 0
		5: volumeInDb = +6

	AudioServer.set_bus_mute(busIndex, self.volumeInSteps <= 0)
	AudioServer.set_bus_volume_db(busIndex, volumeInDb)

	#Debug.watchList.volumeSetting = self.volumeInSteps
	#Debug.watchList.volume = AudioServer.get_bus_volume_db(busIndex)


func onIncreaseButton_pressed() -> void:
	volumeInSteps += 1


func onDecreaseButton_pressed() -> void:
	volumeInSteps -= 1
