{
  description = "Tern Surface Protocol programs alone in their own Tern window";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = {nixpkgs, ...}: let
    systems = ["x86_64-linux" "aarch64-linux"];
  in {
    packages = nixpkgs.lib.genAttrs systems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.stdenvNoCC.mkDerivation {
        pname = "tern-script";
        version = "0.2.0";
        src = ./.;
        nativeBuildInputs = [pkgs.makeWrapper pkgs.python3];
        installPhase = ''
          install -Dm755 tern-script launcher -t $out/share/tern-script
          install -Dm644 bare.css -t $out/share/tern-script
          patchShebangs $out/share/tern-script
          makeWrapper $out/share/tern-script/tern-script $out/bin/tern-script
          makeWrapper $out/share/tern-script/tern-script $out/bin/tern-launcher --add-flags $out/share/tern-script/launcher
        '';
        meta.mainProgram = "tern-script";
      };
    });
  };
}
