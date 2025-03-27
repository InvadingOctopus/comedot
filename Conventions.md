# Comedot Coding Conventions & Design Philosophilizy

## Axioms of Goom

1. Underscores == ugly

2. Tabs > Spaces

3. camelCase == bestCase

This is the Truth of the Universe.

----


> [!TIP]
> Most of this is the opinion of the sole maintainer @ShinryakuTako on GitHub but if you're smart it should be yours too.

I come from Swift and I love it so this framework attempts to follow the Swift API Design Guidelines unless when it's highly inconvenient within Godot: https://www.swift.org/documentation/api-design-guidelines/


## Voidspace

* Tabs instead of Spaces
	- Because GDScript is an indentation-based language :)
	- A single missing or extra space could cause errors.
	- Visual representation can be customized per user and easier to view with visible tabs etc.
	- Easier to navigate.
	- Fewer bytes to store.

* 2 empty lines between functions and different regions of code, such as parameters, signals, state properties etc.
	- This is what the default Godot script templates start with.
	- Adds more clear visual separation between distinct sections.


## Case

* NO underscores whenever possible!
	- Less clutter
	- Fewer keystrokes  
	(Thanks Stannis!)

* camelCase for everything, even constants.
	- No extra SHIFT press needed to start autocomplete etc.

* Capitalized names for Types only.

* Short acronyms may be fully capitalized.
	- Examples: UINode, HUDColor

* Text names/IDs such as for node groups, input actions and animations should be camelCase, to match the convention of enums: `GlobalInput.Actions.yeet = &"yeet"`


## Names

* Names should make grammatical sense wherever possible.

* Booleans should start with `is`, `has`, `should` etc.
	- This may make autocompletion easier by listing all booleans together.
	- Avoid ambiguity with "verbs" e.g.`showDebugInfo` could be a function name.


### Functions & Methods

* Function names should read like a verb/command/action: e.g. `doSomething()` or `checkValidity()`

* Functions that perform a quick & "cheap" retrieval operation, like returning a member from an Array or Dictionary, should be named starting with `get`: e.g. `getComponent(…)`

* Functions that need to do a slower _search_ operation, like scanning a list of all child nodes, should be named starting with `find`: e.g. `findComponent(…)`

* Functions that add an _existing_ object to a parent, container or list, should be named starting with `add`: e.g. `addText(…)`

* Functions that _create_ a new object and then add it to a parent, should be named starting with `create`: e.g. `createLabel(…)`


### Signals

* Signals should generally be named in this form: {object/category}{tense}{event} e.g. `healthDidDecrease`
* or, if the ACTION is the focus: {action}{object} e.g. `didSpawnEntity`
* or, if the OBJECT is the focus: {object}{action} e.g. `entityDidSpawn`
* Signal names should begin with a `did` or `will` wherever it makes sense.
	- This ensure consistency in words by avoiding English plural jankery: `didDecrease` vs `decreased`, `didRunOut` vs `ranOut`
	- `ammoInsufficient` does not make sense in a past or future tense, so it is exempt.
	- If there are no "did" or "will" variants the tense can be omitted, e.g. `onCollide`.

_Examples:_
```
signal healthDidZero
signal didFire(bullet: Entity)
signal didSpawn(newSpawn: Node2D, parent: Node2D)
signal willRemoveFromEntity
```

* Functions that handle signals should be named in this form: `on[ObjectThatEmittedSignal]_[signal]`
	- If the script is attached to the node which emits the signal, then simply: `on[Signal]`
	- If the object name is short enough or a single word, then the _ underscore may be omitted.
	- Yes, this is the ONLY place where underscores are used, because we can't use a — dash etc. :')

_Examples:_
```
func onCollectibleComponent_didCollideCollector(…)
func onGunComponent_ammoDepleted()
func onHealthChanged(…)
func onTimeout() # in the script of a Timer node
```


## Resources

* Resources like [Stat] and [Upgrade] should ONLY CONTAIN INFORMATION and validation functions.
* Resources should NOT contain WHERE THEY ARE USED; an Upgrade should NOT hold a reference to the [UpgradesComponent] where it's "installed"; that should be the job of the component.
* "Passing" Resources that are supposed to stay "unique" between different "owners", like a special Upgrade between UpgradesComponents, should be done via signals.


## Comments

* Comments don't use BBCode. It's ugly and just dumb in 2025. Waiting for Godot to just implement Markdown already.

* Comments may begin with tags for marking stuff to watch out for. Most such as TODO & FIXME are self-explanatory.
	- TBD: (To Be Decided) or CHECK: Something that is an uncertain solution, may not be the ideal and could change in the future, but works for now.
	- DESIGN: Explanation for decisions behind code that may seem weird or when its reason may not be immediately apparent.
	- DEBUG: Code that is only there to aid debugging and should be commented out or removed before committing, exporting or release.
	- FIXED/SOLVED/DONTTOUCH or similar: Code that has already solved a tricky problem and should not be messed with, otherwise the problem might resurface.
	- WORKAROUND: Code that temporarily solves a bug in Godot etc. and may be removed after the bug has been eradicated.
	- CREDIT: For people/sources who created certain code or resources, such as other open-source projects/contributors or third-party asset providers.
	- THANKS: For people/sources who suggested or were the inspiration behind an idea or solution.


## Design

* The ultimate goal is to have minimal time between getting a new gameplay idea and seeing it on screen. And be easy to modify later. The focus is on 2D games.

* The core soul of this project is the library of components: Everything else is just scaffolding to support a workflow based on components (or conveniences like UI).

* HOW components are actually implemented behind-the-scenes may always keep changing, but the components themselves will always be present: e.g. there will always be a HealthComponent, a DamageComponent, a DamageReceivingComponent and so on.

* Try to design from the "outside-in": i.e. first decide on what the front-end "interface" or USAGE should look like. Components should work similar to how the rest of Godot works out of the box: Creating nodes, scripts, and throwing them together and putting numbers in the Inspector sidebar.

* Components are created based on abstractions in terms of _gameplay_ NOT coding abstractions, as in, how the actual play of most games can be broken down into distinct events and behaviors that could be reused even in different genres.

* General over Specific: Components and scripts in Comedot's library should be designed for customization and reusability in as many different games and situations as convenient. Specialized single-purpose components should be a private part of a game project (i.e. not a shared framework). Examples:
	* ModifyOnCollisionComponent instead of RemovalOnCollisionComponent.
	* TreeSearchBox instead of a search feature built into ComponentsDock.
	* Wiring multiple components via signals: Using ModifyOnCollisionComponent to add a ModifyOnTimerComponent and connecting them to implement arrows which get stuck in walls then automatically removed, instead of creating a separate ArrowComponent.

* You don't HAVE to break your game into small modular components: You can have large "monolithic" components like a `PlayerComponent` and `MonsterComponent` and put all your game-specific logic in a single script.

* Try not add too many new features before perfecting or at least solidifying the existing stuff!


## Miscellaneous

* Do not try to use `-1` etc as an indicator of whether some numerical value is invalid or should be ignored. It complicates ALL other calculations down the road. Just use a separate flag.
	- e.g. `allowInfiniteLevels = true` instead of `maxLevel = -1`


## Git Workflow

* TBD: The `develop` branch should be merged into `main` only on a weekend, I guess?
