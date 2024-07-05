{ inputs }:
self: super:
let
  pkgs = self;
  lib = self.pkgs.lib;

  mkNvimPlugin = source: pluginName:
    pkgs.vimUtils.buildVimPlugin {
      pname = pluginName;
      src = source;
      version = source.lastModifiedDate;
    };

  pkgsWrapNeovim = inputs.nixpkgs.legacyPackages.${pkgs.system};

  mkNeovim = pkgs.callPackage ./mk-neovim.nix {
    inherit pkgsWrapNeovim;
  };

  # A plugin can either be a package or an attrset, such as
  # { plugin = <plugin>; # the package, e.g. pkgs.vimPlugins.nvim-cmp
  #   config = <config>; # String; a config that will be loaded with the plugin
  #   # Boolean; Whether to automatically load the plugin as a 'start' plugin,
  #   # or as an 'opt' plugin, that can be loaded with `:packadd!`
  #   optional = <true|false>; # Default: false
  #   ...
  # }
  plugins = with pkgs.vimPlugins; [
    nvim-treesitter.withAllGrammars
  ];

  extraPackages = with pkgs; [
    lua-language-server
    nil # nix LSP
  ];
in
{
  nvim-pkg = mkNeovim {
    inherit plugins extraPackages;
  };
}
