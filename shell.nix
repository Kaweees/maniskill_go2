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

    # X11 and display libraries
    xorg.libX11
    xorg.libXext
    xorg.libXrandr
    xorg.libXrender
    xorg.libXi
    xorg.libXcursor
    xorg.libXinerama

    # Vulkan with software rendering (Lavapipe)
    # Using Nix's mesa.drivers avoids glibc conflicts with system GPU drivers
    vulkan-loader
    mesa.drivers
  ];

  # Set up library paths for runtime
  LD_LIBRARY_PATH = with pkgs; "${lib.makeLibraryPath [
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
    mesa.drivers
  ]}";

  # Shell hook to set up environment
  shellHook = ''
    export TMPDIR=/tmp
    just install

    # Add all bundled .libs directories from Python packages to LD_LIBRARY_PATH
    # Many packages (sapien, pillow, scipy, etc.) bundle their own shared libraries
    SITE_PACKAGES=".venv/lib/python3.12/site-packages"
    if [ -d "$SITE_PACKAGES" ]; then
      for libs_dir in "$SITE_PACKAGES"/*.libs; do
        if [ -d "$libs_dir" ]; then
          export LD_LIBRARY_PATH="$PWD/$libs_dir:$LD_LIBRARY_PATH"
        fi
      done
    fi

    # Use AMD RADV Vulkan driver from Nix's Mesa
    # This provides hardware-accelerated Vulkan for AMD GPUs
    export VK_ICD_FILENAMES="${pkgs.mesa.drivers}/share/vulkan/icd.d/radeon_icd.x86_64.json"

    # Disable CUDA to force CPU physics (no NVIDIA GPU)
    export CUDA_VISIBLE_DEVICES=""
  '';
}
