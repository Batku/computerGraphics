shader_type canvas_item;

// Apply this shader to a ColorRect covering your viewport

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Vignette
uniform float vignette_intensity :  hint_range(0.0, 1.0) = 0.4;
uniform float vignette_softness : hint_range(0.0, 1.0) = 0.5;

// Film Grain
uniform float grain_amount : hint_range(0.0, 0.5) = 0.15;
uniform float grain_speed : hint_range(0.0, 10.0) = 5.0;

// Chromatic Aberration
uniform float aberration_amount : hint_range(0.0, 0.02) = 0.003;

// Color Grading (desaturated, sickly look)
uniform float desaturation : hint_range(0.0, 1.0) = 0.6;
uniform vec3 color_tint : source_color = vec3(0.9, 0.85, 0.75);
uniform float contrast : hint_range(0.5, 2.0) = 1.15;
uniform float brightness : hint_range(-0.5, 0.5) = -0.05;

// Scanlines (CRT effect like Buckshot's monitors)
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.1;
uniform float scanline_count : hint_range(100.0, 1000.0) = 400.0;

// Screen Shake / Distortion
uniform float distortion_amount : hint_range(0.0, 0.1) = 0.0;

// Flicker
uniform float flicker_intensity : hint_range(0.0, 0.2) = 0.03;

// Random function
float random(vec2 uv) {
    return fract(sin(dot(uv. xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Noise function for grain
float noise(vec2 uv, float time) {
    return random(uv + vec2(time * grain_speed, time * grain_speed * 0.7));
}

void fragment() {
    vec2 uv = SCREEN_UV;
    
    // Screen distortion (subtle waviness for unease)
    if (distortion_amount > 0.0) {
        uv. x += sin(uv.y * 20.0 + TIME * 2.0) * distortion_amount;
        uv.y += cos(uv.x * 15.0 + TIME * 1.5) * distortion_amount * 0.5;
    }
    
    // Chromatic aberration (RGB split)
    vec2 aberration_offset = vec2(aberration_amount, 0.0);
    float r = texture(SCREEN_TEXTURE, uv + aberration_offset).r;
    float g = texture(SCREEN_TEXTURE, uv).g;
    float b = texture(SCREEN_TEXTURE, uv - aberration_offset).b;
    vec3 color = vec3(r, g, b);
    
    // Desaturation (washed out horror look)
    float luminance = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(color, vec3(luminance), desaturation);
    
    // Color tint (sickly yellow/brown like dim lighting)
    color *= color_tint;
    
    // Contrast and brightness
    color = (color - 0.5) * contrast + 0.5 + brightness;
    
    // Vignette (darkness at edges)
    vec2 vignette_uv = uv * (1.0 - uv.xy);
    float vignette = vignette_uv.x * vignette_uv.y * 15.0;
    vignette = pow(vignette, vignette_softness);
    vignette = clamp(vignette, 0.0, 1.0);
    color *= mix(1.0 - vignette_intensity, 1.0, vignette);
    
    // Scanlines (CRT monitor effect)
    float scanline = sin(uv.y * scanline_count * 3.14159) * 0.5 + 0.5;
    scanline = pow(scanline, 1.5);
    color *= 1.0 - (scanline_intensity * (1.0 - scanline));
    
    // Film grain
    float grain = noise(uv * 500.0, TIME) - 0.5;
    color += grain * grain_amount;
    
    // Random flicker (like unstable lighting)
    float flicker = 1.0 - (random(vec2(TIME * 10.0, 0.0)) * flicker_intensity);
    color *= flicker;
    
    // Clamp final color
    color = clamp(color, 0.0, 1.0);
    
    COLOR = vec4(color, 1.0);
}