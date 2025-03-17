## Set of parameters for [GunComponent].
## NOTE: Does not include some parameters such as [member GunComponent.bulletEmitter] etc. which are specific to each [GunComponent].
## UNUSED:
## @experimental

class_name GunParameters
extends Resource


#region Parameters

## The [Entity] to instantiate a copy of when the Gun shoots.
@export var bulletEntity: PackedScene # TODO: Enforce `Entity` type

@export var ammo:Stat ## The [Stat] Resource to use as the ammo. If omitted, no ammo is required to fire the gun.
@export var ammoCost: int = 0 ## The ammo used per shot. 0 == Unlimited ammo. NOTE: A negative number will INCREASE the ammo when firing.

## If `true`, the gun fires automatically without any player input.
@export var autoFire: bool = false

## If `true`, the button input has to be unpressed and pressed again for each bullet. If `false`, keep firing as long as the button input is pressed.
@export var pressAgainToShoot: bool = false

## Add the parent entity's [CharacterBody2D] node's velocity to bullets.
## IMPORTANT: Requires [CharacterBodyComponent] and the [member bulletEntity] should have a [LinearMotionComponent].
## @experimental
@export var shouldAddEntityVelocity: bool = false

#endregion
