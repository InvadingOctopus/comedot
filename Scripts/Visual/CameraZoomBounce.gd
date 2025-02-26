## "Bounces" or "headbangs" the camera zoom back and forth in and out of the screen.
## Useful for inducing dizziness.
## TIP: For a camera attached to an [Entity], use [CameraComponent]

extends Camera2D

# TBD: Better name? :')


#region Parameters
@export_range(0.0, 10.0, 0.05) var zoomTimerMax:  float = 0.2
@export_range(0.0, 10.0, 0.05) var zoomDirection: float = 0.2 ## The distance/intensity of the zoom. Swaps sign/"direction" during runtime.
#endregion


#region State
var zoomTimer: float = 0.0
#endregion


func _process(delta: float) -> void:
	zoom += Vector2(zoomDirection * delta, zoomDirection * delta) # Camera2D.zoom
	zoomTimer += delta

	if zoomTimer >= zoomTimerMax:
		zoomDirection = -zoomDirection
		zoomTimer = 0
