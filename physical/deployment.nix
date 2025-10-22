{ pkgs, lib, config, ... }: let
  inherit (builtins) toString;
  inherit (lib) types;
  inherit (lib.meta) getExe;
  inherit (lib.options) mkOption;

  cfg = config.physical.deployment;
in {
  options.physical.deployment = {
    address = mkOption {
      type = types.nullOr types.str;
      default = config.physical.residence.address;
    };
    port = mkOption {
      type = types.port;
      default = 22;
    };
    user = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
    configurationName = mkOption {
      type = types.str;
    };
    script = mkOption {
      type = types.lines;
      default = ''
        case $1 in
          s)
            action=switch
          ;;
          t)
            action=test
          ;;
          ssh)
            exec ${getExe pkgs.openssh} -p ${toString cfg.port} ${cfg.user}@${cfg.address}
          ;;
          *)
            action=''${1:-test}
          ;;
        esac
        echo -n "Host [${cfg.address}]: "
        read -r -t 5 host
        host=''${host:-${cfg.address}}:
        NIX_SSHOPTS='-t -p ${toString cfg.port}' ${getExe pkgs.nixos-rebuild} --flake .#${cfg.configurationName} --target-host ${cfg.user}@${cfg.address} --use-remote-sudo $action
      '';
    };
    options = mkOption {
      type = types.attrs;
      default = {};
    };
  };
}
