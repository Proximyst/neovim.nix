{ pkgs
, lib
, stdenv
, pkgsWrapNeovim ? pkgs
}:
with lib;
{ appName ? "nvim"
, neovim-unwrapped ? pkgsWrapNeovim.neovim-unwrapped
, plugins ? [ ]
, extraPackages ? [ ]
, extraLuaPackages ? p: [ ]
, extraPython3Packages ? p: [ ]
, withPython3 ? true
, withRuby ? false
, withNodeJs ? true
, withSqlite ? true
, viAlias ? appName == "nvim"
, vimAlias ? appName == "nvim"
}:
let
  defaultPlugin = {
    plugin = null;
    config = null;
    optional = false;
    runtime = { };
  };

  externalPackages = extraPackages ++ (optionals withSqlite [ pkgs.sqlite ]);

  normalizedPlugins = map
    (x:
      defaultPlugin
      // (
        if x ? plugin
        then x
        else { plugin = x; }
      ))
    plugins;

  neovimConfig = pkgsWrapNeovim.neovimUtils.makeNeovimConfig {
    inherit extraPython3Packages withPython3 withRuby withNodeJs viAlias vimAlias;
    plugins = normalizedPlugins;
  };

  nvimRtp = stdenv.mkDerivation {
    name = "nvim-rtp-mari";
    src = lib.cleanSource ../nvim;

    # We will copy in the init.lua into a file without this.
    buildPhase = ''
      mkdir -p "$out"/lua
      cp -r * "$out"/lua
    '';

#    initPhase = ''
#      cp -r plugins "$out"
#    '';
  };

  initLua = ''
    vim.loader.enable()
    --vim.opt.rtp:prepend('${nvimRtp}/plugins')
    vim.opt.rtp:prepend('${nvimRtp}')
    require('entrypoint')
  ''
  ;
#  # Wrap the init.lua file
#  + (builtins.readFile ../nvim/init.lua);

  hasCustomAppName = appName != "nvim" && appName != null && appName != "";
  extraMakeWrapperArgs = builtins.concatStringsSep " " (
    (optional hasCustomAppName
      ''--set NVIM_APPNAME "${appName}"'')
    ++ (optional (externalPackages != [ ])
      ''--prefix PATH : "${makeBinPath externalPackages}"'')
    # Set the LIBSQLITE_CLIB_PATH if sqlite is enabled
    ++ (optional withSqlite
      ''--set LIBSQLITE_CLIB_PATH "${pkgs.sqlite.out}/lib/libsqlite3.so"'')
    # Set the LIBSQLITE environment variable if sqlite is enabled
    ++ (optional withSqlite
      ''--set LIBSQLITE "${pkgs.sqlite.out}/lib/libsqlite3.so"'')
  );

  luaPackages = neovim-unwrapped.lua.pkgs;
  resolvedExtraLuaPackages = extraLuaPackages luaPackages;

  extraMakeWrapperLuaCArgs = optionalString (resolvedExtraLuaPackages != [ ])
    ''--suffix LUA_CPATH ";" "${concatMapStringsSep ";" luaPackages.getLuaCPath resolvedExtraLuaPackages}"'';
  extraMakeWrapperLuaArgs = optionalString (resolvedExtraLuaPackages != [ ])
    ''--suffix LUA_PATH ";" "${concatMapStringsSep ";" luaPackages.getLuaPath resolvedExtraLuaPackages}"'';

  neovim-wrapped = pkgsWrapNeovim.wrapNeovimUnstable neovim-unwrapped (neovimConfig
    // {
    luaRcContent = initLua;
    wrapperArgs = escapeShellArgs neovimConfig.wrapperArgs
      + " "
      + extraMakeWrapperArgs
      + " "
      + extraMakeWrapperLuaCArgs
      + " "
      + extraMakeWrapperLuaArgs;
    wrapRc = true;
  });
in
neovim-wrapped.overrideAttrs (oa: {
  buildPhase = oa.buildPhase
    + lib.optionalString hasCustomAppName ''
    mv "$out"/bin/nvim "$out"/bin/${lib.escaleShellArg appName}
  '';
})
