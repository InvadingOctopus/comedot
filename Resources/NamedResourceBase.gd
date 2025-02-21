## Abstract base class for [Resource]s that represent gameplay-related resources such as health/ammo or skills etc. with a named identity and a visual representation including optionally displayed name, description and icon.

@tool
class_name NamedResourceBase
extends Resource

# TBD: A better name? ViewableResource? :')

# NOTE: WATCHOUT: Understand the order of initialazion to avoid unexpected behavior:
# If a Resource such as a Stat is added to a Component like HealthComponent, and `name` is set to &"health",
# then the HealthComponent is added to a MonsterEntity.tscn scene, and the Stat is renamed to &"monsterHealth" and other values are also changed,
# then at runtime, the values of the Stat in HealthComponent.tscn will be applied first, via the property setters, and THEN the MonsterEntity's values for HealthComponent will be applied,
# which may cause unwanted emissions of signals like GameStat.statUpdated and unexpected behavior in scripts like ManualStatsList
# SOLUTION: DELETE the default HealthComponent Stat in MonsterEntity.tscn, and recreate a new Stat with a different name.


#region Common Parameters

## The identity for an instance of this Resource.
## NOTE: This name MUST BE UNIQUE across all Resources of the same type, because components and other classes may search these Resources by their names.
@export var name: StringName:
	set(newValue):
		if newValue.is_empty():
			Debug.printWarning("Rejected attempt to set name to empty string", self)
			return
		name = newValue
		self.resource_name = name # CHECK: Does this work without @tool?

## An optional different name for displaying in the HUD and other UI. If empty, returns [member name] capitalized.
@export var displayName: String:
	get:
		if not displayName.is_empty(): return displayName
		else: return self.name.capitalize()

@export var description: String ## An optional explanation, for internal development notes or to show the player.

@export var icon: Texture2D ## An optional image to display in UI views such as [StatUI].

#endregion

