shader_type texture_blit;
render_mode blend_mix;

uniform sampler2D albedo_texture : hint_blit_source0;
uniform sampler2D normal_texture : hint_blit_source1;
uniform sampler2D ao_texture : hint_default_white;
uniform sampler2D roughness_texture : hint_default_white;
uniform sampler2D metallic_texture : hint_default_black;
uniform vec2 texture_size = vec2(1024.0, 1024.0);
uniform float opacity:hint_range(0,1) = 1;
uniform sampler2D mask:hint_default_white,repeat_enable;
uniform vec2 maskOffset = vec2( 0.0, 0.0 );
uniform float maskScale = 1;
uniform float maskRotation = 0.0;

// ---- walkthrough copy only -------------------------------------------------
// 0 = normal paint, 1 = circular falloff only, 2 = sampled mask only,
// 3 = final stamp alpha (falloff * mask * opacity). Debug stamps paint the
// value as opaque gray into albedo and leave normal/ORM untouched.
uniform int debug_mode : hint_range(0, 3) = 0;

vec2 rotate( vec2 uv, float angle )
{
  float s = sin( angle );
  float c = cos( angle );

    
  float x = uv.x;
  float y = uv.y; 
 
  uv.x = c * x - s * y;
  uv.y = s * x + c * y;

  return uv;
}

vec2 scaleUV( vec2 uv, float scale, vec2 pivot )
{
  uv -= pivot;
  uv *= scale;
  uv += pivot;

  return uv;
}

void blit() 
{
	vec2 uv = FRAGCOORD.xy / texture_size;
	vec4 albedo_color = texture( albedo_texture, uv);
	vec4 normal_color = texture( normal_texture, uv);
	float ao = texture( ao_texture, uv).r;
	float roughness = texture( roughness_texture, uv).r;
	float metallic = texture( metallic_texture, uv ).r;

  vec2 maskUV = rotate( scaleUV( uv, maskScale, vec2( 0.5 ) ), maskRotation ) + maskOffset;
  float sampledMask = texture( mask, maskUV ).r;

	float radius = length( UV * 2.0 - 1.0 );
	float alpha = 1.0 - smoothstep( 0.2, 0.8, radius );

  alpha *= sampledMask * opacity;

	// Output albedo
	COLOR0 = vec4( MODULATE.rgb * albedo_color.rgb, albedo_color.a * alpha);

	// Output normal
	COLOR1 = vec4( normal_color.rgb, alpha );

	// Output ORM
	COLOR2 = vec4( ao, roughness, metallic, alpha );

	// texture_blit forbids early return, so the debug override sits at the
	// end and overwrites the outputs (walkthrough copy only).
	if ( debug_mode > 0 ) {
		float base = 1.0 - smoothstep( 0.2, 0.8, radius );
		float shown = base;
		if ( debug_mode == 2 ) shown = sampledMask;
		if ( debug_mode == 3 ) shown = alpha;
		// 모드 1은 사각 렉트 경계까지 보여주는 게 목적이라 불투명하게 찍고,
		// 나머지 모드는 알파 0 픽셀을 건드리지 않아 검은 사각형이 안 남는다.
		float cover = debug_mode == 1 ? 1.0 : step( 0.004, shown );
		COLOR0 = vec4( vec3( shown ), cover );
		COLOR1 = vec4( 0.5, 0.5, 1.0, 0.0 );
		COLOR2 = vec4( 0.0, 1.0, 0.0, 0.0 );
	}
}
