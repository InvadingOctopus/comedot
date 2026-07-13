// Replaces all pixels of specific colors in a CanvasItem's texture with paired target colors.
// Each active `sourceColors` index maps to the `targetColors` entry at the same index.
// WARNING: `CanvasItem.modulate` & `self_modulate` can affect the final visible result;
// e.g. if a replacement color is red (RGB: 255,0,0) but `modulate` is set to green (RGB: 0,255,0) then the final result will be black!

shader_type canvas_item;

// Uniform arrays require a fixed capacity,
// so `mappingCount` controls how many color pairs are used
uniform int		mappingCount	 : hint_range(0, 16) = 0;
uniform vec4	sourceColors[16] : source_color;
uniform vec4	targetColors[16] : source_color;

// 0 tolerance requires an exact RGB match.
// TIP: Increase this for filtered or compressed textures.
uniform float	tolerance		 : hint_range(0.0, 1.0, 0.001) = 0.0;

// Store the CanvasItem's `modulate` & `self_modulate` separately from its raw texture colors.
varying vec4	vertexColor;


void vertex() {
	vertexColor = COLOR; // Save the vertex color multiplied by the node’s `modulate` & `self_modulate`
}


void fragment() {
	// Read the raw texture so CanvasItem modulation does not affect color matching
	vec4 textureColor = texture(TEXTURE, UV);
	vec4 mappedColor  = textureColor;

	// Make sure `mappingCount` isn't higher than the last valid array index
	int safeMappingCount = min(mappingCount, 16);

	// Go through each color pair to find a match for the current pixel
	for (int index = 0; index < safeMappingCount; index++) {
		// Compare only RGB, not the A channel, so translucent edge pixels retain their original alpha coverage.
		if (distance(textureColor.rgb, sourceColors[index].rgb) <= tolerance) {
			mappedColor.rgb = targetColors[index].rgb;
			break;
		}
	}

	// Reapply the CanvasItem's modulation after swapping, while preserving the texture's alpha
	COLOR = mappedColor * vertexColor;
}
