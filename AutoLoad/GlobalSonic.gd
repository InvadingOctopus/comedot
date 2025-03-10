## AutoLoad
## A scene for playing music or sound effects which are not dependent on any node or entity's lifetime.
## The [member process_mode] is set to [enum ProcessMode.PROCESS_MODE_ALWAYS] which ignores the [meember SceneTree.paused] flag in order to manage audio while the actual gameplay is paused.
## Why not GlobalAudio? Because "sonic" is more cool ;)

#class_name GlobalSonic 
extends Node


#region Parameters
@export var musicFolder: String = "res://Assets/Music" ## The folder from which to load all ".mp3" files on [method _ready] and list them in the [member musicFiles] list.
@export var maximumNumberOfSounds: int = 10 # TBD:
@export var debugMode:  bool = false
#endregion


#region State
var audioPlayers: Array[AudioStreamPlayer2D]
var currentAudioPlayerIndex: int

var musicFiles: PackedStringArray ## An array that is populated by all the ".mp3" files found in the [const musicFolder] on [method _ready].
var currentMusicIndex: int ## The index in the [member musicFiles] array of the currently playing song.
#endregion


#region Dependencies
@onready var sounds: Node = %Sounds
@onready var musicPlayer: AudioStreamPlayer = $MusicPlayer
#endregion


#region Signals
## Emits the path of the new file played by the [member musicPlayer] [AudioStreamPlayer] node.
## If the music player has finished, then [signal musicPlayerDidStop] is emitted.
signal musicPlayerDidPlay(fileName: String)

## Emitted when the [member musicPlayer] [AudioStreamPlayer] node emits its [signal AudioStreamPlayer.finished] signal.
## WARNING: Calling [method AudioStreamPlayer.stop] directly on [member musicPlayer] does NOT emit these signals, or when the node is removed from the scene tree.
signal musicPlayerDidStop
#endregion


func _ready() -> void:
	self.loadMusicFolder()


#region SFX

## Creates an [AudioStreamPlayer2D], plays the specified sound, then deletes the node.
## Used for playing sound effects for nodes and entities that may be deleted before the audio finishes playing,
## such as enemy destruction or collectible pickups etc.
## If [param stream] is `null`, then a [AudioStreamPlayer2D] node will be created only, but not played or automatically removed later.
## Returns: The newly created [AudioStreamPlayer2D] node.
func createAudioPlayer(
	stream:   AudioStream,
	position: Vector2 = Vector2.ZERO,
	bus:	  StringName = Global.AudioBuses.sfx) -> AudioStreamPlayer2D:
	
	# Check the limit on maximum number of sounds
	# TODO: A better implementation, like [TemporaryLabelList]'s?
	
	if sounds.get_child_count() >= maximumNumberOfSounds:
		# Delete the oldest sound (the one at the top of the subtree)
		sounds.remove_child(sounds.get_child(0))

	# Create the new sound
	var audioPlayer: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	audioPlayer.bus = bus
	audioPlayer.stream = stream
	audioPlayer.position = position
	
	sounds.add_child(audioPlayer, true) # force_readable_name
	audioPlayer.owner = sounds # Necessary for persistence to a [PackedScene] for save/load.
	audioPlayer.add_to_group(Global.Groups.audio, true) # persistent 
	
	if stream:
		audioPlayer.play() # TBD: Add playback position argument? TBD: Find a way to move along with node and continue playing after the node is destroyed?
		audioPlayer.finished.connect(audioPlayer.queue_free)
	
	return audioPlayer


## Creates a "pool" of reusable [AudioStreamPlayer2D] nodes for [method playAudioPlayerPool].
## May provide better performance compared to [method createAudioPlayer].
## NOTE: Deletes all existing children already in the `Sounds` node.
func createAudioPlayerPool() -> Array[AudioStreamPlayer2D]:
	# Delete existing children
	self.audioPlayers.clear()
	Tools.removeAllChildren(sounds)

	# Fill the pool
	for count in maximumNumberOfSounds:
		var newAudioPlayer: AudioStreamPlayer2D = createAudioPlayer(null)
		self.audioPlayers.append(newAudioPlayer)
	
	currentAudioPlayerIndex = 0 # Reset the index
	return self.audioPlayers


## Plays a sound via one of the existing [AudioStreamPlayer2D] nodes from the "pool" in the `Sounds` parent node.
## May provide better performance compared to [method createAudioPlayer].
## Used for playing sound effects for nodes and entities that may be deleted before the audio finishes playing,
## such as enemy destruction or collectible pickups etc.
## Returns: The [AudioStreamPlayer2D] node which was used.
func playAudioPlayerPool(
	stream:   AudioStream,
	position: Vector2 = Vector2.ZERO,
	_bus:	  StringName = Global.AudioBuses.sfx) -> AudioStreamPlayer2D:
	
	# Cycle through the available AudioStreamPlayer2D nodes,
	# so we can have a pool of simultaneous sounds up to a limit.

	var audioPlayer: AudioStreamPlayer2D

	if audioPlayers.is_empty():
		createAudioPlayerPool()
		# TBD: Debug.printWarning("No AudioStreamPlayer2D in audioPlayers pool", self)
		# return null
	
	audioPlayer = audioPlayers[currentAudioPlayerIndex]
	
	currentAudioPlayerIndex += 1
	if currentAudioPlayerIndex >= audioPlayers.size():
		currentAudioPlayerIndex = 0

	# Configure the new sound
	audioPlayer.stream = stream
	audioPlayer.position = position
	audioPlayer.play() # TBD: Add playback position argument? TBD: Find a way to move along with node and continue playing after the node is destroyed?
	
	return audioPlayer

#endregion


#region Music

## Replaces and returns the [member musicFiles] array with the list returned by calling [method getMusicFilesFromFolder] on the [member musicFolder].
func loadMusicFolder() -> PackedStringArray:
	self.musicFiles = getMusicFilesFromFolder(self.musicFolder)
	return self.musicFiles


## Returns a list of all the ".mp3" files found at [param path], which defaults to [member musicFolder].
func getMusicFilesFromFolder(path: String = self.musicFolder) -> PackedStringArray:
	var files: PackedStringArray = Tools.getResourcesInFolder(path, ".mp3") # TBD: Allow other extensions?
	if debugMode: Debug.printAutoLoadLog(str("getMusicFilesFromFolder(", path, "): ", files.size(), " ", files))
	return files


## Plays the song found at the specified index in the [member musicFiles] array.
func playMusicIndex(index: int = self.currentMusicIndex) -> AudioStream:
	if currentMusicIndex == 0 and self.musicFiles.is_empty(): # Silence warning for the default state of new projects: No music files.
		if debugMode: Debug.printWarning("playMusicIndex(): musicFiles is empty!", self)
		return null
	
	if Tools.validateArrayIndex(self.musicFiles, index):
		return self.playMusicFile(self.musicFiles[index])
	else:
		Debug.printWarning(str("playMusicIndex() invalid index: ", index, ", musicFiles size: ", musicFiles.size()), self)
		return null


## Plays and returns a random song from the [member musicFiles] array.
## NOTE: The same song as the current/previous song may be played again. Such is the nature of true randomness.
func playRandomMusicIndex() -> AudioStream:
	return self.playMusicIndex(randi_range(0, self.musicFiles.size() - 1)) # randi_range() is inclusive and size() is +1 > maximum valid array index.


## Plays and returns the specified file on the "MusicPlayer" [AudioStreamPlayer] node.
## The file does not have to be included in the [member musicFiles] array.
func playMusicFile(path: String) -> AudioStream:
	var newMusicStream: AudioStream = load(path)
	if newMusicStream == null:
		Debug.printWarning("playMusicFile() cannot load " + path, self)
		return null
	
	self.musicPlayer.stream = newMusicStream
	self.musicPlayer.play()
	self.musicPlayerDidPlay.emit(path)
	return newMusicStream


func onMusicPlayer_finished() -> void:
	self.musicPlayerDidStop.emit()

#endregion


