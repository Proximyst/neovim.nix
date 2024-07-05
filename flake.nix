{
  description = "mari's neovim configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";

        fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, fenix, flake-utils, ... } @ inputs:
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
              fenix.overlays.default
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
