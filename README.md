# Comedot

_Component-based framework and project template for [Godot][godot]_

![Godot+Comedot Logo][logo]

**The goal is to be an all-in-one toolkit for 2D games** (platformers, shoot-em-ups, RPGs, turn-based strategy or puzzle) where you build scenes by adding components to entities and tweaking their parameters in the UI. _"Entities"_ and _"Components"_ are like regular Godot Nodes but for gameplay, so you can combine this framework with any other addons or architecture or fetish.

![components-tree]

* Comes with a library of components for different types of player movement, combat, collectibles, interactions, upgrades etc.
* UI controls like a stats HUD and dynamic buttons for special skills, inventory etc.
* Template scenes for Logo → Main Menu → Options, Input Remapping, Pause Overlay
* Save/Load player preferences via a config file with just `Settings.anyName = 69`
* A neutron star spoonful of helper functions & debugging tools.
* Commented & documented code.
* Free-to-use 3rd-party assets for quick prototyping.

🎖️ The most sprillific feature is components that go beyond basic implementation to make sure gameplay *feels* right, by handling tricky edge-case issues that all games run into sooner or later, like:

* Health/ammo/etc. collectibles don't get picked up if your stat is at max. If the stat drops while still standing on the item, then it gets picked up!
* Climbing: Grabbing a ladder/rope while holding the climb input in mid-jump. Walking towards the ladder if not fully aligned. Horizontal movement on fences etc.

> [!TIP]
> 🛠️ Even if you don't need the template or components, you can copy some of the logic code to use in your own scripts, or just yoink [Tools.gd][tools]

> [!WARNING]
> _This is still mostly a private personal project; it's what I'm using to make [future GotYs][itch] while learning Godot as I go. The API eschews cringe conventions like ugly underscores and shit may break frequently:_ **No backwards compatibility is guaranteed!**


## Examples 

⭐️ The [composition architecture][composition-over-inheritance] lets you do cool shit like putting a `GunComponent` and `MouseRotationComponent` on any object and _It Just Works:_ [(imgur)][pew-pew-plants]  

https://github.com/user-attachments/assets/bc76f0b2-62f7-4fd5-8d26-fef27b182e22

⭐️ Implement dynamic gameplay and easily change abilities/buffs at runtime; just add/remove components in simple event handlers, like this example of swapping between platformer physics and flying/overhead movement: [(imgur)][swapping-components]  

https://github.com/user-attachments/assets/9c71c166-4e0c-47c7-afc1-3334022366cd

⬆️ _These scenes are included in_ `/Templates/Examples/`

📈 There's even kawaii charts for monitoring variables in real-time!  

![debug-charts]


## How To Use

> [!IMPORTANT]  
> _Requires Godot 4.5 ~Embrace the Future_ ✨  

1. Clone this repository; This is a Godot template so you must make a local copy of this entire project for each of your games.
	* Or you can cherry-pick files from Comedot to use in other templates.
2. Drag-&-drop nodes from the `/Entities/` and `/Components/` folders into your scene tree.
	* `/Templates/` contains scenes and Entities with preset Components as a quick starting point for various gameplay.
	* `/Scripts/` contains code for non-Entity nodes.
	* `/UI/` contains customizable UI elements for health, ammo, actions, upgrades etc.

![Custom Dock Plugin][comedock]

> [!NOTE]
> 🧩 A "component" is any Godot node that:
> * Reacts to events (like player input or collisions).
> * Moves or modifies its parent node or other components.
> * Contains data for other components to use (like character health and other stats).
>
> 🪆 An "entity" is a node whose children are components (it may also have non-component children).

🎳 Whenever your game needs an "actor" like the player character or a monster, or an object with "behaviors" that could be reused for other objects, like interactive items or collectible powerups:

* _Use the included custom dock plugin (the Comedock :) or perform these steps manually:_
1. Create a new **Entity** node: a `Node2D/Sprite2D/CharacterBody2D` etc. with the `Entity.gd` script attached.
2. Add **Component** child nodes to the entity. A component is also any `Node/Area2D` etc. with a script that `extends Component`
3. Modify component parameters in the Inspector sidebar.
4. Save that entity+components subtree as a standalone scene file, to organize it separately from the main "world scene" and quickly create copies of it anywhere.

> [!TIP]
> 📜 **Read [HowTo.md][howto] to see how to do basic tasks or fix common issues.**  
> See [Conventions.md][Conventions] for the style guide and design rules this project tries to follow.


----

[Comedot][repository] ©? MMXXV [ShinryakuTako@GitHub][github] • [Syntaks.io@Discord][discord] • [Syntaks@Mastodon][mastodon]

> 💕 THANKS:  
> * Tilesets:	https://kenney.nl/assets/1-bit-pack  
> * Font:		Jayvee Enaguas (HarvettFox96) https://www.dafont.com/pixel-operator.font

[repository]: https://github.com/invadingoctopus/comedot
[website]: https://invadingoctopus.io
[license]: License.txt
[patreon]: https://www.patreon.com/invadingoctopus
[discord]: https://discord.gg/jZG3cBFt7u
[github]:  https://github.com/ShinryakuTako
[itch]:    https://syntaks.itch.io
[twitter]: https://twitter.com/invadingoctopus
[mastodon]:https://mastodon.gamedev.place/@Syntaks

[howto]:		HowTo.md
[conventions]:	Conventions.md
[thanks]:		Thanks.md
[todo]:			ToDo.md
[tools]:		/Scripts/Tools.gd

[godot]: https://github.com/godotengine/godot "Godot Game Engine"
[composition-over-inheritance]: https://en.wikipedia.org/wiki/Composition_over_inheritance
[entity–component–system]: https://en.wikipedia.org/wiki/Entity_component_system

[logo]: /Assets/Logos/ComedotExtraLogo.png "Godot+Comedot Logo"
[components-tree]: https://raw.githubusercontent.com/InvadingOctopus/comedot-media/refs/heads/main/Screenshots/Components%20Tree.png "🌳 Example Components Tree for a Player Entity"
[pew-pew-plants]: https://i.imgur.com/1XyiqVr.mp4 "Trees with Guns"
[swapping-components]: https://i.imgur.com/Y7vbdpl.mp4 "Swapping Control Components"
[debug-charts]: https://raw.githubusercontent.com/InvadingOctopus/comedot-media/refs/heads/main/Screenshots/Debug%20Charts%20%26%20Watchlists.png "Debug Chart Windows"
[comedock]: https://raw.githubusercontent.com/InvadingOctopus/comedot-media/refs/heads/main/Screenshots/Comedock.png "Godot Dock Plugin"
