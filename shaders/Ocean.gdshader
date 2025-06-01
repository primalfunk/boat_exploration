shader_type spatial;

uniform float wave_amp_1 = 0.08;
uniform float wave_amp_2 = 0.04;
uniform float wave_freq_1 = 0.9;
uniform float wave_freq_2 = 0.6;
uniform float wave_speed = 1.9;

void vertex() {
    float t = TIME * wave_speed;

    float wave1 = sin(VERTEX.x * wave_freq_1 + t) * wave_amp_1;
    float wave2 = cos(VERTEX.z * wave_freq_2 + t) * wave_amp_2;

    VERTEX.y += wave1 + wave2;
}

void fragment() {
    // Fresnel-style deep vs shallow color
    float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
    vec3 deep_color = vec3(0.0, 0.2, 0.5);
    vec3 shallow_color = vec3(0.1, 0.4, 0.6);
    vec3 water_color = mix(deep_color, shallow_color, fresnel);

    // Foam detection from surface tilt
    float tilt = 1.0 - clamp(NORMAL.y, 0.0, 1.0);
    float foam = smoothstep(0.05, 0.25, tilt);
    foam = pow(foam, 0.5); // brighten

    vec3 foam_color = vec3(0.95, 0.98, 1.0);
    vec3 final_color = mix(water_color, foam_color, foam);
	final_color = clamp(final_color, 0.0, 1.0);
	final_color = final_color / (final_color + vec3(1.0));

    ALBEDO = final_color;
    ROUGHNESS = mix(0.15, 0.3, fresnel);
    METALLIC = 0.0;
}
