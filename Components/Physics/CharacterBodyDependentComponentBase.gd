## Base class for components which depend on a [CharacterBodyComponent] to manipulate a [CharacterBody2D] before and after it moves during each frame.
## Components which need to perform updates AFTER [method CharacterBody2D.move_and_slide] must connect to the [signal CharacterBodyComponent.didMove] signal.
## NOTE: This is NOT the base class for the [CharacterBodyComponent] itself.

@abstract class_name CharacterBodyDependentComponentBase
extends Component

# TBD: Better name? :')


#region Dependencies
@onready var characterBodyComponent: CharacterBodyComponent = parentEntity.findFirstComponentSubclass(CharacterBodyComponent)
@onready var body: CharacterBody2D = characterBodyComponent.body

func getRequiredComponents() -> Array[Script]:
	return [CharacterBodyComponent]
#endregion


## NOTE: Not required to be called via super._ready(); only for generating an error on a missing dependency.
func _ready() -> void:
	# DESIGN: _enter_tree() cannot be used because components that depend on CharacterBodyComponent may enter the tree before CharacterBodyComponent
	if not characterBodyComponent:
		printError(str("Missing CharacterBodyComponent in ", parentEntity.logFullName)) # If a component inherits this class then it means so a missing dependency is an ERROR!
