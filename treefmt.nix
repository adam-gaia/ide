{
  projectRootFile = "flake.nix";
  programs = {
    alejandra.enable = true; # Nix formatter
    shellcheck.enable = true;
    shfmt.enable = true;
  };
}
