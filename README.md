# Ghostty Gamer Shaders

A curated collection of video game-inspired terminal shaders designed exclusively for the **Ghostty** terminal emulator. Transform your workspace with nostalgia-inducing retro effects, futuristic UI enhancements, and cyber-punk aesthetic filters.

---

## Installation & Setup

Follow these steps to download the shaders and apply them to your Ghostty configuration.

### Step 1: Clone the Repository
Download only the latest files from this repository by running the following commands in your terminal:

```sh
git clone --depth 1 https://github.com/xedret/ghostty-gamer-shaders
cd ghostty-gamer-shaders
```

### Step 2: Create Your Local Shaders Directory
Ghostty expects custom shaders to live in its configuration folder. Create a new directory specifically for your shaders if it doesn't already exist:

```sh
mkdir -p ~/.config/ghostty/shaders
```

### Step 3: Copy Your Chosen Shader
Pick your favorite shader from this repository and copy it into your local Ghostty shader folder. Replace `<your-choice>.glsl` with the actual name of the file you want to use:

```sh
cp <your-choice>.glsl ~/.config/ghostty/shaders/shader.glsl
```

### Step 4: Enable the Shader in Ghostty Config
Open your primary Ghostty configuration file (usually located at `~/.config/ghostty/config`) in your favorite text editor and append the following line:

```ini
# Enable the custom gaming shader
custom-shader = ~/.config/ghostty/shaders/shader.glsl
```

Save the configuration file. Ghostty reloads configurations dynamically, so your new shader effect should apply instantly!

---

## Customization & Tweaks

If you want to manually adjust colors, speed, or intensity variables inside the `.glsl` files, you can modify the values directly. 

Ghostty injects standard Shadertoy-compatible uniforms natively:
*   `iResolution` – Controls the pixel scaling.
*   `iTime` – Tracks terminal execution time for animations.
*   `iChannel0` – Accesses the terminal's underlying text texture layer.

---

## Contributing

Got a game-inspired shader you want to share? 
1. Fork this repository.
2. Add your custom `.glsl` file.
3. Submit a pull request!
