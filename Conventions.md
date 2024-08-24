# Comedot Code & Framework Conventions

I come from Swift so I hate underscores and love camelCase. This framework follows the Swift API Design Guidelines unless when it's highly inconvenient within Godot:

https://www.swift.org/documentation/api-design-guidelines/

# Whitespace

* TABS instead of Spaces
	- Because GDScript is an indentation-based language :)
	- A single missing or extra space could cause errors.
	- Easier to navigate, and to view, with visible tabs etc.

* 2 empty lines between functions and different "categories" of code, such as parameters, signals, state properties etc.
	- This is what the default Godot script templates start with.
	- Adds a bit more clear visual separation between different regions of code.

# Case

* camelCase == bestCase

* Underscores == ugly

* Capitalized names for Types only.

* Short acronyms may be fully capitalized.
	- Examples: UINode, HUDColor

* Names should make grammatical sense wherever possible.
	- Functions should read like a verb/action, or a question if their job is to check something and return a boolean.
	- Booleans should start with `is`, `has`, `should` etc. This may make autocompletion easier by listing all booleans.

* Text names/IDs such as for node groups, input actions and animations should be camelCase, to match the convention of enums: `GlobalInput.Actions.yeet = &"yeet"`

# Functions & Methods

* Functions that perform a quick retrieval operation, like returning a member from an Array or Dictionary, should be named starting with `get`: e.g. `getComponent(...)`

* Functions that need to do a slower _search_ operation, like scanning a list of all child nodes, should be named starting with `find`: e.g. `findComponent(...)`

* Functions that add an existing object to a parent, container or list, should be named starting with `add`: e.g. `addText(...)`

* Functions that _create_ a new object and then add it to a parent, should be named starting with `create`: e.g. `createLabel(...)`

# Signals

* Signals should be named in this form: [object/category][event]
* or, if the ACTION is more important: [action][object]
* or, if the OBJECT is more important: [object][action]
* Signal names should begin with a `did` or `will` wherever it makes sense.
	- This ensure consistency in words by avoiding English plural jankery: `didDecrease` vs `decreased`, `didRunOut` vs `ranOut`.
	- `ammoInsufficient` does not make sense in a past or future tense, so it is exempt.

Examples:
```
healthDecreased
ammoDepleted
entityWillBeRemoved
spawnedEnemy
```

* Functions that handle signals should be named in this form: `on[ObjectEmittingSignal]_[signal]`
	- If the script is attached to the node which emits the signal, then simply: `on[Signal]`
	- If the object name is short enough or a single word, then the _ underscore may be omitted.

Examples:
```
func onCollectibleComponent_didCollideWithCollector()
func onGunComponent_ammoDepleted()
func onHealthChanged()
func onTimeout() # in a script on a Timer node
```

# Resources

* Resources like [Stat] and [Upgrade] should ONLY CONTAIN INFORMATION and validation functions.
* Resources should NOT contain WHERE THEY ARE USED; an Upgrade should NOT hold a reference to the [UpgradesComponent] where it's "installed"; that should be the job of the component.
* "Passing" Resources that are supposed to stay "unique" between different "owners", like a special Upgrade between UpgradesComponents, should be done via signals.

# Miscellaneous

* Do not try to use `-1` etc as an indicator of whether some numerical value is invalid or should be ignored. It complicates ALL other calculations down the road. Just use a separate flag.
	- e.g. `allowInfiniteLevels = true` instead of `maxLevel = -1`

# Git Workflow

* TBD: The `develop` branch should be merged into `main` only on a weekend, I guess?
