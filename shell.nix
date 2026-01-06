{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    python312
    uv
    nixfmt
    just
    ffmpeg
    stdenv.cc.cc.lib
    zlib

    # X11 and display libraries
    xorg.libX11
    xorg.libXext
    xorg.libXrandr
    xorg.libXrender
    xorg.libXi
    xorg.libXcursor
    xorg.libXinerama

    # AMD/Intel Drivers
    vulkan-loader
    mesa
  ];

  # Set up library paths for runtime
  LD_LIBRARY_PATH =
    with pkgs;
    lib.makeLibraryPath [
      stdenv.cc.cc.lib
      ffmpeg
      zlib
      xorg.libX11
      xorg.libXext
      xorg.libXrandr
      xorg.libXrender
      xorg.libXi
      xorg.libXcursor
      xorg.libXinerama
      vulkan-loader
      mesa
    ];

  # Shell hook to set up environment
  shellHook = ''
    export TMPDIR=/tmp
    just install

    # Add bundled Python libs
    if [ -d ".venv/lib/python3.12/site-packages" ]; then
      for d in .venv/lib/python3.12/site-packages/*.libs; do
        [ -d "$d" ] && export LD_LIBRARY_PATH="$PWD/$d:$LD_LIBRARY_PATH"
      done
    fi
  '';
}
