# Assets Catalog

An index of the free assets included with Comedot for quick prototyping in `/Assets/`. Variations of one asset are listed as one entry.

See the third-party licenses for source information:  
* `Godot Demo Projects Shaders.md`
* `Kenney1Bit License.txt`
* `PixelOperator8 License.txt`


## Fonts

* PixelOperator8: Proportional 8-pixel TrueType font for compact game and UI text.
* PixelOperator8-Bold: Bold proportional variant of PixelOperator8 for emphasized game and UI text.
* PixelOperatorMono8: Monospaced 8-pixel TrueType font for aligned values, statistics, debug text, and compact UI.
* PixelOperatorMono8-Bold: Bold monospaced variant of PixelOperatorMono8.


## Icons

* ComedotAppIcon: Primary Comedot application icon, supplied as an editable SVG and a rendered 512x512 PNG.
* ComedotChibiIcon: Compact Comedot mascot icon used by the Components Dock and suitable for editor or tool UI.
* Component: 16x16 cyan puzzle-piece SVG used for Component scripts, scenes, and editor controls.
* Entity: 16x16 green figure SVG used for Entity scripts, scenes, and editor controls.
* Godot: 128x128 framed Godot logo SVG for engine or project placeholders.


## Images

* Checkerboard16: Neutral 16x16 checkerboard texture for repeated backgrounds, transparency guides, and alignment checks.
* Checkerboard32: Neutral 32x32 checkerboard texture used by the default launch background.
* Checkerboard8: Neutral 8x8 checkerboard texture for fine repeated backgrounds and alignment checks.
* DebugCheckerboard16: High-contrast 16x16 debug checkerboard used by prototype sprites and placement tests.
* DebugCheckerboard32: High-contrast 32x32 debug checkerboard used by test scenes and TileSet templates.
* DebugCheckerboard8: High-contrast 8x8 debug checkerboard for fine placement and scaling tests.
* NeutralPointLight: Neutral 256x256 radial light texture for PointLight2D effects and glow-like decorations.
* Solid16: Solid white 16x16 texture for simple sprites, masks, particles, or debug geometry.
* Solid2: Solid white 2x2 texture for minimal repeated fills and tiny particles.
* Solid32: Solid white 32x32 texture for simple sprites, masks, particles, or debug geometry.
* Solid4: Solid white 4x4 texture used by bullets and debug markers.
* Solid8: Solid white 8x8 texture for simple sprites, masks, particles, or debug geometry.
* SolidGray16: Solid gray 16x16 texture for neutral prototype sprites and fills.
* SolidGray32: Solid gray 32x32 texture for neutral prototype sprites and fills.
* SolidGray8: Solid gray 8x8 texture for neutral prototype sprites and fills.
* StatPip: Filled 8x8 square pip sprite used by StatPips to represent available Stat points.
* StatPipDepleted: Depleted 8x8 square pip sprite used by StatPips to represent missing Stat points.


## Images/Kenney 1-Bit Pack

* Heart Empty: Empty 16x16 heart sprite for health indicators and prototype HUDs.
* Heart Full: Full 16x16 heart sprite for health indicators and prototype HUDs.
* Heart Half: Half-full 16x16 heart sprite for health indicators and prototype HUDs.
* Heart Small: Small centered 16x16 heart sprite for compact health indicators or pickups.


## Logos

* ComedotExtraLogo: Wide 678x377 Godot-and-Comedot logo used by the project boot splash and README branding.
* ComedotLogo: Full-color 417x377 Comedot logo used by the default GameFrame launch scene.
* ComedotLogo-Grayscale: Grayscale 417x377 Comedot logo for monochrome branding or alternate presentation.


## Materials

* Add: CanvasItemMaterial configured for additive blending. Useful for light, energy, particles, and overlapping glow effects.
* AddUnshaded: Additive CanvasItemMaterial that ignores 2D lighting. Useful for always-visible cursors, overlays, and effects.
* Multiply: CanvasItemMaterial configured for multiplicative blending, commonly used to tint or darken underlying visuals.
* Subtract: CanvasItemMaterial configured for subtractive blending, useful for darkening or cutout-like effects.
* Unshaded: CanvasItemMaterial that ignores 2D lighting while retaining normal mix blending.


## Shaders - Screen

* BCS: Full-screen color adjustment shader with independent brightness, contrast, and saturation controls.
* Blur: Full-screen mipmap blur controlled by an `amount` level.
* Contrasted: Shifts every screen RGB channel halfway around its range, producing a strong complementary color remapping.
* Mirage: Animates a horizontal sine-wave distortion across the screen, controlled by frequency and depth.
* Negative: Inverts every screen pixel's RGB color.
* Normalized: Rescales each screen pixel's RGB vector to unit length while retaining its channel proportions.
* OldFilm: Converts the screen to a configurable monochrome tint, then applies animated grain, a vignette texture, and flashing. Requires grain and vignette textures.
* Pixelize: Pixelates the screen by quantizing horizontal and vertical screen coordinates to configurable block sizes.
* Sepia: Converts screen luminance to a configurable monochrome tint; use a sepia-colored `base` value for a traditional sepia effect.
* Vignette: Uses a vignette texture to darken the screen edges and increase mipmap blur where the texture is darker.
* Whirl: Applies a radial swirl around the screen center, controlled by rotation strength.


## Shaders - Sprite

* Aura: Adds a configurable colored aura along a sprite's alpha transitions. Requires premultiplied-alpha blending.
* Blur: Blurs a sprite by averaging its original texture sample with four samples at a configurable radius.
* Disintegrate: Applies a deterministic random alpha mask to dissolve sprite pixels, controlled by amount.
* DropShadow: Builds a soft, configurable-color shadow from eight texture samples surrounding the sprite, then composites the original sprite over it.
* Fatty: Radially warps sprite texture coordinates around the center to create bulging or pinching distortion.
* Glow: Adds a blurred glow derived from sprite colors using two rings of texture samples, with configurable radius and amount.
* OffsetShadow: Adds a configurable-color silhouette behind a sprite at a pixel offset.
* Outline: Draws a configurable-color outline around sprite alpha edges at a chosen width.
* PaletteSwap: Replaces up to 16 source colors with paired target colors using configurable matching tolerance, while preserving texture alpha and CanvasItem modulation.
* Silouette: Replaces all sprite RGB values with one configurable color while preserving texture alpha.


## Themes

* Comedot Default: Main pixel-art UI Theme combining PixelOperator8 with the shared button, scrollbar, panel, and empty StyleBox resources.
* StyleBoxEmpty: Empty StyleBox resource for Control states that need layout or theme coverage without drawing a background.


## Themes/Button

* Disabled StyleBox: Muted translucent purple StyleBoxFlat for disabled buttons in the default Comedot theme.
* Focus StyleBox: Transparent-center focus border with a soft shadow for keyboard and gamepad focus indication.
* Hover StyleBox: Blue translucent bordered StyleBoxFlat for hovered buttons.
* Normal StyleBox: Purple translucent bordered StyleBoxFlat for normal buttons.
* Pressed StyleBox: Bright purple StyleBoxFlat with a stronger border and small shadow for pressed buttons.


## Themes/Label

* Debug Outline: Eight-pixel LabelSettings with a thick black outline for readable debug labels over gameplay.
* InteractionControlComponent: Eight-pixel LabelSettings with a medium translucent outline for interaction prompts.
* LabelComponent: Basic eight-pixel PixelOperator8 LabelSettings used by LabelComponent.
* PauseOverlay ExtraLabel: Pink eight-pixel LabelSettings with a thick translucent outline for secondary pause-overlay text.
* PixelOperatorBold8: Reusable LabelSettings for eight-pixel bold PixelOperator text.
* PixelOperatorMono8: Green eight-pixel monospaced LabelSettings for aligned values and compact readouts.
* StatLabel: Eight-pixel monospaced LabelSettings with a thin black outline for Stat and GameplayResource views.
* TemporaryLabel: Eight-pixel LabelSettings with a thin black outline for fading, blinking, and other temporary labels.
* TextBubble: Eight-pixel LabelSettings with a medium translucent outline for floating text bubbles.
* TextInteractionComponent: Bold eight-pixel LabelSettings with a thick outline and downward shadow for interactive text.


## Themes/ScrollBar

* ScrollBar: Translucent purple StyleBoxFlat for the default scrollbar track.
* ScrollBar Grabber: Pale purple StyleBoxFlat for the default scrollbar grabber.
* ScrollBar Grabber Highlight: Bordered pale purple StyleBoxFlat for a highlighted scrollbar grabber.
* ScrollBar Grabber Pressed: White StyleBoxFlat for a pressed scrollbar grabber.


## TileSets

* Kenney1Bit-Colored: Opaque 784x352 colored Kenney 1-Bit sprite sheet with 16x16 characters, terrain, objects, UI symbols, items, and effects.
* Kenney1Bit-Colored-Physics: Colored Kenney TileSet with collision, occlusion, navigation, walkability/blocking data, and destructible-tile metadata.
* Kenney1Bit-Colored-Transparent: Transparent-background 784x352 colored Kenney 1-Bit sprite sheet for extracting prototype sprites and tiles.
* Kenney1Bit-Monochrome: Monochrome 784x352 sprite sheet plus a matching TileSet with walkability and blocking custom data.
* Kenney1Bit-Monochrome-Physics: Monochrome Kenney TileSet with collision, occlusion, and walkability/blocking data.
* Kenney1Bit-Monochrome-Transparent: Transparent-background monochrome sprite sheet plus a matching TileSet with walkability and blocking custom data.
* Kenney1Bit-Monochrome-Transparent-Physics: Transparent monochrome Kenney TileSet with collision, occlusion, and walkability/blocking data.


Total listed: 87
Generated by AI (Codex) on 2026-07-13
