{
  description = "TODO";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    treefmt-nix,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
      };

      runtimeInputs = with pkgs; [
        # Programs and libraries used by the derivation at *run-time*
        tmux
        neovim-remote
      ];
      toolchain = with pkgs;
        [
          (treefmt-nix.lib.mkWrapper pkgs (import ./treefmt.nix))
        ]
        ++ runtimeInputs;

      ide = pkgs.writeShellApplication {
        name = "ide";
        runtimeInputs = runtimeInputs;
        text = builtins.readFile ./ide.sh;
      };
    in {
      packages.default = ide;

      devShells.default = pkgs.mkShell {
        # Tools that should be avaliable in the shell
        nativeBuildInputs = toolchain;
      };
    });
}
