## A basic "dash" [Action] [ScriptPayload] script for a platformer game.
## Adds horizontal velocity for a single frame to the [CharacterBodyComponent],
## based on the recent horizontal input of an [InputComponent].
## @experimental

extends GDScript

# TODO: Some way to set parameters for static functions :')
# TODO: Optional invulnerability


const force: float = 300
const shouldApplyVisualEffect: bool = true


@warning_ignore("unused_parameter")
static func onPayload_didExecute(payload: Payload, source: Variant, target: Variant) -> Variant: # `Variant` may be replaced by specific types such as `Entity` or `Component`.
	if source is Entity:
		var characterBodyComponent: CharacterBodyComponent = source.components.CharacterBodyComponent
		var inputComponent: InputComponent = source.components.InputComponent

		if characterBodyComponent and inputComponent:
			characterBodyComponent.body.velocity.x += inputComponent.lastNonzeroHorizontalInput * force
			if shouldApplyVisualEffect:
				source.modulate = Color(10, 10, 10) # Super white
				Animations.blink(source, 1, 0.05)
				Animations.tweenProperty(source, ^"modulate", Color.WHITE, 0.25)
			return true

	return false
