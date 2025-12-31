{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    python312 # Python 3.12
    uv # Python package manager
    nixfmt # Nix formatter
    just # Just
    ffmpeg # Required for OpenCV (cv2) - provides libswresample
    stdenv.cc.cc.lib # C++ standard library (libstdc++.so.6)
    zlib # Compression library (libz.so.1)
    xorg.libX11 # X11 library (libX11.so.6)
  ];

  # Set up library paths for runtime
  LD_LIBRARY_PATH = with pkgs; "${lib.makeLibraryPath [
    stdenv.cc.cc.lib
    ffmpeg
    zlib
    xorg.libX11
  ]}";

  # Shell hook to set up environment
  shellHook = ''
    export TMPDIR=/tmp
    just install
  '';
}
