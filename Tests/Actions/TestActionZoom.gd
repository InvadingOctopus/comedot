## A script called by a [ScriptPayload] when it is executed by an [Action].

extends GDScript


static func onPayload_didExecute(_payload: Payload, source: Entity, _target: Entity) -> Variant:
	# Function entry logging done in ScriptPayload.executeImplementation()
	var characterBodyComponent: CharacterBodyComponent = source.getComponent(CharacterBodyComponent)
	
	if characterBodyComponent: 
		var body: CharacterBody2D = characterBodyComponent.body
		body.velocity = body.velocity * 3
		return true
	else:
		return false
