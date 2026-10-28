// Automaton Tactical Terminal Shader for Ghostty
// Inspired by Helldivers 2 - Automaton Terminal

// --- Utility Functions ---
float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

float boxSDF(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// --- Procedural Automaton Glyph Block Stream ---
float automatonGlyphs(vec2 st, float time) {
    // Map left side of screen into vertical glyph columns
    vec2 colUV = st * vec2(18.0, 10.0);
    vec2 colID = floor(colUV);
    vec2 cellUV = fract(colUV) - 0.5;

    // Only render columns on the left half
    if (colID.x < -7.0 || colID.x > -2.0 || abs(colID.y) > 3.5) return 0.0;

    // Shift columns down at different speeds
    float speed = 0.8 + rand(vec2(colID.x, 1.0)) * 1.2;
    float rowOffset = floor(colID.y + time * speed * 2.0);
    
    // Generate blocky rune patterns
    float cellHash = rand(vec2(colID.x, rowOffset));
    if (cellHash < 0.35) return 0.0;

    // Segmented block pattern inside cell
    float b1 = boxSDF(cellUV - vec2(0.0, 0.15), vec2(0.3, 0.1));
    float b2 = boxSDF(cellUV + vec2(0.0, 0.15), vec2(0.2, 0.1));
    float glyph = min(b1, b2);

    // Cutout center notch
    if (cellHash > 0.7) {
        float notch = boxSDF(cellUV, vec2(0.1, 0.3));
        glyph = max(glyph, -notch);
    }

    return smoothstep(0.02, 0.0, glyph);
}

// --- Keypad Matrix & Tactical Brackets (Right Side) ---
float keypadUI(vec2 st) {
    vec2 p = st - vec2(0.28, 0.0); // Offset to right screen

    // Outer corner brackets [ ]
    vec2 absP = abs(p);
    float outerBox = boxSDF(p, vec2(0.18, 0.28));
    float innerCut = boxSDF(p, vec2(0.16, 0.26));
    float bracketMask = max(outerBox, -innerCut);

    // Side cutouts to form discrete corner brackets
    if (absP.x < 0.14 || absP.y < 0.22) bracketMask = 1.0;
    float brackets = smoothstep(0.01, 0.0, bracketMask);

    // Inner Grid of Keypad Buttons
    vec2 gridUV = (p + vec2(0.12, 0.20)) * vec2(15.0, 10.0);
    vec2 gridID = floor(gridUV);
    vec2 gridCell = fract(gridUV) - 0.5;

    float gridMask = 0.0;
    if (gridID.x >= 0.0 && gridID.x < 4.0 && gridID.y >= 0.0 && gridID.y < 4.0) {
        float btn = boxSDF(gridCell, vec2(0.35, 0.35));
        gridMask = smoothstep(0.05, 0.0, btn);
    }

    return max(brackets, gridMask * 0.7);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 st = (fragCoord.xy - 0.5 * iResolution.xy) / iResolution.y;

    // =========================================================
    // 1. Dark Charcoal Screen & Ambient Crimson Backlight
    // =========================================================
    vec3 bgColor = vec3(0.05, 0.04, 0.05);

    // Menacing red pulse ambient light from lower center
    float redPulse = 0.5 + 0.5 * sin(iTime * 1.8);
    float ambientGlow = smoothstep(0.8, 0.0, length(uv - vec2(0.5, 0.2)));
    vec3 pulseColor = vec3(0.22, 0.02, 0.03) * (0.7 + 0.3 * redPulse);
    bgColor += pulseColor * ambientGlow;

    // Vignette
    vec2 vigUV = uv * (1.0 - uv.yx);
    float vig = clamp(pow(vigUV.x * vigUV.y * 15.0, 0.3), 0.1, 1.0);
    bgColor *= vig;

    // =========================================================
    // 2. Automaton UI Accents & Colors
    // =========================================================
    vec3 autoRed     = vec3(0.92, 0.12, 0.12);
    vec3 autoCrimson = vec3(0.55, 0.05, 0.08);
    vec3 uiLightGray = vec3(0.50, 0.52, 0.55);

    vec3 bg = bgColor;

    // Glyph stream on left
    float glyphs = automatonGlyphs(st, iTime);
    float glyphGlow = automatonGlyphs(st, iTime + 0.05); // Subtle trails
    bg = mix(bg, autoRed, glyphs * 0.65);
    bg += autoCrimson * glyphGlow * 0.25;

    // Keypad UI on right
    float keypad = keypadUI(st);
    bg = mix(bg, uiLightGray, keypad * 0.45);

    // Active illuminated keypad buttons (animated pulse)
    vec2 keypadUV = (st - vec2(0.28, 0.0));
    if (abs(keypadUV.x) < 0.12 && abs(keypadUV.y) < 0.20) {
        float activeCell = rand(floor(keypadUV * 12.0) + floor(iTime * 1.5));
        if (activeCell > 0.75) {
            bg += autoRed * 0.35;
        }
    }

    // Top/Bottom PCB Circuit trace lines
    float circuitLine1 = smoothstep(0.003, 0.0, abs(uv.y - 0.88));
    float circuitLine2 = smoothstep(0.003, 0.0, abs(uv.y - 0.12));
    bg += uiLightGray * (circuitLine1 + circuitLine2) * 0.15;

    // =========================================================
    // 3. Scanlines & Grain
    // =========================================================
    float scanline = sin(uv.y * iResolution.y * 1.4) * 0.5 + 0.5;
    bg *= 0.91 + 0.09 * scanline;

    float grain = rand(fragCoord.xy + vec2(iTime * 111.0, iTime * 222.0));
    bg += (grain - 0.5) * 0.025;

    // =========================================================
    // 4. Terminal Text Composition (Automaton Red Tinting)
    // =========================================================
    vec4 termColor = texture(iChannel0, uv);
    float termLuma = max(termColor.r, max(termColor.g, termColor.b));

    vec3 finalColor;
    if (termLuma < 0.05) {
        finalColor = bg;
    } else {
        // Active terminal text tinted with Automaton crimson emissive backlight
        vec3 textTint = mix(termColor.rgb, vec3(1.0, 0.30, 0.30), 0.25);
        finalColor = mix(bg * 0.40, textTint + vec3(0.25, 0.02, 0.04), clamp(termLuma * 1.4, 0.0, 1.0));
    }

    fragColor = vec4(finalColor, 1.0);
}