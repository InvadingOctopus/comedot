## A list of [Component] TYPEs, (NOT component instances).
## For use with [ComponentSwapperComponent] etc.
## @experimental

class_name ComponentSet
extends Resource


#region Parameters
## The list of [Component] TYPEs, NOT component "instances".
@export var components: Array[Script] # TBD: Use StringName instead of [Script] as the type>
#endregion
