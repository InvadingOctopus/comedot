# Comedot

**Component-based framework and project template for [Godot][godot]**

![Godot+Comedot Logo][logo]

The aim is to be an all-in-one toolkit for 2D games (platformers, shoot-em-ups, RPGs, turn-based strategy or puzzle) where you build scenes by adding components to entities like Lego blocks and tweaking their parameters in the UI. _"Entities"_ are just regular nodes and _"components"_ are also nodes which modify other nodes, so you can mix this framework with any other architecture or programming style, even when combining 2D scenes within a 3D game!

> [!IMPORTANT]
> This is still mostly a private personal project; it's what I'm using to make [my own epic games][itch] while learning Godot and GDScript as I go. The API may change frequently and **no backwards compatibility is guaranteed!**


🌳 _An example of a player entity's node tree:_

![components-tree]

⭐️ It lets you do neat tricks like put a `GunComponent` and `MouseRotationComponent` on any object and _It Just Works:_  

https://github.com/InvadingOctopus/media/assets/11238708/bb03147b-b4b0-4388-ac35-b31b23519bde

⭐️ The [composition architecture][composition-over-inheritance] helps you easily change abilities/buffs/debuffs at runtime; just add/remove components in simple event handlers, like this example of swapping between platformer-style control and flying "top-down" movement:

https://github.com/InvadingOctopus/media/assets/11238708/a067368c-489c-42f1-aedb-b210b5549489

📈 There's even cool charts for debugging variables in real-time!

![debug-charts]

_(if the videos don't display, view on imgur):_ [1][rocks-with-guns], [2][swapping-components]


## How To Use

> [!WARNING]  
> _Requires Godot 4.4 ~Embrace the Future_ ✨  
> The first time you load this project, there may be errors because Godot will re-import the asset files and set the internal IDs for textures etc. To fix, just close and reopen the project.

🚀 **For a quick glance:** See the `/Templates/Scenes/` folder.

![Custom Dock Plugin][comedock]

⚙️ **To use this framework for your own games:**

1. Clone this repository (make a local copy of this entire Godot project).
2. Create a new git branch for your game (say `game-of-the-year-2069`) **in your local repository**.
3. Drag-and-drop nodes from the `/Entities/` and `/Components/` folders to build your scenes.
	1. Some components have sub-children, like a `GunComponent`'s pivot point. To modify them, select the component node in the Scene Tree and enable "Editable Children".
	2. The `/Scripts/` folder may be used for any node even if it does not inherit from the `Entity` class.

> [!TIP]
> * Make subfolders for your game in the existing folder structure like `/Scenes/YourGame/` or `/YourGame/etc/` to organize your own files separately from the framework and avoid accidental conflicts.

🧩 Whenever your game needs an "actor" which has to react to events, like the player character or a monster, or an object with "behaviors" which could be reused for other objects, like interactive items or powerups:

_Use the included custom dock plugin (the Comedock :) or perform these steps manually:_

1. Create a new `Entity` node (a Node2D/CharacterBody2D/Area2D/etc. with the `Entity.gd` script attached)
2. Add `Component` child nodes to the entity. A component is also a Node/Node2D/Area2D/etc. with a script which extends the `Component` class.
3. Modify component parameters in the editor's inspector.
4. Save the configured entity as a standalone scene to quickly create copies of it anywhere.

> [!TIP]
> 📜 **Read [HowTo.md][howto] to see how to do common tasks** like player movement and combat.
>
> 💬 For more deets, ping Syntaks.io on Discord.

----

[Comedot][repository] ©? MMXXIV [ShinryakuTako@GitHub][github] • [Syntaks.io@Discord][discord]

> 🤍 THANKS:  
> * Tilesets:	https://kenney.nl/assets/1-bit-pack  
> * Font:		Jayvee Enaguas (HarvettFox96) https://www.dafont.com/pixel-operator.font

[repository]: https://github.com/invadingoctopus/comedot
[website]: https://invadingoctopus.io
[license]: https://about:blank
[discord]: https://discord.gg/jZG3cBFt7u
[twitter]: https://twitter.com/invadingoctopus
[patreon]: https://www.patreon.com/invadingoctopus
[github]:  https://github.com/ShinryakuTako
[itch]:    https://syntaks.itch.io

[howto]:		HowTo.md
[conventions]:	Conventions.md
[thanks]:		Thanks.md
[todo]:			ToDo.md

[godot]: https://github.com/godotengine/godot "Godot Game Engine"
[composition-over-inheritance]: https://en.wikipedia.org/wiki/Composition_over_inheritance
[entity–component–system]: https://en.wikipedia.org/wiki/Entity_component_system
[swift-api-guidelines]: https://swift.org/documentation/api-design-guidelines/

[comedock]: https://i.imgur.com/SR3shzr.png "Custom Godot Editor Dock Plugin"
[rocks-with-guns]: https://i.imgur.com/wH84m23.gifv "Rocks with Guns"
[swapping-components]: https://i.imgur.com/iS0xjdI.mp4 "Swapping Control Components"
[components-tree]: https://i.imgur.com/7M0pH3v.png "Example Components Tree for a Player Entity"
[debug-charts]: https://i.imgur.com/jgAjmzY.png "Debug Chart Windows"
[logo]: /Assets/Logos/Comedot.png "Godot+Comedot Logo"
