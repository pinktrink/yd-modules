{ lib, config, ... }: let
  inherit (lib) types;
  inherit (lib.options) mkOption;
in {
  options.physical = {
    tags = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
    functions = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
  };
}
