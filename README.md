# Shader Effects Library

Small library to allow extending rendertype_text fragment shaders with custom effect.

The effects are displayed using a custom font and titles.

Used color codes:
- Alpha 251: Fullscreen effect (extends vertices of rendered letter to fill screen)
- Alpha 252: Marker for animated emoji
- Alpha 253: Similar to 251; Marker for unscaled effects

Animated emoji format:
- Red channel: number of frames in the texture
- Green channel: frames per second
- Blue channel: height per frame

Animated emoji are automatically "converted" to the animated format by naming the file `<name>_animoji<fps>.png`, for example `blink_animoji5.png` will play at 5 FPS

# Commands

`/shaderfx run <effect id> <target player> <hex color> <fade-in-ticks> <stay-for-ticks> <fade-out-ticks>`

Example for fullscreen effect:

`/shaderfx run shaderfx:vignette @s fff 20 10 20`

In some cases you may want to specify your own font/character:

`/shaderfx:custom run shaderfx:vignette "<font:mynamespace:font1>X</font>" @s fff 20 10 20`

For example the builtin image-based transition fonts:
`/shaderfx:custom run "<font:shaderfx:transition><black>C</font>" @s 10 20 10`

THe built-in image-based transitions can also be shown with shaderfx:transition:
`/shaderfx:transition run shaderfx:transition-mechadoor @s 000000 10 20 10`

# Config

```json
{
  "add-assets": true,
  "enable-animated-emoji-conversion": true,
  "mark-as-required": true,
  "effect-textures": [
    {
      "path": "assets/shaderfx/textures/font/custom/fractal.png",
      "effect": "shaderfx:end",
      "size": {
        "x": 40,
        "y": 9
      }
    }
  ],
  "join-effect": {
    "enabled": true,
    "type": "transition",
    "effect": "shaderfx:transition-enclosing-triangles",
    "color": 0,
    "stay": 15,
    "fade-out": 20
  }
}
```

`effect-textures` can be used to reference textures in your polymer managed resource-pack.

the join-effect type can be "transition" or empty/set to "none", "transition" will use the effect under the `/shaderfx:transition run` command.

# API

Includes to the rendertype_text.fsh shader can be added like this:
```java
ShaderEffects.addImport(ResourceLocation.withDefaultNamespace("myeffect.glsl"));
```

This will add a `#moj_import <minecraft:myeffect.glsl>` line at the top of the shader.
The client expects the included shaders to be located in `assets/<namespace>/shaders/include/<file>`.

Code snippets for different effects can be added like this:
```java
static final ShaderEffect VIGNETTE = ShaderEffects.register(ResourceLocation.fromNamespaceAndPath("mynamespace", "vignette"), loadSnippet("vignette_impl.glsl"));
```

`vignette_impl.glsl`:
```glsl
void main() {
    color = vec4(0, 0, 0, clamp(length(centerUV * vec2(0.8, 0.5 / (1 - vertexColor.a))) - 0.6, 0, 1));
}
```

The first and last line of the snippet file will be removed and the implementation will be inserted as `case` in the fragment shader.
Compiled shader:
```glsl
#version 330

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:globals.glsl>
#moj_import <minecraft:dynamictransforms.glsl>

// imported shaders through ShaderEffects.addImport are here:
#moj_import <minecraft:shaderfx_utils.glsl>
#moj_import <minecraft:spikes.glsl>
#moj_import <minecraft:fractal1.glsl>
#moj_import <minecraft:fractal2.glsl>
#moj_import <minecraft:aperture.glsl>

uniform sampler2D Sampler0;

in float sphericalVertexDistance;
in float cylindricalVertexDistance;
in vec4 vertexColor;
in vec2 texCoord0;

flat in int effectId;

flat in int frames;
flat in int fps;
flat in float frameheight;

out vec4 fragColor;

void main() {
    vec4 texColor = texture(Sampler0, texCoord0);
    vec4 color = texColor * vertexColor * ColorModulator;

    vec2 centerUV = gl_FragCoord.xy / ScreenSize - 0.5;
    float ratio = ScreenSize.y / ScreenSize.x;

    if (effectId != 0) {
        switch (effectId) { 
// snippets will be placed here:
case 1: { // vignette_impl.glsl:
    color = vec4(0, 0, 0, clamp(length(centerUV * vec2(0.8, 0.5 / (1 - vertexColor.a))) - 0.6, 0, 1));
} break;
case 2: {
    // another implementation
} break;
/// etc
        }
    }

    // animated emoji
    if (frames > 1) {
        int frameI = int(mod(floor(GameTime*1000.0*fps), frames-1));
        float framePart = 1.0 / float(frames);

        float ty = texCoord0.y*256.0;
        if (ty > frameheight)
            discard;

        color = texture(Sampler0, texCoord0  + vec2(0, frameheight/256*(frameI+1)));
    }

    if (color.a < 0.1) {
        discard;
    }

    fragColor = apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
}
```