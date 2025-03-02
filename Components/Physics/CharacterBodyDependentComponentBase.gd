## Base class for components which depend on a [CharacterBodyComponent] to manipulate a [CharacterBody2D] before and after it moves during each frame.
## Components which need to perform updates AFTER [method CharacterBody2D.move_and_slide] must connect to the [signal CharacterBodyComponent.didMove] signal.
## NOTE: This is NOT the base class for the [CharacterBodyComponent] itself.

class_name CharacterBodyDependentComponentBase
extends Component

# TBD: Better name? :')


#region State

var characterBodyComponent: CharacterBodyComponent:
	get:
		# NOTE: Use [findFirstChildOfType()] instead of [coComponents] so that subclasses of [CharacterBodyComponent] may also be usable.
		if not characterBodyComponent:
			characterBodyComponent = parentEntity.findFirstComponentSubclass(CharacterBodyComponent)
			if not characterBodyComponent: # If we STILL don't have it, raise a ruckus.
				printError("Missing CharacterBody2D in parent Entity: \n" + parentEntity.logFullName)
		return characterBodyComponent

var body: CharacterBody2D:
	get:
		if not body: body = characterBodyComponent.body
		return body

#endregion


func getRequiredComponents() -> Array[Script]:
	return [CharacterBodyComponent]
