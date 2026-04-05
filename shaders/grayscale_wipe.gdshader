shader_type canvas_item;

// 진행도에 따라 아래에서 위로 색이 차오르는 효과.
// progress = 0.0 → 전체 흑백, progress = 1.0 → 전체 컬러.
// edge_softness로 경계 부드러움 조절.

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float edge_softness : hint_range(0.0, 0.2) = 0.05;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);

	// 그레이스케일
	float gray = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));
	vec3 gray_color = vec3(gray);

	// 아래(UV.y=1)에서 위(UV.y=0)로 차오름
	// progress가 0.5이면 화면 아래 절반이 컬러
	float threshold = 1.0 - progress;
	float mask = smoothstep(threshold - edge_softness, threshold + edge_softness, 1.0 - UV.y);

	vec3 final_rgb = mix(gray_color, tex_color.rgb, mask);
	COLOR = vec4(final_rgb, tex_color.a);
}
