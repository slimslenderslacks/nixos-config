{
  stdenvNoCC,
  lib,
  fetchurl,
  makeWrapper,
}:

stdenvNoCC.mkDerivation rec {
  pname = "daytonaai-bin";
  version = "0.50.0";

  src =
    let
      urls = {
        "x86_64-linux" = {
          url = "https://download.daytona.io/daytona/v0.50.0/daytona-linux-amd64";
          hash = "sha256-5nUWeIAKUSrbEAzo1SCSrebKvt2DKB/f2JZZ9c2vjxA=";
        };
        "x86_64-darwin" = {
          url = "https://download.daytona.io/daytona/v0.50.0/daytona-darwin-amd64";
          hash = "sha256-JAc9EbuZnRCX2v1UXPBF8mlqz478DtrVEk6XEICW7CU=";
        };
        "aarch64-linux" = {
          url = "https://download.daytona.io/daytona/v0.50.0/daytona-linux-arm64";
          hash = "sha256-K02vDcRIIORaWG+UWGfdXV44ZxTQupQ72izDdiKJmqI=";
        };
        "aarch64-darwin" = {
          url = "https://download.daytona.io/daytona/v0.50.0/daytona-darwin-arm64";
          hash = "sha256-kL/K5I7D2wmRPVajIJcV9CuW2s7mzxcwcFFusWqVNgY=";
        };
      };
    in
    fetchurl urls."${stdenvNoCC.hostPlatform.system}";

  dontUnpack = true;

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/daytona
    runHook postInstall
  '';
}
