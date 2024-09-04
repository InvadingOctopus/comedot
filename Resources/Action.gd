## Represents an action that may be performed by the player or any other character. May have a cost and may require a target to be chosen.
## It may be a special skill/spell such as "Fireball", an innate ability such as "Fly", or a trivial command like "Examine".
## @experimental

class_name Action
extends StatDependentResourceBase


#region Parameters
@export var requiresTarget: bool 
#endregion


