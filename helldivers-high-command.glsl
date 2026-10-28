// Super Earth High Command Terminal Shader for Ghostty
// Inspired by Helldivers 2

// --- Procedural Noise Functions ---
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    mat2 rot = mat2(0.8, 0.6, -0.6, 0.8);
    for (int i = 0; i < 4; ++i) {
        v += a * noise(p);
        p = rot * p * 2.0;
        a *= 0.5;
    }
    return v;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Standard normalized coordinates
    vec2 uv = fragCoord.xy / iResolution.xy;
    
    // Centered aspect-ratio corrected coordinates for planet geometry
    vec2 st = (fragCoord.xy - 0.5 * iResolution.xy) / iResolution.y;

    // =========================================================
    // 1. Planet Curvature & Atmosphere
    // =========================================================
    vec2 planetCenter = vec2(0.0, -1.65);
    float planetRadius = 1.6;
    float distToCenter = length(st - planetCenter);

    // Planet body mask & edge blending
    float earthMask = smoothstep(planetRadius + 0.005, planetRadius - 0.02, distToCenter);
    
    // Bright atmosphere rim glow along the curved limb
    float atmosphereGlow = smoothstep(planetRadius + 0.25, planetRadius, distToCenter) * 
                           (1.0 - smoothstep(planetRadius, planetRadius - 0.08, distToCenter));

    // Procedural surface details (slow drift over time)
    vec2 surfaceCoords = (st - planetCenter) * 2.2 + vec2(iTime * 0.012, 0.0);
    float continentMap = fbm(surfaceCoords * 2.5);
    float cloudMap = fbm(surfaceCoords * 5.0 + vec2(iTime * 0.02, iTime * 0.008));

    // High Command Blue Color Palette
    vec3 spaceColor = vec3(0.02, 0.05, 0.14);
    vec3 oceanColor = vec3(0.03, 0.15, 0.38);
    vec3 landColor  = vec3(0.08, 0.32, 0.62);
    vec3 cloudColor = vec3(0.35, 0.60, 0.88);
    vec3 atmoColor  = vec3(0.20, 0.70, 1.00);

    // Composite Earth surface
    vec3 planetColor = mix(oceanColor, landColor, smoothstep(0.45, 0.62, continentMap));
    planetColor = mix(planetColor, cloudColor, smoothstep(0.5, 0.72, cloudMap) * 0.45);
    
    // Radial shading toward limb
    float limbShading = smoothstep(planetRadius - 0.4, planetRadius, distToCenter);
    planetColor += atmoColor * limbShading * 0.35;

    // Combine Space, Earth, and Glowing Atmosphere
    vec3 bg = mix(spaceColor, planetColor, earthMask);
    bg += atmoColor * atmosphereGlow * .5;

    // =========================================================
    // 2. Tactical Grid Overlay
    // =========================================================
    // Fine Grid
    vec2 fineGridScale = vec2(60.0, 36.0);
    vec2 fineUV = uv * fineGridScale;
    vec2 fineLine = abs(fract(fineUV - 0.5) - 0.5) / fwidth(fineUV);
    float fineGrid = 1.0 - min(min(fineLine.x, fineLine.y), 1.0);

    // Major Grid Lines
    vec2 majorGridScale = vec2(10.0, 6.0);
    vec2 majorUV = uv * majorGridScale;
    vec2 majorLine = abs(fract(majorUV - 0.5) - 0.5) / fwidth(majorUV);
    float majorGrid = 1.0 - min(min(majorLine.x, majorLine.y), 1.0);

    vec3 gridColor = vec3(0.20, 0.55, 0.95);
    bg += gridColor * fineGrid * 0.12;
    bg += gridColor * majorGrid * 0.28;

    // =========================================================
    // 3. CRT Scanlines & Screen Vignette
    // =========================================================
    float scanline = sin(uv.y * iResolution.y * 1.5) * 0.5 + 0.5;
    bg *= 0.88 + 0.12 * scanline;

    // Edge Vignette
    vec2 vigUV = uv * (1.0 - uv.yx);
    float vig = vigUV.x * vigUV.y * 15.0;
    vig = clamp(pow(vig, 0.22), 0.0, 1.0);
    bg *= vig;

    // =========================================================
    // 4. Terminal Text Composition
    // =========================================================
    vec4 termColor = texture(iChannel0, uv);
    float termLuma = max(termColor.r, max(termColor.g, termColor.b));

    // Composite terminal output over background
    // Pure background pixels show through; active text pixels pop cleanly over the background
    vec3 finalColor;
    if (termLuma < 0.05) {
        finalColor = bg;
    } else {
        // Blend terminal text with subtle emissive backlight
        finalColor = mix(bg * 2.4, termColor.rgb + vec3(0.65, 0.65, 0.75), clamp(termLuma * 0.85, 0.75, 1.0));
    }

    fragColor = vec4(finalColor, 1.0);
}
