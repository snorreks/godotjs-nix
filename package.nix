{
  lib,
  stdenv,
  fetchurl,
  buildFHSEnv,
  unzip,
  alsa-lib,
  dbus,
  fontconfig,
  libGL,
  libpulseaudio,
  libxkbcommon,
  makeDesktopItem,
  mesa,
  udev,
  vulkan-loader,
  xorg,
  zlib,
}: let
  pname = "godotjs";
  # THIS VERSION MUST MATCH flake.nix
  version = "v1.1.0-pipeline-test";

  # Filename logic based on the release pattern
  filename = "linux-editor-4.5-v8.zip";

  src = fetchurl {
    url = "https://github.com/godotjs/GodotJS/releases/download/${version}/${filename}";
    # We will update this automatically via script
    sha256 = "sha256-0000000000000000000000000000000000000000000=";
  };

  # 1. Extract the binary
  godot-unwrapped = stdenv.mkDerivation {
    inherit pname version src;

    nativeBuildInputs = [unzip];

    dontBuild = true;
    dontConfigure = true;
    dontStrip = true;

    installPhase = ''
      mkdir -p $out/bin

      # Unzip content
      unzip $src

      # The binary name inside the zip
      install -m755 godot.linuxbsd.editor.x86_64 $out/bin/godot-bin
    '';
  };

  # 2. Create the Desktop Item
  desktopItem = makeDesktopItem {
    name = "godotjs";
    desktopName = "GodotJS";
    comment = "Godot Engine with JavaScript/TypeScript support";
    exec = "godot %f";
    icon = "godot";
    categories = ["Development" "GameDevelopment"];
    terminal = false;
  };
in
  buildFHSEnv {
    name = "godot";

    # Libraries Godot needs to run
    targetPkgs = pkgs: (with pkgs; [
      alsa-lib
      dbus
      fontconfig
      libGL
      libpulseaudio
      libxkbcommon
      mesa
      udev
      vulkan-loader
      xorg.libX11
      xorg.libXcursor
      xorg.libXext
      xorg.libXi
      xorg.libXinerama
      xorg.libXrandr
      xorg.libXrender
      zlib
    ]);

    # Script to launch
    runScript = "${godot-unwrapped}/bin/godot-bin";

    extraInstallCommands = ''
      mkdir -p $out/share/applications
      ln -s ${desktopItem}/share/applications/* $out/share/applications/
    '';

    meta = with lib; {
      description = "Godot Engine with JavaScript/TypeScript support";
      homepage = "https://github.com/godotjs/GodotJS";
      license = licenses.mit;
      platforms = ["x86_64-linux"];
      mainProgram = "godot";
    };
  }
