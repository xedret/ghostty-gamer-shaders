// Sheikah Slate Shader for Ghostty Terminal
// Inspired by The Legend of Zelda: Breath of the Wild
// Format: Shadertoy / Ghostty Compatible

#define COLOR_BG            vec3(0.02, 0.04, 0.07) // Dark Sheikah slate navy
#define COLOR_SHEIKAH_BLUE  vec3(0.00, 0.78, 1.00) // Glowing cyan energy
#define COLOR_SHEIKAH_AMBER vec3(1.00, 0.45, 0.05) // Top conduit energy
#define COLOR_SHEIKAH_GOLD  vec3(0.75, 0.60, 0.35) // Ancient bronze/gold filigree

float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

float drawLine(vec2 p, vec2 a, vec2 b, float thickness) {
    return smoothstep(thickness, thickness * 0.4, sdSegment(p, a, b));
}

float drawDot(vec2 p, vec2 center, float radius) {
    return smoothstep(radius, radius * 0.5, length(p - center));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 p = (fragCoord.xy - 0.5 * iResolution.xy) / iResolution.y;
    float aspect = iResolution.x / iResolution.y;

    // 1. Dark Slate Background & Radial Vignette
    float distCenter = length(p);
    float vignette = smoothstep(1.1, 0.2, distCenter);
    vec3 bgCol = COLOR_BG * vignette;

    // Subtle Sheikah Digital Matrix Grid
    vec2 gridUV = fract(p * 24.0) - 0.5;
    float gridLine = smoothstep(0.47, 0.50, max(abs(gridUV.x), abs(gridUV.y)));
    bgCol += vec3(0.01, 0.06, 0.12) * gridLine * (0.25 + 0.10 * sin(iTime * 1.5 + p.y * 8.0));

    // Dynamic Energy Breathing Pulse
    float pulse = 0.85 + 0.55 * sin(iTime * 2.0);

    vec3 glyphCol = vec3(0.0);

    // 2. Central Sheikah Eye Emblem
    float r = length(p);

    // Outer Orbital Ring & Ambient Glow
    float dRing = abs(r - 0.22);
    float ringLine = smoothstep(0.0045, 0.003, dRing);
    glyphCol += COLOR_SHEIKAH_BLUE * ringLine * 0.85 * pulse;
    glyphCol += vec3(0.0, 0.45, 0.90) * smoothstep(0.035, 0.0, dRing) * 0.20 * pulse;

    // Almond Eye Lids
    float upperCurve = p.y - (0.085 - 1.5 * p.x * p.x);
    float lowerCurve = p.y - (-0.085 + 1.5 * p.x * p.x);
    if (abs(p.x) < 0.21) {
        float eyeLidUpper = smoothstep(0.0045, 0.001, abs(upperCurve));
        float eyeLidLower = smoothstep(0.0045, 0.001, abs(lowerCurve));
        glyphCol += COLOR_SHEIKAH_BLUE * (eyeLidUpper + eyeLidLower) * pulse;
    }

    // Eyelashes (3 Top Triangular Lashes)
    if (p.y > (0.085 - 1.5 * p.x * p.x) && p.y < 0.155 && abs(p.x) < 0.025) {
        if (p.y > 0.085 + 2.8 * abs(p.x)) {
            glyphCol += COLOR_SHEIKAH_BLUE * pulse;
        }
    }
    if (p.x < -0.04 && p.x > -0.11 && p.y > 0.05 && p.y < 0.12) {
        if (p.y > 0.05 - 1.0 * (p.x + 0.04) && p.y < 0.12 + 1.0 * (p.x + 0.08)) {
            glyphCol += COLOR_SHEIKAH_BLUE * pulse;
        }
    }
    if (p.x > 0.04 && p.x < 0.11 && p.y > 0.05 && p.y < 0.12) {
        if (p.y > 0.05 + 1.0 * (p.x - 0.04) && p.y < 0.12 - 1.0 * (p.x - 0.08)) {
            glyphCol += COLOR_SHEIKAH_BLUE * pulse;
        }
    }

    // Iris & Pupil Core
    float irisRing = smoothstep(0.004, 0.001, abs(r - 0.065));
    float pupilCore = drawDot(p, vec2(0.0), 0.026);
    glyphCol += COLOR_SHEIKAH_BLUE * (irisRing + pupilCore) * pulse;

    // Teardrop Stem & Lower Orb
    float tdLine = drawLine(p, vec2(0.0, -0.085), vec2(0.0, -0.16), 0.005);
    float tdHead = drawDot(p, vec2(0.0, -0.16), 0.028);
    glyphCol += COLOR_SHEIKAH_BLUE * max(tdLine, tdHead) * pulse;

    // Ring Nodes (Top, Left, Right)
    float nodeTop   = drawDot(p, vec2(0.0, 0.22), 0.016);
    float nodeLeft  = drawDot(p, vec2(-0.22, 0.0), 0.016);
    float nodeRight = drawDot(p, vec2(0.22, 0.0), 0.016);
    glyphCol += COLOR_SHEIKAH_BLUE * max(max(nodeTop, nodeLeft), nodeRight) * 1.25;

    // Circuit Branches
    float circ1Line = drawLine(p, vec2(-0.155, -0.155), vec2(-0.25, -0.22), 0.0035);
    float circ1Node = drawDot(p, vec2(-0.25, -0.22), 0.012);

    float circ2LineA = drawLine(p, vec2(0.18, -0.12), vec2(0.26, -0.12), 0.0035);
    float circ2LineB = drawLine(p, vec2(0.26, -0.12), vec2(0.26, -0.20), 0.0035);
    float circ2Node  = drawDot(p, vec2(0.26, -0.20), 0.012);

    glyphCol += COLOR_SHEIKAH_BLUE * max(max(circ1Line, circ1Node), max(max(circ2LineA, circ2LineB), circ2Node)) * pulse;

    // 3. Top Amber Conduit Indicator
    // float amberConduit = drawLine(p, vec2(0.0, 0.24), vec2(0.0, 0.44), 0.0045);
    // glyphCol += COLOR_SHEIKAH_AMBER * amberConduit * (0.90 + 0.20 * sin(iTime * 4.0));

    // 4. Corner Bronze Filigrees
    float marginX = 0.44 * aspect;
    float marginY = 0.39;

    vec2 trCenter = vec2(marginX, marginY);
    float trNode  = drawDot(p, trCenter, 0.014);
    float trRing  = smoothstep(0.0025, 0.0015, abs(length(p - trCenter) - 0.038));
    glyphCol += COLOR_SHEIKAH_BLUE * trNode * 1.2;
    glyphCol += COLOR_SHEIKAH_GOLD * trRing * 0.75;

    vec2 tlCenter = vec2(-marginX, marginY);
    float tlNode  = drawDot(p, tlCenter, 0.014);
    float tlRing  = smoothstep(0.0035, 0.001, abs(length(p - tlCenter) - 0.038));
    glyphCol += COLOR_SHEIKAH_BLUE * tlNode * 1.2;
    glyphCol += COLOR_SHEIKAH_GOLD * tlRing * 0.75;

    vec2 brCenter = vec2(marginX, -marginY);
    float brNode  = drawDot(p, brCenter, 0.014);
    float brRing  = smoothstep(0.0035, 0.001, abs(length(p - brCenter) - 0.038));
    glyphCol += COLOR_SHEIKAH_BLUE * brNode * 1.2;
    glyphCol += COLOR_SHEIKAH_GOLD * brRing * 0.75;

    // Outer Ancient Frame Border
    //float frameX = smoothstep(0.005, 0.001, abs(abs(p.x) - (0.435 * aspect)));
    //float frameY = smoothstep(0.003, 0.001, abs(abs(p.y) - 0.415));
    //if (abs(p.x) < 0.435 * aspect && abs(p.y) < 0.415) {
    //    glyphCol += COLOR_SHEIKAH_GOLD * (frameX + frameY) * 0.35;
    //}

    vec3 finalBg = bgCol + glyphCol;

    // 5. Terminal Foreground Text Compositing (Brightness Masking)
    vec4 termColor = texture(iChannel0, uv);
    
    // Calculate brightness of text characters in iChannel0
    float textBrightness = max(termColor.r, max(termColor.g, termColor.b));
    
    // Mask: 0.0 for empty background space, 1.0 for active terminal text
    float textMask = smoothstep(0.14, 0.15, textBrightness);

    // Blend: Shader artwork on empty background, crisp text over foreground
    vec3 finalColor = mix(finalBg, termColor.rgb, textMask);

    fragColor = vec4(finalColor, 1.0);
}