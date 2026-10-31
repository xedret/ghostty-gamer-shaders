// Super Destroyer Tactical Display Shader for Ghostty
// Inspired by Helldivers 2 - Super Destroyer Terminal

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;

    // =========================================================
    // 1. Dark Gray / Charcoal Background
    // =========================================================
    vec3 bgColor = vec3(0.11, 0.11, 0.11);

    // Subtle radial falloff toward screen center
    float radial = .70 - length(uv - 0.25) * 0.3;
    bgColor *= radial;

    // =========================================================
    // 2. Tactical Grid & Intersection Highlights
    // =========================================================
    vec2 gridScale = vec2(36.0, 20.0);
    vec2 gridUV = uv * gridScale;

    // Anti-aliased grid lines
    vec2 lineFrac = abs(fract(gridUV - 0.5) - 0.5) / fwidth(gridUV);
    float gridX = 1.0 - min(lineFrac.x, 1.0);
    float gridY = 1.0 - min(lineFrac.y, 1.0);
    float gridLine = max(gridX, gridY);

    // Intersection highlight (hits harder right where lines cross)
    vec2 distFromNode = abs(fract(gridUV) - 0.5);
    float intersectionNode = smoothstep(0.10, 0.0, length(distFromNode));

    vec3 lineColor = vec3(0.20, 0.22, 0.25);

    vec3 bg = bgColor;
    bg += lineColor * gridLine * 0.50;

    // =========================================================
    // 3. Subtle CRT Scanlines & Edge Vignette
    // =========================================================
    float scanline = sin(uv.y * iResolution.y * 1.2) * 0.5 + 0.5;
    bg *= 0.93 + 0.07 * scanline;

    vec2 vigUV = uv * (1.0 - uv.yx);
    float vig = vigUV.x * vigUV.y * .75;
    vig = clamp(pow(vig, 0.35), 0.2, 0.2);
    bg *= vig;

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