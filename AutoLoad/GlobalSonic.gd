## AutoLoad
## A scene for playing music or sound effects which are not dependent on any node or entity's lifetime.
## Also contains a "synthesizer" for generating sounds via script code, through the [method beep] function.
## The [member process_mode] is set to [enum ProcessMode.PROCESS_MODE_ALWAYS] which ignores the [meember SceneTree.paused] flag in order to manage audio while the actual gameplay is paused.
## Why not GlobalAudio? Because "sonic" is more cool ;)

#class_name GlobalSonic
extends Node


#region Parameters
@export var musicFolder:			String = "res://Assets/Music" ## The folder from which to load all ".mp3" files on [method _ready] and list them in the [member musicFiles] list.
@export var shouldShuffleMusic:		bool = true ## Affects [method skipMusic] and the next track that plays after the current track finishes.
@export var maximumNumberOfSounds:	int  = 10 # TBD:
@export var debugMode:				bool = false
#endregion


#region State
var audioPlayers: Array[AudioStreamPlayer2D]
var currentAudioPlayerIndex: int

var musicFiles: PackedStringArray ## An array that is populated by all the ".mp3" files found in the [constant musicFolder] on [method _ready].
var currentMusicIndex: int = -1 ## The index in the [member musicFiles] array of the currently playing song. Defaults to -1 to indicate no song.
#endregion


#region Dependencies
@onready var sounds:		Node = $Sounds
@onready var musicPlayer:	AudioStreamPlayer = $MusicPlayer
@onready var synthesizer:	AudioStreamPlayer = %Synthesizer ## Plays sounds generated via script code.
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

	sounds.add_child(audioPlayer, self.debugMode) # PERFORMANCE: force_readable_name is slow so use only if debugging
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


## Searches for the specified song name and returns its index in the [member musicFiles] array if found, otherwise -1
func findMusicFile(fileName: String) -> int:
	var matchingIndex: int = self.musicFiles.find(fileName)
	if matchingIndex < 0: Debug.printWarning("findMusicFile() cannot find: " + fileName, self)
	return matchingIndex


## Plays the song found at the specified index in the [member musicFiles] array.
func playMusicIndex(index: int = self.currentMusicIndex) -> AudioStream:
	if currentMusicIndex == 0 and self.musicFiles.is_empty(): # Silence warning for the default state of new projects: No music files.
		if debugMode: Debug.printWarning("playMusicIndex(): musicFiles is empty!", self)
		return null

	if Tools.validateArrayIndex(self.musicFiles, index):
		self.currentMusicIndex = index
		return self.playMusicFile(self.musicFiles[index])
	else:
		Debug.printWarning(str("playMusicIndex() invalid index: ", index, ", musicFiles size: ", musicFiles.size()), self)
		return null


## Plays the next track from [member musicFiles] after [member currentMusicIndex].
## If the playlist only has 1 track, then it is repeated.
## If the playlist is empty, then the music is stopped.
## Returns: The newly played [AudioStream].
func playNextMusicIndex() -> AudioStream:
	if self.musicFiles.is_empty():
		musicPlayer.stop()
		return null
	elif self.musicFiles.size() == 1:
		# NOTE: Manually replay the stream, in case some other script played a different track that is not the `currentMusicIndex`
		return self.playMusicFile(self.musicFiles[self.currentMusicIndex])
	else:
		var nextIndex: int = self.currentMusicIndex + 1
		if nextIndex >= self.musicFiles.size(): nextIndex = 0 # The last valid index is size-1
		return self.playMusicFile(self.musicFiles[nextIndex])


## Shuffles/plays and returns a random song from the [member musicFiles] array.
## If [param allowRepeats] is `true` the same song as the current/previous song may be played again. Such is the nature of true randomness.
## NOTE: If this is the first music to be played e.g. from [Start].gd then [param allowRepeats] should be set to `true` to allow the index 0 to be included in the shuffle.
func playRandomMusicIndex(allowRepeats: bool = false) -> AudioStream:
	# TBD: A better way to include index 0 on the first call?
	if self.musicFiles.is_empty():
		return null
	elif allowRepeats or self.musicFiles.size() == 1: # No need to random if there's only 1 song!
		return self.playMusicIndex(randi_range(0, self.musicFiles.size() - 1)) # randi_range() is inclusive and size() is +1 > maximum valid array index.
	else:
		var newMusicIndex: int = self.currentMusicIndex
		var tries: int = 0 # Limit the number of tries so we don't get stuck in an infinite loop during pauses etc.
		while newMusicIndex == self.currentMusicIndex and tries < 100: # 100 should be enough to ensure no repeats, right?
			newMusicIndex = randi_range(0, self.musicFiles.size() - 1)
			tries += 1
		return self.playMusicIndex(newMusicIndex)


## Plays and returns the specified file on the "MusicPlayer" [AudioStreamPlayer] node.
## The file does not have to be included in the [member musicFiles] array.
func playMusicFile(path: String) -> AudioStream:
	var newMusicStream: AudioStream = load(path)
	if newMusicStream == null:
		Debug.printWarning("playMusicFile() cannot load " + path, self)
		return null

	# Convert any UIDs to the actual text path
	var fileName: String
	if ResourceUID.has_id(ResourceUID.text_to_id(path)):
		fileName = ResourceUID.get_id_path(ResourceUID.text_to_id(path))
	else:
		fileName = path

	# Update the current index if the song is in our playlist
	self.currentMusicIndex = self.findMusicFile(fileName)

	self.musicPlayer.stream = newMusicStream
	self.musicPlayer.play()
	self.musicPlayerDidPlay.emit(fileName)
	return newMusicStream


func skipMusic() -> AudioStream:
	self.musicPlayerDidStop.emit()
	if shouldShuffleMusic: return self.playRandomMusicIndex()
	else: return self.playNextMusicIndex()


func onMusicPlayer_finished() -> void:
	self.musicPlayerDidStop.emit()
	if shouldShuffleMusic: self.playRandomMusicIndex()
	else: self.playNextMusicIndex()


func _input(event: InputEvent) -> void:
	# BUG: Gets called twice in the same frame??
	if event.is_action(GlobalInput.Actions.skipMusic) and Input.is_action_just_pressed(GlobalInput.Actions.skipMusic):
		self.get_viewport().set_input_as_handled()
		self.skipMusic()

#endregion


#region Synthesized Sounds

@onready var synthesizerSampleHz: float = synthesizer.stream.mix_rate
var phase: float = 0.0 # TBD: Should this be a class property or a local function variable?
var playback: AudioStreamGeneratorPlayback ## Plays code-generated audio for the [member synthesizer].

## Generates a sound via script code to play through the [member synthesizer] [AudioStreamPlayer] [AudioStreamGeneratorPlayback]
## TIP: May be used for debugging via audio cues!
## @experimental
func beep(duration: float = 1.0, pulseHz: float = 440.0, volume: float = 1.0) -> void:
	# NOTE: PERFORMANCE: Godot Documentation:
	# Due to performance constraints, AudioStreamGenerator is best used from a compiled language.
	# If you still want to use this class from GDScript, consider using a lower `mix_rate` such as 11,025 Hz or 22,050 Hz.

	# Prep the player
	# NOTE: The `playback_type` must be `PLAYBACK_TYPE_STREAM` otherwise there is a Godot warning: "/root/GlobalSonic/Synthesizer is trying to play a sample from a stream that cannot be sampled."
	if not synthesizer.playing: synthesizer.play()
	if not playback: playback = synthesizer.get_stream_playback() # TBD: Set once @onready or on each call?
	# var sampleHz:	float = synthesizer.stream.mix_rate # TBD: Set once @onready or on each call?
	playback.clear_buffer() # CHECK: Necessary?
	var frames: float = playback.get_frames_available()

	# Generate the sample
	# CHECK: No idea how any of this actually works. Just copied from the Godot documentation.
	var length:		float = duration * synthesizerSampleHz
	var increment:	float = pulseHz  / synthesizerSampleHz
	#var phase:		float # TBD: Should `phase` be reset here?

	for i in range(minf(length, frames)):
		# NOTE: PERFORMANCE: Godot Documentation:
		# Pushes a single audio data frame to the buffer. This is usually less efficient than push_buffer() in compiled languages,
		# but push_frame() may be more efficient in GDScript.
		playback.push_frame(Vector2.ONE * sin(phase * TAU) * volume) # Stereo
		phase = fmod(phase + increment, 1.0)

	# TBD: Stop manually?
	# await get_tree().create_timer(duration).timeout
	# synthesizer.stop()

#endregion
