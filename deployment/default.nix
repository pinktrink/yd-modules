{ pkgs, lib, config, ... }: let
  inherit (builtins) toString;
  inherit (pkgs) writeShellScript;
  inherit (lib) types;
  inherit (lib.meta) getExe;
  inherit (lib.lists) filter genList elem;
  inherit (lib.options) mkOption;
  inherit (lib.strings) concatStringsSep stringLength optionalString;
  inherit (lib.attrsets) mapAttrsToList;

  cfg = config.physical.deployment;

  getopts = opts: (
    let
      cases = mapAttrsToList
        (n: v:
          let
            attrIsLong = stringLength n > 1;
            short = "-${v.short or (optionalString (! attrIsLong) n)}";
            long = "--${v.long or (optionalString attrIsLong n)}";
            match = filter (x: !(elem x [ "-" "--" ])) [ short long ];
            takes = v.takes or 1;
            inherit (v) run;
            shifts = concatStringsSep "\n" (genList (_: "shift") takes);
          in
          ''
            ${concatStringsSep "|" match})
              ${run}
              ${shifts}
            ;;
          '')
        opts;
    in
    ''
      positionalOpts=()
      while [[ "$#" -gt 0 ]]; do
        currentOpt="$1"
        shift
        case $currentOpt in
          ${concatStringsSep "\n" cases}

          *)
            positionalOpts+=("$currentOpt")
          ;;
        esac
      done
    ''
  );
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
          opts = {
            i = {
              long = "identity";
              run = ''
                identityFile="$1"
              '';
            };
            h = {
              long = "host";
              run = ''
                hostStr="$1"
              '';
            };
            u = {
              long = "user";
              run = ''
                userStr="$1"
              '';
            };
            p = {
              long = "port";
              run = ''
                portStr="$1"
              '';
            };
            o = {
              long = "sshopts";
              run = ''
                additionalSshOpts=" $1"
              '';
            };
          };
        in (writeShellScript "deploy-${cfg.configurationName}" ''
          ${getopts opts}
          host=''${hostStr:-${cfg'.address}}
          user=''${userStr:-${cfg'.user}}
          port=''${portStr:-${toString cfg'.port}}
          action=''${positionalOpts[0]:-test}
          case action in
            ssh)
              exec ${getExe pkgs.openssh} -p ${toString cfg'.port} ${cfg'.user}@${cfg'.address}
              ;;
          esac
          NIX_SSHOPTS="''${additionalSshOpts:+$additionalSshOpts }-p $port''${identityFile:+ -i $identityFile}" ${getExe pkgs.nixos-rebuild} --flake .#${cfg.configurationName} --target-host $user@$host --use-remote-sudo $action
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
