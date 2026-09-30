class_name ThemeFilter
extends RefCounted

## Per-theme full-screen background filter, drawn with a small shader.

const SHADERS := {
	"vampire": """
shader_type canvas_item;
uniform vec4 tint : source_color = vec4(0.35, 0.02, 0.08, 1.0);
void fragment() {
	vec2 d = UV - vec2(0.5);
	float v = smoothstep(0.32, 0.86, length(d) * 1.25);
	float drip = smoothstep(0.985, 1.0, sin(UV.x * 42.0) * 0.5 + 0.5) * smoothstep(0.0, 0.25, UV.y) * 0.05;
	COLOR = vec4(tint.rgb, v * 0.55 + drip);
}
""",
	"undead": """
shader_type canvas_item;
uniform vec4 tint : source_color = vec4(0.32, 0.45, 0.16, 1.0);
void fragment() {
	vec2 d = UV - vec2(0.5);
	float v = smoothstep(0.25, 0.9, length(d));
	float band = sin(UV.y * 260.0) * 0.5 + 0.5;
	float n = fract(sin(dot(UV * 480.0, vec2(12.9898, 78.233))) * 43758.5453);
	COLOR = vec4(tint.rgb, v * 0.42 + band * 0.018 + n * 0.02);
}
""",
	"celebrity": """
shader_type canvas_item;
uniform float t = 0.0;
uniform vec4 tint : source_color = vec4(1.0, 0.82, 0.35, 1.0);
float star(vec2 uv, vec2 p, float seed) {
	float tw = 0.5 + 0.5 * sin(t * 1.7 + seed * 24.0);
	float d = length((uv - p) * vec2(1.7, 1.0));
	return smoothstep(0.035, 0.0, d) * tw;
}
void fragment() {
	float s = 0.0;
	for (int i = 0; i < 16; i++) {
		float fi = float(i);
		vec2 p = vec2(fract(sin(fi * 91.3) * 43758.5453), fract(sin(fi * 47.7) * 24634.6345));
		s += star(UV, p, fi);
	}
	float glow = smoothstep(1.0, 0.25, length(UV - vec2(0.5, 0.0))) * 0.10;
	COLOR = vec4(tint.rgb, clamp(s * 0.5 + glow, 0.0, 0.5));
}
""",
	"villain": """
shader_type canvas_item;
uniform float t = 0.0;
uniform vec4 tint : source_color = vec4(0.55, 0.25, 1.0, 1.0);
void fragment() {
	float scan = smoothstep(0.45, 0.55, fract(UV.y * 190.0 + t * 0.12));
	vec2 d = UV - vec2(0.5);
	float v = smoothstep(0.3, 0.95, length(d));
	COLOR = vec4(tint.rgb, scan * 0.045 + v * 0.35);
}
""",
	"superhero": """
shader_type canvas_item;
// The old version was a faint dot grid on a pale background, which read as
// "bright screen" rather than as anything. This is the comic-panel language
// instead: speed lines radiating out of a point, a proper halftone that gets
// coarser toward the edges, a slow sweep of light across it, and a hard
// two-tone split like ink over newsprint.
uniform float t = 0.0;
uniform vec4 tint : source_color = vec4(0.09, 0.28, 0.76, 1.0);
uniform vec4 hot : source_color = vec4(0.89, 0.23, 0.18, 1.0);

float halftone(vec2 uv, float scale, float radius) {
	vec2 g = fract(uv * scale) - vec2(0.5);
	return smoothstep(radius, radius * 0.45, length(g));
}

void fragment() {
	vec2 c = vec2(0.5, 0.42);
	vec2 d = UV - c;
	float r = length(d);
	float a = atan(d.y, d.x);

	// Speed lines: wedges out of the focal point, thinner near the middle.
	float spokes = abs(sin(a * 22.0 + sin(a * 3.0) * 0.6));
	float lines = smoothstep(0.86, 1.0, spokes) * smoothstep(0.12, 0.62, r);

	// Halftone that coarsens outward, the way cheap printing does.
	float dots = halftone(UV, mix(120.0, 46.0, clamp(r * 1.6, 0.0, 1.0)), mix(0.20, 0.40, clamp(r * 1.5, 0.0, 1.0)));
	dots *= smoothstep(0.18, 0.95, r);

	// A slow highlight sweeping across, so it is alive without being busy.
	float sweep = smoothstep(0.055, 0.0, abs(fract(UV.x * 0.42 - UV.y * 0.22 - t * 0.035) - 0.5));

	// A hard diagonal split: ink one side, warm newsprint the other.
	float split = step(0.0, UV.x * 0.9 + UV.y * 0.45 - 0.72);

	vec3 col = mix(tint.rgb, hot.rgb, split * 0.75 + lines * 0.35);
	float alpha = lines * 0.20 + dots * 0.085 + sweep * 0.08 + split * 0.05;
	// A vignette keeps the middle of the screen readable.
	alpha *= mix(1.0, 0.45, smoothstep(0.55, 0.0, r));
	COLOR = vec4(col, clamp(alpha, 0.0, 0.38));
}
""",
	"royal": """
shader_type canvas_item;
uniform float t = 0.0;
uniform vec4 tint : source_color = vec4(0.95, 0.76, 0.33, 1.0);
void fragment() {
	vec2 d = UV - vec2(0.5, 0.0);
	float crown = smoothstep(0.9, 0.0, length(d * vec2(1.0, 1.6))) * 0.13;
	vec2 c = min(UV, 1.0 - UV);
	float corner = smoothstep(0.16, 0.0, length(c * vec2(1.0, 1.78))) * 0.22;
	float lace = smoothstep(0.92, 1.0, sin((UV.x + UV.y) * 90.0) * sin((UV.x - UV.y) * 90.0)) * 0.035;
	float shimmer = smoothstep(0.02, 0.0, abs(fract(UV.x * 0.6 - UV.y * 0.3 - t * 0.05) - 0.5)) * 0.05;
	COLOR = vec4(tint.rgb, crown + corner + lace + shimmer);
}
""",
	"witch": """
shader_type canvas_item;
uniform float t = 0.0;
uniform vec4 tint : source_color = vec4(0.45, 0.22, 0.7, 1.0);
uniform vec4 glow : source_color = vec4(0.3, 0.85, 0.45, 1.0);
float n(vec2 p) {
	return fract(sin(dot(floor(p), vec2(12.9898, 78.233))) * 43758.5453);
}
float smooth_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(n(i), n(i + vec2(1.0, 0.0)), f.x), mix(n(i + vec2(0.0, 1.0)), n(i + vec2(1.0, 1.0)), f.x), f.y);
}
void fragment() {
	vec2 p = UV * vec2(6.0, 3.0) + vec2(t * 0.05, -t * 0.02);
	float mist = smooth_noise(p) * 0.5 + smooth_noise(p * 2.1) * 0.25;
	float low = smoothstep(0.35, 1.0, UV.y);
	float v = smoothstep(0.3, 0.95, length(UV - vec2(0.5)));
	vec3 col = mix(tint.rgb, glow.rgb, smooth_noise(p * 0.7));
	COLOR = vec4(col, mist * low * 0.3 + v * 0.3);
}
""",
	"dark": """
shader_type canvas_item;
uniform float t = 0.0;
uniform vec4 tint : source_color = vec4(0.25, 0.45, 1.0, 1.0);
void fragment() {
	vec2 c1 = vec2(0.15 + sin(t * 0.03) * 0.05, 0.1);
	vec2 c2 = vec2(0.9, 0.95 + cos(t * 0.025) * 0.04);
	float g = smoothstep(0.75, 0.0, length((UV - c1) * vec2(1.78, 1.0))) * 0.07 + smoothstep(0.7, 0.0, length((UV - c2) * vec2(1.78, 1.0))) * 0.05;
	float v = smoothstep(0.45, 1.0, length(UV - vec2(0.5)));
	COLOR = vec4(mix(tint.rgb, vec3(0.0), v), g + v * 0.2);
}
""",
	"light": """
shader_type canvas_item;
uniform vec4 tint : source_color = vec4(1.0, 0.85, 0.6, 1.0);
void fragment() {
	float g = smoothstep(0.9, 0.0, length((UV - vec2(0.1, 0.0)) * vec2(1.78, 1.0))) * 0.10;
	COLOR = vec4(tint.rgb, g);
}
""",
}


static func build(theme_key: String) -> ColorRect:
	if not SHADERS.has(theme_key):
		return null
	var sh := Shader.new()
	sh.code = SHADERS[theme_key]
	var mat := ShaderMaterial.new()
	mat.shader = sh
	var r := ColorRect.new()
	r.material = mat
	r.color = Color(1, 1, 1, 1)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.z_index = -5
	return r


static func animated(theme_key: String) -> bool:
	return theme_key in ["celebrity", "villain", "royal", "witch", "dark", "superhero"]
