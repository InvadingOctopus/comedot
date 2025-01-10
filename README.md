# Comedot

**Component-based framework and project template for [Godot][godot]**

![Godot+Comedot Logo][logo]

The goal is to be an all-in-one toolkit for 2D games (platformers, shoot-em-ups, RPGs, turn-based strategy or puzzle) where you build scenes by adding components to entities and tweaking their parameters in the UI. _"Entities"_ and _"Components"_ are like regular Godot Nodes but for gameplay, so you can mix this framework with any other architecture or system, even for 2D scenes in a 3D game!

* Includes components for different types of player movement, combat, collectibles, interactions, upgrades etc.
* UI controls like a stats HUD, buttons & lists for special skills etc.
* Template scenes for Logo → Main Menu → Options, Input Remapping, Pause Overlay
* Save/Load player preferences via a config file with just `Settings.any_name = 69`
* Tons of helper functions & debugging tools.
* Commented & documented code.
* Free-to-use 3rd-party assets for quick prototyping.

> [!WARNING]
> This is still mostly a private personal project; it's what I'm using to make [my own epic games][itch] while learning Godot and GDScript as I go. The opinionated style eschews GDScript conventions like ugly underscores, and the API may change frequently and **no backwards compatibility is guaranteed!**


🌳 _An example of a player entity:_

![components-tree]

⭐️ The [composition architecture][composition-over-inheritance] lets you do cool shit like putting a `GunComponent` and `MouseRotationComponent` on any object and _It Just Works:_  

https://github.com/InvadingOctopus/media/assets/11238708/bb03147b-b4b0-4388-ac35-b31b23519bde

⭐️ Easily implement dynamic gameplay and change abilities/buffs/debuffs at runtime; just add/remove components in simple event handlers, like this example of swapping between platformer physics and flying/"overhead" movement:

https://github.com/InvadingOctopus/media/assets/11238708/a067368c-489c-42f1-aedb-b210b5549489

📈 There's even kawaii charts for debugging variables in real-time!

![debug-charts]

_(if the videos don't display, view on imgur):_ [1][rocks-with-guns], [2][swapping-components]


## How To Use

> [!Important]  
> _Requires Godot 4.4 ~Embrace the Future_ ✨  
> The first time you load this project, there may be errors because Godot will re-import the asset files and set the internal IDs for textures etc. To fix: Close and reopen the project.

🚀 **For a quick glance:** See the `/Templates/Scenes/` folder.

⚙️ **To use this framework for your own games:**

1. Clone this repository; make a local copy of this entire Godot project.
2. Drag-&-drop nodes from the `/Entities/` and `/Components/` folders into your scene tree.
	* The `/Templates/` folder contains example scenes and Entities with preset Components as a quick starting point for various gameplay.
	* The `/Scripts/` folder contains code for simple non-Entity nodes.
	* The `/UI/` folder contains common UI elements such as a stats HUD, special action buttons, lists for choosing upgrades etc.

![Custom Dock Plugin][comedock]

> [!NOTE]
> 🧩 A "component" is any Godot node that:
> * Reacts to events (like player input or collisions).
> * Moves or modifies its parent node or other components.
> * Contains data for other components to use (like character health and other stats).
>
> 🪆 An "entity" is a node whose children are components (it may also have non-component children).

🎳 Whenever your game needs an "actor" like the player character or a monster, or an object with "behaviors" that could be reused for other objects, like interactive items or collectible powerups:

_Use the included custom dock plugin (the Comedock :) or perform these steps manually:_

1. Create a new **Entity** node: a `Node2D/Sprite2D/CharacterBody2D` etc. with the `Entity.gd` script attached.
2. Add **Component** child nodes to the entity. A component is also a `Node/Area2D` etc. with a script that `extends` the `Component.gd` class.
3. Modify component parameters in the Godot Editor's Inspector.
4. Save the entity + components tree as a standalone scene file to organize it separately from the main "world" scene and quickly create copies of it anywhere.

> [!TIP]
> 📜 **Read [HowTo.md][howto] to see how to do common tasks** like player movement and combat or adding entirely new functionality.
>
> 💬 For more deets, ping Syntaks.io on Discord.

----

[Comedot][repository] ©? MMXXV [ShinryakuTako@GitHub][github] • [Syntaks.io@Discord][discord]

> 🤍 THANKS:  
> * Tilesets:	https://kenney.nl/assets/1-bit-pack  
> * Font:		Jayvee Enaguas (HarvettFox96) https://www.dafont.com/pixel-operator.font

[repository]: https://github.com/invadingoctopus/comedot
[website]: https://invadingoctopus.io
[license]: License.txt
[patreon]: https://www.patreon.com/invadingoctopus
[discord]: https://discord.gg/jZG3cBFt7u
[twitter]: https://twitter.com/invadingoctopus
[mastodon]:https://mastodon.gamedev.place/@Syntaks
[github]:  https://github.com/ShinryakuTako
[itch]:    https://syntaks.itch.io

[howto]:		HowTo.md
[conventions]:	Conventions.md
[thanks]:		Thanks.md
[todo]:			ToDo.md

[godot]: https://github.com/godotengine/godot "Godot Game Engine"
[composition-over-inheritance]: https://en.wikipedia.org/wiki/Composition_over_inheritance
[entity–component–system]: https://en.wikipedia.org/wiki/Entity_component_system

[logo]: /Assets/Logos/Comedot.png "Godot+Comedot Logo"
[components-tree]: https://i.imgur.com/7M0pH3v.png "Example Components Tree for a Player Entity"
[rocks-with-guns]: https://i.imgur.com/wH84m23.mp4 "Rocks with Guns"
[swapping-components]: https://i.imgur.com/iS0xjdI.mp4 "Swapping Control Components"
[debug-charts]: https://i.imgur.com/jgAjmzY.png "Debug Chart Windows"
[comedock]: https://i.imgur.com/oY4WymY.png "Custom Godot Editor Dock Plugin"
