{
  lib,
  stdenv,
  source,
}:
stdenv.mkDerivation {
  pname = "sketchybar-helper";
  version = "1";

  # Exclude the historical compiled binary and build exclusively from source.
  src = lib.fileset.toSource {
    root = source;
    fileset = lib.fileset.unions [
      (source + "/helper.c")
      (source + "/cpu.h")
      (source + "/sketchybar.h")
    ];
  };

  strictDeps = true;
  dontConfigure = true;
  buildPhase = ''
    runHook preBuild
    "$CC" -std=c99 -O3 helper.c -o helper
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    install -m755 helper "$out/bin/helper"
    runHook postInstall
  '';

  meta = {
    description = "Native CPU statistics helper for the SketchyBar configuration";
    platforms = lib.platforms.darwin;
    mainProgram = "helper";
  };
}
