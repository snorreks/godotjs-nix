{
  lib,
  stdenv,
  fetchurl,
  unzip,
  autoPatchelfHook,
  makeWrapper,
  makeDesktopItem,
  alsa-lib,
  dbus,
  fontconfig,
  libGL,
  libpulseaudio,
  libxkbcommon,
  mesa,
  udev,
  vulkan-loader,
  xorg,
  zlib,
}: let
  pname = "godotjs";
  version = "v1.1.0-generate-typings";
  filename = "linux-editor-4.5-v8.zip";

  src = fetchurl {
    url = "https://github.com/godotjs/GodotJS/releases/download/${version}/${filename}";
    sha256 = "sha256-yDTsaVltB3HaWuSRuDql6c2wmiFWtT611BBQNyFlfW0=";
  };

  # Libraries Godot needs at runtime
  runtimeLibs = lib.makeLibraryPath [
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
  ];

  desktopItem = makeDesktopItem {
    name = "godotjs";
    desktopName = "GodotJS";
    comment = "Godot Engine with JavaScript/TypeScript support";
    exec = "godot %f";
    icon = "godot";
    categories = ["Development" "IDE"];
    terminal = false;
  };
in
  stdenv.mkDerivation {
    inherit pname version src;

    nativeBuildInputs = [
      unzip
      autoPatchelfHook
      makeWrapper
    ];

    buildInputs = [
      alsa-lib
      zlib
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin

      # Unzip content
      unzip $src

      # Rename and install binary
      install -m755 godot.linuxbsd.editor.x86_64 $out/bin/godot

      # Wrap the binary to force it to see our libraries
      wrapProgram $out/bin/godot \
        --prefix LD_LIBRARY_PATH : "${runtimeLibs}"

      # Install Desktop Item
      mkdir -p $out/share/applications
      ln -s ${desktopItem}/share/applications/* $out/share/applications/

      runHook postInstall
    '';

    meta = with lib; {
      description = "Godot Engine with JavaScript/TypeScript support";
      homepage = "https://github.com/godotjs/GodotJS";
      license = licenses.mit;
      platforms = ["x86_64-linux"];
      mainProgram = "godot";
    };
  }
