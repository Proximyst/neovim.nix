{
  description = "mari's neovim configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";

    # Plugins are defined by prefixing the names with "plugin-".
    # This will automatically pick them up.
  };

  outputs = { nixpkgs, flake-utils, ... } @ inputs:
    let
      neovimOverlay = import ./nix/neovim-overlay.nix {
        inherit inputs;
      };
    in
    {
      overlays.default = neovimOverlay;
    } // (
      flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              neovimOverlay
            ];
          };
        in
        {
          packages = rec {
            nvim = pkgs.nvim-pkg;
            default = nvim;
          };

          # Enables `nix fmt`
          formatter = pkgs.nixpkgs-fmt;
        }));
}
