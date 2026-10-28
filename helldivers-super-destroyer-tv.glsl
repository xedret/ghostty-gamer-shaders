// Super Destroyer Tactical Display Shader for Ghostty
// Inspired by Helldivers 2 - Super Destroyer Terminal

// --- Animated Pseudo-Random Grain ---
float rand(vec2 co) {
    return fract(sin(dot(co, vec2(124.9898, 78.233))) * 43758.5453);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;

    // =========================================================
    // 1. Dark Gray / Charcoal Background
    // =========================================================
    vec3 bgColor = vec3(0.2, 0.2, 0.2);

    // Subtle radial falloff toward screen center
    float radial = .70 - length(uv - 0.25) * 0.3;
    bgColor *= radial;

    // =========================================================
    // 2. Tactical Grid & Intersection Highlights
    // =========================================================
    vec2 gridScale = vec2(36.0, 22.0);
    vec2 gridUV = uv * gridScale;

    // Anti-aliased grid lines
    vec2 lineFrac = abs(fract(gridUV - 0.5) - 0.5) / fwidth(gridUV);
    float gridX = 1.0 - min(lineFrac.x, 1.0);
    float gridY = 1.0 - min(lineFrac.y, 1.0);
    float gridLine = max(gridX, gridY);

    vec3 lineColor = vec3(0.20, 0.22, 0.22);

    vec3 bg = bgColor;
    bg += lineColor * gridLine * 0.50;

    // =========================================================
    // 3. Subtle CRT Scanlines, Vignette & Noise
    // =========================================================
    float scanline = sin(uv.y * iResolution.y * 1.2) * 0.75;
    bg *= 0.93 + 0.07 * scanline;

    vec2 vigUV = uv * (1.00 - uv.yx);
    float vig = vigUV.x * vigUV.y * .25;
    vig = clamp(pow(vig, 0.27), 0.12, 1.0);
    bg *= vig;

    // Subtle animated screen grain
    // float grain = rand(fragCoord.xy + vec2(iTime * .4, iTime * 67.8)); // Will work on this later, can't get it to work properly
    float noise = fract(sin(dot(uv + mod(iTime, 11.0) * .012, vec2(25.9898, 71.233))) * 12758.5453);
    bg += (noise - 1.35) * 0.03; // Adjust 0.03 to increase or decrease noise strength

    // =========================================================
    // 4. Terminal Text Composition
    // =========================================================
    vec4 termColor = texture(iChannel0, uv);
    float termLuma = max(termColor.r, max(termColor.g, termColor.b));

    vec3 finalColor;
    if (termLuma < 0.05) {
        finalColor = bg;
    } else {
        // High-contrast blending for crisp terminal text
        finalColor = mix(bg * 0.55, termColor.rgb + vec3(0.55, 0.55, 0.55), clamp(termLuma * .35, 0.35, .35));
    }

    fragColor = vec4(finalColor, 1.0);
}