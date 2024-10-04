## Defines the in-game "factions" to which an [Entity] may belongs, such as the players faction or the monsters.
## Contains functions for comparing 2 [FactionComponent]s against each other,
## used for deciding damage and potential AI NPC interactions.

class_name FactionComponent
extends Component


#region Constants

enum Factions {
	neutral = 1, # TBD: Should `neutral` be 0?
	players = 2,
	playerAllies = 3,
	enemies = 4,
}

const factionStrings: Array[String] = [
	"neutral", 
	"players", 
	"playerAllies", 
	"enemies",
]

#endregion


#region Parameters

## The factions which this component's [Entity] belongs to.
## Entities that share ANY faction are considered implicit allies.
## An Entity belonging to [player, playerAllies] would be considered an ally of an Entity belonging to [playerAllies, enemies].
## Entities that have NO matching factions are considered implicit opponents.
@export_flags(factionStrings[0], factionStrings[1], factionStrings[2], factionStrings[3]) var factions: int = Factions.neutral # TBD: Should the default be 0 or 1?

# TBD: Add `explicitAllies` and `explicitOpponents`?

#endregion


#region Faction Functions

## Returns `true` if there is ANY match between this component's [member factions] and the [param otherFactions].
## Example: [player, playerAllies] vs [playerAllies, enemies]
func checkAlliance(otherFactions: int) -> bool:
	return (self.factions & otherFactions) # Bitwise `AND` means `true` if ANY bits match.


## Returns `true` if there is NO match between this component's [member factions] and the [param otherFactions].
## Example: [player, playerAllies] vs [enemies]
func checkOpposition(otherFactions: int) -> bool:
	return not (self.factions & otherFactions) # Bitwise `AND` means `true` if ANY bits match.

#endregion

