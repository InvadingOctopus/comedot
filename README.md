# Comedot

![Godot+Comedot Logo][logo]

[![Godot v4.8+][godot-badge]][godot-download] [![Comedot][release-badge]][comedot-releases]

**Comedot is an opinionated as fuck framework & project template for [Godot][godot]** where you build games by smacking components into entities and tweaking their parameters.

_"Entities"_ and _"Components"_ are just regular Godot Nodes but for gameplay mechanics, so you can mix this framework with your usual Godot workflow or any other architecture or fetish.

**The goal is to make an all-in-one toolkit for 2D games of any genre:** Platformers, shoot-em-ups, RPGs, strategy, puzzle, turn-based, tile-based etc. This is the result of trying to make [future GotYs][itch] while learning which stuff is needed frequently in multiple genres & shoving it into a shared library.

<sub>*(if you think "ECS" only means "data-oriented design" you need to get out more)*</sub>

<br/> <br/>

![components-tree]

* [120+ megatons][allComponents] of components for player movement, combat, collectibles, interactions, upgrades etc.
* Template scenes for Logo → Main Menu → Options, Input Remapping, Pause Overlay
* UI controls including stat HUDs & dynamic buttons for special skills, inventory etc.
* [150+ neutron star spoonfuls][allScripts] of helper functions & debugging tools.
* Free-to-use tilesets, fonts, shaders & other assets for quick prototyping.
* Snippets for VSCode/VSCodium.

💜 *Organically grown with smooches & cooties〜*

* Commented & documented code.
* Save/Load player preferences via a config file with just `Settings.anyName = 69`
* Bind global values with keys like `"monsterColor"` to Node properties like `modulate` & update them automatically when the values change.
* Handy for game jams & rapid iteration, with paths open for more power & customizations.
* Optimized for balancing ease of use + performance as much as GDScript will allow.
* Meatcrafted components can be Lego'ed together by AI codeblins to reliably create various kinds of gameplay. *\*(Comedot itself has no AI-generated code.)*

🌟 Some specially sprillific components go beyond the bare implementation to make sure gameplay *feels* right, by handling tricky cases that all games run into sooner or later, like:

* Health/ammo/etc. collectibles don't get picked up if your stat is at max. If the stat drops while still standing on the item, _then_ it gets picked up!
* Climbing: Grabbing a ladder/rope while holding the climb input in mid-jump. Walking towards the ladder if not fully aligned. Horizontal movement on fences etc.

> [!WARNING]
> _This is still mostly a private personal project; the API eschews cringe conventions like ugly underscores and shit may break frequently:_ **No backwards compatibility is guaranteed!**

<br/> <br/>

## Examples

⭐️ The [composition architecture][composition-over-inheritance] lets you do cool shit like putting a `GunComponent` & `NodeFacingComponent` on any object and _It Just Works:_ [(imgur)][pew-pew-plants]  

https://github.com/user-attachments/assets/43853546-159f-4184-a7a4-da857ba5e75c

<br/>

⭐️ Implement dynamic gameplay and easily change abilities/buffs at runtime; just add/remove components in simple event handlers, like this example of swapping between platformer physics and flying movement: [(imgur)][swapping-components]  

https://github.com/user-attachments/assets/061cf16a-04e9-477d-8f59-e2fa0fa523b7

<sub>_These scenes are included in_ `/Templates/Examples/`</sub>

<br/>

📈 There's even kawaii charts for monitoring variables in real-time!  

![debug-charts]

<br/> <br/>

## How To Use

> [!IMPORTANT]  
> _Requires **Godot 4.8** 〜embrace the future ✨_

> [!TIP]
> 🚀 **Quickstart:** To try right away, run `/Templates/Scenes/PlatformerSceneTemplate.tscn`
>
> 🍒 If you don't need the entire template, you can just yoink specific code to use in your own scripts, like [*Tools.gd][tools]

1. Clone this repository; this is a Godot template so you should make a local copy of this entire project for each of your games.

2. Use the included custom dock plugin (the Comedock :)

![Custom Dock Plugin][comedock]

3. or you can drag-&-drop files from the `/Entities/` and `/Components/` folders into your scene tree.  
	* `/Templates/` contains scenes and Entities with preset Components as a quick starting point for basic gameplay.  
	* `/Scripts/` contains code for non-Entity nodes.  
	* `/UI/` contains customizable UI elements for health, ammo, abilities, upgrades etc.  

4. _or you can do everything manually:_

	🎭 Whenever your game needs an "actor" like the player character or a monster, or an object with "behaviors" that could be reused for other objects, like interactive props or collectible powerups:

	1. Create a new **Entity** node: a `Node2D/Sprite2D/CharacterBody2D` etc. with the `Entity.gd` script attached.
	2. Add **Component** child nodes to the entity. A component is also any `Node/Area2D` etc. with a script that `extends Component`
	3. Modify component parameters in the Inspector Dock.
	4. Save that entity+components subtree as a standalone scene file, to organize it separately from the main "world scene" and quickly create copies of it anywhere.

<br/>

> [!TIP]
> 📜 **Read [HowTo.md][howto] to see how to do basic tasks or fix common issues.**  
> See [Conventions.md][conventions] for the style guide and design rules this project tries to follow.  
> [AGENTS.md][agents] contains instructions for AI assistants that may also be helpful for meat-based coders.  
>
> 🤖 You can ask AI agents to update your existing projects to the latest Comedot branch.

<br/>

----

[Comedot][repository] © MMXXVI [ShinryakuTako@GitHub][github] • [Syntaks.io@Discord][discord] • [Syntaks@Mastodon][mastodon]

[MIT License][license] Make games, sell games, mutate the framework into whatever beautiful monster you need.

> ### 💕 THANKS:  
> * Tilesets:	https://kenney.nl/assets/1-bit-pack  
> * Font:		Jayvee Enaguas (HarvettFox96) https://www.dafont.com/pixel-operator.font

[repository]: https://github.com/invadingoctopus/comedot
[website]: https://invadingoctopus.io
[license]: LICENSE.txt
[patreon]: https://www.patreon.com/invadingoctopus
[discord]: https://discord.gg/jZG3cBFt7u
[github]:  https://github.com/ShinryakuTako
[itch]:    https://syntaks.itch.io
[twitter]: https://twitter.com/invadingoctopus
[mastodon]:https://mastodon.gamedev.place/@Syntaks

[howto]:		HowTo.md
[conventions]:	Conventions.md
[agents]:		AGENTS.md
[todo]:			ToDo.md
[tools]:		Scripts/Tools/Tools.gd
[allComponents]:Notes/Components%20Catalog.md
[allScripts]:	Notes/Scripts%20Catalog.md

[godot]: https://godotengine.org "Godot Game Engine"
[composition-over-inheritance]: https://en.wikipedia.org/wiki/Composition_over_inheritance
[entity–component–system]: https://en.wikipedia.org/wiki/Entity_component_system

[godot-badge]:		https://img.shields.io/badge/Godot-v4.8%2B-478CBF
[godot-download]:	https://godotengine.org/download/archive/ "Requires Godot 4.8+"
[release-badge]:	https://img.shields.io/github/v/release/InvadingOctopus/comedot?include_prereleases&label=Comedot&color=20A000
[comedot-releases]:	https://github.com/InvadingOctopus/comedot/releases "Latest Comedot Release"

[logo]: Assets/Logos/ComedotExtraLogo.png "Godot+Comedot Logo"
[components-tree]: https://raw.githubusercontent.com/InvadingOctopus/comedot-media/refs/heads/main/Screenshots/Components%20Tree.png "🌳 Example Components Tree for a Player Entity"
[pew-pew-plants]: https://i.imgur.com/1XyiqVr.mp4 "Trees with Guns"
[swapping-components]: https://i.imgur.com/Y7vbdpl.mp4 "Swapping Control Components"
[debug-charts]: https://raw.githubusercontent.com/InvadingOctopus/comedot-media/refs/heads/main/Screenshots/Debug%20Charts%20%26%20Watchlists.png "Debug Chart Windows"
[comedock]: https://raw.githubusercontent.com/InvadingOctopus/comedot-media/refs/heads/main/Screenshots/Comedock.png "Godot Dock Plugin"
