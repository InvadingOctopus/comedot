## A subclass of [Entity] specialized for player-controlled characters.
## ALERT: Game-specific subclasses which extend [PlayerEntity] MUST call `_super.ready()` etc. if those methods are overridden.

class_name PlayerEntity
extends Entity


#region Shortcuts
# Quick access to common components
# NOTE: Not cached, because components may change during runtime.

var bodyComponent: CharacterBodyComponent:
	get: return getComponent(CharacterBodyComponent)

var healthComponent: HealthComponent:
	get: return getComponent(HealthComponent)

var statsComponent: StatsComponent:
	get: return getComponent(StatsComponent)

var actionsComponent: ActionsComponent:
	get: return getComponent(ActionsComponent)

var upgradesComponent: UpgradesComponent:
	get: return getComponent(UpgradesComponent)

#endregion


func _enter_tree() -> void:
	super._enter_tree()
	self.add_to_group(Global.Groups.players, true) # persistent


func _ready() -> void:
	printLog("_ready()")
	GameState.addPlayer(self)
	GameState.playerReady.emit(self)


func _exit_tree() -> void:
	super._exit_tree()
	GameState.removePlayer(self)
