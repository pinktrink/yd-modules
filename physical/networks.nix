{ lib, config, ... }: let
  inherit (builtins) isList;
  inherit (lib) types;
  inherit (lib.lists) toList length elemAt head;
  inherit (lib.modules) mkMerge mkIf;
  inherit (lib.options) mkOption;
  inherit (lib.strings) concatStringsSep;
  inherit (lib.attrsets) foldlAttrs recursiveUpdate attrNames filterAttrs mapAttrsToList optionalAttrs;

  concatMapAttrs = f: foldlAttrs (a: n: v: recursiveUpdate a (f n v)) {};

  cfg = config.physical;
in {
  imports = [ ./networks.options.nix ];

  config.networking = mkMerge [
    (mkIf (cfg.rack?vlan && cfg.rack.vlan.enable) {
      macvlans.${cfg.rack.vlan.name} = { inherit (cfg.rack.vlan) interface; };
      interfaces.${cfg.rack.vlan.name}.ipv4.addresses = mkIf cfg.rack.vlan.ipv4.enable [ { inherit (cfg.rack.vlan.ipv4) address prefixLength; } ];
      firewall.trustedInterfaces = mkIf cfg.rack.vlan.trust [ cfg.rack.vlan.name ];
    })
    {
      macvlans = concatMapAttrs (_: v: optionalAttrs v.macvlan.enable {
        ${v.interface}.interface = v.macvlan.interface;
      }) (filterAttrs (_: v: v.macvlan.enable) cfg.networks);
      interfaces = concatMapAttrs (_: v: optionalAttrs v.createInterface {
        ${v.interface}.ipv4.addresses = [ { inherit (v) address prefixLength; } ];
      }) (filterAttrs (_: v: v.interface != null) cfg.networks);
      firewall.trustedInterfaces = mapAttrsToList (_: v: v.interface) (filterAttrs (_: v: v.trust) cfg.networks);
    }
  ];
}
