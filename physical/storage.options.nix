{ lib, config, ... }: let
  inherit (lib) types;
  inherit (lib.options) mkOption;

  cfg = config.physical;
in {
  options.physical.storage = mkOption {
    type = types.attrsOf (types.submodule ({ name, config, ... }: {
      options = {
        systemd = {
          enable = mkOption {
            type = types.bool;
            default = false;
          };
          unitConfig = mkOption {
            type = types.attrs;
            default = {};
          };
        };
        name = mkOption {
          type = types.str;
          default = name;
        };
        device = mkOption { type = types.str; };
        mountPoint = mkOption {
          type = types.path;
          default = "/mnt/${config.name}";
        };
        fsType = mkOption {
          type = types.str;
          default = "ext4";
        };
        options = mkOption {
          type = types.listOf (types.either types.attrs types.str);
          default = [ ];
        };
        neededForBoot = mkOption {
          type = types.bool;
          default = false;
        };
        types = mkOption {
          type = types.listOf types.str;
          default = [ ];
        };
      };
    }));
    default = {};
  };
}
