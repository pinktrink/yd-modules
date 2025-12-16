{ pkgs, lib, config, ... }: let
  inherit (builtins) toString;
  inherit (pkgs) writeShellScript;
  inherit (lib) types;
  inherit (lib.meta) getExe;
  inherit (lib.options) mkOption;

  cfg = config.physical.deployment;
in {
  options.physical.deployment = {
    configurationName = mkOption {
      type = types.str;
    };
    ssh = {
      enable = mkOption {
        type = types.bool;
        default = true;
      };
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
      script = mkOption {
        type = types.lines;
        default = let
          cfg' = cfg.ssh;
        in (writeShellScript "deploy-${cfg.configurationName}" ''
          case $1 in
            s)
              action=switch
            ;;
            t)
              action=test
            ;;
            ssh)
              exec ${getExe pkgs.openssh} -p ${toString cfg'.port} ${cfg'.user}@${cfg'.address}
            ;;
            *)
              action=''${1:-test}
            ;;
          esac
          echo -n "Host [${cfg'.address}]: "
          read -r -t 5 host
          host=''${host:-${cfg'.address}}:
          NIX_SSHOPTS='-t -p ${toString cfg'.port}' ${getExe pkgs.nixos-rebuild} --flake .#${cfg.configurationName} --target-host ${cfg'.user}@${cfg'.address} --use-remote-sudo $action
        '').outPath;
      };
      options = mkOption {
        type = types.attrs;
        default = {};
      };
    };
    script = mkOption {
      type = types.str;
      default = cfg.ssh.script;
    };
  };
}
