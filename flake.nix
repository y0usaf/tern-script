{
  description = "A look-aware application launcher in its own Tern window";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = {nixpkgs, ...}: let
    systems = ["x86_64-linux" "aarch64-linux"];
  in {
    packages = nixpkgs.lib.genAttrs systems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.stdenvNoCC.mkDerivation {
        pname = "tern-run";
        version = "0.1.0";
        src = ./.;
        nativeBuildInputs = [pkgs.makeWrapper pkgs.python3];
        installPhase = ''
          install -Dm755 tern-run tern-launcher -t $out/share/tern-run
          install -Dm644 bare.css -t $out/share/tern-run
          patchShebangs $out/share/tern-run
          makeWrapper $out/share/tern-run/tern-run $out/bin/tern-run \
            --prefix PATH : ${pkgs.lib.makeBinPath [pkgs.python3]}
        '';
        meta.mainProgram = "tern-run";
      };
    });
  };
}
