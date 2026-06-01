## Creates an [AbilityButton] for each [Ability] in an [AbilityComponent].
## Attach this script to any [Container] [Control] such as a [GridContainer] or [HBoxContainer].
## @experimental

class_name AbilityButtonsList
extends Container


#region Parameters

## An [Entity] with an [AbilityComponent] and a [StatsComponent] which will be used for validating and displaying each [Ability] button.
## If `null`, the first [member GameState.players] Entity will be used.
@export var entity: Entity

@export var debugMode: bool = false
#endregion


#region State
var lastAbilityChosen: Ability
#endregion


#region Signals
signal didChooseAbility(ability: Ability)
#endregion


#region Dependencies

const abilityButtonScene: PackedScene = preload("res://UI/Buttons/AbilityButton.tscn") # TBD: load or preload?

var abilityComponent: AbilityComponent:
	get:
		if   not entity: abilityComponent = null
		elif not abilityComponent: abilityComponent = entity.getComponent(AbilityComponent)
		return abilityComponent

var targetStatsComponent: StatsComponent:
	get:
		if   not entity: targetStatsComponent = null
		elif not targetStatsComponent: targetStatsComponent = entity.getComponent(StatsComponent)
		return targetStatsComponent

var player: Entity: # PlayerEntity or TurnBasedPlayerEntity
	get: return GameState.players.front()

#endregion


func _ready() -> void:
	if not entity:
		entity = player
		if not entity: Debug.printWarning("Missing entity", self)

	if abilityComponent: readdAllAbilities()
	else: Debug.printWarning("Missing abilityComponent", self)


## Removes all children and adds all choices again.
func readdAllAbilities() -> void:
	NodeTools.removeAllChildren(self)
	for ability in abilityComponent.abilities:
		createAbilityButton(ability)


func createAbilityButton(ability: Ability) -> Button:
	var newAbilityButton: AbilityButton = abilityButtonScene.instantiate()
	newAbilityButton.debugMode  = self.debugMode

	newAbilityButton.entity = self.entity
	newAbilityButton.ability = ability

	NodeTools.addChildAndSetOwner(newAbilityButton, self)

	newAbilityButton.updateUI() # TBD: Update before adding or after?
	newAbilityButton.pressed.connect(self.onAbilityButton_pressed.bind(ability))

	return newAbilityButton


func onAbilityButton_pressed(ability: Ability) -> void:
	if debugMode: Debug.printDebug(str("onAbilityButton_pressed() ", ability.logName), self)
	self.lastAbilityChosen = ability
	self.didChooseAbility.emit(ability)
