# GodotJS Nix Flake

[![Build Status](https://github.com/snorreks/godotjs-nix/actions/workflows/update.yml/badge.svg)](https://github.com/snorreks/godotjs-nix/actions/workflows/update.yml)
[![Latest Version](https://img.shields.io/github/v/release/snorreks/godotjs-nix)](https://github.com/snorreks/godotjs-nix/releases/latest)

An auto-updating Nix Flake for [GodotJS](https://github.com/godotjs/GodotJS) — the modified Godot Engine that brings TypeScript and JavaScript support to your game development.

## Features

- **Automated Updates:** Checks upstream releases 3x weekly and auto-updates the flake via GitHub Actions.
- **FHS Environment:** Wraps the binary in a `buildFHSEnv` to ensure compatibility with standard Linux libraries (ALSA, Vulkan, X11, etc.) on NixOS.
- **Zero Config:** Runs immediately without needing to patch binaries manually.
- **Desktop Integration:** Includes a `.desktop` file for application menu integration.

## Installation

### ⚡ Quick Start (Run without installing)

```bash
nix run github:snorreks/godotjs-nix
```

### ❄️ NixOS Configuration (flake.nix)

Add this to your `flake.nix` inputs and modules:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Add GodotJS input
    godotjs-nix.url = "github:snorreks/godotjs-nix";
  };

  outputs = { self, nixpkgs, godotjs-nix, ... }: {
    nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          environment.systemPackages = [
            godotjs-nix.packages.x86_64-linux.default
          ];
        }
      ];
    };
  };
}
```

### 🏠 Home Manager

Add this to your `home.nix` inputs and modules:

```nix
{
  inputs = {
    godotjs-nix.url = "github:snorreks/godotjs-nix";
  };

  outputs = { godotjs-nix, ... }: {
    homeConfigurations.your-user = home-manager.lib.homeManagerConfiguration {
      modules = [
        {
          home.packages = [
            godotjs-nix.packages.x86_64-linux.default
          ];
        }
      ];
    };
  };
}
```

## Usage

Once installed, you can launch the editor from your application launcher or terminal:

```bash
godot
```

or to open a specific project

```bash
godot path/to/project.godot
```

**Note:** This runs the GodotJS editor (V8 version). You can verify JS support is active by checking the available languages in the script editor.

## Version Management

This flake is set up to automatically track the latest releases from the GodotJS repository.

### Pinning a specific version

If you need to stay on a specific version for project stability, reference the tag in your inputs:

```nix
inputs.godotjs-nix.url = "github:snorreks/godotjs-nix/v1.1.0-pipeline-test";
```

### Manual Update

To force a check for updates locally:

```bash
./scripts/update-version.sh
```

## Implementation Details

GodotJS is distributed as a pre-compiled binary. On NixOS, standard binaries often fail because they expect libraries (like `libasound.so` or `libvulkan.so`) to be in `/usr/lib`.

This package uses `buildFHSEnv` to create a bubblewrap container that mimics a standard Linux file system structure, linking the necessary Nix store libraries to expected locations. This ensures 3D acceleration and audio work correctly.

## License

This flake is licensed under MIT. GodotJS is a modification of the Godot Engine.
