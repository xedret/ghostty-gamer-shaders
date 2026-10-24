// Fallout Pip-Boy CRT Shader for Ghostty (with 90% Background Opacity)

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    
    // --- CRT CURVATURE ---
    vec2 centeredUV = uv * 2.0 - 1.0;
    vec2 offset = centeredUV.yx / 4.5;
    centeredUV += centeredUV * offset * offset;
    vec2 curvedUV = centeredUV * 0.5 + 0.5;
    
    // Outside the CRT monitor curve -> completely transparent (alpha 0.0)
    if (curvedUV.x < 0.0 || curvedUV.x > 1.0 || curvedUV.y < 0.0 || curvedUV.y > 1.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 0.0);
        return;
    }

    // Sample the underlying terminal texture
    vec4 texColor = texture(iChannel0, curvedUV);

    // --- PIP-BOY GREEN PHOSPHOR GLOW ---
    vec3 phosphorColor = vec3(0.05, 1.0, 0.35); 

    // Convert terminal text/background to grayscale intensity
    float luminance = dot(texColor.rgb, vec3(0.299, 0.587, 0.114));
    luminance = smoothstep(0.05, 0.9, luminance);
    
    vec3 finalColor = luminance * phosphorColor * 1.8;
    
    // Ambient screen glow for dark terminal areas
    finalColor += phosphorColor * 0.04;

    // --- SCANLINES ---
    float scanline = sin(curvedUV.y * iResolution.y * 1.5) * 0.08;
    finalColor -= scanline;

    // --- VIGNETTE ---
    vec2 vigUV = curvedUV * (1.0 - curvedUV.y);
    float vignette = vigUV.x * vigUV.y * 15.0;
    vignette = pow(vignette, 0.25);
    finalColor *= vignette;

    // --- SUBTLE FLICKER / NOISE ---
    float noise = fract(sin(dot(curvedUV + mod(iTime, 10.0), vec2(12.9898, 78.233))) * 43758.5453);
    finalColor -= noise * 0.03;

    // Set final color with 90% opacity (0.9)
    fragColor = vec4(finalColor, 0.9);
}